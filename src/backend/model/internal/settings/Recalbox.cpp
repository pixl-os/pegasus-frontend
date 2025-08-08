#include "Recalbox.h"
#include "Log.h"

#include "RecalboxBootConf.h"
#include "RecalboxConfOverride.h"

namespace {

QString GetCommandOutput(const std::string& command)
{
	std::string output;
	char buffer[4096];
	FILE* pipe = popen(command.data(), "r");
	if (pipe != nullptr)
	{
	while (feof(pipe) == 0)
	  if (fgets(buffer, sizeof(buffer), pipe) != nullptr)
		output.append(buffer);
	pclose(pipe);
	}
	return QString::fromStdString(output);
}

}

namespace model {

Recalbox::Recalbox(QObject* parent)
    : QObject(parent)
{
//RecalboxConfOverride::Instance() Path will be updated dynamically from loadParametersFromOverride
}

//Override could be for a directory and/or a specific rom
void Recalbox::loadParametersFromOverride(const QString& OverrideFullPath)
{
    bool loaded = RecalboxConfOverride::Instance().LoadFromNewPath(OverrideFullPath.toStdString());
    //Log::debug(LOGMSG("void Recalbox::loadParametersFromOverride() loaded: %1").arg(loaded ? "True" : "False"));
}


void Recalbox::setAudioVolume(int new_val)
{
    if (new_val == RecalboxConf::Instance().GetAudioVolume()){
        return;
    }
    if(RecalboxConf::Instance().AsString("audio.mode") != "none"){
        AudioController::Instance().SetVolume(new_val);
    }
    else AudioController::Instance().SetVolume(0); // to mute in all cases
    RecalboxConf::Instance().SetAudioVolume(new_val);
    emit audioVolumeChanged();
}

void Recalbox::setScreenBrightness(int new_val)
{
    if (new_val == RecalboxConf::Instance().GetScreenBrightness()){
        return;
    }
    //set brightness
    QString brightnessCommand = "timeout 1 sh /recalbox/system/hardware/device/pixl-backlight.sh brightness " + QString::number(new_val);
    int exitcode = system(qPrintable(brightnessCommand));
    RecalboxConf::Instance().SetScreenBrightness(new_val);
    emit screenBrightnessChanged();
}

void Recalbox::setSystemPrimaryScreenEnabled(bool new_val)
{
    if (new_val == RecalboxConf::Instance().GetSystemPrimaryScreenEnabled()){
        return;
    }
    RecalboxConf::Instance().SetSystemPrimaryScreenEnabled(new_val);
    emit systemPrimaryScreenEnabledChanged();
}

void Recalbox::setSystemSecondaryScreenEnabled(bool new_val)
{
    if (new_val == RecalboxConf::Instance().GetSystemSecondaryScreenEnabled()){
        return;
    }
    RecalboxConf::Instance().SetSystemSecondaryScreenEnabled(new_val);
    emit systemSecondaryScreenEnabledChanged();
}

QString Recalbox::getStringParameter(const QString& Parameter, const QString& defaultValue)
{
    if(Parameter.contains("boot.", Qt::CaseInsensitive))
    {
        QString ParameterBoot = Parameter;
        ParameterBoot.replace(QString("boot."), QString(""));
        return QString::fromStdString(RecalboxBootConf::Instance().AsString(ParameterBoot.toUtf8().constData(), defaultValue.toUtf8().constData()));
    }
    else if(Parameter.contains("override.", Qt::CaseInsensitive))
    {
        QString ParameterOverride = Parameter;
        ParameterOverride.replace(QString("override."), QString(""));
        return QString::fromStdString(RecalboxConfOverride::Instance().AsString(ParameterOverride.toUtf8().constData(),
                                                                      RecalboxConf::Instance().AsString(ParameterOverride.toUtf8().constData(), defaultValue.toUtf8().constData())));
    }
    else
    {
        return QString::fromStdString(RecalboxConf::Instance().AsString(Parameter.toUtf8().constData(), defaultValue.toUtf8().constData()));
    }
}

void Recalbox::setStringParameter(const QString& Parameter, const QString& Value)
{
    if(Parameter.contains("boot.", Qt::CaseInsensitive))
    {
        QString ParameterBoot = Parameter;
        ParameterBoot.replace(QString("boot."), QString(""));
        RecalboxBootConf::Instance().SetString(ParameterBoot.toUtf8().constData(), Value.toUtf8().constData());
        RecalboxBootConf::Instance().Save();
    }
    else if(Parameter.contains("override.", Qt::CaseInsensitive))
    {
        QString ParameterOverride = Parameter;
        ParameterOverride.replace(QString("override."), QString(""));
        RecalboxConfOverride::Instance().SetString(ParameterOverride.toUtf8().constData(), Value.toUtf8().constData());
    }
    else
    {
        RecalboxConf::Instance().SetString(Parameter.toUtf8().constData(), Value.toUtf8().constData());
    }
}

bool Recalbox::getBoolParameter(const QString& Parameter, const bool& defaultValue)
{
    if(Parameter.contains("boot.", Qt::CaseInsensitive))
    {
        QString ParameterBoot = Parameter;
        ParameterBoot.replace(QString("boot."), QString(""));
        return RecalboxBootConf::Instance().AsBool(ParameterBoot.toUtf8().constData(),defaultValue);
    }
    else if(Parameter.contains("override.", Qt::CaseInsensitive))
    {
        QString ParameterOverride = Parameter;
        ParameterOverride.replace(QString("override."), QString(""));
        return RecalboxConfOverride::Instance().AsBool(ParameterOverride.toUtf8().constData(),
                                             RecalboxConf::Instance().AsBool(ParameterOverride.toUtf8().constData(),defaultValue));
    }
    else
    {
        return RecalboxConf::Instance().AsBool(Parameter.toUtf8().constData(),defaultValue);
    }
}

void Recalbox::setBoolParameter(const QString& Parameter, const bool& Value)
{
    if(Parameter.contains("boot.", Qt::CaseInsensitive))
    {
        QString ParameterBoot = Parameter;
        ParameterBoot.replace(QString("boot."), QString(""));
        RecalboxBootConf::Instance().SetBool(ParameterBoot.toUtf8().constData(), Value);
        RecalboxBootConf::Instance().Save();
    }
    else if(Parameter.contains("override.", Qt::CaseInsensitive))
    {
        QString ParameterOverride = Parameter;
        ParameterOverride.replace(QString("override."), QString(""));
        RecalboxConfOverride::Instance().SetBool(ParameterOverride.toUtf8().constData(), Value);
    }
    else
    {
        RecalboxConf::Instance().SetBool(Parameter.toUtf8().constData(), Value);
    }
}

int Recalbox::getIntParameter(const QString& Parameter, const int& defaultValue)
{
    if(Parameter.contains("boot.", Qt::CaseInsensitive))
    {
        QString ParameterBoot = Parameter;
        ParameterBoot.replace(QString("boot."), QString(""));
        return RecalboxBootConf::Instance().AsInt(ParameterBoot.toUtf8().constData(),defaultValue);
    }
    else if(Parameter.contains("override.", Qt::CaseInsensitive))
    {
        QString ParameterOverride = Parameter;
        ParameterOverride.replace(QString("override."), QString(""));
        return RecalboxConfOverride::Instance().AsInt(ParameterOverride.toUtf8().constData(),
                                            RecalboxConf::Instance().AsInt(ParameterOverride.toUtf8().constData(),defaultValue));
    }
    else
    {
        return RecalboxConf::Instance().AsInt(Parameter.toUtf8().constData(),defaultValue);
    }
}

void Recalbox::setIntParameter(const QString& Parameter, const int& Value)
{
    if(Parameter.contains("boot.", Qt::CaseInsensitive))
    {
        QString ParameterBoot = Parameter;
        ParameterBoot.replace(QString("boot."), QString(""));
        RecalboxBootConf::Instance().SetInt(ParameterBoot.toUtf8().constData(), Value);
        RecalboxBootConf::Instance().Save();
    }
    else if(Parameter.contains("override.", Qt::CaseInsensitive))
    {
        QString ParameterOverride = Parameter;
        ParameterOverride.replace(QString("override."), QString(""));
        RecalboxConfOverride::Instance().SetInt(ParameterOverride.toUtf8().constData(), Value);
    }
    else
    {
        RecalboxConf::Instance().SetInt(Parameter.toUtf8().constData(), Value);
    }
}

void Recalbox::saveParameters()
{
    RecalboxConf::Instance().Save();
}

void Recalbox::saveParametersInBoot()
{
    RecalboxBootConf::Instance().Save();
}

void Recalbox::saveParametersInOverride()
{
    RecalboxConfOverride::Instance().Save();
}
void Recalbox::reloadParameter(QString parameter) //to relaod parameters from recalbox.conf
{
    //need to identify the parameter to emit the good signal to update the value
    //no other solution found avoiding to reload all parameters except this one
    if(parameter.toLower() == "audio.volume"){
        emit audioVolumeChanged();
    }
    else if(parameter.toLower() == "audio.device"){
        emit audioDeviceChanged();
    }
    else if(parameter.toLower() == "screen.brightness"){
        emit screenBrightnessChanged();
    }
    else if(parameter.toLower() == "system.primary.screen.enabled"){
        emit systemPrimaryScreenEnabledChanged();
    }
    else if(parameter.toLower() == "system.secondary.screen.enabled"){
        emit systemSecondaryScreenEnabledChanged();
    }
}

QString Recalbox::runCommand(const QString& SysCommand, const QStringList& SysOptions)
{
	QString CommandToUpdate = SysCommand;
	//replace from '%1' to '%i' parameters from SysCommand by SysOptions
    if (!SysOptions.empty())
		{
		for(int i = 0; i < SysOptions.count(); i++)
			{
                CommandToUpdate.replace("%"+QString::number(i+1), SysOptions.at(i));
			}
	}
	//launch command using Qprocess to get output
    QString stdout = GetCommandOutput(CommandToUpdate.toUtf8().constData());
    //Log::debug(LOGMSG("GetCommandOutput(CommandToUpdate.toUtf8().constData()): '%1'").arg(stdout));
	return stdout;
}

} // namespace model
