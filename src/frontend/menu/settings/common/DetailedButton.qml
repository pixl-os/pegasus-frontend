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
    property alias screenshot: screenshot.source
    property alias detailed_line1: line1.text
    property alias detailed_line2: line2.text
    property alias detailed_line3: line3.text
    property alias detailed_line4: line4.text
    property alias detailed_line5: line5.text



    readonly property int fontSize: vpx(22)
    readonly property int horizontalPadding: vpx(30)

    signal activate()


    width: parent.width
//    height: fontSize * 2.5
    height: labelContainer.height + vpx(10) //fontSize * 1.25 //focus ? labelContainer.height + vpx(50)) : labelContainer.height // + fontSize * 1.25)

    Keys.onPressed: {
        if (api.keys.isAccept(event) && !event.isAutoRepeat) {
            event.accepted = true;
            root.activate();
        }
    }

    Rectangle {
        id: topline

        width: parent.width
        height: vpx(3)
        anchors.bottom: parent.top

        color: themeColor.underline
        visible: parent.focus //|| mouseArea.containsMouse
    }

    Rectangle {
        id: leftline

        width: vpx(3)
        height: parent.height
        anchors.top: parent.top
        anchors.left: parent.left

        color: themeColor.underline
        visible: parent.focus //||  mouseArea.containsMouse
    }

    Rectangle {
        id: rightline

        width: vpx(3)
        height: parent.height
        anchors.top: parent.top
        anchors.right: parent.right

        color: themeColor.underline
        visible: parent.focus //|| mouseArea.containsMouse
    }


    Rectangle {
        id: underline

        width: parent.width
        height: vpx(3)
        anchors.bottom: parent.bottom

        color: themeColor.underline
        visible: parent.focus //|| mouseArea.containsMouse
    }

    Column {
        id: labelContainer

        anchors {
            left: parent.left; leftMargin: horizontalPadding
            top: parent.top
            //right: parent.horizontalCenter
            //verticalCenter: parent.verticalCenter
        }

        spacing: fontSize * 0.25

        //just to ahve a space at the top
        Row{
            Text{
                height: vpx(2)
                text: " "
            }
        }

        Row{
            height: label.height // + (sublabel.text ? spacing + sublabel.height : 0)


            Text {
                id: label
                color: themeColor.textLabel
                font.pixelSize: fontSize
                font.family: globalFonts.awesome
                width: underline.width
                wrapMode: Text.WordWrap
            }
        }
        Row{
            height: sublabel.height
            Text {
                id: sublabel

                color: themeColor.textSublabel
                font.pixelSize: fontSize * 0.8
                font.family: globalFonts.awesome
                font.italic: true
                width: underline.width
                wrapMode: Text.WordWrap
            }
        }
        Row{
            id:detailedRow
            spacing: fontSize * 0.25
            height: root.focus ? vpx(200) : 0
            width: underline.width
            visible: root.focus
            Column{
                Image {
                    id: screenshot
                    asynchronous: true
                    height: root.focus ? vpx(200) : 0
                    source: "" //file:/recalbox/share/roms/neogeo/media/screenshot/mslugx.png"
                    fillMode: Image.PreserveAspectFit
                    smooth: true
                    //visible: root.focus
                }
            }
            Column{
                Text{
                    id: line1
                    color: themeColor.textSublabel
                    font.pixelSize: fontSize * 0.8
                    font.family: globalFonts.awesome
                    font.italic: true
                }
                Text{
                    id: line2
                    color: themeColor.textSublabel
                    font.pixelSize: fontSize * 0.8
                    font.family: globalFonts.awesome
                    font.italic: true
                }
                Text{
                    id: line3
                    color: themeColor.textSublabel
                    font.pixelSize: fontSize * 0.8
                    font.family: globalFonts.awesome
                    font.italic: true
                }
                Text{
                    id: line4
                    color: themeColor.textSublabel
                    font.pixelSize: fontSize * 0.8
                    font.family: globalFonts.awesome
                    font.italic: true
                }
                Text{
                    id: line5
                    color: themeColor.textSublabel
                    font.pixelSize: fontSize * 0.8
                    font.family: globalFonts.awesome
                    font.italic: true
                }
            }

        }
    }
//    Text {
//        id: label

//        anchors.left: parent.left
//        anchors.leftMargin: horizontalPadding
//        anchors.verticalCenter: parent.verticalCenter

//        color: "#eee"
//        font.pixelSize: fontSize
//        font.family: globalFonts.sans
//    }

    MouseArea {
        id: mouseArea
        anchors.fill: parent
        hoverEnabled: true
        onClicked: activate()
        cursorShape: Qt.PointingHandCursor
    }
}
