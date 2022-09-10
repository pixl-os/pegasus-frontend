// Pegasus Frontend
//
// Created by Bozo The Geek - 28/12/2021
//

//to access to systemList.xml
#include "providers/es2/Es2Provider.h"

#pragma once

#include "model/gaming/Game.h"
#include "model/gaming/GameFile.h"

#include "utils/QmlHelpers.h"
#include <QString>
#include <QObject>

namespace model {

class Singleplay : public QObject {
    Q_OBJECT
    QML_CONST_PROPERTY(model::Game, game)

public:
    explicit Singleplay(QObject* parent = nullptr);
    Q_INVOKABLE void setTitle (const QString title) {m_game.setTitle(title);};
    Q_INVOKABLE void setFile (const QString path) {
        m_game.cleanFiles(); //clean files to avoid to add new file to existing ones for the moment.
        m_game.setFiles({ new model::GameFile(QFileInfo(path), m_game) });
        m_game.setPath(path);
    }
    Q_INVOKABLE void setSystem (const QString shortName);

signals:

private slots:

public:

private:
    providers::es2::Es2Provider *Provider;
};
} // namespace model
