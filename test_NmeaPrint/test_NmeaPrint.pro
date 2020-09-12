QT += testlib
QT += gui
CONFIG += warn_on qmltestcase
TEMPLATE = app
SOURCES += tst_NmeaPrint.cpp
QUICK_TEST_SOURCE_DIR = ../NmeaPrint/componets
RESOURCES += ../NmeaPrint/qml.qrc

DISTFILES += \
    qml/tst_SatellitesMap.qml
