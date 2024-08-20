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

/// Returns $PEGASUS_HOME if defined, or $HOME if defined,
/// otherwise QDir::homePath().
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

/// Returns the directory paths where config files may be located
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

/// Returns the directory paths where themes may be located
QStringList themesDirs(bool forcedRefresh)
{
    static QStringList dir_paths;
    if(forcedRefresh || dir_paths.empty()){
    dir_paths = [](QString dir = "themes"){
        QStringList paths;

        paths.append("/recalbox/share/" + dir);

        //add recalbox share init root in Dirs
        paths.append("/recalbox/share_init/" + dir);

        // Define an array of directory paths (QStringList is preferred for paths)
        QStringList Paths = {
            "/pixl/" + dir,
            "/" + dir,
            "/recalbox/" + dir,
        };

        //if external USB are not hidden
        if(!RecalboxConf::Instance().AsBool(QString("pegasus.external." + dir + ".ignored").toUtf8().constData())){
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
        if(!RecalboxConf::Instance().AsBool(QString("pegasus.internal." + dir + ".ignored").toUtf8().constData())){
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
    }

    return dir_paths;
}

/// Returns the directory paths where roms could be located
QStringList romsDirs(bool forcedRefresh)
{
    static QStringList dir_paths;
    if(forcedRefresh || dir_paths.empty()){
    dir_paths = [](QString dir = "roms"){
        QStringList paths;

        paths.append("/recalbox/share/" + dir);

        //if embedded games are not hidden
        if(!RecalboxConf::Instance().AsBool("pegasus.embedded.games.hide")){
            //add recalbox share init root in romsDirs
            paths.append("/recalbox/share_init/" + dir);
        }

        // Define an array of directory paths (QStringList is preferred for paths)
        QStringList Paths = {
            "/pixl/" + dir,
            "/" + dir,
            "/recalbox/" + dir,
        };

        //if external USB are not hidden
        if(!RecalboxConf::Instance().AsBool(QString("pegasus.external." + dir + ".ignored").toUtf8().constData())){
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
        if(!RecalboxConf::Instance().AsBool(QString("pegasus.internal." + dir + ".ignored").toUtf8().constData())){
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
    }
    return dir_paths;
}

/// Returns the directory paths where saves may be located
QStringList savesDirs(bool forcedRefresh)
{
    static QStringList dir_paths;
    if(forcedRefresh || dir_paths.empty()){
    dir_paths = [](QString dir = "saves"){
        QStringList paths;

        paths.append("/recalbox/share/" + dir);

        //add recalbox share init root in Dirs
        //NO SHARE INIT APPLICABLE IN THIS CASE
        //paths.append("/recalbox/share_init/" + dir);

        // Define an array of directory paths (QStringList is preferred for paths)
        QStringList Paths = {
            "/pixl/" + dir,
            "/" + dir,
            "/recalbox/" + dir,
        };

        //if external USB are not hidden
        if(!RecalboxConf::Instance().AsBool(QString("pegasus.external." + dir + ".ignored").toUtf8().constData())){
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
        if(!RecalboxConf::Instance().AsBool(QString("pegasus.internal." + dir + ".ignored").toUtf8().constData())){
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
    }
    return dir_paths;
}

/// Returns the directory paths where bios may be located
QStringList biosDirs(bool forcedRefresh)
{
    static QStringList dir_paths;
    if(forcedRefresh || dir_paths.empty()){
    dir_paths = [](QString dir = "bios"){
        QStringList paths;

        paths.append("/recalbox/share/" + dir);

        //add recalbox share init root in Dirs
        //NO SHARE INIT APPLICABLE IN THIS CASE
        //paths.append("/recalbox/share_init/" + dir);

        // Define an array of directory paths (QStringList is preferred for paths)
        QStringList Paths = {
            "/pixl/" + dir,
            "/" + dir,
            "/recalbox/" + dir,
        };

        //if external USB are not hidden
        if(!RecalboxConf::Instance().AsBool(QString("pegasus.external." + dir + ".ignored").toUtf8().constData())){
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
        if(!RecalboxConf::Instance().AsBool(QString("pegasus.internal." + dir + ".ignored").toUtf8().constData())){
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
    }

    return dir_paths;
}

/// Returns the directory paths where music may be located
QStringList musicDirs(bool forcedRefresh)
{
    static QStringList dir_paths;
    if(forcedRefresh || dir_paths.empty()){
    dir_paths = [](QString dir = "music"){
        QStringList paths;

        paths.append("/recalbox/share/" + dir);

        //add recalbox share init root in Dirs
        //NO SHARE INIT APPLICABLE IN THIS CASE
        //paths.append("/recalbox/share_init/" + dir);

        // Define an array of directory paths (QStringList is preferred for paths)
        QStringList Paths = {
            "/pixl/" + dir,
            "/" + dir,
            "/recalbox/" + dir,
        };

        //if external USB are not hidden
        if(!RecalboxConf::Instance().AsBool(QString("pegasus.external." + dir + ".ignored").toUtf8().constData())){
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
        if(!RecalboxConf::Instance().AsBool(QString("pegasus.internal." + dir + ".ignored").toUtf8().constData())){
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
    }

    return dir_paths;
}

/// Returns the directory paths where bios overlays be located
QStringList overlaysDirs(bool forcedRefresh)
{
    static QStringList dir_paths;
    if(forcedRefresh || dir_paths.empty()){
    dir_paths = [](QString dir = "overlays"){
        QStringList paths;

        paths.append("/recalbox/share/" + dir);

        //add recalbox share init root in Dirs
        //NO SHARE INIT APPLICABLE IN THIS CASE
        //paths.append("/recalbox/share_init/" + dir);

        // Define an array of directory paths (QStringList is preferred for paths)
        QStringList Paths = {
            "/pixl/" + dir,
            "/" + dir,
            "/recalbox/" + dir,
        };

        //if external USB are not hidden
        if(!RecalboxConf::Instance().AsBool(QString("pegasus.external." + dir + ".ignored").toUtf8().constData())){
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
        if(!RecalboxConf::Instance().AsBool(QString("pegasus.internal." + dir + ".ignored").toUtf8().constData())){
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
    }

    return dir_paths;
}

/// Returns the directory paths where screenshots may be located
QStringList screenshotsDirs(bool forcedRefresh)
{
    static QStringList dir_paths;
    if(forcedRefresh || dir_paths.empty()){
    dir_paths = [](QString dir = "screenshots"){
        QStringList paths;

        paths.append("/recalbox/share/" + dir);

        //add recalbox share init root in Dirs
        //NO SHARE INIT APPLICABLE IN THIS CASE
        //paths.append("/recalbox/share_init/" + dir);

        // Define an array of directory paths (QStringList is preferred for paths)
        QStringList Paths = {
            "/pixl/" + dir,
            "/" + dir,
            "/recalbox/" + dir,
        };

        //if external USB are not hidden
        if(!RecalboxConf::Instance().AsBool(QString("pegasus.external." + dir + ".ignored").toUtf8().constData())){
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
        if(!RecalboxConf::Instance().AsBool(QString("pegasus.internal." + dir + ".ignored").toUtf8().constData())){
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
    }

    return dir_paths;
}

/// Returns the directory paths where shaders may be located
QStringList shadersDirs(bool forcedRefresh)
{
    static QStringList dir_paths;
    if(forcedRefresh || dir_paths.empty()){
    dir_paths = [](QString dir = "shaders"){
        QStringList paths;

        paths.append("/recalbox/share/" + dir);

        //add recalbox share init root in Dirs
        //NO SHARE INIT APPLICABLE IN THIS CASE
        //paths.append("/recalbox/share_init/" + dir);

        // Define an array of directory paths (QStringList is preferred for paths)
        QStringList Paths = {
            "/pixl/" + dir,
            "/" + dir,
            "/recalbox/" + dir,
        };

        //if external USB are not hidden
        if(!RecalboxConf::Instance().AsBool(QString("pegasus.external." + dir + ".ignored").toUtf8().constData())){
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
        if(!RecalboxConf::Instance().AsBool(QString("pegasus.internal." + dir + ".ignored").toUtf8().constData())){
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
    }

    return dir_paths;
}

/// Returns the directory paths where userscripts may be located
QStringList userscriptsDirs(bool forcedRefresh)
{
    static QStringList dir_paths;
    if(forcedRefresh || dir_paths.empty()){
    dir_paths = [](QString dir = "userscripts"){
        QStringList paths;

        paths.append("/recalbox/share/" + dir);

        //add recalbox share init root in Dirs
        //NO SHARE INIT APPLICABLE IN THIS CASE
        //paths.append("/recalbox/share_init/" + dir);

        // Define an array of directory paths (QStringList is preferred for paths)
        QStringList Paths = {
            "/pixl/" + dir,
            "/" + dir,
            "/recalbox/" + dir,
        };

        //if external USB are not hidden
        if(!RecalboxConf::Instance().AsBool(QString("pegasus.external." + dir + ".ignored").toUtf8().constData())){
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
        if(!RecalboxConf::Instance().AsBool(QString("pegasus.internal." + dir + ".ignored").toUtf8().constData())){
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
    }

    return dir_paths;
}

/// Returns the directory paths where videos may be located
QStringList videosDirs(bool forcedRefresh)
{
    static QStringList dir_paths;
    if(forcedRefresh || dir_paths.empty()){
    dir_paths = [](QString dir = "videos"){
        QStringList paths;

        paths.append("/recalbox/share/" + dir);

        //add recalbox share init root in Dirs
        //NO SHARE INIT APPLICABLE IN THIS CASE
        //paths.append("/recalbox/share_init/" + dir);

        // Define an array of directory paths (QStringList is preferred for paths)
        QStringList Paths = {
            "/pixl/" + dir,
            "/" + dir,
            "/recalbox/" + dir,
        };

        //if external USB are not hidden
        if(!RecalboxConf::Instance().AsBool(QString("pegasus.external." + dir + ".ignored").toUtf8().constData())){
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
        if(!RecalboxConf::Instance().AsBool(QString("pegasus.internal." + dir + ".ignored").toUtf8().constData())){
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
    }

    return dir_paths;
}

/// Returns a directory path where persistent data could be stored
QString writableConfigDir()
{
    static const QString config_dir = get_appconfig_dir();
    return config_dir;
}

/// Returns a directory path where cache data could be stored
QString writableCacheDir()
{
    static const QString cache_dir = get_cache_dir();
    return cache_dir;
}

} // namespace paths
