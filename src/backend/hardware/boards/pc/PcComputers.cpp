//
// Created by bkg2k on 02/11/2020.
//
// From recalbox ES and Integrated by BozoTheGeek 12/04/2021 in Pegasus Front-end
//

#include <utils/os/fs/Path.h>
#include <utils/Files.h>
#include <utils/rLog.h>
#include "PcComputers.h"

void PcComputers::SetCPUGovernance(IBoardInterface::CPUGovernance cpuGovernance)
{
  switch (cpuGovernance)
  {
    case CPUGovernance::PowerSave:
    {
      { LOG(LogInfo) << "[CPU] Set powersaving mode"; }
      Files::SaveFile(Path(sCpuGovernancePath), "powersave");
      break;
    }
    case CPUGovernance::OnDemand:
    {
      { LOG(LogInfo) << "[CPU] Set on-demand mode"; }
      Files::SaveFile(Path(sCpuGovernancePath), "ondemand");
      break;
    }
    case CPUGovernance::FullSpeed:
    {
      { LOG(LogInfo) << "[CPU] Set performance mode"; }
      Files::SaveFile(Path(sCpuGovernancePath), "performance");
      break;
    }
    default: break;
  }
}

bool PcComputers::HasBattery()
{
  static bool hasBattery = Path(sBatteryCapacityPath1).Exists() ||
                           Path(sBatteryCapacityPath2).Exists();
  return hasBattery;
}

int PcComputers::BatteryChargePercent()
{
  static Path sBatteryCharge(Path(sBatteryCapacityPath1).Exists() ? sBatteryCapacityPath1 : sBatteryCapacityPath2);
  int charge = -1;
  Strings::ToInt(Strings::Trim(Files::LoadFile(sBatteryCharge), "\n"), charge);
  return charge;
}

bool PcComputers::IsBatteryCharging()
{
  static Path sBatteryStatus(Path(sBatteryStatusPath1).Exists() ? sBatteryStatusPath1 : sBatteryStatusPath2);
  return Strings::Trim(Files::LoadFile(sBatteryStatus), "\n") == "Charging";
}
