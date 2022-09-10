#include "Mutex.h"

Mutex::Mutex()
  : mMutex()
{
  pthread_mutexattr_t MutexAttr;
  pthread_mutexattr_init(&MutexAttr);
  pthread_mutexattr_settype(&MutexAttr, PTHREAD_MUTEX_RECURSIVE_NP);
  pthread_mutex_init(&mMutex, &MutexAttr);
}

Mutex::~Mutex()
{
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
