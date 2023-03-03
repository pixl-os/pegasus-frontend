// Pegasus Frontend
// Copyright (C) 2017  Mátyás Mustoha
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


#include "FrontendLayer.h"

#include "Paths.h"
#include "imggen/BlurhashProvider.h"
#include "utils/DiskCachedNAM.h"

#ifdef Q_OS_ANDROID
#include "platform/AndroidAppIconProvider.h"
#endif

#include <QQmlContext>
#include <QQmlNetworkAccessManagerFactory>

#include "KeyEmitter.h"

#include <QtConcurrent/QtConcurrent>

//For recalbox
#include "RecalboxConf.h"

namespace {

class DiskCachedNAMFactory : public QQmlNetworkAccessManagerFactory {
public:
    QNetworkAccessManager* create(QObject* parent) override;
};

QNetworkAccessManager* DiskCachedNAMFactory::create(QObject* parent)
{
    return utils::create_disc_cached_nam(parent);
}

} // namespace


FrontendLayer::FrontendLayer(QObject* const api, QObject* parent)
    : QObject(parent)
    , m_api(api)
    , m_engine(nullptr)
{
    // Note: the pointer to the Api is non-owning and constant during the runtime
}

void FrontendLayer::rebuild()
{
    if(!m_engine){

        m_engine = new QQmlApplicationEngine(this);
        m_engine->addImportPath(QStringLiteral("lib/qml"));
        m_engine->addImportPath(QStringLiteral("qml"));
        m_engine->setNetworkAccessManagerFactory(new DiskCachedNAMFactory);

        m_engine->addImageProvider(QStringLiteral("blurhash"), new BlurhashProvider);
#ifdef Q_OS_ANDROID
        m_engine->addImageProvider(QStringLiteral("androidicons"), new AndroidAppIconProvider);
#endif
        //to add keyEmitter to simulate press on some keyboard keys from controller
        KeyEmitter *keyEmitter = new KeyEmitter(this);
        m_engine->rootContext()->setContextProperty(QStringLiteral("api"), m_api);
        m_engine->rootContext()->setContextProperty(QStringLiteral("keyEmitter"), keyEmitter);
        m_engine->load(QUrl(QStringLiteral("qrc:/frontend/main.qml")));
    }
    emit rebuildComplete();
}

void FrontendLayer::teardown()
{
    Q_ASSERT(m_engine);

    if((!RecalboxConf::Instance().AsBool("pegasus.multiwindows",false)) && (!RecalboxConf::Instance().AsBool("pegasus.theme.keeploaded",false))){
        // signal forwarding
        connect(m_engine, &QQmlApplicationEngine::destroyed,
                this, &FrontendLayer::teardownComplete);
        m_engine->deleteLater();
        m_engine = nullptr;
    }
    else emit teardownComplete(); //just to confirm all task are done
}

void FrontendLayer::clearCache()
{
    Q_ASSERT(m_engine);
    m_engine->clearComponentCache();
}

void FrontendLayer::trimCache()
{
    Q_ASSERT(m_engine);
    m_engine->trimComponentCache();
}
