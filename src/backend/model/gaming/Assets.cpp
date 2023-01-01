// Pegasus Frontend
// Copyright (C) 2017-2019  Mátyás Mustoha
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


#include "Assets.h"
#include "Log.h"

#include "model/gaming/Game.h"
#include "model/gaming/GameFile.h"

#include <QUrl>

#include <QDir>
#include <QDirIterator>
#include <QFile>
#include <QFileInfo>

namespace model {

Assets::Assets(QObject* parent)
    : QObject(parent)
{}

const QStringList& Assets::get(AssetType key, bool searchFirstOnly) {

    static const QStringList empty_list({});

    //***for test asap if this "AssetType" exists***
    /*const auto it_log = ASSET_DIRS.find(key);
    if (it_log != ASSET_DIRS.cend()){
            if (!it_log->second.isEmpty()){
                Log::info(m_log_tag, LOGMSG("get - it_log->second : %1").arg(it_log->second.join(",")));
            }
            else return empty_list;
    }
    else return empty_list;*/
    //*****************************************
    const auto it = m_asset_lists.find(key);
    //check first to know if empty or not found
    if ((it == m_asset_lists.cend()) || it->second.isEmpty()){
        //search if assets exists in share for games (if not a game, function will exit immediatly with return 0
        size_t nbAssetFound = find_asset_for_game(key, searchFirstOnly);
        if(nbAssetFound != 0){
            const auto it2 = m_asset_lists.find(key);
            if (it2 != m_asset_lists.cend()){
                if(!it2->second.isEmpty()){
                    if(it2->second.constFirst() != "not found"){
                        return it2->second;
                    }
                }
            }
        }
    }
    else{
        //Log::info(m_log_tag, LOGMSG("it->second.constFirst() : ").arg(it->second.constFirst()));
        if(!it->second.isEmpty()){
            if(it->second.constFirst() != "not found"){
                return it->second;
            }
        }
    }
    return empty_list;
}

const QString& Assets::getFirst(AssetType key) {

    //*******for test purpose only*******
    //const auto it_log = ASSET_DIRS.find(key);
    //Log::info(m_log_tag, LOGMSG("get-first - it_log->second : %1").arg(it_log->second.join(",")));
    //***********************************

    static const QString empty;
    const QStringList& list = get(key, true);
    if (!list.isEmpty()){
        if(list.constFirst() != "not found"){
            return list.constFirst();
        }
        else return empty;
    }
    else return empty;
}

Assets& Assets::add_file(AssetType key, QString path)
{
    QString uri = QUrl::fromLocalFile(std::move(path)).toString();
    return add_uri(key, std::move(uri));
}

Assets& Assets::add_uri(AssetType key, QString url)
{
    QStringList& target = m_asset_lists[key];

    if (!url.isEmpty() && !target.contains(url))
        target.append(std::move(url));

    return *this;
}

Assets& Assets::setGame(model::Game* game)
{
    //finally, only one is set to go quicker
    m_game = std::move(game);
    return *this;
}

size_t Assets::find_asset_for_game(AssetType key, bool searchFirstOnly)
{
    //*******for test purpose only*******
    //const auto it_log = ASSET_DIRS.find(key);
    //Log::info(m_log_tag, LOGMSG("find_asset_for_game it->second : %1").arg(it_log->second.join(",")));
    //***********************************

    //if not asset for game, exit immediatly
    if(!m_game) return 0;

    //Log::info(m_log_tag, LOGMSG("Start to search all asset of the same type for one game"));
    size_t found_assets_cnt = 0;

    constexpr auto DIR_FILTERS = QDir::Files | QDir::Readable | QDir::NoDotAndDotDot;
    //constexpr auto DIR_FLAGS = QDirIterator::Subdirectories | QDirIterator::FollowSymlinks;

    //to search media directory in the same dir than game
    const model::GameFile* const gamefile = m_game->filesConst().constFirst();
    QString gameAbsolutePath = gamefile->fileinfo().absoluteDir().absolutePath();
    //Log::info(m_log_tag, LOGMSG("'%1' is gameAbsolutePath !").arg(gameAbsolutePath));
    const QString gameRelativePath = gameAbsolutePath.replace("/recalbox/share/roms/" % m_game->systemShortName(),"");
    //Log::info(m_log_tag, LOGMSG("'%1' is gameRelativePath !").arg(gameRelativePath));
    QString search_file = gamefile->fileinfo().completeBaseName() % ".*";
    //need to replace [ and ] by ? because file filetring doesn't work wwith [ or ]
    search_file.replace("[","?");
    search_file.replace("]","?");
    //Log::info(m_log_tag, LOGMSG("%1 is the file to search !").arg(search_file));
    //Log::debug(m_log_tag, LOGMSG("Nb elements in MEDIA_DIRS : %1").arg(QString::number(MEDIA_DIRS.size())));
    for (const QString& media_dir_subpath : MEDIA_DIRS) {
        //check if this type of asset exists else continue
        const auto it = ASSET_DIRS.find(key);
        if (it == ASSET_DIRS.cend()){
            continue;
        }
        //get list of directory for this asset type
        const QStringList& dir_names = ASSET_DIRS.find(key)->second;
        //search in all directories for this asset
        for (const QString& dir_name : dir_names) {
            const QString search_dir = "/recalbox/share/roms/" % m_game->systemShortName() % media_dir_subpath % dir_name % gameRelativePath;
            //Log::info(m_log_tag, LOGMSG("%1 is the directory where to search for %2 !").arg(search_dir,search_file));
            QDirIterator mediaFileIt(search_dir, { search_file }, DIR_FILTERS); //, DIR_FLAGS);
            if(mediaFileIt.hasNext()){
                do{
                    mediaFileIt.next();
                    add_file(key, mediaFileIt.filePath());
                    //Log::info(m_log_tag, LOGMSG("media found dynamically: %1").arg(mediaFileIt.filePath()));
                    found_assets_cnt++;
                    //exit immediately if first only requested
                    if(searchFirstOnly) return found_assets_cnt;
                }while (mediaFileIt.hasNext());
            }

        }
    }
    Log::info(m_log_tag, LOGMSG("%1 assets found dynamically").arg(QString::number(found_assets_cnt)));
    //set to not found from here to avoid to redo the scan later
    if(found_assets_cnt == 0) add_uri(key, "not found");
    return found_assets_cnt;
}

} // namespace model

