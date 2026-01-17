// Pegasus Frontend
// pixL-OS 2025
// By BozoTheGeek 08/11/2025

import QtQuick 2.15
import QtQuick.Controls 2.15

FocusScope {
    id: root

    property alias label: label.text
    property alias note: sublabel.text
    property alias fileContent: textContent.text
    property alias contentHeight: fileArea.height
    property alias activeScroll: textContent.focus
    property bool showUnderline: true
    property int wrapMode: Text.WordWrap
    property bool launchedAsDialogBox: false
    readonly property int fontSize: vpx(22)
    readonly property int horizontalPadding: launchedAsDialogBox ? vpx(0) : vpx(30)

    signal activate()


    width: parent.width
    height: labelContainer.height + fontSize * 1.25

    Keys.onPressed: {
        if (api.keys.isAccept(event) && !event.isAutoRepeat) {
            event.accepted = true;
            root.activate();
            focus = true;
            activeScroll = true;
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

    Column {
        id: labelContainer

        anchors {
            left: parent.left
            right: parent.horizontalCenter
            verticalCenter: parent.verticalCenter
        }

        spacing: fontSize * 0.25
        height: (label.text !== "" ? spacing + label.height : 0) + (sublabel.text !== "" ? spacing + sublabel.height : 0) + fileArea.height


        Text {
            id: label
            maximumLineCount: (root.wrapMode === Text.NoWrap) ? 1 : 2
            color: themeColor.textLabel
            font.pixelSize: fontSize
            font.family: globalFonts.sans
            width: underline.width
            wrapMode: root.wrapMode
            text: ""
            visible: text !== "" ? true : false
        }

        Text {
            id: sublabel

            color: themeColor.textSublabel
            font.pixelSize: fontSize * 0.8
            font.family: globalFonts.sans
            font.italic: true
            width: underline.width
            wrapMode: Text.WordWrap
            text: ""
            visible: text !== "" ? true : false
        }

        Rectangle {
            id: fileArea
            width: root.width
            height: 400
            color: "lightgray"
            visible: true
            clip: true
            ScrollView {
                id: innerScroll
                width: parent.width
                height: parent.height
                ScrollBar.vertical.policy: ScrollBar.AlwaysOn
                ScrollBar.vertical.implicitWidth: 20
                ScrollBar.vertical.implicitHeight: 30
                ScrollBar.horizontal.implicitWidth: 30
                ScrollBar.horizontal.implicitHeight: 20

                TextEdit {
                    id: textContent

                    text: ""
                    focus: false
                    readOnly: true
                    color: "black"   // For black text
                    wrapMode: Text.WordWrap
                    width: parent.width

                    font.family: "Monospace"
                    font.pointSize: 13

                    Keys.onPressed: (event) => {
                        if (api.keys.isCancel(event) && !event.isAutoRepeat) {
                            //console.log("Cancel Scroll of ScrollView");
                            focus = false;
                            innerScroll.focus = false;
                            root.focus = true;
                            event.accepted = true;
                        }
                        if (api.keys.isUp(event) && !event.isAutoRepeat) {
                            innerScroll.contentItem.contentY = innerScroll.contentItem.contentY - 20;
                            event.accepted = true;
                        }
                        if (api.keys.isDown(event) && !event.isAutoRepeat) {
                            innerScroll.contentItem.contentY = innerScroll.contentItem.contentY + 20;
                            event.accepted = true;
                        }
                        if (api.keys.isLeft(event) && !event.isAutoRepeat) {
                            innerScroll.contentItem.contentX = innerScroll.contentItem.contentX - 20;
                            event.accepted = true;
                        }
                        if (api.keys.isRight(event) && !event.isAutoRepeat) {
                            innerScroll.contentItem.contentX = innerScroll.contentItem.contentX + 20;
                            event.accepted = true;
                        }
                    }

                    onFocusChanged: {
                        if(focus){
                            //console.log("onFocusChanged - focus : " + focus);
                            textContent.forceActiveFocus();
                        }
                    }
                }
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
