//
// Created by bkg2k on 01/10/2019.
//

#include "SyncTimer.h"

void SyncTimer::Run()
{
  while(Thread::IsRunning())
  {
    // Wait for the required time
    if (mSignal.WaitSignal(mMilliseconds))
      break; // A cancel signal is received

    // Send the callback event
    mSender.Call();

    // Once again?
    if (!mRepeat)
      break; // Nope
  }
}
