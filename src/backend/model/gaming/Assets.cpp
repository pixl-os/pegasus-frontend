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

#include <QUrl>

namespace model {

Assets::Assets(QObject* parent)
    : QObject(parent)
{}

const QStringList& Assets::get(AssetType key) const {
    static const QStringList empty;

    const auto it = m_asset_lists.find(key);
    if (it != m_asset_lists.cend())
        return it->second;

    return empty;
}

const QString& Assets::getFirst(AssetType key) const {
    static const QString empty;
    //if(m_game) Log::warning(m_log_tag, LOGMSG("Asset of Game: %1").arg(m_game->path()));
    const QStringList& list = get(key);
    if (!list.isEmpty())
        return list.constFirst();

    return empty;
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

} // namespace model

