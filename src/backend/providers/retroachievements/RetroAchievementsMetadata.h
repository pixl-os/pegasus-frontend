// Pegasus Frontend
//
// Created by BozoTheGeek 07/06/2021
//

#pragma once

#include <QString>
#include "utils/HashMap.h"

#ifndef __RARCH_CHEEVOS_UTIL_H
#define __RARCH_CHEEVOS_UTIL_H

#include "retro_common_api.h"

RETRO_BEGIN_DECLS

/*****************************************************************************
Setup - mainly for debugging
*****************************************************************************/

/* Define this macro to get extra-verbose log for cheevos. */
#define CHEEVOS_VERBOSE

/*****************************************************************************
End of setup
*****************************************************************************/

#define RCHEEVOS_TAG "[RCHEEVOS]: "
#define CHEEVOS_FREE(p) do { void* q = (void*)p; if (q) free(q); } while (0)

#ifdef CHEEVOS_VERBOSE

#define CHEEVOS_LOG RARCH_LOG
#define CHEEVOS_ERR RARCH_ERR

#else

#define CHEEVOS_LOG rcheevos_log
#define CHEEVOS_ERR RARCH_ERR

void rcheevos_log(const char *fmt, ...);

#endif

RETRO_END_DECLS

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
