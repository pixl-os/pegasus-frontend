//
// Created by bkg2k on 21/02/2021.
//
// As part of the RECALBOX Project
// http://www.recalbox.com
//

#include "utils/locale/LocaleHelper.h"
#include "hardware/Board.h"
#include "RootFolders.h"
#include "StorageDevices.h"

void StorageDevices::Initialize()
{
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

  // Add Internal
  mDevices.push_back(Device(Types::Internal, "SHARE",  sInternal, "RECALBOX", "exfat",_("Internal Share Partition"), current == sInternal, sizeInfos));

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
  String devicePath;
  String propertyLine;
  for(const String& line : GetRawDeviceList())
    if (line.Extract(':', devicePath, propertyLine, true))
    {
      // Avoid boot device partitions
      if (devicePath.StartsWith(mBootRoot)) continue;

      // Extract device properties
      PropertyMap properties = ExtractProperties(propertyLine);
      String uuid = "DEV " + properties.get_or_return_default("UUID");
      String label = properties.get_or_return_default("LABEL");
      if (label.empty()) label = "Unnamed";
      String filesystem = properties.get_or_return_default("TYPE");
      if (filesystem.empty()) filesystem = "fs?";
      String displayable = _("Device %d - %l (%f)");
      displayable.Replace("%d", Path(devicePath).Filename())
                 .Replace("%l", label)
                 .Replace("%f", filesystem);

      // Store
      mDevices.push_back(Device(Types::External, devicePath, uuid, label, filesystem, displayable, current == uuid, sizeInfos));
      { LOG(LogDebug) << "[Storage] External storage: " << devicePath << ' ' << uuid << " \"" << label << "\" " << filesystem; }
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
  return GetCommandOutput("blkid");
}

String::List StorageDevices::GetMountedDeviceList()
{
  return GetCommandOutput("mount");
}

StorageDevices::DeviceSizeInfo StorageDevices::GetFileSystemInfo()
{
  DeviceSizeInfo result;
  for(const String& line : GetCommandOutput("df -kP"))
  {
    String::List items = line.Split(' ', true);
    if (items.size() >= 6)
    {
      long long size = items[1].AsInt64();
      long long free = items[3].AsInt64();
      result[items[0]] = SizeInfo(size, free);
      // Special cases
      if (items[5] == RootFolders::DataRootFolder.ToString())
        result["SHARE"] = SizeInfo(size, free);
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

