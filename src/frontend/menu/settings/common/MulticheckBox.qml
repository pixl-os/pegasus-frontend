// Pegasus Frontend
// Created by BozoTheGeek 14/08/2024


import QtQuick 2.12
import QtQuick.Controls 2.12


FocusScope {
    id: root

    property alias model: list.model
    property alias index: list.currentIndex
    property alias isChecked: list.isChecked

    readonly property int textSize: vpx(22)
    readonly property int itemHeight: 2.25 * textSize

    signal close
    signal check(int index, bool checked)

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
            event.accepted = false;
        }
    }
    Component.onCompleted: {
        if (list.currentIndex > 0)
            list.positionViewAtIndex(list.currentIndex, ListView.Center);
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
        height: list.count >= 10 ? (10 * itemHeight) : (list.count * itemHeight)
        width: vpx(700)
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
                    focus: true

                    width: parent.width
                    height: Math.min(count * itemHeight, parent.height)
                    anchors.verticalCenter: parent.verticalCenter
                    delegate: listItem
                    snapMode: ListView.SnapOneItem
                    highlightMoveDuration: 150

                    property var isChecked: []

                    MouseArea {
                        anchors.fill: parent
                        onClicked: {
                            var new_idx = list.indexAt(mouse.x, list.contentY + mouse.y);
                            if (new_idx < 0)
                                return;
                            list.currentIndex = new_idx;
                        }
                        cursorShape: Qt.PointingHandCursor
                    }
                }
            }
        }
    }
    Component {
        id: listItem
        Rectangle {
            readonly property bool highlighted: ListView.isCurrentItem || mouseArea.containsMouse
            width: ListView.view.width
            height: root.itemHeight
            radius: vpx(8)
            color: highlighted ? themeColor.secondary : themeColor.main
            border.color: highlighted ? themeColor.underline : themeColor.main


            Keys.onPressed: {
                if (api.keys.isAccept(event)) {
                    event.accepted = true;
                    checkbox.checked = !checkbox.checked;
                    check(index,checkbox.checked);
                }
            }

            CheckBox {
                id: checkbox
                anchors.left: parent.left
                anchors.verticalCenter: parent.verticalCenter
                text: " "
                checked: typeof(list.isChecked[index]) !== "undefined" ? list.isChecked[index] : true // Set initial checked state
                onCheckedChanged: {
                    //console.log("Label: ",label.text, "Index: ",index, "Checkbox checked: ", checked)
                }
            }

            Text {
                id: label

                anchors.left: checkbox.right
                anchors.verticalCenter: parent.verticalCenter

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
