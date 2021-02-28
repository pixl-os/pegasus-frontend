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


#include "Es2Input.h"

#include "Log.h"
#include "Paths.h"

#include "utils/CommandTokenizer.h"
#include "utils/StdHelpers.h"

#include <QFile>
#include <QFileInfo>
#include <QStringBuilder>
#include <QXmlStreamReader>
#include <array>


namespace {

QString find_input_xml(const std::vector<QString>& possible_config_dirs)
{
    //Log::debug(LOGMSG("The possible_config_dirs are '%1'").arg(possible_config_dirs));
    for (const QString& dir_path : possible_config_dirs) {
        //Log::debug(LOGMSG("The dir_path is '%1'").arg(dir_path));
        QString xml_path = dir_path + QStringLiteral("/es_input.cfg");
        //Log::debug(LOGMSG("The xml_path is '%1'").arg(xml_path));
        if (QFileInfo::exists(xml_path))
            return xml_path;
    }

    return {};
}

providers::es2::inputConfigEntry find_input_entry(const QString& log_tag, QXmlStreamReader& xml, const QString& Name, const QString& GUID)
{
    Q_ASSERT(xml.isStartElement() && xml.name() == "inputConfig");

    providers::es2::inputConfigEntry inputEntry;
    
    // read
    while (xml.readNextStartElement()) {
        
        QString deviceName = xml.attributes().value("deviceName").toString();
        QString deviceGUID = xml.attributes().value("deviceGUID").toString();
        
        Log::debug(log_tag, LOGMSG("es_input.cfg - %1 found : %2/%3").arg(xml.name(),deviceName,deviceGUID));
        
        if ((deviceName == Name) && (deviceGUID == GUID)){
            
                inputEntry.inputConfigAttributs.type = xml.attributes().value("type").toString();
                inputEntry.inputConfigAttributs.deviceName = deviceName;
                inputEntry.inputConfigAttributs.deviceGUID = deviceGUID;
                inputEntry.inputConfigAttributs.deviceNbAxes = xml.attributes().value("deviceNbAxes").toString();
                inputEntry.inputConfigAttributs.deviceNbHats = xml.attributes().value("deviceNbHats").toString();
                inputEntry.inputConfigAttributs.deviceNbButtons = xml.attributes().value("deviceNbButtons").toString();
                while (xml.readNextStartElement()){
                    if (xml.name() == "input"){
                        inputEntry.inputAttributs.append({ xml.attributes().value("name").toString()
                                                          ,xml.attributes().value("type").toString()
                                                          ,xml.attributes().value("id").toString()
                                                          ,xml.attributes().value("value").toString()
                                                          , xml.attributes().value("code").toString()});
                        Log::debug(log_tag, LOGMSG("Input name %1 / type %2").arg(xml.attributes().value("name").toString(),xml.attributes().value("type").toString()));
                        QString Text = xml.readElementText();
                    }
                    else{
                        xml.skipCurrentElement();
                    }
                }                    
            }
        else{
            xml.skipCurrentElement();
            }
    }
    if (xml.error())
        return {};

    return {
        std::move(inputEntry),
    };
}
} // namespace

namespace providers {
namespace es2 {

//std::vector<inputConfigEntry> 
providers::es2::inputConfigEntry find_input(const QString& log_tag, const std::vector<QString>& possible_config_dirs, const QString& DeviceName, const QString& DeviceGUID)
{
    const QString xml_path = find_input_xml(possible_config_dirs);
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
    else Log::debug(log_tag, LOGMSG("The XML tag %1 has been found").arg(xml.name()));
        
    if (xml.name() != QLatin1String("inputList")) {
        Log::error(log_tag, LOGMSG("`%1` does not have a `<inputList>` root node").arg(xml_path));
        return {};
    }

    providers::es2::inputConfigEntry inputentry = find_input_entry(log_tag, xml, DeviceName, DeviceGUID);
    if (xml.error())
        Log::error(log_tag, xml.errorString());

    return inputentry;
}

} // namespace es2
} // namespace providers
