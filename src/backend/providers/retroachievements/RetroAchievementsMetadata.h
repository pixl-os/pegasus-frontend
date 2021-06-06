// Pegasus Frontend
//
// Created by BozoTheGeek 07/06/2021
//


#pragma once

#include <QString>

namespace model { class Game; }
namespace providers { class SearchContext; }

namespace providers {
namespace retroAchievements {

class Metadata {
public:
    explicit Metadata(QString);

    bool fill_from_cache(const QString&, model::Game&) const;
    void fill_from_network(const QString&, model::Game&, SearchContext&) const;

    const QString& log_tag() const { return m_log_tag; }

private:
    const QString m_log_tag;
    const QString m_json_cache_dir;
    const QString m_json_api_suffix;
    const QString m_json_embed_suffix;
};
} // namespace retroAchievements
} // namespace providers
