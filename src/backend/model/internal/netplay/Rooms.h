// Pegasus Frontend
//
// Created by Bozo The Geek - 27/10/2021
//
#pragma once

#include "utils/MoveOnly.h"
#include <QAbstractListModel>

namespace model {
struct RoomEntry {
      int id; // "id": 474269,
      QString username; //"username": "Anonymous",
      QString country; //"country": "us",
      QString game_name; //"game_name": "Aero Fighters ",
      QString game_crc; //"game_crc": "9F8D3323",
      QString core_name; //"core_name": "Snes9x",
      QString core_version; //"core_version": "1.60 7235219",
      QString subsystem_name; //"subsystem_name": "N/A",
      QString retroarch_version; //"retroarch_version": "1.9.11",
      QString frontend; //"frontend": "unix ARMv8",
      QString ip; //"ip": "24.156.110.18",
      int port; //"port": 55436,
      QString mitm_ip; //"mitm_ip": "",
      int mitm_port; //"mitm_port": 0,
      int host_method; //"host_method": 0,
      bool has_password; //"has_password": true,
      bool has_spectate_password; //"has_spectate_password": false,
      QString created; //"created": "2021-10-27T15:44:24.253326Z",
      QString updated; //"updated": "2021-10-27T15:44:34.344168Z"
      //for later// QString lobby_type; // set by Pegasus : "retroarch" or "dolphin" or ...

	  RoomEntry(int, QString, QString, QString, QString, QString, QString, QString, QString, QString, QString,
			   int, QString, int, int, bool, bool, QString, QString);
      MOVE_ONLY(RoomEntry)
};


class Rooms : public QAbstractListModel {
    Q_OBJECT
    Q_PROPERTY(int currentIndex READ currentIndex WRITE setCurrentIndex NOTIFY roomsChanged)
	
public:
    explicit Rooms(QObject* parent = nullptr);

    enum Roles {
        Id = Qt::UserRole + 1,
		Username,
		Country,
		Game_name,
		Game_crc,
		Core_name,
		Core_version,
        Subsystem_name,
		Retroarch_version,
		Frontend,
        Ip,
        Port,
        Mitm_ip,
        Mitm_port,
        Host_method,
        Has_password,
        Has_spectate_password,
        Created,
        Updated,
	};

    int rowCount(const QModelIndex& parent = QModelIndex()) const override;
    QVariant data(const QModelIndex& index, int role = Qt::DisplayRole) const override;
    QHash<int, QByteArray> roleNames() const override { return m_role_names; }

    int currentIndex() const { return static_cast<int>(m_current_idx); }
    void setCurrentIndex(int);
    bool find_available_rooms(QString log_tag, const QJsonDocument& json, std::vector<model::RoomEntry>& roomsEntry);
    Q_INVOKABLE void refresh();
    Q_INVOKABLE void reset();

private slots:
    void reset_slot();
    void refresh_slot();


signals:
    void roomsChanged();

private:
    const QHash<int, QByteArray> m_role_names;

    std::vector<RoomEntry> m_Rooms;

    //QString m_Room;
    
    size_t m_current_idx;

};
} // namespace model
