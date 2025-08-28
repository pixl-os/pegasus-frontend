// Pegasus Frontend
//
// Created by BozoTheGeek - 26/05/2025
//

//import "emulatorsetting"
import "qrc:/qmlutils" as PegasusUtils
import QtQuick 2.12
import QtQuick.Window 2.12


FocusScope {
    id: root

    signal close

    // for any emulator menu
    function openWithEmulator(url, emulator) {
        if(root.launchedAsDialogBox){
            modal.setSource(url, {"emulator": emulator, "launchedAsDialogBox": root.launchedAsDialogBox});
            modal.focus = true;
            root.state = "modal";
        }
        else{
            subscreen.setSource(url, {"emulator": emulator, "launchedAsDialogBox": root.launchedAsDialogBox});
            subscreen.focus = true;
            root.state = "sub";
        }
    }

    function openScreenWithEmulator(url, emulator) {
        subscreen.setSource(url, {"emulator": emulator, "launchedAsDialogBox": root.launchedAsDialogBox});
        subscreen.focus = true;
        root.state = "sub";
    }

    function openModalWithEmulator(url, emulator) {
        modal.setSource(url, {"emulator": emulator, "launchedAsDialogBox": root.launchedAsDialogBox});
        modal.focus = true;
        root.state = "modal";
    }

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

    property var game
    property var system
    property bool launchedAsDialogBox: false

    TeknoParrotMain {
        id: main
        focus: true
        anchors.right: parent.right
        launchedAsDialogBox: root.launchedAsDialogBox
        game: root.game
        system: root.system
        onClose: root.close()
        onOpenWineConfiguration: root.openWithEmulator("../WineConfiguration.qml", "teknoparrot")
        onOpenProtonConfiguration: root.openWithEmulator("../ProtonConfiguration.qml", "teknoparrot")
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
