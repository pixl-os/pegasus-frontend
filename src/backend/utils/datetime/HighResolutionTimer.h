//
// Created by bkg2k on 16/05/19.
//

#pragma once

#include <ctime>

class HighResolutionTimer
{
  private:
    //! Current couting reference
    long long mReference;

    /*!
     * @brief Get current absolute timer
     * @return absolute timer in nanosecond
     */
    static long long getNanoSecondTimer()
    {
      timespec time = { 0, 0 };
      clock_gettime(CLOCK_REALTIME, &time);
      return (long long)time.tv_sec * 1000000000LL + (long long)time.tv_nsec;
    }

  public:
    /*!
     * @brief Constructor
     */
    HighResolutionTimer()
      : mReference(0)
    {
      Initialize(0);
    }

    /*!
     * @brief Restart the timer
     */
    void Initialize(long long initialValue) { mReference = getNanoSecondTimer() - initialValue; }

    /*!
     * @brief Get timer value in nano-seconds
     * @return Elapsed nano-seconds
     */
    long long GetNanoSeconds() { return getNanoSecondTimer() - mReference; }

    /*!
     * @brief Get timer value in micro-seconds
     * @return Elapsed micro-seconds
     */
    long long GetMicroSeconds() { return (getNanoSecondTimer() - mReference) / 1000; }

    /*!
     * @brief Get timer value in milli-seconds
     * @return Elapsed milli-seconds
     */
    int GetMilliSeconds() { return (int)((getNanoSecondTimer() - mReference) / 1000000); }
};
