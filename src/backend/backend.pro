TEMPLATE = lib

QT += core qml quick sql xml
CONFIG += c++17 staticlib warn_on exceptions debug
android: QT += androidextras

!isEmpty(USE_SDL_GAMEPAD)|!isEmpty(USE_SDL_POWER): include($${TOP_SRCDIR}/thirdparty/link_to_sdl.pri)

isEmpty(USE_SDL_GAMEPAD): QT += gamepad

!isEmpty(NO_LEGACY_SDL): DEFINES *= WITHOUT_LEGACY_SDL

!isEmpty(INSIDE_FLATPAK): DEFINES *= PEGASUS_INSIDE_FLATPAK
msvc: DEFINES *= _USE_MATH_DEFINES

#for libcheevos (without FLAC due to issue of compatibility - seems not used for CHD decompression for hashing)
DEFINES *= HAVE_CDROM
DEFINES *= HAVE_CHD
DEFINES *= HAVE_ZLIB
DEFINES *=_7ZIP_ST
DEFINES *= HAVE_7ZIP

SOURCES += \
    Backend.cpp \
    DownloadManager.cpp \
    FrontendLayer.cpp \
    GamepadAxisNavigation.cpp \
    HttpServer.cpp \
    PegasusAssets.cpp \
    ProcessLauncher.cpp \
    ScriptRunner.cpp \
    Paths.cpp \
    AppSettings.cpp \
    Log.cpp \
    GamepadButtonNavigation.cpp \
    RecalboxConf.cpp \
    RootFolders.cpp \
    ScriptManager.cpp \
    RecalboxSystem.cpp

HEADERS += \
    Backend.h \
    CliArgs.h \
    DownloadManager.h \
    FrontendLayer.h \
    GamepadAxisNavigation.h \
    HttpServer.h \
    PegasusAssets.h \
    ProcessLauncher.h \
    ScriptRunner.h \
    Paths.h \
    AppSettings.h \
    Log.h \
    GamepadButtonNavigation.h \
    RecalboxConf.h \
    RootFolders.h \
    ScriptManager.h \
    KeyEmitter.h \
    RecalboxSystem.h

include(imggen/imggen.pri)
include(model/model.pri)
include(parsers/parsers.pri)
include(platform/platform.pri)
include(providers/providers.pri)
include(types/types.pri)
include(utils/utils.pri)
include(audio/audio.pri)
include(hardware/hardware.pri)
include(storage/storage.pri)
# include(mount/mount.pri)


DEFINES *= $${COMMON_DEFINES}

include($${TOP_SRCDIR}/thirdparty/thirdparty.pri)
include($${TOP_SRCDIR}/thirdparty/link_to_pulse.pri)
include($${TOP_SRCDIR}/thirdparty/link_to_zip.pri)

