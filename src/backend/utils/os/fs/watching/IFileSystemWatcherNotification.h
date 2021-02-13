#pragma once

#include <utils/os/fs/Path.h>
#include <utils/datetime/DateTime.h>
#include "EventType.h"

class IFileSystemWatcherNotification
{
  public:
    virtual void FileSystemWatcherNotification(EventType event, const Path& path, const DateTime& time) = 0;
};