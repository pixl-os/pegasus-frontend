// Pegasus Frontend
//
// Created by Bozo The Geek - 23/10/2021
//
#include "NetplayInfo.h"

namespace {
/* model::DeviceInfo::BatteryStatus sdl_state_to_qt(const SDL_PowerState sdl_state)
{
    using Status = model::DeviceInfo::BatteryStatus;
    switch (sdl_state) {
        case SDL_POWERSTATE_NO_BATTERY: return Status::NoBattery;
        case SDL_POWERSTATE_ON_BATTERY: return Status::Discharging;
        case SDL_POWERSTATE_CHARGING: return Status::Charging;
        case SDL_POWERSTATE_CHARGED: return Status::Charged;
        default: return Status::Unknown;
    }
}

model::DeviceInfo::BatteryInfo query_battery()
{
    return {model::DeviceInfo::BatteryStatus::Unknown, NAN, -1};
} */
} // namespace


namespace model {
NetplayInfo::NetplayInfo(QObject* parent)
    : QObject(parent)
{
	//TO DO : add timer to refresh lobbies
	//FOR RETROARCH - TO DO
	//FOR DOLPHIN - TO DO
	//FOR CITRA - TO DO
}
} // namespace model
