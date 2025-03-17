#ifndef FILEIOWRITER_H
#define FILEIOWRITER_H

#include <QThread>
#include <QFile>
#include <QMutex>
#include <QWaitCondition>

class FileIOWriter : public QThread {
    Q_OBJECT

public:
    FileIOWriter(QFile *file, QObject *parent = nullptr);
    ~FileIOWriter();
    void writeData(const QByteArray &data);
    void stop();

signals:
    void finished();

protected:
    void run() override;

private:
    QFile *m_file;
    QMutex m_mutex;
    QWaitCondition m_condition;
    QByteArray m_buffer;
    bool m_running = true;
};

#endif // FILEIOWRITER_H
