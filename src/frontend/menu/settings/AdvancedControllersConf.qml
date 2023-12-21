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

                ToggleOption {
                    id: optBluetoothControllers
                    //controllers.bluetooth.enabled=1
                    // set focus only on first item
                    focus: true
                    SectionTitle {
                        text: qsTr("Bluetooth controlers") + api.tr
                        first: true
                    }
                    // label: qsTr("Enable bluetooth") + api.tr
                    // note: qsTr("Enable support for bluetooth controllers") + api.tr


                    checked: api.internal.recalbox.getBoolParameter("controllers.bluetooth.enabled",true);
                    onCheckedChanged: {
                        if(checked !== api.internal.recalbox.getBoolParameter("controllers.bluetooth.enabled",true)){
                            api.internal.recalbox.setBoolParameter("controllers.bluetooth.enabled",checked);
                            //need to reboot to take change into account !
                            needReboot = true;
                        }
                    }
                    symbol: "\uf29a"
                    onFocusChanged: container.onFocus(this)
                    KeyNavigation.down: optBluetoothAutopair
                }
                ToggleOption {
                    id: optBluetoothAutopair
                    //controllers.bluetooth.autopair=1 by default
                    label: qsTr("Enable Auto pairing") + api.tr
                    note: qsTr("Enable support of autopairing during 5 min after boot for bluetooth controllers.\nPlease reboot to apply change") + api.tr

                    checked: api.internal.recalbox.getBoolParameter("controllers.bluetooth.autopair",true);
                    onCheckedChanged: {
                        if(checked !== api.internal.recalbox.getBoolParameter("controllers.bluetooth.autopair",true)){
                            api.internal.recalbox.setBoolParameter("controllers.bluetooth.autopair",checked);
                            //need to reboot to take change into account !
                            needReboot = true;
                        }
                    }
                    onFocusChanged: container.onFocus(this)
                    KeyNavigation.down: optBluetoothScanMethods
                    visible: optBluetoothControllers.checked
                }
                MultivalueOption {
                    id: optBluetoothScanMethods
                    //controllers.bluetooth.scan.methods
                    property string parameterName :"controllers.bluetooth.scan.methods"
                    label: qsTr("Scanning Method") + api.tr
                    note: qsTr("Select Legacy or any new ones") + api.tr

                    value: api.internal.recalbox.parameterslist.currentName(parameterName)
                    onActivate: {
                        parameterslistBox.parameterName = parameterName;
                        parameterslistBox.callerid = optBluetoothScanMethods;
                        api.internal.recalbox.parameterslist.currentName(parameterName);
                        parameterslistBox.model = api.internal.recalbox.parameterslist;
                        parameterslistBox.index = api.internal.recalbox.parameterslist.currentIndex;
                        parameterslistBox.focus = true;
                    }
                    onFocusChanged: container.onFocus(this)
                    KeyNavigation.down: optBluetoothPairMethods
                    visible: optBluetoothControllers.checked
                }
                MultivalueOption {
                    id: optBluetoothPairMethods
                    //controllers.bluetooth.pair.methods
                    property string parameterName :"controllers.bluetooth.pair.methods"
                    label: qsTr("Pairing Device Method") + api.tr
                    note: qsTr("Select legacy or simple one") + api.tr

                    value: api.internal.recalbox.parameterslist.currentName(parameterName)
                    onActivate: {
                        parameterslistBox.parameterName = parameterName;
                        parameterslistBox.callerid = optBluetoothPairMethods;
                        api.internal.recalbox.parameterslist.currentName(parameterName);
                        parameterslistBox.model = api.internal.recalbox.parameterslist;
                        parameterslistBox.index = api.internal.recalbox.parameterslist.currentIndex;
                        parameterslistBox.focus = true;
                    }
                    onFocusChanged: container.onFocus(this)
                    KeyNavigation.down: optBluetoothUnpairMethods
                    visible: optBluetoothControllers.checked
                }
                MultivalueOption {
                    id: optBluetoothUnpairMethods
                    //controllers.bluetooth.unpair.methods
                    property string parameterName :"controllers.bluetooth.unpair.methods"
                    label: qsTr("Forget Device Method") + api.tr
                    note: qsTr("Select Legacy or simple one") + api.tr

                    value: api.internal.recalbox.parameterslist.currentName(parameterName)
                    onActivate: {
                        parameterslistBox.parameterName = parameterName;
                        parameterslistBox.callerid = optBluetoothUnpairMethods;
                        api.internal.recalbox.parameterslist.currentName(parameterName);
                        parameterslistBox.model = api.internal.recalbox.parameterslist;
                        parameterslistBox.index = api.internal.recalbox.parameterslist.currentIndex;
                        parameterslistBox.focus = true;
                    }
                    onFocusChanged: container.onFocus(this)
                    KeyNavigation.down: optBluetoothERTM
                    visible: optBluetoothControllers.checked
                }
                ToggleOption {
                    id: optBluetoothERTM
                    //controllers.bluetooth.ertm=1
                    label: qsTr("Enable ERTM") + api.tr
                    note: qsTr("Enable additional enhanced retransmission mode") + api.tr

                    checked: api.internal.recalbox.getBoolParameter("controllers.bluetooth.ertm")
                    onCheckedChanged: {
                        api.internal.recalbox.setBoolParameter("controllers.bluetooth.ertm",checked);
                    }
                    onFocusChanged: container.onFocus(this)
                    KeyNavigation.down: optHideUnknownVendor
                    visible: optBluetoothControllers.checked
                }
                ToggleOption {
                    id: optHideUnknownVendor
                    //controllers.bluetooth.hide.unknown.vendor=1
                    label: qsTr("Hide Unknown Vendor") + api.tr
                    note: qsTr("Hide device identified as Unknown Vendor") + api.tr

                    checked: api.internal.recalbox.getBoolParameter("controllers.bluetooth.hide.unknown.vendor")
                    onCheckedChanged: {
                        api.internal.recalbox.setBoolParameter("controllers.bluetooth.hide.unknown.vendor",checked);
                    }
                    onFocusChanged: container.onFocus(this)
                    KeyNavigation.down: optHideNoName
                    visible: optBluetoothControllers.checked
                }
                ToggleOption {
                    id: optHideNoName
                    //controllers.bluetooth.hide.no.name=1
                    label: qsTr("Hide No Name") + api.tr
                    note: qsTr("Hide device without name") + api.tr

                    checked: api.internal.recalbox.getBoolParameter("controllers.bluetooth.hide.no.name")
                    onCheckedChanged: {
                        api.internal.recalbox.setBoolParameter("controllers.bluetooth.hide.no.name",checked);
                    }
                    onFocusChanged: container.onFocus(this)
                    KeyNavigation.down: optBluetoothStartReset
                    visible: optBluetoothControllers.checked
                }
                ToggleOption {
                    id: optBluetoothStartReset
                    //controllers.bluetooth.startreset=1
                    label: qsTr("Reset Bluetooth at start") + api.tr
                    note: qsTr("The goal is to restart the bluetooth stack at start/restart of Pegasus - could resolve issue of pairing") + api.tr

                    checked: api.internal.recalbox.getBoolParameter("controllers.bluetooth.startreset")
                    onCheckedChanged: {
                        api.internal.recalbox.setBoolParameter("controllers.bluetooth.startreset",checked);
                    }
                    onFocusChanged: container.onFocus(this)
                    KeyNavigation.down: optPs3Controllers
                    visible: optBluetoothControllers.checked
                }

                ToggleOption {
                    id: optPs3Controllers
                    SectionTitle {
                        text: qsTr("Sony PS3 bluetooth controllers") + api.tr
                        first: true
                        visible: optBluetoothControllers.checked
                    }

                    checked: api.internal.recalbox.getBoolParameter("controllers.ps3.enabled")
                    onCheckedChanged: {
                        api.internal.recalbox.setBoolParameter("controllers.ps3.enabled",checked);
                    }
                    symbol: "\uf245"
                    onFocusChanged: container.onFocus(this)
                    KeyNavigation.down: optDriversPs3Controllers
                    visible: optBluetoothControllers.checked
                }
                MultivalueOption {
                    id: optDriversPs3Controllers
                    property string parameterName :"controllers.ps3.driver"
                    // ## Choose a driver between bluez, official and shanwan
                    label: qsTr("Sony PS3 Sixaxis drivers") + api.tr
                    note: qsTr("Choose a driver between bluez, official and shanwan for Sisaxis") + api.tr

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
                    KeyNavigation.down: optArcadeStick //optDB9Controllers
                    visible: optPs3Controllers.checked && optBluetoothControllers.checked
                }

//                ToggleOption {
//                    id: optDB9Controllers
//                    //## Enable DB9 drivers for atari, megadrive, amiga controllers (0,1)
//                    //controllers.db9.enabled=0
//                    //                    label: qsTr("Enable driver DB9") + api.tr
//                    //                    note: qsTr("Enable DB9 drivers for atari, megadrive, amiga controllers") + api.tr
//                    SectionTitle {
//                        text: qsTr("Db9 controllers") + api.tr
//                        first: true
//                    }

//                    checked: api.internal.recalbox.getBoolParameter("controllers.db9.enabled")
//                    onCheckedChanged: {
//                        api.internal.recalbox.setBoolParameter("controllers.db9.enabled",checked);
//                    }
//                    symbol: "\uf13b"
//                    onFocusChanged: container.onFocus(this)
//                    KeyNavigation.down: optDB9Arguments
//                }
//                ToggleOption {
//                    id: optDB9Arguments
//                    //controllers.db9.args=map=??
//                    label: qsTr("DB9 Arguement") + api.tr
//                    note: qsTr("Enable DB9 Arguments Mapping for atari, megadrive, amiga controllers") + api.tr

//                    checked: api.internal.recalbox.getBoolParameter("controllers.db9.enabled")
//                    onCheckedChanged: {
//                        api.internal.recalbox.setBoolParameter("controllers.db9.enabled",checked);
//                    }
//                    onFocusChanged: container.onFocus(this)
//                    KeyNavigation.down: optGameconControllers
//                    visible: optDB9Controllers.checked
//                }

//                ToggleOption {
//                    id: optGameconControllers
//                    //## Enable gamecon controllers, for nes, snes, psx (0,1)
//                    //controllers.gamecon.enabled=0

//                    //                    label: qsTr("Gamecon controller") + api.tr
//                    //                    note: qsTr("Enable gamecon controllers, for nes, snes, psx") + api.tr
//                    SectionTitle {
//                        text: qsTr("Gamecon controllers") + api.tr
//                        first: true
//                    }
//                    checked: api.internal.recalbox.getBoolParameter("controllers.gamecon.enabled")
//                    onCheckedChanged: {
//                        api.internal.recalbox.setBoolParameter("controllers.gamecon.enabled",checked);
//                    }
//                    symbol: "\uf13b"
//                    onFocusChanged: container.onFocus(this)
//                    KeyNavigation.down: optGameconArguments
//                }
//                ToggleOption {
//                    id: optGameconArguments
//                    //controllers.gamecon.args=map=1 ???
//                    label: qsTr("Gamecon controller") + api.tr
//                    note: qsTr("Enable gamecon Arguments mapping, for nes, snes, psx") + api.tr

//                    checked: api.internal.recalbox.getBoolParameter("controllers.gamecon.args=map")
//                    onCheckedChanged: {
//                        api.internal.recalbox.setBoolParameter("controllers.gamecon.args=map",checked);
//                    }
//                    onFocusChanged: container.onFocus(this)
//                    KeyNavigation.down: optArcadeStick
//                    visible: optGameconControllers.checked
//                }
                SectionTitle {
                    text: qsTr("Arcade Stick Driver") + api.tr
                    first: true
                    symbol: "\uf251"
                }
                ToggleOption {
                    id: optArcadeStick
                    //controllers.xarcade.enabled=1
                    label: qsTr("Enable driver XGaming's") + api.tr
                    note: qsTr("XGaming's XArcade Tankstick and other compatible devices") + api.tr

                    checked: api.internal.recalbox.getBoolParameter("controllers.xarcade.enabled")
                    onCheckedChanged: {
                        api.internal.recalbox.setBoolParameter("controllers.xarcade.enabled",checked);
                    }
                    onFocusChanged: container.onFocus(this)
                    KeyNavigation.down: optWiiSensorsBars
                }
                SectionTitle {
                    text: qsTr("Dolphin emulators controllers") + api.tr
                    first: true
                    symbol:"\uf24f"
                }
                ToggleOption {
                    id: optWiiSensorsBars
                    //wii.sensorbar.position=1
                    label: qsTr("Wiimote sensor bar position") + api.tr
                    note: qsTr("set position to 1 for the sensor bar at the top of the screen, to 0 for the sensor bar at the bottom") + api.tr

                    checked: api.internal.recalbox.getBoolParameter("wii.sensorbar.position")
                    onCheckedChanged: {
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
                        api.internal.recalbox.setBoolParameter("gamecube.realgamecubepads",checked);
                    }
                    onFocusChanged: container.onFocus(this)
                    KeyNavigation.down: optJoyconControllers
                }
                SectionTitle {
                    text: qsTr("Joycon controllers") + api.tr
                    first: true
                    symbol:"\uf253"
                }
                ToggleOption {
                    id: optJoyconControllers
                    //controllers.joycond.enabled=1
                    label: qsTr("Joycon support") + api.tr
                    note: qsTr("Use authentics Joycon pads") + api.tr

                    checked: api.internal.recalbox.getBoolParameter("controllers.joycond.enabled")
                    onCheckedChanged: {
                        api.internal.recalbox.setBoolParameter("controllers.joycond.enabled",checked);
                    }
                    onFocusChanged: container.onFocus(this)
                    KeyNavigation.down: optSindenLightgunCrossair

                }
                SectionTitle {
                    text: qsTr("Lightguns") + api.tr
                    first: true
                    symbol: "\uf0d0"
                    symbolFontFamily: global.fonts.awesome //global.fonts.ion is used by default
                }

                ToggleOption {
                    id: optSindenLightgunCrossair
                    label: qsTr("Sinden lightgun crossair enabled") + api.tr
                    note: qsTr("Force crossair display for compatible games") + api.tr

                    checked: api.internal.recalbox.getBoolParameter("lightgun.sinden.crossair.enabled", false)
                    onCheckedChanged: {
                        api.internal.recalbox.setBoolParameter("lightgun.sinden.crossair.enabled",checked);
                    }
                    onFocusChanged: container.onFocus(this)
                    KeyNavigation.down: optSindenLightgunBorderColor

                }

                MultivalueOption {
                    id: optSindenLightgunBorderColor
                    property string parameterName :"lightgun.sinden.bordercolor"
                    label: qsTr("Sinden lightgun border color") + api.tr
                    note: qsTr("Select the border's color for sinden lightguns") + api.tr

                    value: api.internal.recalbox.parameterslist.currentName(parameterName)
                    onActivate: {
                        parameterslistBox.parameterName = parameterName;
                        parameterslistBox.callerid = optSindenLightgunBorderColor;
                        api.internal.recalbox.parameterslist.currentName(parameterName);
                        parameterslistBox.model = api.internal.recalbox.parameterslist;
                        parameterslistBox.index = api.internal.recalbox.parameterslist.currentIndex;
                        parameterslistBox.focus = true;
                    }
                    onFocusChanged: container.onFocus(this)
                    KeyNavigation.down: optSindenLightgunBorderSize
                }

                MultivalueOption {
                    id: optSindenLightgunBorderSize
                    property string parameterName :"lightgun.sinden.bordersize"
                    label: qsTr("Sinden lightgun border size") + api.tr
                    note: qsTr("Select the border's size for sinden lightguns") + api.tr

                    value: api.internal.recalbox.parameterslist.currentName(parameterName)
                    onActivate: {
                        parameterslistBox.parameterName = parameterName;
                        parameterslistBox.callerid = optSindenLightgunBorderSize;
                        api.internal.recalbox.parameterslist.currentName(parameterName);
                        parameterslistBox.model = api.internal.recalbox.parameterslist;
                        parameterslistBox.index = api.internal.recalbox.parameterslist.currentIndex;
                        parameterslistBox.focus = true;
                    }
                    onFocusChanged: container.onFocus(this)
                    KeyNavigation.down: optSindenLightgunRecoilMode
                }

                MultivalueOption {
                    id: optSindenLightgunRecoilMode
                    property string parameterName :"lightgun.sinden.recoilmode"
                    label: qsTr("Sinden lightgun recoil mode") + api.tr
                    note: qsTr("Select the behavior of sinden lightgun recoils") + api.tr

                    value: api.internal.recalbox.parameterslist.currentName(parameterName)
                    onActivate: {
                        parameterslistBox.parameterName = parameterName;
                        parameterslistBox.callerid = optSindenLightgunRecoilMode;
                        api.internal.recalbox.parameterslist.currentName(parameterName);
                        parameterslistBox.model = api.internal.recalbox.parameterslist;
                        parameterslistBox.index = api.internal.recalbox.parameterslist.currentIndex;
                        parameterslistBox.focus = true;
                    }
                    onFocusChanged: container.onFocus(this)
                    KeyNavigation.down: optSindenLightgunSettingsApply
                }
                // to apply settings
                SimpleButton {
                    id: optSindenLightgunSettingsApply
                    Rectangle {
                        id: containerValidate
                        width: parent.width
                        height: parent.height
                        anchors.verticalCenter: parent.verticalCenter
                        anchors.horizontalCenter: parent.horizontalCenter
                        color: parent.focus ? themeColor.underline : themeColor.secondary
                        opacity : parent.focus ? 1 : 0.3
                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            anchors.horizontalCenter: parent.horizontalCenter
                            color: themeColor.textValue
                            font.pixelSize: vpx(30)
                            font.family: globalFonts.ion
                            text : "\uf2ba  " + qsTr("Apply Sinden settings (mandatory for recoil)") + api.tr
                        }
                    }
                    onActivate: {
                        //force save in recalbox.conf file before to execute script
                        api.internal.recalbox.saveParameters();
                        //update sinden lightgun xml values from /recalbox/share/system/.config/sinden/LightgunMono.exe.config
                        //TO DO
                        //restart service
                        api.internal.system.run("/etc/init.d/S99sindenlightgun restart");
                    }
                    onFocusChanged: container.onFocus(this)
                }
                // Section deactivated from removing xow - keep code to easily reactivate if needed
                /*SectionTitle {
                    text: qsTr("Xbox One/Series controllers") + api.tr
                    first: true
                    symbol:"\uf34c"
                }
                ToggleOption {
                    id: optXboxOneControllers
                    //controllers.xow.enabled=1
                    label: qsTr("xow daemon activation") + api.tr
                    note: qsTr("Stop/Start daemon to help Xbox One/Series wireless dongle usage - no need to restart") + api.tr

                    checked: api.internal.recalbox.getBoolParameter("controllers.xow.enabled")
                    onCheckedChanged: {
                        var previousState = api.internal.recalbox.getBoolParameter("controllers.xow.enabled");
                        //start or stop daemon immediately
                        if (!isDebugEnv() && checked && !previousState){
                            //start xow
                            console.log("Start xow daemon");
                            api.internal.system.run("start-stop-daemon -b -S -q -m -p /var/run/xow.pid --exec /usr/bin/xow");
                        }
                        else if (!isDebugEnv() && !checked && previousState){
                            //stop xow
                            console.log("Stop xow daemon");
                            api.internal.system.run("start-stop-daemon -K -q -p /var/run/xow.pid");
                        }
                        api.internal.recalbox.setBoolParameter("controllers.xow.enabled",checked);
                    }
                    onFocusChanged: container.onFocus(this)
                }*/
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
