#include <QTcpServer>
#include <QTcpSocket>
#include <QTextStream>
#include <QDateTime>
#include <QUrl>
#include <HttpServer.h>

//For recalbox
#include "RecalboxConf.h"

HttpServer::HttpServer(quint16 port, QObject* parent){
    listen(QHostAddress::Any, port);
}

void HttpServer::incomingConnection(qintptr socketDescriptor) {
        Log::debug(LOGMSG("HttpServer::incomingConnection()"));
        QTcpSocket* socket = new QTcpSocket(this);
        socket->setSocketDescriptor(socketDescriptor);
        socket->waitForReadyRead(1000); // 1 second max
        QString request = socket->readLine();
        Log::debug(LOGMSG("request : %1").arg(request));
        QString method = request.split(' ')[0];
        Log::debug(LOGMSG("method : %1").arg(method));
        QTextStream out(socket);
        if(request.split(' ').count() < 2){
            Log::debug(LOGMSG("Bad request"));
            out << "<h1>400 Bad request</h1>";
        }
        else{
            QString uri = request.split(' ')[1];
            Log::debug(LOGMSG("uri : %1").arg(uri));
            out << "HTTP/1.0 200 OK\r\n";
            out << "Content-Type: text/html; charset=utf-8\r\n";
            out << "\r\n";
            if (method == "GET") {
              if (uri == "/api") {
                out << "<h1>HTTP 'GET' API available</h1>\n";
                out << "<p>Date and Time are : " << QDateTime::currentDateTime().toString() << "</p>\n";
                out << "<p>Request received : " << request << "</p>\n";
              }
              else if (uri.toLower() == "/api?conf=reload"){
                RecalboxConf::Instance().Reload();
                out << "<h1>OK</h1>";
              }
              else if (uri.toLower().contains("/api?conf=reload&parameter=")){
                QString parameter = uri.split('&')[1];
                QString parameterName = parameter.split('=')[1];
                //Log::debug(LOGMSG("parameterName : %1").arg(parameterName));
                QString PreviousValue = QString::fromStdString(RecalboxConf::Instance().AsString(parameterName.toStdString()));
                //Log::debug(LOGMSG("PreviousValue : %1").arg(PreviousValue));
                RecalboxConf::Instance().ReloadValue(parameterName.toStdString());
                emit  confReloaded(parameterName);
                QString UpdatedValue = QString::fromStdString(RecalboxConf::Instance().AsString(parameterName.toStdString()));
                //Log::debug(LOGMSG("UpdatedValue : %1").arg(UpdatedValue));
                out << "<h1>" + parameterName + "=" + UpdatedValue + "</h1>";
              }
              else if (uri.toLower().contains("/api?action=")){
                QString action = uri.split('?')[1];
                QString actionName = "";
                QString parametersList = "";
                if (uri.toLower().contains("&")){
                  actionName = action.split('=')[1].split('&')[0];
                  int index = action.indexOf('&');
                  parametersList = action.mid(index + 1);
                }
                else{
                  actionName = action.split('=')[1];
                }
                //Log::debug(LOGMSG("actionName : %1").arg(actionName));
                //Log::debug(LOGMSG("parametersList : %1").arg(parametersList));

                emit requestAction(actionName, parametersList);
                out << "<h1>" + actionName + "</h1>";
              }
              else if (uri.toLower().contains("/api?popup&title=")){ // format: "?popup&title={title}&message={message}&icon={icon}&delay={delay}"
                  QUrl url(uri);
                  QString action = url.toString(QUrl::FullyDecoded).split('?')[1];
                  //Log::debug(LOGMSG("action : %1").arg(action));
                  QString title = action.split('&')[1].split('=')[1];
                  QString message = action.split('&')[2].split('=')[1];
                  QString icon = action.split('&')[3].split('=')[1];
                  int delay = action.split('&')[4].split('=')[1].toInt();
                  emit displayPopup(title, message, icon, delay);
                  out << "<h1>" + action + "</h1>";
              }
              else {
                out << "<h1>404 Not Found</h1>";
              }
            }
            else {
              out << "<h1>405 Method Not Allowed</h1>";
            }
        }
        socket->flush();
        socket->close();
}
