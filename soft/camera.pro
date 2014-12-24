#-------------------------------------------------
#
# Project created by QtCreator 2014-12-12T13:33:25
#
#-------------------------------------------------

QT       += core gui

greaterThan(QT_MAJOR_VERSION, 4): {
    QT += widgets
    QT += widgets serialport
} else {
    include($$QTSERIALPORT_PROJECT_ROOT/src/serialport/qt4support/serialport.prf)
}

TARGET = camera
TEMPLATE = app


SOURCES += main.cpp \
    mainwin.cpp \
    cfg.cpp

HEADERS  += \
    mainwin.h \
    cfg.h \
    hwi.h
