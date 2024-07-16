//
// Created by bkg2k on 21/02/2021.
//
// As part of the RECALBOX Project
// http://www.recalbox.com
//

#include "utils/locale/LocaleHelper.h"
#include "RootFolders.h"
#include "StorageDevices.h"
#include "utils/rLog.h"
#include "Log.h"
#include <string>
#include <QFile>

void StorageDevices::Initialize()
{
  String devicePath;
  String propertyLine;
  long long Size;          //!< Size in byte

  AnalyseMounts();
  String current = GetStorageDevice();

  // Get storage sizes
  DeviceSizeInfo sizeInfos = GetFileSystemInfo();

  // Ram?
  if (mShareInRAM)
  {
    current = "RAM";
    mDevices.push_back(Device(Types::Ram, "SHARE",  sInMemory, "RECALBOX", "tmpfs",_("In Memory!")+ " \u26a0", true, sizeInfos));
    { LOG(LogWarning) << "[Storage] Share is stored in memory!"; }
  }

  // Add Internal default share
  const String& line = GetRawDeviceByLabel("SHARE");
  if (line.Extract(':', devicePath, propertyLine, true))
    {
      // Extract device properties
      PropertyMap properties = ExtractProperties(propertyLine);
      // Get size for info
      SizeInfo* info = sizeInfos.try_get(devicePath);
      if (info != nullptr)
      {
          Size = ((long long)info->Size) << 10;
      }
      else
      {
          Size = 0;
      }
      String uuid = "DEV " + properties.get_or_return_default("UUID");
      String label = properties.get_or_return_default("LABEL");
      if (label.empty()) label = "Unnamed";
      String filesystem = properties.get_or_return_default("TYPE");
      if (filesystem.empty()) filesystem = "fs?";
      String displayable = _("Internal %l - %d (%f)");
      displayable.Replace("%d", Path(devicePath).Filename())
          .Replace("%l", label)
          .Replace("%f", filesystem);
      String strSize = _("Size: %d");
      strSize.Replace("%d", Size);
      // Store
      if (current == sInternal){
        mDevices.push_back(Device(Types::Internal, devicePath, sInternal, "RECALBOX", filesystem, displayable, current == sInternal, sizeInfos));
      }
      else{
        mDevices.push_back(Device(Types::Internal, devicePath, uuid, label, filesystem, displayable, false, sizeInfos));
      }
      { LOG(LogDebug) << "[Storage] Internal Share partition: " << devicePath << ' ' << uuid << " \"" << label << "\" " << filesystem << " size (bytes): " << Size; }
  }
  else{
      //if issue to detect SHARE
      mDevices.push_back(Device(Types::Internal, "SHARE",  sInternal, "RECALBOX", "exfat",_("Internal Share"), current == sInternal, sizeInfos));
  }

  // Network
  if (mBootConfiguration.HasKeyStartingWith("sharenetwork_") || mBootConfiguration.AsString("sharedevice") == "NETWORK")
  {
    mDevices.push_back(Device(Types::Internal, "", sNetwork, "", "", _("Network Share"), current == sNetwork, sizeInfos));
    { LOG(LogDebug) << "[Storage] Network share configuration detected"; }
  }

  // Any external
  if (mBootConfiguration.AsString("sharedevice") == "ANYEXTERNAL") {
      mDevices.push_back(Device(Types::Internal, "",  sAnyExternal, "", "",_("Any External Device").append(_(" (Deprecated)")), current == sAnyExternal, sizeInfos));
    { LOG(LogDebug) << "[Storage] Any external share configuration detected"; }
  }

  // External Devices
  for(const String& line : GetRawDeviceList()){
    //{ LOG(LogDebug) << "[Storage] GetRawDeviceList line: " << line; }
    if (line.Extract(':', devicePath, propertyLine, true))
    {
      //{ LOG(LogDebug) << "[Storage] propertyLine: " << propertyLine; }
      //{ LOG(LogDebug) << "[Storage] devicePath: " << devicePath; }

      // Avoid boot device partitions
      if (devicePath.StartsWith(mBootRoot)) continue;

      // Extract device properties
      PropertyMap properties = ExtractProperties(propertyLine);

      // Avoid small partition (less than 1 Gb)
      SizeInfo* info = sizeInfos.try_get(devicePath);
      if (info != nullptr)
      {
          Size = ((long long)info->Size) << 10;
      }
      else
      {
          Size = 0;
      }
      //to ignore partition under 1 GByte (if size is well detected for sure)
      if ((Size <= (1024 * 1024 * 1024)) && (Size != 0)) continue;
      //Log::debug(LOGMSG("[Storage] Size: %1").arg(Size));

      String uuid = "DEV " + properties.get_or_return_default("UUID");
      String label = properties.get_or_return_default("LABEL");
      if (label.empty()) label = "Unnamed";
      String filesystem = properties.get_or_return_default("TYPE");
      if (filesystem.empty()) filesystem = "fs?";
      String displayable = _("%l - %d (%f)");
      displayable.Replace("%d", Path(devicePath).Filename())
                 .Replace("%l", label)
                 .Replace("%f", filesystem);
      String strSize = _("Size: %d");
      strSize.Replace("%d", Size);

      // Store
      mDevices.push_back(Device(Types::External, devicePath, uuid, label, filesystem, displayable, current == uuid, sizeInfos));
      { LOG(LogDebug) << "[Storage] External partition: " << devicePath << ' ' << uuid << " \"" << label << "\" " << filesystem << " size (bytes): " << Size; }
    }
  }
}

String::List StorageDevices::GetCommandOutput(const String& command)
{
  String output;
  char buffer[4096];
  FILE* pipe = popen(command.data(), "r");
  if (pipe != nullptr)
  {
    while (feof(pipe) == 0)
      if (fgets(buffer, sizeof(buffer), pipe) != nullptr)
        output.Append(buffer);
    pclose(pipe);
  }
  return output.Split('\n');
}

String::List StorageDevices::GetRawDeviceList()
{
  String command = "blkid";
  if(QFile::exists("/tmp/blkid")) command = "cat /tmp/blkid";
  return GetCommandOutput(command);
}

String StorageDevices::GetRawDeviceByLabel(const String& label)
{
    String command = _("blkid | grep 'LABEL=\"%f\"'");
    command.Replace("%f", label);
    for(const String& line : GetCommandOutput(command))
        return line;
}

String::List StorageDevices::GetMountedDeviceList()
{
    String command = "mount";
    if(QFile::exists("/tmp/mount")) command = "cat /tmp/mount";
    return GetCommandOutput(command);
}

// size/free are in KByte in this function
StorageDevices::DeviceSizeInfo StorageDevices::GetFileSystemInfo()
{
  DeviceSizeInfo result;
  String command = "df -kP";
  if(QFile::exists("/tmp/df-kP")) command = "cat /tmp/df-kP";
  for(const String& line : GetCommandOutput(command))
  {
    String::List items = line.Split(' ', true);
    //{ LOG(LogDebug) << "[Storage] GetFileSystemInfo items.size(): " << items.size() ; }

    if (items.size() >= 6)
    {
      //{ LOG(LogDebug) << "[Storage] GetFileSystemInfo line (df -kP): " << line ; }
      //{ LOG(LogDebug) << "[Storage] GetFileSystemInfo items[1]: " << items[1] ; }
      //{ LOG(LogDebug) << "[Storage] GetFileSystemInfo items[3]: " << items[3] ; }
      long long size = items[1].AsInt64();
      long long free = items[3].AsInt64();
      result[items[0]] = SizeInfo(size, free);
      // Special cases
      if (items[5] == RootFolders::DataRootFolder.ToString())
        result["SHARE"] = SizeInfo(size, free);
    }
  }

  bool isDisk = false;
  bool isDevice = false;
  String currentDisk = "";
  //check also by a second way for unmount disk
  command = "fdisk -l";
  if(QFile::exists("/tmp/fdisk-list")) command = "cat /tmp/fdisk-list";
  for(const String& line : GetCommandOutput(command))
  {
      String::List items = line.Split(' ', true);
      if((items[0] == "Disk") && items[1].StartsWith("/dev/")){
          //{ LOG(LogDebug) << "[Storage] GetFileSystemInfo line (fdisk -l) Disk: " << line ; }
          currentDisk = items[1].Replace(":","");
          isDisk = false;
          isDevice = false;
          continue;
      }
      if(items[0] == "Number"){
          //{ LOG(LogDebug) << "[Storage] GetFileSystemInfo line (fdisk -l) Number: " << line ; }
          isDisk = true;
          isDevice = false;
          continue;
      }
      if(items[0] == "Device"){
          //{ LOG(LogDebug) << "[Storage] GetFileSystemInfo line (fdisk -l): " << line ; }
          currentDisk="";
          isDisk = false;
          isDevice = true;
          continue;
      }
      if(isDisk || (items[0].StartsWith("/dev/") and isDevice)){
          //{ LOG(LogDebug) << "[Storage] GetFileSystemInfo line (fdisk -l) : " << line ; }
          String partition = "";
          int sizeIndex = 0;
          if(isDisk){
              //{ LOG(LogDebug) << "[Storage] GetFileSystemInfo items[1] : " << items[1] ; }
              partition = currentDisk + "p" + items[1];
              sizeIndex = 4;
          }
          else {
              partition = items[0];
              sizeIndex = 6;
              if (items.size() > 9){ //bood colomn not empty case
                  sizeIndex = sizeIndex + 1;
              }
          }
          //{ LOG(LogDebug) << "[Storage] GetFileSystemInfo partition : " << partition ; }
          //check if not already knwon/mount
          SizeInfo* info = result.try_get(partition);
          if (info == nullptr)
          {
              //{ LOG(LogDebug) << "[Storage] GetFileSystemInfo items[sizeIndex] : " << items[sizeIndex] ; }
              char lastChar = items[sizeIndex].back();
              String numeric = items[sizeIndex].SubString(0,items[sizeIndex].length()-1); //just remove last char
              //{ LOG(LogDebug) << "[Storage] GetFileSystemInfo lastChar : " << lastChar ; }
              //{ LOG(LogDebug) << "[Storage] GetFileSystemInfo numeric : " << numeric ; }
              numeric = numeric.Split('.', true).at(0); // to keep only first part before . in all cases
              long long size = 0;
              switch (lastChar) {
              case 'K':
                  size = numeric.AsInt64();
                  break;
              case 'M':
                  size = numeric.AsInt64() * 1024;
                  break;
              case 'G':
                  size = numeric.AsInt64() * 1024 * 1024;
                  break;
              case 'T':
                  size = numeric.AsInt64() * 1024 * 1024 * 1024;
                  break;
              default:
                  size = numeric.AsInt64();
                  break;
              }
              long long free = -1; // unknown in this case
              //{ LOG(LogDebug) << "[Storage] GetFileSystemInfo size : " << size ; }
              result[partition] = SizeInfo(size, free);
          }
      }
  }
  return result;
}

StorageDevices::PropertyMap StorageDevices::ExtractProperties(const String& properties)
{
  PropertyMap map;

  String key;
  String value;
  for(const String& kv : properties.SplitQuoted(' '))
    if (kv.Extract('=', key, value, true))
      map[key] = value.Trim('"');

  return map;
}

void StorageDevices::SetStorageDevice(const StorageDevices::Device& device)
{
  mBootConfiguration.SetString(sShareDevice, device.UUID);
  mBootConfiguration.Save();
}

String StorageDevices::GetStorageDevice()
{
  return mBootConfiguration.AsString(sShareDevice, sInternal);
}

void StorageDevices::AnalyseMounts()
{
  mBootRoot = "/dev/bootdevice";
  for(const String& line : GetMountedDeviceList())
  {
    String::List items = line.Split(' ', true);
    if (items.size() < 6)
    {
      { LOG(LogError) << "[Storage] Incomplete mount line: " << line; }
      continue;
    }
    if (items[2] == "/recalbox/share") mShareInRAM =  (items[4] == "tmpfs");
    else if (items[2] == "/boot") mBootRoot = items[0].Trim("0123456789");
  }
  if (mBootRoot.empty()) mBootRoot = "/dev/boot"; // for testing purpose only :)
  { LOG(LogDebug) << "[Storage] BootRoot: " << mBootRoot << " - Is In Ram: " << mShareInRAM; }
}

