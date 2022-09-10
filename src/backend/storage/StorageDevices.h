//
// Created by bkg2k on 21/02/2021.
//
// As part of the RECALBOX Project
// http://www.recalbox.com
//
#pragma once

#include <string>
#include <vector>
#include <utils/Strings.h>
#include <utils/storage/rHashMap.h>

class StorageDevices
{
  public:
    //! Device Property Map type
    typedef rHashMap<std::string, std::string>  PropertyMap;

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
      Types       Type;          //!< Device type
      std::string DevicePath;    //!< Device path, i.e. /dev/sda1
      std::string UUID;          //!< Device UUID
      std::string PartitionName; //!< Partition name
      std::string FileSystem;    //!< Partition filesystem
      std::string DisplayName;   //!< Displayable name
      bool        Current;       //!< True for the current device
    };

    StorageDevices()
      : mBootConfiguration(Path("/boot/recalbox-boot.conf"))
      , mShareInRAM(false)
    {
      Initialize();
    }

    const std::vector<Device>& GetStorageDevices() const
    {
      return mDevices;
    }

    void SetStorageDevice(const Device& device);

    std::string GetStorageDevice();

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
    std::string mBootRoot;
    //! Share in ram?
    bool mShareInRAM;

    //! Initialize all devices
    void Initialize();

    //! Get raw output of the given command
    static Strings::Vector GetCommandOutput(const std::string& command);

    //! Get raw device list from blkid command
    static Strings::Vector GetRawDeviceList();

    //! Get raw device list from blkid command
    static Strings::Vector GetMountedDeviceList();

    //! Extract properies from the given string
    static PropertyMap ExtractProperties(const std::string& properties);

    //! Analyse mounted devices - Get boot device & check is share is in ram
    void AnalyseMounts();
};



