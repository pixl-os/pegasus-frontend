// Pegasus Frontend
//
// Created by Bozo The Geek - 02/01/2022
//
#include "Updates.h"

namespace {

} // namespace


namespace model {
Updates::Updates(QObject* parent)
    : QObject(parent)
{
}

//Asynchronous function to get last version in background tasts from repo and store it in /tmp
void Updates::getRepoInfo(const QString componentName, const QString repoUrl){

}
//function to check if any updates is available using /tmp
bool Updates::hasAnyUpdate(){
    return true;
}

//function to check information about updates of any componants and confirm quickly if update using /tmp
bool Updates::hasUpdate(const QString componentName, const bool betaIncluded){

}
//function to get details from last "available" update (and only if available)
UpdateEntry Updates::updateDetails(const QString componentName){
    UpdateEntry myEntry;
    myEntry.m_componentName = "test";
    return myEntry;
}
//function to return the number of version available
int Updates::componentVersionsCount(const QString componentName){

}
//function to get any version details using index
UpdateEntry Updates::componentVersionDetails(const QString componentName, const int index){

}
//Asynchronous function to install a component
void Updates::launchComponentInstallation(const QString componentName, const QString version){

}

//Function to know status - as "Download", "Installation", "Completed" or "error"
QString Updates::getInstallationStatus(const QString componentName){
}

//Fucntion to know progress of each installation steps
int Updates::getInstallationProgress(const QString componentName){

} //provide pourcentage of downlaod and installation


} // namespace model
