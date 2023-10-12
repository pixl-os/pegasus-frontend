// Pegasus Frontend
//
// Created by BozoTheGeek 07/06/2021
//

#pragma once

#include <QString>
#include "utils/HashMap.h"

#ifndef __RARCH_CHEEVOS_UTIL_H
#define __RARCH_CHEEVOS_UTIL_H

#define CHEEVOS_FREE(p) do { void* q = (void*)p; if (q) free(q); } while (0)
#define HAVE_CHD

#include "utils/libretro-common/include/retro_common_api.h"

#endif /* __RARCH_CHEEVOS_UTIL_H */

namespace model { class Game; }

namespace providers {
namespace retroAchievements {

class Metadata {
public:
    explicit Metadata(QString);
    //function to set Hash and GameID for game object
    void set_RaHash_And_GameID_from_hashlibrary(model::Game&, bool) const;
    //function to set Ra Details for game object
    void fill_Ra_from_network_or_cache(model::Game&, bool) const;
    const QString& log_tag() const { return m_log_tag; }
    //function to build md5/gameid hash map from hash library json url provided by retroachievements.org
    void build_md5_db(QString hashlibrary_url) const;

private:
    //to store content of http://retroachievements.org/dorequest.php?r=hashlibrary
    static HashMap <QString, qint64> mRetroAchievementsGames;

private:
    const QString m_log_tag;
    const QString m_json_cache_dir;
};
} // namespace retroAchievements
} // namespace providers
