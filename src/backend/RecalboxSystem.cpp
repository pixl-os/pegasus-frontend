/*
 * File:   RecalboxSystem.cpp
 * Author: digitallumberjack
 * 
 * Created on 29 novembre 2014, 03:1
 */

#include "RecalboxSystem.h"
#include <sys/statvfs.h>
#include "utils/rLog.h"
// #include "audio/AudioManager.h"

#include <ifaddrs.h>
#include <netinet/in.h>
#include <arpa/inet.h>
#include <utils/Files.h>
// #include <MainRunner.h>
// #include <Upgrade.h>
#include <utils/locale/LocaleHelper.h>
#include <utils/IniFile.h>
// #include <input/InputMapper.h>

std::string RecalboxSystem::BuildSettingsCommand(const std::string& arguments)
{
  std::string result = sConfigScript;
  result.append(1, ' ');
  result.append(arguments);
  return result;
}

Strings::Vector RecalboxSystem::ExecuteSettingsCommand(const std::string& arguments)
{
  std::string output;
  char buffer[1024];
  FILE* pipe = popen(BuildSettingsCommand(arguments).c_str(), "r");
  if (pipe != nullptr)
  {
    while (feof(pipe) == 0)
      if (fgets(buffer, sizeof(buffer), pipe) != nullptr)
        output.append(buffer);
    pclose(pipe);
  }
  return Strings::Split(output, '\n');
}

unsigned long long RecalboxSystem::getFreeSpace(const std::string& mountpoint)
{
  struct statvfs fiData {};
  const char* fnPath = mountpoint.c_str();
  unsigned long long free = 0;
  if ((statvfs(fnPath, &fiData)) >= 0)
  {
    free = (((unsigned long long)fiData.f_bfree * (unsigned long long)fiData.f_bsize));
  }
  return free;
}

unsigned long RecalboxSystem::getFreeSpaceGB(const std::string& mountpoint)
{
  return (unsigned long)(getFreeSpace(mountpoint) >> 30);
}

std::string RecalboxSystem::SizeToString(unsigned long long size)
{
  if ((size >> 30) != 0) return std::to_string((int)(size >> 30)) + "GB";
  if ((size >> 20) != 0) return std::to_string((int)(size >> 20)) + "MB";
  if ((size >> 10) != 0) return std::to_string((int)(size >> 10)) + "KB";
  return std::to_string((int)size) + 'B';
}

std::string RecalboxSystem::getFreeSpaceInfo()
{
  std::string sharePart = sSharePath;
  std::string result = "N/A";
  if (!sharePart.empty())
  {
    const char* fnPath = sharePart.c_str();
    struct statvfs fiData {};
    if ((statvfs(fnPath, &fiData)) < 0)
    {
      result += " (SYSTEM ERROR)";
    }
    else
    {
      unsigned long long total = ((unsigned long long)fiData.f_blocks * (unsigned long long)fiData.f_bsize);
      unsigned long long free = ((unsigned long long)fiData.f_bfree * (unsigned long long)fiData.f_bsize);
      if (total != 0)
      {
        unsigned long long used = total - free;
        int percent = (int)(used * 100 / total);
        result = SizeToString(used) + '/' + SizeToString(total) + " (" + std::to_string(percent) + "%)";
      }
    }
  }
  else result += " (NO PARTITION)";

  return result;
}

bool RecalboxSystem::isFreeSpaceLimit()
{
  std::string sharePart = sSharePath;
  if (!sharePart.empty())
  {
    return getFreeSpace(sharePart) < GetMinimumFreeSpaceOnSharePartition();
  }
  else
  {
    return false; //"ERROR";
  }

}

std::vector<std::string> RecalboxSystem::getAvailableWiFiSSID(bool activatedWifi)
{
  if (!activatedWifi) enableWifi("", "");
  std::vector<std::string> result = ExecuteSettingsCommand("wifi list");
  if (!activatedWifi) disableWifi();

  return result;
}

bool RecalboxSystem::setOverscan(bool enable)
{
  std::string cmd(sConfigScript);
  cmd += " overscan";
  cmd += enable ? " enable" : " disable";
  { LOG(LogInfo) << "[System] Launching " << cmd; }
  if (system(cmd.c_str()) != 0)
  {
    { LOG(LogWarning) << "[System] Error executing " << cmd; }
    return false;
  }
  else
  {
    { LOG(LogInfo) << "[System] Overscan set to : " << enable; }
    return true;
  }

}

 /*bool RecalboxSystem::setOverclock(const std::string& mode)
 {
   if (!mode.empty())
   {
     std::string cmd(sConfigScript);
     cmd += " overclock";
     cmd += ' ';
     cmd += mode;
     { LOG(LogInfo) << "[System] Launching " << cmd; }
     if (system(cmd.c_str()) != 0)
     {
       { LOG(LogWarning) << "[System] Error executing " << cmd; }
       return false;
     }
     else
     {
       { LOG(LogInfo) << "[System] Overclocking set to " << mode; }
       return true;
     }
   }

   return false;
 }

 bool RecalboxSystem::launchKodi(WindowManager& window)
 {
   { LOG(LogInfo) << "[System] Attempting to launch kodi..."; }

   AudioManager::Instance().Deactivate();

   InputMapper mapper(nullptr);
   //OrderedDevices controllers = InputManager::Instance().GenerateConfiguration(mapper);
   std::string commandline = InputManager::Instance().GetMappedDeviceListConfiguration(mapper);
   std::string command = "configgen -system kodi -rom '' " + commandline;

   WindowManager::Finalize();

   NotificationManager::Instance().NotifyKodi();

   int exitCode = system(command.c_str());
   if (WIFEXITED(exitCode))
   {
     exitCode = WEXITSTATUS(exitCode);
   }

   window.Initialize();
   AudioManager::Instance().Reactivate();
   window.normalizeNextUpdate();

   // handle end of kodi
   switch (exitCode)
   {
     case 10: // reboot code
     {
       MainRunner::RequestQuit(MainRunner::ExitState::NormalReboot);
       return true;
     }
     case 11: // shutdown code
     {
       MainRunner::RequestQuit(MainRunner::ExitState::Shutdown);
       return true;
     }
     default: break;
   }

   return exitCode == 0;
 }*/

bool RecalboxSystem::backupRecalboxConf()
{
  std::string cmd(sConfigScript);
  cmd += " configbackup";
  { LOG(LogInfo) << "[System] Launching " << cmd; }
  if (system(cmd.c_str()) == 0)
  {
    { LOG(LogInfo) << "[System] recalbox.conf backup'ed successfully"; }
    return true;
  }
  else
  {
    { LOG(LogInfo) << "[System] recalbox.conf backup failed"; }
    return false;
  }
}

bool RecalboxSystem::enableWifi(std::string ssid, std::string key)
{
  ssid = Strings::Replace(ssid, "\"", "\\\"");
  key = Strings::Replace(key, "\"", "\\\"");
  std::string cmd(sConfigScript);
  cmd += " wifi enable \"" + ssid + "\" \"" + key + "\"";
  { LOG(LogInfo) << "[System] Launching " << cmd; }
  if (system(cmd.c_str()) == 0)
  {
    { LOG(LogInfo) << "[System] Wifi enabled "; }
    return true;
  }
  else
  {
    { LOG(LogInfo) << "[System] Cannot enable wifi "; }
    return false;
  }
}

bool RecalboxSystem::disableWifi()
{
  std::string cmd(sConfigScript);
  cmd += " wifi disable";
  { LOG(LogInfo) << "[System] Launching " << cmd; }
  if (system(cmd.c_str()) == 0)
  {
    { LOG(LogInfo) << "[System] Wifi disabled "; }
    return true;
  }
  else
  {
    { LOG(LogInfo) << "[System] Cannot disable wifi "; }
    return false;
  }
}

bool RecalboxSystem::getWifiWps()
{
  bool result = false;
  Strings::Vector lines = ExecuteSettingsCommand("wifi wps");
  for(const std::string& line : lines)
    if (Strings::StartsWith(line, STRING_AND_LENGTH("OK")))
    {
      result = true;
      break;
    }
  return result;
}

bool RecalboxSystem::saveWifiWps()
{
  bool result = false;
  Strings::Vector lines = ExecuteSettingsCommand("wifi save");
  for(const std::string& line : lines)
    if (Strings::StartsWith(line, STRING_AND_LENGTH("OK")))
    {
      result = true;
      break;
    }
  return result;
}

bool RecalboxSystem::getWifiConfiguration(std::string& ssid, std::string& psk)
{
  IniFile wpaConfiguration(Path("/etc/wpa_supplicant.conf"));
  ssid = Strings::Trim(wpaConfiguration.AsString("ssid"), " \"");
  psk = Strings::Trim(wpaConfiguration.AsString("psk"), " \"");
  return !ssid.empty() && !psk.empty();
}

std::string RecalboxSystem::getIpAdress()
{
  struct ifaddrs* ifAddrStruct = nullptr;

  std::string result = "NOT CONNECTED";
  getifaddrs(&ifAddrStruct);

  for (struct ifaddrs* ifa = ifAddrStruct; ifa != nullptr; ifa = ifa->ifa_next)
  {
    if (ifa->ifa_addr == nullptr)
    {
      continue;
    }
    if (ifa->ifa_addr->sa_family == AF_INET)
    { // check it is IP4
      // is a valid IP4 Address
      void* tmpAddrPtr = &((struct sockaddr_in*) ifa->ifa_addr)->sin_addr;
      char addressBuffer[INET_ADDRSTRLEN];
      inet_ntop(AF_INET, tmpAddrPtr, addressBuffer, INET_ADDRSTRLEN);
      printf("%s IP Address %s\n", ifa->ifa_name, addressBuffer);
      if (std::string(ifa->ifa_name).find("eth") != std::string::npos ||
          std::string(ifa->ifa_name).find("wlan") != std::string::npos)
      {
        result = std::string(addressBuffer);
        break;
      }
    }
  }
  // Seeking for ipv6 if no IPV4
  if (result == "NOT CONNECTED")
  {
    for (struct ifaddrs* ifa = ifAddrStruct; ifa != nullptr; ifa = ifa->ifa_next)
    {
      if (ifa->ifa_addr == nullptr)
      {
        continue;
      }
      if (ifa->ifa_addr->sa_family == AF_INET6)
      { // check it is IP6
        // is a valid IP6 Address
        void* tmpAddrPtr = &((struct sockaddr_in6*) ifa->ifa_addr)->sin6_addr;
        char addressBuffer[INET6_ADDRSTRLEN];
        inet_ntop(AF_INET6, tmpAddrPtr, addressBuffer, INET6_ADDRSTRLEN);
        printf("%s IP Address %s\n", ifa->ifa_name, addressBuffer);
        if (std::string(ifa->ifa_name).find("eth") != std::string::npos ||
            std::string(ifa->ifa_name).find("wlan") != std::string::npos)
        {
          result = std::string(addressBuffer);
          break;
        }
      }
    }
  }
  if (ifAddrStruct != nullptr) freeifaddrs(ifAddrStruct);
  return result;
}

bool RecalboxSystem::hasIpAdress(bool interface)
{
  const char* itfName = interface ? "wlan0" : "eth0";

  bool result = false;
  struct ifaddrs* ifAddrStruct = nullptr;
  getifaddrs(&ifAddrStruct);

  for (struct ifaddrs* ifa = ifAddrStruct; ifa != nullptr; ifa = ifa->ifa_next)
  {
    if (ifa->ifa_addr == nullptr) continue;
    if (ifa->ifa_addr->sa_family == AF_INET)
    {
      void* tmpAddrPtr = &((struct sockaddr_in*) ifa->ifa_addr)->sin_addr;
      char addressBuffer[INET_ADDRSTRLEN];
      inet_ntop(AF_INET, tmpAddrPtr, addressBuffer, INET_ADDRSTRLEN);
      if (strstr(ifa->ifa_name, itfName) == ifa->ifa_name)
      {
        result = true;
        break;
      }
    }
  }
  // Seeking for ipv6 if no IPV4
  if (!result)
    for (struct ifaddrs* ifa = ifAddrStruct; ifa != nullptr; ifa = ifa->ifa_next)
    {
      if (ifa->ifa_addr == nullptr) continue;
      if (ifa->ifa_addr->sa_family == AF_INET6)
      {
        void* tmpAddrPtr = &((struct sockaddr_in6*) ifa->ifa_addr)->sin6_addr;
        char addressBuffer[INET6_ADDRSTRLEN];
        inet_ntop(AF_INET6, tmpAddrPtr, addressBuffer, INET6_ADDRSTRLEN);
        if (strstr(ifa->ifa_name, itfName) == ifa->ifa_name)
        {
          result = true;
          break;
        }
      }
    }

  if (ifAddrStruct != nullptr) freeifaddrs(ifAddrStruct);
  return result;
}

std::vector<std::string> RecalboxSystem::scanBluetooth()
{
  return ExecuteSettingsCommand("hcitoolscan");
}

bool RecalboxSystem::pairBluetooth(const std::string& controller)
{
  std::string escapedController(controller);
  Strings::ReplaceAllIn(escapedController, "(", "\\(");
  Strings::ReplaceAllIn(escapedController, ")", "\\)");
  Strings::ReplaceAllIn(escapedController, "*", "\\*");
  Strings::ReplaceAllIn(escapedController, "'", "\\'");
  Strings::ReplaceAllIn(escapedController, "\"", "\\\"");
  std::string cmd(sConfigScript);
  cmd += " hiddpair " + escapedController;
  int exitcode = system(cmd.c_str());
  return exitcode == 0;
}

std::vector<std::string> RecalboxSystem::getAvailableStorageDevices()
{
  return ExecuteSettingsCommand("storage list");
}

std::string RecalboxSystem::getCurrentStorage()
{
  Strings::Vector lines = ExecuteSettingsCommand("storage current");
  return lines.empty() ? "INTERNAL" : lines[0];
}

bool RecalboxSystem::setStorage(const std::string& selected)
{
  std::string cmd(sConfigScript);
  cmd += " storage " + selected;
  int exitcode = system(cmd.c_str());
  return exitcode == 0;
}

bool RecalboxSystem::forgetBluetoothControllers()
{
  std::string cmd(sConfigScript);
  cmd += " forgetBT";
  int exitcode = system(cmd.c_str());
  return exitcode == 0;
}

std::string RecalboxSystem::getRootPassword()
{
  Strings::Vector lines = ExecuteSettingsCommand("getRootPassword");
  return lines.empty() ? "" : lines[0];
}

std::pair<std::string, int> RecalboxSystem::execute(const std::string& command)
{
  FILE* pipe = popen(command.c_str(), "r");
  char line[1024];

  if (pipe == nullptr)
  {
    return std::make_pair("", -1);
  }
  std::string output;
  while (fgets(line, 1024, pipe) != nullptr)
  {
    output += line;
  }
  int exitCode = pclose(pipe);
  return std::make_pair(output, WEXITSTATUS(exitCode));
}

 /* bool RecalboxSystem::ping()
 {
   return Upgrade::NetworkReady();
 }

 std::pair<std::string, int> RecalboxSystem::getSDLBatteryInfo()
 {
   std::pair<std::string, int> result;
   int percent = -1;
   auto powerInfo = SDL_GetPowerInfo(nullptr, &percent);
   switch (powerInfo)
   {
     case SDL_POWERSTATE_UNKNOWN:
     case SDL_POWERSTATE_NO_BATTERY:
     {
       percent = -1;
       break;
     }
     case SDL_POWERSTATE_ON_BATTERY:
     {
       if (percent > 66)
         result.first = "\uF1ba";
       else if (percent > 33)
         result.first = "\uF1b8";
       else if (percent > 15)
         result.first = "\uF1b1";
       else
         result.first = "\uF1b5";
       break;
     }
     case SDL_POWERSTATE_CHARGING:
     case SDL_POWERSTATE_CHARGED:
     {
       result.first = "\uf1b4";
       break;
     }
   }
   result.second = percent;

   return result;
 }

 bool RecalboxSystem::getSysBatteryInfo(int& charge, int& unicodeIcon)
 {
   if (!Board::Instance().HasBattery()) return false;

   charge = Board::Instance().BatteryChargePercent();

   unicodeIcon = 0xf1b4;
   if (!Board::Instance().IsBatteryCharging())
   {
     if (charge > 66)      unicodeIcon = 0xF1ba;
     else if (charge > 33) unicodeIcon = 0xF1b8;
     else if (charge > 15) unicodeIcon = 0xF1b1;
     else                  unicodeIcon = 0xF1b5;
   }

   return true;
 }

 bool RecalboxSystem::kodiExists()
 {
   return Path("/usr/bin/kodi").IsFile();
 } */

bool RecalboxSystem::MakeBootReadOnly()
{
  return system("mount -o remount,ro /boot") == 0;
}

bool RecalboxSystem::MakeBootReadWrite()
{
  return system("mount -o remount,rw /boot") == 0;
}
