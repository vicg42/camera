#include "mainwin.h"
#include <QApplication>

int main(int argc, char *argv[])
{
    QApplication a(argc, argv);

    CMainwin mainwin;

    mainwin.setGeometry(200, 200, 400, 300);
    mainwin.show();

    return a.exec();
}
