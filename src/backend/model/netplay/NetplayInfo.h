// Pegasus Frontend
//
// Created by Bozo The Geek - 23/10/2021
//

#pragma once

#include "QtQmlTricks/QQmlObjectListModel.h"
#include <QString>
#include <QObject>
#include <QTimer>

namespace model {

struct Room {
    QString game_name;
};

struct NetplayData {
	QList <Room> rooms;
};

class NetplayInfo : public QObject {
    Q_OBJECT
	
    //Q_CLASSINFO("RegisterEnumClassesUnscoped", "false")

    /*Q_PROPERTY(BatteryStatus batteryStatus READ batteryStatus NOTIFY batteryStatusChanged)
    Q_PROPERTY(bool batteryCharging READ batteryCharging NOTIFY batteryStatusChanged)
    Q_PROPERTY(float batteryPercent READ batteryPercent NOTIFY batteryLifeChanged)
    Q_PROPERTY(int batterySeconds READ batterySeconds NOTIFY batteryLifeChanged)*/

public:
#define GETTER(type, name, field) \
    type name() const { return m_data.field; }
    GETTER(const QList<Room> &, Rooms, rooms)
#undef GETTER


#define SETTER(type, name, field) \
    NetplayInfo& set##name(type val) { m_data.field = std::move(val); return *this; }
    SETTER(QList<Room>, Rooms, rooms)
#undef SETTER

    explicit NetplayInfo(QObject* parent = nullptr);

	//need specific property and invokable function due to QList<struct> is not supported by QML layer
    Q_PROPERTY(int roomsCount READ getRoomsCount CONSTANT)
    Q_INVOKABLE QString GetGameNameAt (const int index) {return m_data.rooms.at(index).game_name;};
    //Q_INVOKABLE QString GetCoreAt (const int index) {return m_data.common_emulators.at(index).core;};
    //Q_INVOKABLE QString GetPriorityAt (const int index) {return QString::number(m_data.common_emulators.at(index).priority);};

	

    /*BatteryStatus batteryStatus() const { return m_battery.status; }
    bool batteryCharging() const {
        return m_battery.status == BatteryStatus::Charging || m_battery.status == BatteryStatus::Charged;
    }
    float batteryPercent() const { return m_battery.percent; }
    int batterySeconds() const { return m_battery.seconds; }*/

signals:
    //void batteryStatusChanged();
    //void batteryLifeChanged();

private slots:
    //void poll_battery();

public:
    int getRoomsCount() const {return m_data.rooms.count();}

private:
	NetplayData m_data;
	
    //QTimer m_battery_poll;
    //BatteryInfo m_battery;
};
} // namespace model
