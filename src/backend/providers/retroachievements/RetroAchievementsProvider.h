// Pegasus Frontend
//
// Created by BozoTheGeek 20/03/2023
//


#pragma once

#include "providers/Provider.h"

namespace providers {
namespace retroAchievements {

class RetroAchievementsProvider : public Provider {
    Q_OBJECT

public:

    explicit RetroAchievementsProvider(QString hashlibrary_url, QObject* parent = nullptr);
    explicit RetroAchievementsProvider(QObject* parent = nullptr);

    Provider& run(SearchContext&) final;

private:
    const QString m_hashlibrary_url;
};

} // namespace retroAchievements
} // namespace providers
