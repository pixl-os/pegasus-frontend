#include "Recalbox.h"
#include "Log.h"

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
    , m_RecalboxBootConf(Path("/boot/recalbox-boot.conf"))
{

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

QString Recalbox::getStringParameter(const QString& Parameter, const QString& defaultValue)
{
    if(Parameter.contains("boot.", Qt::CaseInsensitive))
    {
        QString ParameterBoot = Parameter;
        ParameterBoot.replace(QString("boot."), QString(""));
        return QString::fromStdString(m_RecalboxBootConf.AsString(ParameterBoot.toUtf8().constData(), defaultValue.toUtf8().constData()));
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
        m_RecalboxBootConf.SetString(ParameterBoot.toUtf8().constData(), Value.toUtf8().constData());
        m_RecalboxBootConf.Save();
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
        return m_RecalboxBootConf.AsBool(ParameterBoot.toUtf8().constData(),defaultValue);
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
        m_RecalboxBootConf.SetBool(ParameterBoot.toUtf8().constData(), Value);
        m_RecalboxBootConf.Save();
    }
    else
    {
        RecalboxConf::Instance().SetBool(Parameter.toUtf8().constData(), Value);
    }
}

int Recalbox::getIntParameter(const QString& Parameter)
{
    if(Parameter.contains("boot.", Qt::CaseInsensitive))
    {
        QString ParameterBoot = Parameter;
        ParameterBoot.replace(QString("boot."), QString(""));
        return m_RecalboxBootConf.AsInt(ParameterBoot.toUtf8().constData());
    }
    else
    {
        return RecalboxConf::Instance().AsInt(Parameter.toUtf8().constData());
    }
}

void Recalbox::setIntParameter(const QString& Parameter, const int& Value)
{
    if(Parameter.contains("boot.", Qt::CaseInsensitive))
    {
        QString ParameterBoot = Parameter;
        ParameterBoot.replace(QString("boot."), QString(""));
        m_RecalboxBootConf.SetInt(ParameterBoot.toUtf8().constData(), Value);
        m_RecalboxBootConf.Save();
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

void Recalbox::reloadParameter(QString parameter) //to relaod parameters from recalbox.conf
{
    //need to identify the parameter to emit the good signal to update the value
    //no other solution found avoiding to reload all parameters except this one
    if(parameter.toLower() == "audio.volume"){
        emit audioVolumeChanged();
    }
    else if(parameter.toLower() == "screen.brightness"){
        emit screenBrightnessChanged();
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
    Log::debug(LOGMSG("GetCommandOutput(CommandToUpdate.toUtf8().constData()): '%1'").arg(stdout));
	return stdout;
}

} // namespace model
