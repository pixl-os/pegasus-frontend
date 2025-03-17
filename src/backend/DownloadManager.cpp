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

//#include <cstdio>

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
        append(QUrl::fromEncoded(urlAsString.toLocal8Bit()),"",0);

    if (downloadQueue.isEmpty())
        QTimer::singleShot(0, this, &DownloadManager::finished);
}

void DownloadManager::append(const QUrl &url, const QString &filename)
{
    //Log::debug("DownloadManager", LOGMSG("append('%1','%2','%3')").arg(url.toString(),filename));
    append(url, filename, 0);
}

void DownloadManager::append(const QUrl &url, const QString &filename, const qint64 filesize)
{
    //Log::debug("DownloadManager", LOGMSG("append('%1','%2')").arg(url.toString(),filename));
    if (downloadQueue.isEmpty()){
        downloadQueue.enqueue(url);
        filenameQueue.enqueue(filename);
        filesizeQueue.enqueue(filesize);
        ++totalCount;
        //Log::debug("DownloadManager", LOGMSG("downloadQueue.isEmpty()"));
        //wait 1s to late add list of files in queue before to start to avoid issues
        QTimer::singleShot(1000, this, &DownloadManager::startNextDownload);
    }
    else{
        downloadQueue.enqueue(url);
        filenameQueue.enqueue(filename);
        filesizeQueue.enqueue(filesize);
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
    outputTargetedSize = filesizeQueue.dequeue();
    Log::debug("DownloadManager", LOGMSG("initial outputTargetedSize:  %1 \n").arg(QString::number(outputTargetedSize)));
    if(filename == ""){
        filename = saveFileName(url);
    }
    // Check if the directory exists
    QDir directory(QFileInfo(filename).dir());  // Get directory from file path
    if (!directory.exists()) {
        // Create the directory (including any parent directories)
        if (!directory.mkpath(directory.absolutePath())) {
            // Handle error if directory creation fails (e.g., permission issues)
            Log::error("DownloadManager", LOGMSG("Failed to create directory: %1").arg(directory.absolutePath()));
        }
    }
    output.setFileName(filename);
    QByteArray rangeHeaderValue;
    qint64 existingFileSize = 0;

    if (!QFile::exists(filename) || (outputTargetedSize == 0)) {
        if (!output.open(QIODevice::WriteOnly)) {
            setMessage(QString("Problem to write %1 : %2").arg(qPrintable(filename),
                                                              qPrintable(output.errorString())));

            Log::error("DownloadManager", LOGMSG("Problem to write %1 : %2").arg(qPrintable(filename),
                                                              qPrintable(output.errorString())));
            //set error to save file
            setError(2);

            startNextDownload();
            return;                 // skip this download
        }
    }
    else {
        if (!output.open(QIODevice::Append)) {
            setMessage(QString("Problem to append %1 : %2").arg(qPrintable(filename),
                                                              qPrintable(output.errorString())));

            Log::error("DownloadManager", LOGMSG("Problem to append %1 : %2").arg(qPrintable(filename),
                                                                                qPrintable(output.errorString())));
            //set error to append file
            setError(3);

            startNextDownload();
            return;                 // skip this download
        }
        else {
            existingFileSize = output.size();
        }
    }

    if(existingFileSize == 0) {
        setMessage(QString("Download of %1 started...").arg(output.fileName()));
        Log::debug("DownloadManager", LOGMSG("Download of %1 started...").arg(output.fileName()));
    }
    else if((existingFileSize >= outputTargetedSize) && (outputTargetedSize != 0)) {
        downloadedCount++; //we consider it as already downloaded
        setMessage(QString("%1 already downloaded").arg(output.fileName()));
        Log::debug("DownloadManager", LOGMSG("%1 already downloaded").arg(output.fileName()));
        output.close();
        startNextDownload();
        return; // skip this download
    }
    else {
        setMessage(QString("Download of %1 restarted...").arg(output.fileName()));
        Log::debug("DownloadManager", LOGMSG("Download of %1 restarted from %2 Bytes...").arg(output.fileName(),QString::number(existingFileSize)));
        rangeHeaderValue = "bytes=" + QByteArray::number(existingFileSize) + "-";
    }

    m_fileWriter = new FileIOWriter(&output, this);
    connect(m_fileWriter, &FileIOWriter::finished, this, [this](){
        Log::debug("DownloadManager", LOGMSG("m_fileWriter finished !!!"));
        DownloadManager::writeFinished();
    });
    m_fileWriter->start();

    QNetworkRequest request(url);
    //to restart download from existing file (if needed)
    if(existingFileSize != 0) request.setRawHeader("Range",rangeHeaderValue);
    //set timeout if no reply/transfer stop to 15 seconds
    request.setTransferTimeout(15000);

    QNetworkReply *reply = manager.get(request); // Only call get() once

    currentDownload = reply; // store the reply in currentDownload

    QObject::connect(reply, &QNetworkReply::downloadProgress,
                     this, &DownloadManager::downloadProgress);
    QObject::connect(reply, &QNetworkReply::readyRead,
                     this, &DownloadManager::downloadReadyRead);
    QObject::connect(reply, &QNetworkReply::finished,
                     this, &DownloadManager::downloadFinished);

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

void DownloadManager::downloadFinished(){
    Log::debug("DownloadManager", LOGMSG("downloadFinished !!!"));

    QNetworkReply *reply = qobject_cast<QNetworkReply *>(sender());
    if (!reply){
        Log::error("DownloadManager", LOGMSG("Failed: no sender reply retreived when downloadFinished !!!"));
        return;
    }

    if (reply->error()) {
        // download failed
        setMessage(QString("Failed: %1").arg(qPrintable(reply->errorString())));
        Log::error("DownloadManager", LOGMSG("Failed: %1").arg(qPrintable(reply->errorString())));
        //don't remove to be able to manage retry in case of slow download, stop to remove output file to be able to complete it with retry.
        //set error of download
        setError(1);
    }
    else {
        // let's check if it was actually a redirect
        if (isHttpRedirect(reply)) {
            QUrl redirectUrl = reportRedirect(reply);
            output.remove();
            --totalCount;//remove the initial redirect one
            //append it to tentative to download it
            append(redirectUrl,output.fileName());
        }
    }
    reply->deleteLater();
    m_fileWriter->stop();
}

void DownloadManager::writeFinished(){
    Log::debug("DownloadManager", LOGMSG("writeFinished() of %1 Bytes ").arg(QString::number(output.size())));

    setMessage(QString("%1 downloaded").arg(output.fileName()));
    Log::debug("DownloadManager", LOGMSG("%1 downloaded").arg(output.fileName()));
    Log::debug("DownloadManager", LOGMSG("outputTargetedSize : %1").arg(QString::number(outputTargetedSize)));
    Log::debug("DownloadManager", LOGMSG("output.size() : %1").arg(QString::number(output.size())));
    if((outputTargetedSize != 0) && (outputTargetedSize != output.size())){
        setMessage(QString("%1 has wrong size downloaded !").arg(output.fileName()));
        Log::debug("DownloadManager", LOGMSG("%1 has wrong size downloaded !").arg(output.fileName()));
        //set error of wrong size downloaded
        setError(4);
        //we remove in this case to retry
        output.remove();
    }
    else{
        ++downloadedCount;
    }
    startNextDownload();
}

void DownloadManager::downloadReadyRead()
{
    QNetworkReply *reply = qobject_cast<QNetworkReply *>(sender());
    if (!reply){
        Log::error("DownloadManager", LOGMSG("Failed: no sender reply retreived when downloadReadyRead !!!"));
        return;
    }
    QByteArray data = reply->readAll();
    //Log::debug("DownloadManager", LOGMSG("data.size(): %1 Bytes").arg(QString::number(data.size())));
    m_fileWriter->writeData(data);
}

bool DownloadManager::isHttpRedirect(QNetworkReply *reply) const
{
    int statusCode = reply->attribute(QNetworkRequest::HttpStatusCodeAttribute).toInt();
    return statusCode == 301 || statusCode == 302 || statusCode == 303
           || statusCode == 305 || statusCode == 307 || statusCode == 308;
}

QUrl DownloadManager::reportRedirect(QNetworkReply *reply)
{
    int statusCode = reply->attribute(QNetworkRequest::HttpStatusCodeAttribute).toInt();
    QUrl requestUrl = reply->request().url();
    /*QTextStream(stderr) << "Request: " << requestUrl.toDisplayString()
                        << " was redirected with code: " << statusCode
                        << '\n';*/

    QVariant target = reply->attribute(QNetworkRequest::RedirectionTargetAttribute);
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
