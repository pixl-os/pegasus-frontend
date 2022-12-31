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

const QStringList& Assets::get(AssetType key) {
    static const QStringList empty;

    const auto it = m_asset_lists.find(key);
    if (it != m_asset_lists.cend())
        return it->second;

    return empty;
}

const QString& Assets::getFirst(AssetType key) {
    static const QString empty;
    //if(m_game) Log::warning(m_log_tag, LOGMSG("Asset of Game: %1").arg(m_game->path()));
    const QStringList& list = get(key);
    if (!list.isEmpty()){
        //Log::info(m_log_tag, LOGMSG("!list.isEmpty() : %1").arg(list.constFirst()));
        if(list.constFirst() != "not found"){
            return list.constFirst();
        }
        else return empty;
    }
    //else return empty;
    else{
        //search if assets exists in share
        bool assetFound = find_asset_for_game(key);
        //Log::info(m_log_tag, LOGMSG("assetFilePathFound : %1").arg(assetFilePathFound));
        if(!assetFound){
            //Log::info(m_log_tag, LOGMSG("assetFilePathFound is empty"));
            //if not found, asset created as not found
            add_uri(key,"not found");
            return empty;
        }
        else{
            //getfirst one
            const QStringList& list2 = get(key);
            return list2.constFirst();
        }
    }
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

bool Assets::find_asset_for_game(AssetType key)
{
    //Log::debug(m_log_tag, LOGMSG("Start to search one asset for one game"));
    // NOTE: The entries are ordered by priority
    const HashMap<AssetType, QStringList, EnumHash> ASSET_DIRS {
        { AssetType::ARCADE_MARQUEE, {
            QStringLiteral("marquee"),
            QStringLiteral("screenmarquee"),
            QStringLiteral("screenmarqueesmall"),
            QStringLiteral("steamgrid"),
        }},
        { AssetType::ARCADE_BEZEL, {
            QStringLiteral("bezel"),
        }},
        { AssetType::BACKGROUND, {
            QStringLiteral("fanart"),
            QStringLiteral("screenshot"),
        }},
        { AssetType::BOX_BACK, {
            QStringLiteral("box2dback"),
        }},
        { AssetType::BOX_FRONT, {
            QStringLiteral("box3d"),
            QStringLiteral("support"),
            QStringLiteral("box2dfront"),
            QStringLiteral("supporttexture"),
        }},
        { AssetType::BOX_FULL, {
            QStringLiteral("boxtexture"),
        }},
        { AssetType::BOX_SPINE, {
            QStringLiteral("box2dside"),
        }},
        { AssetType::CARTRIDGE, {
            QStringLiteral("support"),
        }},
        { AssetType::CARTRIDGETEXTURE, {
            QStringLiteral("supporttexture"),
        }},
        { AssetType::LOGO, {
            QStringLiteral("wheel"),
            QStringLiteral("wheelcarbon"),
            QStringLiteral("wheelsteel"),
        }},
        { AssetType::SCREENSHOT, {
            QStringLiteral("screenshot"),
            QStringLiteral("screenshottitle"),
        }},
        { AssetType::TITLESCREEN, {
            QStringLiteral("screenshottitle"),
        }},
        { AssetType::UI_STEAMGRID, {
            QStringLiteral("steamgrid"),
        }},
        { AssetType::VIDEO, {
            QStringLiteral("videos"),
        }},
        { AssetType::MANUAL, {
            QStringLiteral("manuals"),
        }},
        { AssetType::MAPS, {
            QStringLiteral("maps"),
        }},
        { AssetType::MUSIC, {
            QStringLiteral("music"),
        }},
    };

    const std::array<QString, 1> MEDIA_DIRS {
        QStringLiteral("/media/"),
    };

    //Log::debug(m_log_tag, LOGMSG("Nb elements in extless_path_to_game : %1").arg(QString::number(extless_path_to_game.size())));

    //Log::debug(m_log_tag, LOGMSG("Nb elements in sctx.current_filepath_to_entry_map() : %1").arg(QString::number(sctx.current_filepath_to_entry_map().size())));
    //Log::debug(m_log_tag, LOGMSG("Nb elements in sctx.current_collection_to_entry_map() : %1").arg(QString::number(sctx.current_collection_to_entry_map().size())));

    size_t found_assets_cnt = 0;
    static const QString empty;

    //Open media.xml file to write it (we consider that media.xml deson't exist if we call this function
    /*QFile xmlFile(system_dir.path() + "/media.xml");
    if (!xmlFile.open(QFile::WriteOnly | QFile::Text ))
    {
        Log::debug(m_log_tag, LOGMSG("%1 already opened or there is another issue").arg(system_dir.path() + "/media.xml"));
        xmlFile.close();
    }
    QTextStream xmlContent(&xmlFile);
    QDomDocument document;
    //make the root element
    QDomElement root = document.createElement("mediaList");
    //add it to document
    document.appendChild(root);*/

    //Log::debug(m_log_tag, LOGMSG("Nb elements in MEDIA_DIRS : %1").arg(QString::number(MEDIA_DIRS.size())));
    for (const QString& media_dir_subpath : MEDIA_DIRS) {


        //Log::info(m_log_tag, LOGMSG("m_game->launchCmdBasedir() : %1").arg(m_game->launchCmdBasedir()));
        //Log::info(m_log_tag, LOGMSG("m_game->launchWorkdir() : %1").arg(m_game->launchWorkdir()));

        //const QString game_media_dir = m_game->launchCmdBasedir()   % media_dir_subpath;

        /*Log::info(m_log_tag, LOGMSG("game_media_dir : %1").arg(game_media_dir));
        if (!QFileInfo::exists(game_media_dir))
            {
            Log::debug(m_log_tag, LOGMSG("%1 directory not found :-(").arg(game_media_dir));
            continue;
            }*/

        //check if this type of asset exists else continue
        const auto it = ASSET_DIRS.find(key);
        if (it == ASSET_DIRS.cend())
            continue;

        //get list of directory for this asset type
        const QStringList& dir_names = ASSET_DIRS.find(key)->second;
        //searchh in all directories for this asset
        for (const QString& dir_name : dir_names) {
            for (const model::GameFile* const gamefile : m_game->filesConst()) {
                const QString search_dir = gamefile->fileinfo().absoluteDir().absolutePath() % media_dir_subpath % dir_name;
                //Log::info(m_log_tag, LOGMSG("%1 is the directory where to search !").arg(search_dir));
                const QString search_file = gamefile->fileinfo().completeBaseName() % ".*";
                //Log::info(m_log_tag, LOGMSG("%1 is the file to search !").arg(search_file));

                //const int subpath_len = media_dir_subpath.length() + dir_name.length();
                QDirIterator mediaFileIt(search_dir, { search_file }, QDir::Files);
                if(mediaFileIt.hasNext()){
                    do{
                        mediaFileIt.next();
                        add_file(key, mediaFileIt.filePath());
                        Log::info(m_log_tag, LOGMSG("%1 is the file found !").arg(mediaFileIt.filePath()));
                        found_assets_cnt++;
                    }while (mediaFileIt.hasNext());
                }
                //if(QFileInfo::exists("/tmp/" + componentName + ".json")){
                //    model::Game& game = *(it->second);
                //    game.assetsMut().add_file(asset_type, dir_it.filePath());
                //Log::debug(m_log_tag, LOGMSG("%1 asset added !").arg(dir_it.filePath()));
                //found_assets_cnt++;
            }
        }
    }
    Log::debug(m_log_tag, LOGMSG("%1 assets found").arg(QString::number(found_assets_cnt)));
    if(found_assets_cnt != 0){
        return true;
    }
    else{
        //return empty by default
        return false;
    }
}
} // namespace model

