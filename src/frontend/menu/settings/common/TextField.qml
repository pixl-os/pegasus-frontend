import QtQuick 2.12
import QtQuick.Controls 2.12 as Controls
import QtQuick.VirtualKeyboard 2.5
import QtQuick.VirtualKeyboard.Settings 2.15
import QtQml 2.15

Controls.TextField {
    id: control
    focus: true
    color: themeColor.textLabel
    selectionColor: Qt.rgba(0.0, 0.0, 0.0, 0.15)
    selectedTextColor: color
    selectByMouse: false
    font.pixelSize: Qt.application.font.pixelSize * 2

    // change keyboard style
    Component.onCompleted: {
        VirtualKeyboardSettings.styleName = "retro"
        VirtualKeyboardSettings.fullScreenMode = false;
        VirtualKeyboardSettings.wordCandidateList.alwaysVisible = false
    }
    Binding {
        target: VirtualKeyboardSettings
        property: "fullScreenMode"
        value: (parent.width / parent.height) > (16.0 / 9.0)
    }
    property bool mSettingsChanged: false
    //disable handwriting
    property bool handwritingInputPanelActive: false

    property int enterKeyAction: EnterKeyAction.None
    readonly property bool enterKeyEnabled: enterKeyAction === EnterKeyAction.None || acceptableInput || inputMethodComposing

    EnterKeyAction.actionId: control.enterKeyAction
    EnterKeyAction.enabled: control.enterKeyEnabled

    background: Rectangle {
        color: control.activeFocus ? themeColor.secondary : themeColor.main
//        border.width: 1
        border.color: control.activeFocus ? themeColor.screenHeader : themeColor.main
    }
}
