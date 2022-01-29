// Pegasus Frontend
//
// Created by Bozo The Geek - 02/01/2022
//
#include "Updates.h"
#include "Log.h"

//for network
#include <QNetworkAccessManager>
#include <QNetworkReply>
#include <QNetworkRequest>
#include <QSslSocket>

//for file
#include <QFile>
#include <QFileInfo>

//for json parsing
#include <QJsonArray>
#include <QJsonDocument>
#include <QJsonObject>

//for event/timer
#include <QEventLoop>
#include <QElapsedTimer>

namespace {

bool isNewVersion(QList<int> existingVersionNumbers, QList<int> newVersionNumbers){

    //iteration from new version, to manage case as : 1.0 -> 1.0.1
    // but we could manage also: 1.0.1 -> 1.1 or 2.0
    for(int i=0; i < newVersionNumbers.count();i++){
        if(i < existingVersionNumbers.count()){
            if(existingVersionNumbers.at(i) < newVersionNumbers.at(i)){
                return true;
            }
            else if(existingVersionNumbers.at(i) > newVersionNumbers.at(i)){
                return false; //to avoid to consider new if 0.0.1 -> 0.0.0.1
            }
        }
        else return true; // also if we have 2.0 -> 2.0.0
    }
    //if no new version detected
    return false;
}

//function to extract version from any string
QList<int> getVersionNumbers(const QString versionString){
    //folloxing this rules
    //version should start by '-v' (lower case)
    //finish by '-' or nothing
    //as following String examples and QList<int> results:
    // 'pixl-edition-v0.0.1' -> [0,0,1]
    // 'pixl-edition-v0.0.1-45-g6928bd092' -> [0,0,1]
    // 'mame-v0.238' -> [0,238]
    // 'mame-v237' -> [237]
    // 'retroarch-v1.9.14" -> [1,9,14]
    // 'retroarch-v1.9.14 test" -> [1,9,14]
    //Other string format will be not OK and can't be well parsed

    QRegularExpression regex("(-v|v)(\\d+.*?)(-|\\s|$)");// to get between "v" or "-v" and ("-" or end of line or space)

    QRegularExpressionMatch match = regex.match(versionString);
    QList<int> versionNumbers = {};
    Log::debug("getVersionNumbers", LOGMSG("versionString: %1").arg(versionString));
    if (match.hasMatch()) {
        Log::debug("getVersionNumbers", LOGMSG("match.captured(2): %1").arg(match.captured(2)));
        QStringList splits = match.captured(2).split(".");
        for(int i = 0; i < splits.count(); i++){
            versionNumbers.append(splits.at(i).toInt());
        }
    }
    return versionNumbers; // return each number of version in QList<int> or empty one if no version found
}

QJsonDocument get_json_from_url(QString url_str, QString log_tag, QNetworkAccessManager &manager)
{
    QNetworkAccessManager* const manager_ptr = &manager;
    const QUrl url(url_str, QUrl::StrictMode);
    Q_ASSERT(url.isValid());
    if (Q_UNLIKELY(!url.isValid()))
    {
        Log::debug(log_tag, LOGMSG("Q_UNLIKELY(!url.isValid())"));
        return QJsonDocument();
    }

    //Set request
    QNetworkRequest request(url);
    request.setAttribute(QNetworkRequest::FollowRedirectsAttribute, true);
    #if (QT_VERSION >= QT_VERSION_CHECK(5, 15, 0))
        request.setTransferTimeout(10000);
    #endif

    //Get request
    QNetworkReply* const reply = manager_ptr->get(request);

    //do loop on connect to wait donwload in this case
    QEventLoop loop;
    QObject::connect(reply, &QNetworkReply::finished, &loop, &QEventLoop::quit);
    loop.exec();

    if (reply->error()) {
        Log::warning(log_tag, LOGMSG("Downloading metadata failed: %1").arg(reply->errorString()));
        return QJsonDocument();
    }
    const QByteArray raw_data = reply->readAll();
    //Log::debug(log_tag, LOGMSG("Raw data: %1").arg(QString(raw_data)));

    QJsonDocument json = QJsonDocument::fromJson(raw_data);
    if (json.isNull()) {
        Log::warning(log_tag, LOGMSG(
               "Failed to parse the response of the server, "
               "either it's no longer available from https://retroachievements.org/ or the API has changed"));
        return QJsonDocument();
    }
    return json;
}

QJsonDocument loadJson(QString fileName) {
    QFile jsonFile(fileName);
    jsonFile.open(QFile::ReadOnly);
    return QJsonDocument().fromJson(jsonFile.readAll());
}

void saveJson(QJsonDocument document, QString fileName) {
    QFile jsonFile(fileName);
    jsonFile.open(QFile::WriteOnly);
    jsonFile.write(document.toJson());
}

} // namespace

namespace model {
Updates::Updates(QObject* parent)
    : QObject(parent)
{
    //Custom Type declaration to manage all structure ;-)
    qRegisterMetaType<UpdateEntry>();
    qRegisterMetaType<Assets>();
    qRegisterMetaType<UpdateStatus>();
}

//Asynchronous function to get last version in background tasts from repo and store it in /tmp
void Updates::getRepoInfo(const QString componentName, const QString repoUrl){
    //Just Download JSON file from repo and save it from componentName
    //example of url: https://api.github.com/repos/bozothegeek/pegasus-frontend/releases
    QMetaObject::invokeMethod(this,"getRepoInfo_slot", Qt::QueuedConnection,
                              Q_ARG(QString,componentName),Q_ARG(QString,repoUrl));
}

void Updates::getRepoInfo_slot(QString componentName, QString url_str){
    //Log::debug(LOGMSG("void Rooms::refresh_slot()"));
    QJsonDocument json;
    //bool result = false;
    try{
        //Create Network Access
        QNetworkAccessManager *manager = new QNetworkAccessManager(this);
        //get json url
        json = get_json_from_url(url_str, log_tag, *manager);
        //save json in a file in /tmp directory
        saveJson(json, "/tmp/" + componentName + ".json");
        //kill manager to avoid memory leaks
        delete manager;

    }
    catch ( const std::exception & Exp )
    {
        Log::error(log_tag, LOGMSG("Error: %1.\n").arg(Exp.what()));
    }
}
//function to select version depending "Beta flag"
int Updates::selectVersionIndex(QList <UpdateEntry> m_versions, const bool betaIncluded){
    //search index of version selected depeding of betaIncluded or not.
    int versionIndex = -1;
    //in case that we want to keep only release version
    if(!betaIncluded){
        for(int i = 0;i < m_versions.count();i++){
            if(!m_versions[i].m_prerealease){
               versionIndex = i;
               break;// to stop search
            }
        }
    }
    else{
        versionIndex = 0;
    }
    return versionIndex;
}
//function to check if any updates is available using /tmp
bool Updates::hasAnyUpdate(){
    return m_hasanyupdate;
}

//function to check information about updates of any componants and confirm quickly if update using /tmp
bool Updates::hasUpdate(const QString componentName, const bool betaIncluded, const QString filter){
    QList <UpdateEntry> m_versions;
    //get data of update/versions and store in QList<UpdateEntry>
    m_versions = parseJsonComponentFile(componentName);
    if(m_versions.count() != 0)
    {
        //search index of version selected depeding of betaIncluded or not.
        int versionIndex = selectVersionIndex(m_versions,betaIncluded);
        if(versionIndex == -1){
            //no release version found
            return false;
        }

        //compare with version install using date of installation for the moment (date of "modifying" for file on file system)
        //may be use a manifest file in the future
        QString existingVersion;
        //QString existingDate;
        QList<int> existingVersionNumbers;
        QList<int> newVersionNumbers;
        //For specific component, we check version from pegasus directly as Pegasus-frontend itself
        if(componentName.toLower() == "pegasus-frontend"){
            //get internal version of Pegasus
            existingVersion = QStringLiteral(GIT_REVISION);
            //no check of date for the moment
            //existingDate = QStringLiteral(GIT_DATE);
            //may be to do for beta ?!
        }
        else
        {
            //for other case, the getting of the version could be different and using a script
            //read assets to find the script for that


        }

        existingVersionNumbers = getVersionNumbers(existingVersion);

        newVersionNumbers = getVersionNumbers(m_versions[versionIndex].m_tag_name);

        if(isNewVersion(existingVersionNumbers, newVersionNumbers)){
            m_hasanyupdate = true;
            return true;
        }
    }
    return false;//no file or issue or no update ;-)
}
//function to get details from last "available" update (and only if available)
UpdateEntry Updates::updateDetails(const QString componentName, const bool betaIncluded){
    UpdateEntry Empty;
    QList <UpdateEntry> m_versions;
    //get data of update/versions and store in QList<UpdateEntry>
    m_versions = parseJsonComponentFile(componentName);
    if(m_versions.count() != 0)
    {
        //search index of version selected depeding of betaIncluded or not.
        int versionIndex = -1;
        //in case that we want to keep only release version
        if(!betaIncluded){
            for(int i = 0;i < m_versions.count();i++){
                if(!m_versions[i].m_prerealease){
                   versionIndex = i;
                   break;// to stop search
                }
            }
            if(versionIndex == -1){
                //no release version found
                return Empty;
            }
        }
        else versionIndex = 0;
        return m_versions[versionIndex]; //just the last version found that for the moment
    }
    return Empty;//no file or issue or no update ;-)
}
//function to return the number of version available
int Updates::componentVersionsCount(const QString componentName){

}
//function to get any version details using index
UpdateEntry Updates::componentVersionDetails(const QString componentName, const int index){

}
//Asynchronous function to install a component
void Updates::launchComponentInstallation(const QString componentName, const QString version){

    Log::debug(log_tag, LOGMSG("launchComponentInstallation for: %1 in version: %2\n").arg(componentName,version));
    QList <UpdateEntry> m_versions;
    //get data of update/versions and store in QList<UpdateEntry>
    m_versions = parseJsonComponentFile(componentName);
    if(m_versions.count() != 0)
    {
        //search index of version selected depending of tag stored in version
        int versionIndex = -1;
        for(int i = 0;i < m_versions.count();i++){
            if(m_versions[i].m_tag_name == version){
               versionIndex = i;
               break;// to stop search
            }
        }
        Log::debug(log_tag, LOGMSG("launchComponentInstallation , version index: %1\n").arg(QString::number(versionIndex)));
        if(versionIndex == -1){
            //TO DO: add a error status and progress for this component installation
        }
        else{
            //get urls
            Assets zipAsset;
            zipAsset.m_name_asset = "";
            Assets installationScriptAsset;
            installationScriptAsset.m_name_asset = "";
            for(int j = 0;j < m_versions[versionIndex].m_assets.count();j++){
                if(m_versions[versionIndex].m_assets[j].m_download_url.endsWith(".zip",Qt::CaseInsensitive)){
                    zipAsset = m_versions[versionIndex].m_assets[j];
                }
                else if(m_versions[versionIndex].m_assets[j].m_download_url.endsWith(".sh",Qt::CaseInsensitive) ||
                m_versions[versionIndex].m_assets[j].m_download_url.endsWith(".py",Qt::CaseInsensitive)){
                    installationScriptAsset = m_versions[versionIndex].m_assets[j];
                }
            }
            //check if valid
            if((zipAsset.m_name_asset != "") && (installationScriptAsset.m_name_asset != "")){
                //launch installation
                QMetaObject::invokeMethod(this,"launchComponentInstallation_slot", Qt::QueuedConnection,
                                          Q_ARG(QString,componentName),Q_ARG(Assets, zipAsset),Q_ARG(Assets, installationScriptAsset));
            }
            else
            {
                //TO DO: add a error status and progress for this component installation
            }
        }
    }
    //TO DO: add a error status and progress for this component installation
}

//void Updates::launchComponentInstallation_slot(const QString componentName, const QString zipUrl, const QString installationScriptUrl){
void Updates::launchComponentInstallation_slot(const QString componentName, const Assets zipAsset, const Assets installationScriptAsset){

    //check and create directory if needed
    QString diretoryPath = "/tmp/" + componentName;
    if(!QDir(diretoryPath).exists()) {
        //create it
        QDir().mkdir(diretoryPath);
    }
    //check if update already exists
    int foundIndex = -1;
    for(int i=0;i<m_updates.count();i++){
        if(m_updates[i].m_componentName == componentName){
            foundIndex = i;
            break;
        }
    }

    //set update to for follow-up
    if(foundIndex == -1){
        m_updates.append({componentName,0.01,"",downloaderIndex});
        foundIndex = m_updates.count()-1;
        //increase index for later
        downloaderIndex = downloaderIndex + 1;
        if(downloaderIndex == MAX_DOWNLOADER){
            downloaderIndex = 0; //reset to 0 to do the loop
        }
    }
    else{
        m_updates[foundIndex].m_installationProgress = 0.01;
        m_updates[foundIndex].m_installationStatus = "";
    }

    //first download zip & script file + clear before to use or reuse the slot
    downloadManager[m_updates[foundIndex].m_downloaderIndex].clear(); // to reset count of downloaded and total of files.
    downloadManager[m_updates[foundIndex].m_downloaderIndex].append(QUrl(zipAsset.m_download_url),diretoryPath + "/" + zipAsset.m_name_asset);
    downloadManager[m_updates[foundIndex].m_downloaderIndex].append(QUrl(installationScriptAsset.m_download_url),diretoryPath + "/" + installationScriptAsset.m_name_asset);

    //do loop on connect to wait download in this case
    QEventLoop loop;
    QObject::connect(&downloadManager[0], &DownloadManager::finished, &loop, &QEventLoop::quit);
    loop.exec();

    //launch installation,
    //TO DO
}

//Function to know status - as "Download", "Installation", "Completed" or "error"
QString Updates::getInstallationStatus(const QString componentName){
    for(int i = 0;i < m_updates.count();i++){
        if(m_updates[i].m_componentName == componentName){
            if(downloadManager[m_updates[i].m_downloaderIndex].statusSpeed != ""){
                return downloadManager[m_updates[i].m_downloaderIndex].statusMessage + " - " +
                       downloadManager[m_updates[i].m_downloaderIndex].statusSpeed;

            }else{
                return downloadManager[m_updates[i].m_downloaderIndex].statusMessage;

            }
        }
    }
    return "";
}

//Fucntion to know progress of each installation steps
float Updates::getInstallationProgress(const QString componentName){
    for(int i = 0;i < m_updates.count();i++){
        if(m_updates[i].m_componentName == componentName){
            return downloadManager[m_updates[i].m_downloaderIndex].statusProgress;
        }
    }
    return 0.0;
}

QList <UpdateEntry> Updates::parseJsonComponentFile(const QString componentName)
{
    QList <UpdateEntry> m_versions;
    //parse json file if exist
    if(QFileInfo::exists("/tmp/" + componentName + ".json")){
        //load json from file in /tmp directory
        QJsonDocument json = loadJson("/tmp/" + componentName + ".json");

        using QL1 = QLatin1String;

        if (json.isNull())
        {
            Log::debug(log_tag, LOGMSG("json.isNull()"));
            return m_versions;
        }
        const auto json_root = json.array();
        if (json_root.isEmpty())
        {
            Log::debug(log_tag, LOGMSG("json_root.isEmpty()"));
            return m_versions;
        }
        else Log::debug(log_tag, LOGMSG("nb version found: %1").arg(json_root.count()));

        int i = 0;

        m_versions.clear(); //to reset QList before new parsing
        UpdateEntry emptyVersion;// to keep empty please !!! ;-)
        for (const auto& array_entry : json_root) {
            //create new object in Qlist
            m_versions.append(emptyVersion);
            //Log::debug(log_tag, LOGMSG("array_entry[QL1('tag_name')].toString(): %1").arg(array_entry[QL1("tag_name")].toString()));
            m_versions[i].m_componentName = componentName;
            m_versions[i].m_tag_name = array_entry[QL1("tag_name")].toString();
            m_versions[i].m_name = array_entry[QL1("name")].toString();
            m_versions[i].m_draft = array_entry[QL1("draft")].toBool();
            m_versions[i].m_prerealease = array_entry[QL1("prerelease")].toBool();
            m_versions[i].m_created_at = array_entry[QL1("created_at")].toString();
            m_versions[i].m_published_at = array_entry[QL1("published_at")].toString();
            m_versions[i].m_body = array_entry[QL1("body")].toString();

            //reading of assets
            const auto assets = array_entry[QL1("assets")].toArray();
            m_versions[i].m_size = 0;
            for (const auto& asset_entry : assets) {
                //but only one asset
                m_versions[i].m_assets.append({ asset_entry[QL1("name")].toString(),
                                                asset_entry[QL1("created_at")].toString(),
                                                asset_entry[QL1("published_at")].toString(),
                                                asset_entry[QL1("size")].toInt(),
                                                asset_entry[QL1("browser_download_url")].toString()});
                m_versions[i].m_size = m_versions[i].m_size + asset_entry[QL1("size")].toInt();
            }
            i++;
        }
    }
    return m_versions;
}

} // namespace model
