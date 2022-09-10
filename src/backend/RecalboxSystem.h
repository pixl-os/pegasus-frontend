#pragma once

#include <string>
#include <vector>
#include <utils/Strings.h>
#include <cstring>

// #include "WindowManager.h"
// #include "games/FileData.h"

struct EmulatorDefaults
{
  std::string core;
  std::string emulator;
};

/*!
 * @brief Interface between EmulationStation and the Recalbox System
 */
class RecalboxSystem
{
  public:
    static bool MakeBootReadOnly();

    static bool MakeBootReadWrite();

    static unsigned long long GetMinimumFreeSpaceOnSharePartition() { return 3LL << 30; } // 3Gb

    static unsigned long long getFreeSpace(const std::string& mountpoint);

    static unsigned long getFreeSpaceGB(const std::string& mountpoint);

    static std::string SizeToString(unsigned long long size);

    static std::string getFreeSpaceInfo();

    static bool isFreeSpaceLimit();

    static std::string getRootPassword();

    static std::vector<std::string> getAvailableWiFiSSID(bool activateWifi);

    static bool getWifiWps();

    static bool saveWifiWps();

    static bool getWifiConfiguration(std::string& ssid, std::string& psk);

    static bool setOverscan(bool enable);

    static bool setOverclock(const std::string& mode);

    static bool ping();

    // static bool kodiExists();

    // static bool launchKodi(WindowManager&window);

    static bool backupRecalboxConf();

    static bool enableWifi(std::string ssid, std::string key);

    static bool disableWifi();

    /*!
     * @brief Chech if the interface has a valid IP
     * @param interface false = ethernet, true = WIFI
     * @return True if the interface has a valid IP
     */
    static bool hasIpAdress(bool interface);

    static std::string getIpAdress();

    static std::vector<std::string> scanBluetooth();

    static bool pairBluetooth(const std::string& basic_string);

    static std::vector<std::string> getAvailableStorageDevices();

    static std::string getCurrentStorage();

    static bool setStorage(const std::string& basic_string);

    static bool forgetBluetoothControllers();

    static std::pair<std::string, int> execute(const std::string& command);

    static std::pair<std::string, int> getSDLBatteryInfo();

    static bool getSysBatteryInfo(int& charge, int& unicodeIcon);

  private:
    //! Share path
    static constexpr const char* sSharePath = "/recalbox/share/";
    static constexpr const char* sConfigScript = "/recalbox/scripts/recalbox-config.sh";

    static std::string BuildSettingsCommand(const std::string& arguments);

    static Strings::Vector ExecuteSettingsCommand(const std::string& arguments);
};

