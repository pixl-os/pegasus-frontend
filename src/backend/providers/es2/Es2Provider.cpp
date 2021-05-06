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

namespace {
std::vector<QString> default_config_paths()
{
    return {
        paths::homePath() % QStringLiteral("/.emulationstation/"),
        QStringLiteral("/etc/emulationstation/"),
    };
}

} // namespace


namespace providers {
namespace es2 {

Es2Provider::Es2Provider(QObject* parent)
    : Provider(QLatin1String("es2"), QStringLiteral("EmulationStation"), parent)
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

    // Find systems
    QElapsedTimer systems_timer;
    systems_timer.start();
    const std::vector<SystemEntry> systems = find_systems(display_name(), possible_config_dirs);
    if (systems.empty())
        return *this;
    Log::info(display_name(), LOGMSG("Stats: Found %1 systems").arg(QString::number(systems.size())));

    const float progress_step = 1.f / (systems.size() * 2);
    float progress = 0.f;
    Log::info(LOGMSG("Stats - Global Timing: Systems searching took %1ms").arg(systems_timer.elapsed()));
    
    // Find games (file by file) - take bios files also or other file hide
    QElapsedTimer games_timer;
    games_timer.start();    
    for (const SystemEntry& sysentry : systems) {
            const size_t found_cores = create_collection_for(sysentry, sctx);
            Log::info(display_name(), LOGMSG("System `%1` has %2 emulator/cores")
                .arg(sysentry.name, QString::number(found_cores)));
            
            // Find games if not Gamelist Only activated
            if(!RecalboxConf::Instance().AsBool("emulationstation.gamelistonly"))
            {
                // Load MAME blacklist, if exists
                const std::vector<QString> mame_blacklist = read_mame_blacklists(display_name(), possible_config_dirs);
                const size_t found_games = find_games_for(sysentry, sctx, mame_blacklist);
                Log::info(display_name(), LOGMSG("Stats - System `%1` provided %2 games")
                .arg(sysentry.name, QString::number(found_games)));
            }
            progress += progress_step;
            emit progressChanged(progress);
    }
    Log::info(LOGMSG("Stats - Global Timing: Game files searching took %1ms").arg(games_timer.elapsed()));
    // Find assets and games in case of gamelist only
    QElapsedTimer assets_timer;
    assets_timer.start(); 
    const Metadata metahelper(display_name(), std::move(possible_config_dirs));
    for (const SystemEntry& sysentry : systems) {
        metahelper.find_metadata_for(sysentry, sctx);

        progress += progress_step;
        emit progressChanged(progress);
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

    // Find input
    return find_input(display_name(), possible_config_dirs,DeviceName, DeviceGUID);

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


} // namespace es2
} // namespace providers
