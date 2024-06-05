/****************************************************************************
**
** Copyright (C) 2017 The Qt Company Ltd.
** Contact: https://www.qt.io/licensing/
**
** This file is part of the examples of the Qt Toolkit.
**
** $QT_BEGIN_LICENSE:BSD$
** Commercial License Usage
** Licensees holding valid commercial Qt licenses may use this file in
** accordance with the commercial license agreement provided with the
** Software or, alternatively, in accordance with the terms contained in
** a written agreement between you and The Qt Company. For licensing terms
** and conditions see https://www.qt.io/terms-conditions. For further
** information use the contact form at https://www.qt.io/contact-us.
**
** BSD License Usage
** Alternatively, you may use this file under the terms of the BSD license
** as follows:
**
** "Redistribution and use in source and binary forms, with or without
** modification, are permitted provided that the following conditions are
** met:
**   * Redistributions of source code must retain the above copyright
**     notice, this list of conditions and the following disclaimer.
**   * Redistributions in binary form must reproduce the above copyright
**     notice, this list of conditions and the following disclaimer in
**     the documentation and/or other materials provided with the
**     distribution.
**   * Neither the name of The Qt Company Ltd nor the names of its
**     contributors may be used to endorse or promote products derived
**     from this software without specific prior written permission.
**
**
** THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
** "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
** LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
** A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
** OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
** SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT
** LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
** DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
** THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
** (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
** OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE."
**
** $QT_END_LICENSE$
**
****************************************************************************/
//Adapted by BozoTheGeek 29/01/2022

#include "DownloadManager.h"
#include "Log.h"

#include <QTextStream>

#include <cstdio>

using namespace std;

DownloadManager::DownloadManager(QObject *parent)
    : QObject(parent)
{
}

void DownloadManager::clear(){
    downloadedCount = 0;
    totalCount = 0;
    //for message and status
    value = 0;
    maximum = -1;
    iteration = 0;
    statusMessage = "";
    statusProgress = 0.01; // not zero to consider that is started
    statusError = 0;
}

void DownloadManager::setMessage(const QString &m)
{
    statusMessage = m;
}

void DownloadManager::setSpeed(const QString &m)
{
    statusSpeed = m;
}

void DownloadManager::setError(qint64 val)
{
    statusError = val;
}

void DownloadManager::setStatus(qint64 val, qint64 max)
{
    ++iteration; // for RFU to manage when we don't have maximum
    value = val;
    maximum = max;

    if (maximum > 0) {
        statusProgress = float(value) / float(maximum);
        //Log::debug("DownloadManager", LOGMSG("setStatus: %1").arg(statusProgress));

    }
    else{
        //TO DO
    }
}

void DownloadManager::append(const QStringList &urls)
{
    for (const QString &urlAsString : urls)
        append(QUrl::fromEncoded(urlAsString.toLocal8Bit()),"");

    if (downloadQueue.isEmpty())
        QTimer::singleShot(0, this, &DownloadManager::finished);
}

void DownloadManager::append(const QUrl &url, const QString &filename)
{
    //Log::debug("DownloadManager", LOGMSG("append('%1','%2')").arg(url.toString(),filename));
    if (downloadQueue.isEmpty()){
        downloadQueue.enqueue(url);
        filenameQueue.enqueue(filename);
        ++totalCount;
        //Log::debug("DownloadManager", LOGMSG("downloadQueue.isEmpty()"));
        //wait 1s to late add list of files in queue before to start to avoid issues
        QTimer::singleShot(1000, this, &DownloadManager::startNextDownload);
    }
    else{
        downloadQueue.enqueue(url);
        filenameQueue.enqueue(filename);
        ++totalCount;
    }
}

QString DownloadManager::saveFileName(const QUrl &url)
{
    QString path = url.path();
    QString basename = QFileInfo(path).fileName();

    if (basename.isEmpty())
        basename = "download.file";

    basename = "/tmp/" + basename;

    if (QFile::exists(basename)) {
        // already exists, don't overwrite
        int i = 0;
        basename += '.';
        while (QFile::exists(basename + QString::number(i)))
            ++i;

        basename += QString::number(i);
    }
    //Log::debug("DownloadManager", LOGMSG("basename: %1").arg(basename));
    return basename;
}

void DownloadManager::startNextDownload()
{
    //Log::debug("DownloadManager", LOGMSG("startNextDownload()"));

    if (downloadQueue.isEmpty()) {
        setMessage(QString(" %1/%2 files downloaded successfully").arg(QString::number(downloadedCount),QString::number(totalCount)));
        Log::debug("DownloadManager", LOGMSG(" %1 / %2 files downloaded successfully\n").arg(QString::number(downloadedCount),QString::number(totalCount)));
        setSpeed(""); //stop speed
        emit finished();
        return;
    }

    QUrl url = downloadQueue.dequeue();
    QString filename = filenameQueue.dequeue();

    if(filename == ""){
        filename = saveFileName(url);
    }
    output.setFileName(filename);
    QByteArray rangeHeaderValue;
    qint64 existingFileSize = 0;
    if (!output.open(QIODevice::WriteOnly)) {
        setMessage(QString("Problem to save %1 : %2").arg(qPrintable(filename),
                                                          qPrintable(output.errorString())));

        Log::error("DownloadManager", LOGMSG("Problem to save %1 : %2").arg(qPrintable(filename),
                                                          qPrintable(output.errorString())));
        //set error to save file
        setError(2);

        startNextDownload();
        return;                 // skip this download
    }
    else{
        existingFileSize = output.size();
        if(existingFileSize == 0){
            setMessage(QString("Download of %1 started...").arg(output.fileName()));
            Log::debug("DownloadManager", LOGMSG("Download of %1 started...").arg(output.fileName()));
        }
        else{
            setMessage(QString("Download of %1 restarted...").arg(output.fileName()));
            Log::debug("DownloadManager", LOGMSG("Download of %1 restarted from %2 Bytes...").arg(output.fileName(),QString::number(existingFileSize)));
            rangeHeaderValue = "bytes=" + QByteArray::number(existingFileSize) + "-";
        }
    }
    QNetworkRequest request(url);
    //to restart download from existing file (if needed)
    if(existingFileSize != 0) request.setRawHeader("Range",rangeHeaderValue);
    //set timeout if no reply/transfer stop to 15 seconds
    request.setTransferTimeout(15000);

    currentDownload = manager.get(request);
    connect(currentDownload, &QNetworkReply::downloadProgress,
            this, &DownloadManager::downloadProgress);
    connect(currentDownload, &QNetworkReply::finished,
            this, &DownloadManager::downloadFinished);
    connect(currentDownload, &QNetworkReply::readyRead,
            this, &DownloadManager::downloadReadyRead);

    // prepare the output
    //Log::debug("DownloadManager", LOGMSG("Downloading %1...\n").arg(url.toEncoded().constData()));

    downloadTimer.start();
}

void DownloadManager::downloadProgress(qint64 bytesReceived, qint64 bytesTotal)
{

    //Log::debug("DownloadManager", LOGMSG("Receive: %1 / %2 Bytes").arg(QString::number(bytesReceived),QString::number(bytesTotal)));

    setMessage(QString("%1 ...").arg(output.fileName()));

    setStatus(bytesReceived, bytesTotal);

    // calculate the download speed
    double speed = bytesReceived * 1000.0 / downloadTimer.elapsed();
    QString unit;
    if (speed < 1024) {
        unit = "bytes/sec";
    } else if (speed < 1024*1024) {
        speed /= 1024;
        unit = "kB/s";
    } else {
        speed /= 1024*1024;
        unit = "MB/s";
    }

    setSpeed(QString::fromLatin1("%1 %2")
                           .arg(speed, 3, 'f', 1).arg(unit));
}

void DownloadManager::downloadFinished()
{
    //Log::debug("DownloadManager", LOGMSG("downloadFinished()"));

    output.close();

    if (currentDownload->error()) {
        // download failed
        setMessage(QString("Failed: %1").arg(qPrintable(currentDownload->errorString())));
        Log::error("DownloadManager", LOGMSG("Failed: %1").arg(qPrintable(currentDownload->errorString())));
        //don't remove to be able to manage retry in case of slow download, stop to remove output file to be able to complete it with retry.
        //set error of download
        setError(1);
    } else {
        // let's check if it was actually a redirect
        if (isHttpRedirect()) {
            QUrl redirectUrl = reportRedirect();
            output.remove();
            --totalCount;//remove the initial redirect one
            //append it to tentative to download it
            append(redirectUrl,output.fileName());
        } else {
            setMessage(QString("%1 downloaded").arg(output.fileName()));
            Log::debug("DownloadManager", LOGMSG("%1 downloaded").arg(output.fileName()));
            ++downloadedCount;
        }
    }
    currentDownload->deleteLater();
    startNextDownload();
}

void DownloadManager::downloadReadyRead()
{
    output.write(currentDownload->readAll());
}

bool DownloadManager::isHttpRedirect() const
{
    int statusCode = currentDownload->attribute(QNetworkRequest::HttpStatusCodeAttribute).toInt();
    return statusCode == 301 || statusCode == 302 || statusCode == 303
           || statusCode == 305 || statusCode == 307 || statusCode == 308;
}

QUrl DownloadManager::reportRedirect()
{
    int statusCode = currentDownload->attribute(QNetworkRequest::HttpStatusCodeAttribute).toInt();
    QUrl requestUrl = currentDownload->request().url();
    /*QTextStream(stderr) << "Request: " << requestUrl.toDisplayString()
                        << " was redirected with code: " << statusCode
                        << '\n';*/

    QVariant target = currentDownload->attribute(QNetworkRequest::RedirectionTargetAttribute);
    if (!target.isValid()){
        QUrl empty;
        return empty;
    }
    QUrl redirectUrl = target.toUrl();
    if (redirectUrl.isRelative())
        redirectUrl = requestUrl.resolved(redirectUrl);
    /*QTextStream(stderr) << "Redirected to: " << redirectUrl.toDisplayString()
                        << '\n';*/
    //return URL to be abale to download this URL also if needed
    return redirectUrl;
}
