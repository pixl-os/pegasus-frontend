// Pegasus Frontend
//
// Created by Bozo The Geek - 28/12/2021
//

#include "Singleplay.h"

#include "Log.h"

namespace {
//section to add local private function
} // namespace

namespace model {
Singleplay::Singleplay(QObject* parent)
    : QObject(parent)
{
    //put initialization of es2 provider
    Provider = new providers::es2::Es2Provider();
}

void Singleplay::setSystem (const QString shortName){
    //Log::debug(LOGMSG("shortName : %1").arg(shortName));
    providers::es2::SystemEntry sysentry = Provider->find_one_system(shortName);
    //Log::debug(LOGMSG("sysentry.shortname : %1").arg(sysentry.shortname));

    //Way added to manage a game without collection
     if(sysentry.shortname == shortName){ //system found
       //set entry for this game
        m_game
            .setLaunchCmd(sysentry.launch_cmd)
            .setLaunchWorkdir("/recalbox/share/roms/" + sysentry.shortname)
            .setLaunchCmdBasedir(" ")
            .setSystemManufacturer(sysentry.manufacturer)
            .setSystemShortName(sysentry.shortname)
            .setSystemName(sysentry.name);
        //To take into account priority=1 (or lower value) as default emulator and core
        int first_priority = 0;
        for (int n = 0;n < sysentry.emulators.count(); n++)
        {
            //if only one or to initialize with one value
            if (n == 0)
            {   first_priority = sysentry.emulators[n].priority;
                m_game
                    .setEmulatorName(sysentry.emulators[n].name)
                    .setEmulatorCore(sysentry.emulators[n].core);
            }
            else if(first_priority > sysentry.emulators[n].priority) //else we check if previous priority is lower (but number is higher ;-)
            {
                first_priority = sysentry.emulators[n].priority;
                m_game
                    .setEmulatorName(sysentry.emulators[n].name)
                    .setEmulatorCore(sysentry.emulators[n].core);
            }
        }
    }
}

//needed to know where to store the "save/ram" file using libretro (retroarch)
Q_INVOKABLE QString Singleplay::getEmulatorName(){
    return m_game.emulatorName();
}

//needed to know where to store the "save/ram" file using retroarch
Q_INVOKABLE QString Singleplay::getCoreLongName(){
    //Log::debug(LOGMSG("shortName : %1").arg(m_game.systemShortName()));
    providers::es2::SystemEntry sysentry = Provider->find_one_system(m_game.systemShortName());
    //Log::debug(LOGMSG("sysentry.shortname : %1").arg(sysentry.shortname));

    //Way added to manage a game without collection
    QString CoreLongName = "";
    if(sysentry.shortname == m_game.systemShortName()){ //system found
        //To take into account priority=1 (or lower value) as default emulator and core
        int first_priority = 0;
        for (int n = 0;n < sysentry.emulators.count(); n++)
        {
            //if only one or to initialize with one value
            if (n == 0)
            {
                first_priority = sysentry.emulators[n].priority;
                CoreLongName = sysentry.emulators[n].corelongname;
            }
            else if(first_priority > sysentry.emulators[n].priority) //else we check if previous priority is lower (but number is higher ;-)
            {
                first_priority = sysentry.emulators[n].priority;
                CoreLongName = sysentry.emulators[n].corelongname;
            }
        }
    }
    return CoreLongName;
}

} // namespace model
