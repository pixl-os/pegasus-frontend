// Pegasus Frontend
// created by BozoTheGeek 09/06/2024

import QtQuick 2.15


FocusScope {
    id: root

    property alias title: titleText.text
    property alias message: messageText.text

    property int textSize: vpx(18)
    property int titleTextSize: vpx(20)

    property alias spinnerloaderActivation : spinnerloader.active

    signal close()

    anchors.fill: parent
    visible: shade.opacity > 0

    focus: true
    onActiveFocusChanged: state = activeFocus ? "open" : ""

    Keys.onPressed: {
        if (api.keys.isCancel(event) && !event.isAutoRepeat) {
            event.accepted = true;
            root.close();
        }
    }

    Shade {
        id: shade
        onCancel: root.close()
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
            height: messageText.height + 3 * root.textSize
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
        }

        // button row
        Rectangle {
            id: closeButton
            width: parent.width
            height: root.textSize * 2.25
            color: (focus || closeMouseArea.containsMouse) ? "#4ae" : "#666"

            focus: true

            Keys.onPressed: {
                if (api.keys.isAccept(event) && !event.isAutoRepeat) {
                    event.accepted = true;
                    root.close();
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
                id: closeMouseArea
                anchors.fill: parent
                hoverEnabled: true
                onClicked: root.close()
            }

            //Spinner Loader to wait (if needed and if UI blocked)
            Loader {
                id: spinnerloader
                anchors {
                    right:  parent.right;
                    rightMargin: parent.width * 0.02 + vpx(30/2)
                    verticalCenter: parent.verticalCenter
                }
                active: true //by default, for this one, we activate by default !
                sourceComponent: spinner
                onActiveChanged: {
                    //change text to ask to wait if needed
                    okButtonText.text = qsTr("Please wait...") + api.tr
                }
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
    }

    states: [
        State {
            name: "open"
            PropertyChanges { target: shade; opacity: 0.8 }
            PropertyChanges { target: dialogBox; scale: 1 }
        }
    ]
}
