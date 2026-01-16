// Pegasus Frontend
//
// Created by BozoTheGeek - 17/05/2021
// Updated by Strodown - 17/07/2023
//

import "emulatorsetting"
import "qrc:/qmlutils" as PegasusUtils
import QtQuick 2.12
import QtQuick.Window 2.12


FocusScope {
    id: root

    signal close

    function openScreen(url) {
        subscreen.source = url;
        subscreen.focus = true;
        root.state = "sub";
    }
    function openModal(url) {
        modal.source = url;
        modal.focus = true;
        root.state = "modal";
    }

    anchors.fill: parent
    enabled: focus
    visible: 0 < (x + width) && x < Window.window.width


    AdvancedEmulatorMain {
        id: main
        focus: true
        anchors.right: parent.right

        onClose: root.close()
        onOpenRetroarchSettings: root.openScreen("emulatorsetting/libretroSettings.qml")
        onOpenRpcs3Settings: root.openScreen("emulatorsetting/rpcs3Settings.qml")
        onOpenModel2emuSettings: root.openScreen("emulatorsetting/model2emuSettings.qml")
        onOpenDolphinSettings: root.openScreen("emulatorsetting/dolphinSettings.qml")
        onOpenDolphinTriforceSettings: root.openScreen("emulatorsetting/dolphin-triforceSettings.qml")
        onOpenDuckstationSettings: root.openScreen("emulatorsetting/duckstationSettings.qml")
        onOpenPcsx2Settings: root.openScreen("emulatorsetting/pcsx2Settings.qml")
        onOpenCitraSettings: root.openScreen("emulatorsetting/citraSettings.qml")
        onOpenCemuSettings: root.openScreen("emulatorsetting/cemuSettings.qml")
        onOpenXemuSettings: root.openScreen("emulatorsetting/xemuSettings.qml")
        onOpenSupermodelSettings: root.openScreen("emulatorsetting/supermodelSettings.qml")
        onOpenPpssppSettings: root.openScreen("emulatorsetting/ppssppSettings.qml")
        onOpenTeknoParrotSettings: root.openScreen("emulatorsetting/teknoparrotSettings.qml")
        onOpenYuzuSettings: root.openScreen("emulatorsetting/yuzuSettings.qml")
        onOpenSuyuSettings: root.openScreen("emulatorsetting/suyuSettings.qml")
    }
    Loader {
        id: modal
        asynchronous: true

        anchors.fill: parent

        enabled: focus
        onLoaded: item.focus = focus
        onFocusChanged: if (item) item.focus = focus
    }
    Connections {
        target: modal.item
        function onClose() {
            main.focus = true;
            root.state = "";
        }
    }
    Loader {
        id: subscreen
        asynchronous: true

        width: parent.width
        height: parent.height
        anchors.left: main.right

        enabled: focus
        onLoaded: item.focus = focus
        onFocusChanged: if (item) item.focus = focus
    }
    Connections {
        target: subscreen.item
        function onClose() {
            main.focus = true;
            root.state = "";
        }
    }
    states: [
        State {
            name: "sub"
            AnchorChanges {
                target: main
                anchors.right: subscreen.left
            }
            AnchorChanges {
                target: subscreen
                anchors.left: undefined
                anchors.right: parent.right
            }
        }
    ]
    // fancy easing curves, a la material design
    readonly property var bezierDecelerate: [ 0,0, 0.2,1, 1,1 ]
    readonly property var bezierSharp: [ 0.4,0, 0.6,1, 1,1 ]
    readonly property var bezierStandard: [ 0.4,0, 0.2,1, 1,1 ]

    transitions: [
        Transition {
            from: ""; to: "sub"
            AnchorAnimation {
                duration: 425
                easing { type: Easing.Bezier; bezierCurve: bezierStandard }
            }
        },
        Transition {
            from: "sub"; to: ""
            AnchorAnimation {
                duration: 400
                easing { type: Easing.Bezier; bezierCurve: bezierSharp }
            }
            onRunningChanged: if (!running) subscreen.source = ""
        }
    ]
}
