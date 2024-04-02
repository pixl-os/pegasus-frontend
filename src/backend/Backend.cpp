// Pegasus Frontend
// Copyright (C) 2018  Mátyás Mustoha
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


#include "Backend.h"

#include "AppSettings.h"
#include "Log.h"

#include "FrontendLayer.h"
#include "ProcessLauncher.h"
#include "ScriptRunner.h"
#include "platform/PowerCommands.h"
#include "types/AppCloseType.h"

// For type registration
#include "model/Api.h"
#include "model/keys/Key.h"
#include "model/gaming/Assets.h"
#include "model/gaming/GameFile.h"
#include "utils/FolderListModel.h"
#include "QtQmlTricks/QQmlObjectListModel.h"
#include "SortFilterProxyModel/qqmlsortfilterproxymodel.h"
#include "SortFilterProxyModel/filters/filtersqmltypes.h"
#include "SortFilterProxyModel/proxyroles/proxyrolesqmltypes.h"
#include "SortFilterProxyModel/sorters/sortersqmltypes.h"
#include <QGuiApplication>
#include <QQmlEngine>

#if defined(WITH_SDL_GAMEPAD) || defined(WITH_SDL_POWER)
#include <SDL.h>
#endif



namespace model { class Key; }
namespace model { class Keys; }
class FolderListModel;


namespace {
void print_metainfo()
{
    Log::info(LOGMSG("Pegasus for recal - BUILD: " __DATE__ " " __TIME__ " GIT: " GIT_REVISION " (" GIT_DATE ")"));
    Log::info(LOGMSG("Running on %1 (%2, %3)").arg(
        QSysInfo::prettyProductName(),
        QSysInfo::currentCpuArchitecture(),
        QGuiApplication::platformName()));
    Log::info(LOGMSG("Qt version %1").arg(qVersion()));
    Log::info(LOGMSG("Qt 'QLibraryInfo' version %1").arg(QLibraryInfo::version().toString()));
    Log::info(LOGMSG("Qt PrefixPath: %1").arg(QLibraryInfo::location(QLibraryInfo::PrefixPath)));        //	0	The default prefix for all paths.
    Log::info(LOGMSG("Qt DocumentationPath: %1").arg(QLibraryInfo::location(QLibraryInfo::DocumentationPath))); //	1	The location for documentation upon install.
    Log::info(LOGMSG("Qt HeadersPath: %1").arg(QLibraryInfo::location(QLibraryInfo::HeadersPath))); //	2	The location for all headers.
    Log::info(LOGMSG("Qt LibrariesPath: %1").arg(QLibraryInfo::location(QLibraryInfo::LibrariesPath))); //	3	The location of installed libraries.
    Log::info(LOGMSG("Qt LibraryExecutablesPath: %1").arg(QLibraryInfo::location(QLibraryInfo::LibraryExecutablesPath))); //	4	The location of installed executables required by libraries at runtime.
    Log::info(LOGMSG("Qt BinariesPath: %1").arg(QLibraryInfo::location(QLibraryInfo::BinariesPath))); //	5	The location of installed Qt binaries (tools and applications).
    Log::info(LOGMSG("Qt PluginsPath: %1").arg(QLibraryInfo::location(QLibraryInfo::PluginsPath))); //	6	The location of installed Qt plugins.
    Log::info(LOGMSG("Qt ImportsPath: %1").arg(QLibraryInfo::location(QLibraryInfo::ImportsPath))); //	7	The location of installed QML extensions to import (QML 1.x).
    Log::info(LOGMSG("Qt Qml2ImportsPath: %1").arg(QLibraryInfo::location(QLibraryInfo::Qml2ImportsPath))); //	8	The location of installed QML extensions to import (QML 2.x).
    Log::info(LOGMSG("Qt ArchDataPath: %1").arg(QLibraryInfo::location(QLibraryInfo::ArchDataPath))); //	9	The location of general architecture-dependent Qt data.
    Log::info(LOGMSG("Qt DataPath: %1").arg(QLibraryInfo::location(QLibraryInfo::DataPath))); //	10	The location of general architecture-independent Qt data.
    Log::info(LOGMSG("Qt TranslationsPath: %1").arg(QLibraryInfo::location(QLibraryInfo::TranslationsPath))); //	11	The location of translation information for Qt strings.
    Log::info(LOGMSG("Qt ExamplesPath: %1").arg(QLibraryInfo::location(QLibraryInfo::ExamplesPath))); //	12	The location for examples upon install.
    Log::info(LOGMSG("Qt TestsPath: %1").arg(QLibraryInfo::location(QLibraryInfo::TestsPath))); //	13	The location of installed Qt testcases.
    Log::info(LOGMSG("Qt SettingsPath: %1").arg(QLibraryInfo::location(QLibraryInfo::SettingsPath))); //	100	The location for Qt settings. Not applicable on Windows.*/
}

void register_api_classes()
{
    // register API classes:
    //   this should come before the ApiObject constructor,
    //   as that may produce language change signals

    constexpr auto API_URI = "Pegasus.Model";
    const QString error_msg = LOGMSG("Sorry, you cannot create this type in QML.");

    qmlRegisterUncreatableType<model::Collection>(API_URI, 0, 7, "Collection", error_msg);
    qmlRegisterUncreatableType<model::Game>(API_URI, 0, 2, "Game", error_msg);
    qmlRegisterUncreatableType<model::Assets>(API_URI, 0, 2, "GameAssets", error_msg);
    qmlRegisterUncreatableType<model::Locales>(API_URI, 0, 11, "Locales", error_msg);
    qmlRegisterUncreatableType<model::Themes>(API_URI, 0, 11, "Themes", error_msg);
    qmlRegisterUncreatableType<model::Providers>(API_URI, 0, 11, "Providers", error_msg);
    qmlRegisterUncreatableType<model::Key>(API_URI, 0, 10, "Key", error_msg);
    qmlRegisterUncreatableType<model::Keys>(API_URI, 0, 10, "Keys", error_msg);
    qmlRegisterUncreatableType<model::GamepadManager>(API_URI, 0, 12, "GamepadManager", error_msg);
    qmlRegisterUncreatableType<model::DeviceInfo>(API_URI, 0, 13, "Device", error_msg);

    // QML utilities
    qmlRegisterType<FolderListModel>("Pegasus.FolderListModel", 1, 0, "FolderListModel");

    // third-party
    qmlRegisterUncreatableType<QQmlObjectListModelBase>("QtQmlTricks.SmartDataModels",
                                                        2, 0, "ObjectListModel", error_msg);
    qqsfpm::registerSorterTypes();
    qqsfpm::registerFiltersTypes();
    qqsfpm::registerProxyRoleTypes();
    qqsfpm::registerQQmlSortFilterProxyModelTypes();
}

void on_app_close(AppCloseType type)
{
    QString AppCloseTypeName;
    ScriptRunner::run(ScriptEvent::QUIT);
    switch (type) {
        case AppCloseType::RESTART:
            AppCloseTypeName = "Restart";
            ScriptManager::Instance().Notify(Notification::Relaunch,"normal");
            ScriptRunner::run(ScriptEvent::RESTART);
            break;
        case AppCloseType::REBOOT:
            AppCloseTypeName = "Reboot";
            ScriptManager::Instance().Notify(Notification::Reboot,"normal");
            ScriptRunner::run(ScriptEvent::REBOOT);
            break;
        case AppCloseType::SHUTDOWN:
            AppCloseTypeName = "Shutdown";
            ScriptManager::Instance().Notify(Notification::Shutdown,"normal");
            ScriptRunner::run(ScriptEvent::SHUTDOWN);
            break;
        default: break;
    }
    
    Log::info(LOGMSG("Closing Pegasus, goodbye! %1...").arg(AppCloseTypeName));
    Log::close();
    
    QCoreApplication::quit();
    switch (type) {
        case AppCloseType::RESTART:
            platform::power::restart();
            break;
        case AppCloseType::REBOOT:
            platform::power::reboot();
            break;
        case AppCloseType::SHUTDOWN:
            platform::power::shutdown();
            break;
        default: break;
    }
}
} // namespace

namespace backend {

Backend::~Backend()
{
    delete m_launcher;
    delete m_frontend;
    delete m_api;
    delete m_httpapi;

#if defined(WITH_SDL_GAMEPAD) || defined(WITH_SDL_POWER)
    SDL_Quit();
#endif
}

Backend::Backend(const CliArgs& args, char** environment)
  : mScriptManager(environment)
{
    // Make sure this comes before any file related operations
    AppSettings::general.portable = args.portable;

    //pegasus logs
    Log::init(args.silent);
        
    print_metainfo();
    register_api_classes();

    AppSettings::load_providers();
    AppSettings::load_config();

    m_api = new ApiObject(args);
    m_frontend = new FrontendLayer(m_api);
    m_launcher = new ProcessLauncher();
    //start http server to help system scripts to communicate with pegasus-frontend
    m_httpapi = new HttpServer(1234);

    // the following communication is required because process handling
    // and destroying/rebuilding the frontend stack are asynchronous tasks;
    // see the relevant classes

    // the Api asks the Launcher to start the game
    QObject::connect(m_api, &ApiObject::launchGameFile,
                     m_launcher, &ProcessLauncher::onLaunchRequested);

    // the Launcher tries to start the game, ask the Frontend
    // to tear down the UI, then report back to the Api
    QObject::connect(m_launcher, &ProcessLauncher::processLaunchOk,
                     m_api, &ApiObject::onGameLaunchOk);

    QObject::connect(m_launcher, &ProcessLauncher::processLaunchError,
                     m_api, &ApiObject::onGameLaunchError);

    //event to show popup to frontend
    QObject::connect(&m_api->internal().gamepad(), &model::GamepadManager::showPopup,
                     m_api, &ApiObject::onShowPopup);

    //event to configure new controller from frontend
    QObject::connect(&m_api->internal().gamepad(), &model::GamepadManager::newController,
                     m_api, &ApiObject::onNewController);

    QObject::connect(m_launcher, &ProcessLauncher::processLaunchOk,
                     m_frontend, &FrontendLayer::teardown);

    QObject::connect(m_frontend, &FrontendLayer::teardownComplete,
                     m_launcher, &ProcessLauncher::onTeardownComplete);

    // when the game ends, the Launcher wakes up the Api and the Frontend
    QObject::connect(m_launcher, &ProcessLauncher::processFinished,
                     m_api, &ApiObject::onGameFinished);

    QObject::connect(m_launcher, &ProcessLauncher::processFinished,
                     m_frontend, &FrontendLayer::rebuild);


    // to reset QML cache
    QObject::connect(&m_api->internal().meta(), &model::Meta::qmlClearCacheRequested,
                     m_frontend, &FrontendLayer::clearCache);

    // to optimize QML cache
    QObject::connect(&m_api->internal().meta(), &model::Meta::qmlTrimCacheRequested,
                     m_frontend, &FrontendLayer::trimCache);

    // quit/reboot/restart/shutdown request
    QObject::connect(&m_api->internal().system(), &model::System::appCloseRequested, on_app_close);

    // to reload parameters from recalbox.conf
    QObject::connect(m_httpapi, &HttpServer::confReloaded,&m_api->internal().recalbox(), &model::Recalbox::reloadParameter);

    //to send action to frontend from HTTP API
    QObject::connect(m_httpapi, &HttpServer::requestAction, m_api, &ApiObject::requestAction);

}

void Backend::start()
{
    // Save power for battery-powered devices
    mBoard.SetCPUGovernance(IBoardInterface::CPUGovernance::PowerSave);

    // Audio controller initialisation
    if(mRecalboxConf.AsString("audio.mode") != "none") mAudioController.SetVolume(mAudioController.GetVolume());
    else mAudioController.SetVolume(0); // to mute in all cases
    std::string originalAudioDevice = mRecalboxConf.GetAudioOuput();
    std::string fixedAudioDevice = mAudioController.SetDefaultPlayback(originalAudioDevice);
    if (fixedAudioDevice != originalAudioDevice)
    {
      mRecalboxConf.SetAudioOuput(fixedAudioDevice);
      mRecalboxConf.Save();
    }
    
    // Script Manager start launch
    mScriptManager.Notify(Notification::Start, Strings::ToString(0));
    
    m_frontend->rebuild();
    m_api->startScanning(); // TODO: Separate scanner
}

} // namespace backend
