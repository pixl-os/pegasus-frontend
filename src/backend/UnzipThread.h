#ifndef UNZIPTHREAD_H
#define UNZIPTHREAD_H

#include <QThread>
#include <QString>

class UnzipThread : public QThread {
    Q_OBJECT

public:
    UnzipThread(const QString& zipFilePath, const QString& destinationPath, QObject* parent = nullptr);
    void run() override;

signals:
    void finishedUnzipping(const QString& zipFilePath);
    void fileUnzipped(const QString& fileName);
    void errorOccurred(const QString& errorMessage);

private:
    QString zipFilePath_;
    QString destinationPath_;
};

#endif // UNZIPTHREAD_H
