// Pegasus Frontend
// Copyright (C) 2017-2018  Mátyás Mustoha
//
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with this program. If not, see <http://www.gnu.org/licenses/>.


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
    signal openPcsx2Settings
    signal openCitraSettings
    signal openCemuSettings

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
                    id: optRetroarch
                    //set focus only on firt item
                    focus: true

                    label: qsTr("Retroarch") + api.tr
                    note: qsTr("Change Configuration for retroarch/libretro multi emulator !") + api.tr
                    //pointer moved in SimpleButton desactived on default
                    pointerIcon: true

                    onActivate: {
                        focus = true;
                        console.log("openRetroarchSettings");
                        root.openRetroarchSettings();
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
                        console.log("openDolphinSettings");
                        root.openDolphinSettings();
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
                        console.log("openPcsx2Settings");
                        root.openPcsx2Settings();
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
                        console.log("openCitraSettings");
                        root.openCitraSettings();
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
                        console.log("openXemuSettings");
                        root.openXemuSettings();
                    }
                    onFocusChanged: container.onFocus(this)
                    KeyNavigation.down: optCemu
                }
                SimpleButton {
                    id: optCemu
                    label: qsTr("Cemu") + api.tr
                    note: qsTr("Change Configuration for Cemu emulator for Nintendo Wiiu") + api.tr
                    //pointer moved in SimpleButton desactived on default
                    pointerIcon: true

                    onActivate: {
                        focus = true;
                        console.log("openCemuSettings");
                        root.openCemuSettings();
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
                        console.log("openModel2Settings");
                        root.openModel2Settings();
                    }
                    onFocusChanged: container.onFocus(this)
//                    KeyNavigation.down: optDolphin
                }
                Item {
                    width: parent.width
                    height: vpx(30)
                }
            }
        }
    }
}
