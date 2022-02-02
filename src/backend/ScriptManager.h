//
// Created by Bkg2k on 10/03/2020.
//
// Renamed from NotificationManager.h in recalbox ES and Integrated by BozoTheGeek 26/03/2021 for Pegasus Front-end
//
#pragma once

#include <utils/cplusplus/StaticLifeCycleControler.h>
#include <utils/cplusplus/Bitflags.h>
#include <utils/storage/rHashMap.h>

#include "model/gaming/Game.h"
#include "model/gaming/GameFile.h"

#include <QDir>

//RFU
//#include <systems/SystemData.h>
//#include <mqtt/MqttClient.h>

enum class Notification
{
    None                 = 0x00000, //!< Non triggered event
    Start                = 0x00001, //!< ES start or restart. Parameter: start count
    Stop                 = 0x00002, //!< ES stops. Parameter: start count
    Shutdown             = 0x00004, //!< The whole system is required to shutdown
    Reboot               = 0x00008, //!< The whole system is required to reboot
    Relaunch             = 0x00010, //!< ES is going to relaunch
    Quit                 = 0x00020, //!< ES is going to quit (ex: GPI case power button)
    SystemBrowsing       = 0x00040, //!< The user is browsing system list and selected a new system. Parameter: system short name
    GamelistBrowsing     = 0x00080, //!< The user is browsing the game list and selected a new game. Parameter: game path
    RunGame              = 0x00100, //!< A game is going to launch. Parameter: game path
    RunDemo              = 0x00200, //!< A game is going to launch in demo mode. Parameter: game path
    EndGame              = 0x00400, //!< Game session end. Parameter: game path
    EndDemo              = 0x00800, //!< Game demo session end. Parameter: game path
    Sleep                = 0x01000, //!< EmulationStation is entering sleep state.
    WakeUp               = 0x02000, //!< EmulationStation is waking up
    ScrapStart           = 0x04000, //!< A multiple game scrapping session starts
    ScrapStop            = 0x08000, //!< Scrapping session end. Parameter: scrapped game count
    ScrapGame            = 0x10000, //!< A game has been scrapped. Parameter: game path
    ConfigurationChanged = 0x20000, //!< The user changed something in the configuration.
    RunKodi              = 0x40000, //!< Run kodi!
    StartGameClip        = 0x60000, //!< Start a game clip
    StopGameClip         = 0x80000, //!< Stop a game clip
};

DEFINE_BITFLAG_ENUM(Notification, int)

class ScriptManager : public StaticLifeCycleControler<ScriptManager>
{
  public:

    /*!
     * @brief Default constructor
     */
    explicit ScriptManager(char* environement[]);

    /*!
     * @brief Start Kodi notification
     */
    //RFU
    //void NotifyKodi() { Notify(nullptr, nullptr, Notification::RunKodi, ""); }

    /*!
     * @brief Update EmulationStation status file with game information
     * @param game Target game
     * @param action Action to notify
     */
    //RFU
    void Notify(const model::GameFile* q_gamefile, Notification action) { 
    
                    const model::GameFile& gamefile = *q_gamefile;
                    const model::Game& game = *gamefile.parentGame();
                    const QFileInfo& finfo = gamefile.fileinfo();
                
                    Notify(&game, action, QDir::toNativeSeparators(finfo.absoluteFilePath()).toUtf8().constData()); 
                
                }

    /*!
     * @brief Update EmulationStation status file with system information
     * @param system Target system
     * @param action Action to notify
     */
    //RFU
    //void Notify(const SystemData& system, Notification action) { Notify(&system, nullptr, action, system.getFullName()); }

    /*!
     * @brief
     * @param action Action to notify
     */
    void Notify(Notification action) { Notify(nullptr, action, std::string()); }

    /*!
     * @brief
     * @param action Action to notify
     * @param actionParameters Optional action parameters
     */
    void Notify(Notification action, const std::string& actionParameters) { Notify(nullptr, action, actionParameters); }

    /*!
     * @brief Run the target using the given arguments.
     * The target is run aither natively or using python or sh regarding the target extension
     * @param target executable/scriupt to run
     * @param arguments arguments passed to the target
     */
    void RunProcess(const Path& target, const Strings::Vector& arguments, bool synchronous, bool permanent);
    
  private:
    /*!
     * @brief Script data
     */
    struct ScriptData
    {
      Path         mPath;      //!< Script path
      Notification mFilter;    //!< Bitflag of notifications this script must reply to
      bool         mSync;      //!< RunSynchronously?
    };

    //! Shortcut :)
    typedef std::vector<ScriptData> ScriptList;
    //! Shortcut 2 :)
    typedef std::vector<const ScriptData*> RefScriptList;

    /*!
     * @brief Struture to hold a bag of parameters
     */
    struct ParamBag
    {
      // Game
      const model::Game* mGame;
      // Action
      Notification mAction;
      //! Action parameters
      std::string mActionParameters;

      
      //RFU
      //! System
      // const SystemData* mSystemData;
      // Game
      //const FileData* mFileData;


      /*!
       * @brief Default constructor
       */
      ParamBag()
        : mGame(nullptr),
          mActionParameters(),
          mAction(Notification::None)
          //RFU
          //mSystemData(nullptr),
          //mFileData(nullptr),
      {
      }

      /*!
       * @brief Full constructor
       * @param systemData System
       * @param fileData Game
       * @param action Action
       * @param actionParameters Optional action parameters
       */
      //ParamBag(const SystemData* systemData, const FileData* fileData, Notification action, const std::string& actionParameters)
      ParamBag(const model::Game* game, Notification action, const std::string& actionParameters)
        : mGame(game),
          mActionParameters(actionParameters),
          mAction(action)
          //RFU
          //mSystemData(systemData),
          //mFileData(fileData),
      {
      }

      /*!
       * @brief Inequality operator
       * @param compareTo Structure to compare against
       * @return True if at least one field is not equal
       */
      bool operator != (const ParamBag& compareTo) const
      {
      //RFU    
      //(mSystemData != compareTo.mSystemData) ||
      //(mFileData != compareTo.mFileData) ||
                
        return ((mGame != compareTo.mGame) ||
                (mAction != compareTo.mAction) ||
                (mActionParameters != compareTo.mActionParameters));
      }
    };

    //! Script folder
    static constexpr const char* sScriptPath = "/recalbox/share/userscripts";

    //RFU
    //! MQTT Topic
    //static constexpr const char* sEventTopic = "Recalbox/EmulationStation/Event";
    // MQTT client
    //MqttClient mMQTTClient;

    //! Permanent scripts PID
    static rHashMap<std::string, pid_t> sPermanentScriptsPID;

    //! Status file
    static const Path sStatusFilePath;

    //! All available scripts
    ScriptList mScriptList;

    //! Previous data
    ParamBag mPreviousParamBag;

    //! Environement
    char** mEnvironment;

    /*!
     * @brief Convert an Action into a string
     * @param action Action to convert
     * @return Converted string
     */
    static const char* ActionToString(Notification action);

    /*!
     * @brief Convert a string into an Action
     * @param action String to convert
     * @return Converted Action (Action::None if the conversion fails)
     */
    static Notification ActionFromString(const std::string& action);

    /*!
     * @brief Extract notifications bitflag from file name.
     * notifications must be eclosed by [] and comma separated
     * Case insensitive
     * @param path Path to extract notifications from
     * @return Notifications bitflag
     */
    static Notification ExtractNotificationsFromPath(const Path& path);

    /*!
     * @brief Extract sync flag from file name.
     * Sync flag must be '(sync)'. Case insensitive
     * @param path
     * @return
     */
    static bool ExtractSyncFlagFromPath(const Path& path);

    /*!
     * @brief Extract permanent flag from file name.
     * Sync flag must be '(permanent)'. Case insensitive
     * @param path
     * @return
     */
    static bool ExtractPermanentFlagFromPath(const Path& path);

    /*!
     * @brief Load all available scripts
     */
    void LoadScriptList();

    /*!
     * @brief Get a filtered list from all available list
     * @param action Action to filter
     * @return Filtered list
     */
    RefScriptList FilteredScriptList(Notification action);

    /*!
     * @brief Update EmulationStation status file
     * @param system Target System (may be null)
     * @param game Target game (may be null)
     * @param play True if the target game is going to be launched
     * @param demo True if the target game is going ot be launched as demo
     */
    void Notify(const model::Game* game, Notification action, const std::string& actionParameters);
    
    //RFU 
    //void Notify(const SystemData* system, const FileData* game, Notification action, const std::string& actionParameters);
    
    /*!
     * @brief Run all script associated to the given action
     * @param action Action to filter scripts with
     * @param param Optional action parameter
     */
    void RunScripts(Notification action, const std::string& param);

    /*!
     * @brief Build es_state.info Common information into output string
     * @param output Output string
     * @param system System or nullptr
     * @param game Game or nullptr
     * @param action Notification
     * @param actionParameters Notification parameters or empty string
     */
    //static void BuildStateCommons(std::string& output, Notification action, const std::string& actionParameters);
    static void BuildStateCommons(std::string& output, const model::Game* game, Notification action, const std::string& actionParameters);

    /*!
     * @brief Build es_state.info game information into output string
     * @param output Output string
     * @param game Game or nullptr
     */
    static void BuildStateGame(std::string& output, const model::Game* game);
    
    /*!
     * @brief Build es_state.info system information into output string
     * @param output Output string
     * @param game System or nullptr
     */
    //RFU
    //static void BuildStateSystem(std::string& output, const SystemData* system);

    /*!
     * @brief Build es_state.info compatibility key/values
     * @param output Output string
     */
    static void BuildStateCompatibility(std::string& output, Notification action);

    /*!
     * @brief Check path extension and check if the extension is valid or not
     * @param path Path to check extension
     * @return True if the path has a valid extension
     */
    static bool HasValidExtension(const Path& path);
};