#include "Log.h"
#include "RecalboxConf.h"
#include <utils/Files.h>

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
    Log::info(LOGMSG("recalbox.conf file saved."));
}

