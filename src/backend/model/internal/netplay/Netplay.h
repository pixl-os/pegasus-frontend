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
    //Q_PROPERTY(int RoomsCount READ getRoomsCount CONSTANT)
    
    //Q_INVOKABLE void UpdateRooms();


signals:
    //void batteryStatusChanged();
    //void batteryLifeChanged();

private slots:
    //void poll_battery();

public:
    //int getRoomsCount() const {return rooms.count();}

private:
	//QTimer m_battery_poll;
    //BatteryInfo m_battery;
};
} // namespace model
