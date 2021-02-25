// Pegasus Frontend
// Copyright (C) 2017-2019  Mátyás Mustoha
//
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with this program. If not, see <http://www.gnu.org/licenses/>.


#include "GamepadManager.h"

#include "Log.h"
#include "ScriptRunner.h"
#include "RecalboxConf.h"

#ifdef WITH_SDL_GAMEPAD
#  include "GamepadManagerSDL2.h"
#else
#  include "GamepadManagerQt.h"
#endif


namespace {
void call_gamepad_reconfig_scripts()
{
    ScriptRunner::run(ScriptEvent::CONFIG_CHANGED);
    ScriptRunner::run(ScriptEvent::CONTROLS_CHANGED);
}

QQmlObjectListModel<model::Gamepad>::const_iterator
find_by_deviceid(QQmlObjectListModel<model::Gamepad>& model, int device_id)
{
    return std::find_if(
        model.constBegin(),
        model.constEnd(),
        [device_id](const model::Gamepad* const gp){ return gp->deviceId() == device_id; });
}

inline QString pretty_id(int device_id) {
    return QLatin1String("0x") % QString::number(device_id, 16);
}
} // namespace


namespace model {

GamepadManager::GamepadManager(const backend::CliArgs& args, QObject* parent)
    : QObject(parent)
    , m_devices(new QQmlObjectListModel<model::Gamepad>(this))
    , m_log_tag(QStringLiteral("Gamepad"))
#ifdef WITH_SDL_GAMEPAD
    , m_backend(new GamepadManagerSDL2(this))
#else
    , m_backend(new GamepadManagerQt(this))
#endif
{
    connect(m_backend, &GamepadManagerBackend::connected,
            this, &GamepadManager::bkOnConnected);
    connect(m_backend, &GamepadManagerBackend::disconnected,
            this, &GamepadManager::bkOnDisconnected);
    connect(m_backend, &GamepadManagerBackend::nameChanged,
            this, &GamepadManager::bkOnNameChanged);

    connect(m_backend, &GamepadManagerBackend::buttonConfigured,
            this, &GamepadManager::bkOnButtonCfg);
    connect(m_backend, &GamepadManagerBackend::axisConfigured,
            this, &GamepadManager::bkOnAxisCfg);
    connect(m_backend, &GamepadManagerBackend::configurationCanceled,
            this, &GamepadManager::configurationCanceled);

    connect(m_backend, &GamepadManagerBackend::buttonChanged,
            this, &GamepadManager::bkOnButtonChanged);
    connect(m_backend, &GamepadManagerBackend::axisChanged,
            this, &GamepadManager::bkOnAxisChanged);

#ifndef Q_OS_ANDROID
    connect(m_backend, &GamepadManagerBackend::buttonChanged,
            &padbuttonnav, &GamepadButtonNavigation::onButtonChanged);
    connect(m_backend, &GamepadManagerBackend::axisChanged,
            &padaxisnav, &GamepadAxisNavigation::onAxisEvent);

    connect(&padaxisnav, &GamepadAxisNavigation::buttonChanged,
            &padbuttonnav, &GamepadButtonNavigation::onButtonChanged);
#endif // Q_OS_ANDROID

    m_backend->start(args);
}

void GamepadManager::configureButton(int deviceId, GMButton button)
{
    Q_ASSERT(button != GMButton::Invalid);
    m_backend->start_recording(deviceId, static_cast<GamepadButton>(button));
}
void GamepadManager::configureAxis(int deviceId, GMAxis axis)
{
    Q_ASSERT(axis != GMAxis::Invalid);
    m_backend->start_recording(deviceId, static_cast<GamepadAxis>(axis));
}
void GamepadManager::cancelConfiguration() {
    m_backend->cancel_recording();
}

void GamepadManager::bkOnConnected(int device_id, QString name)
{
    if (name.isEmpty())
        name = QLatin1String("generic");

    m_devices->append(new Gamepad(device_id, name, m_devices));

    Log::info(m_log_tag, LOGMSG("Connected device %1 (%2)").arg(pretty_id(device_id), name));
    Log::debug(m_log_tag, LOGMSG("From device_id : %1").arg(device_id));
#ifdef WITH_SDL_GAMEPAD
    Log::debug(m_log_tag, LOGMSG("From path : %1").arg(SDL_JoystickDevicePathById(device_id)));
   
    //Get GUID
    constexpr size_t GUID_LEN = 33; // 16x2 + null
    std::array<char, GUID_LEN> guid_raw_str;
    const SDL_JoystickGUID guid = SDL_JoystickGetDeviceGUID(device_id);
    SDL_JoystickGetGUIDString(guid, guid_raw_str.data(), guid_raw_str.size());    
    // concatenation doesn't work with QLatin1Strings...
    const auto guid_str = QLatin1String(guid_raw_str.data()).trimmed();
    Log::debug(m_log_tag, LOGMSG("With gUId : %1").arg(guid_str));
    // const auto name = QLatin1String(SDL_JoystickNameForIndex(device_idx));
    // constexpr auto default_mapping("," // emscripten default
        // "a:b0,b:b1,x:b2,y:b3,"
        // "dpup:b12,dpdown:b13,dpleft:b14,dpright:b15,"
        // "leftshoulder:b4,rightshoulder:b5,lefttrigger:b6,righttrigger:b7,"
        // "back:b8,start:b9,guide:b16,"
        // "leftstick:b10,rightstick:b11,"
        // "leftx:a0,lefty:a1,rightx:a2,righty:a3");

    //persistence saved in recalbox.conf
    const QString Parameter = QString("pegasus.pad%1").arg(device_id);
    const QString Value = QString("%1:%2:%3").arg(name,guid_str,SDL_JoystickDevicePathById(device_id));
    Log::debug(m_log_tag, LOGMSG("Saved as %1=%2").arg(Parameter,Value));
    RecalboxConf::Instance().SetString(Parameter.toUtf8().constData(), Value.toUtf8().constData());
    //save in file for test purpose
    RecalboxConf::Instance().Save();
    Log::debug(LOGMSG("Recalbox.conf saved."));
#endif    
    
    //TO DO : save info in file to know that controller is connected with /dev/input/event? info + finger print ?!
    
    emit connected(device_id);
}

void GamepadManager::bkOnDisconnected(int device_id)
{
    QString name;

    const auto it = find_by_deviceid(*m_devices, device_id);
    if (it != m_devices->constEnd()) {
        name = (*it)->name();
        m_devices->remove(*it);
    }

    Log::info(m_log_tag, LOGMSG("Disconnected device %1 (%2)").arg(pretty_id(device_id), name));
    
    //TO DO: update file to know that controller is disconnected
    
    emit disconnected(std::move(name));
}

void GamepadManager::bkOnNameChanged(int device_id, QString name)
{
    const auto it = find_by_deviceid(*m_devices, device_id);
    if (it != m_devices->constEnd()) {
        Log::info(m_log_tag, LOGMSG("Set name of device %1 to '%2'").arg(pretty_id(device_id), name));
        (*it)->setName(std::move(name));
    }
}

void GamepadManager::bkOnButtonCfg(int device_id, GamepadButton button)
{
    call_gamepad_reconfig_scripts();
    emit buttonConfigured(device_id, static_cast<GMButton>(button));
}

void GamepadManager::bkOnAxisCfg(int device_id, GamepadAxis axis)
{
    call_gamepad_reconfig_scripts();
    emit axisConfigured(device_id, static_cast<GMAxis>(axis));
}

void GamepadManager::bkOnButtonChanged(int device_id, GamepadButton button, bool pressed)
{
    const auto it = find_by_deviceid(*m_devices, device_id);
    if (it != m_devices->constEnd())
        (*it)->setButtonState(button, pressed);
}

void GamepadManager::bkOnAxisChanged(int device_id, GamepadAxis axis, double value)
{
    const auto it = find_by_deviceid(*m_devices, device_id);
    if (it != m_devices->constEnd())
        (*it)->setAxisState(axis, value);
}

} // namespace model

