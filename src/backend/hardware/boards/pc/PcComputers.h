//
// Created by bkg2k on 02/11/2020.
//
// From recalbox ES and Integrated by BozoTheGeek 12/04/2021 in Pegasus Front-end
//
#pragma once

#include <hardware/messaging/IHardwareNotifications.h>
#include "hardware/IBoardInterface.h"

class PcComputers: public IBoardInterface
{
  public:
    explicit PcComputers(HardwareMessageSender& messageSender)
      : IBoardInterface(messageSender)
    {
    }

  private:
    static constexpr const char* sCpuGovernancePath    = "/sys/devices/system/cpu/cpu0/cpufreq/scaling_governor";
    static constexpr const char* sBatteryCapacityPath1 = "/sys/class/power_supply/BAT0/capacity";
    static constexpr const char* sBatteryStatusPath1   = "/sys/class/power_supply/BAT0/status";
    static constexpr const char* sBatteryCapacityPath2 = "/sys/class/power_supply/BAT1/capacity";
    static constexpr const char* sBatteryStatusPath2   = "/sys/class/power_supply/BAT1/status";

    /*!
     * @brief Start optional global background processes
     * This method is called when ES starts
     */
    void StartGlobalBackgroundProcesses() final {}

    /*!
     * @brief Stop optional global background processes
     * This method is called when ES stops
     */
    void StopGlobalBackgroundProcesses() final {}

    /*!
     * @brief Start optional in-game background processes.
     * This method is called when a game starts
     */
    void StartInGameBackgroundProcesses() final {}

    /*!
     * @brief Stop optional in-game background processes.
     * This method is called when a game stops
     */
    void StopInGameBackgroundProcesses() final {}

    /*!
     * @brief Has Battery?
     */
    bool HasBattery() final;

    /*!
     * @brief Has CPU governance? (and is it worth the use)
     */
    bool HasCPUGovernance() final { return true; }

    /*!
     * @brief Has physical volume buttons?
     */
    bool HasMappableVolumeButtons() final { return false; }

    /*!
     * @brief Has physical brightness buttons?
     */
    bool HasMappableBrightnessButtons() final { return false; }

    /*!
     * @brief Has physical brightness buttons?
     */
    bool HasBrightnessSupport() final { return false; }

    /*!
     * @brief Has hardware suspend/resume?
     */
    bool HasSuspendResume() final { return false; }

    /*!
     * @brief Set lowest brightess possible, including black screen
     */
    void SetLowestBrightness() final {}

    /*!
     * @brief Set brightness
     * @param brighness brightness step from 0 to 8 included
     */
    void SetBrightness(int brighness) final { (void)brighness; }

    /*!
     * @brief Set new CPU governance
     * @param governance cpu governance
     */
    void SetCPUGovernance(CPUGovernance governance) final;

    /*!
     * @brief Process special input if any
     * @param inputEvent Input to process
     * @return True if the input has been processed, false otherwise
     */
    //bool ProcessSpecialInputs(InputCompactEvent& inputEvent) final { (void)inputEvent; return false; }

    /*!
     * @brief Suspend!
     */
    void Suspend() final {}

    /*!
     * @brief Get battery charge in percent
     * @return Battery charge (-1 = no battery)
     */
    int BatteryChargePercent() final;

    /*!
     * @brief Check if the battery is charging
     * @return True = charging, False = discharging or no battery
     */
    bool IsBatteryCharging() final;
};
