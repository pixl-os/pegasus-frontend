#pragma once

#include <utils/cplusplus/Bitflags.h>
#include <sys/inotify.h>
#include <string>

enum class EventType : unsigned int
{
  None = 0,
  Access = IN_ACCESS,
  Attrib = IN_ATTRIB,
  CloseWrite = IN_CLOSE_WRITE,
  CloseNowrite = IN_CLOSE_NOWRITE,
  Close = IN_CLOSE,
  Create = IN_CREATE,
  Remove = IN_DELETE,
  RemoveSelf = IN_DELETE_SELF,
  Modify = IN_MODIFY,
  MoveSelf = IN_MOVE_SELF,
  MovedFrom = IN_MOVED_FROM,
  MovedTo = IN_MOVED_TO,
  Move = IN_MOVE,
  Open = IN_OPEN,
  IsDir = IN_ISDIR,
  Unmount = IN_UNMOUNT,
  QOverflow = IN_Q_OVERFLOW,
  Ignored = IN_IGNORED,
  Oneshot = IN_ONESHOT,
  All = IN_ALL_EVENTS
};

std::string& operator <<(std::string& stream, const EventType& event);

DEFINE_BITFLAG_ENUM(EventType, unsigned int)