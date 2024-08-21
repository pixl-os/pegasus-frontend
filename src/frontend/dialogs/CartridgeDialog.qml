// Pegasus Frontend
// created by BozoTheGeek 20/08/2024

import QtQuick 2.12

FocusScope {
    id: root

    property alias message: messageText.text
    property alias symbol: symbolText.text
    property alias firstchoice: okButtonText.text
    property alias secondchoice: secondButtonText.text
    property alias thirdchoice: cancelButtonText.text
    property var system;

    property int textSize: vpx(18)
    property int titleTextSize: vpx(20)

    signal accept()
    signal secondChoice()
    signal cancel()

    //list model to manage icons of devices
    ListModel {
        id: mySystemIcons

        ListElement { icon: "\uf275"; system: "psx"; picture:"qrc:/frontend/assets/project-cd/retroarch-cd-psx.png"}
        ListElement { icon: "\uf26e"; system: "dreamcast"; picture:"qrc:/frontend/assets/project-cd/retroarch-cd-dreamcast.png"}
        ListElement { icon: "\uf26b"; system: "segacd"; picture:"qrc:/frontend/assets/project-cd/retroarch-cd-segacd.png"}
        ListElement { icon: "\uf271"; system: "pcenginecd"; picture:"qrc:/frontend/assets/project-cd/retroarch-cd-pcenginecd.png"}
        ListElement { icon: "\uf28d"; system: "3do"; picture:"qrc:/frontend/assets/project-cd/retroarch-cd-3do.png"}
        ListElement { icon: "\uf26c"; system: "saturn"; picture:"qrc:/frontend/assets/project-cd/retroarch-cd-saturn.png"}
    }

    //function to get icon from system
    function getIcon(mySystem){
        let icon = "";
        let i = 0;
        //search Icon using the good system
        do{
            if (mySystem.includes(mySystemIcons.get(i).system)){
                    icon = mySystemIcons.get(i).icon;
            }
            i = i + 1;
        }while (icon === "" && i < mySystemIcons.count)
        return icon;
    }

    //function to get CD picture from system
    function getPicture(mySystem){
        let picture = "";
        let i = 0;
        //search Picture using the good system
        do{
            if (mySystem.includes(mySystemIcons.get(i).system)){
                    picture = mySystemIcons.get(i).picture;
            }
            i = i + 1;
        }while (picture === "" && i < mySystemIcons.count)
        return picture;
    }

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

        // image area
        Item {
            width: parent.width
            height: pngCdrom.height + vpx("5") * root.textSize
            Image {
                id: pngCdrom
                source: getPicture(root.system)
                antialiasing: true
                fillMode: Image.PreserveAspectFit
                width: vpx(400); height: vpx(400)
                asynchronous: true
                sourceSize { width: vpx(400); height: vpx(400) }
                anchors {
                    verticalCenter: parent.verticalCenter
                    horizontalCenter: parent.horizontalCenter
                }
                NumberAnimation on rotation {
                    from: 0; to: 1080 * 6
                    running: cdRomPopupLoader.visible === true
                    loops: Animation.Infinite
                    duration: 12000
                    easing.type: Easing.InOutQuart
                }
            }
        }

        // text area
        Rectangle {
            width: parent.width
            height: messageText.height + vpx("50")
            color: themeColor.secondary
            Text {
                id: messageText

                anchors.centerIn: parent
                width: parent.width - vpx("2") * root.textSize

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
                text: getIcon(root.system)
                font {
                    bold: false
                    pixelSize: root.titleTextSize * 2.5
                    family: global.fonts.awesome
                }
            }
        }
        // button row
        Row {
            width: parent.width
            height: root.textSize * 2

            Rectangle {
                id: okButton

                width: (secondchoice !== "") ? parent.width * 0.33 : ((thirdchoice !== "") ? parent.width * 0.5 : parent.width)
                height: root.textSize * 2.25
                color: (focus || okMouseArea.containsMouse) ? "darkGreen" : themeColor.main
                KeyNavigation.right: (secondchoice !== "") ? secondButton : cancelButton
                Keys.onPressed: {
                    if (api.keys.isAccept(event) && !event.isAutoRepeat) {
                        event.accepted = true;
                        root.accept();
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
                        root.accept();
                   }
                }
            }

            Rectangle {
                id: secondButton

                width: (secondchoice !== "") ? parent.width * 0.33 : parent.width * 0.5
                height: root.textSize * 2.25
                color: (focus || okMouseArea.containsMouse) ? "darkOrange" : themeColor.main
                visible: (secondchoice !== "") ? true : false

                KeyNavigation.right: cancelButton
                KeyNavigation.left: okButton
                Keys.onPressed: {
                    if (api.keys.isAccept(event) && !event.isAutoRepeat) {
                        event.accepted = true;
                        root.secondChoice();
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
                        root.secondChoice();
                   }
                }
            }

            Rectangle {
                id: cancelButton

                focus: true

                width: (secondchoice !== "") ? parent.width * 0.34 : ((thirdchoice !== "") ? parent.width * 0.5 : 0)
                height: root.textSize * 2.25
                color: (focus || cancelMouseArea.containsMouse) ? "darkRed" : themeColor.main

                KeyNavigation.left: (secondchoice !== "") ? secondButton : okButton
                Keys.onPressed: {
                    if (api.keys.isAccept(event) && !event.isAutoRepeat) {
                        event.accepted = true;
                        root.cancel();
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
                        root.cancel();
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
