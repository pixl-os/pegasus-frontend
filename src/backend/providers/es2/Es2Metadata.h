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

#pragma once

#include "utils/HashMap.h"
#include "types/AssetType.h"

#include <QString>
#include <QList>
#include <QRegularExpression>

namespace model { class Game; }
namespace model { class GameFile; }
namespace providers { class SearchContext; }
class QDir;
class QXmlStreamReader;

namespace providers {
namespace es2 {

struct SystemEntry;
enum class MetaType : unsigned char;

class Metadata {

struct lightgunGameData {
    lightgunGameData(QString name, QString roms, QString system)
        :name(name), roms(roms), system(system){}
    lightgunGameData(){}
    QString name;
    QString roms;
    QString system;
};

public:
    explicit Metadata(QString, std::vector<QString>);
    void find_metadata_for_system(const SystemEntry&, const QDir&, providers::SearchContext&) const;
    void prepare_lightgun_games_metadata();
    QString find_gamelist_xml(const std::vector<QString>& possible_config_dirs, const QDir& system_dir, const SystemEntry&) const;
    QString find_media_xml(const std::vector<QString>& possible_config_dirs, const QDir& system_dir, const SystemEntry&) const;

private:
    const QString m_log_tag;
    const std::vector<QString> m_config_dirs;
    const HashMap<QString, MetaType> m_key_types;
    const QString m_date_format;
    const QRegularExpression m_players_regex;
    const std::vector<std::pair<MetaType, AssetType>> m_asset_type_map;

    QList <lightgunGameData> m_lightgun_games;

    void process_gamelist_xml(const QDir&, QXmlStreamReader&, providers::SearchContext&, const SystemEntry&) const;
    HashMap<MetaType, QString, EnumHash> parse_gamelist_game_node(QXmlStreamReader&) const;
    void apply_metadata(model::GameFile&, const QDir&, HashMap<MetaType, QString, EnumHash>&, const SystemEntry&) const;
    void add_skraper_media_metadata(const QDir&, providers::SearchContext&, const SystemEntry&, bool generateMediaXML = false) const;
    void add_skraper_media_metadata_v2(const QDir&, providers::SearchContext&, const SystemEntry&, bool generateMediaXML = false) const;
    size_t import_media_from_xml(const QDir&, providers::SearchContext&, const SystemEntry&) const;
    size_t import_lightgun_games_from_xml(const QString&);
    bool isLightgunGames(model::Game*, const model::GameFile*, const SystemEntry&) const;
    bool compareLightgunGames(const lightgunGameData&, const lightgunGameData&) const;



};

} // namespace es2
} // namespace providers
