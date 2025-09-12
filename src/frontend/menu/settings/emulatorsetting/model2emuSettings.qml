// Pegasus Frontend
//
// Created by BozoTheGeek - 26/05/2025
//

import "qrc:/qmlutils" as PegasusUtils
import QtQuick 2.12
import QtQuick.Window 2.12


FocusScope {
    id: root

    signal close

    // for any emulator menu
    function openWithEmulator(url, emulator) {
        if(root.launchedAsDialogBox){
	    openModalWithEmulator(url, emulator)
        }
        else{
	    openScreenWithEmulator(url, emulator)
        }
    }

    function openScreenWithEmulator(url, emulator) {
        subscreen.setSource(url, {"emulator": emulator, "launchedAsDialogBox": root.launchedAsDialogBox});
        subscreen.focus = true;
        root.state = "sub";
    }

    function openModalWithEmulator(url, emulator) {
        console.log("openModal - url : ", url);
        console.log("openModal - root.launchedAsDialogBox : ", root.launchedAsDialogBox);
        if(root.game) console.log("openModal - root.game.title : ", root.game.title);
        if(root.system) console.log("openModal - root.system.name : ", root.system.name);

        if (root.launchedAsDialogBox) modal.fullscreen = false;
        if(root.game){
        modal.setSource(url, {"emulator": emulator, "launchedAsDialogBox": root.launchedAsDialogBox,
                                     "game": root.game});
        }
        else if(root.system){
        modal.setSource(url, {"emulator": emulator, "launchedAsDialogBox": root.launchedAsDialogBox,
                                     "system": root.system});
        }
        else{
            modal.setSource(url, {"emulator": emulator, "launchedAsDialogBox": root.launchedAsDialogBox});
        }
	modal.focus = true;
	root.state = "modal";
    }

    anchors.fill: parent
    enabled: focus
    visible: 0 < (x + width) && x < Window.window.width

    property var game
    property var system
    property bool launchedAsDialogBox: false
    
    Model2emuMain {
        id: main
        focus: true
        anchors.right: parent.right

        game: root.game
        system: root.system
        launchedAsDialogBox: root.launchedAsDialogBox

        onClose: root.close()
        onOpenWineConfiguration: root.openWithEmulator("../WineConfiguration.qml", "model2emu")
    }
    Loader {
        id: modal
        asynchronous: true
        opacity: focus ? 1 : 0
        property bool fullscreen: true
        property real screenratio: fullscreen ? 1.0 : 0.8
        width: appWindow.width * screenratio
        height: appWindow.height * screenratio

        anchors.centerIn: parent

        Rectangle {
            anchors.fill: parent
            color: themeColor.main
            z: -1
        }
        visible: focus
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
