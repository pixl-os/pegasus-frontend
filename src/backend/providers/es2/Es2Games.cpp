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

    // find all (sub-)directories, but ignore 'media'
    const QStringList dirs = [& system_dir]{
        QStringList result;

        constexpr auto subdir_filters = QDir::Dirs | QDir::Readable | QDir::NoDotAndDotDot;
        constexpr auto subdir_flags = QDirIterator::FollowSymlinks | QDirIterator::Subdirectories;
        QDirIterator dirs_it(system_dir.path(), subdir_filters, subdir_flags);
        while (dirs_it.hasNext())
            result.append(dirs_it.next());

        result.removeOne(system_dir.path() + QStringLiteral("/media"));
        result.append(system_dir.path());
        return result;
    }();

    // scan for game files 
    constexpr auto entry_filters = QDir::Files | QDir::Dirs | QDir::Readable | QDir::NoDotAndDotDot;
    constexpr auto entry_flags = QDirIterator::FollowSymlinks;
    const QStringList name_filters = parse_filters(sysentry.extensions);

    size_t found_games = 0;
    for (const QString& dir_path : dirs) {
        QDirIterator files_it(dir_path, name_filters, entry_filters, entry_flags);
        while (files_it.hasNext()) {
            files_it.next();
            QFileInfo fileinfo = files_it.fileInfo();

            const QString filename = fileinfo.completeBaseName();

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
