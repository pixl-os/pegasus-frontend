DEFINES *= ZIP_MAIN_HANDLED

isEmpty(ZIP_LIBS):isEmpty(ZIP_INCLUDES) {
    unix|win32-g++: {
        CONFIG += link_pkgconfig
        PKGCONFIG += libzip
    }
    else: error("Please set ZIP_LIBS and ZIP_INCLUDES")
}
else {
    LIBS += $${ZIP_LIBS}
    INCLUDEPATH += $${ZIP_INCLUDES}
    DEPENDPATH += $${ZIP_INCLUDES}
}
