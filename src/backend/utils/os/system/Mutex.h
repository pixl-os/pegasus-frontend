#pragma once

#include <pthread.h>
typedef pthread_mutex_t OSMutex;

/*!
 * Simple encapsulation of unix's mutex and signal
 */
class Mutex
{
  public:
    //! Initializes a new instance of the CMutex class.
    Mutex();

    //! Releases any ressources held by the mutex.
    ~Mutex();

    /*!
     * Acquires the mutex. If the mutex is currently held by another thread,
     * this call blocks and wait until the mutex becomes available.
     * @return True if the operation is successful
     */
    bool Lock();

    // Releases the mutex.
    /*!
     * Release the muex. If another thread is blocking on a Lock()
     * it will be allowed to aquire the mutex.
     * @return True if the operation is successful
     */
    bool UnLock();

    /*!
     * Send a signal to any thread waiting for the signal
     * @return True if the operation is successful
     */
    bool Signal();

    /*!
     * Wait for the signal to be send
     * @return True if the operation is successful
     */
    bool WaitSignal();

    /*!
     * Wait for the signal to be send with timeout
     * @param timeout in milliseconds
     * @return True if the operation is successful
     */
    bool WaitSignal(long long milliseconds);

  private:
    //! Mutex handle
    OSMutex mMutex;
    //! Signal handle
    pthread_cond_t mCondition;
};
