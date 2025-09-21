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


import QtQuick 2.12


FocusScope {
    id: root

    property alias label: label.text
    property alias note: sublabel.text
    property alias pointerIcon: pointerConfigs.visible
    property bool showUnderline: true
    property bool selectButton: false
    property int wrapMode: Text.WordWrap


    readonly property int fontSize: vpx(22)
    readonly property int horizontalPadding: vpx(30)

    signal activate()


    width: parent.width
    //    height: fontSize * 2.5
    height: labelContainer.height + fontSize * 1.25

    Keys.onPressed: {
        if (api.keys.isAccept(event) && !event.isAutoRepeat) {
            event.accepted = true;
            root.activate();
        }
    }

    Rectangle {
        id: underline

        width: parent.width
        height: vpx(3)
        anchors.bottom: parent.bottom

        color: themeColor.underline
        visible: (parent.focus || mouseArea.containsMouse) && showUnderline
    }
    Rectangle {
        id: buttonSelection

        anchors.fill: parent

        color: themeColor.secondary
        opacity: 0.5
        radius: vpx(10)

        visible: selectButton
    }
    Column {
        id: labelContainer

        anchors {
            left: parent.left; leftMargin: horizontalPadding
            right: parent.horizontalCenter
            verticalCenter: parent.verticalCenter
        }

        spacing: fontSize * 0.25
        height: label.height + (sublabel.text ? spacing + sublabel.height : 0)


        Text {
            id: label
            maximumLineCount: (root.wrapMode === Text.NoWrap) ? 1 : 2
            color: themeColor.textLabel
            font.pixelSize: fontSize
            font.family: globalFonts.sans
            width: underline.width
            wrapMode: root.wrapMode
        }

        Text {
            id: sublabel

            color: themeColor.textSublabel
            font.pixelSize: fontSize * 0.8
            font.family: globalFonts.sans
            font.italic: true
            width: underline.width
            wrapMode: Text.WordWrap
        }
    }
    Text {
        id: pointerConfigs
        visible: false
        anchors {
            rightMargin: vpx(20)
            right: parent.right
            verticalCenter: parent.verticalCenter
        }
        color: themeColor.underline
        font.pixelSize: vpx(30)
        font.family: globalFonts.ion
        text : "\uf3d1"
    }
    MouseArea {
        id: mouseArea
        anchors.fill: parent
        hoverEnabled: true
        onClicked: activate()
        cursorShape: Qt.PointingHandCursor
    }
}
