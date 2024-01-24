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
#include "utils/QmlHelpers.h"
#include <QString>

#ifdef Q_CC_MSVC
// MSVC has troubles with forward declared QML model types
#include "model/gaming/Game.h"
#endif

namespace model { class Assets; }
namespace model { class Game; }
namespace model {

struct EmulatorsEntry {
    QString name;
    QString core;
    int priority;
    int netplay;
    QString corelongname; //now available from all .corenames files
    QString coreversion; //now available from all .corenames files
    QString coreextensions;
    QString corecompatibility;
    QString corespeed;
};

struct CollectionData {
    explicit CollectionData(QString name);

    const QString name;
    QString sort_by;

    QString summary;
    QString description;
    QString type;
    QString manufacturer;
    QString releasedate;
    QString screen_scraper_id;

    //flag added 02/10/2023 from systemlist.xml
    bool pad;
    bool keyboard;
    bool mouse;
    bool lightgun;
    bool retroachievements;

    QString common_launch_cmd;
    QString common_launch_workdir;
    QString common_relative_basedir;
    QList <EmulatorsEntry> common_emulators;

    void set_short_name(const QString&);
    const QString& short_name() const { return m_short_name; }

private:
    QString m_short_name;
};

class Collection : public QObject {
    Q_OBJECT

public:
#define GETTER(type, name, field) \
    type name() const { return m_data.field; }

    GETTER(const QString&, name, name)
    GETTER(const QString&, sortBy, sort_by)
    GETTER(const QString&, shortName, short_name())
    GETTER(const QString&, summary, summary)
    GETTER(const QString&, description, description)
    GETTER(const QString&, type, type)
    GETTER(const QString&, manufacturer, manufacturer)
    GETTER(const QString&, releasedate, releasedate)
    GETTER(const QString&, screenScraperId, screen_scraper_id)

    //flag added 02/10/2023 from systemlist.xml
    GETTER(bool, pad, pad)
    GETTER(bool, keyboard, keyboard)
    GETTER(bool, mouse, mouse)
    GETTER(bool, lightgun, lightgun)
    GETTER(bool, retroachievements, retroachievements)

    GETTER(const QString&, commonLaunchCmd, common_launch_cmd)
    GETTER(const QString&, commonLaunchWorkdir, common_launch_workdir)
    GETTER(const QString&, commonLaunchCmdBasedir, common_relative_basedir)
    GETTER(const QList<EmulatorsEntry> &, commonEmulators, common_emulators)
#undef GETTER


#define SETTER(type, name, field) \
    Collection& set##name(type val) { m_data.field = std::move(val); return *this; }

    SETTER(QString, SortBy, sort_by)
    SETTER(QString, Summary, summary)
    SETTER(QString, Description, description)
    SETTER(QString, Type, type)
    SETTER(QString, Manufacturer, manufacturer)
    SETTER(QString, ReleaseDate, releasedate)
    SETTER(QString, ScreenScraperId, screen_scraper_id)

    //flag added 02/10/2023 from systemlist.xml
    SETTER(bool, Pad, pad)
    SETTER(bool, Keyboard, keyboard)
    SETTER(bool, Mouse, mouse)
    SETTER(bool, Lightgun, lightgun)
    SETTER(bool, Retroachievements, retroachievements)

    SETTER(QString, CommonLaunchCmd, common_launch_cmd)
    SETTER(QString, CommonLaunchWorkdir, common_launch_workdir)
    SETTER(QString, CommonLaunchCmdBasedir, common_relative_basedir)
    SETTER(QList<EmulatorsEntry>, CommonEmulators, common_emulators)
    Collection& setShortName(QString val) { m_data.set_short_name(std::move(val)); return *this; }
#undef SETTER


    Q_PROPERTY(QString name READ name CONSTANT)
    Q_PROPERTY(QString sortBy READ sortBy CONSTANT)
    Q_PROPERTY(QString shortName READ shortName CONSTANT)
    Q_PROPERTY(QString summary READ summary CONSTANT)
    Q_PROPERTY(QString description READ description CONSTANT)
    Q_PROPERTY(QString type READ type CONSTANT)
    Q_PROPERTY(QString manufacturer READ manufacturer CONSTANT)
    Q_PROPERTY(QString releasedate READ releasedate CONSTANT)
    Q_PROPERTY(QString screenScraperId READ screenScraperId CONSTANT)
    //flag added 02/10/2023 from systemlist.xml
    Q_PROPERTY(bool pad READ pad CONSTANT)
    Q_PROPERTY(bool keyboard READ keyboard CONSTANT)
    Q_PROPERTY(bool mouse READ mouse CONSTANT)
    Q_PROPERTY(bool lightgun READ lightgun CONSTANT)
    Q_PROPERTY(bool retroachievements READ retroachievements CONSTANT)

    //need specific property and invokable function due to QList<struct> is not supported by QML layer
    Q_PROPERTY(int emulatorsCount READ getEmulatorsCount CONSTANT)

    //to be retro-compatible with legacy "Themes" but using only one collection (ex: game.collections.get(0)....)
    Q_INVOKABLE model::Collection* get (const int index) { if (index == 0) return this;
                                                           else return nullptr; //as undefined
                                                         };
    Q_INVOKABLE QString getNameAt (const int index) {return m_data.common_emulators.at(index).name;};
    Q_INVOKABLE QString getCoreAt (const int index) {return m_data.common_emulators.at(index).core;};
    Q_INVOKABLE QString getPriorityAt (const int index) {return QString::number(m_data.common_emulators.at(index).priority);};
    Q_INVOKABLE bool hasNetplayAt (const int index) {
		//can't use this method for the moment due to issue in the systemList.xml as for NES where only fbneo is Netplay compatible ?! strange ?!
		//if(m_data.common_emulators.at(index).netplay != 0) return true; 
		//else return false;
        //only libretro is accepted to have netplay
        if((m_data.common_emulators.at(index).corelongname != "") && (m_data.common_emulators.at(index).name == "libretro")) return true; //if not empty, this core exists and use today for netplay
		else return false;
	};
	Q_INVOKABLE QString getCoreLongNameAt (const int index) {return m_data.common_emulators.at(index).corelongname;};
    Q_INVOKABLE QString getCoreVersionAt (const int index) {return m_data.common_emulators.at(index).coreversion;};

    Q_INVOKABLE QString getCoreExtensionsAt (const int index) {return m_data.common_emulators.at(index).coreextensions;};
    Q_INVOKABLE QString getCoreCompatibilityAt (const int index) {return m_data.common_emulators.at(index).corecompatibility;};
    Q_INVOKABLE QString getCoreSpeedAt (const int index) {return m_data.common_emulators.at(index).corespeed;};

    Q_INVOKABLE bool isDefaultEmulatorAt (const int index) {
       // do loop to find the first priorioty (minimum number)
       int first_priority = 0;
       for (int n = 0;n < m_data.common_emulators.count(); n++)
        {
            //if only one or to initialize with one value
            if (n == 0)
            {    
                first_priority = m_data.common_emulators.at(n).priority;
            }
            else if(first_priority > m_data.common_emulators.at(n).priority) //else we check if previous priority is lower
            {
                first_priority = m_data.common_emulators.at(n).priority;
            }
        }
        if(m_data.common_emulators.at(index).priority == first_priority) return true;
        else return false;
    };
    Q_PROPERTY(QVariantMap extra READ extraMap CONSTANT)
    const QVariantMap& extraMap() const { return m_extra; }
    QVariantMap& extraMapMut() { return m_extra; }


    Assets& assets() { return *m_assets; }
    Assets& assetsMut() { return *m_assets; }
    Q_PROPERTY(model::Assets* assets READ assetsPtr CONSTANT)

    Collection& setGames(std::vector<model::Game*>&&);
    int collectionSize(){
        return m_games->size();
    };
    bool hasGame(){
        if(m_games->at(0) != nullptr){
            return true;
        }
        else return false;
    };

    //const QVector<model::Game*>& gamesConst() const { Q_ASSERT(!m_games->isEmpty()); return m_games->asList(); }
    const QVector<model::Game*>& gamesConst() const { return m_games->asList(); }
    QML_OBJMODEL_PROPERTY(model::Game, games)

public:
    explicit Collection(QString name, QObject* parent = nullptr);

    int getEmulatorsCount() const { return m_data.common_emulators.count(); }
    void finalize();

private:
    CollectionData m_data;
    QVariantMap m_extra;
    Assets* const m_assets;

    Assets* assetsPtr() { return m_assets; }
};

bool sort_collections(const model::Collection* const, const model::Collection* const);
} // namespace model


