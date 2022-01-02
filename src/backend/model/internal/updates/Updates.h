// Pegasus Frontend
//
// Created by Bozo The Geek - 02/01/2022
//

#pragma once

#include "utils/QmlHelpers.h"
#include <QString>
#include <QObject>
#include <QTimer>

struct UpdateEntry {
      Q_GADGET
      //Q_PROPERTY(QString title READ title CONSTANT)
      Q_PROPERTY(QString componentName MEMBER m_componentName)
public:
      QString m_componentName;
};
Q_DECLARE_METATYPE(UpdateEntry)

namespace model {

class Updates : public QObject {
    Q_OBJECT

public:
    explicit Updates(QObject* parent = nullptr);
    //Asynchronous function to get last version in background tasts from repo and store it in /tmp
    Q_INVOKABLE void getRepoInfo(const QString componentName, const QString repoUrl);
    //function to check if any updates is available using /tmp
    Q_INVOKABLE bool hasAnyUpdate();
    //function to check information about updates of any componants and confirm quickly if update using /tmp
    Q_INVOKABLE bool hasUpdate(const QString componentName, const bool betaIncluded);
    //function to get details from last "available" update (and only if available)
    Q_INVOKABLE UpdateEntry updateDetails(const QString componentName);
    //function to return the number of version available
    Q_INVOKABLE int componentVersionsCount(const QString componentName);
    //function to get any version details using index
    Q_INVOKABLE UpdateEntry componentVersionDetails(const QString componentName, const int index);
    //Asynchronous function to install a component
    Q_INVOKABLE void launchComponentInstallation(const QString componentName, const QString version);
    //Function to know status - as "Download", "Installation", "Completed" or "error"
    Q_INVOKABLE QString getInstallationStatus(const QString componentName);
    //Fucntion to know progress of each installation steps
    Q_INVOKABLE int getInstallationProgress(const QString componentName); //provide pourcentage of downlaod and installation

signals:

private slots:

public:

private:

};
} // namespace model
