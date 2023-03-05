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

#ifdef WITH_SDL_GAMEPAD
#  include "GamepadManagerSDL2.h"
#else
#  include "GamepadManagerQt.h"
#endif

//to access recalbox.conf & files/paths
#include "RecalboxConf.h"
#include "Paths.h"
#include "utils/StdStringHelpers.h"

namespace {
void call_gamepad_reconfig_scripts()
{
    ScriptRunner::run(ScriptEvent::CONFIG_CHANGED);
    ScriptRunner::run(ScriptEvent::CONTROLS_CHANGED);
}

//to search by id (player id)
QQmlObjectListModel<model::Gamepad>::const_iterator
find_by_deviceid(QQmlObjectListModel<model::Gamepad>& model, int device_id)
{
    return std::find_if(
        model.constBegin(),
        model.constEnd(),
        [device_id](const model::Gamepad* const gp){ return gp->deviceId() == device_id; });
}
//to search by SDL index 
QQmlObjectListModel<model::Gamepad>::const_iterator
find_by_deviceidx(QQmlObjectListModel<model::Gamepad>& model, int device_idx)
{
    return std::find_if(
        model.constBegin(),
        model.constEnd(),
        [device_idx](const model::Gamepad* const gp){ return gp->deviceIndex() == device_idx; });
}
//to search by SDL instance
QQmlObjectListModel<model::Gamepad>::const_iterator
find_by_deviceiid(QQmlObjectListModel<model::Gamepad>& model, int device_iid)
{
    return std::find_if(
        model.constBegin(),
        model.constEnd(),
        [device_iid](const model::Gamepad* const gp){ return gp->deviceInstance() == device_iid; });
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
    connect(m_backend, &GamepadManagerBackend::newController,
            this, &GamepadManager::bkOnNewController);			            
    connect(m_backend, &GamepadManagerBackend::nameChanged,
            this, &GamepadManager::bkOnNameChanged);
    connect(m_backend, &GamepadManagerBackend::indexChanged,
            this, &GamepadManager::bkOnIndexChanged);
    connect(m_backend, &GamepadManagerBackend::layoutChanged,
            this, &GamepadManager::bkOnLayoutChanged);
    connect(m_backend, &GamepadManagerBackend::removed,
            this, &GamepadManager::bkOnRemoved);
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
void GamepadManager::configureAxis(int deviceId, GMAxis axis, QString sign = "")
{
    Q_ASSERT(axis != GMAxis::Invalid);
    m_backend->start_recording(deviceId, static_cast<GamepadAxis>(axis), sign);
}
void GamepadManager::cancelConfiguration()
{
    m_backend->cancel_recording();
}
void GamepadManager::resetButton(int deviceId, GMButton button)
{
    Q_ASSERT(button != GMButton::Invalid);
    m_backend->reset(deviceId, static_cast<GamepadButton>(button));
}
void GamepadManager::resetAxis(int deviceId, GMAxis axis)
{
    Q_ASSERT(axis != GMAxis::Invalid);
    m_backend->reset(deviceId, static_cast<GamepadAxis>(axis));
}

void GamepadManager::swap(int device_id1, int device_id2)
{
    Log::debug(m_log_tag, LOGMSG("swap device from id: %1 to id: %2").arg(QString::number(device_id1),QString::number(device_id2)));
    //swap first in recalbox.conf
    std::string path = "";
    std::string uuid = "";
    std::string name = "";
    std::string sdlidx = "";	
		
    const QString device1PadPegasus = QString::fromStdString(RecalboxConf::Instance().GetPadPegasus(device_id1));
    Log::debug(m_log_tag, LOGMSG("device_id2: %1 device1PadPegasus: %2").arg(QString::number(device_id2), device1PadPegasus));

    const QString device2PadPegasus = QString::fromStdString(RecalboxConf::Instance().GetPadPegasus(device_id2));
    Log::debug(m_log_tag, LOGMSG("device_id1: %1 device2PadPegasus: %2").arg(QString::number(device_id1), device2PadPegasus));

    RecalboxConf::Instance().SetPadPegasus(device_id1,device2PadPegasus.toUtf8().constData());
	RecalboxConf::Instance().SetPadPegasus(device_id2,device1PadPegasus.toUtf8().constData());
	
    //swap now in model::gamepad also
    try{
		QString name1;
		int iid1;
		int idx1;
		//search & backup first device
        const auto it = find_by_deviceid(*m_devices, device_id1);
        if (it != m_devices->constEnd()) {
			name1 = (*it)->name();
            iid1 = (*it)->deviceInstance();
			idx1 = (*it)->deviceIndex();
        }
        QString name2;
        int iid2;
        int idx2;
		//search second device
		const auto it2 = find_by_deviceid(*m_devices, device_id2);
        if (it2 != m_devices->constEnd()) {
			name2 = (*it2)->name();
            iid2 = (*it2)->deviceInstance();
			idx2 = (*it2)->deviceIndex();
        }
		
		//swap information
		if (it != m_devices->constEnd()) {

            //(*it)->setName(std::move(name2));
            (*it)->setName(name2);
            (*it)->setInstance(iid2);
            (*it)->setIndex(idx2);
		}
		if (it2 != m_devices->constEnd()) {
            //(*it2)->setName(std::move(name1));
            (*it2)->setName(name1);
            (*it2)->setInstance(iid1);
            (*it2)->setIndex(idx1);
		}		
    }
    catch ( const std::exception & Exp ) 
    { 
        Log::debug(m_log_tag, LOGMSG("Catched error : %1.\n").arg(Exp.what()));
    } 
}

void GamepadManager::bkOnConnected(int device_idx, QString device_guid, QString device_name, QString device_path, QString device_layout, int device_idd)
{
    if (device_name.isEmpty()){
        device_name = QLatin1String("generic");
    }
	
	//persistence saved in recalbox.conf
	const QString Parameter = QString("pegasus.pad%1").arg(device_idx);
	const QString Value = QString("%1|%2|%3|%4").arg(device_guid,device_name,device_path,QString::number(device_idx));
	Log::debug(m_log_tag, LOGMSG("Saved as %1=%2").arg(Parameter,Value));
	RecalboxConf::Instance().SetString(Parameter.toUtf8().constData(), Value.toUtf8().constData());

    //clean if other lines exists (after shutdown or crash for example if could be possible)
    for(int i = device_idx+1; (RecalboxConf::Instance().GetPadPegasus(i) != "") && (i < RecalboxConf::iMaxInputDevices); i++)
    {
        RecalboxConf::Instance().SetPadPegasus(i,"");
    }

	//save in file immediately for test/follow-up purpose
	RecalboxConf::Instance().Save();	

    m_devices->append(new Gamepad(device_idx, device_name, device_idd, device_idx, device_layout, m_devices)); //device_id equals to device_idx at connnection

    Log::info(m_log_tag, LOGMSG("Connected device %1 (%2)").arg(pretty_id(device_idx), device_name));
    
    //showpopup for 4 seconds by default
    //Depreacated, removing of icon setting at this step: emit showPopup(QStringLiteral("Device %1 connected").arg(QString::number(device_idx)),QStringLiteral("%1").arg(name),QStringLiteral("%1").arg(getIconByName(name)), 4);
    emit showPopup(QStringLiteral("Device %1 connected").arg(QString::number(device_idx)),QStringLiteral("%1").arg(device_name),QStringLiteral("%1").arg(""), 4);
}

void GamepadManager::bkOnDisconnected(int device_iid)
{
    QString name;
    
    try{
        QString name;
        int device_id;
        int device_idx;

        Log::info(m_log_tag, LOGMSG("Disconnected device from iid: %1").arg(pretty_id(device_iid)));
        const auto it = find_by_deviceiid(*m_devices, device_iid);
		if (it != m_devices->constEnd()) {
            name = (*it)->name();
			device_id = (*it)->deviceId();
            device_idx = (*it)->deviceIndex();
            Log::info(m_log_tag, LOGMSG("Disconnected device from id: %1 (%2)").arg(pretty_id(device_id), name));
            Log::info(m_log_tag, LOGMSG("Disconnected device from index: %1 (%2)").arg(pretty_id(device_idx), name));

            //finally, remove device independently in a second time
            //to remove in model::gamepad and in recalbox.conf
            bkOnRemoved(device_id);

            //showpopup for 4 seconds by default
            //Depreacted to set icon here: emit showPopup(QStringLiteral("Device %1 disconnected").arg(QString::number(device_id)),QStringLiteral("%1").arg(name),QStringLiteral("%1").arg(getIconByName(name)), 4);
            emit showPopup(QStringLiteral("Device %1 disconnected").arg(QString::number(device_idx)),QStringLiteral("%1").arg(name),QStringLiteral("%1").arg(""), 4);
            }
    }
    catch ( const std::exception & Exp ) 
    { 
        Log::debug(m_log_tag, LOGMSG("Catched error : %1.\n").arg(Exp.what()));
    } 
}

void GamepadManager::bkOnNewController(int device_idx, QString name)
{
    Log::debug(m_log_tag, LOGMSG("New Controller #%1 (%2)").arg(QString::number(device_idx), name));
    
    emit newController(device_idx, name);
}

void GamepadManager::bkOnNameChanged(int device_id, QString name)
{
    //Log::info(m_log_tag, LOGMSG("void GamepadManager::bkOnNameChanged(int device_id, QString name)"));
    try{
        const auto it = find_by_deviceid(*m_devices, device_id);
        if (it != m_devices->constEnd()) {
            Log::debug(m_log_tag, LOGMSG("Set name of device %1 to '%2'").arg(pretty_id(device_id), name));
            (*it)->setName(std::move(name));
        }
    }
    catch ( const std::exception & Exp ) 
    { 
        Log::debug(m_log_tag, LOGMSG("Catched error : %1.\n").arg(Exp.what()));
    } 
}

void GamepadManager::bkOnIndexChanged(int device_idx1, int device_idx2)
{
    try{
        int device_id;
		const auto it = find_by_deviceidx(*m_devices, device_idx1);
		if (it != m_devices->constEnd()) {
			device_id = (*it)->deviceId();
            Log::debug(m_log_tag, LOGMSG("Change index of device id: '%1' with new index: '%2'").arg(pretty_id(device_id), pretty_id(device_idx2)));
            (*it)->setIndex(device_idx2);
        }		

		//change in recalbox.conf also
		//Get existing line
		std::string initialPadPegasusValue = RecalboxConf::Instance().GetPadPegasus(device_id);
        Log::debug(m_log_tag, LOGMSG("initialPadPegasusValue: %1").arg(QString::fromStdString(initialPadPegasusValue)));
		std::string path = "";
		std::string uuid = "";
		std::string name = "";
		std::string sdlidx = "";
		//Get info to reconstruct the line
        Strings::SplitInFour(initialPadPegasusValue, '|', uuid, name, path, sdlidx, false);
		//set to new index
		sdlidx = std::to_string(device_idx2);
		std::string newPadPegasusValue = "";
		newPadPegasusValue.append(uuid);
		newPadPegasusValue.append("|");
		newPadPegasusValue.append(name);
		newPadPegasusValue.append("|");
		newPadPegasusValue.append(path);
		newPadPegasusValue.append("|");
		newPadPegasusValue.append(sdlidx);
		//write with nen value
        Log::debug(m_log_tag, LOGMSG("newPadPegasusValue: %1").arg(QString::fromStdString(newPadPegasusValue)));
        RecalboxConf::Instance().SetPadPegasus(device_id,newPadPegasusValue);
		//save in file for test/follow-up purpose
        RecalboxConf::Instance().Save();
    }
    catch ( const std::exception & Exp ) 
    { 
        Log::debug(m_log_tag, LOGMSG("Catched error : %1.\n").arg(Exp.what()));
    } 
}

void GamepadManager::bkOnLayoutChanged(int device_id, QString layout)
{
    //Log::info(m_log_tag, LOGMSG("void GamepadManager::bkOnLayoutChanged(int device_id, QString layout)"));
    try{
        const auto it = find_by_deviceid(*m_devices, device_id);
        if (it != m_devices->constEnd()) {
            Log::debug(m_log_tag, LOGMSG("Set layout of device %1 to '%2'").arg(pretty_id(device_id), layout));
            (*it)->setLayout(std::move(layout));
        }
    }
    catch ( const std::exception & Exp )
    {
        Log::debug(m_log_tag, LOGMSG("Catched error : %1.\n").arg(Exp.what()));
    }
}

void GamepadManager::bkOnRemoved(int device_id)
{
    //Log::info(m_log_tag, LOGMSG("void GamepadManager::bkOnRemoveDevice(int device_id)"));
    try{
        const auto it = find_by_deviceid(*m_devices, device_id);
        if (it != m_devices->constEnd()) 
        {
            QString name;
            name = (*it)->name();
            m_devices->remove(*it);
            Log::info(m_log_tag, LOGMSG("Remove device from id: %1 (%2)").arg(pretty_id(device_id), name));
			
			//remove device from recalbox.conf in pegasus.pad parameters using the device_id
			//and move other pegasus.pad lined due to one line removed
            for(int i = device_id; (RecalboxConf::Instance().GetPadPegasus(i) != "") && (i < RecalboxConf::iMaxInputDevices); i++)
			{
                if (i != RecalboxConf::iMaxInputDevices-1){
                    //check and change id in gamepad::model
                    const auto it2 = find_by_deviceid(*m_devices, i+1);
                    if (it2 != m_devices->constEnd()) //if exist
                    {
                        //Get next line
                        std::string NextPadPegasus = RecalboxConf::Instance().GetPadPegasus(i+1);
                        Log::info(m_log_tag, LOGMSG("Update pegasus.pad%1 : %2").arg(QString::number(i),QString::fromStdString(NextPadPegasus)));
                        //Set existing line with next one
                        RecalboxConf::Instance().SetPadPegasus(i,NextPadPegasus);
                        //set id to avoid issue
                        (*it2)->setId(i);
                    }
                    else
                    {
                        Log::info(m_log_tag, LOGMSG("Update pegasus.pad%1 : %2").arg(QString::number(i),""));
                        RecalboxConf::Instance().SetPadPegasus(i,"");
                    }
				}
                else{
                    Log::info(m_log_tag, LOGMSG("Update pegasus.pad%1 : %2").arg(QString::number(i),""));
                    RecalboxConf::Instance().SetPadPegasus(i,"");
                }
			}
			//save in file for test/follow-up purpose
			RecalboxConf::Instance().Save();			
        }
    }
    catch ( const std::exception & Exp ) 
    { 
        Log::debug(m_log_tag, LOGMSG("Catched error : %1.\n").arg(Exp.what()));
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

void GamepadManager::bkOnButtonChanged(int device_idx, GamepadButton button, bool pressed)
{
    //search now by index and not by id
	const auto it = find_by_deviceidx(*m_devices, device_idx);
    if (it != m_devices->constEnd())
        (*it)->setButtonState(button, pressed);
}

void GamepadManager::bkOnAxisChanged(int device_idx, GamepadAxis axis, double value)
{
    //search now by index and not by id
    const auto it = find_by_deviceidx(*m_devices, device_idx);
    if (it != m_devices->constEnd())
        (*it)->setAxisState(axis, value);
}

} // namespace model

