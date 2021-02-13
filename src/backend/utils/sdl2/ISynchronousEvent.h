#include <SDL_events.h>

#pragma once

/*!
 * @brief Simple interface for Synchronous callback
 */
class ISynchronousEvent
{
  public:
    /*!
     * @brief Receive synchronous SDL2 event
     * @param event SDL event with .user populated by the sender
     */
    virtual void ReceiveSyncCallback(const SDL_Event& event) = 0;
};