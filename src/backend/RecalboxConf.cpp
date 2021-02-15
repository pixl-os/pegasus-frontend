#include "RecalboxConf.h"
#include <utils/Files.h>
//#include <usernotifications/NotificationManager.h>

static Path recalboxConfFile("/recalbox/share/system/recalbox.conf");
static Path recalboxConfFileInit("/recalbox/share_init/system/recalbox.conf");

RecalboxConf::RecalboxConf()
  : IniFile(recalboxConfFile, recalboxConfFileInit),
    StaticLifeCycleControler<RecalboxConf>("RecalboxConf")
{
}

void RecalboxConf::OnSave()
{
  //NotificationManager::Instance().Notify(Notification::ConfigurationChanged, recalboxConfFile.ToString());
}

