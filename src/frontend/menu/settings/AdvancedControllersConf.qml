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
//import "keyeditor"
import "qrc:/qmlutils" as PegasusUtils
import QtQuick 2.12
import QtQuick.Window 2.12

FocusScope {
    id: root

    signal close

    anchors.fill: parent
    enabled: focus
    visible: 0 < (x + width) && x < Window.window.width

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
        text: qsTr("Controllers > Advanced controllers configuration") + api.tr
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
                    text: qsTr("Sony controllers") + api.tr
                    first: true
                }
                ToggleOption {
                    id: optPs3Controllers
                    //controllers.ps3.enabled=1
                    // set focus only on first item
                    focus: true

                    label: qsTr("Enable Sony Playstation bluetooth controllers") + api.tr
                    note: qsTr("Sony Playstation 3,4,5 controllers supported") + api.tr

                    checked: api.internal.recalbox.getBoolParameter("controllers.ps3.enabled")
                    onCheckedChanged: {
                        focus = true;
                        api.internal.recalbox.setBoolParameter("controllers.ps3.enabled",checked);
                    }
                    onFocusChanged: container.onFocus(this)
                    KeyNavigation.down: optDriversPs3Controllers
                }
                MultivalueOption {
                    id: optDriversPs3Controllers
                    property string parameterName :"controllers.ps3.driver"
                    // ## Choose a driver between bluez, official and shanwan
                    // controllers.ps3.driver=bluez
                    label: qsTr("Sony controllers drivers bluetooth") + api.tr
                    note: qsTr("Choose a driver between bluez, official and shanwan") + api.tr

                    value: api.internal.recalbox.parameterslist.currentName(parameterName)
                    onActivate: {
                        parameterslistBox.parameterName = parameterName;
                        parameterslistBox.callerid = optDriversPs3Controllers;
                        api.internal.recalbox.parameterslist.currentName(parameterName);
                        parameterslistBox.model = api.internal.recalbox.parameterslist;
                        parameterslistBox.index = api.internal.recalbox.parameterslist.currentIndex;
                        parameterslistBox.focus = true;
                    }
                    onFocusChanged: container.onFocus(this)
                    KeyNavigation.down: optDB9Controllers
                }
                SectionTitle {
                    text: qsTr("Db9 controllers") + api.tr
                    first: true
                }
                ToggleOption {
                    id: optDB9Controllers
                    //## Enable DB9 drivers for atari, megadrive, amiga controllers (0,1)
                    //controllers.db9.enabled=0
                    label: qsTr("Enable driver DB9") + api.tr
                    note: qsTr("Enable DB9 drivers for atari, megadrive, amiga controllers") + api.tr

                    checked: api.internal.recalbox.getBoolParameter("controllers.db9.enabled")
                    onCheckedChanged: {
                        focus = true;
                        api.internal.recalbox.setBoolParameter("controllers.db9.enabled",checked);
                    }
                    onFocusChanged: container.onFocus(this)
                    KeyNavigation.down: optDB9Arguments
                }
                ToggleOption {
                    id: optDB9Arguments
                    //controllers.db9.args=map=??
                    label: qsTr("DB9 Arguement") + api.tr
                    note: qsTr("Enable DB9 Arguments Mapping for atari, megadrive, amiga controllers") + api.tr

                    checked: api.internal.recalbox.getBoolParameter("controllers.db9.enabled")
                    onCheckedChanged: {
                        focus = true;
                        api.internal.recalbox.setBoolParameter("controllers.db9.enabled",checked);
                    }
                    onFocusChanged: container.onFocus(this)
                    KeyNavigation.down: optGameconControllers
                }
                SectionTitle {
                    text: qsTr("Gamecon controllers") + api.tr
                    first: true
                }
                ToggleOption {
                    id: optGameconControllers
                    //## Enable gamecon controllers, for nes, snes, psx (0,1)
                    //controllers.gamecon.enabled=0
                    label: qsTr("Gamecon controller") + api.tr
                    note: qsTr("Enable gamecon controllers, for nes, snes, psx") + api.tr

                    checked: api.internal.recalbox.getBoolParameter("controllers.gamecon.enabled")
                    onCheckedChanged: {
                        focus = true;
                        api.internal.recalbox.setBoolParameter("controllers.gamecon.enabled",checked);
                    }
                    onFocusChanged: container.onFocus(this)
                    KeyNavigation.down: optGameconArguments
                }
                ToggleOption {
                    id: optGameconArguments
                    //controllers.gamecon.args=map=1 ???
                    label: qsTr("Gamecon controller") + api.tr
                    note: qsTr("Enable gamecon Arguments mapping, for nes, snes, psx") + api.tr

                    checked: api.internal.recalbox.getBoolParameter("controllers.gamecon.args=map")
                    onCheckedChanged: {
                        focus = true;
                        api.internal.recalbox.setBoolParameter("controllers.gamecon.args=map",checked);
                    }
                    onFocusChanged: container.onFocus(this)
                    KeyNavigation.down: optArcadeStick
                }
                SectionTitle {
                    text: qsTr("Arcade Stick") + api.tr
                    first: true
                }
                ToggleOption {
                    id: optArcadeStick
                    //controllers.xarcade.enabled=1
                    label: qsTr("Enable driver XGaming's") + api.tr
                    note: qsTr("XGaming's XArcade Tankstick and other compatible devices") + api.tr

                    checked: api.internal.recalbox.getBoolParameter("controllers.xarcade.enabled")
                    onCheckedChanged: {
                        focus = true;
                        api.internal.recalbox.setBoolParameter("controllers.xarcade.enabled",checked);
                    }
                    onFocusChanged: container.onFocus(this)
                    KeyNavigation.down: optWiiSensorsBars
                }
                SectionTitle {
                    text: qsTr("Dolphin emulators controllers") + api.tr
                    first: true
                }
                ToggleOption {
                    id: optWiiSensorsBars
                    //wii.sensorbar.position=1

                    label: qsTr("Wiimote sensor bar position") + api.tr
                    note: qsTr("set position to 1 for the sensor bar at the top of the screen, to 0 for the sensor bar at the bottom") + api.tr

                    checked: api.internal.recalbox.getBoolParameter("wii.sensorbar.position")
                    onCheckedChanged: {
                        focus = true;
                        api.internal.recalbox.setBoolParameter("wii.sensorbar.position",checked);
                    }
                    onFocusChanged: container.onFocus(this)
                    KeyNavigation.down: optRealWiimotes
                }
                ToggleOption {
                    id: optRealWiimotes
                    //wii.realwiimotes=0
                    label: qsTr("Use authentics Wiimotes controllers") + api.tr
                    note: qsTr("Use authentics Wiimotes pads in wii emulator (dolphin-emu)") + api.tr

                    checked: api.internal.recalbox.getBoolParameter("wii.realwiimotes")
                    onCheckedChanged: {
                        focus = true;
                        api.internal.recalbox.setBoolParameter("wii.realwiimotes",checked);
                    }
                    onFocusChanged: container.onFocus(this)
                    KeyNavigation.down: optGcControllers
                }
                ToggleOption {
                    id: optGcControllers
                    //gamecube.realgamecubepads=0
                    label: qsTr("Use authentics Gamecube pads") + api.tr
                    note: qsTr("Use authentics Gamecube pads in Gamecube emulator (dolphin-emu)") + api.tr

                    checked: api.internal.recalbox.getBoolParameter("gamecube.realgamecubepads")
                    onCheckedChanged: {
                        focus = true;
                        api.internal.recalbox.setBoolParameter("gamecube.realgamecubepads",checked);
                    }
                    onFocusChanged: container.onFocus(this)
                    KeyNavigation.down: optJoyconControllers
                }
                SectionTitle {
                    text: qsTr("Joycon controllers") + api.tr
                    first: true
                }
                ToggleOption {
                    id: optJoyconControllers
                    //controllers.joycond.enabled=1
                    label: qsTr("Joycon support") + api.tr
                    note: qsTr("Use authentics Joycon pads") + api.tr

                    checked: api.internal.recalbox.getBoolParameter("controllers.joycond.enabled")
                    onCheckedChanged: {
                        focus = true;
                        api.internal.recalbox.setBoolParameter("controllers.joycond.enabled",checked);
                    }
                    onFocusChanged: container.onFocus(this)
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
