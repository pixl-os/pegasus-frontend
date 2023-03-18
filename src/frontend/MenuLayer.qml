// Pegasus Frontend
// Copyright (C) 2017-2018  Mátyás Mustoha
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


import "menu"
import QtQuick 2.12


FocusScope {
    id: root

    signal close()
    signal requestShutdown()
    signal requestReboot()
	signal requestRestart()
    signal requestRebootForSettings()
    signal requestRestartForSettings()
    signal requestQuit()

    function triggerClose() {
        root.state = "";
        root.close();
    }
    function openScreen(url) {
        subscreen.source = url;
        subscreen.focus = true;
        root.state = "sub";
    }

    anchors.fill: parent
    visible: shade.opacity > 0

    enabled: focus
    onFocusChanged: if (focus) root.state = "menu";


    Rectangle {
        id: shade
        anchors.left: parent.left
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        anchors.right: menuPanel.left

        color: "#000"
        opacity: root.focus ? 0.75 : 0
        visible: opacity > 0.001 && width > 0
        Behavior on opacity { NumberAnimation { duration: 300 } }

        Text {
            id: revision

            text: api.internal.meta.buildName 
					+ " " + api.internal.meta.gitRevision + "," + api.internal.meta.gitDate
					+ " BUILD: " + api.internal.meta.buildDate + " " + api.internal.meta.buildVersion  
                    + " OS: " + api.internal.system.run("cat /recalbox/recalbox.version 2> /dev/null");
            color: "#eee"
            font.pixelSize: vpx(12)
            font.family: global.fonts.mono

            anchors.left: parent.left
            anchors.bottom: parent.bottom
            anchors.margins: vpx(10)
        }

        MouseArea {
            anchors.fill: parent
            acceptedButtons: Qt.LeftButton | Qt.RightButton
            onClicked: root.triggerClose()
        }
    }

    MainMenuPanel {
        id: menuPanel
        anchors.left: parent.right

        focus: true

        // add recalbox menu
        onShowUpdates: root.openScreen("menu/Updates.qml")
        onShowAccountSettings: root.openScreen("menu/AccountSettings.qml")
        onShowControllersSettings: root.openScreen("menu/ControllersSettings.qml")
        onShowGamesSettings: root.openScreen("menu/GamesSettings.qml")
        onShowInterfaceSettings: root.openScreen("menu/InterfaceSettings.qml")
        onShowSystemSettings: root.openScreen("menu/SystemSettings.qml")

        // onShowSettingsScreen: root.openScreen("menu/SettingsScreen.qml")
        // onShowHelpScreen: root.openScreen("menu/HelpScreen.qml")

        onClose: root.triggerClose()
        onRequestShutdown: root.requestShutdown()
        onRequestReboot: root.requestReboot()
		onRequestRestart: root.requestRestart()
        onRequestRebootForSettings: root.requestRebootForSettings()
        onRequestRestartForSettings: root.requestRestartForSettings()
        onRequestQuit: root.requestQuit()
    }

    Loader {
        id: subscreen
        asynchronous: true

        width: parent.width
        height: parent.height
        anchors.left: menuPanel.right

        enabled: focus
        onFocusChanged: if (item) item.focus = focus;
        onLoaded: item.focus = focus

        Rectangle {
            anchors.fill: parent
            color: themeColor.main
            z: -1
        }
    }
    Connections {
        target: subscreen.item
        function onClose() {
            menuPanel.focus = true;
            root.state = "menu";
        }
    }


    states: [
        State {
            name: "menu"
            AnchorChanges {
                target: menuPanel;
                anchors.left: undefined
                anchors.right: parent.right;
            }
        },
        State {
            name: "sub"
            AnchorChanges {
                target: menuPanel;
                anchors.left: undefined
                anchors.right: subscreen.left
            }
            AnchorChanges {
                target: subscreen;
                anchors.left: undefined
                anchors.right: parent.right
            }
        }
    ]

    // fancy easing curves, a la material design
    readonly property var bezierDecelerate: [ 0,0, 0.2,1, 1,1 ]
    readonly property var bezierSharp: [ 0.4,0, 0.6,1, 1,1 ]
    readonly property var bezierStandard: [ 0.4,0, 0.2,1, 1,1 ]

    transitions: [
        Transition {
            from: ""; to: "menu"
            AnchorAnimation {
                duration: 225
                easing { type: Easing.Bezier; bezierCurve: bezierDecelerate }
            }
        },
        Transition {
            from: "menu"; to: ""
            AnchorAnimation {
                duration: 200
                easing { type: Easing.Bezier; bezierCurve: bezierSharp }
            }
            onRunningChanged: if (!running) subscreen.source = ""
        },
        Transition {
            from: "menu"; to: "sub"
            AnchorAnimation {
                duration: 425
                easing { type: Easing.Bezier; bezierCurve: bezierStandard }
            }
        },
        Transition {
            from: "sub"; to: "menu"
            AnchorAnimation {
                duration: 425
                easing { type: Easing.Bezier; bezierCurve: bezierStandard }
            }
        }
    ]
}
