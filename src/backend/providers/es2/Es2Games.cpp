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
#include "Es2Games.h"

#include "Log.h"
#include "Paths.h"
#include "RootFolders.h"
#include "model/gaming/Assets.h"
#include "model/gaming/Collection.h"
#include "providers/SearchContext.h"
#include "providers/es2/Es2Systems.h"
#include "utils/PathTools.h"
#include "utils/StdHelpers.h"

#include <QDirIterator>
#include <QFile>
#include <QRegularExpression>
#include <QStringBuilder>
#include <QTextStream>


namespace {
QVector<QStringRef> split_list(const QString& str)
{
    // FIXME: don't leave statics around
    static const QRegularExpression separator(QStringLiteral("[,\\s]"));
    return str.splitRef(separator, Qt::SkipEmptyParts);
}

/// returns a list of unique, '*.'-prefixed lowercase file extensions
QStringList parse_filters(const QString& filters_raw) {
    const QString filters_lowercase = filters_raw.toLower();
    const QVector<QStringRef> filter_refs = split_list(filters_lowercase);

    QStringList filter_list;
    for (const QStringRef& filter_ref : filter_refs)
        filter_list.append(QChar('*') + filter_ref.trimmed());

    filter_list.removeDuplicates();
    return filter_list;
}
} // namespace


namespace providers {
namespace es2 {

size_t create_collection_for(
    const SystemEntry& sysentry,
    SearchContext& sctx)
    
{
    size_t found_cores = 0;
    model::Collection& collection = *sctx.get_or_create_collection(sysentry.name);

    collection
        .setShortName(sysentry.shortname)
        .setCommonLaunchCmd(sysentry.launch_cmd)
        .setScreenScraperId(sysentry.screenscraper)
        .setManufacturer(sysentry.manufacturer)
        .setType(sysentry.type)
        .setReleaseDate(sysentry.releasedate)
        //flag added 02/10/2023 from systemlist.xml
        .setPad(sysentry.pad.toInt())
        .setKeyboard(sysentry.keyboard.toInt())
        .setMouse(sysentry.mouse.toInt())
        .setLightgun(sysentry.lightgun != "no" ? true : false)
        .setRetroachievements(sysentry.retroachievements.toInt());
        
    struct model::EmulatorsEntry Emulator;
    QList<model::EmulatorsEntry> AllEmulators;
    
    for (int n = 0; n < sysentry.emulators.count(); n++)
    {
        Emulator.name = sysentry.emulators[n].name;
        Emulator.core = sysentry.emulators[n].core;
        Emulator.priority = sysentry.emulators[n].priority;
		Emulator.netplay = sysentry.emulators[n].netplay;
		Emulator.corelongname = sysentry.emulators[n].corelongname;
        Emulator.coreversion = sysentry.emulators[n].coreversion;
        Emulator.coreextensions = sysentry.emulators[n].coreextensions;
        Emulator.corecompatibility = sysentry.emulators[n].corecompatibility;
        Emulator.corespeed = sysentry.emulators[n].corespeed;
        AllEmulators.append(Emulator);
        found_cores++;
    }
    collection.setCommonEmulators(AllEmulators);
    
    return found_cores;
}

size_t find_games_for(
    const SystemEntry& sysentry,
    const QDir& system_dir,
    SearchContext& sctx)
{
    model::Collection& collection = *sctx.get_or_create_collection(sysentry.name);

    // This vector will act as our queue for directories to process
    QVector<QString> dirs_to_scan;
    dirs_to_scan.append(system_dir.path()); // Start with the system's root directory

    // Parse the extensions into QDir::match-compatible filters (e.g., "*.nes", "*.zip")
    const QStringList name_filters = parse_filters(sysentry.extensions);

    size_t found_games = 0;
    int current_dir_index = 0; // Index to simulate popping from the front of the queue

    // Manual BFS traversal
    while (current_dir_index < dirs_to_scan.size()) {
        const QString current_dir_path = dirs_to_scan.at(current_dir_index++);

        // Skip the specific "media" directory if it's the one under the system_dir.
        // We do this check here, so we don't even scan its contents.
        if (current_dir_path == system_dir.path() + QStringLiteral("/media")) {
            continue;
        }

        // Prepare QDirIterator to find both files and directories in the current_dir_path
        // We do NOT use QDirIterator::Subdirectories here, as we manually control recursion.
        constexpr auto entry_filters = QDir::Files | QDir::Dirs | QDir::Readable | QDir::NoDotAndDotDot;
        constexpr auto entry_flags = QDirIterator::FollowSymlinks; // Still follow symlinks for direct entries

        QDirIterator it(current_dir_path, entry_filters, entry_flags);

        while (it.hasNext()) {
            it.next(); // Advance to the next entry (file or directory)
            QFileInfo fileinfo = it.fileInfo();

            // Check if the current entry's name (file or directory name) matches any of the game extensions
            bool matches_extension = false;
            for (const QString& filter : name_filters) {
                // QDir::match can match against full names like "MyGame.zip" or "AnotherGame.nes"
                // It works for both files and directories.
                if (QDir::match(filter, fileinfo.fileName())) {
                    matches_extension = true;
                    break;
                }
            }

            if (fileinfo.isDir()) {
                if (matches_extension) {
                    // Scenario: Directory itself is a game (e.g., "MyGame.ps1/")
                    // Add this directory as a game entry.
                    // IMPORTANT: We DO NOT add this directory to 'dirs_to_scan',
                    // effectively preventing further scanning *inside* it.
                    QString path = ::clean_abs_path(fileinfo);
                    model::Game* game_ptr = sctx.game_by_filepath(path);
                    if (!game_ptr) {
                        game_ptr = sctx.create_game_for(collection);
                        sctx.game_add_filepath(*game_ptr, std::move(path));
                    }
                    sctx.game_add_to(*game_ptr, collection);
                    found_games++;
                } else {
                    // Scenario: Regular directory (e.g., "Roms", "Games")
                    // Add this directory to the list for future scanning,
                    // unless it's the "media" directory.
                    // Ensure 'media' is skipped, even if deeper in structure.
                    if (fileinfo.fileName().compare(QStringLiteral("media"), Qt::CaseInsensitive) != 0) {
                        dirs_to_scan.append(fileinfo.absoluteFilePath());
                    }
                }
            } else if (fileinfo.isFile()) {
                if (matches_extension) {
                    // Scenario: Regular file that is a game (e.g., "game.nes", "rom.zip")
                    QString path = ::clean_abs_path(fileinfo);
                    model::Game* game_ptr = sctx.game_by_filepath(path);
                    if (!game_ptr) {
                        game_ptr = sctx.create_game_for(collection);
                        sctx.game_add_filepath(*game_ptr, std::move(path));
                    }
                    sctx.game_add_to(*game_ptr, collection);
                    found_games++;
                }
            }
        }
    }

    return found_games;
}

size_t find_system_videos_for(
        const SystemEntry& sysentry,
        SearchContext& sctx)
{
    //get collection from name
    model::Collection& collection = *sctx.get_or_create_collection(sysentry.name);
    size_t found_videos = 0;

    //check the share_init also
    QString fileNameFromShare(QString::fromStdString(RootFolders::DataRootFolder.ToString()) + "/videos/" + sysentry.shortname + "/" +  sysentry.shortname + QStringLiteral(".mp4"));
    //Log::debug("video system search",LOGMSG("filepath from 'videos' share folder: '%1' ").arg(fileNameFromShare));
    if(QFileInfo::exists(fileNameFromShare)){
        Log::debug("video system search",LOGMSG("file found: '%1' ").arg(fileNameFromShare));
        //Add video found in collection assets
        collection.assetsMut().add_file(AssetType::VIDEO, fileNameFromShare);
        found_videos++;
    }
    return found_videos;
}

} // namespace es2
} // namespace providers
