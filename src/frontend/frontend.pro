TEMPLATE = lib

QT += qml quick
CONFIG += c++17 staticlib warn_on exceptions rtti_off qtquickcompiler
DEFINES *= $${COMMON_DEFINES}

RESOURCES += \
    ./frontend.qrc \
    ../qmlutils/qmlutils.qrc
