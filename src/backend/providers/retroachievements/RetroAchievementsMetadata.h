// Pegasus Frontend
//
// Created by BozoTheGeek 07/06/2021
//


#pragma once

#include <QString>

namespace model { class Game; }

namespace providers {
namespace retroAchievements {

class Metadata {
public:
    explicit Metadata(QString);

    void fill_from_network(model::Game&) const;
    const QString& log_tag() const { return m_log_tag; }

private:
    const QString m_log_tag;
    const QString m_json_cache_dir;
};
} // namespace retroAchievements
} // namespace providers
