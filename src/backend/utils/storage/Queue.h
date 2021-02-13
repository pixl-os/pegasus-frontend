//
// Created by bkg2k on 21/12/2019.
//
#pragma once

#include "Allocator.h"

/*!
@brief Optimized queue with auto-expansion when necessary.
*/
template<typename T> class Queue : private Allocator
{
  #define __GET(i) ((T*)Memory())[i]
  #define __OBJSZ sizeof(T)

  private:
    //! Read pointer
    int mOut;
    //! Write pointer
    int mIn;

    /*!
     * @brief Get free items in the current space area
     * @return Free items
     */
    int FreeSpace() const
    {
      int Free = mOut - mIn;
      if (Free <= 0) Free = Capacity() + Free;
      return Free;
    }

    /*!
     * @brief Get allocated items in the current space area
     * @return
     */
    int AllocatedSpace() const { return Capacity() - FreeSpace(); }

    /*!
     * @brief Make the Queue grow according to the configured granularity
     */
    void Grow()
    {
      if (Capacity() == 0) Resize(1); // Resize @ granularity (always pow 2)
      else
      {
        int PreviousCapacity = Capacity();
        Resize(PreviousCapacity << 1);   // Ensure Capacity to be always a pure power of 2
        // If the queue is split in high/low parts, move the lower part to the top, into the newly allocated memory.
        if ((mIn < mOut) && (mIn != 0))
        {
          memcpy(&__GET(PreviousCapacity), &__GET(0), __OBJSZ * mIn);
          mIn += PreviousCapacity;
        }
      }
    }

  public:
    Queue& operator = (const Queue& source) = delete; // Forbidden

    Queue()                      : Allocator(__OBJSZ, 0, 4, false, true), mOut(0), mIn(0) {}
    explicit Queue(int capacity) : Allocator(__OBJSZ, capacity, 4, false, true), mOut(0), mIn(0) {}
    explicit Queue(bool owning)  : Allocator(__OBJSZ, 0, 4, false, owning), mOut(0), mIn(0) {}
    Queue(const Queue& source)   : Allocator(source), mOut(source.mOut), mIn(source.mIn) {}

    T& operator[] (int index) const
    {
      if ((unsigned int)index >= (unsigned int)Capacity()) LOG_AND_EXIT("Queue Index out of range!");
      return __GET(index);
    }

    void Push(const T item)
    {
      if (FreeSpace() < 2) Grow();
      __GET(mIn) = item;
      mIn = (mIn + 1) & (Capacity() - 1);
    }

    T& Peek() const
    {
      if (mIn == mOut) return *((T*)nullptr);
      return __GET(mOut);
    }

    T Pop()
    {
      if (mIn == mOut) LOG_AND_EXIT("Queue Out of data");
      T Result = __GET(mOut);
      mOut = (mOut + 1) & (Capacity() - 1);
      return Result;
    }

    T PopAt(int index)
    {
      if (index >= AllocatedSpace()) LOG_AND_EXIT("Queue Index out of range!");
      index = (index + mOut) & (Capacity() - 1);
      T Result = __GET(index);

      // Contiguous block?
      int In = mIn; if (In == 0) In = Capacity();
      if (mIn > mOut)
      {
        memcpy(&__GET(index), &__GET(index + 1), __OBJSZ * ((mIn - index) - 1));
        mIn = In - 1;
      }
      else
      {
        // Non contiguous block, check whether index is located in the high or low block
        if (index > mOut)
        {
          // High block
          memcpy(&__GET(index), &__GET(index + 1), __OBJSZ * ((Capacity() - index) - 1));
          __GET(Capacity() - 1) = __GET(0);
          memcpy(&__GET(0), &__GET(1), __OBJSZ * (mIn - 1));
          mIn--;
        }
        else
        {
          // Low block
          memcpy(&__GET(index), &__GET(index + 1), __OBJSZ * ((mIn - index) - 1));
          mIn--;
        }
      }

      return Result;
    }

    T Pop(T thisone)
    {
      if (mIn > mOut)
      {
        for (int Out = mOut; Out != mIn; Out++)
          if (__GET(Out) == thisone) return PopAt(Out - mOut);
        return false;
      }
      for(int Out = Capacity(); --Out >= mOut; )
        if (__GET(Out) == thisone) return PopAt(Out - mOut);
      for(int Out = mIn; --Out >= 0; )
        if (__GET(Out) == thisone) return PopAt(Capacity() - mOut + Out);
      return false;
    }

    void PopAndDelete() { Pop(); }
    void PopAndDeleteAt(int index) { PopAt(index); }
    void PopAndDelete(T thisone) { Pop(thisone); }

    bool Contains(const T thisone) const
    {
      if (mIn > mOut)
      {
        for (int Out = mOut; Out != mIn; Out++)
          if (__GET(Out) == thisone) return true;
        return false;
      }
      for(int Out = Capacity(); --Out >= mOut; )
        if (__GET(Out) == thisone) return true;
      for(int Out = mIn; --Out >= 0; )
        if (__GET(Out) == thisone) return true;
      return false;
    }

    void Clear()
    {
      mIn = mOut = 0;
    }

    int Count() const { return AllocatedSpace(); }

    bool Empty() const
    {
      return mIn == mOut;
    }

    #undef __GET
    #undef __OBJSZ
};

