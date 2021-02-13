#include "Mutex.h"

Mutex::Mutex()
  : mMutex(), mCondition()
{
  pthread_mutexattr_t MutexAttr;
  pthread_mutexattr_init(&MutexAttr);
  pthread_mutexattr_settype(&MutexAttr, PTHREAD_MUTEX_RECURSIVE_NP);
  pthread_mutex_init(&mMutex, &MutexAttr);
  pthread_cond_init(&mCondition, nullptr);
}

Mutex::~Mutex()
{
  pthread_cond_destroy(&mCondition);
  if(pthread_mutex_destroy(&mMutex) != 0)
  {
    UnLock();
    pthread_mutex_destroy(&mMutex);
  }
}

bool Mutex::Lock()
{
  return pthread_mutex_lock(&mMutex) == 0;
}

bool Mutex::UnLock()
{
  return pthread_mutex_unlock(&mMutex) == 0;
}

bool Mutex::Signal()
{
  pthread_cond_signal(&mCondition);
  return true;
}

bool Mutex::WaitSignal()
{
  Lock();
  pthread_cond_wait(&mCondition, &mMutex);
  UnLock();
  return true;
}

bool Mutex::WaitSignal(long long milliseconds)
{
  struct timespec ts = { 0, 0 };
  clock_gettime(CLOCK_REALTIME, &ts);
  if (milliseconds >1000)
  {
    ts.tv_sec += milliseconds / 1000LL;
    milliseconds %= 1000LL;
  }
  ts.tv_nsec += milliseconds * 1000000LL;

  Lock();
  bool result = (pthread_cond_timedwait(&mCondition, &mMutex, &ts) == 0);
  UnLock();
  return result;
}
