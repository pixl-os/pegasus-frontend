// Pegasus Frontend

#include "Es2Input.h"

#include "Log.h"
#include <QFileInfo>
#include <QStringBuilder>
#include <QXmlStreamReader>
#include <QTextStream>
#include <array>

namespace {

QString input_xml(const std::vector<QString>& possible_config_dirs)
{
    for (const QString& dir_path : possible_config_dirs) {
        QString xml_path = dir_path + QStringLiteral("input.cfg");
        if (QFileInfo::exists(xml_path))
            return xml_path;
    }

    return {};
}

//to get existing one from GUID (especially for fresh install)
providers::es2::inputConfigEntry find_any_input_entry_by_guid(const QString& log_tag, QXmlStreamReader& xml, const QString& GUID)
{
    Q_ASSERT(xml.isStartElement() && (xml.name() == "inputList"));
    
    providers::es2::inputConfigEntry inputConfigEntry;
    
    // read
    while (xml.readNextStartElement()) {
        
        QString deviceName = xml.attributes().value("deviceName").toString();
        QString deviceGUID = xml.attributes().value("deviceGUID").toString();
        
        if ((deviceGUID == GUID)){
            
                inputConfigEntry.inputConfigAttributs.type = xml.attributes().value("type").toString();
                inputConfigEntry.inputConfigAttributs.deviceName = deviceName;
                inputConfigEntry.inputConfigAttributs.deviceGUID = deviceGUID;
                inputConfigEntry.inputConfigAttributs.deviceNbAxes = xml.attributes().value("deviceNbAxes").toString();
                inputConfigEntry.inputConfigAttributs.deviceNbHats = xml.attributes().value("deviceNbHats").toString();
                inputConfigEntry.inputConfigAttributs.deviceNbButtons = xml.attributes().value("deviceNbButtons").toString();
                //device layout (optional)
                inputConfigEntry.inputConfigAttributs.deviceLayout = xml.attributes().value("deviceLayout").toString();
                while (xml.readNextStartElement()){
                    if (xml.name() == "input"){
                        inputConfigEntry.inputElements.append({ xml.attributes().value("name").toString()
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
        inputConfigEntry,
    };
}

//to get input by his GUID and Name (by this way, we could have several configuration for the same pad ;-)
providers::es2::inputConfigEntry find_input_entry(const QString& log_tag, QXmlStreamReader& xml, const QString& Name, const QString& GUID)
{
    Q_ASSERT(xml.isStartElement() && (xml.name() == "inputList"));
    
    providers::es2::inputConfigEntry inputConfigEntry;
    
    // read
    while (xml.readNextStartElement()) {
        
        QString deviceName = xml.attributes().value("deviceName").toString();
        QString deviceGUID = xml.attributes().value("deviceGUID").toString();
        
        if (((deviceName == Name) || (Name == "")) && (deviceGUID == GUID)){
            
                inputConfigEntry.inputConfigAttributs.type = xml.attributes().value("type").toString();
                inputConfigEntry.inputConfigAttributs.deviceName = deviceName;
                inputConfigEntry.inputConfigAttributs.deviceGUID = deviceGUID;
                inputConfigEntry.inputConfigAttributs.deviceNbAxes = xml.attributes().value("deviceNbAxes").toString();
                inputConfigEntry.inputConfigAttributs.deviceNbHats = xml.attributes().value("deviceNbHats").toString();
                inputConfigEntry.inputConfigAttributs.deviceNbButtons = xml.attributes().value("deviceNbButtons").toString();
                //device layout (optional)
                inputConfigEntry.inputConfigAttributs.deviceLayout = xml.attributes().value("deviceLayout").toString();
                while (xml.readNextStartElement()){
                    if (xml.name() == "input"){
                        inputConfigEntry.inputElements.append({ xml.attributes().value("name").toString()
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
        inputConfigEntry,
    };
}

bool add_input_entry(const QString& log_tag, QFile& xml_file, const providers::es2::inputConfigEntry& input_to_save)
{
    //open xml file to read content and create XML DOM object
    if (!xml_file.open(QIODevice::ReadOnly))
    {
        Log::debug(log_tag, LOGMSG("Problem to open input.cfg in readonly"));
        return false;
    }    
    QDomDocument doc;
    if (!doc.setContent(&xml_file))
    {
        Log::debug(log_tag, LOGMSG("Problem to set DOM content to add input in input.cfg"));
        return false;
    }
    xml_file.close();
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
    
    //device layout (optional)
    QDomAttr deviceLayout = doc.createAttribute(QString("deviceLayout"));
    deviceLayout.setValue(input_to_save.inputConfigAttributs.deviceLayout);
    inputConfig.setAttributeNode(deviceLayout);

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

    if(inputList.appendChild(inputConfig).isNull())
    {
        Log::error(log_tag, LOGMSG("Problem to add in input.cfg using new inputConfig"));
        return false;
    }

    if(!xml_file.open(QIODevice::WriteOnly | QIODevice::Truncate))
    {
        Log::debug(log_tag, LOGMSG("Problem to open input.cfg in WriteOnly|Truncate"));
        return false;
    }
    QTextStream out(&xml_file);
    doc.save(out, 4);
    xml_file.close();

    return true;
}

bool update_input_entry(const QString& log_tag, QFile& xml_file, const providers::es2::inputConfigEntry& input_to_save)
{
    //open xml file to read content and create XML DOM object
    if (!xml_file.open(QIODevice::ReadOnly))
    {
        Log::debug(log_tag, LOGMSG("Problem to open input.cfg in readonly"));
        return false;
    }    
    QDomDocument doc;
    if (!doc.setContent(&xml_file))
    {
        Log::debug(log_tag, LOGMSG("Problem to set DOM content to add input in input.cfg"));
        return false;
    }
    xml_file.close();
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
    
    //find old child
    QDomElement oldInputConfig;
    QDomNode n = inputList.firstChild();
    while (!n.isNull()) {
        if (n.isElement()) {
            QDomElement e = n.toElement();
            if (e.tagName() == "inputConfig")
            {
                if((e.attribute("deviceName") == input_to_save.inputConfigAttributs.deviceName) && (e.attribute("deviceGUID") == input_to_save.inputConfigAttributs.deviceGUID))
                {
                    Log::warning(log_tag, LOGMSG("previous input config found for %1/%2").arg(input_to_save.inputConfigAttributs.deviceName,input_to_save.inputConfigAttributs.deviceGUID));
                    oldInputConfig = e;
                    break;
                }
            }
        }
    n = n.nextSibling();
    }
    
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

    //device layout (optional)
    QDomAttr deviceLayout = doc.createAttribute(QString("deviceLayout"));
    deviceLayout.setValue(input_to_save.inputConfigAttributs.deviceLayout);
    inputConfig.setAttributeNode(deviceLayout);
    
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
    
    if(inputList.replaceChild(inputConfig,oldInputConfig).isNull())
    {
        Log::error(log_tag, LOGMSG("Problem to update input.cfg using new inputConfig"));
        return false;
    }

    if(!xml_file.open(QIODevice::WriteOnly | QIODevice::Truncate))
    {
        Log::error(log_tag, LOGMSG("Problem to open input.cfg in WriteOnly|Truncate"));
        return false;
    }
    QTextStream out(&xml_file);
    doc.save(out, 4);
    xml_file.close();

    return true;
}

} // namespace

namespace providers {
namespace es2 {

inputConfigEntry find_any_input_by_guid(const QString& log_tag, const std::vector<QString>& possible_config_dirs, const QString& DeviceGUID)
{
    const QString xml_path = input_xml(possible_config_dirs);
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

    providers::es2::inputConfigEntry inputentry = find_any_input_entry_by_guid(log_tag, xml, DeviceGUID);
    if (xml.error())
        Log::error(log_tag, xml.errorString());
    xml_file.close();
    
    if (inputentry.inputConfigAttributs.deviceGUID != DeviceGUID)
    {
        Log::error(log_tag, LOGMSG("input configuration with GUID:%1 not found from input.cfg").arg(inputentry.inputConfigAttributs.deviceGUID));
    }
    else
    {
        Log::info(log_tag, LOGMSG("%1 input configuration found from input.cfg").arg(inputentry.inputConfigAttributs.deviceName));
    }

    return inputentry;

}



inputConfigEntry find_input(const QString& log_tag, const std::vector<QString>& possible_config_dirs, const QString& DeviceName, const QString& DeviceGUID)
{
    const QString xml_path = input_xml(possible_config_dirs);
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
    
    if (inputentry.inputConfigAttributs.deviceGUID != DeviceGUID)
    {
        Log::error(log_tag, LOGMSG("%1/'%2' input configuration not found from input.cfg").arg(DeviceGUID,DeviceName));
    }
    else
    {
        Log::info(log_tag, LOGMSG("%1/'%2' input configuration found from input.cfg").arg(inputentry.inputConfigAttributs.deviceGUID,inputentry.inputConfigAttributs.deviceName));
    }

    return inputentry;

}

bool save_input(const QString& log_tag, const std::vector<QString>& possible_config_dirs, const inputConfigEntry& input_to_save)
{
    const QString xml_path = input_xml(possible_config_dirs);
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
    {//to update any entry in input.cfg
        if(!add_input_entry(log_tag, xml_file, input_to_save))
        {
            Log::error(log_tag, LOGMSG("`%1` can't be added to input.cfg").arg(input_to_save.inputConfigAttributs.deviceName));
            return false;
        }
    }
    else
    {//to update any entry in input.cfg
        if(!update_input_entry(log_tag, xml_file, input_to_save))
        {
            Log::error(log_tag, LOGMSG("`%1` can't be updated from input.cfg").arg(input_to_save.inputConfigAttributs.deviceName));
            return false;
        }
        
    }

    return true;
}

} // namespace es2
} // namespace providers
