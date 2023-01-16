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
    property int controllersListItemIndexHasFocus: -1

    signal close
    signal openBluetoothDevices
    signal openGamepadSettings(var parameters)
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
                    id: optGamepadConfig
                    //take focus by default
                    focus: true
                    label: qsTr("Gamepad layout") + api.tr
                    note: qsTr("Show game layout configuration controller") + api.tr
                    //pointer moved in SimpleButton desactived on default
                    pointerIcon: true

                    onActivate: {
                        focus = true;
                        root.openGamepadSettings({"selectedGamepadIndex":0});
                    }
                    onFocusChanged: container.onFocus(this)
                    KeyNavigation.down: optBluetoothDevices
                }
                SimpleButton {
                    id: optBluetoothDevices

                    label: qsTr("Bluetooth devices") + api.tr
                    note: qsTr("connect your pads") + api.tr
                    //pointer moved in SimpleButton desactived on default
                    pointerIcon: true

                    onActivate: {
                        focus = true;
                        root.openBluetoothDevices();
                    }
                    onFocusChanged: container.onFocus(this)
                    KeyNavigation.down: optAdvancedControllers
                    visible: api.internal.recalbox.getBoolParameter("controllers.bluetooth.enabled")
                }
                SimpleButton {
                    id: optAdvancedControllers

                    label: qsTr("Advanced controllers configuration") + api.tr
                    note: qsTr("Choose your drivers or Special Controllers") + api.tr
                    //pointer moved in SimpleButton desactived on default
                    pointerIcon: true

                    onActivate: {
                        focus = true;
                        root.openAdvancedControllersConfiguration();
                    }
                    onFocusChanged: container.onFocus(this)
                    KeyNavigation.up: optBluetoothDevices
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
                    first: true
                    symbol: "\uf4a9"
                }
                Repeater{
                    id:controllersList
                    model: api.internal.gamepad.devices
                    //specific properties to manage interactions between items of the repeater
                    property bool moveMode: false
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
                    onMoveModeChanged: {
                        //DO TO
                        //change background and add icon to display that we could move or not the item
                        //and for index using controllersList.itemAt(index)...
                        
                    }

                    SimpleButton {
                        selectButton: controllersList.moveMode && focus
                        showUnderline: !selectButton
                        Text {
                            id: deviceIcon

                            color: themeColor.textLabel
                            text : getIcon(modelData.name,"");
                            font.pixelSize: (parent.fontSize)*getIconRatio(deviceIcon.text)*0.9
                            font.family: getIconFont

                            anchors.right: parent.left
                            anchors.rightMargin: vpx(10)
                            anchors.verticalCenter: parent.verticalCenter

                            visible: true
                        }
                        label: (modelData) ? "#" + (index + 1) + ": " + modelData.name +
                                             (api.internal.recalbox.getBoolParameter("emulationstation.debuglogs") ?
                                             " (id:" + modelData.deviceId + "/idx:" + modelData.deviceIndex + "/iid:" + modelData.deviceInstance + ")" :
                                             " (" +modelData.deviceInstance + ")") :
                                             ""
                        Text {
                            id: moveIcon

                            anchors.left: parent.right
                            anchors.leftMargin: vpx(10)
                            anchors.verticalCenter: parent.verticalCenter
                            //anchors.bottom: parent.bottom
                            //anchors.bottomMargin: vpx(10)

                            color: themeColor.textLabel
                            text : "\uf220"
                            font.pixelSize: (parent.fontSize)*getIconRatio(moveIcon.text)
                            font.family: globalFonts.ion
                            height: parent.height
                            visible: controllersList.moveMode && parent.focus
                        }


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
                            //Activation/Desactivation "move Mode" to change order of controllers connected
                            if (api.keys.isAccept(event) && !event.isAutoRepeat) {
                                event.accepted = true;
                                if(controllersList.count > 1) controllersList.moveMode = !controllersList.moveMode;
                                //console.log("controllersList.moveMode : ", controllersList.moveMode);
                            }
                            //Desactivation of "move Mode" to change order of controllers connected
                            if (api.keys.isCancel(event) && !event.isAutoRepeat) {
                                if(controllersList.moveMode) event.accepted = true;
                                controllersList.moveMode = false;
                                //console.log("controllersList.moveMode : ", controllersList.moveMode);
                            }
                            //Launch gamepadeditor from selected gamepad from the controllersList
                            else if(api.keys.isFilters(event) && !event.isAutoRepeat) { //Y
                                //console.log("api.keys.isFilters(event)");
                                event.accepted = true;
                                if(!controllersList.moveMode) root.openGamepadSettings({"selectedGamepadIndex":index});
                            }
                            else if (api.keys.isDetails(event) && !event.isAutoRepeat) { //X
                                //console.log("api.keys.isDetails(event)");
                                //RFU
                            }
                            //verify if finally other lists are empty or not when we are just before to change list
                            //it's a tip to refresh the KeyNavigations value just before to change from one list to an other
                            if ((event.key === Qt.Key_Up) && !event.isAutoRepeat) {
                                if (index > 0) {
                                    KeyNavigation.up = controllersList.itemAt(index-1);
                                    //Call api to change index of controller
                                    if (controllersList.moveMode){
                                        api.internal.gamepad.swap(index,index-1);
                                    }
                                }
                                else{
                                    if(!controllersList.moveMode){
                                        KeyNavigation.up = optAdvancedControllers;
                                        //console.log("Keys.onPressed - controllersListItemIndexHasFocus = -1;");
                                        controllersListItemIndexHasFocus = -1;
                                    }
                                    else{
                                        KeyNavigation.up = controllersList.itemAt(0);
                                    }
                                }
                            }
                            if ((event.key === Qt.Key_Down) && !event.isAutoRepeat) {
                                if (index < controllersList.count-1){
                                    KeyNavigation.down = controllersList.itemAt(index+1);
                                    //Call api to change index of controller
                                    if (controllersList.moveMode){
                                        api.internal.gamepad.swap(index,index+1);
                                    }
                                }
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

    //to clean, legacy copy/paste ;-)
    /*MultivalueBox {
        id: localeBox
        z: 3

        model: api.internal.settings.locales
        index: api.internal.settings.locales.currentIndex

        onClose: content.focus = true
        onSelect: api.internal.settings.locales.currentIndex = index
    }*/
    /*MultivalueBox {
        id: themeBox
        z: 3
        model: api.internal.settings.themes
        index: api.internal.settings.themes.currentIndex

        onClose: content.focus = true
        onSelect: api.internal.settings.themes.currentIndex = index
    }*/

    Item {
        id: footer
        width: parent.width
        height: vpx(50)
        anchors.bottom: parent.bottom
        visible: controllersListItemIndexHasFocus !== -1
        z:2

        //Rectangle for the transparent background
        Rectangle {
            anchors.fill: parent
            color: themeColor.screenHeader
            opacity: 0.1
        }

        //rectangle for the gray line
        Rectangle {
            width: parent.width * 0.97
            height: vpx(1)
            color: "#777"
            anchors.top: parent.top
            anchors.horizontalCenter: parent.horizontalCenter
        }

        //for the help to "gamepad layout"
        Rectangle {
            id: filterButtonIcon
            height: labelY.height
            width: height
            radius: width * 0.5
            border { color: "#777"; width: vpx(1) }
            color: "transparent"
            visible: !controllersList.moveMode

            anchors {
                right: labelY.left
                verticalCenter: parent.verticalCenter
                verticalCenterOffset: vpx(1)
                margins: vpx(10)
            }
            Text {
                text: "Y"
                color: "#777"
                font {
                    family: global.fonts.sans
                    pixelSize: parent.height * 0.7
                }
                anchors.centerIn: parent
            }
        }

        Text {
            id: labelY
            text: qsTr("Selected gamepad layout") + api.tr
            verticalAlignment: Text.AlignTop
            visible: !controllersList.moveMode

            color: "#777"
            font {
                family: global.fonts.sans
                pixelSize: vpx(22)
                capitalization: Font.SmallCaps
            }
            anchors {
                verticalCenter: parent.verticalCenter
                verticalCenterOffset: vpx(-1)
                right: (controllersList.count > 1) ? validButtonIcon.left : parent.right;
                rightMargin: parent.width * 0.015
            }
        }


        //for the help to "Change controller order"
        Rectangle {
            id: validButtonIcon
            height: labelA.height
            width: height
            radius: width * 0.5
            border { color: "#777"; width: vpx(1) }
            color: "transparent"
            visible: (controllersList.count > 1) //!controllersList.moveMode
            anchors {
                right: labelA.left
                verticalCenter: parent.verticalCenter
                verticalCenterOffset: vpx(1)
                margins: controllersList.moveMode ? vpx(5) : vpx(10)
            }
            Text {
                text: "A"
                color: "#777"
                font {
                    family: global.fonts.sans
                    pixelSize: parent.height * 0.7
                }
                anchors.centerIn: parent
            }
        }

        Text {
            id: labelA
            text: controllersList.moveMode ? "/" : qsTr("Change the order") + api.tr
            verticalAlignment: Text.AlignTop
            color: "#777"
            visible: (controllersList.count > 1)
            font {
                family: global.fonts.sans
                pixelSize: vpx(22)
                capitalization: Font.SmallCaps
            }
            anchors {
                verticalCenter: parent.verticalCenter
                verticalCenterOffset: vpx(-1)
                right: controllersList.moveMode ? backButtonIcon.left : parent.right
                rightMargin: controllersList.moveMode ? vpx(5) : parent.width * 0.015
            }
        }

        //for the help for "stop moving"
        Rectangle {
            id: backButtonIcon
            height: labelB.height
            width: height
            radius: width * 0.5
            border { color: "#777"; width: vpx(1) }
            color: "transparent"
            visible: controllersList.moveMode

            anchors {
                right: labelB.left
                verticalCenter: parent.verticalCenter
                verticalCenterOffset: vpx(1)
                margins: vpx(10)
            }
            Text {
                text: "B"
                color: "#777"
                font {
                    family: global.fonts.sans
                    pixelSize: parent.height * 0.7
                }
                anchors.centerIn: parent
            }
        }

        Text {
            id: labelB
            text: qsTr("Stop moving") + api.tr
            verticalAlignment: Text.AlignTop
            visible: controllersList.moveMode

            color: "#777"
            font {
                family: global.fonts.sans
                pixelSize: vpx(22)
                capitalization: Font.SmallCaps
            }
            anchors {
                verticalCenter: parent.verticalCenter
                verticalCenterOffset: vpx(-1)
                right: parent.right; rightMargin: parent.width * 0.015
            }
        }

        //for the help to 'RFU'
        Rectangle {
            id: detailButtonIcon
            height: labelX.height
            width: height
            radius: width * 0.5
            border { color: "#777"; width: vpx(1) }
            color: "transparent"
            visible: {
                return false;
            }
            anchors {
                right: labelX.left
                verticalCenter: parent.verticalCenter
                verticalCenterOffset: vpx(1)
                margins: vpx(10)
            }
            Text {
                text: "X"
                color: "#777"
                font {
                    family: global.fonts.sans
                    pixelSize: parent.height * 0.7
                }
                anchors.centerIn: parent
            }
        }

        Text {
            id: labelX
            text: qsTr("") + api.tr
            verticalAlignment: Text.AlignTop
            color: "#777"
            visible: {
                return false;
            }

            font {
                family: global.fonts.sans
                pixelSize: vpx(22)
                capitalization: Font.SmallCaps
            }
            anchors {
                verticalCenter: parent.verticalCenter
                verticalCenterOffset: vpx(-1)
                right: filterButtonIcon.left; rightMargin: parent.width * 0.015
            }
        }

    }




}
