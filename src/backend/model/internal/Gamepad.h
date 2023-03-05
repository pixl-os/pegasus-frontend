// Pegasus Frontend
// Copyright (C) 2017-2019  Mátyás Mustoha
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


#pragma once

#include "types/GamepadKeyId.h"

#include <QObject>


namespace model {
class Gamepad : public QObject {
    Q_OBJECT

// TODO: a compile time map might be better
#define GEN(type, field, initval) \
    private: \
        Q_PROPERTY(type field READ field NOTIFY field##Changed) \
        type m_##field = initval; \
    public: \
        type field() const { return m_##field; } \
    private:
#define GEN_BTN(field) GEN(bool, button##field, false)
#define GEN_AXIS(field) GEN(double, axis##field, 0.0)

    GEN_BTN(Up)
    GEN_BTN(Down)
    GEN_BTN(Left)
    GEN_BTN(Right)

    GEN_BTN(North)
    GEN_BTN(South)
    GEN_BTN(East)
    GEN_BTN(West)

    GEN_BTN(L1)
    GEN_BTN(L2)
    GEN_BTN(L3)
    GEN_BTN(R1)
    GEN_BTN(R2)
    GEN_BTN(R3)

    GEN_BTN(Select)
    GEN_BTN(Start)
    GEN_BTN(Guide)

    GEN_AXIS(LeftX)
    GEN_AXIS(RightX)
    GEN_AXIS(LeftY)
    GEN_AXIS(RightY)

#undef GEN_AXIS
#undef GEN_BTN
#undef GEN

    Q_PROPERTY(QString name READ name NOTIFY nameChanged)
    Q_PROPERTY(int deviceId READ deviceId NOTIFY idChanged) //position in Gamepad #?
    Q_PROPERTY(int deviceInstance READ deviceInstance NOTIFY instanceChanged) //SDL instance
    Q_PROPERTY(int deviceIndex READ deviceIndex NOTIFY indexChanged) //SDL index (at connection and could change when any device is disconnected)
    Q_PROPERTY(QString deviceLayout READ deviceLayout NOTIFY layoutChanged) //Gamepad layout

public:
    explicit Gamepad(int device_id, QString name, int device_idd, int device_idx, QString device_layout, QObject* parent);

    int deviceId() const { return m_device_id; } // as player id
    int deviceInstance() const { return m_device_iid; } // as sdl instance id
    int deviceIndex() const { return m_device_idx; } // as index of connection and change during deconnection

    const QString& name() const { return m_name; }
    const QString& deviceLayout() const { return m_device_layout; }

    void setName(QString);
    void setId(int);
    void setInstance(int);
    void setIndex(int);
    void setLayout(QString);
    void setButtonState(GamepadButton, bool);
    void setAxisState(GamepadAxis, double);

signals:
    // NOTE: moc can't handle signals in preprocessor code
    void nameChanged(QString);
    void idChanged(int);
    void instanceChanged(int);
    void indexChanged(int);
    void layoutChanged(QString);

    void buttonUpChanged(bool);
    void buttonDownChanged(bool);
    void buttonLeftChanged(bool);
    void buttonRightChanged(bool);

    void buttonNorthChanged(bool);
    void buttonSouthChanged(bool);
    void buttonEastChanged(bool);
    void buttonWestChanged(bool);

    void buttonL1Changed(bool);
    void buttonL2Changed(bool);
    void buttonL3Changed(bool);
    void buttonR1Changed(bool);
    void buttonR2Changed(bool);
    void buttonR3Changed(bool);

    void buttonSelectChanged(bool);
    void buttonStartChanged(bool);
    void buttonGuideChanged(bool);

    void axisLeftXChanged(double);
    void axisRightXChanged(double);
    void axisLeftYChanged(double);
    void axisRightYChanged(double);

private:
    int m_device_id;
    QString m_name;
    int m_device_iid;
    int m_device_idx;
    QString m_device_layout;
};
} // namespace model
