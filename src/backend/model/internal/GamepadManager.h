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

#include "CliArgs.h"
#include "Gamepad.h"
#include "GamepadManagerBackend.h"
#include "utils/HashMap.h"

#include "QtQmlTricks/QQmlObjectListModel.h"
#include <QObject>
#include <QString>
#include <QVector>

#ifndef Q_OS_ANDROID
#  include "GamepadAxisNavigation.h"
#  include "GamepadButtonNavigation.h"
#endif


namespace model {

class GamepadManager : public QObject {
    Q_OBJECT
    Q_CLASSINFO("RegisterEnumClassesUnscoped", "false")

    QML_OBJMODEL_PROPERTY(Gamepad, devices)

public:
    explicit GamepadManager(const backend::CliArgs& args, QObject* parent = nullptr);

    enum class GMButton {
        Invalid,
        Up, Down, Left, Right,
        North, South, East, West,
        L1, L2, L3,
        R1, R2, R3,
        Select,
        Start,
        Guide,
    };
    Q_ENUM(GMButton)

    enum class GMAxis {
        Invalid,
        LeftX, LeftY,
        RightX, RightY,
    };
    Q_ENUM(GMAxis)

    Q_INVOKABLE void configureButton(int deviceId, model::GamepadManager::GMButton button);
    Q_INVOKABLE void configureAxis(int deviceId, model::GamepadManager::GMAxis axis, QString sign);
    Q_INVOKABLE void resetButton(int deviceId, model::GamepadManager::GMButton button);
    Q_INVOKABLE void resetAxis(int deviceId, model::GamepadManager::GMAxis axis);
    Q_INVOKABLE void cancelConfiguration();
    Q_INVOKABLE void swap(int, int);

signals:
    void buttonConfigured(int deviceId, model::GamepadManager::GMButton button);
    void axisConfigured(int deviceId, model::GamepadManager::GMAxis axis);
    void configurationCanceled(int deviceId);
    
    void showPopup(QString title, QString message, QString icon, int delay);
	void newController(int device_idx, QString message);

private slots:
    void bkOnConnected(int, QString, QString, QString, QString, int);
    void bkOnDisconnected(int);
    void bkOnNewController(int, QString);
    void bkOnNameChanged(int, QString);
	void bkOnIndexChanged(int, int);
    void bkOnLayoutChanged(int, QString);
    void bkOnRemoved(int);

    void bkOnButtonCfg(int, GamepadButton);
    void bkOnAxisCfg(int, GamepadAxis);

    void bkOnButtonChanged(int, GamepadButton, bool);
    void bkOnAxisChanged(int, GamepadAxis, double);

private:
    const QString m_log_tag;
    GamepadManagerBackend* const m_backend;

#ifndef Q_OS_ANDROID
    GamepadButtonNavigation padbuttonnav;
    GamepadAxisNavigation padaxisnav;
#endif
};

} // namespace model

