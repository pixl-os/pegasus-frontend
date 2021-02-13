#pragma once

class ISyncTimer
{
  public:
    virtual void TimerTick(int id) = 0;
};
