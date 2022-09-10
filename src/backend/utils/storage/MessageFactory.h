//
// Created by bkg2k on 03/11/2020.
//
#pragma once

#include <utils/storage/Stack.h>
#include <utils/os/system/Mutex.h>

template<class T> class MessageFactory
{
  public:
    /*!
     * @brief Destructor, destroy all in use and recycled messages
     */
    ~MessageFactory()
    {
      for(int i = mInUse.Count(); --i >= 0; ) delete mInUse[i];
      mInUse.Clear();
      for(int i = mReady.Count(); --i >= 0; ) delete mReady[i];
      mReady.Clear();
    }

    /*!
     * @brief Obtain a new message.
     * Try to re-use a recycled message if possible or create a new one
     * @return Message
     */
    T* Obtain()
    {
      // Synchronize
      Mutex::AutoLock locker(mSyncer);

      // Create or reuse recycled message
      T* result = (!mReady.Empty()) ? mReady.Pop() : new T();
      // Push message into the "in use" stack
      mInUse.Push(result);

      // Return newly usable message
      return result;
    }

    /*!
     * @brief Recycle a message and make it ready to be re-used
     * @param message Message to recycle
     */
    void Recycle(T* message)
    {
      // Synchronize
      Mutex::AutoLock locker(mSyncer);

      // Remove from in use (ignore fail to allow user-created message to join the factory)
      mInUse.Pop(message);
      // Insert into the ready stack
      mReady.Push(message);
    }

  private:
    //! Messages ready to be obtained (recycled)
    Stack<T*> mReady;
    //! Messages in use
    Stack<T*> mInUse;

    //! Synchronizer
    Mutex mSyncer;
};
