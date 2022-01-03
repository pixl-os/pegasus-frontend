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
}

//Asynchronous function to get last version in background tasts from repo and store it in /tmp
void Updates::getRepoInfo(const QString componentName, const QString repoUrl){
    //Just Download JSON file from repo and save it from componentName
    //example of url: https://api.github.com/repos/bozothegeek/pegasus-frontend/releases
    m_componentName = componentName;
    m_repoUrl = repoUrl;
    QMetaObject::invokeMethod(this,"getRepoInfo_slot", Qt::QueuedConnection);
}
void Updates::getRepoInfo_slot(){
    //Log::debug(LOGMSG("void Rooms::refresh_slot()"));
    QJsonDocument json;
    //bool result = false;
    try{
        //Create Network Access
        QNetworkAccessManager *manager = new QNetworkAccessManager(this);
        //get json url
        const QString url_str = m_repoUrl;
        const QString componentName = m_componentName;
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

//function to check if any updates is available using /tmp
bool Updates::hasAnyUpdate(){
    m_hasanyupdate = true; // as forced for testing
    return m_hasanyupdate;
}

//function to check information about updates of any componants and confirm quickly if update using /tmp
bool Updates::hasUpdate(const QString componentName, const bool betaIncluded){
    //get data of update/versions and store in QList<UpdateEntry>
    if(parseJsonComponentFile(componentName))
    {
        return true; //just that for the moment
        //To do
        //compare with version install using date of installation for the moment (date of "modifying" for file on file system)
        //may be use a manifest file in the future
    }
    return false;//no file or issue = no update ;-)
}
//function to get details from last "available" update (and only if available)
UpdateEntry Updates::updateDetails(const QString componentName, const bool betaIncluded){
    //get data of update/versions and store in QList<UpdateEntry>
    if(parseJsonComponentFile(componentName))
    {
        return m_versions[0]; //just that for the moment
        //To do
        //compare with version install using date of installation for the moment (date of "modifying" for file on file system)
        //may be use a manifest file in the future
    }
    UpdateEntry Empty;
    return Empty;//no file or issue = no update ;-)
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

bool Updates::parseJsonComponentFile(const QString componentName)
{
    //parse json file if exist
    if(QFileInfo::exists("/tmp/" + componentName + ".json")){
        //load json from file in /tmp directory
        QJsonDocument json = loadJson("/tmp/" + componentName + ".json");

        using QL1 = QLatin1String;

        if (json.isNull())
        {
            Log::debug(log_tag, LOGMSG("json.isNull()"));
            return false;
        }
        const auto json_root = json.array();
        if (json_root.isEmpty())
        {
            Log::debug(log_tag, LOGMSG("json_root.isEmpty()"));
            return false;
        }
        else Log::debug(log_tag, LOGMSG("nb version found: %1").arg(json_root.count()));

        int i = 0;

        m_versions.clear(); //to reset QList before new parsing
        UpdateEntry emptyVersion;// to keep empty please !!!
        for (const auto& array_entry : json_root) {
            //create new object in Qlist
            m_versions.append(emptyVersion);
            Log::debug(log_tag, LOGMSG("array_entry[QL1('tag_name')].toString(): %1").arg(array_entry[QL1("tag_name")].toString()));
            m_versions[i].m_tag_name = array_entry[QL1("tag_name")].toString();

    //        const auto fields = array_entry[QL1("fields")].toObject();
    //        const auto Id = fields[QL1("id")].toInt();
    //        const auto Username = fields[QL1("username")].toString();
    //        const auto Country = fields[QL1("country")].toString();
    //        const auto Game_name = fields[QL1("game_name")].toString();
    //        const auto Game_crc = fields[QL1("game_crc")].toString();
    //        const auto Core_name = fields[QL1("core_name")].toString();
    //        const auto Core_version = fields[QL1("core_version")].toString();
    //        const auto Subsystem_name = fields[QL1("subsystem_name")].toString();
    //        const auto Retroarch_version = fields[QL1("retroarch_version")].toString();
    //        const auto Frontend = fields[QL1("frontend")].toString();
    //        const auto Ip = fields[QL1("ip")].toString();
    //        const auto Port = fields[QL1("port")].toInt();
    //        const auto Mitm_ip = fields[QL1("mitm_ip")].toString();
    //        const auto Mitm_port = fields[QL1("mitm_port")].toInt();
    //        const auto Host_method = fields[QL1("host_method")].toInt();
    //        const auto Has_password = fields[QL1("has_password")].toBool();
    //        const auto Has_spectate_password = fields[QL1("has_spectate_password")].toBool();
    //        const auto Created = fields[QL1("created")].toString();
    //        const auto Updated = fields[QL1("updated")].toString();
    //        const auto Latency = 1000; //default value / unknown
            i++;
        }
        return true;
    }
    //Log::info(log_tag, LOGMSG("json_root.count(): %1.").arg(json_root.count()));
    //Log::info(log_tag, LOGMSG("m_Count: %1.").arg(m_Count));
    //Log::info(log_tag, LOGMSG("rowCount(): %1.").arg(rowCount()));
    return false;
}

} // namespace model
