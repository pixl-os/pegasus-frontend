
#include "Recalbox.h"


namespace model {

Recalbox::Recalbox(QObject* parent)
    : QObject(parent)
    , m_RecalboxBootConf(Path("/boot/recalbox-boot.conf"))
{
}

QString Recalbox::getStringParameter(const QString& Parameter)
{
    if(Parameter.contains("boot.", Qt::CaseInsensitive))
    {
        QString ParameterBoot = Parameter;
        ParameterBoot.replace(QString("boot."), QString(""));
        return QString::fromStdString(m_RecalboxBootConf.AsString(ParameterBoot.toUtf8().constData()));
    }
    else
    {
        return QString::fromStdString(RecalboxConf::Instance().AsString(Parameter.toUtf8().constData()));
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

bool Recalbox::getBoolParameter(const QString& Parameter)
{
    if(Parameter.contains("boot.", Qt::CaseInsensitive))
    {
        QString ParameterBoot = Parameter;
        ParameterBoot.replace(QString("boot."), QString(""));
        return m_RecalboxBootConf.AsBool(ParameterBoot.toUtf8().constData());
    }
    else
    {
        return RecalboxConf::Instance().AsBool(Parameter.toUtf8().constData());
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

        /********************* realtime action linked to any parameter (to avoid to create a new api just for that :-(***************/
        if(Parameter == "audio.volume")
        {
            //change audio volume as proposed
            if(RecalboxConf::Instance().AsString("audio.mode") != "none") AudioController::Instance().SetVolume(Value);
            else AudioController::Instance().SetVolume(0); // to mute in all cases
        }
    }
}

void Recalbox::saveParameters()
{
    RecalboxConf::Instance().Save();
}

} // namespace model
