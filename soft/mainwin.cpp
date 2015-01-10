#include <QtWidgets>
#include "mainwin.h"
#include <QtSerialPort/QSerialPortInfo>
#include "hwi.h"

CMainwin::CMainwin(QWidget *parent)
    : QDialog(parent)
{

  setWindowTitle(tr("Camera Ctrl"));

  ld.txbuf.data = new char;
  ld.txbuf.size.byte = sizeof(char);
  ld.rxbuf.data = new char;
  ld.rxbuf.size.byte = sizeof(char);
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
                   , this, SLOT(UARTconnect(bool)));

  QObject::connect(tab_CCD->btn_setRIO, SIGNAL(clicked())
                   , this, SLOT(setCCDRIO()));

  QObject::connect(io.uart.dev, SIGNAL(readyRead())
                   , this, SLOT(getDevData()));

  QObject::connect(io.tmr_timeout, SIGNAL(timeout())
                   , this, SLOT(DevAckTimeout()));

  QObject::connect(tab_CCD->btn_getRIO, SIGNAL(clicked())
                   , this, SLOT(getCCDRIO()));

  QObject::connect(tab_Dev2PC->cmb_UART_BaudRate,SIGNAL(currentTextChanged(QString))
                   , this, SLOT(UARTBaudRate(QString)));
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

  if ((bcount % sizeof(TCfg_chunk))
      && (sizeof(TCfg_chunk) != sizeof(quint8)))
    chunk_count = ((bcount / sizeof(TCfg_chunk)) + 1);
  else
    chunk_count = bcount;


  ld.req_bsize = bcount;

  if (dir == C_CFG_DIR_WR)
  {
    ld.txbuf.size.byte = (C_CFG_HCHUNK_COUNT * sizeof(TCfg_chunk))
                      + (chunk_count * sizeof(TCfg_chunk));
    ld.txbuf.size.chunk = C_CFG_HCHUNK_COUNT + chunk_count;
    if (!ld.txbuf.data)
      ld.txbuf.data = new char[ld.txbuf.size.byte];
    else
    {
      delete [] ld.txbuf.data;
      ld.txbuf.data = new char[ld.txbuf.size.byte];
    }

    //set rxbuf for ACK
    ld.rxbuf.size.byte = (C_CFG_HCHUNK_COUNT * sizeof(TCfg_chunk));
    ld.rxbuf.size.chunk = C_CFG_HCHUNK_COUNT;
    if (!ld.rxbuf.data)
      ld.rxbuf.data = new char[ld.rxbuf.size.byte];
    else
    {
      delete [] ld.rxbuf.data;
      ld.rxbuf.data = new char[ld.rxbuf.size.byte];
    }
  }
  else
  {
    ld.txbuf.size.byte = (C_CFG_HCHUNK_COUNT * sizeof(TCfg_chunk));
    ld.txbuf.size.chunk = C_CFG_HCHUNK_COUNT;
    if (!ld.txbuf.data)
      ld.txbuf.data = new char[ld.txbuf.size.byte];
    else
    {
      delete [] ld.txbuf.data;
      ld.txbuf.data = new char[ld.txbuf.size.byte];
    }

    ld.rxbuf.size.byte = (C_CFG_HCHUNK_COUNT * sizeof(TCfg_chunk))
                      + (chunk_count * sizeof(TCfg_chunk));
    ld.txbuf.size.chunk = C_CFG_HCHUNK_COUNT + chunk_count;
    if (!ld.rxbuf.data)
      ld.rxbuf.data = new char[ld.rxbuf.size.byte];
    else
    {
      delete [] ld.rxbuf.data;
      ld.rxbuf.data = new char[ld.rxbuf.size.byte];
    }
  }

  memset(ld.txbuf.data, 0, ld.txbuf.size.byte);
  memset(ld.rxbuf.data, 0, ld.rxbuf.size.byte);

  TCfg_chunk * ptr = (TCfg_chunk *) ld.txbuf.data;

  ptr[C_CFG_HCHUNK_CTRL]
    = ((dir << C_CFG_DIR_BIT) & C_CFG_DIR_MASK)
    | ((fifo << C_CFG_FIFO_BIT) & C_CFG_FIFO_MASK)
    | ((target_code << C_CFG_DEV_BIT) & C_CFG_DEV_MASK)
    | (1 << 7); //| ((tagcnt << C_CFG_TAG_BIT) & C_CFG_TAG_MASK);
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
  edt_Log->append(" ");
  io.tmr_timeout->stop();
  ld.status = IOS_IDLE;

  io.uart.dev->clear();
}

void CMainwin::UARTBaudRate(QString text)
{
  io.uart.dev->setBaudRate(text.toInt());
}

void CMainwin::UARTconnect(bool state)
{
  if (state)
  {
    io.uart.dev->setPort(io.uart.info->availablePorts().at(
                           tab_Dev2PC->cmb_UART_Port->currentIndex()));
    io.uart.dev->setBaudRate(tab_Dev2PC->cmb_UART_BaudRate->currentText().toInt());

    if (io.uart.dev->isOpen())
    {
      edt_Log->append(QString(tr("ERROR: port is open "))
                      + io.uart.dev->portName());
      edt_Log->append(" ");
      return;
    }

    if (io.uart.dev->open(QIODevice::ReadWrite))
    {
      edt_Log->append(QString(tr("Open: ")) + io.uart.dev->portName());
      edt_Log->append("");
      io.uart.dev->clear();
    }
    else
    {
      edt_Log->append(tr("Error"));
      edt_Log->append(" ");
    }
  }
  else
  {
    io.uart.dev->close();
//    edt_Log->append(QString(tr("Close: ")) + io.uart.dev->portName());
//    edt_Log->append(" ");
    edt_Log->clear();
  }

}


void CMainwin::getDevData()
{
  qint64 rxcount = io.uart.dev->bytesAvailable();
  if (ld.status == IOS_WR)
  {
    if (rxcount == ld.rxbuf.size.byte)
    {
      io.tmr_timeout->stop();

      if (io.uart.dev->read(ld.rxbuf.data, ld.rxbuf.size.byte) == ld.rxbuf.size.byte)
      {
        if (memcmp(ld.txbuf.data, ld.rxbuf.data, ld.rxbuf.size.byte))
          edt_Log->append(QString(tr("ERROR: bad TxACK")));

        for(size_t i = 0; i < rxcount; i++)
        edt_Log->append(QString("CFG_ACK: Data[")
                        + QString::number(i)
                        + QString("]=")
                        + QString::number((ld.rxbuf.data[i] & 0xFF), 16).toUpper());

        edt_Log->append(" ");
        ld.status = IOS_IDLE;
        io.uart.dev->clear();
      }
    }
  }
  else
    if (ld.status == IOS_RD)
    {
      if (rxcount == ld.rxbuf.size.byte)
      {
        io.tmr_timeout->stop();
        if (io.uart.dev->read(ld.rxbuf.data, ld.rxbuf.size.byte) == ld.rxbuf.size.byte)
        {
          if (memcmp(ld.txbuf.data, ld.rxbuf.data, (C_CFG_HCHUNK_COUNT * sizeof(TCfg_chunk))))
            edt_Log->append(QString(tr("ERROR: PktRD Header")));

          for(size_t i = 0; i < rxcount; i++)
          edt_Log->append(QString("CFG_ACK: Data[")
                          + QString::number(i)
                          + QString("]=")
                          + QString::number((ld.rxbuf.data[i] & 0xFF), 16).toUpper());
          edt_Log->append(" ");

          TCfg_chunk * ptr = (TCfg_chunk *) ld.rxbuf.data;
          TCfg_chunk devnum = (ptr[C_CFG_HCHUNK_CTRL] >> C_CFG_DEV_BIT) & 0xf;

          if (devnum == CFG_DEV_FRR)
          {
            quint16 *x1RIO = (quint16 *) &ptr[C_CFG_HCHUNK_DATA];
            tab_CCD->edl_x1RIO->setText(QString::number((*x1RIO & 0xffff)));
          }
          else
            if (devnum == C_CFG_DEV_FIBER)
            {
              quint16 *y1RIO = (quint16 *) &ptr[C_CFG_HCHUNK_DATA];
              tab_CCD->edl_y1RIO->setText(QString::number((*y1RIO & 0xffff)));
            }

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

  quint16 txd = !tab_CCD->chkb_SelDev->checkState()
                ? tab_CCD->edl_x2RIO->text().toUInt()
                : tab_CCD->edl_y2RIO->text().toUInt();

  if (sendCommand((!tab_CCD->chkb_SelDev->checkState() ? CFG_DEV_FRR : CFG_DEV_FIBER),
                  C_CFG_DIR_WR,
                  C_CFG_FIFO_OFF,
                  0, //Start Register Number
                  (char *) &txd,
                  sizeof(quint16)))
  {
    edt_Log->append(QString(tr("ERROR: sendCommand")));
    return;
  }

  qint64 txcount;
  txcount = io.uart.dev->write(ld.txbuf.data, ld.txbuf.size.byte);
  if (txcount == -1)
  {
    edt_Log->append(QString(tr("ERROR: io.dev / Write ")));
    return;
  }
//  else
//    edt_Log->append(QString(tr("OK: io.dev / Write ")) + QString::number(txcount));

  for(size_t i = 0; i < ld.txbuf.size.byte; i++)
  edt_Log->append("CFG_Req: Data[" + QString::number(i) + "]="
                  + QString::number((ld.txbuf.data[i] & 0xFF), 16).toUpper());

  edt_Log->append(" ");

  io.tmr_timeout->start(1000);

}

void CMainwin::getCCDRIO()
{
  if (!io.uart.dev->isOpen())
  {
    edt_Log->append(QString(tr("ERROR: UART port closed")));
    return;
  }

  if (sendCommand((!tab_CCD->chkb_SelDev->checkState() ? CFG_DEV_FRR : CFG_DEV_FIBER),
                  C_CFG_DIR_RD,
                  C_CFG_FIFO_OFF,
                  0, //Start Register Number
                  (char *) &tmp,
                  sizeof(quint16)))
  {
    edt_Log->append(QString(tr("ERROR: sendCommand")));
    return;
  }

  qint64 txcount;
  txcount = io.uart.dev->write(ld.txbuf.data, ld.txbuf.size.byte);
  if (txcount == -1)
  {
    edt_Log->append(QString(tr("ERROR: io.dev / Write ")));
    return;
  }

  for(size_t i = 0; i < ld.txbuf.size.byte; i++)
  edt_Log->append(QString("CFG_Req: Data[") + QString::number(i) + QString("]=")
                  + QString::number((ld.txbuf.data[i] & 0xFF), 16).toUpper());

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
  chkb_SelDev = new QCheckBox;

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
  RIO_GLayout->addWidget(chkb_SelDev, 6, 0, 1, 2);

  QGroupBox *grp_RIO = new QGroupBox(tr("RIO"));
  grp_RIO->setLayout(RIO_GLayout);

  QGridLayout *mainLayout = new QGridLayout;
  mainLayout->addWidget(grp_RIO, 0 ,0);


  setLayout(mainLayout);
}
