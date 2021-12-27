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

import "../menu/settings/common"

FocusScope {
    id: root

    property alias title: titleText.text
    property alias message: messageText.text
    property alias symbol: symbolText.text
    property alias firstchoice: okButtonText.text
    property alias secondchoice: secondButtonText.text
    property alias thirdchoice: cancelButtonText.text

    property alias game_logo: picture.source
    property var player_name: ""
    property bool has_password: false
    property bool has_spectate_password: false
    property bool is_to_create_room: false

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
        //console.log("onActiveFocusChanged : ", activeFocus);
        state = activeFocus ? "open" : "";
        if (activeFocus)
            cancelButton.focus = true;
    }

    Keys.onPressed: {
        //console.log("Global Keys.onPressed");
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

        width: parent.height * (1.4) //0.8
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
            height: messageText.height + 1 * root.textSize
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
            width: parent.width
            height: vpx(100)
            color: themeColor.secondary
            visible: (game_logo !== "") ? true : false
            Image {
                id: picture

                asynchronous: true

                height: parent.height
                anchors.verticalCenter: parent.verticalCenter
                anchors.horizontalCenter: parent.horizontalCenter
                width: parent.width
                fillMode: Image.PreserveAspectFit
                smooth: true
                visible: true
            }
        }

        ToggleOption {
            id: optNetplayFriend
            Rectangle {
                        width: parent.width
                        height: parent.height
                        color: themeColor.secondary
                        z:-1
                      }
            label: player_name + qsTr(" is your friend ?") + api.tr
            note: qsTr("Set it to keep or not in your list of friends !") + api.tr

            checked: api.internal.recalbox.getBoolParameter("netplay.friend." + player_name)
            onCheckedChanged: {
                api.internal.recalbox.setBoolParameter("netplay.friend." + player_name,checked);
            }
            KeyNavigation.down: optNetplayPswdClient
            visible: player_name !== "" ? true : false
        }

        ToggleOption {
            id: optNetplayPswdClientActivate
            Rectangle {
                        width: parent.width
                        height: parent.height
                        color: themeColor.secondary
                        z:-1
                      }
            label: qsTr("Activate password for netplay player") + api.tr
            note: qsTr("Set password for other players join your game") + api.tr

            checked: api.internal.recalbox.getBoolParameter("netplay.password.useforplayer")
            onCheckedChanged: {
                api.internal.recalbox.setBoolParameter("netplay.password.useforplayer",checked);
            }
            KeyNavigation.up: optNetplayFriend
            KeyNavigation.down: optNetplayPswdClient
            visible: is_to_create_room
        }

        MultivalueOption {
            id: optNetplayPswdClient
            Rectangle {
                        width: parent.width
                        height: parent.height
                        color: themeColor.secondary
                        z:-1
                      }
            //property to manage parameter name
            property string parameterName : "netplay.password.client"

            label: qsTr("Netplay player password") + api.tr
            note: qsTr("Choose password for join session") + api.tr
            value: api.internal.recalbox.parameterslist.currentName(parameterName)
            onActivate: {
                //for callback by parameterslistBox
                parameterslistBox.parameterName = parameterName;
                parameterslistBox.callerid = optNetplayPswdClient;
                //to force update of list of parameters
                api.internal.recalbox.parameterslist.currentName(parameterName);
                parameterslistBox.model = api.internal.recalbox.parameterslist;
                parameterslistBox.index = api.internal.recalbox.parameterslist.currentIndex;
                //to transfer focus to parameterslistBox
                parameterslistBox.focus = true;
            }
            KeyNavigation.up: is_to_create_room ? optNetplayPswdClientActivate : optNetplayFriend
            KeyNavigation.down: is_to_create_room ? optNetplayPswdViewerActivate : optNetplayPswdViewer
            visible: has_password || (is_to_create_room && optNetplayPswdClientActivate.checked)

        }
        ToggleOption {
            id: optNetplayPswdViewerActivate
            Rectangle {
                        width: parent.width
                        height: parent.height
                        color: themeColor.secondary
                        z:-1
                      }
            label: qsTr("Activate password for netplay spectator") + api.tr
            note: qsTr("Set password for netplay spectator") + api.tr

            checked: api.internal.recalbox.getBoolParameter("netplay.password.useforviewer")
            onCheckedChanged: {
                api.internal.recalbox.setBoolParameter("netplay.password.useforviewer",checked);
            }
            KeyNavigation.up: optNetplayPswdClient
            KeyNavigation.down: optNetplayPswdViewer
            visible: is_to_create_room
        }
        MultivalueOption {
            id: optNetplayPswdViewer
            Rectangle {
                        width: parent.width
                        height: parent.height
                        color: themeColor.secondary
                        z:-1
                      }
            //property to manage parameter name
            property string parameterName : "netplay.password.viewer"

            label: qsTr("Netplay spectator password") + api.tr
            note: qsTr("Choose password for netplay spectator") + api.tr
            value: api.internal.recalbox.parameterslist.currentName(parameterName)
            onActivate: {
                //for callback by parameterslistBox
                parameterslistBox.parameterName = parameterName;
                parameterslistBox.callerid = optNetplayPswdViewer
                //to force update of list of parameters
                api.internal.recalbox.parameterslist.currentName(parameterName);
                parameterslistBox.model = api.internal.recalbox.parameterslist;
                parameterslistBox.index = api.internal.recalbox.parameterslist.currentIndex;
                //to transfer focus to parameterslistBox
                parameterslistBox.focus = true;
            }
            KeyNavigation.up: is_to_create_room ? optNetplayPswdViewerActivate : optNetplayPswdClient
            KeyNavigation.down: okButton
            visible: has_spectate_password || (is_to_create_room && optNetplayPswdViewerActivate.checked)
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
                KeyNavigation.up: optNetplayPswdViewer
                KeyNavigation.right: (secondchoice !== "") ? secondButton : cancelButton
                Keys.onPressed: {
                    //console.log("okButton Keys.onPressed");
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
                visible: (secondchoice !== "") ? true : false
                KeyNavigation.up: optNetplayPswdViewer
                KeyNavigation.right: cancelButton
                KeyNavigation.left: okButton
                Keys.onPressed: {
                    //console.log("secondButton Keys.onPressed");
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
                KeyNavigation.up: optNetplayPswdViewer
                KeyNavigation.left: (secondchoice !== "") ? secondButton : okButton
                Keys.onPressed: {
                    //console.log("cancelButton Keys.onPressed");
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
    MultivalueBox {
        id: parameterslistBox
        z: 3

        //properties to manage parameter
        property string parameterName
        property MultivalueOption callerid

        //reuse same model
        model: api.internal.recalbox.parameterslist.model
        //to use index from parameterlist QAbstractList
        index: api.internal.recalbox.parameterslist.currentIndex

        onClose: callerid.focus = true

        onSelect: {
            //to update index of parameterlist QAbstractList
            api.internal.recalbox.parameterslist.currentIndex = index;
            //to force update of display of selected value
            callerid.value = api.internal.recalbox.parameterslist.currentName(parameterName);
        }
    }
}
