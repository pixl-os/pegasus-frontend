#include "FileSystemWatcher.h"
#include "utils/rLog.h"
#include "IFileSystemWatcherNotification.h"

#include <string>
#include <sys/epoll.h>
#include <zconf.h>
#include <cstring>

FileSystemWatcher::FileSystemWatcher()
  : mEventBuffer(),
    mEventQueue(),
    mDirectorieMap(),
    mEpollEvents(),
    mInotifyEpollEvent(),
    mEventMask(EventType::All),
    mInotifyFd(0),
    mEpollFd(0),
    mPipeReadIdx(0),
    mPipeWriteIdx(1)
{
  mInotifyFd = inotify_init1(IN_NONBLOCK);
  if (mInotifyFd == -1)
    LOG(LogError) << "Can't initialize inotify ! " << strerror(errno) << ".";

  mEpollFd = epoll_create1(0);
  if (mEpollFd == -1)
    LOG(LogError) << "Can't initialize epoll ! " << strerror(errno) << ".";

  mInotifyEpollEvent.events = EPOLLIN | EPOLLET;
  mInotifyEpollEvent.data.fd = mInotifyFd;
  if (epoll_ctl(mEpollFd, EPOLL_CTL_ADD, mInotifyFd, &mInotifyEpollEvent) == -1)
    LOG(LogError) << "Can't add inotify filedescriptor to epoll ! " << strerror(errno) << ".";
}

FileSystemWatcher::~FileSystemWatcher()
{
  epoll_ctl(mEpollFd, EPOLL_CTL_DEL, mInotifyFd, nullptr);

  if (close(mInotifyFd) != 0)
    LOG(LogError) << "Error closing notify fd.";

  if (close(mEpollFd) != 0)
    LOG(LogError) << "Error closing poll fd.";
}

void FileSystemWatcher::WatchDirectoryRecursively(const Path& path)
{
  if (path.Exists())
  {
    WatchFile(path);
    if (path.IsDirectory())
    {
      Path::PathList list = path.GetDirectoryContent();
      for (const Path& p : list)
        WatchDirectoryRecursively(p);
    }
  }
  else
    LOG(LogError) << "Can´t watch Path! Path does not exist. Path: " + path.ToString();
}

void FileSystemWatcher::WatchFile(const Path& file)
{
  if (file.Exists())
  {
    int wd = inotify_add_watch(mInotifyFd, file.ToChars(), (int)mEventMask);

    if (wd == -1)
    {
      int Error = errno;
      if (Error == 28)
        LOG(LogError) << "Failed to watch! " << strerror(Error) << ". Please increase number of watches in "
                         "\"/proc/sys/fs/inotify/max_user_watches\".";

      LOG(LogError) << "Failed to watch! " << strerror(Error) << ". Path: " << file.ToString();
    }
    mDirectorieMap.insert({wd, file });
  }
  else
    LOG(LogError) << "Can´t watch Path! Path does not exist. Path: " << file.ToString();
}

bool FileSystemWatcher::GetNextEvent(FileSystemEvent& fsevent)
{
  std::vector<FileSystemEvent> newEvents;

  int length = readEventsIntoBuffer();
  if (length != 0)
  {
    readEventsFromBuffer(length, newEvents);
    filterEvents(newEvents);
  }

  if (!mEventQueue.empty())
  {
    fsevent = mEventQueue.front();
    mEventQueue.pop();
    return true;
  }
  return false;
}

ssize_t FileSystemWatcher::readEventsIntoBuffer()
{
  ssize_t length = 0;
  length = 0;
  int timeout = 0;
  int nFdsReady = epoll_wait(mEpollFd, mEpollEvents, MAX_EPOLL_EVENTS, timeout);

  if (nFdsReady == -1)
    return length;

  for (int n = 0; n < nFdsReady; ++n)
  {
    //if (mEpollEvents[n].data.fd == mStopPipeFd[mPipeReadIdx]) break;

    length = read(mEpollEvents[n].data.fd, mEventBuffer, sizeof(mEventBuffer));
    if (length == -1 && errno == EINTR)
      break;
  }

  return length;
}

void FileSystemWatcher::readEventsFromBuffer(int length, std::vector<FileSystemEvent>& events)
{
  int i = 0;
  while (i < length)
  {
    inotify_event* event = ((struct inotify_event*) &mEventBuffer[i]);

    if ((event->mask & IN_IGNORED) != 0u)
    {
      i += (int)(EVENT_SIZE + event->len);
      mDirectorieMap.erase(event->wd);
      continue;
    }

    Path path = wdToPath(event->wd) / std::string(event->len != 0 ? event->name : "");
    if (!path.IsEmpty())
    {
      if (path.IsDirectory())
        event->mask |= IN_ISDIR;
      FileSystemEvent fsEvent(event->wd, (EventType) event->mask, path, DateTime());

      if (!fsEvent.mPath.IsEmpty())
        events.push_back(fsEvent); // else Event is not complete --> ignore
    }
    i += (int)(EVENT_SIZE + event->len);
  }
}

void FileSystemWatcher::filterEvents(std::vector<FileSystemEvent>& events)
{
  for (const FileSystemEvent& currentEvent : events)
    mEventQueue.push(currentEvent);
}

