//
// Created by Bkg2k on 10/03/2020.
//
// Renamed from NotificationManager.h in recalbox ES and Integrated by BozoTheGeek 26/03/2021 for Pegasus Front-end
//

//to remove
//#include <utils/storage/rHashMap.h>


#include <utils/Files.h>

//RFU
//nclude <systems/SystemData.h>
//nclude <systems/SystemManager.h>

#include <sys/wait.h>
#include <spawn.h>

#include "ScriptManager.h"

/*
 * Members
 */
const std::string eol("\r\n");
const Path ScriptManager::sStatusFilePath("/tmp/es_state.inf");
rHashMap<std::string, pid_t> ScriptManager::sPermanentScriptsPID;

ScriptManager::ScriptManager(char** environment)
  : StaticLifeCycleControler<ScriptManager>("ScriptManager"),
    mEnvironment(environment)
{
  LoadScriptList();
}
    //RFU
    //mMQTTClient("recalbox-emulationstation"),


const char* ScriptManager::ActionToString(Notification action)
{
  switch(action)
  {
    case Notification::None:                 return "none";
    case Notification::Start:                return "start";
    case Notification::Stop:                 return "stop";
    case Notification::Shutdown:             return "shutdown";
    case Notification::Reboot:               return "reboot";
	case Notification::Relaunch:             return "relaunch";
    case Notification::Quit:                 return "quit";
    case Notification::SystemBrowsing:       return "systembrowsing";
    case Notification::GamelistBrowsing:     return "gamelistbrowsing";
    case Notification::RunKodi:              return "runkodi";
    case Notification::RunGame:              return "rungame";
    case Notification::RunDemo:              return "rundemo";
    case Notification::EndGame:              return "endgame";
    case Notification::EndDemo:              return "enddemo";
    case Notification::Sleep:                return "sleep";
    case Notification::WakeUp:               return "wakeup";
    case Notification::ScrapStart:           return "scrapstart";
    case Notification::ScrapStop:            return "scrapstop";
    case Notification::ScrapGame:            return "scrapgame";
    case Notification::ConfigurationChanged: return "configurationchanged";
    case Notification::StartGameClip:        return "startgameclip";
    case Notification::StopGameClip:         return "stopgameclip";
    default: break;
  }
  return "error";
}

Notification ScriptManager::ActionFromString(const std::string& action)
{
  static rHashMap<std::string, Notification> sStringToAction
  ({
    { "start"               , Notification::Start                },
    { "stop"                , Notification::Stop                 },
    { "shutdown"            , Notification::Shutdown             },
    { "reboot"              , Notification::Reboot               },
    { "relaunch"            , Notification::Relaunch             },
	{ "quit"                , Notification::Quit                 },
    { "systembrowsing"      , Notification::SystemBrowsing       },
    { "gamelistbrowsing"    , Notification::GamelistBrowsing     },
    { "runkodi"             , Notification::RunKodi              },
    { "rungame"             , Notification::RunGame              },
    { "rundemo"             , Notification::RunDemo              },
    { "endgame"             , Notification::EndGame              },
    { "enddemo"             , Notification::EndDemo              },
    { "sleep"               , Notification::Sleep                },
    { "wakeup"              , Notification::WakeUp               },
    { "scrapstart"          , Notification::ScrapStart           },
    { "scrapstop"           , Notification::ScrapStop            },
    { "scrapgame"           , Notification::ScrapGame            },
    { "configurationchanged", Notification::ConfigurationChanged },
    { "startgameclip"       , Notification::StartGameClip        },
    { "stopgameclip"        , Notification::StopGameClip         },
  });

  if (!sStringToAction.contains(action))
    return Notification::None;

  return sStringToAction[action];
}

bool ScriptManager::ExtractSyncFlagFromPath(const Path& path)
{
  const std::string& scriptName = Strings::ToLowerASCII(path.FilenameWithoutExtension());
  return (scriptName.find("(sync)") != std::string::npos);
}

bool ScriptManager::ExtractPermanentFlagFromPath(const Path& path)
{
  const std::string& scriptName = Strings::ToLowerASCII(path.FilenameWithoutExtension());
  return (scriptName.find("(permanent)") != std::string::npos);
}

Notification ScriptManager::ExtractNotificationsFromPath(const Path& path)
{
  // Extract events between [ and ] in filename
  const std::string& scriptName = Strings::ToLowerASCII(path.FilenameWithoutExtension());
  unsigned long start = scriptName.find('[');
  unsigned long stop = scriptName.find(']');

  if (((start | stop) == std::string::npos) || (stop - start <= 1)) return (Notification)-1;

  Notification result = Notification::None;
  // Split events
  Strings::Vector events = Strings::Split(scriptName.substr(start + 1, stop - start - 1), ',');
  // Extract notifications
  for(const std::string& event : events)
    result = result | ActionFromString(event);
  return result;
}

void ScriptManager::LoadScriptList()
{
  Path scriptsFolder(sScriptPath);
  Path::PathList scripts = scriptsFolder.GetDirectoryContent();

  for(const Path& path : scripts)
    if (path.IsFile())
      if (HasValidExtension(path))
      {
        bool permanent = ExtractPermanentFlagFromPath(path);
        bool synced = ExtractSyncFlagFromPath(path) && !permanent;
        if (permanent)
        {
          RunProcess(path, {}, false, true);
          { LOG(LogDebug) << "[Script] Run permanent UserScript: " << path.ToString(); }
        }
        else
        {
          mScriptList.push_back({ path, ExtractNotificationsFromPath(path), synced });
          { LOG(LogDebug) << "[Script] Scan UserScript: " << path.ToString(); }
        }
      }
}

ScriptManager::RefScriptList ScriptManager::FilteredScriptList(Notification action)
{
  RefScriptList result;

  for(const ScriptData& script : mScriptList)
    if ((script.mFilter & action) != 0)
      result.push_back(&script);

  return result;
}

void ScriptManager::RunScripts(Notification action, const std::string& param)
{
  RefScriptList scripts = FilteredScriptList(action);
  if (scripts.empty()) return; // Nothing to launch

  // Build parameter
  Strings::Vector args;
  args.push_back("-action");
  args.push_back(ActionToString(action));
  args.push_back("-statefile");
  args.push_back(sStatusFilePath.ToString());
  if (!param.empty())
  {
    args.push_back("-param");
    args.push_back(param);
  }

  for(const ScriptData* script : scripts)
  {
    // Run!
    RunProcess(script->mPath, args, script->mSync, false);
  }
}

void ScriptManager::BuildStateCommons(std::string& output, const model::Game* game, Notification action, const std::string& actionParameters)
//RFU
//void ScriptManager::BuildStateCommons(std::string& output, const SystemData* system, const FileData* game, Notification action, const std::string& actionParameters)
{
  // Build status file
  output.append("Action=").append(ActionToString(action)).append(eol)
        .append("ActionData=").append(actionParameters).append(eol);

  //RFU
  // System
  if (game != nullptr)
    output.append("System=").append(eol) //empty for the moment
          .append("SystemId=").append(game->systemShortName().toUtf8().constData()).append(eol);
  // else if (action == Notification::RunKodi)
    // output.append("System=kodi").append(eol)
          // .append("SystemId=kodi").append(eol);
  else
    output.append("System=").append(eol)
          .append("SystemId=").append(eol);

  // Permanent game infos
  if (game != nullptr)
     output.append("Game=").append(game->title().toUtf8().constData()).append(eol)
            .append("GamePath=").append(actionParameters).append(eol)
            .append("ImagePath=").append(eol); //empty for the moment
  else
    output.append("Game=").append(eol)
          .append("GamePath=").append(eol)
          .append("ImagePath=").append(eol);
}

void ScriptManager::BuildStateGame(std::string& output, const model::Game* game)
{
  std::string emulator;
  std::string core;

  if (game == nullptr) return;
        output.append("IsFolder=").append(eol) //empty for the moment
        .append("ThumbnailPath=").append(eol) //empty for the moment
        .append("VideoPath=").append(eol) //empty for the moment
        .append("Developer=").append((game->developerListConst().count() != 0) ? game->developerListConst().at(0).toUtf8().constData() : "").append(eol)
        .append("Publisher=").append((game->publisherListConst().count() != 0) ? game->publisherListConst().at(0).toUtf8().constData() : "").append(eol)
        .append("Players=").append(std::to_string(game->playerCount())).append(eol)
        .append("Region=").append(eol) //empty for the moment
        .append("Genre=").append((game->genreListConst().count() !=0) ? game->genreListConst().at(0).toUtf8().constData() : "").append(eol)
        .append("GenreId=").append(game->genreid().toUtf8().constData()).append(eol)
        .append("Favorite=").append((game->isFavorite() ? "1" : "0")).append(eol)
        .append("Hidden=").append(eol) //empty for the moment
        .append("Adult=").append(eol); //empty for the moment;

  if ((game->emulatorName() != "") && (game->emulatorCore() != ""))
      output.append("Emulator=").append(game->emulatorName().toUtf8().constData()).append(eol)
      .append("Core=").append(game->emulatorCore().toUtf8().constData()).append(eol);
}

/* void ScriptManager::BuildStateSystem(std::string& output, const SystemData* system)
{
  std::string emulator;
  std::string core;

  if (system == nullptr) return;

  if (!system->IsVirtual())
    if (system->Manager().Emulators().GetDefaultEmulator(*system, emulator, core))
      output.append("DefaultEmulator=").append(emulator).append(eol)
            .append("DefaultCore=").append(core).append(eol);
} */

void ScriptManager::BuildStateCompatibility(std::string& output, Notification action)
{
  // Mimic old behavior of "State"
  output.append("State=");
  switch(action)
  {
    case Notification::RunKodi:
    case Notification::RunGame: output.append("playing"); break;
    case Notification::RunDemo: output.append("demo"); break;
    case Notification::None:
    case Notification::Start:
    case Notification::Stop:
    case Notification::Shutdown:
    case Notification::Reboot:
	case Notification::Relaunch:
    case Notification::Quit:
    case Notification::SystemBrowsing:
    case Notification::GamelistBrowsing:
    case Notification::EndGame:
    case Notification::EndDemo:
    case Notification::Sleep:
    case Notification::WakeUp:
    case Notification::ScrapStart:
    case Notification::ScrapStop:
    case Notification::ScrapGame:
    case Notification::ConfigurationChanged:
    case Notification::StartGameClip:
    case Notification::StopGameClip:
    default: output.append("selected"); break;
  }
}

void ScriptManager::Notify(const model::Game* game, Notification action, const std::string& actionParameters)
//RFU
//void ScriptManager::Notify(const SystemData* system, const FileData* game, Notification action, const std::string& actionParameters)
{
  //RFU
  //const std::string& notificationParameter = (game != nullptr) ? game->getPath().ToString() :
  //                                           ((system != nullptr) ? system->getName() : actionParameters);
  
  const std::string& notificationParameter = actionParameters;

  // Check if it is the same event than in previous call
  //
  //ParamBag newBag(system, game, action, actionParameters);
  ParamBag newBag(game, action, actionParameters);
  
  if (newBag != mPreviousParamBag)
  {
    // Build all
    std::string output("Version=2.0"); output.append(eol);
    BuildStateCommons(output, game, action, actionParameters);
    
    
    //RFU
    //BuildStateCommons(output, system, game, action, actionParameters);
    
    BuildStateGame(output, game);
    
    //BuildStateSystem(output, system);
    
    
    
    BuildStateCompatibility(output, action);

    // Save
    Files::SaveFile(Path(sStatusFilePath), output);

    //RFU
    // MQTT notification
    //mMQTTClient.Send(sEventTopic, ActionToString(action));

    // Run scripts
    RunScripts(action, notificationParameter);
  }
  mPreviousParamBag = newBag;
}

void ScriptManager::RunProcess(const Path& target, const Strings::Vector& arguments, bool synchronous, bool permanent)
{
  // final argument array
  std::vector<const char*> args;

  std::string command;

  // Extract extension
  std::string ext = Strings::ToLowerASCII(target.Extension());
  if      (ext == ".sh")  { command = "/bin/sh";          args.push_back(command.data()); }
  else if (ext == ".ash") { command = "/bin/ash";         args.push_back(command.data()); }
  else if (ext == ".py")  { command = "/usr/bin/python";  args.push_back(command.data()); }
  else if (ext == ".py2") { command = "/usr/bin/python2"; args.push_back(command.data()); }
  else if (ext == ".py3") { command = "/usr/bin/python3"; args.push_back(command.data()); }
  else { command = target.ToString(); }

  args.push_back(target.ToChars());
  for (const std::string& argument : arguments) args.push_back(argument.c_str());

  { LOG(LogDebug) << "[Script] Run UserScript: " << Strings::Join(args, ' '); }

  // Push final null
  args.push_back(nullptr);

  if (sPermanentScriptsPID.contains(target.ToString()))
  {
    // Still running?
    if (waitpid(sPermanentScriptsPID[target.ToString()], nullptr, WNOHANG) == 0)
      return;
    // Not running, remove pid
    sPermanentScriptsPID.erase(target.ToString());
  }

  pid_t pid = 0;
  posix_spawnattr_t spawn_attr;
  posix_spawnattr_init(&spawn_attr);
  int status = posix_spawn(&pid, command.data(), nullptr, &spawn_attr, (char **) args.data(), mEnvironment);
  posix_spawnattr_destroy(&spawn_attr);

  if (status != 0) // Error
  {
    { LOG(LogError) << "[Script] Error running " << target.ToString() << " (spawn failed)"; }
    return;
  }

  // Wait for child?
  if (synchronous)
  {
    if (waitpid(pid, &status, 0) != pid)
    { LOG(LogError) << "[Script] Error waiting for " << target.ToString() << " to complete. (waitpid failed)"; }
  }

  // Permanent?
  if (permanent)
    sPermanentScriptsPID.insert(target.ToString(), pid);
}

bool ScriptManager::HasValidExtension(const Path& path)
{
  std::string ext = Strings::ToLowerASCII(path.Extension());
  return (ext.empty()) ||
         (ext == ".sh" ) ||
         (ext == ".ash") ||
         (ext == ".py" ) ||
         (ext == ".py2") ||
         (ext == ".py3");
}


