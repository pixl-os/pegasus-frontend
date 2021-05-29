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


import "common"
import QtQuick 2.12
import QtQuick.Layouts 1.0
import QtQuick.Controls 2.15 as Controls
import QtQuick.VirtualKeyboard 2.15
import QtQuick.VirtualKeyboard.Settings 2.15
import QtQuick.Window 2.12

FocusScope {
    id: root

    property bool mSettingsChanged: false
    //disable handwriting
    property bool handwritingInputPanelActive: false

    signal close

    anchors.fill: parent

    enabled: focus
    visible: opacity > 0.001
    opacity: focus ? 1.0 : 0.0
    Behavior on opacity { PropertyAnimation { duration: 150 } }

    function closeMaybe() {
        root.close();
    }

    Keys.onPressed: {
        if (api.keys.isCancel(event) && !event.isAutoRepeat) {
            event.accepted = true;
            root.closeMaybe();
        }
    }
    //    change keyboard style
    Component.onCompleted: {
        VirtualKeyboardSettings.styleName = "retro"
        VirtualKeyboardSettings.fullScreenMode = false;
    }

    Rectangle {
        id: shade

        anchors.fill: parent
        color: "#000"
        opacity: 0.75

        MouseArea {
            anchors.fill: parent
            acceptedButtons: Qt.LeftButton | Qt.RightButton
            onClicked: root.closeMaybe()
        }
    }
    Flickable {
        id: flickable
        anchors.fill: parent
        contentWidth: content.width
        contentHeight: content.height
        interactive: contentHeight > height
        flickableDirection: Flickable.VerticalFlick

        property real scrollMarginVertical: 10

        Column {
            id: textEditors
            anchors.topMargin: vpx(200)
            spacing: vpx(20)
            //           y: 720 / 3
            width: parent.width - 26

            Text {
                color: themeColor.underline
                text: "message de connexion a faire !! "
                anchors.horizontalCenter: parent.horizontalCenter
                font.pixelSize: 20
            }
//            TextField {
//                id: pseudoInput
//                width: parent.width / 2.5
//                horizontalAlignment: TextInput.AlignHCenter
//                placeholderText: "Pseudo"
//                text: api.internal.recalbox.getStringParameter("global.retroachievements.username")
//                anchors.horizontalCenter: parent.horizontalCenter
//                echoMode: TextInput.Normal
//                enterKeyAction: EnterKeyAction.Next
//                onAccepted: api.internal.recalbox.setStringParameter("global.retroachievements.username", pseudoInput.text)
//            }
//            TextField {
//                id: passwordInput
//                width: parent.width / 2.5
//                placeholderText: "password"
//                text: api.internal.recalbox.getStringParameter("global.retroachievements.password")
//                horizontalAlignment: TextInput.AlignHCenter
//                anchors.horizontalCenter: parent.horizontalCenter
//                echoMode: TextInput.PasswordEchoOnEdit
//                //                enterKeyAction: EnterKeyAction.Next
//                inputMethodHints: Qt.ImhNoAutoUppercase | Qt.ImhPreferLowercase | Qt.ImhSensitiveData | Qt.ImhNoPredictiveText
//                onAccepted: api.internal.recalbox.setStringParameter("global.retroachievements.password", passwordInput.text)
//            }
        }
        Rectangle {
            id: validationButton
            color: themeColor.main
            radius: vpx(8)
            anchors.centerIn: textEditors
            anchors.top: TextField.bottom
            width: parent.width / 2.5
            height: TextField.height
            Text {
                text: qsTr("Connexion")
                horizontalAlignment: validationButton.AlignHCenter
            }
        }
    }
}
