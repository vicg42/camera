#include <QtWidgets>
#include "mainwin.h"
#include <QtSerialPort/QSerialPortInfo>
#include "hwi.h"

CMainwin::CMainwin(QWidget *parent)
    : QDialog(parent)
{

  setWindowTitle(tr("Camera Ctrl"));

  ld.txbuf.data = new char;
  ld.txbuf.bsize = sizeof(char);
  ld.rxbuf.data = new char;
  ld.rxbuf.bsize = sizeof(char);
  ld.status = IOS_IDLE;

  io.uart.dev = new QSerialPort(this);
  io.uart.info = new QSerialPortInfo;
  io.tmr_timeout = new QTimer(this);
  io.tmr_timeout->stop();

  edt_Log = new QTextEdit(this);
  tab_Ctrl = new QTabWidget(this);
  tab_Dev2PC = new CDev2PC_tab(this);
  tab_CCD = new CCCD_tab(this);

  tab_Ctrl->addTab(tab_Dev2PC, tr("Dev2PC"));
  tab_Ctrl->addTab(tab_CCD, tr("CCD"));

  foreach (const QSerialPortInfo &inf, io.uart.info->availablePorts())
    tab_Dev2PC->cmb_UART_Port->addItem(inf.portName());

  QListIterator<qint32> it(QSerialPortInfo::standardBaudRates());
  while(it.hasNext())
    tab_Dev2PC->cmb_UART_BaudRate->addItem(QString::number(it.next()));

  tab_Dev2PC->cmb_UART_BaudRate->setCurrentText(QString::number(115200));

  QVBoxLayout *mainLayout = new QVBoxLayout(this);
  mainLayout->addWidget(tab_Ctrl);
  mainLayout->addWidget(edt_Log);
  setLayout(mainLayout);


  QObject::connect(tab_Dev2PC->btn_UART_connect, SIGNAL(toggled(bool))
                   , this, SLOT(connectUART(bool)));

  QObject::connect(tab_CCD->btn_setRIO, SIGNAL(clicked())
                   , this, SLOT(setCCDRIO()));

  QObject::connect(io.uart.dev, SIGNAL(readyRead())
                   , this, SLOT(getDevData()));

  QObject::connect(io.tmr_timeout, SIGNAL(timeout())
                   , this, SLOT(DevAckTimeout()));

  QObject::connect(tab_CCD->btn_getRIO, SIGNAL(clicked())
                   , this, SLOT(getCCDRIO()));
}


CMainwin::~CMainwin()
{
  io.uart.dev->close();
  delete io.uart.info;

  delete [] ld.txbuf.data;
  delete [] ld.rxbuf.data;
}


int CMainwin::sendCommand(TCFGTarget target,
                  char dir,
                  char fifo,
                  size_t areg,
                  char *data,
                  size_t bcount
                  )
{
  // check arguments, translate <target> to H/W code

  if (ld.status != IOS_IDLE)
    return EER_INVAL;

  u8 target_code = 0;

  switch (target)
  {
  case CFG_DEV_FRR:
    target_code = C_CFG_DEV_FRR;
    break;
  case CFG_DEV_FIBER:
    target_code = C_CFG_DEV_FIBER;
    break;
  case CFG_DEV_FG:
    target_code = C_CFG_DEV_FG;
    break;
  case CFG_DEV_TIMER:
    target_code = C_CFG_DEV_TIMER;
    break;
  default:
    return EER_INVAL;
  }

  const TCfg_chunk cfg_chunk_mask = ~0;

  if ((areg & cfg_chunk_mask) != areg)
    return EER_INVAL;

  if (!data)
    return EER_INVAL;

  if  (!bcount || ((bcount & cfg_chunk_mask) != bcount))
    return EER_INVAL;

  if (bcount > (C_CFG_MAX_NCHUNKS - C_CFG_HCHUNK_DATA))
    return EER_NOBUFS;

  // make packet
  size_t chunk_count = 0;

  if (bcount % sizeof(TCfg_chunk))
    chunk_count = ((bcount / sizeof(TCfg_chunk)) + 1);
  else
    chunk_count = bcount;

  ld.req_bsize = bcount;

  if (dir == C_CFG_DIR_WR)
  {
    ld.txbuf.bsize = (C_CFG_HCHUNK_COUNT * sizeof(TCfg_chunk))
                      + (chunk_count * sizeof(TCfg_chunk));
    if (!ld.txbuf.data)
      ld.txbuf.data = new char[ld.txbuf.bsize];
    else
    {
      delete [] ld.txbuf.data;
      ld.txbuf.data = new char[ld.txbuf.bsize];
    }

    //set rxbuf for ACK
    ld.rxbuf.bsize = (C_CFG_HCHUNK_COUNT * sizeof(TCfg_chunk));
    if (!ld.rxbuf.data)
      ld.rxbuf.data = new char[ld.rxbuf.bsize];
    else
    {
      delete [] ld.rxbuf.data;
      ld.rxbuf.data = new char[ld.rxbuf.bsize];
    }
  }
  else
  {
    ld.txbuf.bsize = (C_CFG_HCHUNK_COUNT * sizeof(TCfg_chunk));
    if (!ld.txbuf.data)
      ld.txbuf.data = new char[ld.txbuf.bsize];
    else
    {
      delete [] ld.txbuf.data;
      ld.txbuf.data = new char[ld.txbuf.bsize];
    }

    ld.rxbuf.bsize = (C_CFG_HCHUNK_COUNT * sizeof(TCfg_chunk))
                      + (chunk_count * sizeof(TCfg_chunk));
    if (!ld.rxbuf.data)
      ld.rxbuf.data = new char[ld.rxbuf.bsize];
    else
    {
      delete [] ld.rxbuf.data;
      ld.rxbuf.data = new char[ld.rxbuf.bsize];
    }
  }

  memset(ld.txbuf.data, 0, ld.txbuf.bsize);
  memset(ld.rxbuf.data, 0, ld.rxbuf.bsize);

  TCfg_chunk * ptr = (TCfg_chunk *) ld.txbuf.data;

  ptr[C_CFG_HCHUNK_CTRL]
    = ((fifo << C_CFG_FIFO_BIT) & C_CFG_FIFO_MASK)
    | ((dir << C_CFG_DIR_BIT) & C_CFG_DIR_MASK)
    | ((tagcnt << C_CFG_TAG_BIT) & C_CFG_TAG_MASK)
    | ((target_code << C_CFG_DEV_BIT) & C_CFG_DEV_MASK);
  ptr[C_CFG_HCHUNK_ADR] = areg;
  ptr[C_CFG_HCHUNK_DLEN] = chunk_count;

  if (dir == C_CFG_DIR_WR)
  {
    memcpy((char *) &ptr[C_CFG_HCHUNK_DATA], data, ld.req_bsize);
    ld.status = IOS_WR;
  }
  else
    ld.status = IOS_RD;

  ld.tag_tx++;
  ld.error = 0;

  return 0;
}



void CMainwin::DevAckTimeout()
{
  edt_Log->append(tr("ERROR: ACK Timeout "));
  io.tmr_timeout->stop();
}


void CMainwin::connectUART(bool state)
{
  if (state){
    io.uart.dev->setPort(io.uart.info->availablePorts().at(
                           tab_Dev2PC->cmb_UART_Port->currentIndex()));

    if (io.uart.dev->isOpen())
    {
      edt_Log->append(QString(tr("ERROR: port is open "))
                      + io.uart.dev->portName());
      return;
    }

    if (io.uart.dev->open(QIODevice::ReadWrite))
    {
      edt_Log->append(QString(tr("Open: ")) + io.uart.dev->portName());
    }
    else
      edt_Log->append(tr("Error"));
  }
  else
  {
    io.uart.dev->close();
    edt_Log->append(QString(tr("Close: ")) + io.uart.dev->portName());
  }

}


void CMainwin::getDevData()
{
  if (ld.status == IOS_WR)
  {
    if (io.uart.dev->bytesAvailable() == ld.rxbuf.bsize)
    {
      io.tmr_timeout->stop();
      if (io.uart.dev->read(ld.rxbuf.data, ld.rxbuf.bsize) == ld.rxbuf.bsize)
      {
        if (memcmp(ld.txbuf.data, ld.rxbuf.data, ld.rxbuf.bsize))
          edt_Log->append(QString(tr("ERROR: bad TxACK")));

        ld.status = IOS_IDLE;
      }
    }
  }
  else
    if (ld.status == IOS_RD)
    {
      if (io.uart.dev->bytesAvailable() == ld.rxbuf.bsize)
      {
        io.tmr_timeout->stop();
        if (io.uart.dev->read(ld.rxbuf.data, ld.rxbuf.bsize) == ld.rxbuf.bsize)
        {
          if (memcmp(ld.txbuf.data, ld.rxbuf.data, (C_CFG_HCHUNK_COUNT * sizeof(TCfg_chunk))))
            edt_Log->append(QString(tr("ERROR: PktRD Header")));

          ld.status = IOS_IDLE;
        }
      }
    }
}

void CMainwin::setCCDRIO()
{
  if (!io.uart.dev->isOpen())
  {
    edt_Log->append(QString(tr("ERROR: UART port closed")));
    return;
  }

  if (tab_CCD->edl_x1RIO->text().isEmpty() && tab_CCD->edl_y1RIO->text().isEmpty()
    && tab_CCD->edl_x2RIO->text().isEmpty() && tab_CCD->edl_y2RIO->text().isEmpty())
  {
    edt_Log->append(QString(tr("ERROR: Bad coordinate")));
    return;
  }

  if ((tab_CCD->edl_x1RIO->text().toUInt() >= tab_CCD->edl_x2RIO->text().toUInt())
      || (tab_CCD->edl_y1RIO->text().toUInt()) > tab_CCD->edl_y2RIO->text().toUInt())
  {
    edt_Log->append(QString(tr("ERROR: Bad coordinate")));
    return;
  }

  quint16 txd = tab_CCD->edl_x2RIO->text().toUInt();

  if (sendCommand(CFG_DEV_FG,
                  C_CFG_DIR_WR,
                  C_CFG_FIFO_OFF,
                  0,
                  (char *) &txd,
                  sizeof(quint16)))
  {
    edt_Log->append(QString(tr("ERROR: sendCommand")));
    return;
  }

  qint64 txcount;
  txcount = io.uart.dev->write(ld.txbuf.data, ld.txbuf.bsize);
  if (txcount == -1)
  {
    edt_Log->append(QString(tr("ERROR: io.dev / Write ")));
    return;
  }
//  else
//    edt_Log->append(QString(tr("OK: io.dev / Write ")) + QString::number(txcount));

  io.tmr_timeout->start(1000);

}

void CMainwin::getCCDRIO()
{
  if (!io.uart.dev->isOpen())
  {
    edt_Log->append(QString(tr("ERROR: UART port closed")));
    return;
  }

  if (sendCommand(CFG_DEV_FG,
                  C_CFG_DIR_RD,
                  C_CFG_FIFO_OFF,
                  0,
                  0,
                  sizeof(quint16)))
  {
    edt_Log->append(QString(tr("ERROR: sendCommand")));
    return;
  }

  qint64 txcount;
  txcount = io.uart.dev->write(ld.txbuf.data, ld.txbuf.bsize);
  if (txcount == -1)
  {
    edt_Log->append(QString(tr("ERROR: io.dev / Write ")));
    return;
  }

  io.tmr_timeout->start(1000);

}


CDev2PC_tab::CDev2PC_tab(QWidget *parent)
  : QWidget(parent)
{
  QLabel *lbl_UART_Port = new QLabel(tr("Port:"));
  cmb_UART_Port  = new QComboBox;

  QLabel *lbl_UART_BaudRate = new QLabel(tr("BaudRate:"));
  cmb_UART_BaudRate  = new QComboBox;

  btn_UART_connect = new QPushButton(tr("Connect"));
  btn_UART_connect->setCheckable(true);
  btn_UART_connect->setChecked(false);

  QGridLayout *UART_GLayout = new QGridLayout;
  UART_GLayout->addWidget(lbl_UART_Port, 0, 0);
  UART_GLayout->addWidget(cmb_UART_Port, 0, 1);

  UART_GLayout->addWidget(lbl_UART_BaudRate, 1, 0);
  UART_GLayout->addWidget(cmb_UART_BaudRate, 1, 1);

  UART_GLayout->addWidget(btn_UART_connect, 2, 0, 1, 2);

  QGroupBox *grp_UART = new QGroupBox(tr("UART"));
  grp_UART->setLayout(UART_GLayout);

  QHBoxLayout *mainLayout = new QHBoxLayout;
  mainLayout->addWidget(grp_UART);
  setLayout(mainLayout);

}


CCCD_tab::CCCD_tab(QWidget *parent)
  : QWidget(parent)
{
  QLabel *lbl_x1RIO = new QLabel(tr("X1:"));
  QLabel *lbl_y1RIO = new QLabel(tr("Y1:"));;
  QLabel *lbl_x2RIO = new QLabel(tr("X2:"));
  QLabel *lbl_y2RIO = new QLabel(tr("Y2:"));

  edl_x1RIO = new QLineEdit(tr("0"));
  edl_y1RIO = new QLineEdit(tr("0"));
  edl_x2RIO = new QLineEdit(tr("1024"));
  edl_y2RIO = new QLineEdit(tr("1024"));

  btn_setRIO = new QPushButton(tr("SET"));
  btn_getRIO = new QPushButton(tr("GET"));

  QGridLayout *RIO_GLayout = new QGridLayout;

  RIO_GLayout->addWidget(lbl_x1RIO, 0, 0);
  RIO_GLayout->addWidget(edl_x1RIO, 0, 1);
  RIO_GLayout->addWidget(lbl_y1RIO, 1, 0);
  RIO_GLayout->addWidget(edl_y1RIO, 1, 1);
  RIO_GLayout->addWidget(lbl_x2RIO, 2, 0);
  RIO_GLayout->addWidget(edl_x2RIO, 2, 1);
  RIO_GLayout->addWidget(lbl_y2RIO, 3, 0);
  RIO_GLayout->addWidget(edl_y2RIO, 3, 1);
  RIO_GLayout->addWidget(btn_setRIO, 4, 0, 1, 2);
  RIO_GLayout->addWidget(btn_getRIO, 5, 0, 1, 2);

  QGroupBox *grp_RIO = new QGroupBox(tr("RIO"));
  grp_RIO->setLayout(RIO_GLayout);

  QGridLayout *mainLayout = new QGridLayout;
  mainLayout->addWidget(grp_RIO, 0 ,0);


  setLayout(mainLayout);
}
