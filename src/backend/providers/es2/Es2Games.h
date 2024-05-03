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

#include <QDir>
#include <QString>
#include <vector>

namespace model { class Game; }
namespace providers { class SearchContext; }
namespace providers { namespace es2 { struct SystemEntry; } }


namespace providers {
namespace es2 {

size_t find_games_for(const SystemEntry&, const QDir&, SearchContext&);
size_t create_collection_for(const SystemEntry&, SearchContext&);
size_t find_system_videos_for(const SystemEntry&, SearchContext&);

} // namespace es2
} // namespace providers
