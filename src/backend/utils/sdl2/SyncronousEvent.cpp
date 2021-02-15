#include "SyncronousEvent.h"
#include "SyncronousEventService.h"

SyncronousEvent::SyncronousEvent(ISynchronousEvent* callback)
  : SyncronousEvent(SyncronousEventService::Instance().ObtainSyncCallback(callback))
{
}

SyncronousEvent::~SyncronousEvent()
{
  SyncronousEventService::Instance().RecycleSyncCallback(*this);
}

void SyncronousEvent::Call() const
{
  SDL_Event event;
  event.user.type = mSDLEvent;
  SDL_PushEvent(&event);
}

void SyncronousEvent::Call(int data) const
{
  SDL_Event event;
  event.user.type = mSDLEvent;
  event.user.code = data;
  SDL_PushEvent(&event);
}

void SyncronousEvent::Call(void* data) const
{
  SDL_Event event;
  event.user.type = mSDLEvent;
  event.user.data1 = data;
  SDL_PushEvent(&event);
}

void SyncronousEvent::Call(int data, void* data1) const
{
  SDL_Event event;
  event.user.type = mSDLEvent;
  event.user.code = data;
  event.user.data1 = data1;
  SDL_PushEvent(&event);
}

void SyncronousEvent::Call(void* data1, void* data2) const
{
  SDL_Event event;
  event.user.type = mSDLEvent;
  event.user.data1 = data1;
  event.user.data2 = data2;
  SDL_PushEvent(&event);
}

void SyncronousEvent::Call(int data, void* data1, void* data2) const
{
  SDL_Event event;
  event.user.type = mSDLEvent;
  event.user.code = data;
  event.user.data1 = data1;
  event.user.data2 = data2;
  SDL_PushEvent(&event);
}

