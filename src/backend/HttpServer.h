#ifndef HTTPSERVER_H
#define HTTPSERVER_H

#pragma once

#include <QObject>
#include <QTcpServer>

class HttpServer: public QTcpServer
{
Q_OBJECT
public:
    explicit HttpServer(quint16 port = 8080, QObject* parent = nullptr);
    void incomingConnection(qintptr socketDescriptor) override;
signals:
    void confReloaded(QString parameter);
};

#endif // HTTPSERVER_H
