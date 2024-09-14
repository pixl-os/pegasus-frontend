// Pegasus Frontend
// Copyright (C) 2017-2018  Mátyás Mustoha
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


#include "Memory.h"

#include "Log.h"
#include "Paths.h"

#include <QDir>
#include <QFileInfo>
#include <QJsonDocument>
#include <QJsonObject>
#include <QStringBuilder>


namespace {
QString default_settings_dir()
{
    return paths::writableConfigDir() % QStringLiteral("/theme_settings/");
}

QString json_path_for(const QString& settings_dir, const QString& theme_id)
{
    return settings_dir % theme_id % QLatin1String(".json");
}

void save_map_maybe(const QVariantMap& map, const QString& settings_dir, const QString& theme_id)
{
    if (map.isEmpty() || theme_id.isEmpty())
        return;

    if (!QDir(settings_dir).mkpath(QStringLiteral("."))) {
        Log::warning(LOGMSG("could not create directory `%1`. Theme settings will not be saved.")
            .arg(settings_dir));
        return;
    }

    const QString json_path = json_path_for(settings_dir, theme_id);
    QFile json_file(json_path);
    if (!json_file.open(QIODevice::WriteOnly)) {
        Log::warning(LOGMSG("could not save theme settings file `%1`: %2")
            .arg(json_path, json_file.errorString()));
        return;
    }

    const auto json_doc = QJsonDocument::fromVariant(map);
    if (json_file.write(json_doc.toJson(QJsonDocument::Compact)) < 0) {
        Log::warning(LOGMSG("failed to write theme settings file `%1`: %2")
            .arg(json_path, json_file.errorString()));
    }
}

QVariantMap load_map_maybe(const QString& settings_dir, const QString& theme_id)
{
    if (theme_id.isEmpty())
        return {};

    const QString json_path = json_path_for(settings_dir, theme_id);
    if (!QFileInfo::exists(json_path))
        return {};

    QFile json_file(json_path);
    if (!json_file.open(QIODevice::ReadOnly)) {
        Log::warning(LOGMSG("could not load theme settings file `%1`: %2")
            .arg(json_path, json_file.errorString()));
        return {};
    }

    QJsonParseError parse_error {};
    const auto json_doc = QJsonDocument::fromJson(json_file.readAll(), &parse_error);
    if (json_doc.isNull()) {
        Log::warning(LOGMSG("failed to parse theme settings file `%1`: %2")
            .arg(json_path, parse_error.errorString()));
        return {};
    }

    return json_doc.object().toVariantMap();
}
} // namespace


namespace model {
Memory::Memory(QObject* parent)
    : Memory(default_settings_dir(), parent)
{}

Memory::Memory(QString settings_dir, QObject* parent)
    : QObject(parent)
    , m_settings_dir(std::move(settings_dir))
{}

void Memory::flush() const
{
    save_map_maybe(m_data, m_settings_dir, m_current_theme);
}

QVariant Memory::get(const QString& key) const
{
    return m_data.value(key);
}

bool Memory::has(const QString& key) const
{
    return m_data.contains(key);
}

void Memory::set(const QString& key, QVariant value)
{
    if (key.isEmpty()) {
        Log::warning(LOGMSG("`set(key,val)` called with empty `key`, ignored"));
        return;
    }
    if (!value.isValid()) {
        Log::warning(LOGMSG("`set(key,val)` called with invalid `val` type, ignored"));
        return;
    }

    m_data[key] = std::move(value);
    emit dataChanged();

    flush();
}

void Memory::unset(const QString& key)
{
    m_data.remove(key);
    emit dataChanged();

    flush();
}

void Memory::changeTheme(const QString& theme_root_dir)
{
    //Log::debug(LOGMSG("void Memory::changeTheme(const QString& theme_root_dir) : %1").arg(theme_root_dir));
    if(theme_root_dir.endsWith('/')){
        const int dir_name_start = theme_root_dir.lastIndexOf('/', -2) + 1;
        const int dir_name_len = theme_root_dir.length() - dir_name_start - 1;
        if (dir_name_len > 0) {
            m_current_theme = theme_root_dir.mid(dir_name_start, dir_name_len);
            m_data = load_map_maybe(m_settings_dir, m_current_theme);
        }
    }
    emit dataChanged();
}
} // namespace model
