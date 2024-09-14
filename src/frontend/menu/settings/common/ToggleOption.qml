// Pegasus Frontend
// Copyright (C) 2017  Mátyás Mustoha
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
    property alias checked: toggle.checked
    property alias symbol: symbolSubMenu.text
    property alias symbolFontSize: symbolSubMenu.font.pixelSize
    property alias symbolFontFamily: symbolSubMenu.font.family

    property int fontSize: vpx(22)
    property int horizontalPadding: vpx(30)

    width: parent.width
    height: labelContainer.height + fontSize * 1.25


    Rectangle {
        id: underline

        width: parent.width
        height: vpx(3)
        anchors.bottom: parent.bottom

        color: themeColor.underline
        visible: parent.focus || mouseArea.containsMouse
    }
    Text {
        id: symbolSubMenu
        anchors {
            //deactivate vertical centering to be better centralize for symbol finally
            //verticalCenter: parent.verticalCenter
            left: parent.left
            leftMargin: - font.pixelSize * 1.5
        }
        color: themeColor.textTitle
        font {
            bold: false
            pixelSize: fontSize * 1.25
            family: global.fonts.ion
        }
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

            color: themeColor.textLabel
            font.pixelSize: fontSize
            font.family: globalFonts.sans
        }

        Text {
            id: sublabel

            color: themeColor.textSublabel
            font.pixelSize: fontSize * 0.8
            font.family: globalFonts.sans
            font.italic: true
        }
    }

    Switch {
        id: toggle

        focus: true

        anchors.right: parent.right
        anchors.rightMargin: horizontalPadding
        anchors.verticalCenter: parent.verticalCenter

        height: fontSize * 1.15
    }

    MouseArea {
        id: mouseArea
        anchors.fill: parent
        hoverEnabled: true
        onClicked: toggle.checked = !toggle.checked
        cursorShape: Qt.PointingHandCursor
    }
}
