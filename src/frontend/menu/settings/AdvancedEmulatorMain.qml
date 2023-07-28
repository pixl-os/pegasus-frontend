// Pegasus Frontend
//
// Created by BozoTheGeek - 17/05/2021
//

import "common"
import "qrc:/qmlutils" as PegasusUtils
import QtQuick 2.12
import QtQuick.Window 2.12


FocusScope {
    id: root

    signal close
    signal openRetroarchSettings
    signal openModel2Settings
    signal openDolphinSettings
    signal openDolphinTriforceSettings
    signal openPcsx2Settings
    signal openCitraSettings
    signal openCemuSettings
    signal openXemuSettings
    signal openSupermodelSettings
    signal openPpssppSettings
    signal openYuzuSettings

    width: parent.width
    height: parent.height
    visible: 0 < (x + width) && x < Window.window.width

    enabled: focus

    Keys.onPressed: {
        if (api.keys.isCancel(event) && !event.isAutoRepeat) {
            event.accepted = true;
            root.close();
        }
    }
    PegasusUtils.HorizontalSwipeArea {
        anchors.fill: parent
        onSwipeRight: root.close()
    }
    MouseArea {
        anchors.fill: parent
        acceptedButtons: Qt.RightButton
        onClicked: root.close()
    }
    ScreenHeader {
        id: header
        text: qsTr("Games > Advanced emulators settings") + api.tr
        z: 2
    }
    Flickable {
        id: container

        width: content.width
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: header.bottom
        anchors.bottom: parent.bottom

        contentWidth: content.width
        contentHeight: content.height

        Behavior on contentY { PropertyAnimation { duration: 100 } }
        boundsBehavior: Flickable.StopAtBounds
        boundsMovement: Flickable.StopAtBounds

        readonly property int yBreakpoint: height * 0.7
        readonly property int maxContentY: contentHeight - height

        function onFocus(item) {
            if (item.focus)
                contentY = Math.min(Math.max(0, item.y - yBreakpoint), maxContentY);
        }
        FocusScope {
            id: content

            focus: true
            enabled: focus

            width: contentColumn.width
            height: contentColumn.height

            Column {
                id: contentColumn
                spacing: vpx(5)

                width: root.width * 0.7
                height: implicitHeight

                Item {
                    width: parent.width
                    height: implicitHeight + vpx(30)
                }
                SimpleButton {
                    id: optCemu
                    //set focus only on firt item
                    focus: true

                    label: qsTr("Cemu") + api.tr
                    note: qsTr("Change Configuration for Cemu emulator for Nintendo Wiiu") + api.tr
                    //pointer moved in SimpleButton desactived on default
                    pointerIcon: true

                    onActivate: {
                        focus = true;
                        root.openCemuSettings();
                    }
                    onFocusChanged: container.onFocus(this)
                    KeyNavigation.down: optCitra
                }
                SimpleButton {
                    id: optCitra
                    label: qsTr("Citra-emu") + api.tr
                    note: qsTr("Change Configuration for Citra-emu emulator for Nintendo 3ds") + api.tr
                    //pointer moved in SimpleButton desactived on default
                    pointerIcon: true

                    onActivate: {
                        focus = true;
                        root.openCitraSettings();
                    }
                    onFocusChanged: container.onFocus(this)
                    KeyNavigation.down: optDolphin
                }
                SimpleButton {
                    id: optDolphin
                    label: qsTr("Dolphin") + api.tr
                    note: qsTr("Change Configuration for Dolphin emulator for Nintendo GameCube and Wii.") + api.tr
                    //pointer moved in SimpleButton desactived on default
                    pointerIcon: true

                    onActivate: {
                        focus = true;
                        root.openDolphinSettings();
                    }
                    onFocusChanged: container.onFocus(this)
                    KeyNavigation.down: optDolphinTriforce
                }
                SimpleButton {
                    id: optDolphinTriforce
                    label: qsTr("Dolphin-Triforce") + api.tr
                    note: qsTr("Change Configuration for Dolphin-Triforce emulator for Triforce arcade systems.") + api.tr
                    //pointer moved in SimpleButton desactived on default
                    pointerIcon: true

                    onActivate: {
                        focus = true;
                        root.openDolphinTriforceSettings();
                    }
                    onFocusChanged: container.onFocus(this)
                    KeyNavigation.down: optModel2
                }
                SimpleButton {
                    id: optModel2
                    label: qsTr("Model2") + api.tr
                    note: qsTr("Change Configuration for Model2 emulator for Sega Model2 !") + api.tr
                    //pointer moved in SimpleButton desactived on default
                    pointerIcon: true

                    onActivate: {
                        focus = true;
                        root.openModel2Settings();
                    }
                    onFocusChanged: container.onFocus(this)
                    KeyNavigation.down: optPcsx2
                }
                SimpleButton {
                    id: optPcsx2
                    label: qsTr("Pcsx2") + api.tr
                    note: qsTr("Change Configuration for Pcsx2 emulator for Sony Playstation 2") + api.tr
                    //pointer moved in SimpleButton desactived on default
                    pointerIcon: true

                    onActivate: {
                        focus = true;
                        root.openPcsx2Settings();
                    }
                    onFocusChanged: container.onFocus(this)
                    KeyNavigation.down: optPpsspp
                }
                SimpleButton {
                    id: optPpsspp
                    label: qsTr("PPSSPP") + api.tr
                    note: qsTr("Change Configuration for PPSSPP emulator for Sony Playstation Portable !") + api.tr
                    //pointer moved in SimpleButton desactived on default
                    pointerIcon: true

                    onActivate: {
                        focus = true;
                        root.openPpssppSettings();
                    }
                    onFocusChanged: container.onFocus(this)
                    KeyNavigation.down: optRetroarch
                }
                SimpleButton {
                    id: optRetroarch

                    label: qsTr("Retroarch") + api.tr
                    note: qsTr("Change Configuration for retroarch/libretro multi emulator !") + api.tr
                    //pointer moved in SimpleButton desactived on default
                    pointerIcon: true

                    onActivate: {
                        focus = true;
                        root.openRetroarchSettings();
                    }
                    onFocusChanged: container.onFocus(this)
                    KeyNavigation.down: optSupermodel
                } 
                SimpleButton {
                    id: optSupermodel
                    label: qsTr("Supermodel") + api.tr
                    note: qsTr("Change Configuration for Supermodel emulator for Sega Model3 !") + api.tr
                    //pointer moved in SimpleButton desactived on default
                    pointerIcon: true

                    onActivate: {
                        focus = true;
                        root.openSupermodelSettings();
                    }
                    onFocusChanged: container.onFocus(this)
                    KeyNavigation.down: optXemu
                }
                SimpleButton {
                    id: optXemu
                    label: qsTr("Xemu") + api.tr
                    note: qsTr("Change Configuration for Xemu emulator for Microsoft Xbox") + api.tr
                    //pointer moved in SimpleButton desactived on default
                    pointerIcon: true

                    onActivate: {
                        focus = true;
                        root.openXemuSettings();
                    }
                    onFocusChanged: container.onFocus(this)
                    KeyNavigation.down: optYuzu
                }
                SimpleButton {
                    id: optYuzu
                    label: qsTr("Yuzu") + api.tr
                    note: qsTr("Change Configuration for Yuzu emulator for Nintendo switch") + api.tr
                    //pointer moved in SimpleButton desactived on default
                    pointerIcon: true

                    onActivate: {
                        focus = true;
                        root.openYuzuSettings();
                    }
                    onFocusChanged: container.onFocus(this)
                }
                Item {
                    width: parent.width
                    height: vpx(30)
                }
            }
        }
    }
}
