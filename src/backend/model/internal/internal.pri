HEADERS += \
    $$PWD/Gamepad.h \
    $$PWD/GamepadManager.h \
    $$PWD/GamepadManagerBackend.h \
    $$PWD/Internal.h \
    $$PWD/Meta.h \
    $$PWD/System.h

SOURCES += \
    $$PWD/Gamepad.cpp \
    $$PWD/GamepadManager.cpp \
    $$PWD/GamepadManagerBackend.cpp \
    $$PWD/Internal.cpp \
    $$PWD/Meta.cpp \
    $$PWD/System.cpp

!isEmpty(USE_SDL_GAMEPAD) {
    HEADERS += $$PWD/GamepadManagerSDL2.h
    SOURCES += $$PWD/GamepadManagerSDL2.cpp
} else {
    HEADERS += $$PWD/GamepadManagerQt.h
    SOURCES += $$PWD/GamepadManagerQt.cpp
}

include(settings/settings.pri)
include(netplay/netplay.pri)
include(singleplay/singleplay.pri)
include(updates/updates.pri)
include(bios/bios.pri)


