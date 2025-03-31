// unzipthreadzlib.h
#ifndef UNZIPTHREADZLIB_H
#define UNZIPTHREADZLIB_H

#include <QThread>
#include <QString>

class UnzipThreadZlib : public QThread {
    Q_OBJECT

public:
    UnzipThreadZlib(const QString& zipFilePath, const QString& destinationPath, QObject* parent = nullptr);
    void run() override;

signals:
    void finishedUnzipping();
    void fileUnzipped(const QString& fileName);
    void errorOccurred(const QString& errorMessage);

private:
    QString zipFilePath_;
    QString destinationPath_;
};

#endif // UNZIPTHREADZLIB_H
