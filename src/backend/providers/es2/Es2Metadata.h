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

public:
    explicit Metadata(QString, std::vector<QString>);
    void find_metadata_for_system(const SystemEntry&, providers::SearchContext&) const;
    void find_metadata_for_game(model::GameFile& gamefile, const QDir& xml_dir) const;
    QString find_gamelist_xml(const std::vector<QString>& possible_config_dirs, const QDir& system_dir, const QString& system_name) const;
    QString find_media_xml(const std::vector<QString>& possible_config_dirs, const QDir& system_dir, const QString& system_name) const;

private:
    const QString m_log_tag;
    const std::vector<QString> m_config_dirs;
    const HashMap<QString, MetaType> m_key_types;
    const QString m_date_format;
    const QRegularExpression m_players_regex;
    const std::vector<std::pair<MetaType, AssetType>> m_asset_type_map;

    void process_gamelist_xml(const QDir&, QXmlStreamReader&, providers::SearchContext&, const QString&) const;
    HashMap<MetaType, QString, EnumHash> parse_gamelist_game_node(QXmlStreamReader&) const;
    void apply_metadata(model::GameFile&, const QDir&, HashMap<MetaType, QString, EnumHash>&) const;
    void add_skraper_media_metadata(const QDir&, providers::SearchContext&, bool generateMediaXML = false) const;
    void import_media_from_xml(const QDir&, providers::SearchContext&) const;
};

} // namespace es2
} // namespace providers
