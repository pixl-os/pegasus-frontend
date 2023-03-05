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


#include "Gamepad.h"

namespace model {

Gamepad::Gamepad(const int device_id, QString name, const int device_iid, const int device_idx, QString device_layout, QObject* parent)
    : QObject(parent)
    , m_device_id(device_id)
    , m_name(std::move(name))
    , m_device_iid(device_iid)
    , m_device_idx(device_idx)
    , m_device_layout(device_layout)
{}

void Gamepad::setName(QString name)
{
    m_name = std::move(name);
    emit nameChanged(m_name);
}

void Gamepad::setId(const int device_id)
{
    m_device_id = device_id;
    emit idChanged(m_device_id);
}

void Gamepad::setInstance(const int device_iid)
{
    m_device_iid = device_iid;
    emit instanceChanged(m_device_iid);
}

void Gamepad::setIndex(const int device_idx)
{
    m_device_idx = device_idx;
    emit indexChanged(m_device_idx);
}

void Gamepad::setLayout(QString device_layout)
{
    m_device_layout = std::move(device_layout);
    emit layoutChanged(m_device_layout);
}

void Gamepad::setButtonState(GamepadButton button, bool pressed)
{
#define GEN(key, target) \
    case GamepadButton::key: \
        m_button##target = pressed; \
        emit button##target##Changed(m_button##target); \
        break

    switch (button) {
        GEN(UP, Up);
        GEN(DOWN, Down);
        GEN(LEFT, Left);
        GEN(RIGHT, Right);
        GEN(SOUTH, South);
        GEN(EAST, East);
        GEN(WEST, West);
        GEN(NORTH, North);
        GEN(L1, L1);
        GEN(L2, L2);
        GEN(L3, L3);
        GEN(R1, R1);
        GEN(R2, R2);
        GEN(R3, R3);
        GEN(SELECT, Select);
        GEN(START, Start);
        GEN(GUIDE, Guide);
        default:
            break;
    }

#undef GEN
}

void Gamepad::setAxisState(GamepadAxis button, double value)
{
#define GEN(key, target) \
    case GamepadAxis::key: \
        m_axis##target = value; \
        emit axis##target##Changed(m_axis##target); \
        break

    switch (button) {
        GEN(LEFTX, LeftX);
        GEN(LEFTY, LeftY);
        GEN(RIGHTX, RightX);
        GEN(RIGHTY, RightY);
        default:
            break;
    }

#undef GEN
}

} // namespace model
