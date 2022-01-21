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
import "qrc:/qmlutils" as PegasusUtils


FocusScope {
    id: root

    //first line as preview
    property alias status: status.text
    property alias status_color: status.color
    property alias label: label.text
    property alias label_color: label.color
    property alias note: sublabel.text
    property alias icon: icon.source
    property alias icon2: icon2.source
    property var icon2_forced_display: false;

    //second line a full detailed
    //first column (titles)
    property alias detailed_line1: line1.text
    property alias detailed_line2: line2.text
    property alias detailed_line3: line3.text
    property alias detailed_line4: line4.text
    property alias detailed_line5: line5.text
    property alias detailed_line6: line6.text
    property alias detailed_line7: line7.text
    property alias detailed_line8: line8.text
    property alias detailed_description: scrolltext.text
    //second column (status and details)
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
    property alias picture: picture.source


    readonly property int fontSize: vpx(22)
    readonly property int horizontalPadding: vpx(20)
    readonly property int detailPartHeight: vpx(150)

    signal activate()


    width: parent.width
    height: labelContainer.height + vpx(10)
	
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
        width: parent.width *(3/4)
        anchors {
            left: parent.left;
            leftMargin: horizontalPadding;
            right: logoContainer.left
            rightMargin: horizontalPadding
            top: parent.top
        }
        spacing: fontSize * 0.25

        //just to have a space at the top
        Row{
        id: paddingRow
            Text{
                height: vpx(2)
                text: " "
            }
        }

        Row{
        id: previewRow
            spacing: vpx(5)
            width: parent.width

            Column{
            id:labelsColumn
                Row{
                id: labelRow
                    height: label.height
                    width: parent.width
                    spacing: vpx(5)
                    Text {
                        id: status
                        width: label.height
                        color: themeColor.textLabel
                        font.pixelSize: fontSize
                        font.family: globalFonts.awesome
                        elide: Text.ElideRight
                        visible: text !== "" ? true : false
                    }
                    Text {
                        id: label
                        width: labelContainer.width - status.width
                        color: themeColor.textLabel
                        font.pixelSize: fontSize
                        font.family: globalFonts.awesome
                        elide: Text.ElideRight
                        visible: text !== "" ? true : false
                    }
                }
                Row{
                    id: sublabelRow
                    height: sublabel.height
                    Image {
                        id: icon
                        asynchronous: true
                        height: sublabel.height 
						source: ""
                        fillMode: Image.PreserveAspectFit
                        smooth: true
                    }
                    Text {
                        id: sublabel
                        color: themeColor.textSublabel
                        font.pixelSize: fontSize * 0.8
                        font.family: globalFonts.awesome
                        font.italic: true
                        wrapMode: Text.WordWrap
                        visible: text !== "" ? true : false
                    }
                }

            }
        }
        Row{
        id: detailedRow
            spacing: fontSize //* 0.25
            height: root.focus ? detailPartHeight : 0
            width: underline.width
            visible: root.focus
            Column{
                spacing: vpx(4)
                Text{
                    id: line1
                    color: themeColor.textSublabel
                    font.pixelSize: fontSize * 0.8
                    font.family: globalFonts.awesome
                    font.italic: true
                    visible: text !== "" ? true : false
                }
                Text{
                    id: line2
                    color: themeColor.textSublabel
                    font.pixelSize: fontSize * 0.8
                    font.family: globalFonts.awesome
                    font.italic: true
                    visible: text !== "" ? true : false
                }
                Text{
                    id: line3
                    color: themeColor.textSublabel
                    font.pixelSize: fontSize * 0.8
                    font.family: globalFonts.awesome
                    font.italic: true
                    visible: text !== "" ? true : false
                }
                Text{
                    id: line4
                    color: themeColor.textSublabel
                    font.pixelSize: fontSize * 0.8
                    font.family: globalFonts.awesome
                    font.italic: true
                    visible: text !== "" ? true : false
                }
                Text{
                    id: line5
                    color: themeColor.textSublabel
                    font.pixelSize: fontSize * 0.8
                    font.family: globalFonts.awesome
                    font.italic: true
                    visible: text !== "" ? true : false
                }
                Text{
                    id: line6
                    color: themeColor.textSublabel
                    font.pixelSize: fontSize * 0.8
                    font.family: globalFonts.awesome
                    font.italic: true
                    visible: text !== "" ? true : false
                }
                Text{
                    id: line7
                    color: themeColor.textSublabel
                    font.pixelSize: fontSize * 0.8
                    font.family: globalFonts.awesome
                    font.italic: true
                    visible: text !== "" ? true : false
                }
                Text{
                    id: line8
                    color: themeColor.textSublabel
                    font.pixelSize: fontSize * 0.8
                    font.family: globalFonts.awesome
                    font.italic: true
                    visible: text !== "" ? true : false
                }

            }
            Column{
                spacing: vpx(4)
                Text{
                    id: line9
                    color: themeColor.textSublabel
                    font.pixelSize: fontSize * 0.8
                    font.family: globalFonts.awesome
                    font.bold: false
                    visible: text !== "" ? true : false
                }
                Text{
                    id: line10
                    color: themeColor.textSublabel
                    font.pixelSize: fontSize * 0.8
                    font.family: globalFonts.awesome
                    font.bold: false
                    visible: text !== "" ? true : false
                }
                Text{
                    id: line11
                    color: themeColor.textSublabel
                    font.pixelSize: fontSize * 0.8
                    font.family: globalFonts.awesome
                    font.bold: false
                    visible: text !== "" ? true : false
                }
                Text{
                    id: line12
                    color: themeColor.textSublabel
                    font.pixelSize: fontSize * 0.8
                    font.family: globalFonts.awesome
                    font.bold: false
                    visible: text !== "" ? true : false
                }
                Text{
                    id: line13
                    color: themeColor.textSublabel
                    font.pixelSize: fontSize * 0.8
                    font.family: globalFonts.awesome
                    font.bold: false
                    visible: text !== "" ? true : false
                }
                Text{
                    id: line14
                    color: themeColor.textSublabel
                    font.pixelSize: fontSize * 0.8
                    font.family: globalFonts.awesome
                    font.bold: false
                    visible: text !== "" ? true : false
                }
                Text{
                    id: line15
                    color: themeColor.textSublabel
                    font.pixelSize: fontSize * 0.8
                    font.family: globalFonts.awesome
                    font.bold: false
                    visible: text !== "" ? true : false
                }
                Text{
                    id: line16
                    color: themeColor.textSublabel
                    font.pixelSize: fontSize * 0.8
                    font.family: globalFonts.awesome
                    font.bold: false
                    visible: text !== "" ? true : false
                }
            }
            // Description
            PegasusUtils.AutoScroll
            {
                width: parent.width - horizontalPadding
                height: root.focus ? detailPartHeight : 0
                Text{
                    id: scrolltext
                    color: themeColor.textSublabel
                    font.pixelSize: fontSize * 0.8
                    font.family: globalFonts.awesome
                    font.italic: true
                    visible: (text !== "") && root.focus ? true : false
                    elide: Text.ElideRight
                    wrapMode: Text.WordWrap
                }
            }

        }
    }
    Column {
        id: logoContainer
        anchors.right: parent.right;
        anchors.rightMargin: horizontalPadding;
        anchors.top: parent.top
        height: !root.focus ? parent.height : 0
        width: parent.width * (1/4)
        spacing: fontSize * 0.25
        Row{
            Text{
                height: vpx(2)
                text: " "
            }
        }
        Row{
            Image {
                id: icon2
                asynchronous: true
                height: (icon2_forced_display || !root.focus) ? (label.height + labelContainer.spacing + sublabel.height) : 0
                fillMode: Image.PreserveAspectFit
                smooth: true
                visible: (icon2_forced_display || !root.focus) ? true : false
            }
        }
    }
    Column {
        id: screenshotContainer
        anchors.right: parent.right;
        anchors.rightMargin: horizontalPadding;
        anchors.top: parent.top
        height: root.focus ? parent.height : 0
        width: parent.width * (1/4)
        spacing: fontSize * 0.25
        Row{
            Text{
                height: vpx(2)
                text: " "
            }
        }
        Row{
            Image {
                id: picture
                asynchronous: true
                height: root.focus ? (label.height + labelContainer.spacing + sublabel.height + detailPartHeight) : 0
                fillMode: Image.PreserveAspectFit
                smooth: true
                visible: root.focus
            }
        }
    }


    MouseArea {
        id: mouseArea
        anchors.fill: parent
        hoverEnabled: true
        onClicked: activate()
        cursorShape: Qt.PointingHandCursor
    }
}
