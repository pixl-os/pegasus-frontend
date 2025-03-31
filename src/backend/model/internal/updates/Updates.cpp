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

//for RunProcess, just use script manager
#include <utils/Files.h>
#include "ScriptManager.h"

#include "UnzipThreadZlib.h"


namespace {

QString cleanName(QString componentName){
    //to avoid issue with spaces and paranthesis in directories and scripts
    componentName = componentName.replace(" ","");
    componentName = componentName.replace("(","");
    componentName = componentName.replace(")","");
    return componentName;
}

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

QString getExistingRawVersion(const QString componentName, const QString versionScript){
    QString existingVersion = "";

    //For specific component, we check version from pegasus directly as Pegasus-frontend itself
    if(componentName.toLower() == "pegasus-frontend"){
        //get internal version of Pegasus
        existingVersion = QStringLiteral(GIT_REVISION);
    }
    else if(versionScript != "") {
        //for other case, the getting of the version could be different and using a script
        //run the script to read the existing version
        // Build parameters
        Strings::Vector args;
        //prepare script to run
        const Path path = Path(QString(versionScript).toStdString());
        const ScriptManager::ScriptData script = { path, Notification::None , true };
        existingVersion = QString::fromStdString(ScriptManager::Instance().RunProcessWithReturn(script.mPath,args));
    }
    return existingVersion;
}

//function to extract "test" version from any string
QString getVersionString(const QString rawVersion){
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

    QRegularExpression regex("(-v|v|-V|V)(\\d+.*?)(-|\\s|$)");// to get between "v" or "-v" and ("-" or end of line or space) and in upper case also now.

    QRegularExpressionMatch match = regex.match(rawVersion);
    //Log::debug("getVersionNumbers", LOGMSG("versionString: %1").arg(rawVersion));
    if (match.hasMatch()) {
        //Log::debug("getVersionString", LOGMSG("match.captured(2): %1").arg(match.captured(2)));
        return match.captured(2);
    }
    else return ""; // return empty string if not matching
}


//function to extract version from any string
QList<int> getVersionNumbers(const QString rawVersion){
    QString versionString = getVersionString(rawVersion);
    QList<int> versionNumbers = {};
    //Log::debug("getVersionNumbers", LOGMSG("versionString: %1").arg(versionString));
    QStringList splits = versionString.split(".");
    for(int i = 0; i < splits.count(); i++){
        versionNumbers.append(splits.at(i).toInt());
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
    //to avoid memory leacks
    reply->deleteLater();

    if (json.isNull()) {
        Log::warning(log_tag, LOGMSG(
                         "Failed to parse the response of the server, "
                         "either it's no longer available from %1 or the API has changed").arg(url_str));
        return QJsonDocument();
    }
    return json;
}

QJsonDocument loadJson(QString fileName) {
    QFile jsonFile(fileName);
    //Log::debug(LOGMSG("Json fileName: %1").arg(fileName));
    if(jsonFile.open(QFile::ReadOnly)){
        //Log::debug(LOGMSG("Json Raw data: %1").arg(QString::fromLatin1(jsonFile.readAll())));jsonFile.reset();
        return QJsonDocument().fromJson(jsonFile.readAll());
    }
    else return QJsonDocument().fromVariant(""); //empty json
}

void saveJson(QJsonDocument document, QString fileName) {
    QFile jsonFile(fileName);
    jsonFile.open(QFile::WriteOnly);
    jsonFile.write(document.toJson());
}

QString get_script_from_path(QString path_str, QString log_tag)
{
    //read file content
    //Log::debug(log_tag, LOGMSG("Script path_str: %1").arg(path_str));
    QFile f(path_str);
    QString raw_data;
    if (f.open(QFile::ReadOnly | QFile::Text)){
        QTextStream in(&f);
        raw_data = in.readAll();
    }
    QString script = QString(raw_data);
    //Log::debug(log_tag, LOGMSG("Script Raw data: %1").arg(script));

    if (script.isNull()) {
        Log::warning(log_tag, LOGMSG(
                         "Failed to parse the local file, "
                         "either it's no longer available"));
        return "";
    }
    return script;
}

QString get_script_from_url(QString url_str, QString log_tag, QNetworkAccessManager &manager)
{
    QNetworkAccessManager* const manager_ptr = &manager;
    const QUrl url(url_str, QUrl::StrictMode);
    Q_ASSERT(url.isValid());
    if (Q_UNLIKELY(!url.isValid()))
    {
        Log::debug(log_tag, LOGMSG("Q_UNLIKELY(!url.isValid())"));
        return "";
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
        return "";
    }
    QString script = reply->readAll();
    //Log::debug(log_tag, LOGMSG("Script Raw data: %1").arg(script));

    //to avoid memory leacks
    reply->deleteLater();

    if (script.isNull()) {
        Log::warning(log_tag, LOGMSG(
                         "Failed to parse the response of the server, "
                         "either it's no longer available from repo API"));
        return "";
    }
    return script;
}

void saveScript(QString scriptContent, QString fileName) {
    QFile scriptFile(fileName);
    scriptFile.open(QFile::WriteOnly);
    scriptFile.write(scriptContent.toStdString().c_str());
}


} // namespace

namespace model {
Updates::Updates(QObject* parent)
    : QObject(parent)
{
    //Custom Type declaration to manage all structure ;-)
    qRegisterMetaType<UpdateEntry>();
    qRegisterMetaType<UpdateAssets>();
    qRegisterMetaType<UpdateStatus>();
}

//Asynchronous function to get last version in background tasts from repo and store it in /tmp
void Updates::getRepoInfo(QString componentName, const QString repoUrl){
    //to avoid issue with directories and scripts
    componentName = cleanName(componentName);

    //Just Download JSON file from repo and save it from componentName
    //example of url: https://api.github.com/repos/bozothegeek/pegasus-frontend/releases
    QMetaObject::invokeMethod(this,"getRepoInfo_slot", Qt::QueuedConnection,
                              Q_ARG(QString,componentName),Q_ARG(QString,repoUrl));
}

void Updates::getRepoInfo_slot(QString componentName, QString url_str){
    //to avoid issue with spaces in directories and scripts
    componentName = cleanName(componentName);

    //Log::debug(log_tag, LOGMSG("void Updates::getRepoInfo_slot()"));
    QJsonDocument json;
    //bool result = false;
    try{
        //Log::debug(log_tag, LOGMSG("url_str: %1").arg(url_str));
        if(url_str.startsWith("http",Qt::CaseInsensitive)){ //to check that is a remote repo using url
            //Log::debug(log_tag, LOGMSG("url valid: %1").arg(url_str));
            //Create Network Access
            QNetworkAccessManager *manager = new QNetworkAccessManager(this);
            //get json url
            json = get_json_from_url(url_str, log_tag, *manager);
            //save json in a file in /tmp directory
            saveJson(json, "/tmp/" + componentName + ".json");
            //kill manager to avoid memory leaks
            delete manager;
        }
        else if(url_str.startsWith("/",Qt::CaseInsensitive)) //to check if it's a local repo using path
        {
            //Log::debug(log_tag, LOGMSG("path valid: %1").arg(url_str));
            //read file
            json = loadJson(url_str);
            //save json in a file in /tmp directory
            saveJson(json, "/tmp/" + componentName + ".json");
        }
        else{
            Log::error(log_tag, LOGMSG("Error: %2's repo is not identified as local or remote repo : %1\n").arg(url_str,componentName));
        }
    }
    catch ( const std::exception & Exp )
    {
        Log::error(log_tag, LOGMSG("Error: %1.\n").arg(Exp.what()));
    }
}

//function to check if any updates is available using /tmp
bool Updates::hasAnyUpdate(){
    return m_hasanyupdate; //deprecated
}

//function to check information about updates of any componants and confirm quickly if update using /tmp
//and return index of update found
int Updates::hasUpdate(QString componentName, const bool betaIncluded, const bool multiVersions, const QString filter){
    //to avoid issue with directories and scripts
    componentName = cleanName(componentName);
    //Log::debug(LOGMSG("hasUpdate - componentName : %1").arg(componentName));
    //Log::debug(LOGMSG("hasUpdate - betaIncluded : %1").arg(betaIncluded ? "true" : "false"));

    QList <UpdateEntry> m_versions;
    QString existingVersion;
    //get data of update/versions and store in QList<UpdateEntry>
    m_versions = parseJsonComponentFile(componentName);


    for(int versionIndex = 0;versionIndex < m_versions.count();versionIndex++)
    {
        //in case that we want to keep only release version
        if(!betaIncluded){
            if(m_versions[versionIndex].m_prerealease){ // if pre-release identified
                continue; //jump to next index
            }
        }
        //get version.? from selected version (if exists)
        UpdateAssets versionScriptAsset;
        versionScriptAsset.m_name_asset = "";
        for(int j = 0;j < m_versions[versionIndex].m_assets.count();j++){
            if(m_versions[versionIndex].m_assets[j].m_name_asset.startsWith("version.",Qt::CaseInsensitive)){
                versionScriptAsset = m_versions[versionIndex].m_assets[j];
            }
        }
        //download version.? script
        //check and create directory if needed
        QString directoryPath = "/tmp/" + componentName;
        if(!QDir(directoryPath).exists()) {
            //create it
            QDir().mkdir(directoryPath);
        }
        //Log::debug(LOGMSG("hasUpdate - versionScriptAsset.m_download_url: %1").arg(versionScriptAsset.m_download_url));
        //In case of multiVersions, finally delete script systematically to avoid problem With a previous one
        if(multiVersions) QFile(directoryPath + "/" + versionScriptAsset.m_name_asset).remove();
        //check if any script version already exists
        if(!QFile(directoryPath + "/" + versionScriptAsset.m_name_asset).exists() ||  (QFile(directoryPath + "/" + versionScriptAsset.m_name_asset).size() == 0)) {
            //Create Network Access
            QNetworkAccessManager *manager = new QNetworkAccessManager(this);
            //get script content from url
            QString scriptContent;
            if(versionScriptAsset.m_download_url.startsWith("http",Qt::CaseInsensitive)) //to check that is a remote repo using url
            {
                scriptContent = get_script_from_url(versionScriptAsset.m_download_url, log_tag, *manager);
            }
            else if(versionScriptAsset.m_download_url.startsWith("/",Qt::CaseInsensitive)) //to check if it's a local repo using path
            {
                scriptContent = get_script_from_path(versionScriptAsset.m_download_url, log_tag);
            }
            //save script content in a file in /tmp/'Componenet Name' directory
            saveScript(scriptContent, directoryPath + "/" + versionScriptAsset.m_name_asset);
            delete manager; //to avoid memory leaks also
        }
        //compare with version install
        existingVersion = "";
        existingVersion = getExistingRawVersion(componentName,directoryPath + "/" + versionScriptAsset.m_name_asset);
        //if version empty, we have an issue, we can't continue
        if((existingVersion == "") && !multiVersions){
            break;
        }
        else if((existingVersion == "") && multiVersions){// if multiversion, we check next version
            continue;
        }

        QList<int> existingVersionNumbers = getVersionNumbers(existingVersion);
        QList<int> newVersionNumbers = getVersionNumbers(m_versions[versionIndex].m_tag_name);
        if(isNewVersion(existingVersionNumbers, newVersionNumbers)){
            m_hasanyupdate = true; //deprecated
            return versionIndex;
        }
        else if(multiVersions){
            continue;
        }
    }
    return -1;//no file or issue or no update ;-)
}

bool Updates::hasPlugin(){

    //if has plugin under unzipping
    if(m_hasplugin) return true;

    QString directoryPath = "/recalbox/share/plugin";
    QDir directory(directoryPath);
    if (!directory.exists()) {
        Log::debug(log_tag, LOGMSG("Directory does not exist: %1.\n").arg(directoryPath));
        return false;
    }

    QStringList filters;
    filters << "*.plugin"; // Filter for files with the ".plugin" extension

    QStringList entries = directory.entryList(filters, QDir::Files);

    if (entries.isEmpty()) {
        Log::debug(log_tag, LOGMSG("No .plugin file found !"));
        return false;
    }

    //check file plugin
    QString zipFilePath = directory.absoluteFilePath(entries.first());
    QString destinationPath = directoryPath; // Replace with your destination path

    UnzipThreadZlib* unzipThread = new UnzipThreadZlib(zipFilePath, destinationPath);

    QObject::connect(unzipThread, &UnzipThreadZlib::finishedUnzipping, [&]() {
        Log::debug(log_tag, LOGMSG("Unzipping finished."));
        // Unzip successful and files exist, now remove the zip.
        QFile zipFile(zipFilePath);
        if(zipFile.remove()) {
            Log::debug(log_tag, LOGMSG("Zip file removed."));
        }
        else {
            Log::debug(log_tag, LOGMSG("Failed to remove zip file."));
        }
        unzipThread->deleteLater();
        m_hasplugin = false;
    });

    QObject::connect(unzipThread, &UnzipThreadZlib::fileUnzipped, [&](const QString& fileName) {
        Log::debug(log_tag, LOGMSG("Unzipped file: %1").arg(fileName));
    });

    QObject::connect(unzipThread, &UnzipThreadZlib::errorOccurred, [&](const QString& errorMessage){
        Log::error(log_tag, LOGMSG("Error: %1").arg(errorMessage));
        unzipThread->deleteLater();
        //remove .plugin file in case of issue also
        m_hasplugin = false;
    });

    unzipThread->start();
    m_hasplugin = true;
    return true;
}

//function to get details from last "available" update (and only if available)
UpdateEntry Updates::updateDetails(QString componentName, const int versionIndex){
    //to avoid issue with directories and scripts
    componentName = cleanName(componentName);
    UpdateEntry Empty;
    QList <UpdateEntry> m_versions;
    //get data of update/versions and store in QList<UpdateEntry>
    m_versions = parseJsonComponentFile(componentName);
    return m_versions[versionIndex];
}

//function to return the number of version available
int Updates::componentVersionsCount(QString componentName){
    //to avoid issue with directories and scripts
    componentName = cleanName(componentName);
    //RFU
}

//function to get any version details using index
UpdateEntry Updates::componentVersionDetails(QString componentName, const int versionIndex){
    //to avoid issue with directories and scripts
    componentName = cleanName(componentName);
    //RFU
}

//Asynchronous function to install a component
void Updates::launchComponentInstallation(QString componentName, const QString version, const QString downloaddirectory){
    //to avoid issue with directories and scripts
    componentName = cleanName(componentName);

    //Log::debug(log_tag, LOGMSG("launchComponentInstallation for: %1 in version: %2\n").arg(componentName,version));
    //launch installation
    QMetaObject::invokeMethod(this,"launchComponentInstallation_slot", Qt::QueuedConnection,
                              Q_ARG(QString,componentName),Q_ARG(QString,version),Q_ARG(QString,downloaddirectory));
}

//void Updates::launchComponentInstallation_slot(const QString componentName, const QString zipUrl, const QString installationScriptUrl){
void Updates::launchComponentInstallation_slot(QString componentName, const QString version, const QString downloaddirectory){
    //to avoid issue with directories and scripts
    componentName = cleanName(componentName);

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
        //Log::debug(log_tag, LOGMSG("launchComponentInstallation_slot , version index: %1\n").arg(QString::number(versionIndex)));
        if(versionIndex != -1){
            //get urls
            UpdateAssets zipAsset;
            zipAsset.m_name_asset = "";
            UpdateAssets installationScriptAsset;
            installationScriptAsset.m_name_asset = "";
            UpdateAssets versionScriptAsset;
            versionScriptAsset.m_name_asset = "";
            //add new type of assets to add support of image downlaod
            UpdateAssets imgAsset;
            imgAsset.m_name_asset = "";
            UpdateAssets sha1Asset;
            sha1Asset.m_name_asset = "";
            //to manage linux kernel + pixL os
            UpdateAssets linuxAsset;
            linuxAsset.m_name_asset = "";
            UpdateAssets pixLAsset;
            pixLAsset.m_name_asset = "";
            // to manage other files ;-)
            QList<UpdateAssets> genericAssets;
            for(int j = 0;j < m_versions[versionIndex].m_assets.count();j++){
                //if it's a zip file, we consider that's the package to download
                if(m_versions[versionIndex].m_assets[j].m_name_asset.endsWith(".zip",Qt::CaseInsensitive)){
                    zipAsset = m_versions[versionIndex].m_assets[j];
                }//if it's a file with "install.", we consider that it will be the script for installation
                else if(m_versions[versionIndex].m_assets[j].m_name_asset.startsWith("install.",Qt::CaseInsensitive)){
                    installationScriptAsset = m_versions[versionIndex].m_assets[j];
                }//if it's a file with "version.", we consider that it will be the script for checking of existing version
                else if(m_versions[versionIndex].m_assets[j].m_name_asset.startsWith("version.",Qt::CaseInsensitive)){
                    versionScriptAsset = m_versions[versionIndex].m_assets[j];
                }//if it's a .img.xz file, we consider that it will be any image to install
                else if(m_versions[versionIndex].m_assets[j].m_name_asset.endsWith(".img.xz",Qt::CaseInsensitive)){
                    imgAsset = m_versions[versionIndex].m_assets[j];
                }//if it's a .img.xz.sha1 file, we consider that it will be any sha1 of image to install
                else if(m_versions[versionIndex].m_assets[j].m_name_asset.endsWith(".img.xz.sha1",Qt::CaseInsensitive)){
                    sha1Asset = m_versions[versionIndex].m_assets[j];
                }//if it's a 'linux' file as for "raw" update
                else if(m_versions[versionIndex].m_assets[j].m_name_asset.endsWith("/linux")){
                    linuxAsset = m_versions[versionIndex].m_assets[j];
                }//if it's a 'recalbox' os file as for "raw" update
                else if(m_versions[versionIndex].m_assets[j].m_name_asset.endsWith("/recalbox")){
                    pixLAsset = m_versions[versionIndex].m_assets[j];
                }
                else{//for all other assets if needed
                    genericAssets.append(m_versions[versionIndex].m_assets[j]);
                }
            }
            //check and create directory if needed
            QString directoryPath = "/tmp/" + componentName;
            if(!QDir(directoryPath).exists()) {
                //create it
                QDir().mkdir(directoryPath);
            }
            //Redownload in all cases because we are in a slot
            //Create Network Access
            QNetworkAccessManager *manager = new QNetworkAccessManager(this);
            //get script content from url
            QString scriptContent;

            //delete log/err files to avoid border effect
            QFile(directoryPath + "/install.err").remove();
            QFile(directoryPath + "/install.log").remove();
            QFile(directoryPath + "/progress.log").remove();

            //delete script to avoid problem of existing or corrupted file
            QFile(directoryPath + "/" + versionScriptAsset.m_name_asset).remove();

            if(versionScriptAsset.m_download_url.startsWith("http",Qt::CaseInsensitive)) //to check that is a remote repo using url
            {
                scriptContent = get_script_from_url(versionScriptAsset.m_download_url, log_tag, *manager);
            }
            else if(versionScriptAsset.m_download_url.startsWith("/",Qt::CaseInsensitive)) //to check if it's a local repo using path
            {
                scriptContent = get_script_from_path(versionScriptAsset.m_download_url, log_tag);
            }
            //save script content in a file in /tmp/'Componenet Name' directory
            saveScript(scriptContent, directoryPath + "/" + versionScriptAsset.m_name_asset);
            delete manager; //to avoid memory leaks also

            //prepare version also
            QString rawVersion = getExistingRawVersion(componentName,directoryPath + "/" + versionScriptAsset.m_name_asset);
            QString existingVersion = getVersionString(rawVersion);
            QString newVersion = getVersionString(version);

            //check if valid (at minimum to have a package and an installation script and with an existing version)
            if((installationScriptAsset.m_name_asset != "") && (existingVersion != "")){

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

                //following this rules
                //set update to for follow-up
                if(foundIndex == -1){
                    m_updates.append({componentName,0.01,"",downloaderIndex,0});
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
                    m_updates[foundIndex].m_installationStep = 0;
                }

                //delete script to avoid problem of existing or corrupted file
                QFile(directoryPath + "/" + installationScriptAsset.m_name_asset).remove();

                if(installationScriptAsset.m_download_url.startsWith("http",Qt::CaseInsensitive)) //to check that is a remote repo using url
                {
                    //first download zip, script and other asset files + clear before to use or reuse the slot
                    downloadManager[m_updates[foundIndex].m_downloaderIndex].clear(); // to reset count of downloaded and total of files.
                    if (installationScriptAsset.m_name_asset != "") downloadManager[m_updates[foundIndex].m_downloaderIndex].append(QUrl(installationScriptAsset.m_download_url),diretoryPath + "/" + installationScriptAsset.m_name_asset); //no set size to always download from 0
                    //management of download directory only for zip package, image and its sha1
                    if (zipAsset.m_name_asset != ""){
                        if(downloaddirectory == "") downloadManager[m_updates[foundIndex].m_downloaderIndex].append(QUrl(zipAsset.m_download_url),diretoryPath + "/" + zipAsset.m_name_asset, zipAsset.m_size);
                        else downloadManager[m_updates[foundIndex].m_downloaderIndex].append(QUrl(zipAsset.m_download_url),downloaddirectory + "/" + zipAsset.m_name_asset, zipAsset.m_size);
                    }
                    //additional ones only when we ahve to update OS
                    if (sha1Asset.m_name_asset != "") {
                        if(downloaddirectory == "") downloadManager[m_updates[foundIndex].m_downloaderIndex].append(QUrl(sha1Asset.m_download_url),diretoryPath + "/" + sha1Asset.m_name_asset); //no set size to always download from 0
                        else downloadManager[m_updates[foundIndex].m_downloaderIndex].append(QUrl(sha1Asset.m_download_url),downloaddirectory + "/" + sha1Asset.m_name_asset); //no set size to always download from 0
                    }
                    if (imgAsset.m_name_asset != "") {
                        if(downloaddirectory == "") downloadManager[m_updates[foundIndex].m_downloaderIndex].append(QUrl(imgAsset.m_download_url),diretoryPath + "/" + imgAsset.m_name_asset, imgAsset.m_size);
                        else downloadManager[m_updates[foundIndex].m_downloaderIndex].append(QUrl(imgAsset.m_download_url),downloaddirectory + "/" + imgAsset.m_name_asset, imgAsset.m_size);
                    }
                    //additional ones for linux kernel + os
                    if (linuxAsset.m_name_asset != "") {
                        if(downloaddirectory == "") downloadManager[m_updates[foundIndex].m_downloaderIndex].append(QUrl(linuxAsset.m_download_url),diretoryPath + "/" + linuxAsset.m_name_asset, linuxAsset.m_size);
                        else downloadManager[m_updates[foundIndex].m_downloaderIndex].append(QUrl(linuxAsset.m_download_url),downloaddirectory + "/" + linuxAsset.m_name_asset, linuxAsset.m_size);
                    }
                    if (pixLAsset.m_name_asset != "") {
                        if(downloaddirectory == "") downloadManager[m_updates[foundIndex].m_downloaderIndex].append(QUrl(pixLAsset.m_download_url),diretoryPath + "/" + pixLAsset.m_name_asset, pixLAsset.m_size);
                        else downloadManager[m_updates[foundIndex].m_downloaderIndex].append(QUrl(pixLAsset.m_download_url),downloaddirectory + "/" + pixLAsset.m_name_asset, pixLAsset.m_size);
                    }
                    //additional ones for generic files (as other scripts, files, ressources needed for an update)
                    for(int i = 0; i < genericAssets.count() ;i++){
                        if(downloaddirectory == "") downloadManager[m_updates[foundIndex].m_downloaderIndex].append(QUrl(genericAssets[i].m_download_url),diretoryPath + "/" + genericAssets[i].m_name_asset); //no set size to always download from 0
                        else downloadManager[m_updates[foundIndex].m_downloaderIndex].append(QUrl(genericAssets[i].m_download_url),downloaddirectory + "/" + genericAssets[i].m_name_asset); //no set size to always download from 0
                    }

                    //refactored code
                    m_updates[foundIndex].m_installationStep = 1;
                    QObject::connect(&downloadManager[m_updates[foundIndex].m_downloaderIndex], &DownloadManager::finished,
                                     this, [this, foundIndex, existingVersion, newVersion, componentName, diretoryPath, installationScriptAsset]() { // Use a lambda to capture variables
                                         //Log::debug(log_tag, LOGMSG("launchComponentInstallation_slot: %1").arg(downloadManager[m_updates[foundIndex].m_downloaderIndex].statusMessage));
                                         if (downloadManager[m_updates[foundIndex].m_downloaderIndex].statusError > 0) {
                                             //Log::debug(log_tag, LOGMSG("launchComponentInstallation_slot: finished with error - exit status: %1").arg(QString::number(downloadManager[m_updates[foundIndex].m_downloaderIndex].statusError)));
                                             // Handle the error (e.g., emit a signal to notify the UI)
                                             // If neccesary, return from the calling function.
                                             return;
                                         }
                                         // Continue processing after download completion (e.g., installation)
                                         QMetaObject::invokeMethod(this, [this, foundIndex, existingVersion, newVersion, componentName, diretoryPath, installationScriptAsset]() {
                                                 // update UI here.
                                                 //Log::debug(log_tag, LOGMSG("launchComponentInstallation_slot: Example of UI update from non-UI thread: %1").arg(QString::number(downloadManager[m_updates[foundIndex].m_downloaderIndex].statusError)));
                                                 //launch installation after download
                                                 m_updates[foundIndex].m_installationStep = 2;

                                                 //launch installation script
                                                 // Build parameters
                                                 Strings::Vector args;
                                                 args.push_back("-e");
                                                 args.push_back(QString(existingVersion).toStdString());
                                                 args.push_back("-n");
                                                 args.push_back(QString(newVersion).toStdString());
                                                 args.push_back("-c");
                                                 args.push_back(QString(componentName).toStdString());

                                                 //prepare script to run
                                                 const Path path = Path(QString(diretoryPath + "/" + installationScriptAsset.m_name_asset).toStdString());

                                                 //sync to wait end of script in this slot
                                                 const ScriptManager::ScriptData script = { path, Notification::None , true };
                                                 ScriptManagerThread *MyThread = new ScriptManagerThread(script.mPath,args,script.mSync,ScriptManager::Instance().mEnvironment);

                                                 //connect to Thread
                                                 connect(MyThread, &ScriptManagerThread::finished, [this, foundIndex, componentName](int exit_status)->void{
                                                     //Check if OK and no error during installation
                                                     if((exit_status == 0) && (this->getInstallationError(componentName) <= 0)){
                                                         //Log::debug(log_tag, LOGMSG("Thread finished without error - exit status: %1").arg(QString::number(exit_status)));
                                                         this->m_updates[foundIndex].m_installationStep = 3; //installation finish
                                                     }
                                                     else{
                                                         //Log::debug(log_tag, LOGMSG("Thread finished with error - exit status: %1").arg(QString::number(exit_status)));
                                                         this->m_updates[foundIndex].m_installationStep = 4; //installation finish on error
                                                     }
                                                 });
                                                 MyThread->start();
                                                 QThread::msleep(200); // sleep temporary to let thread start and show changes else it could crash :-(
                                             }, Qt::QueuedConnection);

                                     });
                }
                else if(installationScriptAsset.m_download_url.startsWith("/",Qt::CaseInsensitive)) //to check if it's a local repo using path
                {
                    //no loop or wait, but step 1 ...
                    m_updates[foundIndex].m_installationStep = 1;
                    QString installationScriptContent = get_script_from_path(installationScriptAsset.m_download_url, log_tag);
                    //save script content in a file in /tmp/'Componenet Name' directory
                    saveScript(installationScriptContent, directoryPath + "/" + installationScriptAsset.m_name_asset);
                    //no package downloaded in this case for the moment.

                    //launch installation after download
                    m_updates[foundIndex].m_installationStep = 2;

                    //launch installation script
                    // Build parameters
                    Strings::Vector args;
                    args.push_back("-e");
                    args.push_back(QString(existingVersion).toStdString());
                    args.push_back("-n");
                    args.push_back(QString(newVersion).toStdString());
                    args.push_back("-c");
                    args.push_back(QString(componentName).toStdString());

                    //prepare script to run
                    const Path path = Path(QString(diretoryPath + "/" + installationScriptAsset.m_name_asset).toStdString());

                    //sync to wait end of script in this slot
                    const ScriptManager::ScriptData script = { path, Notification::None , true };
                    ScriptManagerThread *MyThread = new ScriptManagerThread(script.mPath,args,script.mSync,ScriptManager::Instance().mEnvironment);

                    //connect to Thread
                    connect(MyThread, &ScriptManagerThread::finished, [this, foundIndex, componentName](int exit_status)->void{
                        //Check if OK and no error during installation
                        if((exit_status == 0) && (this->getInstallationError(componentName) <= 0)){
                            //Log::debug(log_tag, LOGMSG("Thread finished without error - exit status: %1").arg(QString::number(exit_status)));
                            this->m_updates[foundIndex].m_installationStep = 3; //installation finish
                        }
                        else{
                            //Log::debug(log_tag, LOGMSG("Thread finished with error - exit status: %1").arg(QString::number(exit_status)));
                            this->m_updates[foundIndex].m_installationStep = 4; //installation finish on error
                        }
                    });
                    MyThread->start();
                    QThread::msleep(200); // sleep temporary to let thread start and show changes else it could crash :-(
                }
            }
        }
    }
}

//Function to know status - as "Download", "Installation", "Completed" or "error"
QString Updates::getInstallationStatus(QString componentName){
    //to avoid issue with directories and scripts
    componentName = cleanName(componentName);

    for(int i = 0;i < m_updates.count();i++){
        if(m_updates[i].m_componentName == componentName){
            if(m_updates[i].m_installationStep == 1){//if we are downloading...
                if(downloadManager[m_updates[i].m_downloaderIndex].statusSpeed != ""){
                    return downloadManager[m_updates[i].m_downloaderIndex].statusMessage + " - " +
                           downloadManager[m_updates[i].m_downloaderIndex].statusSpeed;
                }else{
                    return downloadManager[m_updates[i].m_downloaderIndex].statusMessage;
                }
            }
            else if(m_updates[i].m_installationStep >= 2){//if we are installing... and more
               //return content of file /tmp/componentName/install.log
                QFile installFile("/tmp/" + componentName + "/install.log");
                if (installFile.open(QFile::ReadOnly | QFile::Text)) {
                   QTextStream stream(&installFile);
                   QString line = stream.readAll();
                   return line;
                }
            }
        }
    }
    return "";
}

//Fucntion to know progress of each installation steps
float Updates::getInstallationProgress(QString componentName){
    //to avoid issue with directories and scripts
    componentName = cleanName(componentName);

    for(int i = 0;i < m_updates.count();i++){
        if(m_updates[i].m_componentName == componentName){
            if(m_updates[i].m_installationStep == 1){//if we are downloading...
                return downloadManager[m_updates[i].m_downloaderIndex].statusProgress;
            }
            else if(m_updates[i].m_installationStep >= 2){//if we are installing...
                //return content of file /tmp/componentName/progress.log
                QFile progressFile("/tmp/" + componentName + "/progress.log");
                if (progressFile.open(QFile::ReadOnly | QFile::Text)) {
                   QTextStream stream(&progressFile);
                   QString line = stream.readAll();
                   return line.toFloat();
                }
                else return 0.1;
            }
        }
    }
    return 0.0;
}

int Updates::getInstallationError(QString componentName){
    //to avoid issue with directories and scripts
    componentName = cleanName(componentName);

    for(int i = 0;i < m_updates.count();i++){
        if(m_updates[i].m_componentName == componentName){
            if(m_updates[i].m_installationStep == 1){
                if(downloadManager[m_updates[i].m_downloaderIndex].statusError > 0){
                    return downloadManager[m_updates[i].m_downloaderIndex].statusError;
                }
            }
            else if(m_updates[i].m_installationStep >= 2){//if we are installing...and more.
               //return content of file /tmp/componentName/install.err
                QFile installFile("/tmp/" + componentName + "/install.err");
                if (installFile.open(QFile::ReadOnly | QFile::Text)) {
                   QTextStream stream(&installFile);
                   QString line = stream.readAll();
                   return line.toInt();
                }
            }
        }
    }
    return 0;
}

QList <UpdateEntry> Updates::parseJsonComponentFile(QString componentName)
{
    //to avoid issue with directories and scripts
    componentName = cleanName(componentName);

    QList <UpdateEntry> m_versions;
    //parse json file if exist
    Log::debug(log_tag, LOGMSG("/tmp/%1.json").arg(componentName));
    if(QFileInfo::exists("/tmp/" + componentName + ".json")){
        //load json from file in /tmp directory
        QJsonDocument json = loadJson("/tmp/" + componentName + ".json");

        using QL1 = QLatin1String;

        if (json.isNull())
        {
            //Log::debug(log_tag, LOGMSG("%1 : json.isNull()").arg(componentName));
            return m_versions;
        }
        const auto json_root = json.array();
        if (json_root.isEmpty())
        {
            //Log::debug(log_tag, LOGMSG("json_root.isEmpty()"));
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
            m_versions[i].m_body = array_entry[QL1("body")].toString().replace("\r","");
            //Log::debug(log_tag, LOGMSG("array_entry[QL1('body')].toString(): %1").arg(array_entry[QL1("body")].toString().replace("\r","")));

            //reading of assets
            const auto assets = array_entry[QL1("assets")].toArray();
            m_versions[i].m_size = 0;
            for (const auto& asset_entry : assets) {
                //but only one asset
                m_versions[i].m_assets.append({ asset_entry[QL1("name")].toString(),
                                                asset_entry[QL1("created_at")].toString(),
                                                asset_entry[QL1("published_at")].toString(),
                                                qint64(asset_entry[QL1("size")].toDouble()),
                                                asset_entry[QL1("browser_download_url")].toString()});
                if(asset_entry[QL1("browser_download_url")].toString().contains("icon.png")){
                    QString prefix = "";
                    if(asset_entry[QL1("browser_download_url")].toString().startsWith("/",Qt::CaseInsensitive)) //to check if it's a local image using path
                    {
                        prefix = "file:/";
                    }
                    m_versions[i].m_icon = prefix + asset_entry[QL1("browser_download_url")].toString();
                }
                else if(asset_entry[QL1("browser_download_url")].toString().contains("picture.png")){
                    QString prefix = "";
                    if(asset_entry[QL1("browser_download_url")].toString().startsWith("/",Qt::CaseInsensitive)) //to check if it's a local image using path
                    {
                        prefix = "file:/";
                    }
                    m_versions[i].m_picture = prefix + asset_entry[QL1("browser_download_url")].toString();
                }
                //Log::info(log_tag, LOGMSG("asset_entry[QL1('name')].toString(): %1").arg(asset_entry[QL1("name")].toString()));
                //Log::info(log_tag, LOGMSG("asset_entry[QL1('size')].ToDouble(): %1").arg(QString::number(qint64(asset_entry[QL1("size")].toDouble()))));
                m_versions[i].m_size = m_versions[i].m_size + qint64(asset_entry[QL1("size")].toDouble());
                //Log::info(log_tag, LOGMSG("m_versions[i].m_size: %1").arg(QString::number(m_versions[i].m_size)));
            }
            i++;
        }
    }
    return m_versions;
}

} // namespace model
