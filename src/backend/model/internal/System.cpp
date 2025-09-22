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

//added to manage action notifications provided by script manager
#include "ScriptManager.h"

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

void System::runAsync(const QString& Command, const QString& Engine)
{
    //Log::debug(LOGMSG("System::runAsync_slot() put in Qt::QueuedConnection"));
    m_Command = Command;
    m_Engine = Engine;
    QMetaObject::invokeMethod(this,"runAsync_slot", Qt::QueuedConnection);
}

void System::runAsync_slot()
{
    if(m_Engine == "popen"){
        run(m_Command);
    }
    else if(m_Engine == "QProcess"){
        QProcess *myProcess = new QProcess(parent());
        myProcess->startDetached(m_Command);
        m_Result = ""; //TO DO
        myProcess->destroyed();
    }
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

void System::notify(const QString& Action, const QString& ActionData, model::Collection* collection, model::Game* game)
{
    if(game == nullptr && collection == nullptr){
        //Log::debug(LOGMSG("NotifyFromString(Action.toUtf8().constData())"));
        if(ActionData == nullptr){
            ScriptManager::Instance().NotifyFromString(Action.toUtf8().constData());
        }
        else{
            ScriptManager::Instance().NotifyFromString(Action.toUtf8().constData(), ActionData.toUtf8().constData());
        }
    }
    else if (game == nullptr) {
        //Log::debug(LOGMSG("NotifyFromString(collection, Action.toUtf8().constData())"));
        ScriptManager::Instance().NotifyFromString(collection, Action.toUtf8().constData());
    }
    else if (collection != nullptr){
        //Log::debug(LOGMSG("NotifyFromString(collection, game, Action.toUtf8().constData())"));
        ScriptManager::Instance().NotifyFromString(collection, game, Action.toUtf8().constData());
    }    
}

QString System::currentAction()
{
    return QString::fromStdString(ScriptManager::Instance().LastAction());
}

model::Game* System::currentGame()
{
    return ScriptManager::Instance().LastGame();
}

model::Collection* System::currentCollection()
{
    return ScriptManager::Instance().LastCollection();
}

} // namespace model
