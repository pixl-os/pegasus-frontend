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
    signal openBiosCheckingSettings
    signal openAdvancedEmulatorSettings

    width: parent.width
    height: parent.height
    visible: 0 < (x + width) && x < Window.window.width

    enabled: focus

    Keys.onPressed: {
        if (api.keys.isCancel(event) && !event.isAutoRepeat) {
            event.accepted = true;
            root.close();
            api.internal.recalbox.saveParameters();
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

                SectionTitle {
                    text: qsTr("Game screen") + api.tr
                    first: true
                    symbol: "\uf17f"
                }
                MultivalueOption {
                    id: optGlobalGameRatio
                    // set focus only on first item
                    focus: true

                    //property to manage parameter name
                    property string parameterName : "global.ratio"

                    label: qsTr("Game ratio") + api.tr
                    note: qsTr("Set ratio for all emulators (auto,4/3,16/9,16/10,etc...)") + api.tr

                    value: api.internal.recalbox.parameterslist.currentName(parameterName)
                    onActivate: {
                        //for callback by parameterslistBox
                        parameterslistBox.parameterName = parameterName;
                        parameterslistBox.callerid = optGlobalGameRatio;
                        //to force update of list of parameters
                        api.internal.recalbox.parameterslist.currentName(parameterName);
                        parameterslistBox.model = api.internal.recalbox.parameterslist;
                        parameterslistBox.index = api.internal.recalbox.parameterslist.currentIndex;
                        //to transfer focus to parameterslistBox
                        parameterslistBox.focus = true;
                    }
                    onFocusChanged: container.onFocus(this)
                    KeyNavigation.down: optPixelPerfect
                }
                ToggleOption {
                    id: optPixelPerfect

                    label: qsTr("Pixel perfect") + api.tr
                    note: qsTr("Once enabled, your screen will be cropped, and you will have a pixel perfect image") + api.tr

                    checked: api.internal.recalbox.getBoolParameter("global.integerscale")
                    onCheckedChanged: {
                        focus = true;
                        api.internal.recalbox.setBoolParameter("global.integerscale",checked);
                    }
                    onFocusChanged: container.onFocus(this)
                    KeyNavigation.down: optSmoothGame
                }
                ToggleOption {
                    id: optSmoothGame

                    label: qsTr("Smooth games") + api.tr
                    note: qsTr("Set smooth for all emulators") + api.tr

                    checked: api.internal.recalbox.getBoolParameter("global.smooth")
                    onCheckedChanged: {
                        focus = true;
                        api.internal.recalbox.setBoolParameter("global.smooth",checked);
                    }
                    onFocusChanged: container.onFocus(this)
                    KeyNavigation.down: optGlobalShaderSet
                }
                MultivalueOption {
                    id: optGlobalShaderSet
                    //property to manage parameter name
                    property string parameterName : "global.shaderset"

                    label: qsTr("Predefined shader") + api.tr
                    note: qsTr("Set predefined Shader effect") + api.tr

                    value: api.internal.recalbox.parameterslist.currentName(parameterName)
                    onActivate: {
                        //for callback by parameterslistBox
                        parameterslistBox.parameterName = parameterName;
                        parameterslistBox.callerid = optGlobalShaderSet;
                        //to force update of list of parameters
                        api.internal.recalbox.parameterslist.currentName(parameterName);
                        parameterslistBox.model = api.internal.recalbox.parameterslist;
                        parameterslistBox.index = api.internal.recalbox.parameterslist.currentIndex;
                        //to transfer focus to parameterslistBox
                        parameterslistBox.focus = true;
                    }
                    onFocusChanged: container.onFocus(this)
                    KeyNavigation.down: optGlobalShader
                }
                MultivalueOption {
                    id: optGlobalShader
                    //property to manage parameter name
                    property string parameterName : "global.shaders"

                    label: qsTr("Shaders") + api.tr
                    note: qsTr("Set prefered Shader effect") + api.tr

                    value: api.internal.recalbox.parameterslist.currentName(parameterName)
                    onActivate: {
                        //for callback by parameterslistBox
                        parameterslistBox.parameterName = parameterName;
                        parameterslistBox.callerid = optGlobalShader;
                        //to force update of list of parameters
                        api.internal.recalbox.parameterslist.currentName(parameterName);
                        parameterslistBox.model = api.internal.recalbox.parameterslist;
                        parameterslistBox.index = api.internal.recalbox.parameterslist.currentIndex;
                        //to transfer focus to parameterslistBox
                        parameterslistBox.focus = true;
                    }
                    onFocusChanged: container.onFocus(this)
                    KeyNavigation.down: optGlobalOverlays
                }
                ToggleOption {
                    id: optGlobalOverlays

                    label: qsTr("Set overlays") + api.tr
                    note: qsTr("Set overlays for all systems") + api.tr

                    checked: api.internal.recalbox.getBoolParameter("global.recalboxoverlays")
                    onCheckedChanged: {
                        focus = true;
                        api.internal.recalbox.setBoolParameter("global.recalboxoverlays",checked);
                    }
                    onFocusChanged: container.onFocus(this)
                    KeyNavigation.down: optShowFramerate
                }
                ToggleOption {
                    id: optShowFramerate

                    label: qsTr("Show framerate") + api.tr
                    note: qsTr("Show FPS in game") + api.tr

                    checked: api.internal.recalbox.getBoolParameter("global.showfps")
                    onCheckedChanged: {
                        focus = true;
                        api.internal.recalbox.setBoolParameter("global.showfps",checked);
                    }
                    onFocusChanged: container.onFocus(this)
                    KeyNavigation.down: optGameRewind
                }
                SectionTitle {
                    text: qsTr("Gameplay options") + api.tr
                    first: true
                    symbol: "\uf412"
                }
                ToggleOption {
                    id: optGameRewind

                    label: qsTr("Game rewind") + api.tr
                    note: qsTr("Set rewind for all emulators 'Only work with Retroarch'") + api.tr

                    checked: api.internal.recalbox.getBoolParameter("global.rewind")
                    onCheckedChanged: {
                        focus = true;
                        api.internal.recalbox.setBoolParameter("global.rewind",checked);
                    }
                    onFocusChanged: container.onFocus(this)
                    KeyNavigation.down: optAutoSave
                }
                ToggleOption {
                    id: optAutoSave

                    label: qsTr("Auto save/load") + api.tr
                    note: qsTr("Set autosave/load savestate for all emulators") + api.tr

                    checked: api.internal.recalbox.getBoolParameter("global.autosave")
                    onCheckedChanged: {
                        focus = true;
                        api.internal.recalbox.setBoolParameter("global.autosave",checked);
                    }
                    onFocusChanged: container.onFocus(this)
                    KeyNavigation.down: optBiosChecking

                }
                SectionTitle {
                    text: qsTr("Other options") + api.tr
                    first: true
                    symbol: "\uf1d9"
                }
                SimpleButton {
                    id: optBiosChecking

                    label: qsTr("Bios Checking") + api.tr
                    note: qsTr("Check all necessary bios !") + api.tr
                    pointerIcon: true

                    onActivate: {
                        focus = true;
                        root.openBiosCheckingSettings();
                    }
                    onFocusChanged: container.onFocus(this)
                    KeyNavigation.down: optAdvancedEmulator
                }
                SimpleButton {
                    id: optAdvancedEmulator

                    label: qsTr("Advandced emulators settings") + api.tr
                    note: qsTr("choose emulator, ratio and more by system") + api.tr
                    //pointer moved in SimpleButton desactived on default
                    pointerIcon: true

                    onActivate: {
                        focus = true;
                        root.openAdvancedEmulatorSettings();
                    }
                    onFocusChanged: container.onFocus(this)
                    KeyNavigation.up: optBiosChecking
                }
                Item {
                    width: parent.width
                    height: implicitHeight + vpx(30)
                }
            }
        }
    }
    MultivalueBox {
        id: parameterslistBox
        z: 3

        //properties to manage parameter
        property string parameterName
        property MultivalueOption callerid

        //reuse same model
        model: api.internal.recalbox.parameterslist.model
        //to use index from parameterlist QAbstractList
        index: api.internal.recalbox.parameterslist.currentIndex

        onClose: content.focus = true
        onSelect: {
            //to update index of parameterlist QAbstractList
            api.internal.recalbox.parameterslist.currentIndex = index;
            //to force update of display of selected value
            callerid.value = api.internal.recalbox.parameterslist.currentName(parameterName);
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
