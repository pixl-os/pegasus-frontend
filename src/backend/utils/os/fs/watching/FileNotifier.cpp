#include "FileNotifier.h"

FileNotifier& FileNotifier::WatchPathRecursively(const Path& path)
{
  mInotify.WatchDirectoryRecursively(path);
  return *this;
}

FileNotifier& FileNotifier::WatchFile(const Path& file)
{
  mInotify.WatchFile(file);
  return *this;
}

FileNotifier& FileNotifier::SetEventNotifier(const EventType events, IFileSystemWatcherNotification* eventObserver)
{
  mInotify.SetEventMask(events);
  mEventNotifier = eventObserver;

  return *this;
}

FileNotifier& FileNotifier::ResetEventNotifier()
{
  mInotify.SetEventMask(EventType::None);
  mEventNotifier = nullptr;

  return *this;
}

void FileNotifier::CheckAndDispatch()
{
  FileSystemEvent fileSystemEvent;
  if (!mInotify.GetNextEvent(fileSystemEvent))
    return;

  EventType currentEvent = (EventType)fileSystemEvent.mMask;

  if ((mInotify.EventMask() & currentEvent) != 0)
  {
    if (mEventNotifier != nullptr)
      mEventNotifier->FileSystemWatcherNotification(currentEvent, fileSystemEvent.mPath, fileSystemEvent.mEventTime);
  }
}
