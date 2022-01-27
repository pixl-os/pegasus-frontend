// Pegasus Frontend
// Copyright (C) 2017-2019  Mátyás Mustoha
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

    property alias title: titleText.text
    property alias message: messageText.text
    property alias symbol: symbolText.text
    property alias firstchoice: okButtonText.text
    property alias secondchoice: secondButtonText.text
    property alias thirdchoice: cancelButtonText.text
    property string logo: ""

    property int textSize: vpx(18)
    property int titleTextSize: vpx(20)
    property var lastchoice: ""

    signal accept()
    signal secondChoice()
    signal cancel()

    anchors.fill: parent
    visible: shade.opacity > 0

    focus: true
    onActiveFocusChanged: {
        state = activeFocus ? "open" : "";
        if (activeFocus)
            cancelButton.focus = true;
    }

    Keys.onPressed: {
        if (api.keys.isCancel(event) && !event.isAutoRepeat) {
            event.accepted = true;
            root.cancel();
        }
    }

    Shade {
        id: shade
        onCancel: root.cancel()
    }

    // actual dialog
    MouseArea {
        anchors.centerIn: parent
        width: dialogBox.width
        height: dialogBox.height
    }
    Column {
        id: dialogBox

        width: parent.height * 0.8
        anchors.centerIn: parent
        scale: 0.5

        Behavior on scale { NumberAnimation { duration: 125 } }

        // title bar
        Rectangle {
            id: titleBar
            width: parent.width
            height: root.titleTextSize * 2.25
            color: themeColor.main

            Text {
                id: titleText
                elide: Text.ElideRight
                anchors {
                    verticalCenter: parent.verticalCenter
                    left: parent.left
                    leftMargin: root.titleTextSize * 0.75
                    right: parent.right
                    rightMargin: root.titleTextSize * 0.75
                }

                color: themeColor.textTitle
                font {
                    bold: true
                    pixelSize: root.titleTextSize
                    family: globalFonts.sans
                }
            }
        }

        // text area
        Rectangle {
            width: parent.width
            height: messageText.height + 5 * root.textSize
            color: themeColor.secondary

            Text {
                id: messageText

                anchors.centerIn: parent
                width: parent.width - 2 * root.textSize

                wrapMode: Text.WordWrap
                horizontalAlignment: Text.AlignHCenter

                color: themeColor.textTitle
                font {
                    pixelSize: root.textSize
                    family: globalFonts.sans
                }
            }

            Text {
                id: symbolText

                anchors {
                    verticalCenter: parent.verticalCenter
                    left: parent.left
                    leftMargin: root.titleTextSize * 0.75
                    right: messageText.left
                    rightMargin: root.titleTextSize * 0.75
                }

                color: themeColor.textTitle
                font {
                    bold: true
                    pixelSize: root.titleTextSize * 4
                    family: globalFonts.sans
                }
            }
        }
        Rectangle {
            width: visible ? parent.width : 0
            height: visible ? vpx(80): 0
            color: themeColor.secondary
            visible: (logo !== "") ? true : false
            Image {
                id: picture

                asynchronous: true
                source: logo
                height: parent.height * 0.8
                width: parent.width * 0.8
                anchors.verticalCenter: parent.verticalCenter
                anchors.horizontalCenter: parent.horizontalCenter
                fillMode: Image.PreserveAspectFit
                smooth: true
                visible: parent.visible
            }
        }
        // button row
        Row {
            width: parent.width
            height: root.textSize * 2

            //to let DialogBox to update message after accept ;-)
            Timer{
                id: acceptTimer
                interval: 50 // launch after 50 ms
                repeat: false
                running: false
                triggeredOnStart: false
                onTriggered: {
                    if(lastchoice === "firstchoice") root.accept();
                    else if(lastchoice === "secondchoice") root.secondChoice();
                    else root.cancel();
                }
            }


            Rectangle {
                id: okButton

                width: (secondchoice !== "") ? parent.width * 0.33 : ((thirdchoice !== "") ? parent.width * 0.5 : parent.width)
                height: root.textSize * 2.25
                color: (focus || okMouseArea.containsMouse) ? "darkGreen" : themeColor.main //"#222"
//                radius: vpx(8)
                KeyNavigation.right: (secondchoice !== "") ? secondButton : cancelButton
                Keys.onPressed: {
                    if (api.keys.isAccept(event) && !event.isAutoRepeat) {
                        event.accepted = true;
                        //change text to ask to wait if needed
                        okButtonText.text = qsTr("Please wait...") + api.tr
                        messageText.text = qsTr("Under progress...") + api.tr
                        //add spinner display
                        spinnerloader.active = true;
                        //hide other buttons
                        secondButtonText.text = "";
                        cancelButtonText.text = "";
                        //let 50 ms to update interface
                        lastchoice = "firstchoice";
                        acceptTimer.running = true;
                    }
                }

                Text {
                    id: okButtonText
                    anchors.centerIn: parent

                    text: qsTr("Ok") + api.tr
                    color: themeColor.textTitle
                    font {
                        pixelSize: root.textSize
                        family: globalFonts.sans
                    }
                }

                MouseArea {
                    id: okMouseArea
                    anchors.fill: parent
                    hoverEnabled: true
                    onClicked: {
                        //change text to ask to wait if needed
                        okButtonText.text = qsTr("Please wait...") + api.tr;
                        messageText.text = qsTr("Under progress...") + api.tr;
                        //add spinner display
                        spinnerloader.active = true;
                        //hide other buttons
                        secondButtonText.text = "";
                        cancelButtonText.text = "";
                        //let 50 ms to update interface
                        lastchoice = "firstchoice";
                        acceptTimer.running = true;
                   }
                }
                //Spinner Loader to wait after accept (if needed and if UI blocked)
                Loader {
                    id: spinnerloader
                    anchors {
                        right:  parent.right;
                        rightMargin: parent.width * 0.02 + vpx(30/2)
                        verticalCenter: parent.verticalCenter
                    }
                    active: false
                    sourceComponent: spinner
                }

                Component {
                    id: spinner
                    Rectangle{
                        Image {
                            id: imageSpinner
                            source: "../assets/loading.png"
                            width: vpx(30)
                            height: vpx(30)
                            asynchronous: true
                            anchors.verticalCenter: parent.verticalCenter
                            anchors.horizontalCenter: parent.horizontalCenter
                            sourceSize { width: vpx(50); height: vpx(50) }
                            RotationAnimator on rotation {
                                loops: Animator.Infinite;
                                from: 0;
                                to: 360;
                                duration: 3000
                            }
                        }
                    }
                }
            }

            Rectangle {
                id: secondButton

                width: (secondchoice !== "") ? parent.width * 0.33 : parent.width * 0.5
                height: root.textSize * 2.25
                color: (focus || okMouseArea.containsMouse) ? "darkOrange" : themeColor.main //"#222"
//                radius: vpx(8)
                visible: (secondchoice !== "") ? true : false

                KeyNavigation.right: cancelButton
                KeyNavigation.left: okButton
                Keys.onPressed: {
                    if (api.keys.isAccept(event) && !event.isAutoRepeat) {
                        event.accepted = true;
                        //change text to ask to wait if needed
                        okButtonText.text = qsTr("Please wait...") + api.tr;
                        messageText.text = qsTr("Under progress...") + api.tr;
                        //add spinner display
                        spinnerloader.active = true;
                        //hide other buttons
                        secondButtonText.text = "";
                        cancelButtonText.text = "";
                        //let 50 ms to update interface
                        lastchoice = "secondchoice";
                        acceptTimer.running = true;
                    }
                }
                Text {
                    id: secondButtonText
                    anchors.centerIn: parent

                    text: qsTr("2nd choice") + api.tr
                    color: themeColor.textTitle
                    font {
                        pixelSize: root.textSize
                        family: globalFonts.sans
                    }
                }

                MouseArea {
                    id: secondMouseArea
                    anchors.fill: parent
                    hoverEnabled: true
                    onClicked: {
                        //change text to ask to wait if needed
                        okButtonText.text = qsTr("Please wait...") + api.tr;
                        messageText.text = qsTr("Under progress...") + api.tr;
                        //add spinner display
                        spinnerloader.active = true;
                        //hide other buttons
                        secondButtonText.text = "";
                        cancelButtonText.text = "";
                        //let 50 ms to update interface
                        lastchoice = "secondchoice";
                        acceptTimer.running = true;
                   }
                }
            }

            Rectangle {
                id: cancelButton

                focus: true

                width: (secondchoice !== "") ? parent.width * 0.34 : ((thirdchoice !== "") ? parent.width * 0.5 : 0)
                height: root.textSize * 2.25
                color: (focus || cancelMouseArea.containsMouse) ? "darkRed" : themeColor.main //"#222"
//                radius: vpx(8)

                KeyNavigation.left: (secondchoice !== "") ? secondButton : okButton
                Keys.onPressed: {
                    if (api.keys.isAccept(event) && !event.isAutoRepeat) {
                        event.accepted = true;
                        //change text to ask to wait if needed
                        okButtonText.text = qsTr("Please wait...") + api.tr;
                        messageText.text = qsTr("Under progress...") + api.tr;
                        //add spinner display
                        spinnerloader.active = true;
                        //hide other buttons
                        secondButtonText.text = "";
                        cancelButtonText.text = "";
                        //let 50 ms to update interface
                        lastchoice = "thirdchoice";
                        acceptTimer.running = true;
                    }
                }

                Text {
                    id: cancelButtonText
                    anchors.centerIn: parent

                    text: qsTr("Cancel") + api.tr
                    color: themeColor.textTitle
                    font {
                        pixelSize: root.textSize
                        family: globalFonts.sans
                    }
                }

                MouseArea {
                    id: cancelMouseArea
                    anchors.fill: parent
                    hoverEnabled: true
                    onClicked: {
                        //change text to ask to wait if needed
                        okButtonText.text = qsTr("Please wait...") + api.tr;
                        messageText.text = qsTr("Under progress...") + api.tr;
                        //add spinner display
                        spinnerloader.active = true;
                        //hide other buttons
                        secondButtonText.text = "";
                        cancelButtonText.text = "";
                        //let 50 ms to update interface
                        lastchoice = "thirdchoice";
                        acceptTimer.running = true;
                   }

                }
            }
        }
    }

    states: [
        State {
            name: "open"
            PropertyChanges { target: shade; opacity: 0.8 }
            PropertyChanges { target: dialogBox; scale: 1 }
        }
    ]
}
