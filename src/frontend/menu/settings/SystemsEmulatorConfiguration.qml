// Pegasus Frontend
//
// Created by BozoTheGeek - 28/08/2025
//

import "emulatorsetting"
import "qrc:/qmlutils" as PegasusUtils
import QtQuick 2.12
import QtQuick.Window 2.12


FocusScope {
    id: root

    signal close

    function openScreen(url) {
        //console.log("openScreen - root.launchedAsDialogBox : ", root.launchedAsDialogBox);
        if(root.game){
            subscreen.setSource(url, {"launchedAsDialogBox": root.launchedAsDialogBox,
                                     "game": root.game});
        }
        else if(root.system){
            subscreen.setSource(url, {"launchedAsDialogBox": root.launchedAsDialogBox,
                                     "system": root.system});
        }
        else{
            subscreen.setSource(url, {"launchedAsDialogBox": root.launchedAsDialogBox});
        }
        subscreen.focus = true;
        root.state = "sub";
    }

    function openModal(url) {
        console.log("openModal - url : ", url);
        console.log("openModal - root.launchedAsDialogBox : ", root.launchedAsDialogBox);
        if(root.game) console.log("openModal - root.game.title : ", root.game.title);
        if(root.system) console.log("openModal - root.system.name : ", root.system.name);

        if (root.launchedAsDialogBox) modal.fullscreen = false;
        if(root.game){
            modal.setSource(url, {"launchedAsDialogBox": root.launchedAsDialogBox,
                                     "game": root.game});
        }
        else if(root.system){
            modal.setSource(url, {"launchedAsDialogBox": root.launchedAsDialogBox,
                                     "system": root.system});
        }
        else{
            modal.setSource(url, {"launchedAsDialogBox": root.launchedAsDialogBox});
        }
        modal.focus = true;
        root.state = "modal";
    }

    anchors.fill: parent
    enabled: focus
    visible: 0 < (x + width) && x < Window.window.width

    property var game
    property var system
    property var prefix : system.shortName
    property bool launchedAsDialogBox: false

    SystemsEmulatorConfigurationMain {
        id: main

        focus: true
        anchors.right: parent.right

        game: root.game
        system: root.system
        prefix: root.prefix
        launchedAsDialogBox: root.launchedAsDialogBox

        onClose: root.close()
        onOpenEmulatorSettings: {
            if (launchedAsDialogBox){
                root.openModal("emulatorsetting/" + emulator + "Settings.qml")
            }
            else root.openScreen("emulatorsetting/" + emulator + "Settings.qml")
        }
    }
    Loader {
        id: modal
        asynchronous: true
        opacity: focus ? 1 : 0
        property bool fullscreen: true
        width: appWindow.width * (fullscreen ? 1.0 : 0.90)
        height: appWindow.height * (fullscreen ? 1.0 : 0.80)

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
