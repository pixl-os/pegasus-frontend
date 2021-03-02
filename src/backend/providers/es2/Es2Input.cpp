// Pegasus Frontend

#include "Es2Input.h"

#include "Log.h"
#include "Paths.h"

#include "utils/CommandTokenizer.h"
#include "utils/StdHelpers.h"


#include <QFileInfo>
#include <QStringBuilder>
#include <QXmlStreamReader>
#include <QTextStream>
#include <array>

namespace {

QString es_input_xml(const std::vector<QString>& possible_config_dirs)
{
    //Log::debug(LOGMSG("The possible_config_dirs are '%1'").arg(possible_config_dirs));
    for (const QString& dir_path : possible_config_dirs) {
        //Log::debug(LOGMSG("The dir_path is '%1'").arg(dir_path));
        QString xml_path = dir_path + QStringLiteral("es_input.cfg");
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
        
        //Log::debug(log_tag, LOGMSG("es_input.cfg - %1 found : %2/%3").arg(xml.name(),deviceName,deviceGUID));
        
        if ((deviceName == Name) && (deviceGUID == GUID)){
            
                inputEntry.inputConfigAttributs.type = xml.attributes().value("type").toString();
                inputEntry.inputConfigAttributs.deviceName = deviceName;
                inputEntry.inputConfigAttributs.deviceGUID = deviceGUID;
                inputEntry.inputConfigAttributs.deviceNbAxes = xml.attributes().value("deviceNbAxes").toString();
                inputEntry.inputConfigAttributs.deviceNbHats = xml.attributes().value("deviceNbHats").toString();
                inputEntry.inputConfigAttributs.deviceNbButtons = xml.attributes().value("deviceNbButtons").toString();
                while (xml.readNextStartElement()){
                    if (xml.name() == "input"){
                        inputEntry.inputElements.append({ xml.attributes().value("name").toString()
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

bool add_input_entry(const QString& log_tag, QFile& xml_file, const providers::es2::inputConfigEntry& input_to_save)
{
    //open xml file to read content and create XML DOM object
    if (!xml_file.open(QIODevice::ReadOnly))
    {
        Log::debug(log_tag, LOGMSG("Problem to open es_input.cfg in readonly"));
        return false;
    }    
    QDomDocument doc;
    if (!doc.setContent(&xml_file))
    {
        Log::debug(log_tag, LOGMSG("Problem to set DOM content to add input in es_input.cfg"));
        return false;
    }
// <?xml version="1.0"?>
// <inputList>
	// <inputConfig type="keyboard" deviceName="Keyboard" deviceGUID="-1" deviceNbAxes="0" deviceNbHats="0" deviceNbButtons="120">
		// <input name="a" type="key" id="115" value="1" code="168" />
		// <input name="b" type="key" id="97" value="1" code="168" />
		// <input name="down" type="key" id="1073741905" value="1" code="168" />
		// <input name="hotkey" type="key" id="32" value="1" code="168" />
		// <input name="left" type="key" id="1073741904" value="1" code="168" />
		// <input name="pagedown" type="key" id="1073741902" value="1" code="168" />
		// <input name="pageup" type="key" id="1073741899" value="1" code="168" />
		// <input name="right" type="key" id="1073741903" value="1" code="168" />
		// <input name="select" type="key" id="32" value="1" code="168" />
		// <input name="start" type="key" id="13" value="1" code="168" />
		// <input name="up" type="key" id="1073741906" value="1" code="168" />
	// </inputConfig>
// </inputList>
    
    QDomElement inputList = doc.documentElement();  // as root

    QDomElement inputConfig = doc.createElement(QString("inputConfig"));

    QDomAttr type = doc.createAttribute(QString("type"));
    type.setValue(input_to_save.inputConfigAttributs.type);
    inputConfig.setAttributeNode(type);
    
    QDomAttr deviceName = doc.createAttribute(QString("deviceName"));
    deviceName.setValue(input_to_save.inputConfigAttributs.deviceName);
    inputConfig.setAttributeNode(deviceName);
    
    QDomAttr deviceGUID = doc.createAttribute(QString("deviceGUID"));
    deviceGUID.setValue(input_to_save.inputConfigAttributs.deviceGUID);
    inputConfig.setAttributeNode(deviceGUID);

    QDomAttr deviceNbAxes = doc.createAttribute(QString("deviceNbAxes"));
    deviceNbAxes.setValue(input_to_save.inputConfigAttributs.deviceNbAxes);
    inputConfig.setAttributeNode(deviceNbAxes);

    QDomAttr deviceNbHats = doc.createAttribute(QString("deviceNbHats"));
    deviceNbHats.setValue(input_to_save.inputConfigAttributs.deviceNbHats);
    inputConfig.setAttributeNode(deviceNbHats);

    QDomAttr deviceNbButtons = doc.createAttribute(QString("deviceNbButtons"));
    deviceNbButtons.setValue(input_to_save.inputConfigAttributs.deviceNbButtons);
    inputConfig.setAttributeNode(deviceNbButtons);
    
    for (int idx = 0; idx < input_to_save.inputElements.size(); idx++) {
        QDomElement input = doc.createElement(QString("input"));
        
        QDomAttr name = doc.createAttribute(QString("name"));
        name.setValue(input_to_save.inputElements.at(idx).name);
        input.setAttributeNode(name);

        QDomAttr type = doc.createAttribute(QString("type"));
        type.setValue(input_to_save.inputElements.at(idx).type);
        input.setAttributeNode(type);
        
        QDomAttr id = doc.createAttribute(QString("id"));
        id.setValue(input_to_save.inputElements.at(idx).id);
        input.setAttributeNode(id);

        QDomAttr value = doc.createAttribute(QString("value"));
        value.setValue(input_to_save.inputElements.at(idx).value);
        input.setAttributeNode(value);

        QDomAttr code = doc.createAttribute(QString("code"));
        code.setValue(input_to_save.inputElements.at(idx).code);
        input.setAttributeNode(code);

        inputConfig.appendChild(input);
    }
    inputList.appendChild(inputConfig);

    if(!xml_file.open(QIODevice::WriteOnly | QIODevice::Truncate))
    {
        Log::debug(log_tag, LOGMSG("Problem to open es_input.cfg in WriteOnly|Truncate"));
        return false;
    }
    QTextStream out(&xml_file);
    doc.save(out, 4);
    xml_file.close();

    return true;
}

bool update_input_entry(const QString& log_tag, QFile& xml_file, const providers::es2::inputConfigEntry& input_to_save)
{
    //TO DO
    return false; // return as fault for the moment
}


} // namespace

namespace providers {
namespace es2 {

inputConfigEntry find_input(const QString& log_tag, const std::vector<QString>& possible_config_dirs, const QString& DeviceName, const QString& DeviceGUID)
{
    const QString xml_path = es_input_xml(possible_config_dirs);
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
    xml_file.close();
    return inputentry;
}

bool save_input(const QString& log_tag, const std::vector<QString>& possible_config_dirs, const inputConfigEntry& input_to_save)
{
    const QString xml_path = es_input_xml(possible_config_dirs);
    if (xml_path.isEmpty()) {
        Log::info(log_tag, LOGMSG("No installation found"));
        return false;
    }
    Log::info(log_tag, LOGMSG("Found `%1`").arg(xml_path));

    QFile xml_file(xml_path);
    if (!xml_file.open(QIODevice::ReadOnly)) {
        Log::error(log_tag, LOGMSG("Could not open `%1`").arg(xml_path));
        return false;
    }

    QXmlStreamReader xml(&xml_file);
    if (!xml.readNextStartElement()) {
        Log::error(log_tag, LOGMSG("Could not parse `%1`").arg(xml_path));
        return false;
    }
    else Log::debug(log_tag, LOGMSG("The XML tag %1 has been found").arg(xml.name()));
        
    if (xml.name() != QLatin1String("inputList")) {
        Log::error(log_tag, LOGMSG("`%1` does not have a `<inputList>` root node").arg(xml_path));
        return false;
    }

    providers::es2::inputConfigEntry inputentry = find_input_entry(log_tag, xml, input_to_save.inputConfigAttributs.deviceName, input_to_save.inputConfigAttributs.deviceGUID);
    if (xml.error())
        Log::error(log_tag, xml.errorString());
    xml_file.close();// close file before to add inputs
        
    if (inputentry.inputConfigAttributs.deviceName != input_to_save.inputConfigAttributs.deviceName)
    {//to update any entry in es_input.cfg
        if(!add_input_entry(log_tag, xml_file, input_to_save))
        {
            Log::error(log_tag, LOGMSG("`%1` can't be added to es_input.cfg").arg(input_to_save.inputConfigAttributs.deviceName)); 
            return false;
        }
    }
    else
    {//to update any entry in es_input.cfg
        if(!update_input_entry(log_tag, xml_file, input_to_save))
        {
            Log::error(log_tag, LOGMSG("`%1` can't be updated from es_input.cfg").arg(input_to_save.inputConfigAttributs.deviceName)); 
            return false;
        }
        
    }

    return true;
}

} // namespace es2
} // namespace providers
