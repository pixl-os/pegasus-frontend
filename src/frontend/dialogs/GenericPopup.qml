import QtQuick 2.12
import QtQuick.Controls 2.15

FocusScope {
    id: rootWindow
    visible: true
    width: 600
    height: 800
    property color popupBackGroundColor: "#b44"
    property color popupTextCOlor: "#ffffff"

    property alias message: popup.popMessage
    property alias delay : Timer.delay
    
    Popup {
            id: popup
            property alias popMessage: message.text

            background: Rectangle {
                implicitWidth: rootWindow.width
                implicitHeight: 60
                color: popupBackGroundColor
            }
            y: (rootWindow.height - 60)
            modal: true
            focus: true
            closePolicy: Popup.CloseOnPressOutside
            Text {
                id: message
                anchors.centerIn: parent
                font.pointSize: 12
                color: popupTextCOlor
            }
            onOpened: popupClose.start()
        }

        // Popup will be closed automatically in 2 seconds after its opened
        Timer {
            //properties to manage parameter
            property int delay
            id: popupClose
            interval: delay
            onTriggered: popup.close()
        }
}