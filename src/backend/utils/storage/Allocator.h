//
// From recalbox ES and Integrated by BozoTheGeek in Pegasus Front-end
//
#ifndef __GRANULAR_MEMORY_H__
#define __GRANULAR_MEMORY_H__

#include <memory.h>
#include <utils/storage/Common.h>
#include <utils/rLog.h>

// Shorten c++11 checks
#if __cplusplus >= 201103L
  #define __cplusplus11
#endif

/*!
 * Provide a base class to manage expendable memory chunk.
 */
class Allocator
{
  private:
    void*          mMemory;           //!< Memory pointer
    unsigned short mObjectSize;       //!< Object size
    unsigned short mMultiplier;       //!< Capacity multiplier
    unsigned char  mLog2Granularity;  //!< Log2(Granularity) : Capacity = Multiplier * (1 << Granularity)
    bool           mCanDecrease;      //!< Capacity can decrease?
    // Object size = 10, word aligned

    #define __GMSZ(i) (((int)(i) << (int)mLog2Granularity) * (int)mObjectSize)

  protected:
    /*! This flag is a placeholder for overriden class.
     * It only enables overriden classes to control object ownership.
     * It's been moved there to save padding, by using one of the left 2 bytes here. */
    bool fOwner;
    // Object size = 11, byte aligned

    /*!
     * Resize, or not, the current memory chunk, according to the granularity and the required size.
     * @param size Required size (memory chunk will be *at least* this size)
     */
    void Resize(int size)
    {
      // Get the new aligned multiplier
      int Multiplier = (size + (1 << (int)mLog2Granularity) - 1) >> mLog2Granularity;

    	
      // Change?
		  if ((unsigned int)Multiplier != (unsigned int)(unsigned short)mMultiplier)
		  {
		    if (((unsigned int)Multiplier > (unsigned int)(unsigned short)mMultiplier) || (mCanDecrease))
        {
          while ((Multiplier >> 16) != 0)
          {
            // Multiplier is too high, we must change the Log of 2
            mLog2Granularity++;
            // Get the new aligned multiplier
            Multiplier = (size + (1 << (int)mLog2Granularity) - 1) >> mLog2Granularity;
          }

          mMemory = realloc(mMemory, __GMSZ(Multiplier));
          if ((mMemory == nullptr) && ((Multiplier) != 0)) LOG_AND_EXIT("Allocator Memory allocation failure!");
          if (Multiplier > mMultiplier) // Empty added memory
            memset(((char*)mMemory) + __GMSZ(mMultiplier), 0, __GMSZ(Multiplier - mMultiplier));

          mMultiplier = (unsigned short)Multiplier;
        }
      }
    }

#ifdef __cplusplus11
    /*!
     * C++11 Move constructor
     * @param source source memory manager to move
     */
    Allocator(Allocator&& source) noexcept
    {
      // Move
      mMemory          = source.mMemory;
      mObjectSize      = source.mObjectSize;
      mMultiplier      = source.mMultiplier;
      mLog2Granularity = source.mLog2Granularity;
      mCanDecrease     = source.mCanDecrease;
      fOwner           = source.fOwner;

      // Disable source
      source.mMemory = nullptr;
      source.mMultiplier = 0;
    }

    /*!
     * C++11 Move assignement
     * @param source source memory manager to move
     * @return this
     */
    Allocator& operator =(Allocator&& source) noexcept
    {
      // Move
      mMemory          = source.mMemory;
      mObjectSize      = source.mObjectSize;
      mMultiplier      = source.mMultiplier;
      mLog2Granularity = source.mLog2Granularity;
      mCanDecrease     = source.mCanDecrease;
      fOwner           = source.fOwner;

      // Disable source
      source.mMemory = nullptr;
      source.mMultiplier = 0;

      return *this;
    }
#endif

    /*!
     * Constructor
     * @param objectsize Object base size
     * @param initialcapacity Initial memory chunk capacity
     * @param granularity Granularity
     * @param candecrease True if the memory chunk can decrease. False, if the memory chunk mist never decrease.
     * @param owner This flag is used by inherited classes.
     */
    Allocator(int objectsize, int initialcapacity, int granularity, bool candecrease, bool owner = false)
    {
      // Convert granularity to Power of 2
      unsigned char rLog = 0;
      if (granularity <= 0) granularity = 1;
      granularity >>= 1; while(granularity != 0) { rLog++; granularity >>= 1; }

      // Initialize
      fOwner           = owner;
      mMemory          = nullptr;
      mObjectSize      = (unsigned short)objectsize;
      mMultiplier      = 0;
      mLog2Granularity = rLog;
      mCanDecrease     = candecrease;

      // Initialize capacity when required
      if (initialcapacity > 0) Resize(initialcapacity);
    }

    /*!
     * Copy constructor
     * @param source Source object
     */
    Allocator(const Allocator& source)
    {
      mObjectSize      = source.mObjectSize;
      mMultiplier      = source.mMultiplier;
      mLog2Granularity = source.mLog2Granularity;
      mCanDecrease     = source.mCanDecrease;
      fOwner           = false; // Automatic top-level ownership disabled

      int Capacity = __GMSZ(mMultiplier);
      mMemory = malloc(Capacity);
      memcpy(mMemory, source.mMemory, Capacity);
    }

    /*!
     * = Operator
     * @param source Source object
     * @return This object
     */
    Allocator& operator = (const Allocator& source)
    {
      if (this == &source) return *this;

      if (mMemory != nullptr) free(mMemory);

      mObjectSize      = source.mObjectSize;
      mMultiplier      = source.mMultiplier;
      mLog2Granularity = source.mLog2Granularity;
      mCanDecrease     = source.mCanDecrease;
      fOwner           = false; // Automatic top-level ownership disabled

      int Capacity = __GMSZ(mMultiplier);
      mMemory = malloc(Capacity);
      memcpy(mMemory, source.mMemory, Capacity);

      return *this;
    }


    /*!
     * @brief Destructor
     */
    ~Allocator()
    {
      if (mMemory != nullptr) free(mMemory);
    }

    //! Raw memory accessor
    void* Memory() const { return mMemory; }

  public:
    //! Return Granularity in bytes
    int Granularity() const { return (1 << (int)mLog2Granularity); }
    //! Return Capacity in bytes
    int Capacity() const { return (int)mMultiplier << (int)mLog2Granularity; }

    #undef __GMSZ
};

#endif
