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

    //first line as preview
    property alias label: label.text
    property alias note: sublabel.text
    property alias icon: icon.source
    property alias icon2: icon2.source

    //second line a full detailed
    //first column
    property alias picture: picture.source
    //second column (titles)
    property alias detailed_line1: line1.text
    property alias detailed_line2: line2.text
    property alias detailed_line3: line3.text
    property alias detailed_line4: line4.text
    property alias detailed_line5: line5.text
    property alias detailed_line6: line6.text
    property alias detailed_line7: line7.text
    property alias detailed_line8: line8.text
    //third column (status and details)
    property alias detailed_line9: line9.text
    property alias detailed_line9_color: line9.color

    property alias detailed_line10: line10.text
    property alias detailed_line10_color: line10.color

    property alias detailed_line11: line11.text
    property alias detailed_line11_color: line11.color

    property alias detailed_line12: line12.text
    property alias detailed_line12_color: line12.color

    property alias detailed_line13: line13.text
    property alias detailed_line13_color: line13.color

    property alias detailed_line14: line14.text
    property alias detailed_line14_color: line14.color

    property alias detailed_line15: line15.text
    property alias detailed_line15_color: line15.color

    property alias detailed_line16: line16.text
    property alias detailed_line16_color: line16.color
    //last column (to put additional images)
    property alias picture2: picture2.source


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
            //bottom: parent.bottom
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
            spacing: vpx(5)
            Column{
                Row{
                    height: label.height // + (sublabel.text ? spacing + sublabel.height : 0)
                    //width: underline.width * 0.8
                    spacing: vpx(5)
                    Text {
                        id: label
                        color: themeColor.textLabel
                        font.pixelSize: fontSize
                        font.family: globalFonts.awesome
                        wrapMode: Text.WordWrap
                    }
                }
                Row{
                    height: sublabel.height
                    //width: underline.width * 0.8
                    Text {
                        id: sublabel

                        color: themeColor.textSublabel
                        font.pixelSize: fontSize * 0.8
                        font.family: globalFonts.awesome
                        font.italic: true
                        //width: parent.width
                        wrapMode: Text.WordWrap
                    }
                    Image {
                        id: icon
                        asynchronous: true
                        height: parent.height //label.height + labelContainer.spacing + sublabel.height//parent.height
                        //width: height * (4/3) // for 4/3 flag
                        source: ""
                        fillMode: Image.PreserveAspectFit
                        smooth: true
                        //visible: root.focus
                    }
                }

            }
            Column{
                Row{
                    //layoutDirection: Qt.RightToLeft
                    spacing: vpx(5)
                    Image {
                        id: icon2
                        asynchronous: true
                        height: label.height + labelContainer.spacing + sublabel.height //parent.height
                        //width: height * (4/3) // for 4/3 flag
                        source: ""
                        fillMode: Image.PreserveAspectFit
                        smooth: true
                        //visible: root.focus
                    }
                }
            }
        }
        Row{
            spacing: fontSize //* 0.25
            height: root.focus ? vpx(200) : 0
            width: underline.width
            visible: root.focus
            Column{
                Image {
                    id: picture
                    asynchronous: true
                    height: root.focus ? vpx(200) : 0
                    width: height * (4/3) // for 4/3 video sized
                    source: ""
                    fillMode: Image.PreserveAspectFit
                    smooth: true
                    //visible: root.focus
                }
            }
            Column{
                spacing: vpx(4)
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
                Text{
                    id: line6
                    color: themeColor.textSublabel
                    font.pixelSize: fontSize * 0.8
                    font.family: globalFonts.awesome
                    font.italic: true
                }
                Text{
                    id: line7
                    color: themeColor.textSublabel
                    font.pixelSize: fontSize * 0.8
                    font.family: globalFonts.awesome
                    font.italic: true
                }
                Text{
                    id: line8
                    color: themeColor.textSublabel
                    font.pixelSize: fontSize * 0.8
                    font.family: globalFonts.awesome
                    font.italic: true
                }

            }
            Column{
                spacing: vpx(4)
                Text{
                    id: line9
                    color: themeColor.textSublabel
                    font.pixelSize: fontSize * 0.8
                    font.family: globalFonts.awesome
                    font.bold: true
                }
                Text{
                    id: line10
                    color: themeColor.textSublabel
                    font.pixelSize: fontSize * 0.8
                    font.family: globalFonts.awesome
                    font.bold: true
                }
                Text{
                    id: line11
                    color: themeColor.textSublabel
                    font.pixelSize: fontSize * 0.8
                    font.family: globalFonts.awesome
                    font.bold: true
                }
                Text{
                    id: line12
                    color: themeColor.textSublabel
                    font.pixelSize: fontSize * 0.8
                    font.family: globalFonts.awesome
                    font.bold: true
                }
                Text{
                    id: line13
                    color: themeColor.textSublabel
                    font.pixelSize: fontSize * 0.8
                    font.family: globalFonts.awesome
                    font.bold: true
                }
                Text{
                    id: line14
                    color: themeColor.textSublabel
                    font.pixelSize: fontSize * 0.8
                    font.family: globalFonts.awesome
                    font.bold: true
                }
                Text{
                    id: line15
                    color: themeColor.textSublabel
                    font.pixelSize: fontSize * 0.8
                    font.family: globalFonts.awesome
                    font.bold: true
                }
                Text{
                    id: line16
                    color: themeColor.textSublabel
                    font.pixelSize: fontSize * 0.8
                    font.family: globalFonts.awesome
                    font.bold: true
                }
            }
            Column{
                Row{
                    layoutDirection: Qt.RightToLeft
                    Image {
                    id: picture2
                    asynchronous: true
                    height: root.focus ? vpx(200) : 0
                    width: height * (4/3) // for 4/3 video sized
                    source: ""
                    fillMode: Image.PreserveAspectFit
                    smooth: true
                    //visible: root.focus
                    }
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
