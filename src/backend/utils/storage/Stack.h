//
// Created by bkg2k on 21/12/2019.
//
#pragma once

#include "Allocator.h"

/*!
@brief Optimized stack with auto-expension when necessary.
*/
template<typename T> class Stack : private Allocator
{
  #define __GET(i) ((T*)Memory())[i]
  #define __OBJSZ sizeof(T)

  private:
    int fCount;

  public:
    Stack() : Allocator(__OBJSZ, 0, 4, false, true), fCount(0) {}
    explicit Stack(int capacity) : Allocator(__OBJSZ, capacity, 4, false, true), fCount(0) {}
    Stack(const Stack& source) : Allocator(source), fCount(source.fCount) {}
    Stack(const Stack&& source) noexcept : Allocator(source), fCount(source.fCount) { source.fCount = 0; }
    Stack& operator = (const Stack& source) { if (&source != this) { Allocator::operator=(source); fCount = source.fCount; } return *this; }
    Stack& operator = (Stack&& source) noexcept { if (&source != this) { Allocator::operator=(source); source.fCount = 0; } return *this; }

    T& operator[] (int index) const
    {
      if ((unsigned int)index >= (unsigned int)(fCount))
      {
        LOG_AND_EXIT("Stack Index out of range!");
      }
      return __GET(index);
    }

    void Push(const T& item)
    {
      if (fCount >= Capacity()) Resize(fCount + 1);
      __GET(fCount++) = item;
    }

    T& Peek() const
    {
      if (fCount==0) return *((T*)nullptr);
      return __GET(fCount - 1);
    }

    T Pop()
    {
      if (fCount == 0) return *((T*)nullptr);
      return __GET(--fCount);
    }

    T PopAt(int index)
    {
      if (index >= fCount) return *((T*)nullptr);
      T poped = __GET(index);
      if (index < fCount - 1) memcpy(&__GET(index), &__GET(index + 1), __OBJSZ * (fCount - index - 1));
      fCount--;
      return poped;
    }

    T Pop(const T& thisone)
    {
      for(int i=fCount; --i>=0;)
        if (__GET(i) == thisone) return PopAt(i);
      return *((T*)nullptr);
    }

    void PopAndDelete()
    {
      if (fCount > 0) fCount--;
    }

    void PopAndDeleteAt(int index)
    {
      if (index < fCount)
      {
        if (index < fCount - 1) memcpy(&__GET(index), &__GET(index + 1), __OBJSZ * (fCount - index - 1));
        fCount--;
      }
    }

    void PopAndDelete(const T& thisone)
    {
      for(int i=fCount; --i>=0;)
        if (__GET(i) == thisone) { Pop(i); break; }
    }

    bool Contains(const T& thisone) const
    {
      for(int i=fCount; --i>=0;)
        if (__GET(i) == thisone) return true;
      return false;
    }

    void Clear()
    {
      Resize(fCount = 0);
    }

    int Count() const { return fCount; }

    bool Empty() const { return fCount == 0; }

  #undef __GET
  #undef __OBJSZ
};
