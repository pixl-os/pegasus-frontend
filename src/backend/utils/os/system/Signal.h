//
// Created by bkg2k on 28/12/2020.
//
// As part of the RECALBOX Project
// http://www.recalbox.com
//

#pragma once

#include <utils/os/system/Mutex.h>

class Signal
{
  public:
    //! Constructor
    Signal();

    //! Destructor
    ~Signal();

    /*!
     * Send a signal to any thread waiting for the signal
     * @return True if the operation is successful
     */
    void Fire();

    /*!
     * Wait for the signal to be send
     * @return True if the operation is successful
     */
    void WaitSignal();

    /*!
     * Wait for the signal to be send with timeout
     * @param timeout in milliseconds
     * @return True if the operation is successful
     */
    bool WaitSignal(long long milliseconds);

    /*!
     * @brief Force a manuel signal reset
     */
    void Reset();

  private:
    //! Mutex handle
    pthread_mutex_t mMutex;
    //! Signal handle
    pthread_cond_t mCondition;
    //! Signal
    bool mSignal;
};



