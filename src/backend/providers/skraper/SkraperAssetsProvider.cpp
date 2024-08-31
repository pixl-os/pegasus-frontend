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
// Update by Sebio 30/08/2024

#include "SkraperAssetsProvider.h"

#include "Log.h"
#include "model/gaming/Assets.h"
#include "model/gaming/Game.h"
#include "model/gaming/GameFile.h"
#include "providers/SearchContext.h"
#include "utils/PathTools.h"

#include <QDirIterator>
#include <QStringBuilder>
#include <array>


namespace {
HashMap<QString, model::Game*> build_gamepath_db(const HashMap<QString, model::GameFile*>& filepath_to_entry_map)
{
    HashMap<QString, model::Game*> map;

    // TODO: C++17
    for (const auto& entry : filepath_to_entry_map) {
        const QFileInfo finfo(entry.first);
        QString path = ::clean_abs_dir(finfo) % '/' % finfo.completeBaseName();
        map.emplace(std::move(path), entry.second->parentGame());
    }

    return map;
}
} // namespace


namespace providers {
namespace skraper {

SkraperAssetsProvider::SkraperAssetsProvider(QObject* parent)
    : Provider(QLatin1String("skraper"), QStringLiteral("Skraper Assets"), parent)
{}

Provider& SkraperAssetsProvider::run(SearchContext& sctx)
{
    // NOTE: The entries are ordered by priority
    const HashMap<AssetType, QStringList, EnumHash> ASSET_DIRS {
        // multi posibility
        { AssetType::ARCADE_MARQUEE, {
            QStringLiteral("marquee"),
            QStringLiteral("screenmarquee"),
            QStringLiteral("screenmarqueesmall"),
            QStringLiteral("steamgrid"),
        }},
        { AssetType::BACKGROUND, {
            QStringLiteral("fanart"),
            QStringLiteral("screenshot"),
            QStringLiteral("image"),
            QStringLiteral("images"),
        }},
        { AssetType::BOX_FRONT, {
            QStringLiteral("box3d"),
            QStringLiteral("support"),
            QStringLiteral("boxfront"),
            QStringLiteral("boxFront"),
            QStringLiteral("box2dfront"),
            QStringLiteral("supporttexture"),
            QStringLiteral("thumbnail"),
        }},
        { AssetType::LOGO, {
            QStringLiteral("wheel"),
            QStringLiteral("wheelcarbon"),
            QStringLiteral("wheelsteel"),
        }},
        { AssetType::SCREENSHOT, {
            QStringLiteral("screenshot"),
            QStringLiteral("screenshottitle"),
            QStringLiteral("image"),
            QStringLiteral("images"),
        }},
        { AssetType::FULLMEDIA, {         
            QStringLiteral("mix"),
            QStringLiteral("fanart"),
            QStringLiteral("screenshot"),
            QStringLiteral("screenshottitle"),
            QStringLiteral("image"),
            QStringLiteral("images"),
            QStringLiteral("thumbnail"),
            QStringLiteral("extra1"),
            QStringLiteral("box3d"),
            QStringLiteral("boxfront"),
            QStringLiteral("boxFront"),
            QStringLiteral("box2dfront"),
            QStringLiteral("support"),
            QStringLiteral("supporttexture"),
            QStringLiteral("boxback"),
            QStringLiteral("boxBack"),
            QStringLiteral("box2dback"),
            QStringLiteral("boxfull"),
            QStringLiteral("boxFull"),
            QStringLiteral("boxtexture"),
        }},

        // solo posibility
        // for tag <bezels></bezels>
        { AssetType::ARCADE_BEZEL, {
            QStringLiteral("bezel"), // specific with arrm
            QStringLiteral("bezels"), // specific with arrm
        }},
        // for tag <box2dback></box2dback>
        { AssetType::BOX_BACK, {
            QStringLiteral("boxback"),
            QStringLiteral("boxBack"),
            QStringLiteral("box2dback"),
        }},
        // for tag <box2dfront></box2dfront>
        { AssetType::BOX_2DFRONT, {    
            QStringLiteral("boxfront"),
            QStringLiteral("boxFront"),
            QStringLiteral("box2dfront"),
        }},
        // for tag <box2dside></box2dside>
        { AssetType::BOX_SPINE, {
            QStringLiteral("boxside"),
            QStringLiteral("boxSide"),
            QStringLiteral("box2dside"),
        }},
        // for tag <box3d></box3d>
        { AssetType::BOX_3DFRONT, {
            QStringLiteral("box3d"),
        }},
        // for tag <boxtexture></boxtexture>
        { AssetType::BOX_FULL, {
            QStringLiteral("boxfull"),
            QStringLiteral("boxFull"),
            QStringLiteral("boxtexture"),
        }},
        // for tag <extra1></extra1>
        { AssetType::EXTRA1, {
            QStringLiteral("extra1"), // flyer specific with arrm
        }},
        // for tag <fanart></fanart>
        { AssetType::FANART, {
            QStringLiteral("fanart"),
        }},
        // for tag <images></images>
        { AssetType::IMAGES, {
            QStringLiteral("image"),
            QStringLiteral("images"),
        }},
        // for tag <manuals></manuals>
        { AssetType::MANUAL, {
            QStringLiteral("manual"),
            QStringLiteral("manuals"),
        }},
        // for tag <map></map>
        { AssetType::MAPS, {
            QStringLiteral("map"),
            QStringLiteral("maps"),            
        }},
        // for tag <marquee></marquee>
        { AssetType::MARQUEE, {
            QStringLiteral("marquee"),
        }},
        // for tag <mix></mix>
        { AssetType::MIX, {
            QStringLiteral("mix"), // specific with arrm
        }},
        // for tag <music></music>
        { AssetType::MUSIC, {
            QStringLiteral("music"), // specific with arrm
        }},
        // for tag <screenmarquee></screenmarquee>
        { AssetType::SCREEN_MARQUEE, {  
            QStringLiteral("screenmarquee"),
        }},
        // for tag <screenmarqueesmall></screenmarqueesmall>
        { AssetType::SCREEN_MARQUEESMALL, {      
            QStringLiteral("screenmarqueesmall"),
        }},
        // for tag <screenshot></screenshot>
        { AssetType::SCREENSHOT_BIS, {
            QStringLiteral("screenshot"),
        }},
        // for tag <screenshottitle></screenshottitle>
        { AssetType::TITLESCREEN, {
            QStringLiteral("screenshottitle"),
        }},
        // for tag <steamgrid></steamgrid>
        { AssetType::UI_STEAMGRID, {
            QStringLiteral("steamgrid"),
        }},
        // for tag <support></support>
        { AssetType::CARTRIDGE, {
            QStringLiteral("support"),
        }},
        // for tag <supporttexture></supporttexture>
        { AssetType::CARTRIDGETEXTURE, {
            QStringLiteral("supporttexture"),
        }},
        // for tag <thumbnail></thumbnail>
        { AssetType::THUMBNAIL, {
            QStringLiteral("thumbnail"),
        }},
        // for tag <videos></videos>
        { AssetType::VIDEO, {
            QStringLiteral("video"),
            QStringLiteral("videos"),
        }},
        // for tag <videomix></videomix>
        { AssetType::VIDEOMIX, {
            QStringLiteral("videomix"), // specific with arrm
        }},
        // for tag <wheel></wheel>
        { AssetType::WHEEL, {
            QStringLiteral("wheel"),
        }},
        // for tag <wheelcarbon></wheelcarbon>
        { AssetType::WHEEL_CARBON, {
            QStringLiteral("wheelcarbon"),
        }},
        // for tag <wheelsteel></wheelsteel>
        { AssetType::WHEEL_STEEL, {         
            QStringLiteral("wheelsteel"),
        }},
    };

    const std::array<QString, 1> MEDIA_DIRS {
        QStringLiteral("/media/"),
    };

    constexpr auto DIR_FILTERS = QDir::Files | QDir::Readable | QDir::NoDotAndDotDot;
    constexpr auto DIR_FLAGS = QDirIterator::Subdirectories | QDirIterator::FollowSymlinks;


    const HashMap<QString, model::Game*> extless_path_to_game = build_gamepath_db(sctx.current_filepath_to_entry_map());

    size_t found_assets_cnt = 0;
    for (const QString& root_dir : sctx.pegasus_game_dirs()) {
        for (const QString& media_dir_subpath : MEDIA_DIRS) {
            const QString game_media_dir = root_dir % media_dir_subpath;
            if (!QFileInfo::exists(game_media_dir))
                continue;

            // TODO: C++17
            for (const auto& asset_dir_entry : ASSET_DIRS) {
                const AssetType asset_type = asset_dir_entry.first;
                const QStringList& dir_names = asset_dir_entry.second;
                for (const QString& dir_name : dir_names) {
                    const QString search_dir = game_media_dir % dir_name;
                    const int subpath_len = media_dir_subpath.length() + dir_name.length();

                    QDirIterator dir_it(search_dir, DIR_FILTERS, DIR_FLAGS);
                    while (dir_it.hasNext()) {
                        dir_it.next();
                        const QFileInfo finfo = dir_it.fileInfo();

                        const QString game_path = ::clean_abs_dir(finfo).remove(root_dir.length(), subpath_len)
                                                % '/' % finfo.completeBaseName();
                        const auto it = extless_path_to_game.find(game_path);
                        if (it == extless_path_to_game.cend())
                            continue;

                        model::Game& game = *(it->second);
                        game.assetsMut().add_file(asset_type, dir_it.filePath());
                        found_assets_cnt++;
                    }
                }
            }
        }
    }

    Log::info(display_name(), LOGMSG("%1 assets found").arg(QString::number(found_assets_cnt)));
    return *this;
}

} // namespace skraper
} // namespace providers
