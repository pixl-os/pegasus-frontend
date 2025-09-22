#include "ShellThread.h"

QString runPopen(const QString& Command)
{
    const std::string& command = Command.toUtf8().constData();
    std::string output;
    char buffer[4096];
    FILE* pipe = popen(command.data(), "r");
    if (pipe != nullptr)
    {
        while (feof(pipe) == 0)
            if (fgets(buffer, sizeof(buffer), pipe) != nullptr)
                output.append(buffer);
        pclose(pipe);
    }
    return QString::fromStdString(output);
}

ShellThread::ShellThread(const QString& command, const QString& engine, QObject* parent)
    : QThread(parent), command_(command), engine_(engine) {}

void ShellThread::run() {
    runPopen(command_);
    emit finishedShellCommand(command_);
}

