#include "Log.h"
#include "RecalboxConf.h"
#include <utils/Files.h>
//#include <usernotifications/NotificationManager.h>

static Path recalboxConfFile("/recalbox/share/system/recalbox.conf");
static Path recalboxConfFileInit("/recalbox/share_init/system/recalbox.conf");

RecalboxConf::RecalboxConf()
  : IniFile(recalboxConfFile, recalboxConfFileInit),
    StaticLifeCycleControler<RecalboxConf>("RecalboxConf")
{
    Log::debug(LOGMSG("Recalbox.conf instance created."));
}

void RecalboxConf::OnSave()
{
    Log::debug(LOGMSG("Recalbox.conf saved."));
  //NotificationManager::Instance().Notify(Notification::ConfigurationChanged, recalboxConfFile.ToString());
}

