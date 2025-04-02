#include "UnzipThread.h"
#include <QFile>
#include <QDir>
#include <QDebug>
#include <utils/quazip/quazip.h>
#include <utils/quazip/quazipfile.h>
#include "Log.h"

UnzipThread::UnzipThread(const QString& zipFilePath, const QString& destinationPath, QObject* parent)
    : QThread(parent), zipFilePath_(zipFilePath), destinationPath_(destinationPath) {}

void UnzipThread::run() {
    QuaZip zip(zipFilePath_);
    if (!zip.open(QuaZip::mdUnzip)) {
        emit errorOccurred(QString("Failed to open zip file: %1").arg(zip.getZipError()));
        return;
    }

    QuaZipFile zipFile(&zip);
    QuaZipFileInfo fileInfo;

    QDir destinationDir(destinationPath_);
    if (!destinationDir.exists()) {
        destinationDir.mkpath(".");
    }

    for (bool moreFiles = zip.goToFirstFile(); moreFiles; moreFiles = zip.goToNextFile()) {
        if (!zip.getCurrentFileInfo(&fileInfo)) {
            emit errorOccurred(QString("Failed to get file info: %1").arg(zip.getZipError()));
            zip.close();
            return;
        }

        QString filePath = destinationPath_ + "/" + fileInfo.name;
        QFileInfo file(filePath); // Create QFileInfo, but don't assume existence
        Log::debug("UnzipThread", LOGMSG("filePath: %1").arg(filePath));
        if (file.isDir() || filePath.endsWith("/")) { // Check if it's a directory (might not exist yet)
            Log::debug("UnzipThread", LOGMSG("this file is directory"));
            QDir dir(filePath);
            if (!dir.exists()) {
                if (dir.mkpath(filePath)) {
                    Log::debug("UnzipThread", LOGMSG("Directory created: %1").arg(filePath));
                } else {
                    Log::debug("UnzipThread", LOGMSG("Failed to create directory: %1").arg(filePath));
                }
            }
            continue; // Continue to the next file/directory in your loop
        }

        if (!zipFile.open(QIODevice::ReadOnly)) {
            emit errorOccurred(QString("Failed to open file in zip: %1").arg(zipFile.getZipError()));
            zip.close();
            return;
        }

        QFile outFile(filePath);
        if (!outFile.open(QIODevice::WriteOnly)) {
            emit errorOccurred(QString("Failed to open output file: %1").arg(outFile.errorString()));
            zipFile.close();
            zip.close();
            return;
        }

        char buffer[4096];
        int bytesRead;
        while ((bytesRead = zipFile.read(buffer, sizeof(buffer))) > 0) {
            outFile.write(buffer, bytesRead);
        }
        outFile.flush(); //Ensure the data is written to disk.
        outFile.close();
        zipFile.close();
        emit fileUnzipped(fileInfo.name);
    }
    zip.close();
    emit finishedUnzipping(zipFilePath_);
}
