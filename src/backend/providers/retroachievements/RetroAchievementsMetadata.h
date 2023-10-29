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
    //function to set Hash and GameID for game object (return gameid)
    int set_RaHash_And_GameID_from_hashlibrary_or_cache(model::Game&, bool) const;
    //function to set Ra Details for game object
    void fill_Ra_from_network_or_cache(model::Game&, bool) const;
    const QString& log_tag() const { return m_log_tag; }
    //function to build md5/gameid hash map from hash library json url provided by retroachievements.org
    void build_md5_db(QString hashlibrary_url) const;
    //function used by when provider is launch at pegasus-frontend start
    //and need to reset cache each time to force update of hash library
    void reset_md5_db() const;
    //function to verify/get token for the first time
    bool verify_token() const;
private:
    //to store content of http://retroachievements.org/dorequest.php?r=hashlibrary
    static HashMap <QString, qint64> mRetroAchievementsGames;
    static bool HashProcessingInProgress;
    static QString Token; //to keep token locally in memory to avoid use read cache (using file)
private:
    const QString m_log_tag;
    const QString m_json_cache_dir;
};
} // namespace retroAchievements
} // namespace providers
