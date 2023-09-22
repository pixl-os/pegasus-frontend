// Pegasus Frontend
//
// Created by BozoTheGeek 07/06/2021
//

#pragma once

#include <QString>

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

    void fill_from_network_or_cache(model::Game&, bool) const;
    const QString& log_tag() const { return m_log_tag; }

private:
    const QString m_log_tag;
    const QString m_json_cache_dir;
};
} // namespace retroAchievements
} // namespace providers
