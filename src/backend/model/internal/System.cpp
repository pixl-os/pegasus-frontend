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

bool System::runBoolResult(const QString& Command)
{
  std::string escapedCommand(Command.toUtf8().constData());
  Strings::ReplaceAllIn(escapedCommand, "(", "\\(");
  Strings::ReplaceAllIn(escapedCommand, ")", "\\)");
  Strings::ReplaceAllIn(escapedCommand, "*", "\\*");
  Strings::ReplaceAllIn(escapedCommand, "'", "\\'");
  Strings::ReplaceAllIn(escapedCommand, "\"", "\\\"");
  int exitcode = system(escapedCommand.c_str());
  return exitcode == 0;
}

} // namespace model
