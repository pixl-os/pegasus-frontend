//
// Created by bkg2k on 21/02/2021.
//
// As part of the RECALBOX Project
// http://www.recalbox.com
//
#pragma once

#include <utils/String.h>
#include <utils/Strings.h>
#include <vector>
#include "utils/Sizes.h"
#include <utils/storage/rHashMap.h>
#include <utils/IniFile.h>
#include <QStringList>

class StorageDevices
{
  private:
    //! Size info
    struct SizeInfo
    {
      long long Size; //!< Size in Kbyte
      long long Free; //!< Free in Kbyte
      SizeInfo() : Size(0), Free(0) {}
      SizeInfo(long long s, long long f) : Size(s), Free(f) {}
    };

  public:
    //! Device Property Map type
    typedef rHashMap<std::string, std::string>  PropertyMap;
    //! Device Property Map type
    typedef rHashMap<String, struct SizeInfo>  DeviceSizeInfo;

    //! Storage types
    enum class Types
    {
      Internal, //!< Default partition
      Ram,      //!< tmpfs partition
      Network,  //!< Network share
      External, //!< External device
    };

    //! Storage descriptor
    struct Device
    {
      Types     Type;          //!< Device type
      String    DevicePath;    //!< Device path, i.e. /dev/sda1
      String    UUID;          //!< Device UUID
      String    PartitionName; //!< Partition name
      String    FileSystem;    //!< Partition filesystem
      String    DisplayName;   //!< Displayable name
      long long Size;          //!< Size in byte
      long long Free;          //!< Free in byte
      bool      Current;       //!< True for the current device

      // Constructor
      Device()
        : Type(Types::Internal)
        , Size(0)
        , Free(0)
        , Current(false)
      {}

      // Constructor
      Device(Types t, const String& p, const String& u, const String& pn, const String& fs, const String& dn, bool c, const DeviceSizeInfo& i)
        : Type(t)
        , DevicePath(p)
        , UUID(u)
        , PartitionName(pn)
        , FileSystem(fs)
        , DisplayName(dn)
        , Size(0)
        , Free(0)
        , Current(c)
      {
        SizeInfo* info = i.try_get(p);
        if (info != nullptr)
        {
          Size = ((long long)info->Size) << 10;
          Free = ((long long)info->Free) << 10;
        }
        else{
          Size = 0;
          Free = -1;
        }
      }

      [[nodiscard]] String HumanSize() const { return Sizes(Size).ToHumanSize(); }

      [[nodiscard]] String HumanFree() const { return Sizes(Free).ToHumanSize(); };

      [[nodiscard]] String PercentFree() const { return String((int)(((double)Free / (double)Size) * 100.0)); }
    };

    StorageDevices()
      : mBootConfiguration(Path("/boot/recalbox-boot.conf"))
      , mShareInRAM(false)
    {
      Initialize();
    }

    /*!
     * @brief Get storage device list
     * @return Storage list
     */
    [[nodiscard]] const std::vector<Device>& GetStorageDevices() const { return mDevices; }

    /*!
     * @brief Set storage device
     * @param device Device to set as share device
     */
    void SetStorageDevice(const Device& device);

    /*!
     * @brief Get share device
     * @return Device selected as share device
     */
    String GetStorageDevice();

    /*!
     * @brief Get Device from any Directory (to know partition/disk source of any directory)
     * @param directory Directory to set as share device
     */
    const Device& GetDeviceFromDirectory(const String& directory);

    /*!
     * @brief Get List of Device from any List of Directories (to know partition/disk source of a set of directories)
     * @param directories List of Directories to set as share device
     */
    const QStringList GetDevicesFromDirectories(const QStringList& directories);

private:
    //! Share device key
    static constexpr const char* sShareDevice = "sharedevice";
    //! Internal string
    static constexpr const char* sInMemory = "RAM";
    //! Internal string
    static constexpr const char* sInternal = "INTERNAL";
    //! Any external string
    static constexpr const char* sAnyExternal = "ANYEXTERNAL";
    //! Network string
    static constexpr const char* sNetwork = "NETWORK";

    //! Boot configuration file
    IniFile mBootConfiguration;
    //! All devices
    std::vector<Device> mDevices;
    //! Boot root device name
    String mBootRoot;
    //! Share in ram?
    bool mShareInRAM;

    //! Initialize all devices
    void Initialize();

    //! Get raw output of the given command
    static String::List GetCommandOutput(const String& command);

    //! Get raw device list from blkid command
    static String::List GetRawDeviceList();

    //! Get icon by device
    static String GetIconByDevice(const String& device);

    //! Get raw device by LABEL from blkid command
    static String GetRawDeviceByLabel(const String& label);

    //! Get mounted device list from mount command
    static String::List GetMountedDeviceList();

    //! Get file system info from df command
    static DeviceSizeInfo GetFileSystemInfo();

    //! Extract properies from the given string
    static PropertyMap ExtractProperties(const String& properties);

    //! Analyse mounted devices - Get boot device & check is share is in ram
    void AnalyseMounts();
};



