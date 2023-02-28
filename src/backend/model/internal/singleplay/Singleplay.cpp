// Pegasus Frontend
//
// Created by Bozo The Geek - 28/12/2021
//

#include "Singleplay.h"

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
    providers::es2::SystemEntry sysentry = Provider->find_one_system(shortName);
	
	//TO DO
	//Add way to add a game unitary in a collection

/*     if(sysentry.platforms == shortName){ //system found
       //set entry for this game
        m_game
            .setLaunchCmd(sysentry.launch_cmd)
            .setSystemShortname(sysentry.shortname);

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
    } */
}

} // namespace model
