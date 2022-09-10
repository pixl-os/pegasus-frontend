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


#include "GameFile.h"

#include "model/gaming/Game.h"


namespace model {
QString pretty_filename(const QFileInfo& fi)
{
    return fi.completeBaseName()
        .replace(QLatin1Char('_'), QLatin1Char(' '))
        .replace(QLatin1Char('.'), QLatin1Char(' '));
}


GameFileData::GameFileData(QFileInfo fi)
    : fileinfo(std::move(fi))
    , name(pretty_filename(fileinfo))
{}

GameFileData::GameFileData(QFileInfo fi, QString new_name)
    : fileinfo(std::move(fi))
    , name(std::move(new_name))
{}

bool GameFileData::operator==(const GameFileData& other) const {
    return fileinfo == other.fileinfo;
}


GameFile::GameFile(QFileInfo finfo, model::Game& parent)
    : QObject(&parent)
    , m_data(std::move(finfo))
{}

model::Game* GameFile::parentGame() const
{
    return static_cast<model::Game*>(parent());
}

void GameFile::launch()
{
	//reset netplay data in all cases to avoid issue
	m_data.netplay.mode = 0;
    m_data.netplay.emulator = "";
    m_data.netplay.core = "";
    m_data.netplay.port = "";
    m_data.netplay.ip = "";
    m_data.netplay.playerpassword = "";
    m_data.netplay.viewerpassword = "";
    m_data.netplay.vieweronly = false;
    m_data.netplay.hash = "";
	
    emit launchRequested();
}

void GameFile::launchNetplay(const int mode, const QString& port, const QString& ip, const QString& playerpassword, const QString& viewerpassword, const bool vieweronly, const QString& hash, const QString& emulator, const QString& core)
{
    m_data.netplay.mode = mode;
    m_data.netplay.emulator = emulator;
    m_data.netplay.core = core;
    m_data.netplay.port = port;
    m_data.netplay.ip = ip;
    m_data.netplay.playerpassword = playerpassword;
    m_data.netplay.viewerpassword = viewerpassword;
    m_data.netplay.vieweronly = vieweronly;
    m_data.netplay.hash = hash;
	
    emit launchRequested();
}

void GameFile::update_playstats(int playcount, qint64 playtime, QDateTime last_played)
{
    m_data.playstats.last_played = std::max(m_data.playstats.last_played, std::move(last_played));
    m_data.playstats.play_time += playtime;
    m_data.playstats.play_count += playcount;
    emit playStatsChanged();
}

bool sort_gamefiles(const model::GameFile* const a, const model::GameFile* const b) {
    return QString::localeAwareCompare(a->name(), b->name()) < 0;
}
} // namespace model
