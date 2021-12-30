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

    property alias bluetoothDeviceVisibility: optBluetoothDevices.visible
    property var controllersListItemIndexHasFocus: -1

    signal close
    signal openBluetoothDevices
    signal openGamepadSettings
    signal openGameDirSettings
    signal openAdvancedControllersConfiguration

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
        text: qsTr("Controllers") + api.tr
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
                    text: qsTr("Controllers") + api.tr
                    first: true
                    symbol: "\uf181"
                }
                SimpleButton {
                    id: optBluetoothDevices

                    // set focus only on first item
                    focus: visible

                    label: qsTr("Bluetooth devices") + api.tr
                    note: qsTr("connect your pads") + api.tr

                    Text {
                        id: pointeroptBluetoothConfig

                        anchors.right: parent.right
                        anchors.verticalCenter: parent.verticalCenter

                        color: themeColor.textValue
                        font.pixelSize: vpx(30)
                        font.family: globalFonts.ion

                        text : "\uf3d1"
                    }
					
                    onActivate: {
                        focus = true;
                        root.openBluetoothDevices();
                    }
                    onFocusChanged: container.onFocus(this)
                    KeyNavigation.down: optGamepadConfig
                    visible: api.internal.recalbox.getBoolParameter("controllers.bluetooth.enabled")
                }
                SimpleButton {
                    id: optGamepadConfig
                    //take focus if Bluetooth Devices button is not visible
                    focus: !optBluetoothDevices.focus
                    label: qsTr("Gamepad layout") + api.tr
                    note: qsTr("Show game layout configuration controller") + api.tr

                    Text {
                        id: pointeroptGamepadConfig

                        anchors.right: parent.right
                        anchors.verticalCenter: parent.verticalCenter

                        color: themeColor.textValue
                        font.pixelSize: vpx(30)
                        font.family: globalFonts.ion

                        text : "\uf3d1"
                    }

                    onActivate: {
                        focus = true;
                        root.openGamepadSettings();
                    }
                    onFocusChanged: container.onFocus(this)
                    KeyNavigation.down: optAdvancedControllers
                }
                SimpleButton {
                    id: optAdvancedControllers

                    label: qsTr("Advanced controllers configuration") + api.tr
                    note: qsTr("Choose your drivers or Special Controllers") + api.tr

                    Text {
                        id: pointeroptAdvancedControllers

                        anchors.right: parent.right
                        anchors.verticalCenter: parent.verticalCenter

                        color: themeColor.textValue
                        font.pixelSize: vpx(30)
                        font.family: globalFonts.ion

                        text : "\uf3d1"
                    }

                    onActivate: {
                        focus = true;
                        root.openAdvancedControllersConfiguration();
                    }
                    onFocusChanged: container.onFocus(this)
                    KeyNavigation.up: optGamepadConfig
                    Keys.onPressed: {
                        //verify if finally other lists are empty or not when we are just before to change list
                        //it's a tip to refresh the KeyNavigations value just before to change from one list to an other
                        if ((event.key === Qt.Key_Down) && !event.isAutoRepeat) {
                            if (controllersList.count !== 0) KeyNavigation.down = controllersList.itemAt(0);
                            else KeyNavigation.down = optAdvancedControllers;
                        }
                   }

                }
                SectionTitle {
                    text: qsTr("Controllers inputs") + api.tr
                    first: false
                    symbol: "\uf4a9"
                }
                Repeater{
                    id:controllersList
                    model: api.internal.gamepad.devices
                    onItemRemoved:{
                        //if previous focus was the removed one
                        if(controllersListItemIndexHasFocus === index){
                            //if focus is on the Removed one
                            if(controllersList.count === 0){
                                //if empty go up
                                optAdvancedControllers.focus = true;
                            }
                            else if (index > controllersList.count-1){
                                //if it was the last one
                                controllersList.itemAt(controllersList.count-1).focus = true;
                            }
                            else {
                                //if not the last one
                                controllersList.itemAt(index).focus = true;
                            }
                        }
                    }

                    SimpleButton {
                        label: (modelData) ? "#" + (index + 1) + ": " + modelData.name : ""
                        // set focus only on first item
                        focus: index == 0 ? true : false
                        onActivate: {
                            focus = true;
                        }
                        onActiveFocusChanged:{
                            if(focus) controllersListItemIndexHasFocus = index;
                        }
                        onFocusChanged:{
                            container.onFocus(this);
                        }
                        Keys.onPressed: {
                            //verify if finally other lists are empty or not when we are just before to change list
                            //it's a tip to refresh the KeyNavigations value just before to change from one list to an other
                            if ((event.key === Qt.Key_Up) && !event.isAutoRepeat) {

                                if (index > 0) KeyNavigation.up = controllersList.itemAt(index-1);
                                else {

                                    KeyNavigation.up = optAdvancedControllers;
                                    console.log("Keys.onPressed - controllersListItemIndexHasFocus = -1;");
                                    controllersListItemIndexHasFocus = -1;
                                }
                            }
                            if ((event.key === Qt.Key_Down) && !event.isAutoRepeat) {
                                if (index < controllersList.count-1) KeyNavigation.down = controllersList.itemAt(index+1);
                                else KeyNavigation.down = controllersList.itemAt(controllersList.count-1);
                            }
                        }
                    }
                }
                Item {
                    width: parent.width
                    height: implicitHeight + vpx(30)
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
