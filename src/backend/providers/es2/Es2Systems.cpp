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


#include "Es2Systems.h"

#include "Log.h"
#include "Paths.h"
#include "RootFolders.h"
#include "utils/Files.h"
#include "utils/Strings.h"

#include "model/gaming/Collection.h"
#include "model/gaming/Game.h"
#include "providers/SearchContext.h"
#include "utils/CommandTokenizer.h"
#include "utils/StdHelpers.h"

#include <QFile>
#include <QFileInfo>
#include <QStringBuilder>
#include <QXmlStreamReader>
#include <array>


namespace {

QString find_systems_xml(const std::vector<QString>& possible_config_dirs)
{
    for (const QString& dir_path : possible_config_dirs) {
        QString xml_path = dir_path + QStringLiteral("es_systems.cfg");
        if (QFileInfo::exists(xml_path))
            return xml_path;
        //add search of new ROMFS V2 systems list
        xml_path = dir_path + QStringLiteral("systemlist.xml");
        if (QFileInfo::exists(xml_path))
            return xml_path;
    }

    return {};
}

HashMap<QLatin1String, QString>::iterator
find_by_str_ref(HashMap<QLatin1String, QString>& map, const QStringRef& str)
{
    HashMap<QLatin1String, QString>::iterator it;
    for (it = map.begin(); it != map.end(); ++it)
        if (it->first == str)
            break;

    return it;
}

void set_by_str(HashMap<QLatin1String, QString>& map, const QString& str, const QString& value)
{
    HashMap<QLatin1String, QString>::iterator it;
    for (it = map.begin(); it != map.end(); ++it)
    {
        if (it->first == str)
        {
            it->second = value;
            break;
        }
    }
}

providers::es2::SystemEntry read_system_entry(const QString& log_tag, QXmlStreamReader& xml,std::vector<providers::es2::CoreInfo>& coreList)
{
    Q_ASSERT(xml.isStartElement() && xml.name() == "system");

    // read all XML fields into a key-value map

    // non-optional properties
    const std::vector<QLatin1String> required_keys {{
            QLatin1String("name"),
                    QLatin1String("path"),
                    QLatin1String("extension"),
                    QLatin1String("command"),
                                                    }};
    
    // all supported properties
    HashMap<QLatin1String, QString> xml_props {
        { QLatin1String("name"), QString() },
        { QLatin1String("fullname"), QString() },
        { QLatin1String("path"), QString() },
        { QLatin1String("extension"), QString() },
        { QLatin1String("command"), QString() },
        { QLatin1String("platform"), QString() },
        { QLatin1String("theme"), QString() },
        { QLatin1String("emulators"), QString() },
    };

    //emulators/emulator attributes
    QList<providers::es2::EmulatorsEntry> SystemEmulators;
    // read
    while (xml.readNextStartElement()) {
        const auto it = find_by_str_ref(xml_props, xml.name());
        if (it != xml_props.end()){
            if (xml.name() == "emulators"){
                while (xml.readNextStartElement()){
                    if (xml.name() == "emulator"){
                        QString emulatorName = xml.attributes().value("name").toString();
                        //Log::debug(log_tag,LOGMSG("Emulateur name: %1").arg(emulatorName));

                        while (xml.readNextStartElement()) {
                            if (xml.name() == "cores"){
                                while (xml.readNextStartElement()) {
                                    if (xml.name() == "core"){
                                        QString corePriority = xml.attributes().value("priority").toString();
                                        QString coreNetplay = "0";
                                        QString coreName = xml.readElementText();
                                        QString coreLongName = "";
                                        QString coreVersion = "";
                                        //Log::debug(log_tag, LOGMSG("Core name/priority: %1/%2").arg(coreName,corePriority));
                                        //For libretro cores only for the moment
                                        if(emulatorName.toLower().contains("libretro")){
                                            for(const providers::es2::CoreInfo& info : coreList){
                                                Log::debug(log_tag, LOGMSG("Core name: %1 - Core Short name found: %2").arg(coreName,QString::fromStdString(info.ShortName())));
                                                if (QString::fromStdString(info.ShortName()) == coreName){
                                                    Log::debug(log_tag, LOGMSG("Core Long Name: %1 - Core version: %2").arg(QString::fromStdString(info.LongName()),QString::fromStdString(info.Version())));
                                                    coreLongName = QString::fromStdString(info.LongName());
                                                    coreVersion = QString::fromStdString(info.Version());
                                                    break;
                                                }
                                            }
                                        }
                                        SystemEmulators.append({ emulatorName, coreName, corePriority.toInt(), coreNetplay.toInt(),coreLongName,coreVersion});
                                    }
                                }
                            }
                        }
                    }
                }
            }
            else{
                QString elementRead = xml.readElementText();
                //Log::debug(log_tag, LOGMSG("System entry : %1").arg(elementRead));
                it->second = elementRead;
            }
        }
        else{
            xml.skipCurrentElement();
        }

    }
    if (xml.error())
        return {};


    // check if all required params are present
    for (const QLatin1String& key : required_keys) {
        if (xml_props[key].isEmpty()) {
            Log::warning(log_tag, LOGMSG("The `<system>` node in `%1` that ends at line %2 has no `<%3>` parameter")
                         .arg(static_cast<QFile*>(xml.device())->fileName(), QString::number(xml.lineNumber()), key));
            return {};
        }
    }

    // do some path formatting
    xml_props[QLatin1String("path")]
            .replace("\\", "/")
            .replace("~", paths::homePath());


    // construct the new platform

    QString fullname = std::move(xml_props[QLatin1String("fullname")]);
    QString shortname = std::move(xml_props[QLatin1String("name")]);

    QString launch_cmd = xml_props[QLatin1String("command")]
            .replace (QLatin1String("%CONTROLLERSCONFIG%"), QLatin1String("{controllers.config}"))
            .replace(QLatin1String("%SYSTEM%"), QLatin1String("{system.shortname}"))
            .replace(QLatin1String("%ROM%"), QLatin1String("{file.path}"))
            .replace(QLatin1String("%ROM_RAW%"), QLatin1String("{file.path}"))
            .replace(QLatin1String("%BASENAME%"), QLatin1String("{file.basename}"))
            .replace(QLatin1String("%EMULATOR%"), QLatin1String("{emulator.name}"))
            .replace(QLatin1String("%CORE%"), QLatin1String("{emulator.core}"))
            .replace(QLatin1String("%RATIO%"), QLatin1String("{emulator.ratio}"))
            .replace(QLatin1String("%NETPLAY%"), QLatin1String("{emulator.netplay}"));

    return {
        fullname.isEmpty() ? shortname : fullname,
                std::move(shortname),
                std::move(xml_props[QLatin1String("path")]),
                std::move(xml_props[QLatin1String("extension")]),
                std::move(xml_props[QLatin1String("platform")]),
                std::move(launch_cmd), // assumed to be absolute
                std::move(SystemEmulators),
    };
}

providers::es2::SystemEntry read_system_entry_v2(const QString& log_tag, QXmlStreamReader& xml, const QString& defaultsCommand,std::vector<providers::es2::CoreInfo>& coreList)
{
    Q_ASSERT(xml.isStartElement() && xml.name() == "system");

    // read all XML fields into a key-value map

    // non-optional properties
    const std::vector<QLatin1String> required_keys {{
            QLatin1String("name"),
                    QLatin1String("path"),
                    QLatin1String("extension"),
                    QLatin1String("command"),
                                                    }};
    
    // all supported properties
    HashMap<QLatin1String, QString> xml_props {
        { QLatin1String("name"), QString() },
        { QLatin1String("fullname"), QString() },
        { QLatin1String("platform"), QString() },
        { QLatin1String("path"), QString() },
        { QLatin1String("extension"), QString() },
        { QLatin1String("command"), QString() },
    };

    //emulators/emulator attributes
    QList< providers::es2::EmulatorsEntry> SystemEmulators;
    
    //read the attributs from <system> and put it in HashMap
    set_by_str(xml_props, "name",xml.attributes().value("name").toString());
    set_by_str(xml_props, "fullname",xml.attributes().value("fullname").toString());
    set_by_str(xml_props, "platform",xml.attributes().value("platforms").toString());

    //just put default command here for future used
    set_by_str(xml_props, "command",defaultsCommand);

    // read
    while (xml.readNextStartElement()) {
        if (xml.name() == "descriptor"){
            //const auto
            set_by_str(xml_props, "path",xml.attributes().value("path").toString());
            set_by_str(xml_props, "extension",xml.attributes().value("extensions").toString());
            xml.skipCurrentElement(); //because not read of element text
        }
        else if (xml.name() == "emulatorList"){
            while (xml.readNextStartElement()){
                if (xml.name() == "emulator"){
                    QString emulatorName = xml.attributes().value("name").toString();
                    //Log::debug(log_tag,LOGMSG("Emulateur name: %1").arg(emulatorName));
                    while (xml.readNextStartElement()) {
                        if (xml.name() == "core"){
                            QString corePriority = xml.attributes().value("priority").toString();
                            QString coreNetplay = xml.attributes().value("netplay").toString();
                            QString coreName = xml.attributes().value("name").toString();
                            QString coreLongName = "";
                            QString coreVersion = "";
                            //Log::debug(log_tag, LOGMSG("Core name/priority: %1/%2").arg(coreName,corePriority));

                            //For libretro cores only for the moment
                            if(emulatorName.contains("libretro",Qt::CaseInsensitive)){
                                for(const providers::es2::CoreInfo& info : coreList){
                                    //Log::debug(log_tag, LOGMSG("Core name: %1 - Core Short name found: %2").arg(coreName,QString::fromStdString(info.ShortName())));
                                    if (QString::fromStdString(info.ShortName()) == coreName){
                                        //Log::debug(log_tag, LOGMSG("Core Long Name: %1 - Core version: %2").arg(QString::fromStdString(info.LongName()),QString::fromStdString(info.Version())));
                                        coreLongName = QString::fromStdString(info.LongName());
                                        coreVersion = QString::fromStdString(info.Version());
                                        break;
                                    }
                                }
                            }
                            //For other cores /  standalone as "citra", "dolphin", "dosbox", "duckstation", "gsplus", "hatari", "hypseus", "mupen64plus", "openbor", "oricutron", "pcsx2", "pcsx_rearmed", "ppsspp", "reicast", "scummvm", "simcoupe", "solarus", "supermodel", "xroar"
                            else{
                                //Log::debug(log_tag,LOGMSG("emulatorName.toLower().toStdString(): '%1' ").arg(emulatorName.toLower()));
                                std::string filepath = "system/configs/" + emulatorName.toLower().toStdString() + ".corenames";
                                //Log::debug(log_tag,LOGMSG("filepath: '%1' ").arg(QString::fromStdString(filepath)));
                                std::string content = Files::LoadFile(RootFolders::DataRootFolder / filepath);

                                for(std::string& line : Strings::Split(content, '\n'))
                                {
                                    Strings::Vector parts = Strings::Split(line, ';');
                                    if (parts.size() == 3){
                                        //Log::debug(log_tag,LOGMSG("Core details: %1;%2;%3").arg(QString::fromStdString(parts[0]),QString::fromStdString(parts[1]),QString::fromStdString(parts[2])));
                                        coreLongName = QString::fromStdString(parts[0]);
                                        coreVersion = QString::fromStdString(parts[2]);                                    }
                                }
                            }

                            SystemEmulators.append({ emulatorName, coreName, corePriority.toInt(), coreNetplay.toInt(), coreLongName, coreVersion});
                            xml.skipCurrentElement(); //because not read of element text
                        }
                    }
                }
            }
        }
        else{
            xml.skipCurrentElement(); //because not read of element text
        }
    }
    if (xml.error())
    {
        Log::debug(log_tag,LOGMSG("xml.error()"));
        return {};
    }
    // check if all required params are present
    for (const QLatin1String& key : required_keys) {
        if (xml_props[key].isEmpty()) {
            Log::warning(log_tag, LOGMSG("The `<system>` node in `%1` that ends at line %2 has no `<%3>` parameter")
                         .arg(static_cast<QFile*>(xml.device())->fileName(), QString::number(xml.lineNumber()), key));
            return {};
        }
    }

    // do some path formatting
    xml_props[QLatin1String("path")]
            .replace("\\", "/")
            .replace("~", paths::homePath())
            .replace("%ROOT%","/recalbox/share/roms");


    // construct the new platform

    QString fullname = std::move(xml_props[QLatin1String("fullname")]);
    QString shortname = std::move(xml_props[QLatin1String("name")]);

    QString launch_cmd = xml_props[QLatin1String("command")]
            .replace (QLatin1String("%CONTROLLERSCONFIG%"), QLatin1String("{controllers.config}"))
            .replace(QLatin1String("%SYSTEM%"), QLatin1String("{system.shortname}"))
            .replace(QLatin1String("%ROM%"), QLatin1String("{file.path}"))
            .replace(QLatin1String("%ROM_RAW%"), QLatin1String("{file.path}"))
            .replace(QLatin1String("%BASENAME%"), QLatin1String("{file.basename}"))
            .replace(QLatin1String("%EMULATOR%"), QLatin1String("{emulator.name}"))
            .replace(QLatin1String("%CORE%"), QLatin1String("{emulator.core}"))
            .replace(QLatin1String("%RATIO%"), QLatin1String("{emulator.ratio}"))
            .replace(QLatin1String("%NETPLAY%"), QLatin1String("{emulator.netplay}"));

    return {
        fullname.isEmpty() ? shortname : fullname,
                std::move(shortname),
                std::move(xml_props[QLatin1String("path")]),
                std::move(xml_props[QLatin1String("extension")]),
                std::move(xml_props[QLatin1String("platform")]),
                std::move(launch_cmd), // assumed to be absolute
                std::move(SystemEmulators),
    };
}

} // namespace


namespace providers {
namespace es2 {


std::vector<SystemEntry> find_systems(const QString& log_tag, const std::vector<QString>& possible_config_dirs)
{
    const QString xml_path = find_systems_xml(possible_config_dirs);
    if (xml_path.isEmpty()) {
        Log::info(log_tag, LOGMSG("No installation found"));
        return {};
    }
    Log::info(log_tag, LOGMSG("Found `%1`").arg(xml_path));

    QFile xml_file(xml_path);
    if (!xml_file.open(QIODevice::ReadOnly)) {
        Log::error(log_tag, LOGMSG("Could not open `%1`").arg(xml_path));
        return {};
    }

    QXmlStreamReader xml(&xml_file);
    if (!xml.readNextStartElement()) {
        Log::error(log_tag, LOGMSG("Could not parse `%1`").arg(xml_path));
        return {};
    }

    if (xml.name() != QLatin1String("systemList")) {
        Log::error(log_tag, LOGMSG("`%1` does not have a `<systemList>` root node").arg(xml_path));
        return {};
    }

    //! Core information list
    std::vector<providers::es2::CoreInfo> mCoreList;
    //read also retroarch cores first to complete info
    std::string content = Files::LoadFile(RootFolders::DataRootFolder / "system/configs/retroarch.corenames");
    for(std::string& line : Strings::Split(content, '\n'))
    {
        Strings::Vector parts = Strings::Split(line, ';');
        if (parts.size() == 3){
            //Log::debug(log_tag,LOGMSG("Core details: %1;%2;%3").arg(QString::fromStdString(parts[0]),QString::fromStdString(parts[1]),QString::fromStdString(parts[2])));
            mCoreList.push_back({ parts[0], parts[1], parts[2] });
        }
    }


    // read all <system> nodes
    std::vector<SystemEntry> systems;
    //Since ROMFS V2, find default as following:
    //<defaults command="python /usr/bin/emulatorlauncher.pyc %CONTROLLERSCONFIG% -system %SYSTEM% -rom %ROM% -emulator %EMULATOR% -core %CORE% -ratio %RATIO% %NETPLAY%"/>
    QString defaultsCommand = "";
    while (xml.readNextStartElement()) {
        QStringRef name = xml.name();
        if (name == QLatin1String("defaults")) {
            //ROMFS V2 file identified
            Log::info(log_tag, LOGMSG("ROMFS V2 xml format Identified"));
            //Get default command
            //TO DO to extract from XML
            defaultsCommand = "python /usr/bin/emulatorlauncher.pyc %CONTROLLERSCONFIG% -system %SYSTEM% -rom %ROM% -emulator %EMULATOR% -core %CORE% -ratio %RATIO% %NETPLAY%";
            xml.skipCurrentElement();
            continue;

        }
        else if (name != QLatin1String("system")) {
            Log::debug(log_tag, LOGMSG("Skip this one: %1").arg(name));
            xml.skipCurrentElement();
            continue;
        }
        providers::es2::SystemEntry sysentry;
        if (defaultsCommand == "") sysentry = read_system_entry(log_tag, xml,mCoreList);
        else sysentry = read_system_entry_v2(log_tag, xml, defaultsCommand,mCoreList);
        if (!sysentry.name.isEmpty())
            systems.emplace_back(std::move(sysentry));
    }
    if (xml.error())
        Log::error(log_tag, xml.errorString());

    return systems;
}

SystemEntry find_system(const QString& log_tag, const std::vector<QString>& possible_config_dirs, const QString shortName)
{
    providers::es2::SystemEntry sysentry;
    const QString xml_path = find_systems_xml(possible_config_dirs);
    if (xml_path.isEmpty()) {
        Log::info(log_tag, LOGMSG("No installation found"));
        return {};
    }
    Log::info(log_tag, LOGMSG("Found `%1`").arg(xml_path));

    QFile xml_file(xml_path);
    if (!xml_file.open(QIODevice::ReadOnly)) {
        Log::error(log_tag, LOGMSG("Could not open `%1`").arg(xml_path));
        return {};
    }

    QXmlStreamReader xml(&xml_file);
    if (!xml.readNextStartElement()) {
        Log::error(log_tag, LOGMSG("Could not parse `%1`").arg(xml_path));
        return {};
    }

    if (xml.name() != QLatin1String("systemList")) {
        Log::error(log_tag, LOGMSG("`%1` does not have a `<systemList>` root node").arg(xml_path));
        return {};
    }

    //! Core information list
    std::vector<providers::es2::CoreInfo> mCoreList;
    //read also retroarch cores first to complete info
    std::string content = Files::LoadFile(RootFolders::DataRootFolder / "system/configs/retroarch.corenames");
    for(std::string& line : Strings::Split(content, '\n'))
    {
        Strings::Vector parts = Strings::Split(line, ';');
        if (parts.size() == 3){
            //Log::debug(log_tag,LOGMSG("Core details: %1;%2;%3").arg(QString::fromStdString(parts[0]),QString::fromStdString(parts[1]),QString::fromStdString(parts[2])));
            mCoreList.push_back({ parts[0], parts[1], parts[2] });
        }
    }

    //Since ROMFS V2, find default as following:
    //<defaults command="python /usr/bin/emulatorlauncher.pyc %CONTROLLERSCONFIG% -system %SYSTEM% -rom %ROM% -emulator %EMULATOR% -core %CORE% -ratio %RATIO% %NETPLAY%"/>
    QString defaultsCommand = "";
    while (xml.readNextStartElement()) {
        QStringRef name = xml.name();
        if (name == QLatin1String("defaults")) {
            //ROMFS V2 file identified
            Log::info(log_tag, LOGMSG("ROMFS V2 xml format Identified"));
            //Get default command
            //TO DO to extract from XML
            defaultsCommand = "python /usr/bin/emulatorlauncher.pyc %CONTROLLERSCONFIG% -system %SYSTEM% -rom %ROM% -emulator %EMULATOR% -core %CORE% -ratio %RATIO% %NETPLAY%";
            xml.skipCurrentElement();
            continue;

        }
        else if (name != QLatin1String("system")) {
            Log::debug(log_tag, LOGMSG("Skip this one: %1").arg(name));
            xml.skipCurrentElement();
            continue;
        }
        if (defaultsCommand == "") sysentry = read_system_entry(log_tag, xml,mCoreList);
        else sysentry = read_system_entry_v2(log_tag, xml, defaultsCommand,mCoreList);
        if ((!sysentry.name.isEmpty()) && (sysentry.platforms == shortName)){
            break; //to get only one system in this case
        }
    }
    if (xml.error())
        Log::error(log_tag, xml.errorString());

    return sysentry;
}


} // namespace es2
} // namespace providers
