// Pegasus Frontend
//
// Created by Bozo The Geek - 02/01/2022
//

#pragma once

#include "utils/QmlHelpers.h"
#include <QString>
#include <QObject>
#include <QTimer>
#include "DownloadManager.h"

const int MAX_DOWNLOADER = 20;

struct UpdateAssets {
    QString m_name_asset;
    QString m_created_at_asset;
    QString m_published_at_asset;
    qint64 m_size;
    QString m_download_url;
};
Q_DECLARE_METATYPE(UpdateAssets)

struct UpdateStatus {
    Q_GADGET
    Q_PROPERTY(QString componentName MEMBER m_componentName);
    Q_PROPERTY(float installationProgress MEMBER m_installationProgress);
    Q_PROPERTY(QString installationStatus MEMBER m_installationStatus)  //Name provided during "getRepoInfo" as reference
    Q_PROPERTY(int downloaderIndex MEMBER m_downloaderIndex);
    Q_PROPERTY(int installationStep MEMBER m_installationStep);

public:
    QString m_componentName;
    float m_installationProgress;
    QString m_installationStatus;
    int m_downloaderIndex;
    int m_installationStep; //0: not started, 1: download files under progress, 2: installation under progress, 3: done, 4:issue to download/install
};
Q_DECLARE_METATYPE(UpdateStatus)

struct UpdateEntry {
      Q_GADGET
      Q_PROPERTY(QString componentName MEMBER m_componentName)  //Name provided during "getRepoInfo" as reference
      Q_PROPERTY(QString tagName MEMBER m_tag_name)             //from repo json "tag_name": "pixL-edition-v0.0.1",
      Q_PROPERTY(QString releaseTitle MEMBER m_name)                    //from repo json "name": "pixL-edition-v0.0.1",
      Q_PROPERTY(bool isDraft MEMBER m_draft)                   //from repo json "draft": false,
      Q_PROPERTY(bool isPreRelease MEMBER m_prerealease)        //from repo json "prerelease": true,
      Q_PROPERTY(QString createdAt MEMBER m_created_at)         //from repo json "created_at": "2022-01-01T16:48:18Z",
      Q_PROPERTY(QString publishedAt MEMBER m_published_at)     //from repo json "published_at": "2022-01-01T18:34:04Z",
      Q_PROPERTY(QString releaseNote MEMBER m_body) //from repo json "body": "## What's new in this version ? (included in pixL-Beta19)\r\n...
      //from asset
      Q_PROPERTY(QString icon MEMBER m_icon)
      Q_PROPERTY(QString picture MEMBER m_picture)
      Q_PROPERTY(qint64 size MEMBER m_size) //get size of the update, if several files, all sizes will be added to have the full size in this value.



public:
      QString m_componentName;
      QString m_tag_name;
      QString m_name;
      bool m_draft;
      bool m_prerealease;
      QString m_created_at;
      QString m_published_at;
      QString m_body;
      //if available from repo
      QString m_icon = "";
      QString m_picture = "";
      qint64 m_size; //to have the total size

      //for asset
      QList <UpdateAssets> m_assets;

      //flag if update detected
      bool m_hasanyupdate = false; //deprecated

};
Q_DECLARE_METATYPE(UpdateEntry)

namespace model {

class Updates : public QObject {
    Q_OBJECT

public:
    explicit Updates(QObject* parent = nullptr);
    //Asynchronous function to get last version in background tasts from repo and store it in /tmp
    Q_INVOKABLE void getRepoInfo(QString componentName, const QString repoUrl);
    //function to check if any updates is available using /tmp
    Q_INVOKABLE bool hasAnyUpdate(); //deprecated
    //function to check information about updates of any componants and confirm quickly if update using /tmp
    //and return index of update found
    Q_INVOKABLE int hasUpdate(QString componentName, const bool betaIncluded = false, const bool multiversions = false, const QString filter = "");
    //function to get details from last "available" update (and only if available)
    Q_INVOKABLE UpdateEntry updateDetails(QString componentName, const int versionIndex);
    //function to return the number of version available
    Q_INVOKABLE int componentVersionsCount(QString componentName);
    //function to get any version details using index
    Q_INVOKABLE UpdateEntry componentVersionDetails(QString componentName, const int versionIndex);
    //Asynchronous function to install a component
    Q_INVOKABLE void launchComponentInstallation(QString componentName, const QString version);
    //Function to know status - as "Download", "Installation", "Completed" or "error"
    Q_INVOKABLE QString getInstallationStatus(QString componentName);
    //Fucntion to know progress of each installation steps
    Q_INVOKABLE float getInstallationProgress(QString componentName); //provide pourcentage of downlaod and installation
    //Function to know if error during installation step
    Q_INVOKABLE int getInstallationError(QString componentName); //provide code from -2 to 3 / 0 : no error / >0: errors/need retry / -1: need restart / -2: need reboot

private:
    QList <UpdateEntry> parseJsonComponentFile(QString componentName);

signals:

private slots:
    //to have thread to download JSON file from repo
    void getRepoInfo_slot(QString componentName, QString repoUrl);
    //to have thread to download ZIP file/Script and to install the new component
    void launchComponentInstallation_slot(QString componentName, const QString version);

public:

private:
    //to follow status of updates
    QList <UpdateStatus> m_updates;
    DownloadManager downloadManager[MAX_DOWNLOADER];
    int downloaderIndex = 0;
    bool m_hasanyupdate = false; //deprecated
    QString log_tag = "Updates";
};
} // namespace model
