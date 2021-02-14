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
import QtQuick 2.0
import QtQuick.Window 2.2


FocusScope {
    id: root

    signal close
    signal openBiosChecking_Settings
    signal openAdvancedEmulator_Settings
//    signal openKeySettings
//    signal openGamepadSettings
//    signal openGameDirSettings

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
        text: qsTr("Games") + api.tr
        z: 2
    }

    Flickable {
        id: container

        width: content.width
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        anchors.bottom: parent.bottom

        contentWidth: content.width
        contentHeight: content.height

        Behavior on contentY { PropertyAnimation { duration: 100 } }

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
                    height: header.height + vpx(25)
                }

                SectionTitle {
                    text: qsTr("Game Screen") + api.tr
                    first: true
                }

                MultivalueOption {
                    id: optGameRatio

                    label: qsTr("Game Ratio") + api.tr

                    onActivate: {
                        focus = true;
                        localeBox.focus = true;
                    }
                    onFocusChanged: container.onFocus(this)

                    KeyNavigation.down: optSmoothGame
                    KeyNavigation.up: optAdvancedEmulator
                }

                ToggleOption {
                    id: optSmoothGame

                    label: qsTr("Smooth Games") + api.tr
                    note: qsTr("Add Smooth pixel effects") + api.tr

//                    checked: api.internal.settings.fullscreen
                    onCheckedChanged: {
                        focus = true;
//                        api.internal.settings.fullscreen = checked;
                    }
                    KeyNavigation.down: optGameRewind
                }

                ToggleOption {
                    id: optGameRewind

                    label: qsTr("Game Rewind") + api.tr
                    note: qsTr("Only work with Retroarch") + api.tr

//                    checked: api.internal.settings.fullscreen
                    onCheckedChanged: {
                        focus = true;
//                        api.internal.settings.fullscreen = checked;
                    }
                    KeyNavigation.down: optShowFramerate
                }

                ToggleOption {
                    id: optShowFramerate

                    label: qsTr("Show Framerate") + api.tr
                    note: qsTr("Show FPS in game") + api.tr

//                    checked: api.internal.settings.fullscreen
                    onCheckedChanged: {
                        focus = true;
//                        api.internal.settings.fullscreen = checked;
                    }
                    KeyNavigation.down: optAutoSave
                }

                SectionTitle {
                    text: qsTr("Save/Load") + api.tr
                    first: true
                }

                ToggleOption {
                    id: optAutoSave

                    label: qsTr("Auto Saves") + api.tr
                    note: qsTr("Auto Saves your Games") + api.tr

//                    checked: api.internal.settings.fullscreen
                    onCheckedChanged: {
                        focus = true;
//                        api.internal.settings.fullscreen = checked;
                    }
                    KeyNavigation.down: optAutoLoad
                }

                ToggleOption {
                    id: optAutoLoad

                    label: qsTr("Auto Load") + api.tr
                    note: qsTr("Auto Load your Games") + api.tr

//                    checked: api.internal.settings.fullscreen
                    onCheckedChanged: {
                        focus = true;
//                        api.internal.settings.fullscreen = checked;
                    }
                    KeyNavigation.down: optShaders
                }

                MultivalueOption {
                    id: optShaders

                    focus: true

                    label: qsTr("Shaders") + api.tr
//                    value: api.internal.settings.locales.currentName

                    onActivate: {
                        focus = true;
                        localeBox.focus = true;
                    }
                    onFocusChanged: container.onFocus(this)

                    KeyNavigation.down: optPixelPerfect
                }

                ToggleOption {
                    id: optPixelPerfect

                    label: qsTr("Pixel Perfect") + api.tr
                    note: qsTr("Set Interger Scale") + api.tr

//                    checked: api.internal.settings.fullscreen
                    onCheckedChanged: {
                        focus = true;
//                        api.internal.settings.fullscreen = checked;
                    }
                    KeyNavigation.down: optBiosChecking
                }

                SimpleButton {
                    id: optBiosChecking

                    label: qsTr("Bios Checking") + api.tr
                    onActivate: {
                        focus = true;
                        root.openBiosChecking_Settings();
                    }
                    onFocusChanged: container.onFocus(this)

                    KeyNavigation.down: optAdvancedEmulator
                }

                SimpleButton {
                    id: optAdvancedEmulator

                    label: qsTr("Advandced Emulator Settings") + api.tr
                    onActivate: {
                        focus = true;
                        root.openAdvancedEmulator_Settings();
                    }
                    onFocusChanged: container.onFocus(this)

                    KeyNavigation.down: optGameRatio
                }

                Item {
                    width: parent.width
                    height: vpx(25)
                }
            }
        }
    }


    MultivalueBox {
        id: localeBox
        z: 3

        model: api.internal.settings.locales
        index: api.internal.settings.locales.currentIndex

        onClose: content.focus = true
        onSelect: api.internal.settings.locales.currentIndex = index
    }
    MultivalueBox {
        id: themeBox
        z: 3

        model: api.internal.settings.themes
        index: api.internal.settings.themes.currentIndex

        onClose: content.focus = true
        onSelect: api.internal.settings.themes.currentIndex = index
    }
}
