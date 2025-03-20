#include "FileIOWriter.h"
#include "Log.h"

FileIOWriter::FileIOWriter(QFile *file, QObject *parent) : QThread(parent), m_file(file) {}

FileIOWriter::~FileIOWriter() {
    stop();
    wait();
}

void FileIOWriter::writeData(const QByteArray &data) {
    QMutexLocker locker(&m_mutex);
    //Log::debug("FileIOWriter::writeData", LOGMSG("data.size(): %1 Bytes").arg(QString::number(data.size())));
    m_buffer.append(data);
    m_condition.wakeAll();
}

void FileIOWriter::stop() {
    QMutexLocker locker(&m_mutex);
    m_running = false;
    m_condition.wakeAll();
}

void FileIOWriter::run() {
    //in case that file is not yet open, we are trying to open it in the thread
    if(!m_file->isOpen()){
        //Log::debug("FileIOWriter", LOGMSG("file not opened in thread, still to do..."));
        if(m_file->size() == 0){
            if (!m_file->open(QIODevice::WriteOnly)) {
                Log::error("FileIOWriter", LOGMSG("Problem to write %1 : %2 \n").arg(qPrintable(m_file->fileName()),
                                                                                        qPrintable(m_file->errorString())));
                emit finished();
                return;
            }
        }
        else if (!m_file->open(QIODevice::Append)) {
            Log::error("FileIOWriter", LOGMSG("Problem to append %1 : %2 \n").arg(qPrintable(m_file->fileName()),
                                                                                     qPrintable(m_file->errorString())));
            emit finished();
            return;
        }
        /*if(m_file->isOpen()){
            Log::debug("FileIOWriter", LOGMSG("file seems opened now !"));
        }*/
    }
    //else Log::debug("FileIOWriter", LOGMSG("file seems already opened !"));

    //file opened will could start to run file writing
    while (m_running) {
        QByteArray dataToWrite;
        {
            QMutexLocker locker(&m_mutex);
            if (m_buffer.isEmpty()) {
                m_condition.wait(&m_mutex);
            }
            if (!m_running && m_buffer.isEmpty()) break; //Check if running is false AND buffer is empty.
            dataToWrite = m_buffer;
            m_buffer.clear();
        }
        //Log::debug("FileIOWriter", LOGMSG("before data To Write"));
        m_file->write(dataToWrite);
        //Log::debug("FileIOWriter", LOGMSG("after data To Write"));

    }
    // Write any remaining data in the buffer
    QByteArray remainingData;
    {
        QMutexLocker locker(&m_mutex);
        remainingData = m_buffer;
    }
    //Log::debug("FileIOWriter", LOGMSG("before remaining Data"));
    m_file->write(remainingData);
    //Log::debug("FileIOWriter", LOGMSG("after remaining Data"));

    m_file->flush(); //Ensure the data is written to disk.
    m_file->close();
    emit finished();
}
