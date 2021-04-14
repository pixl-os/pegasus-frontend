HEADERS += \
    $$PWD/Board.h \
    $$PWD/BoardType.h \
    $$PWD/IBoardInterface.h \
    $$PWD/boards/NullBoard.h \
    $$PWD/boards/pc/PcComputers.h \
    $$PWD/messaging/HardwareMessage.h \
    $$PWD/messaging/HardwareMessageSender.h \
    $$PWD/messaging/IHardwareNotifications.h \
    $$PWD/messaging/MessageTypes.h
    
SOURCES += \
    $$PWD/Board.cpp \
    $$PWD/boards/NullBoard.cpp \
    $$PWD/boards/pc/PcComputers.cpp \
    $$PWD/messaging/HardwareMessageSender.cpp
    