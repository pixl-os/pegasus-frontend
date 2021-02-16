
#include "Recalbox.h"
#include "Log.h"


namespace model {

Recalbox::Recalbox(QObject* parent)
    : QObject(parent)
{
    //mRecalboxConf = RecalboxConf::Instance();
}

bool Recalbox::getBoolParameter(const QString& Parameter)
    {
      return RecalboxConf::Instance().AsBool(Parameter.toUtf8().constData());
    }

void Recalbox::setBoolParameter(const QString& Parameter, const bool& Value)
    {
      RecalboxConf::Instance().SetBool(Parameter.toUtf8().constData(), Value);
    }
QString Recalbox::getStringParameter(const QString& Parameter)
    {
      return QString::fromStdString(RecalboxConf::Instance().AsString(Parameter.toUtf8().constData()));
    }

void Recalbox::setStringParameter(const QString& Parameter, const QString& Value)
    {
      RecalboxConf::Instance().SetString(Parameter.toUtf8().constData(), Value.toUtf8().constData());
    }
    
void Recalbox::saveParameters()
    {
      RecalboxConf::Instance().Save();
      Log::info(LOGMSG("Recalbox.conf saved."));
    }

} // namespace model
