#pragma once

#include "FileSystemWatcher.h"
#include "IFileSystemWatcherNotification.h"

class FileNotifier
{
  private:
    //! Underlying file watcher
    FileSystemWatcher mInotify;

    //! Notification interface
    IFileSystemWatcherNotification* mEventNotifier;

  public:
    /*!
     * @brief Default constructor
     */
    FileNotifier()
      : mInotify(),
        mEventNotifier(nullptr)
    {
    }

    /*!
     * @brief Check event and call Notifiers
     */
    void CheckAndDispatch();

    /*!
     * @brief Watch recursively all files starting from the given path
     * @param path Path to recurse in
     * @return Itself
     */
    FileNotifier& WatchPathRecursively(const Path& path);

    /*!
     * @brief Watch a single file
     * @param file File ot watch
     * @return Itself
     */
    FileNotifier& WatchFile(const Path& file);

    /*!
     * @brief Reset notifiers and events
     * @return Itself
     */
    FileNotifier& ResetEventNotifier();

    /*!
     * @brief Set event to watch and notifier interface
     * @param event Events to notify
     * @param notify Notification interface
     * @return Itself
     */
    FileNotifier& SetEventNotifier(EventType event, IFileSystemWatcherNotification* notify);
};


