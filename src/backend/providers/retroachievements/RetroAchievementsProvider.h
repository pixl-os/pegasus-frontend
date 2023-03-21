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
    explicit RetroAchievementsProvider(QObject* parent = nullptr);

    Provider& run(SearchContext&) final;
};

} // namespace retroAchievements
} // namespace providers
