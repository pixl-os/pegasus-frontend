#ifndef SHELLTHREAD_H
#define SHELLTHREAD_H

#include <QThread>
#include <QString>

class ShellThread : public QThread {
    Q_OBJECT

public:
    ShellThread(const QString& command, const QString& engine, QObject* parent = nullptr);
    void run() override;

signals:
    void finishedShellCommand(const QString& command);

private:
    QString command_;
    QString engine_;
};

#endif // SHELLTHREAD_H
