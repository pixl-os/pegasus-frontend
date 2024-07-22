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


#pragma once

#include "QtQmlTricks/QQmlObjectListModel.h"
#include <QDateTime>
#include <QStringList>

//add here to access Assets/Collection/GameFile information from Game class also
#include "model/gaming/Assets.h"
#include "model/gaming/Collection.h"
#include "model/gaming/GameFile.h"

//add here to access Metadata for retroAchievements for game
#include "providers/retroachievements/RetroAchievementsMetadata.h"

namespace model { class Assets; }
namespace model { class GameFile; }
namespace model { class Collection; }


namespace model {
	
struct RetroAchievement {
		int ID;
		QString Title;
		QString Description;
		int Points;
		QString Author;
		QString BadgeName;
		int Flags;
		bool Unlocked;
		bool HardcoreMode;
};		
	
struct GameData {
    explicit GameData();
    explicit GameData(QString);

    QString title;
    QString sort_by;
    QString summary;
    QString description;
    QString hash;
    QString md5;
	QString path;
	QString genreid;

    QStringList developers;
    QStringList publishers;
    QStringList genres;
    QStringList tags;

    short player_count = 1;
    float rating = 0.0;
    QDate release_date;

    struct PlayStats {
        int play_count = 0;
        int play_time = 0;
        QDateTime last_played;
    } playstats;

    bool is_favorite = false;
    bool is_lightgun_game = false;

    QList <RetroAchievement> retro_achievements;
    int ra_game_id = 0;
    QString ra_hash = 0;
};


class Game : public QObject {
    Q_OBJECT

public:
#define GETTER(type, name, field) \
    type name() const { return field; }

    GETTER(const QString&, title, m_data.title)
    GETTER(const QString&, sortBy, m_data.sort_by)
    GETTER(const QString&, summary, m_data.summary)
    GETTER(const QString&, description, m_data.description)
    GETTER(const QString&, hash, m_data.hash)
    GETTER(const QString&, md5, m_data.md5)
    GETTER(const QString&, path, m_data.path)
    GETTER(const QString&, genreid, m_data.genreid)
    GETTER(const QDate&, releaseDate, m_data.release_date)
    GETTER(int, playerCount, m_data.player_count)
    GETTER(float, rating, m_data.rating)

    GETTER(const QStringList&, developerListConst, m_data.developers)
    GETTER(const QStringList&, publisherListConst, m_data.publishers)
    GETTER(const QStringList&, genreListConst, m_data.genres)
    GETTER(const QStringList&, tagListConst, m_data.tags)

    GETTER(int, releaseYear, m_data.release_date.year())
    GETTER(int, releaseMonth, m_data.release_date.month())
    GETTER(int, releaseDay, m_data.release_date.day())

    GETTER(int, playCount, m_data.playstats.play_count)
    GETTER(int, playTime, m_data.playstats.play_time)
    GETTER(const QDateTime&, lastPlayed, m_data.playstats.last_played)
    GETTER(bool, isFavorite, m_data.is_favorite)
    GETTER(bool, isLightgunGame, m_data.is_lightgun_game)
	
    GETTER(const QList<RetroAchievement> &, retroAchievements, m_data.retro_achievements)
    GETTER(int, RaGameID, m_data.ra_game_id)
    GETTER(const QString&, RaHash, m_data.ra_hash)

    //new way using collection to access information from GETTER
    GETTER(const QString&, systemManufacturer, m_collections->get(0)->manufacturer())
    GETTER(const QString&, systemShortName, m_collections->get(0)->shortName())
    GETTER(const QString&, launchCmd, m_collections->get(0)->commonLaunchCmd())
    GETTER(const QString&, launchWorkdir, m_collections->get(0)->commonLaunchWorkdir())
    GETTER(const QString&, launchCmdBasedir, m_collections->get(0)->commonLaunchCmdBasedir())
    GETTER(const QString, emulatorName, getEmulatorName())
    GETTER(const QString, emulatorCore, getEmulatorCore())
#undef GETTER


#define SETTER(type, name, field) \
    Game& set##name(type val) { m_data.field = std::move(val); return *this; }
    Game& setTitle(QString);
    SETTER(QString, SortBy, sort_by)
    SETTER(QString, Summary, summary)
    SETTER(QString, Description, description)
    SETTER(QString, Hash, hash)
    SETTER(QString, Md5, md5)
	SETTER(QString, Path, path)
	SETTER(QString, GenreId, genreid)
    SETTER(QDate, ReleaseDate, release_date)
    SETTER(int, PlayerCount, player_count)
    SETTER(float, Rating, rating)
	SETTER(int, RaGameID, ra_game_id)
	SETTER(QString, RaHash, ra_hash)
	SETTER(QList<RetroAchievement>, RetroAchievements, retro_achievements)
    Game& setFavorite(bool val);
    Game& setLightgunGame(bool val);
#undef SETTER


#define STRLIST(singular, field) \
    QString singular##Str() const; \
    QStringList& singular##List() { return m_data.field; } \
    Q_PROPERTY(QString singular READ singular##Str CONSTANT) \
    Q_PROPERTY(QStringList singular##List READ singular##ListConst CONSTANT)
    STRLIST(developer, developers)
    STRLIST(publisher, publishers)
    STRLIST(genre, genres)
    STRLIST(tag, tags)
#undef GEN

    Q_PROPERTY(QString title READ title CONSTANT)
    Q_PROPERTY(QString sortTitle READ sortBy CONSTANT)
    Q_PROPERTY(QString sortBy READ sortBy CONSTANT)
    Q_PROPERTY(QString summary READ summary CONSTANT)
    Q_PROPERTY(QString description READ description CONSTANT)
    Q_PROPERTY(QString hash READ hash CONSTANT)
    Q_PROPERTY(QString md5 READ md5 CONSTANT)
	Q_PROPERTY(QString path READ path CONSTANT)
	Q_PROPERTY(QString genreid READ genreid CONSTANT)
    Q_PROPERTY(QDate release READ releaseDate CONSTANT)
    Q_PROPERTY(int players READ playerCount CONSTANT)
    Q_PROPERTY(float rating READ rating CONSTANT)

    Q_PROPERTY(int releaseYear READ releaseYear CONSTANT)
    Q_PROPERTY(int releaseMonth READ releaseMonth CONSTANT)
    Q_PROPERTY(int releaseDay READ releaseDay CONSTANT)

    Q_PROPERTY(int playCount READ playCount NOTIFY playStatsChanged)
    Q_PROPERTY(int playTime READ playTime NOTIFY playStatsChanged)
    Q_PROPERTY(QDateTime lastPlayed READ lastPlayed NOTIFY playStatsChanged)
    Q_PROPERTY(bool favorite READ isFavorite WRITE setFavorite NOTIFY favoriteChanged)
    Q_PROPERTY(bool lightgungame READ isLightgunGame WRITE setLightgunGame NOTIFY lightgunGameChanged)

    Q_PROPERTY(QString systemShortName READ systemShortName CONSTANT)
    Q_PROPERTY(QString systemManufacturer READ systemManufacturer CONSTANT)

    Q_PROPERTY(int RaGameID READ RaGameID NOTIFY raGameIDChanged)
    Q_PROPERTY(QString RaHash READ RaHash NOTIFY raHashChanged)
	
    Q_PROPERTY(QVariantMap extra READ extraMap CONSTANT)
    const QVariantMap& extraMap() const { return m_extra; }
    QVariantMap& extraMapMut() { return m_extra; }

    //need specific property and invokable function due to QList<struct> is not supported by QML layer
    Q_PROPERTY(int retroAchievementsCount READ getRetroAchievementsCount CONSTANT)
    Q_INVOKABLE QString GetRaTitleAt (const int index) {if (m_data.retro_achievements.count() > index) return m_data.retro_achievements.at(index).Title;
														else return "";};
	Q_INVOKABLE QString GetRaDescriptionAt (const int index) {if (m_data.retro_achievements.count() > index) return m_data.retro_achievements.at(index).Description;
														else return "";};
	Q_INVOKABLE QString GetRaPointsAt (const int index){if (m_data.retro_achievements.count() > index) return QString::number(m_data.retro_achievements.at(index).Points);
														else return "";};
	Q_INVOKABLE QString GetRaAuthorAt (const int index){if (m_data.retro_achievements.count() > index) return m_data.retro_achievements.at(index).Author;
														else return "";};
	Q_INVOKABLE QString GetRaBadgeAt (const int index) {if (m_data.retro_achievements.count() > index) return m_data.retro_achievements.at(index).BadgeName;
														else return "";};
	Q_INVOKABLE bool isRaUnlockedAt (const int index)  {if (m_data.retro_achievements.count() > index) return m_data.retro_achievements.at(index).Unlocked;
														else return false;};
	Q_INVOKABLE bool isRaHardcoreAt (const int index)  {if (m_data.retro_achievements.count() > index) return m_data.retro_achievements.at(index).HardcoreMode;
														else return false;};

    Assets& assets() { return *m_assets; }
    Assets& assetsMut() { return *m_assets; }
    Q_PROPERTY(model::Assets* assets READ assetsPtr CONSTANT)

    const Collection& collections() const { return *m_collections; }
    Collection* collectionMut() { return m_collections; }
    Q_PROPERTY(model::Collection* collections READ collectionPtr CONSTANT)

    Game& setFiles(std::vector<model::GameFile*>&&);
    Game& cleanFiles();
    Game& setCollections(std::vector<model::Collection*>&&);
		
    const QVector<model::GameFile*>& filesConst() const { Q_ASSERT(!m_files->isEmpty()); return m_files->asList(); }

    QML_OBJMODEL_PROPERTY(model::GameFile, files)

private:
    GameData m_data;
    Assets* const m_assets;
    Collection* m_collections;
    QVariantMap m_extra;
    static const providers::retroAchievements::Metadata m_metahelper;

    Assets* assetsPtr() const { return m_assets; }
    Collection* collectionPtr() const { return m_collections; }

    const QString getEmulatorName() const;
    const QString getEmulatorCore() const;

signals:
    void launchFileSelectorRequested();
    void favoriteChanged();
    void lightgunGameChanged();
    void playStatsChanged();
	void retroAchievementsInitialized();
	void retroAchievementsChanged();
    void raGameIDChanged();
    void raHashChanged();

private slots:
    void onEntryPlayStatsChanged();
	void updateRetroAchievements_slot();
	void initRetroAchievements_slot();
    void checkRetroAchievements_slot();

public:
    explicit Game(QObject* parent = nullptr);
    explicit Game(QString name, QObject* parent = nullptr);
	int getRetroAchievementsCount() const { return m_data.retro_achievements.count(); };
	void unlockRetroAchievement(const int index) { if (m_data.retro_achievements.count() > index) m_data.retro_achievements[index].Unlocked = true; };
	void activateHardcoreRetroAchievement(const int index) { if (m_data.retro_achievements.count() > index) m_data.retro_achievements[index].HardcoreMode = true; };
	Q_INVOKABLE void launch();
    Q_INVOKABLE void launchNetplay(const int mode, const QString& port, const QString& ip, const QString& playerpassword, const QString& viewerpassword, const bool vieweronly, const QString& hash, const QString& emulator, const QString& core);

    //Function to check if any Retroachievements are available (just generate hash and check if gameid exists)
    Q_INVOKABLE void checkRetroAchievements();
    //Function to initialize all Retrachievements details for a game
    Q_INVOKABLE void initRetroAchievements();
    //Function to update existing retroachievements
    Q_INVOKABLE void updateRetroAchievements();

    void finalize();
};


bool sort_games(const model::Game* const, const model::Game* const);
} // namespace model
