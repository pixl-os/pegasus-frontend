// Pegasus Frontend
// Copyright (C) 2017  Mátyás Mustoha
//
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with this program. If not, see <http://www.gnu.org/licenses/>.


#include "System.h"
#include <QProcess>
#include "Log.h"


namespace model {

System::System(QObject* parent)
    : QObject(parent)
{
}

void System::quit()
{
    emit appCloseRequested(AppCloseType::QUIT);
}

void System::reboot()
{
    emit appCloseRequested(AppCloseType::REBOOT);
}

void System::restart()
{
    emit appCloseRequested(AppCloseType::RESTART);
}

void System::shutdown()
{
    emit appCloseRequested(AppCloseType::SHUTDOWN);
}

QString System::run(const QString& Command)
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

void System::runAsync(const QString& Command)
{
    //Log::debug(LOGMSG("System::runAsync_slot() put in Qt::QueuedConnection"));
    m_Command = Command;
    QMetaObject::invokeMethod(this,"runAsync_slot", Qt::QueuedConnection);
}

void System::runAsync_slot()
{
    QProcess *myProcess = new QProcess(parent());
    myProcess->startDetached(m_Command);
    m_Result = ""; //TO DO
    myProcess->destroyed();
}

QString System::getRunAsyncResult()
{
    return m_Result;
}

bool System::runBoolResult(const QString& Command, bool escaped)
{
  std::string escapedCommand(Command.toUtf8().constData());
  if(escaped){
      Strings::ReplaceAllIn(escapedCommand, "(", "\\(");
      Strings::ReplaceAllIn(escapedCommand, ")", "\\)");
      Strings::ReplaceAllIn(escapedCommand, "*", "\\*");
      Strings::ReplaceAllIn(escapedCommand, "'", "\\'");
      Strings::ReplaceAllIn(escapedCommand, "\"", "\\\"");
  }
  //Log::debug(LOGMSG("runBoolResult escaped Command : '%1'").arg(escapedCommand.c_str()));
  int exitcode = system(escapedCommand.c_str());
  return exitcode == 0;
}

} // namespace model
