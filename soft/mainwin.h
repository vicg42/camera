#ifndef MAINWIN_H
#define MAINWIN_H

#include <QDialog>
#include <QtSerialPort/QSerialPort>
#include <QTextEdit>
#include <QTabWidget>
#include <QComboBox>
#include <QPushButton>
#include <QTimer>

typedef quint8 TCfg_chunk;
typedef quint8 u8;

#define EER_INVAL    -1
#define EER_NOBUFS   -2
#define EER_TIMEOUT  -3

typedef enum { IOS_IDLE, IOS_WR, IOS_RD } TIOStatus;

/** Configurable subsystems (destinations/sources) */

typedef enum
{
  CFG_DEV_FRR     // "Fiber Routing Rules" (switcher)
, CFG_DEV_FIBER
, CFG_DEV_FG      // "Frame Grabber" (vctrl)
, CFG_DEV_TIMER

} TCFGTarget;


class CDev2PC_tab : public QWidget
{
  Q_OBJECT

public:
  explicit CDev2PC_tab (QWidget *parent = 0);

  QComboBox *cmb_UART_BaudRate;
  QComboBox *cmb_UART_Port;
  QPushButton *btn_UART_connect;
};


class CCCD_tab : public QWidget
{
  Q_OBJECT

public:
  explicit CCCD_tab (QWidget *parent = 0);

  QLineEdit *edl_x1RIO;
  QLineEdit *edl_y1RIO;
  QLineEdit *edl_x2RIO;
  QLineEdit *edl_y2RIO;
  QPushButton *btn_setRIO;
  QPushButton *btn_getRIO;
};


class CMainwin : public QDialog
{
  Q_OBJECT

public:
  CMainwin(QWidget *parent = 0);
  ~CMainwin();

private:
  QTabWidget *tab_Ctrl;
  QTextEdit *edt_Log;
  CDev2PC_tab *tab_Dev2PC;
  CCCD_tab *tab_CCD;

  size_t tagcnt;

  struct SDev
  {
    struct SUART
    {
      QSerialPort *dev;
      QSerialPortInfo *info;
    } uart;
    QTimer *tmr_timeout;
  } io;

  struct TLocal_data
  {
    struct TTxBuf
    {
      char * data;
      size_t bsize;
    } txbuf;

    struct TRxBuf
    {
      char * data;
      size_t bsize;
    } rxbuf;

    size_t req_bsize;
    size_t tag_tx;

    TIOStatus status;
    int error;
  } ld;

public slots:
  void connectUART(bool state);
  void getDevData();
  void setCCDRIO();
  void DevAckTimeout();
  void getCCDRIO();

  int sendCommand( TCFGTarget target,
                    char dir,
                    char fifo,
                    size_t areg,
                    char * data,
                    size_t bcount
                    );

};

#endif // MAINWIN_H
