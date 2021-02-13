#pragma once

#include <utils/os/fs/Path.h>
#include <utils/datetime/DateTime.h>
#include "EventType.h"

class FileSystemEvent
{
  public:
    FileSystemEvent()
      : mWd(0),
        mMask()
    {
    }

    FileSystemEvent(int wd, EventType mask, const Path& path, const DateTime& eventTime)
      : mWd(wd),
        mMask(mask),
        mPath(path),
        mEventTime(eventTime)
    {
    }

    ~FileSystemEvent() = default;

  public:
    int mWd;
    EventType mMask;
    Path mPath;
    DateTime mEventTime;
};
