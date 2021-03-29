import QtQuick 2.12
import QtQuick.Controls 2.12 as Controls
import QtQuick.VirtualKeyboard 2.5
import QtQuick.VirtualKeyboard.Settings 2.15
import QtQml 2.15

Controls.TextField {
    id: control
//    focus: true
    color: themeColor.textLabel
    selectionColor: Qt.rgba(0.0, 0.0, 0.0, 0.15)
    selectedTextColor: color
    selectByMouse: true
    font.pixelSize: Qt.application.font.pixelSize * 2

    property int enterKeyAction: EnterKeyAction.None
    readonly property bool enterKeyEnabled: enterKeyAction === EnterKeyAction.None || acceptableInput || inputMethodComposing

    EnterKeyAction.actionId: control.enterKeyAction
    EnterKeyAction.enabled: control.enterKeyEnabled

    background: Rectangle {
        color: themeColor.secondary
        border.width: 1
        border.color: control.activeFocus ? "#5CAA15" : "#BDBEBF"
    }
}
