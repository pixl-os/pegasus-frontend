/*! File watching, inspired from the Inotofy library from Erik Zenker */

#pragma once

#include <utils/storage/rHashMap.h>
#include <queue>
#include <sys/inotify.h>
#include <sys/epoll.h>
#include <vector>

#include "FileSystemEvent.h"

/*!
 * @eventMask
 *
 * IN_ACCESS         File was accessed (read) (*).
 * IN_ATTRIB         Metadata changed—for example, permissions,
 *                   timestamps, extended attributes, link count
 *                   (since Linux 2.6.25), UID, or GID. (*).
 * IN_CLOSE_WRITE    File opened for writing was closed (*).
 * IN_CLOSE_NOWRITE  File not opened for writing was closed (*).
 * IN_CREATE         File/directory created in watched directory(*).
 * IN_DELETE         File/directory deleted from watched directory(*).
 * IN_DELETE_SELF    Watched file/directory was itself deleted.
 * IN_MODIFY         File was modified (*).
 * IN_MOVE_SELF      Watched file/directory was itself moved.
 * IN_MOVED_FROM     Generated for the directory containing the old
 *                   filename when a file is renamed (*).
 * IN_MOVED_TO       Generated for the directory containing the new
 *                   filename when a file is renamed (*).
 * IN_OPEN           File was opened (*).
 * IN_ALL_EVENTS     macro is defined as a bit mask of all of the above
 *                   events
 * IN_MOVE           IN_MOVED_FROM|IN_MOVED_TO
 * IN_CLOSE          IN_CLOSE_WRITE | IN_CLOSE_NOWRITE
 *
 * See inotify manpage for more event details
 *
 */

class FileSystemWatcher
{
  public:
    /*!
     * @brief Default constructor
     */
    FileSystemWatcher();

    /*!
     * @brief Default destructor
     */
    ~FileSystemWatcher();

    /*!
     * @brief Recursively add every single file from the given path to the watch list
     * @param path Path to watch
     */
    void WatchDirectoryRecursively(const Path& path);

    /*!
     * @brief Add a single file to the watch list
     * @param file File to watch
     */
    void WatchFile(const Path& file);

    /*!
     * @brief Set the event we want to be notified of
     * @param eventMask events
     */
    void SetEventMask(EventType eventMask) { mEventMask = eventMask; }

    /*!
     * @brief Get events to be notified of
     * @return events
     */
    EventType EventMask() const { return mEventMask; }

    /*!
     * @brief Get next event if any
     * @param fsevent Event structure filled in with the next event if available
     * @return True if the fsevent structure has been filled with a valid event, false otherwise
     */
    bool GetNextEvent(FileSystemEvent& fsevent);

  private:
    //! Max events
    static constexpr int MAX_EVENTS = 256;
    //! Max polled event at once
    static constexpr int MAX_EPOLL_EVENTS = 1;
    //! Event structure size
    static constexpr int EVENT_SIZE = (int) (sizeof(inotify_event));

    /*!
     * @brief Return a path from a "wd" identifier
     * @param wd Identifier
     * @return Path
     */
    Path wdToPath(int wd) const { Path* found = mDirectorieMap.try_get(wd); return found != nullptr ? *found : Path::Empty; }

    /*!
     * @brief Read available events if any and return read size
     * @return Read size
     */
    ssize_t readEventsIntoBuffer();

    /*!
     * @brief Convert raw events to event structures
     * @param length
     * @param events
     */
    void readEventsFromBuffer(int length, std::vector<FileSystemEvent>& events);

    /*!
     * @brief Filter events
     * @param events events ot filter
     */
    void filterEvents(std::vector<FileSystemEvent>& events);

  private:
    unsigned char mEventBuffer[MAX_EVENTS * (EVENT_SIZE + 16)];
    std::queue<FileSystemEvent> mEventQueue;
    rHashMap<int, Path> mDirectorieMap;

    epoll_event mEpollEvents[MAX_EPOLL_EVENTS];
    epoll_event mInotifyEpollEvent;

    EventType mEventMask;
    int mInotifyFd;
    int mEpollFd;
    const int mPipeReadIdx;
    const int mPipeWriteIdx;
};
