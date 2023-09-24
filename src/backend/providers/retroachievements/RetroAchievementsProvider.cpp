// Pegasus Frontend
//
// Created by BozoTheGeek 20/03/2023
//

#include "RetroAchievementsProvider.h"
#include "RetroAchievementsMetadata.h"

#include "Log.h"
#include "model/gaming/Assets.h"
#include "model/gaming/Game.h"
#include "model/gaming/GameFile.h"
#include "providers/SearchContext.h"
#include "utils/PathTools.h"

#include <QDirIterator>
#include <QStringBuilder>
#include <array>


namespace {
QString default_hashlibrary_urls()
{
    return QStringLiteral("http://retroachievements.org/dorequest.php?r=hashlibrary");
}
} // namespace

namespace providers {
namespace retroAchievements {

RetroAchievementsProvider::RetroAchievementsProvider(QObject* parent)
    : RetroAchievementsProvider(default_hashlibrary_urls(), parent)
{}

RetroAchievementsProvider::RetroAchievementsProvider(QString hashlibrary_url, QObject* parent)
    : Provider(QLatin1String("retroAchievements"), QStringLiteral("RetroAchievements provider"), PROVIDER_FLAG_INTERNAL | PROVIDER_FLAG_HIDE_PROGRESS, parent)
    , m_hashlibrary_url(std::move(hashlibrary_url))
{}

Provider& RetroAchievementsProvider::run(SearchContext& sctx)
{
    //Initialize Metahelper for each update and for each games for the moment
    QString log_tag = "Retroachievements provider";
    try{
        //build md5 db for hash library
        providers::retroAchievements::Metadata metahelper(log_tag);
        metahelper.build_md5_db(m_hashlibrary_url);
    }
    catch ( const std::exception & Exp )
    {
        Log::error(log_tag, LOGMSG("Error: %1.\n").arg(Exp.what()));
    }
    return *this;
}

} // namespace skraper
} // namespace providers
