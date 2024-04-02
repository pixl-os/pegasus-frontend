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


#pragma once

#include "CliArgs.h"
#include "model/gaming/Collection.h"
#include "model/gaming/Game.h"
#include "model/internal/Internal.h"
#include "model/device/DeviceInfo.h"
#include "model/keys/Keys.h"
#include "model/memory/Memory.h"
#include "providers/ProviderManager.h"
#include "utils/QmlHelpers.h"

#include "QtQmlTricks/QQmlObjectListModel.h"
#include <QObject>


/// Provides data access for QML
///
/// Provides an API for the frontend layer, to allow accessing every public
/// property of the backend from QML.
class ApiObject : public QObject {
    Q_OBJECT

    QML_CONST_PROPERTY(model::Internal, internal)
    QML_CONST_PROPERTY(model::DeviceInfo, device)
    QML_CONST_PROPERTY(model::Keys, keys)
    QML_READONLY_PROPERTY(model::Memory, memory)
    QML_OBJMODEL_PROPERTY(model::Collection, collections)
    QML_OBJMODEL_PROPERTY(model::Game, allGames)

    // retranslate on locale change
    Q_PROPERTY(QString tr READ emptyString NOTIFY localeChanged)

    // get game from m_launch_game_file
    Q_PROPERTY(model::Game* launchedgame READ launchedgame NOTIFY launchedgameChanged)

public:
    explicit ApiObject(const backend::CliArgs& args, QObject* parent = nullptr);

    // scanning
    void startScanning();
	
    Q_INVOKABLE void connectGameFiles(model::Game* game);

signals:
    void launchGameFile(const model::GameFile*);
    void launchFailed(QString);
    void memoryChanged();

    // triggers translation update
    void localeChanged();

    // triggers  launched game file update
    void launchedgameChanged();
    
    // triggers list of parameters update
    void parameterChanged();

    // Api events for QML -- no const here
    void eventLoadingStarted();
    void eventSelectGameFile(model::Game* game);
    void eventLaunchError(QString msg);
    void showPopup(QString title, QString message, QString icon, int delay);
    void newController(int device_idx, QString message);
    void requestAction(QString action);

public slots:
    // game launch communication
    void onGameFinished();
    void onGameLaunchOk();
    void onGameLaunchError(QString);
    void onShowPopup(QString, QString, QString, int);
    void onNewController(int, QString);
    void onRequestAction(QString);

private slots:
    // internal communication
    void onSearchFinished();
    void onGameFavoriteChanged();
    void onGameFileSelectorRequested();
    void onGameFileLaunchRequested();
    void onThemeChanged();

private:
    // game launching
    model::GameFile* m_launch_game_file;

    // initialization
    QVector<model::Collection*> m_providerman_collections; // TODO: std::vector
    QVector<model::Game*> m_providerman_games;
    ProviderManager m_providerman;

    // used to trigger re-rendering of texts on locale change
    QString emptyString() const { return QString(); }

    // return m_launch_game_file path in a string
    model::Game* launchedgame() const {
        if(m_launch_game_file != nullptr){
            return m_launch_game_file->parentGame();
        }
        else return nullptr;
    }
};
