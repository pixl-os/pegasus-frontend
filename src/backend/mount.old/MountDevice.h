//
// Created by bkg2k on 10/02/2022.
//
// As part of the RECALBOX Project
// http://www.recalbox.com
//
#pragma once

#include "utils/os/fs/Path.h"
#include "utils/String.h"
#include "utils/Sizes.h"
#include <sys/statvfs.h>

//! Device mount info
class DeviceMount
{
  public:
    /*!
     * @brief Constructor
     * @param device Device path
     * @param mountpoint Mount point
     * @param name Volume Name
     */
    DeviceMount(const Path& device, const Path& mountpoint, const String& name, const String& type, const String& options)
      : mDevice(device)
      , mMountPoint(mountpoint)
      , mName(name)
      , mType(type)
      , mTotalSize(0)
      , mFreeSize(0)
      , mReadOnly(false)
    {
      for(const String& option : options.Split(','))
        if (option == "ro")
        {
          mReadOnly = true;
          break;
        }
    }

    /*
     * Tool
     */

    [[nodiscard]] String DisplayableDeviceName() const
    {
      return String(mName)
             .Append(" (", 2)
             .Append(mDevice.ToString())
             .Append(')');
    }

    [[nodiscard]] String DisplayableFreeSpace() const
    {
      return Sizes(mFreeSize).ToHumanSize()
             .Append('/')
             .Append(Sizes(mTotalSize).ToHumanSize())
             .Append(" (", 2)
             .Append(mTotalSize == 0 ? String("Unknown") : String((mFreeSize * 100) / mTotalSize))
             .Append("%)", 2);
    }

    /*!
     * @brief Update size & free
     * @return This
     */
    DeviceMount& UpdateSize()
    {
      struct statvfs fiData {};
      if ((statvfs(mMountPoint.ToChars(), &fiData)) >= 0)
      {
        mTotalSize = ((long long)fiData.f_blocks * (long long)fiData.f_bsize);
        mFreeSize = ((long long)fiData.f_bfree * (long long)fiData.f_bsize);
      }
      return *this;
    }

    /*
     * Accessors
     */

    //! Get device path
    [[nodiscard]] const Path& Device() const { return mDevice; }
    //! Get mount point
    [[nodiscard]] const Path& MountPoint() const { return mMountPoint; }
    //! Get volume name
    [[nodiscard]] const String& Name() const { return mName; }
    //! Get file system type
    [[nodiscard]] const String& Type() const { return mType; }
    //! Total size
    [[nodiscard]] long long TotalSize() const { return mTotalSize; }
    //! Free size
    [[nodiscard]] long long FreeSize() const { return mFreeSize; }
    //! Get file system read-only status
    [[nodiscard]] bool ReadOnly() const { return mReadOnly; }

    /*
     * Operators
     */

    bool operator == (const DeviceMount& right)
    {
      return mDevice == right.mDevice;
    }

  private:
    Path        mDevice;     //!< Device (/dev/...)
    Path        mMountPoint; //!< Mount point (/recalbox/share/externals/...)
    String mName;       //!< Volume name
    String mType;       //!< FS type (ntfs, ext, ...)
    long long   mTotalSize;  //!< Total size in byte
    long long   mFreeSize;   //!< Free size in byte
    bool        mReadOnly;   //!< Read only?
};
