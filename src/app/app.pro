TARGET = pegasus-fe
CONFIG += c++17 warn_on exceptions rtti_off debug

SOURCES += main.cpp
DEFINES *= $${COMMON_DEFINES}

RESOURCES += "$${TOP_SRCDIR}/assets/assets.qrc"
OTHER_FILES += qmlplugins.qml


# Linking

include($${TOP_SRCDIR}/src/link_to_backend.pri)
include($${TOP_SRCDIR}/src/link_to_frontend.pri)


# Translations

EXTRA_TRANSLATIONS = $$files($${TOP_SRCDIR}/lang/pegasus_*.ts)
CONFIG += lrelease embed_translations


# Deployment

include(install.pri)
