//
// Created by BozoTheGeek 07/08/2025 in Pegasus Front-end
//

#include "Log.h"

#include <utils/rLog.h>
#include "RecalboxConfOverride.h"
#include "ScriptManager.h"
#include <utils/Files.h>

// The delegating constructor (declared as private in the header)
// This is where the shared initialization code lives.
RecalboxConfOverride::RecalboxConfOverride(const Path& path)
    : IniFile(path),
    StaticLifeCycleControler<RecalboxConfOverride>("RecalboxConfOverride")
{
    recalboxConfOverrideFile = path;
    Log::debug(LOGMSG("%1 instance created.").arg(QString::fromStdString(path.ToString())));
}

// The default public constructor
// It delegates to the private constructor.
RecalboxConfOverride::RecalboxConfOverride()
    : RecalboxConfOverride(Path("/recalbox/share/roms/.recalbox.conf"))
{
    //default path / updated on demand
}

void RecalboxConfOverride::OnSave()
{
    ScriptManager::Instance().Notify(Notification::ConfigurationChanged, recalboxConfOverrideFile.ToString());
}

std::string RecalboxConfOverride::GetLanguage()
{
  std::string locale = Strings::ToLowerASCII(RecalboxConfOverride::Instance().GetSystemLanguage());
  return (locale.length() == 5) ? locale.substr(0, 2) : "en";
}

std::string RecalboxConfOverride::GetCountry()
{
  std::string locale = Strings::ToLowerASCII(RecalboxConfOverride::Instance().GetSystemLanguage());
  return (locale.length() == 5) ? locale.substr(3, 2) : "us";
}

RecalboxConfOverride::Menu RecalboxConfOverride::MenuFromString(const std::string& menu)
{
  if (menu == "bartop") return Menu::Bartop;
  if (menu == "none") return Menu::None;
  return Menu::Default;
}

const std::string& RecalboxConfOverride::MenuFromEnum(RecalboxConfOverride::Menu menu)
{
  switch (menu)
  {
    case Menu::Bartop:
    {
      static std::string sBartop = "bartop";
      return sBartop;
    }
    case Menu::None:
    {
      static std::string sNone = "none";
      return sNone;
    }
    case Menu::Default:
    default: break;
  }
  static std::string sDefault = "default";
  return sDefault;
}

RecalboxConfOverride::Relay RecalboxConfOverride::RelayFromString(const std::string& relay)
{
  if (relay == "nyc") return Relay::NewYork;
  if (relay == "madrid") return Relay::Madrid;
  return Relay::None;
}

const std::string& RecalboxConfOverride::RelayFromEnum(RecalboxConfOverride::Relay relay)
{
  switch (relay)
  {
    case Relay::NewYork:
    {
      static std::string sNewYork = "nyc";
      return sNewYork;
    }
    case Relay::Madrid:
    {
      static std::string sMadrid = "madrid";
      return sMadrid;
    }
    case Relay::None:
    default: break;
  }
  static std::string sDefault = "none";
  return sDefault;
}

/* DefineSystemGetterSetterImplementation(Emulator, std::string, String, sSystemEmulator, "")
 DefineSystemGetterSetterImplementation(Core, std::string, String, sSystemCore, "")
 DefineSystemGetterSetterImplementation(Ratio, std::string, String, sSystemRatio, GetGlobalRatio())
 DefineSystemGetterSetterImplementation(Smooth, bool, Bool, sSystemSmooth, GetGlobalSmooth())
 DefineSystemGetterSetterImplementation(Rewind, bool, Bool, sSystemRewind, GetGlobalRewind())
 DefineSystemGetterSetterImplementation(AutoSave, bool, Bool, sSystemAutoSave, GetGlobalAutoSave())
 DefineSystemGetterSetterImplementation(Shaders, std::string, String, sSystemShaders, GetGlobalShaders())
 DefineSystemGetterSetterImplementation(ShaderSet, std::string, String, sSystemShaderSet, GetGlobalShaderSet())

 DefineEmulationStationSystemGetterSetterImplementation(FilterAdult, bool, Bool, sSystemFilterAdult, false)
 DefineEmulationStationSystemGetterSetterImplementation(FlatFolders, bool, Bool, sSystemFlatFolders, false)
 DefineEmulationStationSystemGetterSetterNumericEnumImplementation(Sort, FileSorts::Sorts, sSystemSort, FileSorts::Sorts::FileNameAscending)
 DefineEmulationStationSystemGetterSetterNumericEnumImplementation(RegionFilter, Regions::GameRegions, sSystemRegionFilter, Regions::GameRegions::Unknown)*/
