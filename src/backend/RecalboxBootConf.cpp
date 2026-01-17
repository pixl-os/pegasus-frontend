//
// Created by BozoTheGeek 07/08/2025 in Pegasus Front-end
//

#include "Log.h"

#include <utils/rLog.h>
#include "RecalboxBootConf.h"
#include "ScriptManager.h"
#include <utils/Files.h>

static Path recalboxBootConfFile("/boot/recalbox-boot.conf");

// The delegating constructor (declared as private in the header)
// This is where the shared initialization code lives.
RecalboxBootConf::RecalboxBootConf(const Path& primaryPath, const Path& initPath)
    : IniFile(primaryPath, initPath),
    StaticLifeCycleControler<RecalboxBootConf>("RecalboxBootConf")
{
    Log::debug(LOGMSG("%1 instance created.").arg(QString::fromStdString(primaryPath.ToString())));
}

// The default public constructor
// It delegates to the private constructor.
RecalboxBootConf::RecalboxBootConf()
    : RecalboxBootConf(recalboxBootConfFile, Path())
{
    // This body can be empty as the work is done by the delegated constructor.
}

void RecalboxBootConf::OnSave()
{
    ScriptManager::Instance().Notify(Notification::ConfigurationChanged, recalboxBootConfFile.ToString());
}

std::string RecalboxBootConf::GetLanguage()
{
  std::string locale = Strings::ToLowerASCII(RecalboxBootConf::Instance().GetSystemLanguage());
  return (locale.length() == 5) ? locale.substr(0, 2) : "en";
}

std::string RecalboxBootConf::GetCountry()
{
  std::string locale = Strings::ToLowerASCII(RecalboxBootConf::Instance().GetSystemLanguage());
  return (locale.length() == 5) ? locale.substr(3, 2) : "us";
}

RecalboxBootConf::Menu RecalboxBootConf::MenuFromString(const std::string& menu)
{
  if (menu == "bartop") return Menu::Bartop;
  if (menu == "none") return Menu::None;
  return Menu::Default;
}

const std::string& RecalboxBootConf::MenuFromEnum(RecalboxBootConf::Menu menu)
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

RecalboxBootConf::Relay RecalboxBootConf::RelayFromString(const std::string& relay)
{
  if (relay == "nyc") return Relay::NewYork;
  if (relay == "madrid") return Relay::Madrid;
  return Relay::None;
}

const std::string& RecalboxBootConf::RelayFromEnum(RecalboxBootConf::Relay relay)
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
