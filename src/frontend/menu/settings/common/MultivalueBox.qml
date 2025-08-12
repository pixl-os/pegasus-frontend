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

    property var model
    property alias index: list.currentIndex

    readonly property int textSize: vpx(22)
    readonly property int itemHeight: 2.25 * textSize

    property string selected_picture: ""

    //coming from MultivalueOption geenrallly linked to MultiValueBox
    property bool has_picture: false
    property int max_listitem_displayed: 10

    signal close
    signal select(int index)

    onFocusChanged: if (focus) root.state = "open";
    function triggerClose() {
        root.state = "";
        root.close();
    }

    anchors.fill: parent
    enabled: focus
    visible: focus || animClosing.running

    Keys.onPressed: {
        if (event.isAutoRepeat)
            return;

        if (api.keys.isCancel(event)) {
            event.accepted = true;
            triggerClose();
        }
        else if (api.keys.isAccept(event)) {
            event.accepted = true;
            select(index);
            triggerClose();
        }
    }

    Component.onCompleted: {
        if (list.currentIndex > 0){
            list.positionViewAtIndex(list.currentIndex, ListView.Center);
        }
    }

    Rectangle {
        id: shade

        anchors.fill: parent
        color: "#000"

        opacity: parent.focus ? 0.3 : 0.0
        Behavior on opacity { PropertyAnimation { duration: 150 } }

        MouseArea {
            anchors.fill: parent
            acceptedButtons: Qt.LeftButton | Qt.RightButton
            onClicked: root.triggerClose()
        }
    }
    Item {
        id: box
        //fix to 10 items size if picture to display for each selection
        height: (list.count >= max_listitem_displayed) ? (max_listitem_displayed * itemHeight) : has_picture ? (max_listitem_displayed * itemHeight) : (list.count * itemHeight)
        width: has_picture ? vpx(1100) : vpx(700)
        anchors.centerIn: parent
        Rectangle {
            id: borderBox
            height: box.height + vpx(15)
            width: box.width + vpx(15)
            color: themeColor.secondary
            radius: vpx(8)
            anchors.centerIn: parent
        }
        Rectangle {
            color: themeColor.main
            radius: vpx(8)
            anchors.fill: box

            MouseArea {
                id: mouseArea
                anchors.fill: parent
                hoverEnabled: true
                clip: true

                ListView {
                    id: list
                    model: root.model
                    focus: true
                    width: has_picture === true ? parent.width/2 : parent.width
                    height: Math.min(count * itemHeight, parent.height)
                    anchors.left: parent.left

                    delegate: listItem
                    snapMode: ListView.SnapOneItem
                    highlightMoveDuration: 150

                    MouseArea {
                        anchors.fill: parent
                        onClicked: {
                            var new_idx = list.indexAt(mouse.x, list.contentY + mouse.y);
                            if (new_idx < 0)
                                return;

                            list.currentIndex = new_idx;
                            root.select(new_idx);
                        }
                        cursorShape: Qt.PointingHandCursor
                    }
                }

                Image {
                    id: picture
                    source: selected_picture !== "" ? selected_picture : ""
                    visible: selected_picture !== "" ? true : false
                    //width: selected_picture !== "" ? (parent.width/2) : 0
                    //height: parent.height

                    anchors.right: parent.right
                    anchors.left: list.right
                    anchors.leftMargin: vpx(10) // Left margin
                    anchors.rightMargin: vpx(10) // Right margin
                    anchors.top: parent.top
                    anchors.bottom: parent.bottom
                    anchors.topMargin: vpx(10) // Top margin
                    anchors.bottomMargin: vpx(10) // Bottom margin

                    asynchronous: true
                    antialiasing: true
                    fillMode: Image.PreserveAspectFit
                    opacity: 1
                }

                Text {
                    id: noImageText
                    text: qsTr("No Preview Available") + api.tr
                    visible: has_picture & ((selected_picture === "") || (picture.status === Image.Error)) ? true : false
                    width: selected_picture !== "" ? (parent.width/2) : 0
                    height: parent.height
                    anchors.right: parent.right
                    anchors.left: list.right
                    anchors.leftMargin: vpx(10) // Left margin
                    anchors.rightMargin: vpx(10) // Right margin
                    anchors.topMargin: vpx(10) // Top margin
                    anchors.bottomMargin: vpx(10) // Bottom margin
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                    color: "red"
                    font.pixelSize: root.textSize
                    font.family: globalFonts.sans
                }
            }
        }
    }
    Component {
        id: listItem
        Rectangle {
            readonly property bool highlighted: ListView.isCurrentItem || mouseArea.containsMouse
            clip: true
            onHighlightedChanged:{
            //onHighlightedChanged:{
                //console.log("onTextChanged - model.picture : " + model.picture)
                selected_picture = model.picture;
            }

            width: ListView.view.width
            height: root.itemHeight
            radius: vpx(8)
            color: highlighted ? themeColor.secondary : themeColor.main
            border.color: highlighted ? themeColor.underline : themeColor.main

            PegasusUtils.HorizontalAutoScroll{
                id: longtext

                scrollWaitDuration: 1000 // in ms
                pixelsPerSecond: 20
                activated: has_picture
                visible: has_picture
                anchors {
                    top:    parent.top;
                    left:   parent.left;
                    right:  parent.right;
                    leftMargin: vpx(5);
                    rightMargin: vpx(5);
                    horizontalCenter: parent.horizontalCenter;
                    //verticalCenter: parent.verticalCenter;
                }

                height: parent.height

                Text {
                    id: labellongtext
                    visible: has_picture
                    //anchors.verticalCenter: parent.verticalCenter
                    //anchors.horizontalCenter: parent.horizontalCenter

                    text: (typeof(model.version) !== "undefined") && (model.version.trim().length !== 0) ? model.name + " - " + model.version : model.name
                    color: themeColor.textValue
                    font.pixelSize: root.textSize
                    font.family: globalFonts.sans

                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                }
            }

            Text {
                 id: label
                 visible: !has_picture
                 anchors.verticalCenter: parent.verticalCenter
                 anchors.horizontalCenter: parent.horizontalCenter

                 text: (typeof(model.version) !== "undefined") && (model.version.trim().length !== 0) ? model.name + " - " + model.version : model.name
                 color: themeColor.textValue
                 font.pixelSize: root.textSize
                 font.family: globalFonts.sans
            }

            MouseArea {
                id: mouseArea
                anchors.fill: parent
                hoverEnabled: true
            }
        }
    }
    states: State {
        name: "open"
        AnchorChanges {
            target: box
            anchors.left: undefined
            anchors.right: root.right
        }
    }
    readonly property var bezierDecelerate: [ 0,0, 0.2,1, 1,1 ]
    readonly property var bezierSharp: [ 0.4,0, 0.6,1, 1,1 ]

    transitions: [
        Transition {
            from: ""; to: "open"
            AnchorAnimation {
                duration: 175
                easing { type: Easing.Bezier; bezierCurve: bezierDecelerate }
            }
        },
        Transition {
            id: animClosing
            from: "open"; to: ""
            AnchorAnimation {
                duration: 150
                easing { type: Easing.Bezier; bezierCurve: bezierSharp }
            }
        }
    ]
}
