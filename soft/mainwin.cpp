#include <QtWidgets>
#include "mainwin.h"
#include <QtSerialPort/QSerialPortInfo>
#include "hwi.h"

CMainwin::CMainwin(QWidget *parent)
    : QDialog(parent)
{

  setWindowTitle(tr("Camera Ctrl"));

  io.protocol = new CCfg;
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
  delete io.protocol;
}


void CMainwin::parseRxDATA(char *data, int count)
{
//  switch (io.srcrq)
//  {
//    case UGUI_CCDRIO :
//      {

//        break;
//      }

//    default:
//      break;
//  }
}

void CMainwin::getCCDRIO()
{
  if (!io.uart.dev->isOpen())
  {
    edt_Log->append(QString(tr("ERROR: UART port closed")));
    return;
  }

  int error = io.protocol->setReq(LSD_CFG_DIR_RD,
                                  CFG_DEV_FG,
                                  0,
                                  0,
                                  0,
                                  0);

  if (error)
  {
    edt_Log->append(QString(tr("ERROR: io.protocol / make write paket")));
    return;
  }

  if (io.uart.dev->write(io.protocol->getTxBuf(), io.protocol->getTxCount())
      != io.protocol->getTxCount())
  {
    edt_Log->append(QString(tr("ERROR: io.dev / Write")));
    return;
  }
  io.srcrq = UGUI_CCDRIO;
  io.tmr_timeout->start(1000);

}

void CMainwin::DevAckTimeout()
{
  edt_Log->append(tr("ERROR: ACK Timeout "));
  io.protocol->AckTimeout();
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
  io.tmr_timeout->stop();

  size_t rxcount = io.protocol->getRxCount();
  int ack = 0;

  if ((io.protocol->getState() == IOS_WR)
      | (io.protocol->getState() == IOS_RD))
  {
    if (io.uart.dev->bytesAvailable() == rxcount)
    {
      io.uart.dev->read(io.protocol->setRxBuf(rxcount), rxcount);

      ack = io.protocol->chkACK();
      if (ack <= 0)
        edt_Log->append(QString("ERROR: Bad ACK"));
    }
    if (io.protocol->getState() == IOS_RD)
    {
      parseRxDATA(io.protocol->getRxPayload(), ack);
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

  int error = io.protocol->setReq(LSD_CFG_DIR_RD,
                                  CFG_DEV_FG,
                                  0,
                                  0,
                                  (char *) &txd,
                                  sizeof(quint16));

  if (error)
  {
    edt_Log->append(QString(tr("ERROR: io.protocol / make write paket")));
    return;
  }

  if (io.uart.dev->write(io.protocol->getTxBuf(), io.protocol->getTxCount())
      != io.protocol->getTxCount())
  {
    edt_Log->append(QString(tr("ERROR: io.dev / Write")));
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
