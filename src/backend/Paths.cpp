// Pegasus Frontend
// Copyright (C) 2018  Mátyás Mustoha
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


#include "Paths.h"

#include "AppSettings.h"

#include <QCoreApplication>
#include <QDir>
#include <QFileInfo>
#include <QProcessEnvironment>
#include <QRegularExpression>
#include <QStandardPaths>
#include <QString>

#include <functional>

//For recalbox
#include "RecalboxConf.h"

namespace {
using QSP = QStandardPaths;

void remove_orgname(QString& str)
{
    const QRegularExpression replace_regex(QStringLiteral("(/pegasus-frontend){2}$"));
    str.replace(replace_regex, QStringLiteral("/pegasus-frontend"));
}

void create_dir_if_not_exists(const QString& dir_path)
{
    Q_ASSERT(!dir_path.isEmpty());
    QDir(dir_path).mkpath(QLatin1String(".")); // does nothing if already exists
}

QString get_appconfig_dir()
{
#ifdef Q_OS_ANDROID
    const QString dir_path = QSP::writableLocation(QSP::GenericDataLocation)
                           + QStringLiteral("/pegasus-frontend");
#else
    QString dir_path = AppSettings::general.portable
        ? QCoreApplication::applicationDirPath() + QStringLiteral("/config")
        : QSP::writableLocation(QSP::AppConfigLocation);
    remove_orgname(dir_path);
#endif
    create_dir_if_not_exists(dir_path);
    return dir_path;
}

QString get_cache_dir()
{
    QString dir_path = QSP::writableLocation(QSP::CacheLocation);
    remove_orgname(dir_path);
    create_dir_if_not_exists(dir_path);
    return dir_path;
}

} // namespace


namespace paths {

QString homePath()
{
    static const QString home_path = [](){
        const auto env = QProcessEnvironment::systemEnvironment();

#ifdef Q_OS_WIN32
        // allow overriding the home directory on Windows:
        // QDir::homePath() checks the env vars last on this platform,
        // but we want it to be the first
        return env.value("PEGASUS_HOME", env.value("HOME", QDir::homePath()));
#else
        // on other platforms, QDir::homePath() returns $HOME first
        return env.value(QStringLiteral("PEGASUS_HOME"), QDir::homePath());
#endif
    }();
    return home_path;
}

QStringList configDirs()
{
    static const QStringList config_dir_paths = [](){
        QStringList paths(QLatin1String(":"));
        paths << QCoreApplication::applicationDirPath();

        const QString local_config_dir = QCoreApplication::applicationDirPath()
                                       + QStringLiteral("/config");
        if (QFileInfo::exists(local_config_dir))
            paths << local_config_dir;


        if (!AppSettings::general.portable) {
            paths << writableConfigDir();
            paths << QSP::standardLocations(QSP::AppConfigLocation);
            paths << QSP::standardLocations(QSP::AppDataLocation);

            // do not add the organization name to the search path
            const QRegularExpression regex(QStringLiteral("(/pegasus-frontend){2}$"));
            paths.replaceInStrings(regex, QStringLiteral("/pegasus-frontend"));
        }

        //add recalbox root in configDirs
        paths.append("/recalbox/share");

        paths.removeDuplicates();
        return paths;
    }();

    return config_dir_paths;
}

QStringList themesDirs()
{
    static const QStringList themes_dir_paths = [](){
        QStringList paths;

        //depreacated
        // (QLatin1String(""));
        /*const QString local_themes_dir = QCoreApplication::applicationDirPath()
                                       + QStringLiteral("/themes");
        if (QFileInfo::exists(local_themes_dir))
            paths << local_themes_dir;*/

        //add recalbox share root in themsDirs
        paths.append("/recalbox/share/themes");

        //add recalbox share init root in themsDirs
        paths.append("/recalbox/share_init/themes");

        // Define an array of directory paths (QStringList is preferred for paths)
        QStringList Paths = {
            "/pixl/themes",
            "/themes",
            "/recalbox/themes",
        };

        //if external USB are not hidden
        if(!RecalboxConf::Instance().AsBool("pegasus.external.themes.ignored")){
            //add recalbox share externals for USB
            for(int i=0; i <= 7; i++){
                QString directoryPath = "/recalbox/share/externals/usb" + QString::number(i);
                // Iterate through the directory paths
                for (const QString& Path : Paths) {
                    QString fullPath = directoryPath + Path;
                    QDir dir(fullPath);
                    // Check if the directory exists
                    if (dir.exists()) {
                        paths.append(fullPath);
                    }
                }
            }
            //add recalbox share externals for NETWORK
            for(int i=0; i <= 3; i++){
                QString directoryPath = "/recalbox/share/externals/network" + QString::number(i);
                // Iterate through the directory paths
                for (const QString& Path : Paths) {
                    QString fullPath = directoryPath + Path;
                    QDir dir(fullPath);
                    // Check if the directory exists
                    if (dir.exists()) {
                        paths.append(fullPath);
                    }
                }
            }
        }

        //if internal DRIVE are not hidden
        if(!RecalboxConf::Instance().AsBool("pegasus.internal.themes.ignored")){
            //add recalbox share internals for DRIVE
            for(int i=0; i <= 7; i++){
                QString directoryPath = "/recalbox/share/internals/drive" + QString::number(i);
                // Iterate through the directory paths
                for (const QString& Path : Paths) {
                    QString fullPath = directoryPath + Path;
                    QDir dir(fullPath);
                    // Check if the directory exists
                    if (dir.exists()) {
                        paths.append(fullPath);
                    }
                }
            }
        }

        paths.removeDuplicates();
        return paths;
    }();

    return themes_dir_paths;
}

QStringList romsDirs()
{
    static const QStringList roms_dir_paths = [](){
        QStringList paths;

        //depreacated
        // (QLatin1String(""));
        /*const QString local_roms_dir = QCoreApplication::applicationDirPath()
                                       + QStringLiteral("/roms");
        if (QFileInfo::exists(local_roms_dir))
            paths << local_roms_dir;*/

        //add recalbox share root in romsDirs
        paths.append("/recalbox/share/roms");

        //if embedded games are not hidden
        if(!RecalboxConf::Instance().AsBool("pegasus.embedded.games.hide")){
            //add recalbox share init root in romsDirs
            paths.append("/recalbox/share_init/roms");
        }

        // Define an array of directory paths (QStringList is preferred for paths)
        QStringList Paths = {
            "/pixl/roms",
            "/roms",
            "/recalbox/roms",
        };

        //if external USB are not hidden
        if(!RecalboxConf::Instance().AsBool("pegasus.external.roms.ignored")){
            //add recalbox share externals for USB
            for(int i=0; i <= 7; i++){
                QString directoryPath = "/recalbox/share/externals/usb" + QString::number(i);
                // Iterate through the directory paths
                for (const QString& Path : Paths) {
                    QString fullPath = directoryPath + Path;
                    QDir dir(fullPath);
                    // Check if the directory exists
                    if (dir.exists()) {
                        paths.append(fullPath);
                    }
                }
            }
        }

        //if internal DRIVE are not hidden
        if(!RecalboxConf::Instance().AsBool("pegasus.internal.roms.ignored")){
            //add recalbox share internals for DRIVE
            for(int i=0; i <= 7; i++){
                QString directoryPath = "/recalbox/share/internals/drive" + QString::number(i);
                // Iterate through the directory paths
                for (const QString& Path : Paths) {
                    QString fullPath = directoryPath + Path;
                    QDir dir(fullPath);
                    // Check if the directory exists
                    if (dir.exists()) {
                        paths.append(fullPath);
                    }
                }
            }
        }

        paths.removeDuplicates();
        return paths;
    }();

    return roms_dir_paths;
}

QString writableConfigDir()
{
    static const QString config_dir = get_appconfig_dir();
    return config_dir;
}

QString writableCacheDir()
{
    static const QString cache_dir = get_cache_dir();
    return cache_dir;
}

} // namespace paths
