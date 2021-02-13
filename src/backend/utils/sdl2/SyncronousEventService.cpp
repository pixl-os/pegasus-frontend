//
// Created by bkg2k on 30/09/2019.
//

#include "SyncronousEventService.h"

SyncronousEvent SyncronousEventService::ObtainSyncCallback(ISynchronousEvent* callback)
{
  // Lookup free message
  for(int i = mMessageCount; --i >= 0;)
  {
    int dword = i / ((int)sizeof(int) * 8);
    int bit = i - (dword * ((int)sizeof(int) * 8));
    if (((mMessageInUse[dword] >> bit) & 1) == 0)
    {
      mMessageInUse[dword] |= 1 << bit; // Set message in use
      mCallbacks[i] = callback;
      return SyncronousEvent((unsigned int)i + mFirstMessage);
    }
  }
  // No luck
  return SyncronousEvent(0u);
}

void SyncronousEventService::RecycleSyncCallback(SyncronousEvent& recyclable)
{
  unsigned int message = recyclable.mSDLEvent - mFirstMessage;
  recyclable.mSDLEvent = 0;
  if (message < mMessageCount)
  {
    unsigned int dword = message / ((int)sizeof(int) * 8);
    unsigned int bit = message - (dword * ((int)sizeof(int) * 8));
    mMessageInUse[dword] &= ~(1 << bit); // Clear message bit
    mCallbacks[message] = nullptr;
  }
}

bool SyncronousEventService::Dispatch(SDL_Event* event)
{
  unsigned int index = event->type - mFirstMessage;
  if (index >= mMessageCount) return false;

  ISynchronousEvent* interface = mCallbacks[index];
  if (interface != nullptr)
  {
    interface->ReceiveSyncCallback(*event);
    return true;
  }

  return false;
}
