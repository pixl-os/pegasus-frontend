DEFINES *= PULSE_MAIN_HANDLED

isEmpty(PULSE_LIBS):isEmpty(PULSE_INCLUDES) {
    unix|win32-g++: {
        CONFIG += link_pkgconfig
        PKGCONFIG += libpulse
    }
    else: error("Please set PULSE_LIBS and PULSE_INCLUDES")
}
else {
    LIBS += $${PULSE_LIBS}
    INCLUDEPATH += $${PULSE_INCLUDES}
    DEPENDPATH += $${PULSE_INCLUDES}
}
