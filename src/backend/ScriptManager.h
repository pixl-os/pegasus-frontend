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

#include <QThread>

#include <sys/wait.h>
#include <spawn.h>

enum class Notification
{
    None                 = 0x00000, //!< Non triggered event
    Start                = 0x00001, //!< PEGASUS-FRONTEND start or restart. Parameter: start count
    Stop                 = 0x00002, //!< PEGASUS-FRONTEND stops. Parameter: start count
    Shutdown             = 0x00004, //!< The whole system is required to shutdown
    Reboot               = 0x00008, //!< The whole system is required to reboot
    Relaunch             = 0x00010, //!< PEGASUS-FRONTEND is going to relaunch
    Quit                 = 0x00020, //!< PEGASUS-FRONTEND is going to quit (ex: GPI case power button)
    GroupBrowsing        = 0x00030, //!< The user is browsing group list and selected a new system. Parameter: group name
    SystemBrowsing       = 0x00040, //!< The user is browsing system list and selected a new system. Parameter: collection
    CollectionBrowsing   = 0x00070, //!< The user is browsing any collection list and selected a new game. Parameter: game, collection
    GamelistBrowsing     = 0x00080, //!< The user is browsing the game list and selected a new game. Parameter: game, collection
    GameviewSelected     = 0x00090, //!< The user is selecting a view where game is described/focus. Parameter: game
    RunGame              = 0x00100, //!< A game is going to launch. Parameter: game
    RunDemo              = 0x00200, //!< A game is going to launch in demo mode. Parameter: game
    EndGame              = 0x00400, //!< Game session end. Parameter: game
    EndDemo              = 0x00800, //!< Game demo session end. Parameter: game
    Sleep                = 0x01000, //!< Pegasus-Frontend is entering sleep state.
    WakeUp               = 0x02000, //!< Pegasus-Frontend is waking up
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
     * @brief Script data
     */
    struct ScriptData
    {
      Path         mPath;      //!< Script path
      Notification mFilter;    //!< Bitflag of notifications this script must reply to
      bool         mSync;      //!< RunSynchronously?
    };

    //! Environement
    char** mEnvironment;

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
     * @brief
     * @return string containing last/previous Action
     */
    std::string LastAction() { return ActionToString(mPreviousParamBag.mAction); }

    /*!
     * @brief
     * @return const model::Game containing last/previous Game
     */
    model::Game* LastGame() { return const_cast<model::Game*>(mPreviousParamBag.mGame); }

    /*!
     * @brief
     * @return const model::Collection containing last/previous Collection
     */
    model::Collection* LastCollection() { return const_cast<model::Collection*>(mPreviousParamBag.mCollection); }

    /*!
     * @brief
     * @param action Action to notify from string
     */
    void NotifyFromString(const std::string& action) {
        Notification event = ActionFromString(action);
        Notify(event, std::string());
    }

    /*!
     * @brief
     * @param action Action to notify from string
     */
    void NotifyFromString(const std::string& action, const std::string& actionData) {
        Notification event = ActionFromString(action);
        Notify(event, actionData);
    }

    /*!
     * @brief
     * @param model::Collection collection to set collection
     * @param std::string action to notify from string
     */
    void NotifyFromString(const model::Collection* collection, const std::string& action) {
        Notification event = ActionFromString(action);
        Notify(collection, event);
    }

    /*!
     * @brief
     * @param model::Collection collection to set collection
     * @param model::Game game to set game
     * @param std::string action to notify from string
     */
    void NotifyFromString(const model::Collection* collection, const model::Game* game, const std::string& action) {
        Notification event = ActionFromString(action);
        const model::GameFile& gamefile = *game->filesConst().first();
        const QFileInfo& finfo = gamefile.fileinfo();
        Notify(collection, game, event, QDir::toNativeSeparators(finfo.absoluteFilePath()).toUtf8().constData());
    }

    /*!
     * @brief Update Pegasus-Frontend status file with game information
     * @param game Target game
     * @param action Action to notify
     */
    void Notify(const model::GameFile* q_gamefile, Notification action) { 
        const model::GameFile& gamefile = *q_gamefile;
        const model::Game& game = *gamefile.parentGame();
        const QFileInfo& finfo = gamefile.fileinfo();
        Notify(nullptr,&game, action, QDir::toNativeSeparators(finfo.absoluteFilePath()).toUtf8().constData());
    }

    /*!
     * @brief Update Pegasus-Frontend status file with system information
     * @param system Target system
     * @param action Action to notify
     */
    void Notify(const model::Collection* collection, Notification action) {
        Notify(collection, nullptr, action, collection->name().toUtf8().constData());
    }

    /*!
     * @brief
     * @param action Action to notify
     */
    void Notify(Notification action) { Notify(nullptr, nullptr, action, std::string()); }

    /*!
     * @brief
     * @param action Action to notify
     * @param actionParameters Optional action parameters
     */
    void Notify(Notification action, const std::string& actionParameters) {
        Notify(nullptr, nullptr, action, actionParameters);
    }

    /*!
     * @brief Run the target using the given arguments.
     * The target is run aither natively or using python or sh regarding the target extension
     * @param target executable/scriupt to run
     * @param arguments arguments passed to the target
     */
    void RunProcess(const Path& target, const Strings::Vector& arguments, bool synchronous, bool permanent);

    /*!
     * @brief Run the target using the given arguments. (run immediatelly in the same thread, should be a quicker one)
     * The target is run aither natively or using python or sh regarding the target extension
     * @param target executable/script to run
     * @param arguments arguments passed to the target
     * @return string content is the result of the script
     */

    std::string RunProcessWithReturn(const Path& target, const Strings::Vector& arguments);

  private:

    //! Shortcut :)
    typedef std::vector<ScriptData> ScriptList;
    //! Shortcut 2 :)
    typedef std::vector<const ScriptData*> RefScriptList;

    /*!
     * @brief Struture to hold a bag of parameters
     */
    struct ParamBag
    {
      // Collection/System
      const model::Collection* mCollection;
      // Game
      const model::Game* mGame;
      // Action
      Notification mAction;
      //! Action parameters
      std::string mActionParameters;

      /*!
       * @brief Default constructor
       */
      ParamBag()
        : mCollection(nullptr),
          mGame(nullptr),
          mAction(Notification::None),
          mActionParameters()
      {
      }

      /*!
       * @brief Full constructor
       * @param model::Collection* collection
       * @param model::Game* game
       * @param Notification action
       * @param std::string& actionParameters
       */
      ParamBag(const model::Collection* collection, const model::Game* game, Notification action, const std::string& actionParameters)
        : mCollection(collection),
          mGame(game),
          mAction(action),
          mActionParameters(actionParameters)
      {
      }

      /*!
       * @brief Inequality operator
       * @param compareTo Structure to compare against
       * @return True if at least one field is not equal
       */
      bool operator != (const ParamBag& compareTo) const
      {
        return ((mCollection != compareTo.mCollection) ||
                (mGame != compareTo.mGame) ||
                (mAction != compareTo.mAction) ||
                (mActionParameters != compareTo.mActionParameters));
      }
    };

    //! Script folder
    static constexpr const char* sScriptPath = "/recalbox/share/userscripts";

    //RFU
    //! MQTT Topic
    //static constexpr const char* sEventTopic = "Recalbox/Pegasus-Frontend/Event";
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
     * @brief Update Pegasus-Frontend status file
     * @param collection Target System (may be null)
     * @param game Target game (may be null)
     * @param play True if the target game is going to be launched
     * @param demo True if the target game is going ot be launched as demo
     */
    void Notify(const model::Collection* collection, const model::Game* game, Notification action, const std::string& actionParameters);
    
    /*!
     * @brief Run all script associated to the given action
     * @param action Action to filter scripts with
     * @param param Optional action parameter
     */
    void RunScripts(Notification action, const std::string& param);

    /*!
     * @brief Build es_state.info Common information into output string
     * @param output Output string
     * @param collection Collection or nullptr
     * @param game Game or nullptr
     * @param action Notification
     * @param actionParameters Notification parameters or empty string
     */
    static void BuildStateCommons(std::string& output, const model::Collection* collection, const model::Game* game, Notification action, const std::string& actionParameters);

    /*!
     * @brief Build es_state.info game information into output string
     * @param output Output string
     * @param game Game or nullptr
     */
    static void BuildStateGame(std::string& output, const model::Game* game);
    
    /*!
     * @brief Build es_state.info system information into output string
     * @param output Output string
     * @param collection Collection or nullptr
     */
    static void BuildStateSystem(std::string& output, const model::Collection* collection);

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

//create a specific object to work in independant thread
class ScriptManagerThread : public QThread {
    Q_OBJECT

public:
    ScriptManagerThread(const Path& _target, const Strings::Vector& _arguments, bool _synchronous, char* const* _mEnvironment)
        :target(_target),
        arguments(_arguments),
        synchronous(_synchronous),
        mEnvironment(_mEnvironment)
    {}
private:
    const Path& target;
    const Strings::Vector& arguments;
    bool synchronous;
    char* const* mEnvironment;

signals:
    void finished(int exit_status);

protected:

    void run() override {
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

        { LOG(LogDebug) << "[Script] Run script in dedicated thread: " << Strings::Join(args, ' '); }

        // Push final null
        args.push_back(nullptr);

        pid_t pid = 0;
        pid_t wpid;
        posix_spawnattr_t spawn_attr;
        posix_spawnattr_init(&spawn_attr);
        int status = posix_spawn(&pid, command.data(), nullptr, &spawn_attr, (char **) args.data(), mEnvironment);
        posix_spawnattr_destroy(&spawn_attr);
        if (status != 0) // Error
        {
            { LOG(LogError) << "[Script] Error running " << target.ToString() << " (spawn failed)"; }
            return;
        }

        // Wait for child? and block UI in this case
        if (synchronous)
        {
            do {
                wpid = waitpid(pid, &status, WNOHANG);
                if(wpid == pid){
                    if (WIFEXITED(status)) {
                        LOG(LogError) << "[Script] Exited, status=" << WEXITSTATUS(status);
                    }
                    else if (WIFSIGNALED(status)) {
                        LOG(LogError) << "[Script] Killed by signal " << WTERMSIG(status);
                    }
                    else if (WIFSTOPPED(status)) {
                        LOG(LogError) << "[Script] Stopped by signal " << WSTOPSIG(status);
                    }
                    break; // we could leave loop
                }
                else if(wpid == 0){
                    LOG(LogDebug) << "[Script] Continued...";
                    QThread::msleep(2000);
                }
                else{
                    LOG(LogError) << "[Script] Error waiting for " << target.ToString() << " to complete. (waitpid failed)";
                    break; // we could leave loop
                }
            }
            while (wpid != pid);
            LOG(LogDebug) << "[Script] exit loop";
        }
        // Emit signal with exit code
        emit finished(WEXITSTATUS(status));
    }
};
