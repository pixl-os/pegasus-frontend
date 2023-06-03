REQ_QT_MAJOR = 5
REQ_QT_MINOR = 15

# FIXME: pixL have qt6.4.2 but pegasus need qt5.15.8 force version for cohabitation
QML_IMPORT_MAJOR_VERSION = 5
QML_IMPORT_MINOR_VERSION = 15

lessThan(QT_MAJOR_VERSION, $${REQ_QT_MAJOR}) | lessThan(QT_MINOR_VERSION, $${REQ_QT_MINOR}) {
    message("Cannot build this project using Qt $$[QT_VERSION]")
    error("This project requires at least Qt $${REQ_QT_MAJOR}.$${REQ_QT_MINOR} or newer")
}


TEMPLATE = subdirs
SUBDIRS += src thirdparty
OTHER_FILES += .qmake.conf

src.depends = thirdparty

# FIXME: MAke sure the QT options of Backend inherit to the dependers
qtHaveModule(testlib):!android {
    SUBDIRS += tests
    tests.depends = src
    tests.CONFIG = no_default_install
}

# Translations
TRANSLATIONS = lang/pegasus_ar.ts lang/pegasus_bs.ts lang/pegasus_de.ts lang/pegasus_en.ts lang/pegasus_en-GB.ts \
               lang/pegasus_es.ts lang/pegasus_fr.ts lang/pegasus_hu.ts lang/pegasus_ko.ts lang/pegasus_nl.ts \
               lang/pegasus_pt-BR.ts lang/pegasus_ru.ts lang/pegasus_zh.ts lang/pegasus_zh-TW.ts


include($${TOP_SRCDIR}/src/deployment_vars.pri)
include($${TOP_SRCDIR}/src/print_config.pri)
