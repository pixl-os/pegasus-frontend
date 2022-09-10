// Pegasus Frontend
//
// Created by Bozo The Geek - 27/10/2021
//

#pragma once

#include "Rooms.h"
#include "utils/QmlHelpers.h"
#include <QString>
#include <QObject>
#include <QTimer>

namespace model {

class Netplay : public QObject {
    Q_OBJECT
    QML_CONST_PROPERTY(model::Rooms, rooms)

public:
    explicit Netplay(QObject* parent = nullptr);

signals:

private slots:

public:

private:

};
} // namespace model
