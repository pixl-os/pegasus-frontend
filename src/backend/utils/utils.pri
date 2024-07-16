#to find include files of rcheevos/libretro-common parts for QT
INCLUDEPATH += . utils/rcheevos/include
INCLUDEPATH += . utils/libretro-common/include

HEADERS += \
    $$PWD/CommandTokenizer.h \
    $$PWD/DiskCachedNAM.h \
    $$PWD/FakeQKeyEvent.h \
    $$PWD/Files.h \
    $$PWD/FolderListModel.h \
    $$PWD/HashMap.h \
    $$PWD/Http.h \
    $$PWD/IniFile.h \
    $$PWD/KeySequenceTools.h \
    $$PWD/MoveOnly.h \
    $$PWD/NoCopyNoMove.h \
    $$PWD/PathTools.h \
    $$PWD/QmlHelpers.h \
    $$PWD/rLog.h \
    $$PWD/SqliteDb.h \
    $$PWD/StdHelpers.h \
    $$PWD/StdStringHelpers.h \
    $$PWD/StrBoolConverter.h \
    $$PWD/Stringize.h \
    $$PWD/Strings.h \
    $$PWD/Unicode.h \
    $$PWD/Xml.h \
    $$PWD/Zip.h \
    $$PWD/cplusplus/Bitflags.h \
    $$PWD/cplusplus/INoCopy.h \
    $$PWD/cplusplus/StaticLifeCycleControler.h \
    $$PWD/datetime/DateTime.h \
    $$PWD/datetime/HighResolutionTimer.h \
    $$PWD/datetime/TimeSpan.h \
    $$PWD/hash/Crc32.h \
    $$PWD/hash/Crc32File.h \
    $$PWD/hash/Md5.h \
    $$PWD/locale/Internationalizer.h \
    $$PWD/locale/LocaleHelper.h \
    $$PWD/math/Misc.h \
    $$PWD/math/Transform4x4f.h \
    $$PWD/math/Vector2f.h \
    $$PWD/math/Vector2i.h \
    $$PWD/math/Vector3f.h \
    $$PWD/math/Vector4f.h \
    $$PWD/math/Vector4i.h \
    $$PWD/math/Vectors.h \
    $$PWD/os/fs/Path.h \
    $$PWD/os/fs/StringMapFile.h \
    $$PWD/os/fs/watching/EventType.h \
    $$PWD/os/fs/watching/FileNotifier.h \
    $$PWD/os/fs/watching/FileSystemEvent.h \
    $$PWD/os/fs/watching/FileSystemWatcher.h \
    $$PWD/os/fs/watching/IFileSystemWatcherNotification.h \
    $$PWD/os/system/IThreadPoolWorkerInterface.h \
    $$PWD/os/system/Mutex.h \
    $$PWD/os/system/ProcessTree.h \
    $$PWD/os/system/Thread.h \
    $$PWD/os/system/ThreadPool.h \
    $$PWD/os/system/Signal.h \
    $$PWD/storage/Allocator.h \
    $$PWD/storage/Array.h \
    $$PWD/storage/Common.h \
    $$PWD/storage/MessageFactory.h \
    $$PWD/storage/Queue.h \
    $$PWD/storage/rHashMap.h \
    $$PWD/storage/Stack.h \
    $$PWD/storage/Set.h \
    $$PWD/rcheevos/include/rc_api_request.h \
    $$PWD/rcheevos/include/rc_api_runtime.h \
    $$PWD/rcheevos/include/rc_api_user.h \
    $$PWD/rcheevos/include/rc_api_client.h \
    $$PWD/rcheevos/include/rc_api_client_raintegration.h \
    $$PWD/rcheevos/include/rc_consoles.h \
    $$PWD/rcheevos/include/rc_error.h \
    $$PWD/rcheevos/include/rc_export.h \
    $$PWD/rcheevos/include/rc_hash.h \
    $$PWD/rcheevos/include/rc_runtime.h \
    $$PWD/rcheevos/include/rc_runtime_types.h \
    $$PWD/rcheevos/include/rc_url.h \
    $$PWD/rcheevos/include/rc_util.h \
    $$PWD/rcheevos/include/rcheevos.h \
    $$PWD/rcheevos/src/rc_client_external.h \
    $$PWD/rcheevos/src/rc_client_internal.h \
    $$PWD/rcheevos/src/rc_client_ratintegration.h \
    $$PWD/rcheevos/src/rc_compat.h \
    $$PWD/rcheevos/src/rc_libretro.h \
    $$PWD/rcheevos/src/rc_version.h \
    $$PWD/rcheevos/src/rapi/rc_api_common.h \
    $$PWD/rcheevos/src/rcheevos/rc_internal.h \
    $$PWD/rcheevos/src/rhash/aes.h \
    $$PWD/rcheevos/src/rhash/md5.h \
    $$PWD/libretro-common/include/compat/strl.h \
    $$PWD/libretro-common/include/compat/posix_string.h \
    $$PWD/libretro-common/include/compat/strcasestr.h \
    $$PWD/libretro-common/include/compat/fopen_utf8.h \
    $$PWD/libretro-common/include/compat/msvc.h \
    $$PWD/libretro-common/include/encodings/utf.h \
    $$PWD/libretro-common/include/encodings/crc32.h \
    $$PWD/libretro-common/include/file/file_path.h \
    $$PWD/libretro-common/include/formats/cdfs.h \
    $$PWD/libretro-common/include/streams/chd_stream.h \
    $$PWD/libretro-common/include/streams/interface_stream.h \
    $$PWD/libretro-common/include/streams/file_stream.h \
    $$PWD/libretro-common/include/streams/trans_stream.h \
    $$PWD/libretro-common/include/streams/rzip_stream.h    \
    $$PWD/libretro-common/include/streams/memory_stream.h    \
    $$PWD/libretro-common/include/string/stdstring.h \
    $$PWD/libretro-common/include/libretro.h \
    $$PWD/libretro-common/include/retro_common.h \
    $$PWD/libretro-common/include/retro_common_api.h \
    $$PWD/libretro-common/include/retro_inline.h \
    $$PWD/libretro-common/include/retro_miscellaneous.h \
    $$PWD/libretro-common/include/retro_endianness.h \
    $$PWD/libretro-common/include/memmap.h \
    $$PWD/libretro-common/include/memalign.h \
    $$PWD/libretro-common/include/boolean.h \
    $$PWD/libretro-common/include/retro_assert.h \
    $$PWD/libretro-common/include/retro_math.h \
    $$PWD/libretro-common/include/retro_timers.h \
    $$PWD/libretro-common/include/retro_dirent.h \
    $$PWD/libretro-common/include/retro_environment.h \
    $$PWD/libretro-common/include/time/rtime.h \
    $$PWD/libretro-common/include/rthreads/rthreads.h \
    $$PWD/libretro-common/include/vfs/vfs.h \
    $$PWD/libretro-common/include/vfs/vfs_implementation.h \
    $$PWD/libretro-common/include/vfs/vfs_implementation_cdrom.h \
    $$PWD/libretro-common/include/cdrom/cdrom.h \
    $$PWD/libretro-common/include/libchdr/chd.h \
    $$PWD/libretro-common/include/libchdr/coretypes.h \
    $$PWD/libretro-common/include/lists/dir_list.h \
    $$PWD/libretro-common/include/lists/file_list.h \
    $$PWD/libretro-common/include/lists/string_list.h \
    $$PWD/liboping/src/config.h \
    $$PWD/liboping/src/oping.h
    
SOURCES += \
    $$PWD/CommandTokenizer.cpp \
    $$PWD/DiskCachedNAM.cpp \
    $$PWD/FakeQKeyEvent.cpp \
    $$PWD/Files.cpp \
    $$PWD/FolderListModel.cpp \
    $$PWD/Http.cpp \
    $$PWD/IniFile.cpp \
    $$PWD/KeySequenceTools.cpp \
    $$PWD/PathTools.cpp \
    $$PWD/rLog.cpp \
    $$PWD/SqliteDb.cpp \
    $$PWD/StdStringHelpers.cpp \
    $$PWD/StrBoolConverter.cpp \
    $$PWD/Strings.cpp \
    $$PWD/Zip.cpp \
    $$PWD/datetime/DateTime.cpp \
    $$PWD/datetime/TimeSpan.cpp \
    $$PWD/hash/Crc32.cpp \
    $$PWD/hash/Crc32File.cpp \
    $$PWD/hash/Md5.cpp \
    $$PWD/locale/Internationalizer.cpp \
    $$PWD/math/Misc.cpp \
    $$PWD/math/Transform4x4f.cpp \
    $$PWD/math/Vector2f.cpp \
    $$PWD/math/Vector2i.cpp \
    $$PWD/math/Vector3f.cpp \
    $$PWD/math/Vector4f.cpp \
    $$PWD/math/Vector4i.cpp \
    $$PWD/os/fs/Path.cpp \
    $$PWD/os/fs/StringMapFile.cpp \
    $$PWD/os/fs/watching/EventType.cpp \
    $$PWD/os/fs/watching/FileNotifier.cpp \
    $$PWD/os/fs/watching/FileSystemWatcher.cpp \
    $$PWD/os/system/Mutex.cpp \
    $$PWD/os/system/ProcessTree.cpp \
    $$PWD/os/system/Signal.cpp \
    $$PWD/os/system/Thread.cpp \
    $$PWD/rcheevos/src/rc_client.c \
    $$PWD/rcheevos/src/rc_client_raintegration.c \
    $$PWD/rcheevos/src/rc_compat.c \
    $$PWD/rcheevos/src/rc_libretro.c \
    $$PWD/rcheevos/src/rc_util.c \
    $$PWD/rcheevos/src/rc_version.c \
    $$PWD/rcheevos/src/rapi/rc_api_common.c \
    $$PWD/rcheevos/src/rapi/rc_api_runtime.c \
    $$PWD/rcheevos/src/rcheevos/alloc.c \
    $$PWD/rcheevos/src/rcheevos/condition.c \
    $$PWD/rcheevos/src/rcheevos/condset.c \
    $$PWD/rcheevos/src/rcheevos/consoleinfo.c \
    $$PWD/rcheevos/src/rcheevos/format.c \
    $$PWD/rcheevos/src/rcheevos/lboard.c \
    $$PWD/rcheevos/src/rcheevos/memref.c \
    $$PWD/rcheevos/src/rcheevos/operand.c \
    $$PWD/rcheevos/src/rcheevos/richpresence.c \
    $$PWD/rcheevos/src/rcheevos/runtime.c \
    $$PWD/rcheevos/src/rcheevos/runtime_progress.c \
    $$PWD/rcheevos/src/rcheevos/trigger.c \
    $$PWD/rcheevos/src/rcheevos/value.c \
    $$PWD/rcheevos/src/rhash/aes.c \
    $$PWD/rcheevos/src/rhash/cdreader.c \
    $$PWD/rcheevos/src/rhash/hash.c \    
    $$PWD/rcheevos/src/rhash/md5.c \
    $$PWD/rcheevos/src/rurl/url.c \
    $$PWD/libretro-common/compat/compat_strl.c \
    $$PWD/libretro-common/compat/compat_posix_string.c \
    $$PWD/libretro-common/compat/compat_strcasestr.c \
    $$PWD/libretro-common/compat/fopen_utf8.c \
    $$PWD/libretro-common/encodings/encoding_utf.c \
    $$PWD/libretro-common/encodings/encoding_crc32.c \
    $$PWD/libretro-common/formats/cdfs/cdfs.c \
    $$PWD/libretro-common/string/stdstring.c \
    $$PWD/libretro-common/file/file_path.c \
    $$PWD/libretro-common/file/retro_dirent.c \
    $$PWD/libretro-common/time/rtime.c \
    $$PWD/libretro-common/rthreads/rthreads.c \
    $$PWD/libretro-common/streams/chd_stream.c \
    $$PWD/libretro-common/streams/interface_stream.c \
    $$PWD/libretro-common/streams/file_stream.c \
    $$PWD/libretro-common/streams/memory_stream.c \
    $$PWD/libretro-common/streams/trans_stream.c \
    $$PWD/libretro-common/streams/rzip_stream.c \
    $$PWD/libretro-common/vfs/vfs_implementation.c \
    $$PWD/libretro-common/vfs/vfs_implementation_cdrom.c \
    $$PWD/libretro-common/cdrom/cdrom.c \
    $$PWD/libretro-common/lists/dir_list.c \
    $$PWD/libretro-common/lists/file_list.c \
    $$PWD/libretro-common/lists/string_list.c \
    $$PWD/libretro-common/lists/vector_list.c \
    $$PWD/libretro-common/memmap/memmap.c \
    $$PWD/libretro-common/memmap/memalign.c \
    $$PWD/liboping/src/liboping.c \
    $$PWD/liboping/src/oping.c
    
    

!isEmpty(USE_SDL_GAMEPAD) {
    HEADERS += $$PWD/sdl2/ISynchronousEvent.h
    HEADERS += $$PWD/sdl2/ISyncTimer.h
    HEADERS += $$PWD/sdl2/SyncronousEvent.h
    HEADERS += $$PWD/sdl2/SyncronousEventService.h
    HEADERS += $$PWD/sdl2/SyncTimer.h

    SOURCES += $$PWD/sdl2/SyncronousEvent.cpp
    SOURCES += $$PWD/sdl2/SyncronousEventService.cpp
    SOURCES += $$PWD/sdl2/SyncTimer.cpp
} 

    
