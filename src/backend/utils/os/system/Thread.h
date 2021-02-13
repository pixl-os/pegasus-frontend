#pragma once

#include <unistd.h>
#include <string>
#include "pthread.h"
typedef pthread_t ThreadHandle;

/*!
 * Abstract class which creates, starts and controls threads.
 * This class is a simple abstraction for the concept of threads and provides
 * common functionality on disparate operating environments.
 */
class Thread
{
  public:
    /*!
     * Creates a new IThread.
     */
    Thread();

    /*!
     * Releases resources held by the IThread.
     */
    virtual ~Thread();

    /*!
     * Starts the thread
     * @param name Thread's name
     */
    void Start(const std::string& name);

    /*!
     * Stops the thread
     * @param donotjoin Don't call join to wait for the effective end
     */
    void Stop();

    /*!
     * @brief Wait until thread death
     */
    void Join();

    /*!
     * Returns the running status of the thread
     * @return True if the thread is still running
     */
    bool IsRunning() const { return mIsRunning; }

    /*!
     * Returns the completion status of the thread
     * @return True if the thread has completed execution.
     */
    bool IsDone() const { return mIsDone; }

    /*!
     * @brief Get the current thread id
     * @return Current Thread ID
     */
    static int SelfId() { return (int)pthread_self(); }

    /*!
     * Allow the thread to destroy blocking resources while exiting
     */
    virtual void Break() {}

    /*!
     * Static encapsulation of delay
     * @param _100thOfSecond Delay in 100th of second
     */
    static void Sleep(int milliSecond)
    {
      usleep((useconds_t)(milliSecond * 1000));
    }

  protected:
    /*!
     * Calls the inheriting object's BeforeRun() method.
     */
    virtual void BeforeRun() {}

    /*!
     * Calls the inheriting object's Run() method.
     * @note set fIsRunning false to exit
     */
    virtual void Run() = 0;

    /*!
     * Calls the inheriting object's AfterRun() method.
     */
    virtual void AfterRun() {}

  private:
    /*!
     * Thread entry-point
     *@param thread User data (pointer to the class instance)
     */
    static void* StartThread(void* thread);

  private:
    //! Thread name
    char mName[16 + 1];
    //! Thread handle
    ThreadHandle mHandle;
    //! Thread id
    int mId;
    //! Running flag
    volatile bool mIsRunning;
    //! Completion flag
    volatile bool mIsDone;
};

