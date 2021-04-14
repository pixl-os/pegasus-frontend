#pragma once

#include <pthread.h>

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
     * @brief Autolock class
     */
    class AutoLock
    {
      private:
        //! Mutex to use
        Mutex& mMutex;

      public:
        /*!
         * @brief Build an autolock instance based and the given mutex, then lock the mutex
         * @param mutex Mutex to use
         */
        explicit AutoLock(Mutex& mutex)
          : mMutex(mutex)
        {
          mMutex.Lock();
        }

        /*!
         * @brief Unlock the given mutex on destruction
         */
        ~AutoLock()
        {
          mMutex.UnLock();
        }
    };

  private:
    //! Mutex handle
    pthread_mutex_t mMutex;
};
