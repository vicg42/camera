#ifndef MAINWIN_H
#define MAINWIN_H

#include <QDialog>
#include <QtSerialPort/QSerialPort>
#include <QTextEdit>
#include <QTabWidget>
#include <QComboBox>
#include <QPushButton>
#include <QTimer>
#include "cfg.h"

typedef enum
{
  UGUI_CCDRIO
} TSrcRq;

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

  struct SDev {
    struct SUART {
      QSerialPort *dev;
      QSerialPortInfo *info;
    } uart;
    QTimer *tmr_timeout;
    CCfg *protocol;
    TSrcRq srcrq;
  } io;


public slots:
  void connectUART(bool state);
  void getDevData();
  void setCCDRIO();
  void DevAckTimeout();
  void getCCDRIO();
  void parseRxDATA(char *data, int count);

};

#endif // MAINWIN_H
