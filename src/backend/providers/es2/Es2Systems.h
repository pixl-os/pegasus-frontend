// Pegasus Frontend
// Copyright (C) 2017-2020  Mátyás Mustoha
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


#pragma once

#include <QString>
#include <QList>
#include <vector>

namespace providers {
namespace es2 {

struct EmulatorsEntry {
    QString name;
    QString core;
    int priority;
    int netplay;
    QString corelongname; //now available from all .corenames files
    QString coreversion; //now available from all .corenames files
    QString coreextensions;
    QString corecompatibility;
    QString corespeed;
};

//! Immutable core information from retroarch only
struct CoreInfo
{
  private:
    //! Long name (i.e. "MAME 2003-Plus")
    std::string mLongName;
    //! Short name (i.e. "mame2003+")
    std::string mShortName;
    //! Version
    std::string mVersion;

  public:
    CoreInfo(const std::string& longName, const std::string& shortName, const std::string& version)
      : mLongName(longName)
      , mShortName(shortName)
      , mVersion(version)
    {
    }

    CoreInfo() = default;

    //! Long name
    const std::string& LongName() const { return mLongName; }
    //! Short name
    const std::string& ShortName() const { return mShortName; }
    //! Version
    const std::string& Version() const { return mVersion; }
    //! Empty?
    bool Empty() const { return mLongName.empty(); }
};

struct SystemEntry {
    QString name;
    QString shortname;
    QString path;
    QString extensions;
    QString platforms; // seems depreacted soon from recalbox 8.1.X
    QString launch_cmd;
    QString icon;
    QString screenscraper;
    QString type;
    QString pad;
    QString keyboard;
    QString mouse;
    QString lightgun;
    QString releasedate;
    QString retroachievements;
    QList <EmulatorsEntry> emulators;
};

std::vector<SystemEntry> find_systems(const QString&, const std::vector<QString>&);
SystemEntry find_system(const QString& log_tag, const std::vector<QString>& possible_config_dirs, const QString shortName);

} // namespace es2
} // namespace providers
