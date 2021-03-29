//
// Created by bkg2k on 21/12/2019.
//
#pragma once

#include "Allocator.h"
#include "Common.h"

#ifdef __cplusplus11
#include <initializer_list>
#endif

/*!
@brief Optimized CARDINAL array with auto-expansion on write
*/
template<typename T> class Array : private Allocator
{
  #define __GET(i) ((T*)Memory())[i]
  #define __OBJSZ sizeof(T)

  private:
    static constexpr int __InitialCapacity = 0;
    static constexpr int __InitialGranularity = 4;

    int fCount; // Object count

    // Check available memory against fCount. Expand if necessary
    T* Check(int from, int count)
    {
      if (from + count > fCount)
      {
        if (from >= fCount) return Expand(from, count); // Full expand
        Expand(fCount, from + count - fCount); // Expand what needed.
      }
      return &__GET(from);
    }

    // Expand after fCount or insert in current area
    T* Expand(int from, int count)
    {
      if (from >= fCount)
      {
        Resize(from + count); // Expand out of current range, just grow up
        fCount = from + count;
      }
      else
      {
        Resize(fCount + count); // Expand in current range -> Resize
        memmove(&__GET(from + count), &__GET(from), (fCount - from) * __OBJSZ);
        fCount += count;
      }
      return &__GET(from);
    }

    // Clear size byte from memory
    inline void ClearMemory(void* memory, int size)
    {
      memset(memory, 0, size);
    }

    // Contract area by removing count item
    void Contract(int from, int count)
    {
      if (from >= fCount) return;
      if (from + count > fCount) count = fCount - from;
      memcpy(&__GET(from), &__GET(from + count), (fCount - (from + count)) * __OBJSZ);
      fCount -= count;
      ClearMemory(&__GET(fCount), count * __OBJSZ);
    }

#ifdef __cplusplus11
    // Fill from STD immediate initialization list - always by value
    void FillFromStd(std::initializer_list<T> l)
    {
      T* items = Check(0, l.size());
      int index = 0;
      for(T item : l) items[index++] = item;
    }
#endif

    typedef int (Comparer)(const T&, const T&);
  public:

    Array() : Allocator(__OBJSZ, __InitialCapacity, __InitialGranularity, true), fCount(0) { }
    explicit Array(int capacity) : Allocator(__OBJSZ, capacity, __InitialGranularity, false), fCount(0) { }
    explicit Array(bool candecrease) : Allocator(__OBJSZ, __InitialCapacity, __InitialGranularity, candecrease), fCount(0) { }
    Array(int capacity, int granularity) : Allocator(__OBJSZ, capacity, granularity, false), fCount(0) { }
    Array(int capacity, int granularity, bool candecrease) : Allocator(__OBJSZ, capacity, granularity, candecrease), fCount(0) { }
    Array(const Array& source) : Allocator(source), fCount(source.fCount) { }

#ifdef __cplusplus11
    Array(Array&& source) noexcept : Allocator((Array&&)source), fCount(source.fCount) { source.fCount = 0; }
    Array& operator =(Array&& source) noexcept { Allocator::operator =((Array&&)source); fCount = source.fCount; source.fCount = 0; return *this; }
    Array(std::initializer_list<T> l) : Allocator(__OBJSZ, __InitialCapacity, __InitialGranularity, true), fCount(0) { FillFromStd(l); }
#endif

    // Assign operator
    Array& operator =(const Array& source) { if (&source != this) { Clear(); CopyFrom(source); } return *this; }

#ifdef __cplusplus11
    Array& operator =(std::initializer_list<T> l) { Clear(); FillFromStd(l); return *this; }
#endif

    /*!
     * Main Quicksort
     * @param low Lowest element
     * @param high Highest element
     * @param comparer Compare method
     */
    void QuickSort(int low, int high, Comparer comparer)
    {
      int Low = low, High = high;
      T Pivot= __GET((Low + High) >> 1);
      do
      {
        while((*comparer)(__GET(Low) , Pivot) < 0) Low++;
        while((*comparer)(__GET(High), Pivot) > 0) High--;
        if (Low <= High)
        {
          T Tmp = __GET(Low); __GET(Low) = __GET(High); __GET(High) = Tmp;
          Low++; High--;
        }
      }while(Low <= High);
      if (High > low) QuickSort(low, High, comparer);
      if (Low < high) QuickSort(Low, high, comparer);
    }
    
    // Sorter
    void Sort(Comparer compare)
    {
      if (fCount > 1) QuickSort(0, fCount-1, compare);
    }

    // Read operator
    T operator[] (int index) const
    {
      if ((unsigned int)index >= (unsigned int)fCount) LOG_AND_EXIT("Array Index out of bound!");
      return __GET(index);
    }

    /*!
     * Get the first element
     * @return Object pointer
     */
    T First() const { return (*this)[0]; }

    /*!
     * Get the Last element
     * @return Object pointer
     */
    T Last() const { return (*this)[fCount - 1]; }

    /*!
     * Get array memory buffer as const typed pointer (thus, read-only)
     * @return cont typed pointer
     */
    const T* BufferReadOnly() const { return (const T*)Memory(); }

    /*!
     * Get array memory buffer as non-const typed pointer (thus, read-write)
     * @return typed pointer
     */
    T* BufferReadWrite() const { return (T*)Memory(); }

    /*!
     * Get array memory buffer as const char pointer (thus, read-only)
     * @return const char pointer
     */
    const unsigned char* ByteBufferReadOnly() const { return (const unsigned char*)Memory(); }

    /*!
     * Get array memory buffer as non-const char pointer (thus, read-write)
     * @return char pointer
     */
    unsigned char* ByteBufferReadWrite() const { return (unsigned char*)Memory(); }

    /*!
     * By reference, non-const item accessor. May be used as a write operator, or to access large object by reference
     * @param index Item index
     * @return Item at the index. If the index is out of bound, the array is automaticaly extended.
     */
    T& operator() (int index)
    {
      if (index >= Capacity()) Check(index, 1);
      else if (index >= fCount) fCount = index + 1;
      return __GET(index);
    }

    /*!
     * Get array length
     * @return Number of items in the array
     */
    int Count() const { return fCount; }

    /*!
     * Return whether the list is empty or not
     * @return True if there is no element
     */
    bool Empty() const { return fCount == 0; }

    /*!
     * Return whether the list has at least one element or not
     * @return True if there is at least one element
     */
    bool HasElement() const { return fCount != 0; }

    /*!
     * Get array byte size
     * @return Sie of the array in byte
     */
    int ByteSize() const { return Capacity() * sizeof(T); }

    /*!
     * Get array capacity (before memory reallocation)
     * @return Array capacity
     */
    using Allocator::Capacity;

    /*!
     * Clear the array and reset its size to zero
     */
    void Clear() { Resize(0); fCount = 0; }
    void Delete(int index) { Contract(index, 1); }
    void Delete(int index, int count) { Contract(index, count); }

    /*!
     * If the array size exceed the given size, it is truncated to the given size.
     * @param size Max size
     */
    void TruncateTo(int size) { if (fCount > size) { Resize(size); fCount = size; } }

    /*!
     * If the array size is less than the given size, it is expanded to the given size.
     * @param size Max size
     */
    void ExpandTo(int size) { if (fCount < size) { Resize(size); fCount = size; } }

    void Set(const T& item, int index)
    {
      if (index < Capacity()) { if (index >= fCount) fCount = index + 1; __GET(index) = item; }
      else *Check(index, 1) = item;
    }
    void Add(const T& item)
    {
      if (fCount < Capacity()) __GET(fCount++) = item;
      else *Expand(fCount, 1) = item;
    }

    bool Contains(const T* item)
    {
      for(int i = fCount; --i >= 0; )
        if (__GET(i) == *item)
          return true;
      return false;
    }

    bool Contains(const T& item)
    {
      for(int i = fCount; --i >= 0; )
        if (__GET(i) == item)
          return true;
      return false;
    }

    int IndexOf(const T* item)
    {
      for(int i = fCount; --i >= 0; )
        if (__GET(i) == *item)
          return i;
      return -1;
    }

    int IndexOf(const T& item)
    {
      for(int i = fCount; --i >= 0; )
        if (__GET(i) == item)
          return i;
      return -1;
    }

    void AddItems(const T* item, int count) { T* insertAt = Expand(fCount, count); memcpy(insertAt, item, sizeof(T) * count); }
    void Insert(const T& item, int index) { *Expand(index, 1) = item; }
    void Insert(const T& item, int index, int count) { T* insertAt = Expand(index, count); for(; --count >= 0;) insertAt[count] = item; }
    void InsertItems(const T* item, int index, int count) { T* insertAt = Expand(index, count); memcpy(insertAt, item, sizeof(T) * count); }

    void CopyFrom(const Array& source)                       { CopyFrom(source, fCount, 0, source.fCount); }
    void CopyFrom(const Array& source, int index)            { CopyFrom(source, index, 0, source.fCount); }
    void CopyFrom(const Array& source, int index, int count) { CopyFrom(source, index, 0, count); }
    void CopyFrom(const Array& source, int index, int sourceindex, int count)
    {
      Array* RemoveConst = (Array*)&source;
      memcpy(Check(index, count), RemoveConst->Check(sourceindex, count), count * __OBJSZ);
    }

    void MoveFrom(Array& source)                       { MoveFrom(source, fCount, 0, source.fCount); }
    void MoveFrom(Array& source, int index)            { MoveFrom(source, index, 0, source.fCount); }
    void MoveFrom(Array& source, int index, int count) { MoveFrom(source, index, 0, count); }
    void MoveFrom(Array& source, int index, int sourceindex, int count)
    {
      memcpy(Check(index, count), source.Check(sourceindex, count), count * __OBJSZ);
      source.Contract(sourceindex, count);
    }

  #undef __GET
  #undef __OBJSZ
};

// Basic Templates
typedef Array<bool>           BoolArray;
typedef Array<char>           CharArray;
typedef Array<unsigned char>  ByteArray;
typedef Array<short>          ShortArray;
typedef Array<unsigned short> WordArray;
typedef Array<int>            IntArray;
typedef Array<unsigned int>   DWordArray;
typedef Array<long>           LongArray;
typedef Array<unsigned long>  QWordArray;
