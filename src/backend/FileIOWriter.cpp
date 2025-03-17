#include "FileIOWriter.h"
//#include "Log.h"

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
        m_file->write(dataToWrite);
    }
    // Write any remaining data in the buffer
    QByteArray remainingData;
    {
        QMutexLocker locker(&m_mutex);
        remainingData = m_buffer;
    }
    m_file->write(remainingData);
    m_file->flush(); //Ensure the data is written to disk.
    m_file->close();
    emit finished();
}
