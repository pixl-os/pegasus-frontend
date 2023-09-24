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


#include "Game.h"

#include "providers/SearchContext.h"
#include "providers/retroachievements/RetroAchievementsMetadata.h"

#include "Log.h"

#include <QThread>
#include <QMetaObject>

#include <QtConcurrent/QtConcurrent>

//For recalbox
#include "RecalboxConf.h"


namespace {
QString joined_list(const QStringList& list) { return list.join(QLatin1String(", ")); }
} // namespace


namespace model {
GameData::GameData() = default;

GameData::GameData(QString new_title)
    : title(std::move(new_title))
    , sort_by(title)
{}


Game::Game(QString name, QObject* parent)
    : QObject(parent)
    , m_files(new QQmlObjectListModel<model::GameFile>(this))
    , m_data(std::move(name))
    , m_assets(new model::Assets(this))
{
    //set Game link in case of assets for game
    m_assets->setGame(this);
}

Game::Game(QObject* parent)
    : Game(QString(), parent)
{
}

QString Game::developerStr() const { return joined_list(m_data.developers); }
QString Game::publisherStr() const { return joined_list(m_data.publishers); }
QString Game::genreStr() const { return joined_list(m_data.genres); }
QString Game::tagStr() const { return joined_list(m_data.tags); }

Game& Game::setTitle(QString title)
{
    m_data.title = std::move(title);
    if (sortBy().isEmpty())
        setSortBy(m_data.title);
    return *this;
}

Game& Game::setFavorite(bool new_val)
{
    m_data.is_favorite = new_val;
    emit favoriteChanged();
    return *this;
}

const QString Game::getEmulatorName() const
{
    QString shortname = m_collections->get(0)->shortName();
    QString emulator = QString::fromStdString(RecalboxConf::Instance().AsString(shortname.append(".emulator").toUtf8().constData()));
    //TO DO: add also case when we search emulator if set by game
    if(emulator == "")
    {
        //to take into account priority=1 as default emulator and core
        int first_priority = 0;
        for (int n = 0;n < m_collections->commonEmulators().count(); n++)
        {
            //if only one or to initialize with one value
            if (n == 0)
            {
                first_priority = m_collections->commonEmulators()[n].priority;
                emulator = m_collections->commonEmulators()[n].name;
            }
            else if(first_priority > m_collections->commonEmulators()[n].priority) //else we check if previous priority is lower (but number is higher ;-)
            {
                first_priority = m_collections->commonEmulators()[n].priority;
                emulator = m_collections->commonEmulators()[n].name;
            }
        }
    }
    return emulator;
}

const QString Game::getEmulatorCore() const
{
    QString shortname = m_collections->get(0)->shortName();
    QString core = QString::fromStdString(RecalboxConf::Instance().AsString(shortname.append(".core").toUtf8().constData()));
    //TO DO: add also case when we search core if set by game
    if(core == "")
    {
        //to take into account priority=1 as default emulator and core
        int first_priority = 0;
        for (int n = 0;n < m_collections->commonEmulators().count(); n++)
        {
            //if only one or to initialize with one value
            if (n == 0)
            {
                first_priority = m_collections->commonEmulators()[n].priority;
                core = m_collections->commonEmulators()[n].core;
            }
            else if(first_priority > m_collections->commonEmulators()[n].priority) //else we check if previous priority is lower (but number is higher ;-)
            {
                first_priority = m_collections->commonEmulators()[n].priority;
                core = m_collections->commonEmulators()[n].core;
            }
        }
    }
    return core;
}

int Game::getRaGameID()
{
    //Log::debug(LOGMSG("Game::getRaGameID_slot() put in Qt::QueuedConnection"));
    QMetaObject::invokeMethod(this,"getRaGameID_slot", Qt::QueuedConnection);

    return 0;
}

void Game::getRaGameID_slot()
{
   //Log::debug(LOGMSG("Game::initRetroAchievements_slot()"));
    //Initialize Metahelper for each update and for each games for the moment
    QString log_tag = "Retroachievements";
    try{
    const providers::retroAchievements::Metadata metahelper(log_tag);
    //get GameID from cache and calculating the hash
    metahelper.fill_RaGameID_from_cache(*this, false);
    //emit signal to alert front-end about end of change
    emit raGameIDChanged();
    }
    catch ( const std::exception & Exp )
    {
        Log::error(log_tag, LOGMSG("Error: %1.\n").arg(Exp.what()));
    }
}

void Game::onEntryPlayStatsChanged()
{
    const auto prev_play_count = m_data.playstats.play_count;
    const auto prev_play_time = m_data.playstats.play_time;
    const auto prev_last_played = m_data.playstats.last_played;

    m_data.playstats.play_count = std::accumulate(filesConst().cbegin(), filesConst().cend(), 0,
        [](int sum, const model::GameFile* const gamefile){
            return sum + gamefile->playCount();
        });
    m_data.playstats.play_time = std::accumulate(filesConst().cbegin(), filesConst().cend(), 0,
        [](qint64 sum, const model::GameFile* const gamefile){
            return sum + gamefile->playTime();
        });
    m_data.playstats.last_played = std::accumulate(filesConst().cbegin(), filesConst().cend(), QDateTime(),
        [](const QDateTime& current_max, const model::GameFile* const gamefile){
            return std::max(current_max, gamefile->lastPlayed());
        });

    const bool changed = prev_play_count != m_data.playstats.play_count
        || prev_play_time != m_data.playstats.play_time
        || prev_last_played != m_data.playstats.last_played;
    if (changed)
        emit playStatsChanged();
}

void Game::launch()
{
    Q_ASSERT(m_files->count() > 0);
	
    if (m_files->count() == 1)
        m_files->first()->launch();
    else
        emit launchFileSelectorRequested();
}

void Game::launchNetplay(const int mode, const QString& port, const QString& ip, const QString& playerpassword, const QString& viewerpassword, const bool vieweronly, const QString& hash, const QString& emulator, const QString& core)
{
    Q_ASSERT(m_files->count() > 0);

	if (m_files->count() == 1)
        m_files->first()->launchNetplay(mode,port,ip,playerpassword,viewerpassword,vieweronly,hash,emulator,core);
    else
        emit launchFileSelectorRequested();
}

void Game::initRetroAchievements()
{
    //Log::debug(LOGMSG("Game::initRetroAchievements_slot() put in Qt::QueuedConnection"));
	QMetaObject::invokeMethod(this,"initRetroAchievements_slot", Qt::QueuedConnection);
}

void Game::initRetroAchievements_slot()
{
    //Log::debug(LOGMSG("Game::initRetroAchievements_slot()"));
	//Initialize Metahelper for each update and for each games for the moment
	QString log_tag = "Retroachievements";
    try{
	const providers::retroAchievements::Metadata metahelper(log_tag);
	//get all from network for the moment to have last information / one function called for the moment
	metahelper.fill_from_network_or_cache(*this, false);
	//emit signal to alert front-end about end of update
	emit retroAchievementsInitialized();
    }
    catch ( const std::exception & Exp ) 
    { 
        Log::error(log_tag, LOGMSG("Error: %1.\n").arg(Exp.what()));
    } 	
}

void Game::updateRetroAchievements()
{
    //Log::debug(LOGMSG("Game::updateRetroAchievements_slot() put in Qt::QueuedConnection"));
	QMetaObject::invokeMethod(this,"updateRetroAchievements_slot", Qt::QueuedConnection);
}

void Game::updateRetroAchievements_slot()
{
    //Log::debug(LOGMSG("Game::updateRetroAchievements_slot()"));
	//Initialize Metahelper for each update and for each games for the moment
	QString log_tag = "Retroachievements";
    try{
		const providers::retroAchievements::Metadata metahelper(log_tag);
		//get all from network for the moment to have last information / one function called for the moment
		metahelper.fill_from_network_or_cache(*this, true);	
		//emit signal to alert front-end about end of update
		emit retroAchievementsChanged();
    }
    catch ( const std::exception & Exp ) 
    { 
        Log::error(log_tag, LOGMSG("Error: %1.\n").arg(Exp.what()));
    }
}

Game& Game::cleanFiles()
{
    if(!m_files->isEmpty()){
        //remove link
        for (model::GameFile* const gamefile : this->filesConst()) {
            disconnect(gamefile, &model::GameFile::playStatsChanged,
                    this, &model::Game::onEntryPlayStatsChanged);
        }
        m_files->clear();
    }
    return *this;
}

Game& Game::setFiles(std::vector<model::GameFile*>&& files)
{
    for (model::GameFile* const gamefile : files) {
        connect(gamefile, &model::GameFile::playStatsChanged,
                this, &model::Game::onEntryPlayStatsChanged);
    }

    std::sort(files.begin(), files.end(), model::sort_gamefiles);

    QVector<model::GameFile*> modelvec;
    modelvec.reserve(files.size());
    std::move(files.begin(), files.end(), std::back_inserter(modelvec));

    m_files->append(std::move(modelvec));

    onEntryPlayStatsChanged();

    return *this;
}

Game& Game::setCollections(std::vector<model::Collection*>&& collections)
{
    //finally, only one is set to go quicker
    m_collections = std::move(collections.at(0));
    return *this;
}

bool sort_games(const model::Game* const a, const model::Game* const b) {
   return QString::localeAwareCompare(a->sortBy(), b->sortBy()) < 0;
}
} // namespace model
