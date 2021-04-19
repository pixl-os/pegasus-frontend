//
// Created by bkg2k on 21/02/2021.
//
// As part of the RECALBOX Project
// http://www.recalbox.com
//

#include <utils/IniFile.h>
#include <utils/locale/LocaleHelper.h>
#include <hardware/Board.h>
#include "StorageDevices.h"

void StorageDevices::Initialize()
{
  AnalyseMounts();
  std::string current = GetStorageDevice();

  // Ram?
  if (mShareInRAM)
  {
    current = "RAM";
    mDevices.push_back({ Types::Ram, "",  sInMemory, "RECALBOX", "tmpfs",_("In Memory!")+ " \u26a0", true });
    LOG(LogWarning) << "[Storage] Share is stored in memory!";
  }

  // Add Internal
  mDevices.push_back({ Types::Internal, "",  sInternal, "RECALBOX", "exfat",_("Internal Share Partition"), current == sInternal });

  // // Go advance does not support external storage
  // if ((Board::Instance().GetBoardType() == BoardType::OdroidAdvanceGo) ||
  //     (Board::Instance().GetBoardType() == BoardType::OdroidAdvanceGoSuper)) return;

  // Network
  if (mBootConfiguration.HasKeyStartingWith("sharenetwork_") || mBootConfiguration.AsString("sharedevice") == "NETWORK")
  {
    mDevices.push_back({ Types::Internal, "", sNetwork, "", "", _("Network Share"), current == sNetwork});
    LOG(LogDebug) << "[Storage] Network share configuration detected";
  }

  // Any external
  // Add Internal
  mDevices.push_back({ Types::Internal, "",  sAnyExternal, "", "",_("Any External Device"), current == sAnyExternal });

  // External Devices
  std::string devicePath;
  std::string propertyLine;
  for(const std::string& line : GetRawDeviceList())
    if (Strings::SplitAt(line, ':', devicePath, propertyLine, true))
    {
      // Avoid SD cards
      if (Strings::StartsWith(devicePath, mBootRoot)) continue;

      // Extract device properties
      PropertyMap properties = ExtractProperties(propertyLine);
      std::string uuid = "DEV " + properties.get_or_return_default("UUID");
      std::string label = properties.get_or_return_default("LABEL");
      if (label.empty()) label = "Unnamed";
      std::string filesystem = properties.get_or_return_default("TYPE");
      if (filesystem.empty()) filesystem = "fs?";
      std::string displayable = _("Device %d - %l (%f)");
      Strings::ReplaceAllIn(displayable, "%d", devicePath);
      Strings::ReplaceAllIn(displayable, "%l", label);
      Strings::ReplaceAllIn(displayable, "%f", filesystem);

      // Store
      mDevices.push_back({ Types::External, devicePath, uuid, label, filesystem, displayable, current == uuid });
      LOG(LogDebug) << "[Storage] External storage: " << devicePath << ' ' << uuid << " \"" << label << "\" " << filesystem;
    }
}

Strings::Vector StorageDevices::GetCommandOutput(const std::string& command)
{
  std::string output;
  char buffer[4096];
  FILE* pipe = popen(command.data(), "r");
  if (pipe != nullptr)
  {
    while (feof(pipe) == 0)
      if (fgets(buffer, sizeof(buffer), pipe) != nullptr)
        output.append(buffer);
    pclose(pipe);
  }
  return Strings::Split(output, '\n');
}

Strings::Vector StorageDevices::GetRawDeviceList()
{
  return GetCommandOutput("blkid");
}

Strings::Vector StorageDevices::GetMountedDeviceList()
{
  return GetCommandOutput("mount");
}

StorageDevices::PropertyMap StorageDevices::ExtractProperties(const std::string& properties)
{
  PropertyMap map;

  std::string key;
  std::string value;
  for(const std::string& kv : Strings::SplitQuotted(properties, ' '))
    if (Strings::SplitAt(kv, '=', key, value, true))
      map[key] = Strings::Trim(value, "\"");

  return map;
}

void StorageDevices::SetStorageDevice(const StorageDevices::Device& device)
{
  mBootConfiguration.SetString(sShareDevice, device.UUID);
  mBootConfiguration.Save();
}

std::string StorageDevices::GetStorageDevice()
{
  return mBootConfiguration.AsString(sShareDevice, sInternal);
}

void StorageDevices::AnalyseMounts()
{
  for(const std::string& line : GetMountedDeviceList())
  {
    Strings::Vector items = Strings::Split(line, ' ', true);
    if (items.size() < 6)
    {
      LOG(LogError) << "[Storage] Uncomplete mount line: " << line;
      continue;
    }
    if (items[2] == "/recalbox/share") mShareInRAM =  (items[4] == "tmpfs");
    else if (items[2] == "/boot") mBootRoot = Strings::Trim(items[0], "0123456789");
  }
  LOG(LogDebug) << "[Storage] BootRoot: " << mBootRoot << " - Is In Ram: " << mShareInRAM;
}

