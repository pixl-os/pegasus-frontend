// Pegasus Frontend
// Copyright (C) 2017-2020  Mátyás Mustoha
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
//
// Updated and integrated for recalbox by BozoTheGeek 03/05/2021
//

#include "Es2Provider.h"

#include "Log.h"
#include "Paths.h"
#include "providers/es2/Es2Games.h"
#include "providers/es2/Es2Metadata.h"
#include "providers/es2/Es2Systems.h"

//For recalbox
#include "RecalboxConf.h"

#include <QDir>
#include <QStringBuilder>
#include <QElapsedTimer>
#include <QCoreApplication>

namespace {
std::vector<QString> default_config_paths()
{
    QString shareInitPath = paths::homePath() % QStringLiteral("/.pegasus-frontend/");
    shareInitPath.replace("/share/","/share_init/");
    //to work in all cases and also on other linux distribution
    QString shareInitStrongPath = QStringLiteral("/recalbox/share_init/system/.pegasus-frontend/");
    return {
        paths::homePath() % QStringLiteral("/.pegasus-frontend/"),
        shareInitPath,
        QStringLiteral("/etc/pegasus-frontend/"),
        shareInitStrongPath
    };
}

} // namespace


namespace providers {
namespace es2 {

Es2Provider::Es2Provider(QObject* parent)
    : Provider(QLatin1String("es2"), QStringLiteral("Gamelist"), parent)
{}

Provider& Es2Provider::run(SearchContext& sctx)
{

    std::vector<QString> possible_config_dirs = [this]{
        const auto option_it = options().find(QStringLiteral("installdir"));
        return (option_it != options().cend())
            ? std::vector<QString>{ QDir::cleanPath(option_it->second.front()) + QLatin1Char('/') }
            : default_config_paths();
    }();

    for (int i = 0; i < possible_config_dirs.size(); ++i) {
        Log::info(display_name(), LOGMSG("ES2 Default config path : %1").arg(possible_config_dirs.at(i)));
    }

    //Create metadata helper
    Metadata metahelper("Metadata", possible_config_dirs);

    // Find systems
    QElapsedTimer systems_timer;
    systems_timer.start();
    const std::vector<SystemEntry> systems = find_systems(display_name(), possible_config_dirs);
    if (systems.empty())
        return *this;
    Log::info(display_name(), LOGMSG("Stats: Found %1 systems").arg(QString::number(systems.size())));

    const float progress_step = 1.f / (systems.size() * 2);
    float progress = 0.f;
    Log::info(LOGMSG("Global Timing: Systems searching took %1ms").arg(systems_timer.elapsed()));

    // Find games (file by file) - take bios files also or other file hide
    QElapsedTimer games_timer;
    games_timer.start();
    for (const SystemEntry& sysentry : systems) {
            const size_t found_cores = create_collection_for(sysentry, sctx);
            Log::info(display_name(), LOGMSG("System `%1` has %2 emulator/cores")
                .arg(sysentry.name, QString::number(found_cores)));
            emit progressStage(sysentry.name);

            // Find system videos
            const size_t found_videos = find_system_videos_for(sysentry, sctx);
            Log::debug(display_name(), LOGMSG("System `%1` provided %2 system videos")
            .arg(sysentry.name, QString::number(found_videos)));

            for(const QString& romsDir : paths::romsDirs()){
                QString share_path = sysentry.path ;
                share_path = share_path.replace("%ROOT%",romsDir);
                const QDir xml_dir(share_path);

                //if gamelistfist activated we propose to search games if no gamelist in this system
                if(RecalboxConf::Instance().AsBool("pegasus.gamelistfirst"))
                {
                    //check if no gamelist exists
                    if(metahelper.find_gamelist_xml(possible_config_dirs, xml_dir,sysentry).isEmpty()){
                        const size_t found_games = find_games_for(sysentry, xml_dir, sctx);
                        Log::debug(display_name(), LOGMSG("System `%1` provided %2 games from share init")
                        .arg(sysentry.name, QString::number(found_games)));
                    }
                }
                // Find games if not Gamelist Only activated
                else if(!RecalboxConf::Instance().AsBool("pegasus.gamelistonly"))
                {
                    //check if game exists
                    size_t found_games = find_games_for(sysentry, xml_dir, sctx);
                    Log::debug(display_name(), LOGMSG("System `%1` provided %2 games from share init")
                    .arg(sysentry.name, QString::number(found_games)));
                }

                progress += progress_step;
                emit progressChanged(progress);
            }
    }
    Log::info(LOGMSG("Global Timing: Game files searching took %1ms").arg(games_timer.elapsed()));

    // prepare and parse lightgun games from lightgun.cfg
    QElapsedTimer lightgun_games_timer;
    lightgun_games_timer.start();
    emit progressStage("lightgun games");
    progress += progress_step;
    emit progressChanged(progress);
    //Process event in the queue
    QCoreApplication::processEvents();
    metahelper.prepare_lightgun_games_metadata();
    Log::info(LOGMSG("Stats - Global Timing: lightgun.cfg parsing took %1ms").arg(lightgun_games_timer.elapsed()));

    // Find assets and games in case of gamelist only (+ add info for lightgun games)
    QElapsedTimer assets_timer;
    assets_timer.start();
    //unlock file system temporary to permit to store updates during asset parsing (as generation of media.xml from share_init for example)
    if (system("mount -o remount,rw /") != 0) Log::error(LOGMSG("Issue to provide read/write on '/'"));
    for(const QString& romsDir : paths::romsDirs()){
        if(romsDir.contains("/share_init/")){
            //unlock file system temporary to permit to store updates during asset parsing (as generation of media.xml from share_init for example)
            if (system("mount -o remount,rw /") != 0) Log::error(LOGMSG("Issue to provide read/write on '/'"));
        }
        for (const SystemEntry& sysentry : systems) {
            QString share_path = sysentry.path ;
            share_path = share_path.replace("%ROOT%",romsDir);
            const QDir xml_dir(share_path);
            emit progressStage(sysentry.name);
            progress += progress_step;
            emit progressChanged(progress);
            //Process event in the queue
            QCoreApplication::processEvents();
            metahelper.find_metadata_for_system(sysentry, xml_dir, sctx);
        }
        if(romsDir.contains("/share_init/")){
            //unlock file system after asset parsing/updates from share_init
            if (system("mount -o remount,ro /") != 0) Log::error(LOGMSG("Issue to provide read only on '/'"));
        }
    }
    Log::info(LOGMSG("Stats - Global Timing: Gamelists/Assets parsing/searching took %1ms").arg(assets_timer.elapsed()));
    return *this;
}

inputConfigEntry Es2Provider::load_input_data(const QString& DeviceName, const QString& DeviceGUID)
{
    std::vector<QString> possible_config_dirs = [this]{
        const auto option_it = options().find(QStringLiteral("installdir"));
        return (option_it != options().cend())
            ? std::vector<QString>{ QDir::cleanPath(option_it->second.front()) + QLatin1Char('/') }
            : default_config_paths();
    }();

    // Find input with CRC and Without if needed
    // since 25/02/24 - with new buildroot and new SDL2 version
    providers::es2::inputConfigEntry inputentry = find_input(display_name(), possible_config_dirs,DeviceName, DeviceGUID);
    if((inputentry.inputConfigAttributs.deviceGUID != DeviceGUID) && (DeviceGUID.mid(4,4) != "0000")){
        QString DeviceGUIDWithoutCRC = DeviceGUID.mid(0,4) + "0000" + DeviceGUID.mid(8);
        inputentry = find_input(display_name(), possible_config_dirs,DeviceName, DeviceGUIDWithoutCRC);
        if(inputentry.inputConfigAttributs.deviceGUID == DeviceGUIDWithoutCRC){
            //save conf with DeviceGUID with CRC
            inputentry.inputConfigAttributs.deviceGUID = DeviceGUID;
            bool status = save_input_data(inputentry);
        }
    }
    return inputentry;
}

inputConfigEntry Es2Provider::load_any_input_data_by_guid(const QString& DeviceGUID)
{
    std::vector<QString> possible_config_dirs = [this]{
        const auto option_it = options().find(QStringLiteral("installdir"));
        return (option_it != options().cend())
            ? std::vector<QString>{ QDir::cleanPath(option_it->second.front()) + QLatin1Char('/') }
            : default_config_paths();
    }();

    // Find input
    return find_any_input_by_guid(display_name(), possible_config_dirs,DeviceGUID);

}

bool Es2Provider::save_input_data(const inputConfigEntry& input)
{
    std::vector<QString> possible_config_dirs = [this]{
        const auto option_it = options().find(QStringLiteral("installdir"));
        return (option_it != options().cend())
            ? std::vector<QString>{ QDir::cleanPath(option_it->second.front()) + QLatin1Char('/') }
            : default_config_paths();
    }();
    const inputConfigEntry& input_to_save = input;
    // save input
    return save_input(display_name(), possible_config_dirs, input_to_save);

}

SystemEntry Es2Provider::find_one_system(const QString shortName)
{

    std::vector<QString> possible_config_dirs = [this]{
        const auto option_it = options().find(QStringLiteral("installdir"));
        return (option_it != options().cend())
            ? std::vector<QString>{ QDir::cleanPath(option_it->second.front()) + QLatin1Char('/') }
            : default_config_paths();
    }();

    /*for (int i = 0; i < possible_config_dirs.size(); ++i) {
        Log::debug(display_name(), LOGMSG("ES2 Default config path : %1").arg(possible_config_dirs.at(i)));
    }*/

    // Find one system
    //QElapsedTimer systems_timer;
    //systems_timer.start();
    //Log::debug("ES2 Provider", LOGMSG("shortName : '%1'").arg(shortName));
    SystemEntry system = find_system("ES2 Provider", possible_config_dirs, shortName);
    //Log::debug("ES2 Provider", LOGMSG("Found '%1' system").arg(system.shortname));
    //Log::debug(LOGMSG("System searching took %1ms").arg(systems_timer.elapsed()));
    return system;
}

} // namespace es2
} // namespace providers
