//
// Created by bkg2k on 28/12/2020.
//
// As part of the RECALBOX Project
// http://www.recalbox.com
//

#include "Signal.h"

Signal::Signal()
  : mMutex()
  , mCondition()
  , mSignal(false)
{
  pthread_cond_init(&mCondition, nullptr);
}

Signal::~Signal()
{
  pthread_cond_destroy(&mCondition);
  pthread_mutex_destroy(&mMutex);
}

void Signal::Fire()
{
  pthread_mutex_lock(&mMutex);
  mSignal = true;
  pthread_mutex_unlock(&mMutex);

  pthread_cond_signal(&mCondition);
}

void Signal::WaitSignal()
{
  pthread_mutex_lock(&mMutex);
  while(!mSignal)
    pthread_cond_wait(&mCondition, &mMutex);
  mSignal = false;
  pthread_mutex_unlock(&mMutex);
}

bool Signal::WaitSignal(long long int milliseconds)
{
  struct timespec ts = { 0, 0 };
  clock_gettime(CLOCK_REALTIME, &ts);
  if (milliseconds >1000) { ts.tv_sec += milliseconds / 1000LL; milliseconds %= 1000LL; }
  ts.tv_nsec += milliseconds * 1000000LL;

  bool result = false;
  pthread_mutex_lock(&mMutex);
  while(!mSignal)
  {
    result = (pthread_cond_timedwait(&mCondition, &mMutex, &ts) == 0);
    if (!result) break; // Timeout
  }
  mSignal = false;
  pthread_mutex_unlock(&mMutex);
  return result;
}

void Signal::Reset()
{
  pthread_mutex_lock(&mMutex);
  mSignal = false;
  pthread_mutex_unlock(&mMutex);
}
