#include "ISynchronousEvent.h"
#include "SyncronousEvent.h"

#pragma once

class SyncronousEventService
{
  private:
    //! Max synchroneous messages
    static constexpr int mMessageCount = 1024;

    //! Used messages
    int mMessageInUse[mMessageCount / (sizeof(int) * 8)];

    //! First SDL event available for our internal use
    unsigned int mFirstMessage;

    //! List of current callbacks
    ISynchronousEvent* mCallbacks[mMessageCount];

  public:

    static SyncronousEventService& Instance()
    {
      static SyncronousEventService _this;
      return _this;
    }

    SyncronousEventService()
      : mMessageInUse(),
        mFirstMessage(0u),
        mCallbacks()
    {
      mFirstMessage = SDL_RegisterEvents(mMessageCount);
      memset(mMessageInUse, 0, sizeof(mMessageInUse));
      memset(mCallbacks, 0, sizeof(mCallbacks));
    }

    SyncronousEvent ObtainSyncCallback(ISynchronousEvent* callback);

    void RecycleSyncCallback(SyncronousEvent& recyclable);

    bool Dispatch(SDL_Event* event);
};

