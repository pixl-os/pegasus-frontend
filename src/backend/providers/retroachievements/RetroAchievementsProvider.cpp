// Pegasus Frontend
//
// Created by BozoTheGeek 20/03/2023
//


#include "RetroAchievementsProvider.h"

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
namespace retroAchievements {

RetroAchievementsProvider::RetroAchievementsProvider(QObject* parent)
    : Provider(QLatin1String("retroAchievements"), QStringLiteral("RetroAchievements provider"), parent)
{}

Provider& RetroAchievementsProvider::run(SearchContext& sctx)
{
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

    const std::array<QString, 2> MEDIA_DIRS {
        QStringLiteral("/skraper/"),
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
