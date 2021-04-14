//
// From recalbox ES and Integrated by BozoTheGeek 12/04/2021 in Pegasus Front-end
//

#pragma once

#include <string>
#include "BoardType.h"
#include "IBoardInterface.h"
#include <utils/cplusplus/StaticLifeCycleControler.h>
#include <hardware/messaging/HardwareMessageSender.h>

// Forward declaration
class InputCompactEvent;

class Board: public StaticLifeCycleControler<Board>
{
  public:
    /*!
     * @brief Constructor
     * @param notificationInterface Notification interface
     */
    explicit Board();

    //! Destructor
    ~Board()
    {
      delete mBoard;
    }

    /*!
     * @brief Get board type
     * @return Board type
     */
    BoardType GetBoardType();

    /*!
     * @brief Get brightness support
     * @return True if the current board support brightness, false otherwise
     */
    bool HasBrightnessSupport() { return mBoard->HasBrightnessSupport(); }

    /*!
     * @brief Set brightness
     * @param step Step value from 0 to 8
     */
    void SetBrightness(int step) { mBoard->SetBrightness(step); }

    /*!
     * @brief Set lowerst brightness available or even switch off the screen
     * @param step Step value from 0 to 8
     */
    void SetLowestBrightness() { mBoard->SetLowestBrightness(); };

    /*!
     * @brief Check if the current board has battery
     * @return
     */
    bool HasBattery() { return mBoard->HasBattery(); }

    /*!
     * @brief Get battery charge in percent
     * @return Battery charge (-1 = no battery)
     */
    int BatteryChargePercent() { return mBoard->BatteryChargePercent(); }

    /*!
     * @brief Check if the battery is charging
     * @return True = charging, False = discharging or no battery
     */
    bool IsBatteryCharging() { return mBoard->IsBatteryCharging(); }

    /*!
     * @brief Set CPU governance
     * @param cpuGovernance CPU governance
     */
    void SetCPUGovernance(IBoardInterface::CPUGovernance cpuGovernance) { mBoard->SetCPUGovernance(cpuGovernance); }

    /*!
     * @brief Check if this board has extra volume +/- buttons
     * @return True if such buttons are available, false otherwise
     */
    bool HasPhysicalVolumeButtons() { return mBoard->HasMappableVolumeButtons(); }

    /*!
     * @brief Check if this board has extra brightness +/- buttons
     * @return True if such buttons are available, false otherwise
     */
    bool HasPhysicalBrightnessButtons() { return mBoard->HasMappableBrightnessButtons(); }

    /*!
     * @brief Check if the current board supports suspend/resume operations
     * @return True if the board supports suspend/resume operations, false otherwise
     */
    bool HasSuspendResume() { return mBoard->HasSuspendResume(); }

    /*!
     * @brief Suspend!
     */
    void Suspend() { mBoard->Suspend(); }

    /*!
     * @brief Start optional global background processes
     * This method is called when ES starts
     */
    void StartGlobalBackgroundProcesses()
    {
      { LOG(LogInfo) << "[Hardware] Start global Hardware processes"; }
      return mBoard->StartGlobalBackgroundProcesses();
    }

    /*!
     * @brief Stop optional global background processes
     * This method is called when ES stops
     */
    void StopGlobalBackgroundProcesses()
    {
      { LOG(LogInfo) << "[Hardware] Stop global Hardware processes"; }
      return mBoard->StopGlobalBackgroundProcesses();
    }

    /*!
     * @brief Start optional in-game background processes.
     * This method is called when a game starts
     */
    void StartInGameBackgroundProcesses()
    {
      { LOG(LogInfo) << "[Hardware] Start in-game Hardware processes"; }
      return mBoard->StartInGameBackgroundProcesses();
    }

    /*!
     * @brief Stop optional in-game background processes.
     * This method is called when a game stops
     */
    void StopInGameBackgroundProcesses()
    {
      { LOG(LogInfo) << "[Hardware] Start in-game Hardware processes"; }
      return mBoard->StopInGameBackgroundProcesses();
    }

  private:
    //static constexpr const char* sBatteryCapacityPath1 = "/sys/class/power_supply/BAT0/capacity";
    //static constexpr const char* sBatteryCapacityPath2 = "/sys/class/power_supply/battery/capacity";
    //static constexpr const char* sBatteryStatusPath1 = "/sys/class/power_supply/BAT0/status";
    //static constexpr const char* sBatteryStatusPath2 = "/sys/class/power_supply/battery/status";

    //! Board type
    BoardType mType;
    //! Synchronous message sender
    HardwareMessageSender mSender;
    //! Real hardware board interface implementation
    IBoardInterface* mBoard;

    //! Get board interface
    IBoardInterface* GetBoardInterface(HardwareMessageSender& messageSender);

    /*!
     * Raspberry model (real models)
     * https://www.raspberrypi.org/documentation/hardware/raspberrypi/revision-codes/README.md
     */
    enum class RaspberryModel
    {
        OneA        = 0x00,
        OneB        = 0x01,
        OneAPlus    = 0x02,
        OneBPlus    = 0x03,
        TwoB        = 0x04,
        Alpha       = 0x05,
        OneCM1      = 0x06,
        TreeB       = 0x08,
        Zero        = 0x09,
        TreeCM3     = 0x0A,
        ZeroW       = 0x0C,
        TreeBPlus   = 0x0D,
        TreeAPlus   = 0x0E,
        TreeCM3Plus = 0x10,
        FourB       = 0x11,
        FourHundred = 0x13,
        FourCM4     = 0x14,
    };

    /*!
     * @brief Extract RPi modem
     * @param revision raw revision number
     * @return RPi model
     */
    static BoardType GetPiModel(unsigned int revision);
};
