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

//to access es_input.cfg
#include "providers/es2/Es2Provider.h"

#include "GamepadManagerSDL2.h"

#include "Log.h"
#include "Paths.h"
#include "utils/StdStringHelpers.h"
#include "utils/Strings.h"


#include <QDataStream>
#include <QFile>
#include <QFileInfo>
#include <QStringBuilder>
#include <QTextStream>
#include <array>


namespace {
constexpr size_t GUID_LEN = 33; // 16x2 + null
constexpr auto USERCFG_FILE = "/sdl_controllers.txt";

constexpr uint16_t version(uint16_t major, uint16_t minor, uint16_t micro)
{
    return major * 1000u + minor * 100u + micro;
}

unsigned constexpr const_hash(char const *input) {
    return *input ?
    static_cast<unsigned int>(*input) + 33 * const_hash(input + 1) :
    5381;
}

std::unique_ptr<char, void(*)(void*)> freeable_str(char* const str)
{
    return { str, SDL_free };
}

void print_sdl_error()
{
    Log::error(LOGMSG("Error reported by SDL2: %1").arg(SDL_GetError()));
}

QString pretty_idx(int device_idx) {
    return QLatin1Char('#') % QString::number(device_idx);
}

uint16_t linked_sdl_version()
{
    SDL_version raw;
    SDL_GetVersion(&raw);
    Log::info(LOGMSG("SDL version %1.%2.%3")
        .arg(QString::number(raw.major), QString::number(raw.minor), QString::number(raw.patch)));
    return version(raw.major, raw.minor, raw.patch);
}

QLatin1String gamepaddb_file_suffix(uint16_t linked_ver)
{
    //Log::debug(LOGMSG("QLatin1String gamepaddb_file_suffix(uint16_t linked_ver)"));
    if (version(2, 0, 14) <= linked_ver) //use SDL 2.0.16 format with our SDL 2.0.14 (pixL version ;-)
        return QLatin1String("2016");

    if (version(2, 0, 9) <= linked_ver)
        return QLatin1String("209");

    if (version(2, 0, 5) <= linked_ver)
        return QLatin1String("205");

    return QLatin1String("204");
}

bool load_internal_gamepaddb(uint16_t linked_ver)
{
    //Log::debug(LOGMSG("bool load_internal_gamepaddb(uint16_t linked_ver)"));
    const QString path = QLatin1String(":/sdl2/gamecontrollerdb_")
        % gamepaddb_file_suffix(linked_ver)
        % QLatin1String(".txt");
    QFile dbfile(path);
    dbfile.open(QFile::ReadOnly);
    Q_ASSERT(dbfile.isOpen()); // it's embedded

    const auto size = static_cast<int>(dbfile.size());
    QByteArray contents(size, 0);
    QDataStream stream(&dbfile);
    stream.readRawData(contents.data(), size);

    SDL_RWops* const rw = SDL_RWFromConstMem(contents.constData(), contents.size());
    if (!rw)
        return false;

    const int entry_cnt = SDL_GameControllerAddMappingsFromRW(rw, 1);
    if (entry_cnt < 0)
        return false;

    return true;
}

void try_register_default_mapping(int device_idx)
{
    //Log::debug(LOGMSG("try_register_default_mapping"));
    std::array<char, GUID_LEN> guid_raw_str;
    const SDL_JoystickGUID guid = SDL_JoystickGetDeviceGUID(device_idx);
    SDL_JoystickGetGUIDString(guid, guid_raw_str.data(), guid_raw_str.size());

    // concatenation doesn't work with QLatin1Strings...
    const auto guid_str = QLatin1String(guid_raw_str.data()).trimmed();
    const auto name = QLatin1String(SDL_JoystickNameForIndex(device_idx));
    constexpr auto default_mapping("," // emscripten default
        "a:b0,b:b1,x:b2,y:b3,"
        "dpdown:h0.4,dpleft:h0.8,dpright:h0.2,dpup:h0.1,"
        "leftshoulder:b4,rightshoulder:b5,lefttrigger:b6,righttrigger:b7,"
        "back:b8,start:b9,guide:b10,"
        "leftstick:b11,rightstick:b12,"
        "leftx:a0,lefty:a1,rightx:a2,righty:a3");
    const QString new_mapping = guid_str % QLatin1Char(',') % name % default_mapping;

    if (SDL_GameControllerAddMapping(new_mapping.toLocal8Bit().data()) < 0) {
        Log::error(LOGMSG("SDL2: failed to set the default layout for gamepad %1").arg(pretty_idx(device_idx)));
        print_sdl_error();
        return;
    }
    Log::info(LOGMSG("SDL2: using default layout for gamepad %1").arg(pretty_idx(device_idx)));
}

GamepadButton translate_button(Uint8 button)
{
#define GEN(from, to) case SDL_CONTROLLER_BUTTON_##from: return GamepadButton::to
    switch (button) {
        GEN(DPAD_UP, UP);
        GEN(DPAD_DOWN, DOWN);
        GEN(DPAD_LEFT, LEFT);
        GEN(DPAD_RIGHT, RIGHT);
        GEN(A, SOUTH);
        GEN(B, EAST);
        GEN(X, WEST);
        GEN(Y, NORTH);
        GEN(LEFTSHOULDER, L1);
        GEN(LEFTSTICK, L3);
        GEN(RIGHTSHOULDER, R1);
        GEN(RIGHTSTICK, R3);
        GEN(BACK, SELECT);
        GEN(START, START);
        GEN(GUIDE, GUIDE);
        default:
            return GamepadButton::INVALID;
    }
#undef GEN
}

GamepadAxis translate_axis(Uint8 axis)
{
#define GEN(from, to) case SDL_CONTROLLER_AXIS_##from: return GamepadAxis::to
    switch (axis) {
        GEN(LEFTX, LEFTX);
        GEN(LEFTY, LEFTY);
        GEN(RIGHTX, RIGHTX);
        GEN(RIGHTY, RIGHTY);
        default:
            return GamepadAxis::INVALID;
    }
#undef GEN
}

const char* to_fieldname(GamepadButton button)
{
#define GEN(from, to) case GamepadButton::from: return SDL_GameControllerGetStringForButton(SDL_CONTROLLER_BUTTON_##to)
    switch (button) {
        GEN(UP, DPAD_UP);
        GEN(DOWN, DPAD_DOWN);
        GEN(LEFT, DPAD_LEFT);
        GEN(RIGHT, DPAD_RIGHT);
        GEN(SOUTH, A);
        GEN(EAST, B);
        GEN(WEST, X);
        GEN(NORTH, Y);
        GEN(L1, LEFTSHOULDER);
        GEN(L3, LEFTSTICK);
        GEN(R1, RIGHTSHOULDER);
        GEN(R3, RIGHTSTICK);
        GEN(SELECT, BACK);
        GEN(START, START);
        GEN(GUIDE, GUIDE);
        case GamepadButton::L2:
            return SDL_GameControllerGetStringForAxis(SDL_CONTROLLER_AXIS_TRIGGERLEFT);
        case GamepadButton::R2:
            return SDL_GameControllerGetStringForAxis(SDL_CONTROLLER_AXIS_TRIGGERRIGHT);
        default:
            Q_UNREACHABLE();
            return nullptr;
    }
#undef GEN
}

const char* to_fieldname(GamepadAxis axis)
{
#define GEN(from, to) case GamepadAxis::from: return SDL_GameControllerGetStringForAxis(SDL_CONTROLLER_AXIS_##to)
    switch (axis) {
        GEN(LEFTX, LEFTX);
        GEN(LEFTY, LEFTY);
        GEN(RIGHTX, RIGHTX);
        GEN(RIGHTY, RIGHTY);
        default:
            Q_UNREACHABLE();
            return nullptr;
    }
#undef GEN
}

GamepadButton detect_trigger_axis(Uint8 axis)
{
    switch (axis) {
        case SDL_CONTROLLER_AXIS_TRIGGERLEFT: return GamepadButton::L2;
        case SDL_CONTROLLER_AXIS_TRIGGERRIGHT: return GamepadButton::R2;
        default: return GamepadButton::INVALID;
    }
}

std::string generate_hat_str(int hat_idx, int hat_value)
{
    return 'h' + std::to_string(hat_idx) + '.' + std::to_string(hat_value);
}
std::string generate_axis_str(int axis_idx)
{
    return 'a' + std::to_string(axis_idx);
}
std::string generate_button_str(int button_idx)
{
    return 'b' + std::to_string(button_idx);
}
std::string generate_binding_str(const SDL_GameControllerButtonBind& bind)
{
    //Log::debug(LOGMSG("std::string generate_binding_str(const SDL_GameControllerButtonBind& bind)"));
    switch (bind.bindType) {
        case SDL_CONTROLLER_BINDTYPE_BUTTON:
            return generate_button_str(bind.value.button);
        case SDL_CONTROLLER_BINDTYPE_AXIS:
            return generate_axis_str(bind.value.axis);
        case SDL_CONTROLLER_BINDTYPE_HAT:
            return generate_hat_str(bind.value.hat.hat, bind.value.hat.hat_mask);
        default:
            return {};
    }
}

void write_mappings(const std::vector<std::string>& mappings)
{
    //Log::debug(LOGMSG("void write_mappings(const std::vector<std::string>& mappings)"));
    const QString db_path = paths::writableConfigDir() + QLatin1String(USERCFG_FILE);

    QFile db_file(db_path);
    if (!db_file.open(QIODevice::WriteOnly | QIODevice::Text)) {
        Log::error(LOGMSG("SDL: could not open `%1` for writing, gamepad config cannot be saved.")
            .arg(db_path));
        return;
    }

    QTextStream db_stream(&db_file);
    for (const std::string& mapping : mappings)
        db_stream << mapping.data() << '\n';
}

std::string create_mapping_from_es_input(const providers::es2::inputConfigEntry& inputConfigEntry)
{

    //example of Pegasus Mapping data: 
    //030000005e040000a102000000010000,X360 Wireless Controller,
    //a:b0,b:b1,back:b8,dpdown:b16,dpleft:b13,dpright:b14,dpup:b15,guide:b10,
    //leftshoulder:b4,leftstick:b11,lefttrigger:b6,leftx:a0,lefty:a1,rightshoulder:b5,
    //rightstick:b12,righttrigger:b7,rightx:a2,righty:a3,start:b9,x:b2,y:b3,platform:Linux,
    
    //QString FullMappingData = QString::fromStdString(new_mapping);
        
    QStringList ListMappingData; // = FullMappingData.split(",");
    
    //GET GUID
    ListMappingData.append(inputConfigEntry.inputConfigAttributs.deviceGUID);
    
    //GET NAME
    ListMappingData.append(inputConfigEntry.inputConfigAttributs.deviceName);
    
    //SET TYPE
    //inputConfigEntry.inputConfigAttributs.type = "joystick"; //TO DO: or keyboard ???
    
    //SET INPUTS
    // int NbAxis = 0;
    // int NbHats = 0;
    // int NbButtons = 0;
    // int NbKeys = 0;
    // for (int i = 2; i < ListMappingData.size(); i++)
    // {
    for (int idx = 0; idx < inputConfigEntry.inputElements.size(); idx++) {
            
        //QStringList InputData = ListMappingData.at(i).split(":");
        //Log::info(LOGMSG("InputData size = %1").arg(QString::number(InputData.size())));

        //with default value
        QString name;
        QString value = "";
        QString type;
        QString point = "";
        
        QString code = "-1";

        // sign ?
        QString sign = "";
        QString InputSign = inputConfigEntry.inputElements.at(idx).value;
        
        switch(const_hash(InputSign.toStdString().c_str()))
         {
             case const_hash("-1"): { sign = "-"; break; }
             case const_hash("1"): { sign = "+"; break; }
             default: break;
         }

        // id ?
        QString id=inputConfigEntry.inputElements.at(idx).id;
                
        // name ?
        QString InputName = inputConfigEntry.inputElements.at(idx).name;
        
        Log::debug(LOGMSG("name:`%1`").arg(InputName));
        
        switch(const_hash(InputName.toStdString().c_str())) // to get name of input as "a", "b", "hotkey", etc...
        {
            case const_hash(""):
                //to ignore empty field
                continue;
            break;
            case const_hash("a"):
                name = "b"; //inversed due to the fact that pegasus is based on xbox 360 pad but recalbox on super nintendo pad 
            break;
            case const_hash("b"):
                name = "a"; //inversed due to the fact that pegasus is based on xbox 360 pad but recalbox on super nintendo pad 
            break;
            case const_hash("x"): //inversed due to the fact that pegasus is based on xbox 360 pad but recalbox on super nintendo pad 
                name = "y";
            break;
            case const_hash("y"):
                name = "x"; //inversed due to the fact that pegasus is based on xbox 360 pad but recalbox on super nintendo pad 
            break;
            case const_hash("select"):
                name = "back";
            break;
            case const_hash("start"):
                name = "start";
            break;
            case const_hash("hotkey"):
                name = "guide";
            break;
            case const_hash("down"):
                name = "dpdown";
            break;
            case const_hash("up"):
                name = "dpup";
            break;
            case const_hash("right"):
                name = "dpright";
            break;
            case const_hash("left"):
                name = "dpleft";
            break;
            case const_hash("l1"):
                name = "leftshoulder";
            break;
            case const_hash("r1"):
                name = "rightshoulder";
            break;
             case const_hash("l2"):
                name = "lefttrigger";
            break;
            case const_hash("r2"):
                name = "righttrigger";
            break;           
             case const_hash("l3"):
                name = "leftstick";
            break;
            case const_hash("r3"):
                name = "rightstick";
            break;               
            case const_hash("joystick2up"):
                name = "righty";
                sign = ""; //cancel sign for this control
            break;
            case const_hash("joystick2left"):
                name = "rightx";
                sign = ""; //cancel sign for this control
            break;           
             case const_hash("joystick1up"):
                name = "lefty";
                sign = ""; //cancel sign for this control
            break;
            case const_hash("joystick1left"):
                name = "leftx";
                sign = ""; //cancel sign for this control
            break;             
        }
        
        // type ?
        
        QString InputType = inputConfigEntry.inputElements.at(idx).type;
        
        Log::debug(LOGMSG("type:`%1`").arg(InputType));
        
        switch (const_hash(InputType.toStdString().c_str())) // to get type as "a" axis or "b" button
        {
            case const_hash("axis"):
                type = "a";
                value = ""; //no value used
                point = ""; //no point used
            break;
            case const_hash("button"):
                type = "b";
                sign = ""; // cancel sign in case of hat
                value = ""; //no value used
                point = ""; //no point used
            break;
            case const_hash("hat"):
                type = "h";
                sign = ""; // cancel sign in case of hat
                point = "."; // set point as for hat
                value = inputConfigEntry.inputElements.at(idx).value;
            break;
            // case const_hash("key"):
                //for future used ;-)
                // type = "k";
            // break;
        }

        Log::debug(LOGMSG("id:`%1`").arg(id));
        Log::debug(LOGMSG("sign:`%1`").arg(sign));
        Log::debug(LOGMSG("point:`%1`").arg(point));
        Log::debug(LOGMSG("value:`%1`").arg(value));
        
        ListMappingData.append(name + ":" + sign + type + id + point + value);
    }

    ListMappingData.append("platform:" + QString::fromStdString(SDL_GetPlatform()));

    QString FullMappingData = ListMappingData.join(",") + ","; // add ',' at the end to be as we saved custom conf from controller settings

    Log::debug(LOGMSG("Controller full Mapping data:`%1`").arg(FullMappingData));
    
    return FullMappingData.toUtf8().constData(); // to std::string
    
}

void update_es_input(int device_idx, std::string new_mapping)
{
    Log::debug(LOGMSG("Controller full Mapping data:`%1`").arg(QString::fromStdString(new_mapping)));
    
    //example of Pegasus Mapping data: 
    //030000005e040000a102000000010000,X360 Wireless Controller,
    //a:b0,b:b1,back:b8,dpdown:b16,dpleft:b13,dpright:b14,dpup:b15,guide:b10,
    //leftshoulder:b4,leftstick:b11,lefttrigger:b6,leftx:a0,lefty:a1,rightshoulder:b5,
    //rightstick:b12,righttrigger:b7,rightx:a2,righty:a3,start:b9,x:b2,y:b3,platform:Linux,
    
    providers::es2::inputConfigEntry inputConfigEntry;
    
    QString FullMappingData = QString::fromStdString(new_mapping);
        
    QStringList ListMappingData = FullMappingData.split(",");
        
    //GET GUID
    inputConfigEntry.inputConfigAttributs.deviceGUID = ListMappingData.at(0);
    
    //GET NAME
    inputConfigEntry.inputConfigAttributs.deviceName = ListMappingData.at(1);
    
    //SET TYPE
    inputConfigEntry.inputConfigAttributs.type = "joystick"; //TO DO: or keyboard ???
    
    //SET INPUTS
    int NbAxis = 0;
    int NbHats = 0;
    int NbButtons = 0;
    int NbKeys = 0;
    for (int i = 2; i < ListMappingData.size(); i++)
    {
        
        QStringList InputData = ListMappingData.at(i).split(":");
        Log::info(LOGMSG("InputData size = %1").arg(QString::number(InputData.size())));
        QString name;
        QString InputName = InputData.at(0);
        Log::debug(LOGMSG("name:`%1`").arg(InputName));
        switch(const_hash(InputName.toStdString().c_str())) // to get name of input as "a", "b", "rightx", etc...
        {
            case const_hash(""):
                //to ignore empty field
                continue;
            break;
            case const_hash("platform"):
                //to ignore platform
                continue;
            break;
            case const_hash("a"):
                name = "b"; //inversed due to the fact that pegasus is based on xbox 360 pad but recalbox on super nintendo pad 
            break;
            case const_hash("b"):
                name = "a"; //inversed due to the fact that pegasus is based on xbox 360 pad but recalbox on super nintendo pad 
            break;
            case const_hash("x"): //inversed due to the fact that pegasus is based on xbox 360 pad but recalbox on super nintendo pad 
                name = "y";
            break;
            case const_hash("y"):
                name = "x"; //inversed due to the fact that pegasus is based on xbox 360 pad but recalbox on super nintendo pad 
            break;
            case const_hash("back"):
                name = "select";
            break;
            case const_hash("start"):
                name = "start";
            break;
            case const_hash("guide"):
                name = "hotkey";
            break;
            case const_hash("dpdown"):
                name = "down";
            break;
            case const_hash("dpup"):
                name = "up";
            break;
            case const_hash("dpright"):
                name = "right";
            break;
            case const_hash("dpleft"):
                name = "left";
            break;
            case const_hash("leftshoulder"):
                name = "l1";
            break;
            case const_hash("rightshoulder"):
                name = "r1";
            break;
             case const_hash("lefttrigger"):
                name = "l2";
            break;
            case const_hash("righttrigger"):
                name = "r2";
            break;           
             case const_hash("leftstick"):
                name = "l3";
            break;
            case const_hash("rightstick"):
                name = "r3";
            break;               
            case const_hash("righty"):
                name = "joystick2up";
            break;
            case const_hash("rightx"):
                name = "joystick2left";
            break;           
             case const_hash("lefty"):
                name = "joystick1up";
            break;
            case const_hash("leftx"):
                name = "joystick1left";
            break;             
        }

        if (InputData.size() != 2){
            Log::error(LOGMSG("Abnormal size for this input - size = %1").arg(QString::number(InputData.size())));
            continue; //anusual content for this input.
        }
        else if (InputData.at(1) == "")
        {
            Log::error(LOGMSG("Abnormal content for this input - content = %1").arg(ListMappingData.at(i)));
            continue; //anusual content for this input.
        }

        //with default value
        QString value = "0";
        QString type;
        QString code = "-1";

        // Sign?
        int sign = 0;
        int shift = 0;
        QString InputSign = InputData.at(1).at(0);
        
        switch(const_hash(InputSign.toStdString().c_str()))
        {
            case const_hash("-"): { sign = -1; shift = 1; break; }
            case const_hash("+"): { sign = +1; shift = 1; break; }
            default: break;
        }
                
        QString InputType = InputData.at(1).at(0 + shift);
        Log::debug(LOGMSG("type:`%1`").arg(InputType));
        
        QString id=InputData.at(1).mid(1 + shift,InputData.at(1).size()-(1 + shift));
        
        switch (const_hash(InputType.toStdString().c_str())) // to get type as "a" axis or "b" button
        {
            case const_hash("a"):
                NbAxis = NbAxis + 1;
                type = "axis";
                if (sign == 0) value = "-1"; // non-signed axes are affected to joysticks: always left or up
                else value = QString::number(sign); // Otherwise, take the sign as-is
                #ifdef WITHOUT_LEGACY_SDL
                code = "0"; //for QT creator test without SDL 1 compatibility
                #else
                code = QString::number(SDL_JoystickAxisEventCodeById(device_idx, id.toInt()));
                #endif
            break;
            case const_hash("b"):
                NbButtons = NbButtons + 1;
                type = "button";
                value = "1";
                #ifdef WITHOUT_LEGACY_SDL
                code = "0"; //for QT creator test without SDL 1 compatibility
                #else
                code = QString::number(SDL_JoystickButtonEventCodeById(device_idx, id.toInt()));
                #endif                
            break;
            case const_hash("h"):
                NbHats = NbHats + 1;
                type = "hat";
                //set code and value after due to id to change
            break;
            // case const_hash("k"):
                // //for future used ;-)
                // NbKeys = NbKeys + 1;
                // type = "key";
                // value = "1";
            // break;
        }

        if(type == "hat")        
        {//if hat format of id value is : X.Y, need to split
            QStringList HatData = id.split(".");
            id = HatData.at(0);
            value = HatData.at(1);
            #ifdef WITHOUT_LEGACY_SDL
            code = "0"; //for QT creator test without SDL 1 compatibility
            #else
            code = QString::number(SDL_JoystickHatEventCodeById(device_idx, id.toInt()));
            #endif 
        }
        Log::debug(LOGMSG("id:`%1`").arg(id));
        Log::debug(LOGMSG("value:`%1`").arg(value));
        #ifdef WITHOUT_LEGACY_SDL
        Log::debug(LOGMSG("code:`%1` - SDL 1 not supported !").arg(code)); //for QT creator test without SDL 1 compatibility
        #else
        Log::debug(LOGMSG("code:`%1`").arg(code));
        #endif 
        inputConfigEntry.inputElements.append({ name
                                               ,type
                                               ,id
                                               ,value
                                               ,code});
        
    }
    // Open joystick & add to our list
    SDL_Joystick* joy = SDL_JoystickOpen(device_idx);
    if (joy == nullptr)
    {
        Log::warning(LOGMSG("Numbers of Axis/Hats/Buttons are calculated for es_input.cfg update."));
    }
    else
    {
        NbAxis = SDL_JoystickNumAxes(joy);
        NbHats = SDL_JoystickNumHats(joy);
        NbButtons = SDL_JoystickNumButtons(joy);
        
        //We could read from SDL to have same name as initial es_input.cfg
        //but we keep that for futur used: 
        //inputConfigEntry.inputConfigAttributs.deviceName = QString::fromStdString(SDL_JoystickName(joy));
        //Keep name from SDL file finally
        
        Log::debug(LOGMSG("Name from Pegasus: %1 / Name from SDL function : %2").arg(ListMappingData.at(1),QString::fromStdString(SDL_JoystickName(joy))));
        inputConfigEntry.inputConfigAttributs.deviceName = ListMappingData.at(1);
    }
    
    //SET NBAXIS
    inputConfigEntry.inputConfigAttributs.deviceNbAxes = QString::number(NbAxis);
    Log::debug(LOGMSG("NbAxis:`%1`").arg(NbAxis));
    //SET NBHATS
    inputConfigEntry.inputConfigAttributs.deviceNbHats = QString::number(NbHats);
    Log::debug(LOGMSG("NbHats:`%1`").arg(NbHats));
    //SET NBBUTTONS
    inputConfigEntry.inputConfigAttributs.deviceNbButtons = QString::number(NbButtons);
    Log::debug(LOGMSG("NbButtons:`%1`").arg(NbButtons));
    
    providers::es2::Es2Provider *Provider = new providers::es2::Es2Provider();
    bool status = Provider->save_input_data(inputConfigEntry);
              
}

} // namespace


namespace model {

GamepadManagerSDL2::GamepadManagerSDL2(QObject* parent)
    : GamepadManagerBackend(parent)
    , m_sdl_version(linked_sdl_version())
    , m_log_tag(QStringLiteral("GamepadManagerSDL2"))
{
    //Log::debug(LOGMSG("GamepadManagerSDL2::GamepadManagerSDL2(QObject* parent"));
    connect(&m_poll_timer, &QTimer::timeout, this, &GamepadManagerSDL2::poll);
}

bool GamepadManagerSDL2::RecordingState::is_active() const
{
    //Log::debug(LOGMSG("bool GamepadManagerSDL2::RecordingState::is_active() const"));
    return device >= 0;
}

void GamepadManagerSDL2::RecordingState::reset()
{
    //Log::debug(LOGMSG("GamepadManagerSDL2::RecordingState::reset()"));
    device = -1;
    target_button = GamepadButton::INVALID;
    target_axis = GamepadAxis::INVALID;
    value.clear();
}

void GamepadManagerSDL2::start(const backend::CliArgs& args)
{
    //Log::debug(LOGMSG("void GamepadManagerSDL2::start(const backend::CliArgs& args)"));    
    if (SDL_Init(SDL_INIT_GAMECONTROLLER) != 0) {
        Log::info(LOGMSG("Failed to initialize SDL2. Gamepad support may not work."));
        print_sdl_error();
        return;
    }

    if (args.enable_gamepad_autoconfig) {
        if (Q_UNLIKELY(!load_internal_gamepaddb(m_sdl_version)))
            print_sdl_error();
    }

    //Load existing user configuration in a local store but don't load the mapping in SDL for the moment.
    for (const QString& dir : paths::configDirs())
        load_user_gamepaddb(dir);

    m_poll_timer.start(16);
}

GamepadManagerSDL2::~GamepadManagerSDL2()
{
    //Log::debug(LOGMSG("GamepadManagerSDL2::~GamepadManagerSDL2()"));
    m_poll_timer.stop();
    m_iid_to_device.clear();
    SDL_Quit();
}

std::string GamepadManagerSDL2::get_user_gamepaddb_mapping(const QString& dir, const QString& guid_to_find)
{
    //Log::debug(m_log_tag, LOGMSG("GamepadManagerSDL2::get_user_gamepaddb_mapping(const QString& dir, const QString& guid_to_find)"));
    constexpr size_t GUID_HEX_CNT = 16;
    constexpr size_t GUID_STR_LEN = GUID_HEX_CNT * 2;

    const QString path = dir + QLatin1String(USERCFG_FILE);
    if (!QFileInfo::exists(path))
        return "";

    QFile db_file(path);
    if (!db_file.open(QFile::ReadOnly | QFile::Text)) {
        Log::warning(LOGMSG("SDL: could not open `%1`, ignored").arg(path));
        return "";
    }
    Log::info(LOGMSG("SDL: loading controller mappings from `%1`").arg(path));

    QTextStream db_stream(&db_file);
    QString line;
    int linenum = 0;
    while (db_stream.readLineInto(&line)) {
        linenum++;

        if (line.startsWith('#'))
            continue;

        const std::string guid_str = line.left(GUID_STR_LEN).toStdString();
        const bool has_comma = line.length() > static_cast<int>(GUID_STR_LEN)
            && line.at(GUID_STR_LEN + 1) == QLatin1Char(',');
        if (guid_str.length() != GUID_STR_LEN || has_comma) {
            Log::warning(LOGMSG("SDL: in `%1` line #%2, the line format is incorrect, skipped")
                .arg(path, QString::number(linenum)));
            continue;
        }
        const auto bytes = QByteArray::fromHex(QByteArray::fromRawData(guid_str.data(), GUID_STR_LEN));
        if (bytes.count() != GUID_HEX_CNT) {
            Log::warning(LOGMSG("SDL: in `%1` line #%2, the GUID is incorrect, skipped")
                .arg(path, QString::number(linenum)));
            continue;
        }

        std::string new_mapping = line.toStdString();

        if(guid_to_find.toUtf8().constData() == guid_str)
        {
            return new_mapping; //found
        }
    }
    return ""; // not found
}

std::string GamepadManagerSDL2::get_user_gamepaddb_mapping_with_name(const QString& dir, const QString& guid_to_find, const QString& name_to_find)
{
    //Log::debug(m_log_tag, LOGMSG("GamepadManagerSDL2::get_user_gamepaddb_mapping(const QString& dir, const QString& guid_to_find)"));
    constexpr size_t GUID_HEX_CNT = 16;
    constexpr size_t GUID_STR_LEN = GUID_HEX_CNT * 2;

    const QString path = dir + QLatin1String(USERCFG_FILE);
    if (!QFileInfo::exists(path))
        return "";

    QFile db_file(path);
    if (!db_file.open(QFile::ReadOnly | QFile::Text)) {
        Log::warning(LOGMSG("SDL: could not open `%1`, ignored").arg(path));
        return "";
    }
    Log::info(LOGMSG("SDL: loading controller mappings from `%1`").arg(path));

    QTextStream db_stream(&db_file);
    QString line;
    int linenum = 0;
    while (db_stream.readLineInto(&line)) {
        linenum++;

        if (line.startsWith('#'))
            continue;

        const std::string guid_str = line.left(GUID_STR_LEN).toStdString();
        const bool has_comma = line.length() > static_cast<int>(GUID_STR_LEN)
            && line.at(GUID_STR_LEN + 1) == QLatin1Char(',');
        if (guid_str.length() != GUID_STR_LEN || has_comma) {
            Log::warning(LOGMSG("SDL: in `%1` line #%2, the line format is incorrect, skipped")
                .arg(path, QString::number(linenum)));
            continue;
        }
        const auto bytes = QByteArray::fromHex(QByteArray::fromRawData(guid_str.data(), GUID_STR_LEN));
        if (bytes.count() != GUID_HEX_CNT) {
            Log::warning(LOGMSG("SDL: in `%1` line #%2, the GUID is incorrect, skipped")
                .arg(path, QString::number(linenum)));
            continue;
        }


		std::string existing_name = line.split(",").at(1).toStdString();

        if((guid_to_find.toUtf8().constData() == guid_str) &&
           (name_to_find.toUtf8().constData() == existing_name))
        {
            Log::debug(LOGMSG("SDL: user gamepad db mapping found for `%1`/'%2'")
                .arg(guid_to_find, name_to_find));
            std::string existing_mapping = line.toStdString();
            return existing_mapping; //found
        }
    }
    return ""; // not found
}


void GamepadManagerSDL2::load_user_gamepaddb(const QString& dir)
{
    //Log::debug(m_log_tag, LOGMSG("GamepadManagerSDL2::load_user_gamepaddb(const QString& dir)"));
    constexpr size_t GUID_HEX_CNT = 16;
    constexpr size_t GUID_STR_LEN = GUID_HEX_CNT * 2;

    const QString path = dir + QLatin1String(USERCFG_FILE);
    if (!QFileInfo::exists(path))
        return;

    QFile db_file(path);
    if (!db_file.open(QFile::ReadOnly | QFile::Text)) {
        Log::warning(LOGMSG("SDL: could not open `%1`, ignored").arg(path));
        return;
    }
    Log::info(LOGMSG("SDL: loading controller mappings from `%1`").arg(path));

    QTextStream db_stream(&db_file);
    QString line;
    int linenum = 0;
    while (db_stream.readLineInto(&line)) {
        linenum++;

        if (line.startsWith('#'))
            continue;

        const std::string guid_str = line.left(GUID_STR_LEN).toStdString();
        const bool has_comma = line.length() > static_cast<int>(GUID_STR_LEN)
            && line.at(GUID_STR_LEN + 1) == QLatin1Char(',');
        if (guid_str.length() != GUID_STR_LEN || has_comma) {
            Log::warning(LOGMSG("SDL: in `%1` line #%2, the line format is incorrect, skipped")
                .arg(path, QString::number(linenum)));
            continue;
        }
        const auto bytes = QByteArray::fromHex(QByteArray::fromRawData(guid_str.data(), GUID_STR_LEN));
        if (bytes.count() != GUID_HEX_CNT) {
            Log::warning(LOGMSG("SDL: in `%1` line #%2, the GUID is incorrect, skipped")
                .arg(path, QString::number(linenum)));
            continue;
        }

        SDL_JoystickGUID guid;
        memmove(guid.data, bytes.data(), GUID_HEX_CNT);

        std::string new_mapping = line.toStdString();

        update_mapping_store(std::move(new_mapping));
    }
}

void GamepadManagerSDL2::start_recording(int device_idx, GamepadButton button)
{
    m_recording.reset();
    m_recording.device = device_idx;
    m_recording.target_button = button;
}

void GamepadManagerSDL2::start_recording(int device_idx, GamepadAxis axis)
{
    m_recording.reset();
    m_recording.device = device_idx;
    m_recording.target_axis = axis;
}

void GamepadManagerSDL2::cancel_recording()
{
    if (m_recording.is_active())
        emit configurationCanceled(m_recording.device);

    m_recording.reset();
}

void GamepadManagerSDL2::poll()
{
    //Log::debug(LOGMSG("void GamepadManagerSDL2::poll()"));
    SDL_Event event;
    while (SDL_PollEvent(&event)) {
        switch (event.type) {
            case SDL_CONTROLLERDEVICEADDED:
                //Log::debug(LOGMSG("SDL: SDL_CONTROLLERDEVICEADDED"));
                // ignored in favor of SDL_JOYDEVICEADDED
                break;
            case SDL_CONTROLLERDEVICEREMOVED:
                //Log::debug(LOGMSG("SDL: SDL_CONTROLLERDEVICEREMOVED"));
                remove_pad_by_iid(event.cdevice.which);
                break;
            case SDL_CONTROLLERDEVICEREMAPPED:
                //Log::debug(LOGMSG("SDL: SDL_CONTROLLERDEVICEREMAPPED"));
                break;
            case SDL_JOYDEVICEADDED:
                //Log::debug(LOGMSG("SDL: SDL_JOYDEVICEADDED"));
                add_controller_by_idx(event.jdevice.which);
                break;
            case SDL_JOYDEVICEREMOVED:
                //Log::debug(LOGMSG("SDL: SDL_JOYDEVICEREMOVED"));
                // ignored in favor of SDL_CONTROLLERDEVICEREMOVED
                break;
            case SDL_CONTROLLERBUTTONUP:
                //Log::debug(LOGMSG("SDL: SDL_CONTROLLERBUTTONUP - button: %1 - state: %2").arg(QString::number(event.cbutton.button),QString::number(event.cbutton.state)));
                // also ignore input from other (non-recording) gamepads
                if (!m_recording.is_active()) {
                    const bool pressed = event.cbutton.state == SDL_PRESSED;
                    fwd_button_event(event.cbutton.which, event.cbutton.button, pressed);
                }
                break;
            case SDL_CONTROLLERBUTTONDOWN:
                //Log::debug(LOGMSG("SDL: SDL_CONTROLLERBUTTONDOWN - instance_id: %1 - button: %2 - state: %3").arg(QString::number(event.cbutton.which),QString::number(event.cbutton.button),QString::number(event.cbutton.state)));
                // also ignore input from other (non-recording) gamepads
                if (!m_recording.is_active()) {
                    const bool pressed = event.cbutton.state == SDL_PRESSED;
                    fwd_button_event(event.cbutton.which, event.cbutton.button, pressed);
                }
                break;
            case SDL_CONTROLLERAXISMOTION:
                //Log::debug(LOGMSG("SDL: SDL_CONTROLLERAXISMOTION - instance_id: %1 - axis: %2 - value: %3").arg(QString::number(event.caxis.which),QString::number(event.caxis.axis),QString::number(event.caxis.value)));
                if (!m_recording.is_active())
                    fwd_axis_event(event.caxis.which, event.caxis.axis, event.caxis.value);
                break;
            case SDL_JOYBUTTONUP:
                //Log::debug(LOGMSG("SDL: SDL_JOYBUTTONUP"));
                // ignored
                break;
            case SDL_JOYBUTTONDOWN:
                //Log::debug(LOGMSG("SDL: SDL_JOYBUTTONDOWN"));
                record_joy_button_maybe(event.jbutton.which, event.jbutton.button);
                break;
            case SDL_JOYHATMOTION:
                //Log::debug(LOGMSG("SDL: SDL_JOYHATMOTION"));
                record_joy_hat_maybe(event.jhat.which, event.jhat.hat, event.jhat.value);
                break;
            case SDL_JOYAXISMOTION:
                //Log::debug(LOGMSG("SDL: SDL_JOYAXISMOTION - instance_id: %1 - axis: %2 - value: %3").arg(QString::number(event.jaxis.which),QString::number(event.jaxis.axis),QString::number(event.jaxis.value)));
                record_joy_axis_maybe(event.jaxis.which, event.jaxis.axis, event.jaxis.value);
                break;
            default:
                break;
        }
    }
}

void GamepadManagerSDL2::add_controller_by_idx(int device_idx)
{
    Log::debug(LOGMSG("GamepadManagerSDL2::add_controller_by_idx"));
    //Log::debug(m_log_tag, LOGMSG("int device_idx : %1").arg(device_idx));
    try{
        Q_ASSERT(m_idx_to_iid.count(device_idx) == 0);
        //Log::debug(LOGMSG("m_idx_to_iid(device_idx).count(%1): %2").arg(QString::number(device_idx),QString::number(m_idx_to_iid.count(device_idx))));

        
        //Check if the given joystick is supported by the game controller interface.
        if (!SDL_IsGameController(device_idx))
        {
            Log::debug(LOGMSG("Not SDL_IsGameController(%1)").arg(device_idx));
			//generate a mapping by default (forced)
            try_register_default_mapping(device_idx);
        }
        
        //if problem to connect this device
        SDL_GameController* const pad = SDL_GameControllerOpen(device_idx);
        if (!pad) {
            Log::error(LOGMSG("SDL2: could not open gamepad %1").arg(pretty_idx(device_idx)));
            print_sdl_error();
            return;
        }

        //get mapping found by SDL DB or driver itself
        const auto mapping = freeable_str(SDL_GameControllerMapping(pad));
        
        //if no mapping, strange ?!
        if (!mapping){
            Log::error(m_log_tag, LOGMSG("SDL2: 'default' layout for gamepad %1 set to `%2`").arg(pretty_idx(device_idx), mapping.get()));
			//tentative to generate mapping by default
			try_register_default_mapping(device_idx);
			//retry to 'force' mapping
			const auto second_mapping = freeable_str(SDL_GameControllerMapping(pad));
			//if no mapping, it's a major issue !!!
			if (!second_mapping){
				Log::error(m_log_tag, LOGMSG("SDL2: 'forced' layout for gamepad %1 set to `%2`").arg(pretty_idx(device_idx), second_mapping.get()));
			}
		}	

        //get the name found by sdl in assets/sdl2/gamecontrollerdb_209.txt or sdl_controllers.txt (user mappings)
        Log::debug(m_log_tag, LOGMSG("Device name found by SDL (not trimmed): '%1'").arg(QLatin1String(SDL_GameControllerName(pad))));
        QString name = QLatin1String(SDL_GameControllerName(pad)).trimmed();
        Log::debug(m_log_tag, LOGMSG("Device name found by SDL (trimmed): '%1'").arg(name));

        SDL_Joystick* const joystick = SDL_GameControllerGetJoystick(pad);
        const SDL_JoystickID iid = SDL_JoystickInstanceID(joystick);
        
        Log::debug(m_log_tag, LOGMSG("iid value = %1").arg(iid));

        m_idx_to_iid.emplace(device_idx,iid);
        m_iid_to_idx.emplace(iid, device_idx);
        m_iid_to_device.emplace(iid, device_ptr(pad, SDL_GameControllerClose));
       
        //Log::debug(m_log_tag, LOGMSG("device_idx : %1").arg(device_idx)); 
            
        //Get GUID
        constexpr size_t GUID_LEN = 33; // 16x2 + null
        std::array<char, GUID_LEN> guid_raw_str;
        
        const SDL_JoystickGUID guid = SDL_JoystickGetDeviceGUID(device_idx);
        
        SDL_JoystickGetGUIDString(guid, guid_raw_str.data(), guid_raw_str.size());    
        
        // concatenation doesn't work with QLatin1Strings...
        const auto guid_str = QLatin1String(guid_raw_str.data()).trimmed();
        Log::debug(m_log_tag, LOGMSG("With gUId : %1").arg(guid_str));

        //check if gamepad has been configured by user previously using guid/name
        std::string user_mapping = "";
        for (const QString& dir : paths::configDirs())
        {
            //user_mapping = get_user_gamepaddb_mapping(dir, guid_str); //to change by adding name also ?! no ?
            user_mapping = get_user_gamepaddb_mapping_with_name(dir, guid_str, name); //to change by adding name also ?! no ?
            if(user_mapping != "") {
                //And add this mapping in SDL to be take into account
                if (SDL_GameControllerAddMapping(user_mapping.data()) < 0) {
                    print_sdl_error();
                    continue;
                }
                break; //exit for if not empty
            }
        }
        
        //if no user mapping defined / else we do nothing because it seems a pad already configured by user
        if (user_mapping == "")
        {
            Log::debug(m_log_tag, LOGMSG("no mapping in sdl_controllers.txt for this controller"));
            //check if any es_input.cfg record exists for this GUID
            providers::es2::Es2Provider *Provider = new providers::es2::Es2Provider();
            //check if we already saved this configuration (same guid/same name)
            providers::es2::inputConfigEntry inputConfigEntry = Provider->load_input_data(name, guid_str);
            //Log::debug(m_log_tag, LOGMSG("inputConfigEntry.inputConfigAttributs.deviceName : '%1'").arg(inputConfigEntry.inputConfigAttributs.deviceName));
        
            //if nothing is in es_input with this name -> we update es_input with the SDL conf
            if (inputConfigEntry.inputConfigAttributs.deviceName == "")
            {
                Log::debug(m_log_tag, LOGMSG("no mapping found in es_input.cfg for this controller"));
                //get default mapping from SDL2
                std::string existing_mapping = generate_mapping(device_idx).c_str();
				Log::debug(LOGMSG("existing_mapping : %1").arg(QString::fromStdString(existing_mapping))); 
				//write user SDL2 mapping in es_input.cfg
                Log::debug(m_log_tag, LOGMSG("save default SDL2 mapping in es_input.cfg to be able to play right now !"));
                update_es_input(device_idx, existing_mapping);
            }
            else //if anything is in es_input with this name -> we update user conf (sdl_controllers.txt) and reload
            {
                Log::debug(m_log_tag, LOGMSG("mapping with same name found in es_input.cfg for this controller"));
                //get default mapping from es_input.cfg to SDL2 format
                std::string new_mapping = create_mapping_from_es_input(inputConfigEntry);
                //write user SDL2 mapping in es_input.cfg
                Log::debug(m_log_tag, LOGMSG("save es_input.cfg mapping in sdl_controllers.txt to be able to use this conf in menu !"));
                //force reload new mapping
                Log::debug(m_log_tag, LOGMSG("Force reload new mapping for menu !"));
                //And add this mapping in SDL to be take into account
                if (SDL_GameControllerAddMapping(new_mapping.data()) < 0) {
                    print_sdl_error();
                }
                //add/udpate mapping in local store m_custom_mappings
                update_mapping_store(std::move(new_mapping));
                //saving of local store m_custom_mappings in file sdl_controllers.txt
                write_mappings(m_custom_mappings);
            }
			//to propose to configure or not the new controller
			emit newController(device_idx, name);
        }
		#ifdef WITHOUT_LEGACY_SDL
		//for QT creator test without SDL 1 compatibility
		Log::debug(m_log_tag, LOGMSG("From path using device_idx : %1").arg("/dev/input/bidon because SDL 1 API not supported"));
		const QString JoystickDevicePath = "/dev/input/bidon";
		#else
		// SDL_JoystickDevicePathById(device_idx) <- seems not SDL 2.0 compatible
		Log::debug(m_log_tag, LOGMSG("From path using device_idx : %1").arg(SDL_JoystickDevicePathById(device_idx)));
		Log::debug(m_log_tag, LOGMSG("And instance using device_idx : %1").arg(QString::number(device_idx)));
		Log::debug(m_log_tag, LOGMSG("And instance using iid : %1").arg(QString::number(iid)));
		//we use device_idx storage in recalbox.conf to know initial value of index and to update it/use it later.
        const QString JoystickDevicePath = SDL_JoystickDevicePathById(device_idx);
		#endif
        emit connected(device_idx, guid_str, name, JoystickDevicePath, iid); //device_idx = device_id when we connect device
        }
    catch ( const std::exception & Exp ) 
    { 
        Log::error(m_log_tag, LOGMSG("Erreur 1: %1.\n").arg(Exp.what()));
    } 
    catch ( const std::bad_alloc & ) 
    { 
        Log::error(m_log_tag, LOGMSG("Erreur : mémoire insuffisante.\n")); 
    } 
    catch ( const std::out_of_range & ) 
    { 
        Log::error(m_log_tag, LOGMSG("Erreur : débordement de mémoire.\n")); 
    }
}

void GamepadManagerSDL2::remove_pad_by_iid(SDL_JoystickID instance_id)
{
    Log::debug(m_log_tag, LOGMSG("void GamepadManagerSDL2::remove_pad_by_iid(SDL_JoystickID instance_id)"));
    try{
        Q_ASSERT(m_iid_to_idx.count(instance_id) == 1);
        Q_ASSERT(m_iid_to_device.count(instance_id) == 1);

        const int device_idx = m_iid_to_idx.at(instance_id);
        Log::debug(m_log_tag, LOGMSG("int device_idx : %1").arg(device_idx));
        Log::debug(m_log_tag, LOGMSG("int instance_id : %1").arg(instance_id));

        //Log::debug(m_log_tag, LOGMSG("emit disconnected(%1)").arg(QString::number(device_idx)));
        emit disconnected(instance_id); /*diconnected change to SDL "connection" index
                                       remove also in model:gamepad & an change recalbox.conf now.*/

        //erase existing device index/device and instance id
        m_iid_to_device.erase(instance_id);
        m_iid_to_idx.erase(instance_id);
        m_idx_to_iid.erase(device_idx);
        
        if (m_recording.device == device_idx) //Good here finally, the index should be used, but still to verify in other function also, take care !
            cancel_recording();

        //check instance for all indexes after this removing
        //Get number of Joystick
        int count = SDL_NumJoysticks();
        for(int j = 0; j < count; j++ ){
            //Get Device
            SDL_Joystick* joystick = SDL_JoystickOpen(j);
            //Get global index of Device
            SDL_JoystickID joystickIdentifier = SDL_JoystickInstanceID(joystick);
            //Get previous index from instance
            int previousIndex = m_iid_to_idx.at(joystickIdentifier);
            //Clode device
            SDL_JoystickClose(joystick);
            if(previousIndex != j){
                //need to redo hasmaps
                //remove previous value
                m_iid_to_idx.erase(joystickIdentifier);
                m_idx_to_iid.erase(previousIndex);
                //store new value using an index decremented
                m_iid_to_idx.emplace(joystickIdentifier,j);
                m_idx_to_iid.emplace(j,joystickIdentifier);
                //Request to update indexes in model::gamepad & recalbox.conf
                emit indexChanged(previousIndex, j);
            }

        }


		//need to clean also other index now due to removal of one pad
        /*for(int i = 0; (i <= (int)m_idx_to_iid.size()) && (m_idx_to_iid.size() != 0); i++){ //we check more than hashmap to take into account the one removed
			if(i > device_idx){ //if index upper
				if (m_idx_to_iid.count(i) == 1){ //if index exist
                    //need to redo hasmaps
                    const SDL_JoystickID iid = m_idx_to_iid.at(i); //keep instance
                    //remove previous value
                    m_iid_to_idx.erase(iid);
                    m_idx_to_iid.erase(i);
                    //store new value using an index decremented
                    m_iid_to_idx.emplace(iid,i-1);
                    m_idx_to_iid.emplace(i-1,iid);
                    //Request to update indexes in model::gamepad & recalbox.conf
                    emit indexChanged(i, i-1);
                }
			}
        }*/
    }
    catch ( const std::exception & Exp ) 
    { 
        Log::error(m_log_tag, LOGMSG("Erreur 2: %1.\n").arg(Exp.what()));
    } 
    catch ( const std::bad_alloc & ) 
    { 
        Log::error(m_log_tag, LOGMSG("Erreur : mémoire insuffisante.\n")); 
    } 
    catch ( const std::out_of_range & ) 
    { 
        Log::error(m_log_tag, LOGMSG("Erreur : débordement de mémoire.\n")); 
    }
}

void GamepadManagerSDL2::fwd_button_event(SDL_JoystickID instance_id, Uint8 button, bool pressed)
{
    //Log::debug(m_log_tag, LOGMSG("void GamepadManagerSDL2::fwd_button_event(SDL_JoystickID instance_id, Uint8 button, bool pressed)"));
    //catch exception to avoid issue !!!
    try{
        const int device_idx = m_iid_to_idx.at(instance_id);
        emit buttonChanged(device_idx, translate_button(button), pressed);
    }
    catch ( const std::exception & Exp ) 
    { 
        Log::error(m_log_tag, LOGMSG("Erreur 3: %1.\n").arg(Exp.what()));
    } 
    catch ( const std::bad_alloc & ) 
    { 
        Log::error(m_log_tag, LOGMSG("Erreur : mémoire insuffisante.\n")); 
    } 
    catch ( const std::out_of_range & ) 
    { 
        Log::error(m_log_tag, LOGMSG("Erreur : débordement de mémoire.\n")); 
    }    
}

void GamepadManagerSDL2::fwd_axis_event(SDL_JoystickID instance_id, Uint8 axis, Sint16 value)
{
    //catch exception to avoid issue !!! can help in case of deconnection to any controller ;-)
    try{
        const int device_idx = m_iid_to_idx.at(instance_id);
        const GamepadButton button = detect_trigger_axis(axis);
        if (button != GamepadButton::INVALID) {
            emit buttonChanged(device_idx, button, value != 0);
            return;
        }
        const double dblval = value / static_cast<double>(std::numeric_limits<Sint16>::max());
        emit axisChanged(device_idx, translate_axis(axis), dblval);
    }
    catch ( const std::exception & Exp ) 
    { 
        Log::error("GamepadManagerSDL2::fwd_axis_event", LOGMSG("Erreur : %1.\n").arg(Exp.what()));
    } 
    catch ( const std::bad_alloc & ) 
    { 
        Log::error("GamepadManagerSDL2::fwd_axis_event", LOGMSG("Erreur : mémoire insuffisante.\n")); 
    } 
    catch ( const std::out_of_range & ) 
    { 
        Log::error("GamepadManagerSDL2::fwd_axis_event", LOGMSG("Erreur : débordement de mémoire.\n")); 
    }
}

void GamepadManagerSDL2::record_joy_button_maybe(SDL_JoystickID instance_id, Uint8 button)
{
    //Log::debug(m_log_tag, LOGMSG("void GamepadManagerSDL2::record_joy_button_maybe(SDL_JoystickID instance_id, Uint8 button)"));
    //catch exception to avoid issue !!!
    try{

        if (!m_recording.is_active())
            return;

        const int device_idx = m_iid_to_idx.at(instance_id);
        if (m_recording.device != device_idx)
            return;
        m_recording.sign = ""; //no sign for button
        m_recording.value = generate_button_str(button);
        finish_recording();
        }
    catch ( const std::exception & Exp ) 
    { 
        Log::error(m_log_tag, LOGMSG("Erreur 5: %1.\n").arg(Exp.what()));
    } 
    catch ( const std::bad_alloc & ) 
    { 
        Log::error(m_log_tag, LOGMSG("Erreur : mémoire insuffisante.\n")); 
    } 
    catch ( const std::out_of_range & ) 
    { 
        Log::error(m_log_tag, LOGMSG("Erreur : débordement de mémoire.\n")); 
    }
}

void GamepadManagerSDL2::record_joy_axis_maybe(SDL_JoystickID instance_id, Uint8 axis, Sint16 axis_value)
{
    //Log::debug(m_log_tag, LOGMSG("void GamepadManagerSDL2::record_joy_axis_maybe(SDL_JoystickID instance_id, Uint8 axis, Sint16 axis_value)"));
    try{
        if (!m_recording.is_active())
            return;

        const int device_idx = m_iid_to_idx.at(instance_id);
        if (m_recording.device != device_idx)
            return;

        constexpr Sint16 deadzone = std::numeric_limits<Sint16>::max() / 2;
        Log::debug(m_log_tag, LOGMSG("deadzone: %1").arg(QString::number(deadzone)));
        Log::debug(m_log_tag, LOGMSG("axis_value: %1").arg(QString::number(axis_value)));
        if (-deadzone < axis_value && axis_value < deadzone)
        {
            Log::debug(m_log_tag, LOGMSG("-deadzone < axis_value && axis_value < deadzone"));       
            return;
        }
                
        // constexpr Sint16 mini = std::numeric_limits<Sint16>::min();
        // Log::debug(m_log_tag, LOGMSG("mini: %1").arg(QString::number(mini)));
        // if (axis_value == mini) // some triggers start from negative
        // {
            // Log::debug(m_log_tag, LOGMSG("axis_value == mini"));
            // return;
        // }

        //no sign necessary if stick left or right
        if ((m_recording.target_axis != GamepadAxis::LEFTX) \
        && (m_recording.target_axis != GamepadAxis::LEFTY) \
        && (m_recording.target_axis != GamepadAxis::RIGHTX) \
        && (m_recording.target_axis != GamepadAxis::RIGHTY))
        {
            m_recording.sign = axis_value > 0 ? '+' : '-';
        }
        else m_recording.sign = "";
        
        m_recording.value = generate_axis_str(axis);
        
        finish_recording();
        }
    catch ( const std::exception & Exp ) 
    { 
        Log::error(m_log_tag, LOGMSG("Erreur 6: %1.\n").arg(Exp.what()));
    } 
    catch ( const std::bad_alloc & ) 
    { 
        Log::error(m_log_tag, LOGMSG("Erreur : mémoire insuffisante.\n")); 
    } 
    catch ( const std::out_of_range & ) 
    { 
        Log::error(m_log_tag, LOGMSG("Erreur : débordement de mémoire.\n")); 
    }
}

void GamepadManagerSDL2::record_joy_hat_maybe(SDL_JoystickID instance_id, Uint8 hat, Uint8 hat_value)
{
    //Log::debug(m_log_tag, LOGMSG("void GamepadManagerSDL2::record_joy_hat_maybe- instance_id = %1, hat = %2, hat_value = %3").arg(QString::number(instance_id),QString::number(hat),QString::number(hat_value)));
    try{
        if (!m_recording.is_active())
            return;

        const int device_idx = m_iid_to_idx.at(instance_id);
        if (m_recording.device != device_idx)
            return;

        if (hat_value == SDL_HAT_CENTERED)
            return;
        m_recording.sign = ""; //no sign for hat
        m_recording.value = generate_hat_str(hat, hat_value);
        finish_recording();
    }
    catch ( const std::exception & Exp ) 
    { 
        Log::error(m_log_tag, LOGMSG("Erreur 7: %1.\n").arg(Exp.what()));
    } 
    catch ( const std::bad_alloc & ) 
    { 
        Log::error(m_log_tag, LOGMSG("Erreur : mémoire insuffisante.\n")); 
    } 
    catch ( const std::out_of_range & ) 
    { 
        Log::error(m_log_tag, LOGMSG("Erreur : débordement de mémoire.\n")); 
    }
}


std::string GamepadManagerSDL2::generate_mapping_for_field(const char* const field, const char* const recording_field,
                                                           const SDL_GameControllerButtonBind& current_bind,
                                                           std::string mapping){
    // new mapping
    if (field == recording_field)
        return std::string(field) + ':' + m_recording.sign + m_recording.value;

    // old mapping
    // const std::string value = generate_binding_str(current_bind);
    // if ((std::string(field) != "guide") && (value.empty() || value == (m_recording.sign + m_recording.value)))
        // return {};

    // from old  mapping also (but better to manage sign)
    Strings::Vector fields = Strings::Split(mapping, ',');
    for(int i = 0; i < fields.size(); i++)
    {
        Strings::Vector field_details = Strings::Split(fields[i],':');
        if(field_details.size() == 2) /// good cut confirmed
        {        
            if (std::string(field) == field_details[0])
            {
                //found and sure to have all (sign + binding)
                return std::string(field) + ':' + std::string(field_details[1]);
            }
        }             
    }
    // unaffected mapping
    return {};
    
    //return done for unaffected mapping before 24-03-2021
    //const std::string value = generate_binding_str(current_bind);
    //return std::string(field) + ':' + value;
}

std::string GamepadManagerSDL2::generate_mapping(int device_idx)
{
    //Log::debug(LOGMSG("GamepadManagerSDL2::generate_mapping"));
    try{
        Q_ASSERT(m_iid_to_device.count(m_idx_to_iid.at(device_idx)) == 1);
        
        const device_ptr& pad_ptr = m_iid_to_device.at(m_idx_to_iid.at(device_idx));

        std::array<char, GUID_LEN> guid_raw_str;
        const SDL_JoystickGUID guid = SDL_JoystickGetDeviceGUID(device_idx);
        SDL_JoystickGetGUIDString(guid, guid_raw_str.data(), guid_raw_str.size());

        std::vector<std::string> list;
            list.emplace_back(utils::trimmed(guid_raw_str.data()));
            list.emplace_back(SDL_GameControllerName(pad_ptr.get()));

        const char* const recording_field = m_recording.is_active()
            ? (m_recording.target_button != GamepadButton::INVALID)
                ? to_fieldname(m_recording.target_button)
                : to_fieldname(m_recording.target_axis)
            : nullptr;
        
        //Get existing mapping to avoid to recalculate all
        std::string existing_mapping = SDL_GameControllerMapping(pad_ptr.get());
        Log::debug(m_log_tag, LOGMSG("SDL2: layout for gamepad %1 set to `%2`").arg(pretty_idx(device_idx), QString::fromStdString(existing_mapping)));

        #define GEN(TYPE, MAX) \
            for (int idx = 0; idx < MAX; idx++) { \
                const auto item = static_cast<SDL_GameController##TYPE>(idx); \
                const char* const field = SDL_GameControllerGetStringFor##TYPE(item); \
                const auto current_bind = SDL_GameControllerGetBindFor##TYPE(pad_ptr.get(), item); \
                std::string new_mapping_field = generate_mapping_for_field(field, recording_field, current_bind, existing_mapping); \
                Log::debug(m_log_tag, LOGMSG("new_mapping_field: %1").arg(QString::fromStdString(new_mapping_field))); \
                if (!new_mapping_field.empty()) \
                    list.emplace_back(std::move(new_mapping_field)); \
            } 
            GEN(Button, SDL_CONTROLLER_BUTTON_MAX)
            GEN(Axis, SDL_CONTROLLER_AXIS_MAX)
        #undef GEN

        std::sort(list.begin() + 2, list.end());
        if (version(2, 0, 5) <= m_sdl_version)
            list.emplace_back(std::string("platform:") + SDL_GetPlatform());

        size_t out_len = 0;
        for (const std::string& item : list)
            out_len += item.size() + 1;

        std::string out;
        out.reserve(out_len);
        for (std::string& item : list)
            out += std::move(item) + ',';

        return out;
    }
    catch ( const std::exception & Exp ) 
    { 
        Log::error(m_log_tag, LOGMSG("Erreur 8: %1.\n").arg(Exp.what()));
    } 
    catch ( const std::bad_alloc & ) 
    { 
        Log::error(m_log_tag, LOGMSG("Erreur : mémoire insuffisante.\n")); 
    } 
    catch ( const std::out_of_range & ) 
    { 
        Log::error(m_log_tag, LOGMSG("Erreur : débordement de mémoire.\n")); 
    }
}

void GamepadManagerSDL2::update_mapping_store(std::string new_mapping)
{
    //Log::debug(LOGMSG("void GamepadManagerSDL2::update_mapping_store(std::string new_mapping)"));
    const auto it = std::find_if(m_custom_mappings.begin(), m_custom_mappings.end(),
        [&new_mapping](const std::string& mapping){
            return mapping.compare(0, GUID_LEN, new_mapping, 0, GUID_LEN) == 0;
        });
    if (it != m_custom_mappings.end())
        (*it) = std::move(new_mapping);
    else
        m_custom_mappings.emplace_back(std::move(new_mapping));
}

void GamepadManagerSDL2::finish_recording()
{
    Q_ASSERT(m_recording.is_active());
    //Log::debug(LOGMSG("m_recording.value : %1").arg(QString::fromStdString(m_recording.value))); 
    std::string new_mapping = generate_mapping(m_recording.device).c_str();
    Log::debug(LOGMSG("new_mapping : %1").arg(QString::fromStdString(new_mapping))); 

    if (SDL_GameControllerAddMapping(new_mapping.data()) < 0) {
        print_sdl_error();
        return;
    }

    //added to update es_input.cfg for configgen interface
    update_es_input(m_recording.device, new_mapping);

    update_mapping_store(std::move(new_mapping));
    write_mappings(m_custom_mappings);

    //Log::debug(LOGMSG("m_recording.value : %1").arg(QString::fromStdString(m_recording.value))); 
    Log::debug(LOGMSG("m_recording.device : %1").arg(QString::number(m_recording.device)));

    if (m_recording.target_button != GamepadButton::INVALID)
    {
        //Log::debug(LOGMSG("emit buttonConfigured(m_recording.device, m_recording.target_button);")); 
        emit buttonConfigured(m_recording.device, m_recording.target_button);
    }    
    else
    {
        //Log::debug(LOGMSG("emit axisConfigured(m_recording.device, m_recording.target_axis);"));
		emit axisConfigured(m_recording.device, m_recording.target_axis);
    }    

    m_recording.reset();
}

} // namespace model
