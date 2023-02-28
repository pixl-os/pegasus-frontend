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


#include "SearchContext.h"

#include "AppSettings.h"
#include "Log.h"
#include "model/gaming/Collection.h"
#include "model/gaming/Game.h"
#include "model/gaming/GameFile.h"
#include "utils/DiskCachedNAM.h"
#include "utils/PathTools.h"
#include "utils/StdHelpers.h"

#include <QFileInfo>
#include <QNetworkAccessManager>
#include <QNetworkReply>
#include <QNetworkRequest>
#include <QSslSocket>

#include <QElapsedTimer>

#include <QtConcurrent/QtConcurrent>

namespace {
QStringList read_game_dirs()
{
    QStringList game_dirs;

    AppSettings::parse_gamedirs([&game_dirs](const QString& line){
        const QFileInfo finfo(line);
        if (finfo.isDir())
            game_dirs.append(::clean_abs_path(finfo));
    });

    game_dirs.removeDuplicates();
    return game_dirs;
}
} // namespace


namespace providers {
SearchContext::SearchContext(QObject* parent)
    : SearchContext(read_game_dirs(), parent)
{}

SearchContext::SearchContext(QStringList game_dirs, QObject* parent)
    : QObject(parent)
    , m_root_game_dirs(std::move(game_dirs))
    , m_netman(nullptr)
    , m_pending_downloads(0)
{}

SearchContext& SearchContext::pegasus_add_game_dir(QString path)
{
    m_pegasus_game_dirs.append(std::move(path));
    m_pegasus_game_dirs.removeDuplicates();  // TODO: optimize?
    return *this;
}

model::Collection* SearchContext::get_or_create_collection(const QString& name)
{
    const auto it = m_collections.find(name);
    if (it != m_collections.cend())
        return it->second;

    auto* const new_ptr = new model::Collection(name);
    m_collections.emplace(name, new_ptr);
    return new_ptr;
}

model::Game* SearchContext::create_game_for(model::Collection& collection)
{
    auto* const game_ptr = new model::Game();

    //set collection during creation now
    //(*game_ptr).setCollection(&collection);

	//tentative to reduce quantity of data recopied by games to improve performance during loading of games and memory usage
    /*(*game_ptr)
        .setLaunchCmd(collection.commonLaunchCmd())
        .setLaunchWorkdir(collection.commonLaunchWorkdir())
        .setLaunchCmdBasedir(collection.commonLaunchCmdBasedir())
        .setSystemShortname(collection.shortName());


    //for to take into account priority=1 (or lower value) as default emulator and core
    int first_priority = 0;
    for (int n = 0;n < collection.commonEmulators().count(); n++)
    {
        //if only one or to initialize with one value
        if (n == 0)
        {   first_priority = collection.commonEmulators()[n].priority; 
            (*game_ptr).setEmulatorName(collection.commonEmulators()[n].name);
            (*game_ptr).setEmulatorCore(collection.commonEmulators()[n].core); 
        }
        else if(first_priority > collection.commonEmulators()[n].priority) //else we check if previous priority is lower (but number is higher ;-)
        {
            first_priority = collection.commonEmulators()[n].priority;
            (*game_ptr).setEmulatorName(collection.commonEmulators()[n].name);
            (*game_ptr).setEmulatorCore(collection.commonEmulators()[n].core);
        }
    }*/

    m_collection_games[&collection].emplace_back(game_ptr);

    return game_ptr;
}

model::Game* SearchContext::create_game()
{
    auto* const game_ptr = new model::Game();
    m_parentless_games.emplace_back(game_ptr);
    return game_ptr;
}

model::Game* SearchContext::game_by_filepath(const QString& can_path) const
{
    model::GameFile* const entry_ptr = gamefile_by_filepath(can_path);
    return entry_ptr
        ? entry_ptr->parentGame()
        : nullptr;
}

model::Game* SearchContext::game_by_uri(const QString& uri) const
{
    model::GameFile* const entry_ptr = gamefile_by_uri(uri);
    return entry_ptr
        ? entry_ptr->parentGame()
        : nullptr;
}

model::GameFile* SearchContext::gamefile_by_filepath(const QString& can_path) const
{
    const auto it = m_filepath_to_gamefile.find(can_path);
    return it != m_filepath_to_gamefile.cend()
        ? it->second
        : nullptr;
}

model::GameFile* SearchContext::gamefile_by_uri(const QString& uri) const
{
    const auto it = m_uri_to_gamefile.find(uri);
    return it != m_uri_to_gamefile.cend()
        ? it->second
        : nullptr;
}

model::GameFile* SearchContext::game_add_filepath(model::Game& game, QString can_path)
{
    model::GameFile* const registered_ptr = gamefile_by_filepath(can_path);
    if (registered_ptr)
        return registered_ptr;

    auto* const entry_ptr = new model::GameFile(can_path, game);
    m_game_entries[&game].emplace_back(entry_ptr);
    m_filepath_to_gamefile.emplace(can_path, entry_ptr);

    if (game.title().isEmpty()) {
        game.setTitle(entry_ptr->name())
            .setSortBy(entry_ptr->name());
    }

    return entry_ptr;
}

model::GameFile* SearchContext::game_add_uri(model::Game& game, QString uri)
{
    model::GameFile* const registered_ptr = gamefile_by_uri(uri);
    if (registered_ptr)
        return registered_ptr;

    auto* const entry_ptr = new model::GameFile(uri, game);
    m_game_entries[&game].emplace_back(entry_ptr);
    m_uri_to_gamefile.emplace(uri, entry_ptr);
    return entry_ptr;
}

SearchContext& SearchContext::game_add_to(model::Game& game, model::Collection& collection)
{
    m_collection_games[&collection].emplace_back(&game);
    VEC_REMOVE_VALUE(m_parentless_games, &game);

    if (game.launchCmd().isEmpty())
        game.setLaunchCmd(collection.commonLaunchCmd());
    if (game.launchWorkdir().isEmpty())
        game.setLaunchWorkdir(collection.commonLaunchWorkdir());
    if (game.launchCmdBasedir().isEmpty())
        game.setLaunchCmdBasedir(collection.commonLaunchCmdBasedir());
    if (game.systemShortName().isEmpty())
        game.setSystemShortname(collection.shortName());
    if (game.emulatorName().isEmpty() || game.emulatorCore().isEmpty())
    {
        //for to take into account priority=1 as default emulator and core
        int first_priority = 0;
        for (int n = 0;n < collection.commonEmulators().count(); n++)
        {
            //if only one or to initialize with one value
            if (n == 0)
            {   
                first_priority = collection.commonEmulators()[n].priority;  
                game.setEmulatorName(collection.commonEmulators()[n].name);
                game.setEmulatorCore(collection.commonEmulators()[n].core); 
            }
            else if(first_priority > collection.commonEmulators()[n].priority) //else we check if previous priority is lower (but number is higher ;-)
            {
                first_priority = collection.commonEmulators()[n].priority; 
                game.setEmulatorName(collection.commonEmulators()[n].name);
                game.setEmulatorCore(collection.commonEmulators()[n].core);
            }
        }
    }
        
    return *this;
}

void SearchContext::finalize_cleanup_games()
{
    // remove parentless games
    for (model::Game* const game_ptr : m_parentless_games) {
        Log::warning(LOGMSG("The game '%1' does not belong to any collections, ignored").arg(game_ptr->title()));
        m_game_entries.erase(game_ptr);
        delete game_ptr;
    }

    // Remove entryless games
    for (auto& pair : m_collection_games) {
        std::vector<model::Game*>& game_list = pair.second;
        VEC_REMOVE_IF(game_list, [this](model::Game* const ptr){ return m_game_entries.count(ptr) == 0; });
    }

    // Remove empty game lists
    std::vector<model::Collection*> empty_list_keys;
    empty_list_keys.reserve(m_collection_games.size());
    for (auto& pair : m_collection_games) {
        if (pair.second.empty())
            empty_list_keys.push_back(pair.first);
    }
    for (model::Collection* const key : empty_list_keys)
        m_collection_games.erase(key);
}

void SearchContext::finalize_cleanup_collections()
{
    std::vector<model::Collection*> deleted_collections;

    // Find gameless collections
    for (const auto& pair : m_collections) {
        model::Collection* const coll_ptr = pair.second;

        const auto game_list_it = m_collection_games.find(coll_ptr);
        if (game_list_it != m_collection_games.cend())
            continue;

        Log::warning(LOGMSG("The collection '%1' has no valid games, ignored").arg(pair.first));
        deleted_collections.emplace_back(coll_ptr);
    }

    // Remove invalid collections
    for (model::Collection* const coll_ptr : deleted_collections) {
        m_collections.erase(coll_ptr->name());
        delete coll_ptr;
    }
}

void SearchContext::finalize_apply_lists()
{
    //QElapsedTimer finalize_apply_lists_timer;
    //finalize_apply_lists_timer.start();
	
    // Apply game entries (set files to game)
	// using this global one: HashMap<model::Game*, std::vector<model::GameFile*>> m_game_entries;
    for (auto& pair : m_game_entries) {
        Q_ASSERT(!pair.second.empty());
        pair.first->setFiles(std::move(pair.second));
    }
    //Log::info(LOGMSG("Game list post-processing took %1ms (+ including pair.first->setFiles(std::move(pair.second));)").arg(finalize_apply_lists_timer.elapsed()));


    // Apply collections to games using the following HashMap
    HashMap<model::Game*, std::vector<model::Collection*>> game_collections;
    for (const auto& pair : m_collection_games) {
        for (model::Game* const game_ptr : pair.second)
            game_collections[game_ptr].emplace_back(pair.first);
    }
    //Log::info(LOGMSG("Game list post-processing took %1ms (+ including game_collections[game_ptr].emplace_back(pair.first);)").arg(finalize_apply_lists_timer.elapsed()));

    for (auto& pair : game_collections) {
        VEC_REMOVE_DUPLICATES(pair.second);
        pair.first->setCollections(std::move(pair.second));
    }
    //Log::info(LOGMSG("Game list post-processing took %1ms (+ including pair.first->setCollections(std::move(pair.second));)").arg(finalize_apply_lists_timer.elapsed()));

    // Apply games to collections
    for (auto& pair : m_collection_games) {
        VEC_REMOVE_DUPLICATES(pair.second);
        pair.first->setGames(std::move(pair.second));
    }
    //Log::info(LOGMSG("Game list post-processing took %1ms (+ including pair.first->setGames(std::move(pair.second));)").arg(finalize_apply_lists_timer.elapsed()));

}

std::pair<QVector<model::Collection*>, QVector<model::Game*>> SearchContext::finalize(QObject* const qparent)
{
    // TODO: C++17
    //QElapsedTimer internal_finalize_timer;
    //internal_finalize_timer.start();

    finalize_cleanup_games();
    //Log::info(LOGMSG("Stats - Game list post-processing took %1ms (+ including finalize_cleanup_games())").arg(internal_finalize_timer.elapsed()));

    finalize_cleanup_collections();
    //Log::info(LOGMSG("Stats - Game list post-processing took %1ms (+ including finalize_cleanup_collections())").arg(internal_finalize_timer.elapsed()));

    finalize_apply_lists();
    //Log::info(LOGMSG("Stats - Game list post-processing took %1ms (+ including finalize_apply_lists())").arg(internal_finalize_timer.elapsed()));


    QVector<model::Game*> games;
    games.reserve(m_game_entries.size());

    for (const auto& pair : m_game_entries) {
        model::Game& game = *pair.first;

        game.developerList().removeDuplicates();
        game.publisherList().removeDuplicates();
        game.genreList().removeDuplicates();
        game.tagList().removeDuplicates();

        game.moveToThread(qparent->thread());
        game.setParent(qparent);

        games.append(pair.first);
    }
    //Log::info(LOGMSG("Stats - Game list post-processing took %1ms (+ including for (const auto& pair : m_game_entries) )").arg(internal_finalize_timer.elapsed()));



    QVector<model::Collection*> collections;
    collections.reserve(m_collections.size());

    for (auto& pair : m_collections) {
        model::Collection& collection = *pair.second;

        collection.moveToThread(qparent->thread());
        collection.setParent(qparent);

        collections.append(pair.second);
    }
    //Log::info(LOGMSG("Stats - Game list post-processing took %1ms (+ including for (auto& pair : m_collections) )").arg(internal_finalize_timer.elapsed()));


    std::sort(collections.begin(), collections.end(), model::sort_collections);
    //Log::info(LOGMSG("Stats - Game list post-processing took %1ms (+ including collections sorting)").arg(internal_finalize_timer.elapsed()));

    std::sort(games.begin(), games.end(), model::sort_games);
    //Log::info(LOGMSG("Stats - Game list post-processing took %1ms (+ including games sorting)").arg(internal_finalize_timer.elapsed()));


    return std::make_pair(std::move(collections), std::move(games));
}


SearchContext& SearchContext::enable_network()
{
    Q_ASSERT(!m_netman);

    if (!QSslSocket::supportsSsl()) {
        Log::warning(LOGMSG("Secure connection (SSL) support not available, downloading metadata is not possible"));
        return *this;
    }

    // TODO: C++14
    m_netman = utils::create_disc_cached_nam(this);
    return *this;
}

bool SearchContext::has_network() const
{
    return !!m_netman;
}

bool SearchContext::has_pending_downloads() const
{
    return m_pending_downloads > 0;
}

SearchContext& SearchContext::schedule_download(
    const QUrl& url,
    const std::function<void(QNetworkReply* const)>& on_finish_callback)
{
    Q_ASSERT(m_netman);
    Q_ASSERT(url.isValid());

    m_pending_downloads++;

    QNetworkRequest request(url);
    request.setAttribute(QNetworkRequest::FollowRedirectsAttribute, true);
#if (QT_VERSION >= QT_VERSION_CHECK(5, 15, 0))
    request.setTransferTimeout(10000);
#endif

    QNetworkReply* const reply = m_netman->get(request);
	Log::debug(LOGMSG("emit downloadScheduled();"));
    //emit downloadScheduled();

	QObject::connect(reply, &QNetworkReply::finished, [=]() {
		if(reply->error() == QNetworkReply::NoError)
		{
			QByteArray response = reply->readAll();
			// do something with the data...
			Log::debug(LOGMSG("response searchcontext = %1").arg(QString::fromStdString(response.toStdString())));
		}
		else // handle error
		{
	      Log::debug(LOGMSG("ERROR"));
		}
		//emit downloadCompleted();
	});



    // QObject::connect(reply, &QNetworkReply::finished,
        // this, [this, reply, on_finish_callback]{
 			// Log::debug(LOGMSG("on_finish_callback(reply);"));
			// on_finish_callback(reply);
            // m_pending_downloads--;
			// Log::debug(LOGMSG("emit downloadCompleted();"));
            // emit downloadCompleted();
        // });
		
	Log::debug(LOGMSG("return *this;"));
    return *this;
}
} // namespace providers
