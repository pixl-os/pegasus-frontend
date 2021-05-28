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
    //    signal openKeySettings
    //    signal openGamepadSettings
    //    signal openGameDirSettings
    //    signal openProviderSettings

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
        text: qsTr("Settings") + api.tr
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
                    text: qsTr("Sound Configuration") + api.tr
                    first: true
                }
                MultivalueOption {
                    id: optAudioMode
                    
                    //property to manage parameter name
                    property string parameterName : "audio.mode"

                    // set focus only on first item
                    focus: true

                    label: qsTr("Mode") + api.tr
                    note: qsTr("Choose Audio Mode") + api.tr
                    value: api.internal.recalbox.parameterslist.currentName(parameterName)
                    font: globalFonts.ion

                    onActivate: {
                        //for callback by parameterslistBox
                        parameterslistBox.parameterName = parameterName;
                        parameterslistBox.callerid = optAudioMode;
                        //to force update of list of parameters
                        api.internal.recalbox.parameterslist.currentName(parameterName);
                        parameterslistBox.model = api.internal.recalbox.parameterslist;
                        parameterslistBox.index = api.internal.recalbox.parameterslist.currentIndex;
                        //to transfer focus to parameterslistBox
                        parameterslistBox.focus = true;
                    }
                    onFocusChanged: container.onFocus(this)
                    KeyNavigation.down: optOutputAudio
                }
                MultivalueOption {
                    id: optOutputAudio
                    
                    //property to manage parameter name
                    property string parameterName : "audio.device"

                    label: qsTr("Output") + api.tr
                    note: qsTr("Choose Audio Output") + api.tr
                    value: api.internal.recalbox.parameterslist.currentName(parameterName)
                    font: globalFonts.awesome
                    
                    onActivate: {
                        //for callback by parameterslistBox
                        parameterslistBox.parameterName = parameterName;
                        parameterslistBox.callerid = optOutputAudio;
                        //to force update of list of parameters
                        api.internal.recalbox.parameterslist.currentName(parameterName);
                        parameterslistBox.model = api.internal.recalbox.parameterslist;
                        parameterslistBox.index = api.internal.recalbox.parameterslist.currentIndex;
                        //to transfer focus to parameterslistBox
                        parameterslistBox.focus = true;
                    }
                    onFocusChanged: container.onFocus(this)
                    KeyNavigation.up: optAudioMode
                    KeyNavigation.down: optOutputVolume
                }
                SliderOption {
                    id: optOutputVolume
                    
                    //property to manage parameter name
                    property string parameterName : "audio.volume"

                    //property of SliderOption to set
                    label: qsTr("Volume") + api.tr
                    note: qsTr("Set Audio Volume") + api.tr
                    // in slider object
                    max : 100
                    min : 0
                    slidervalue : api.internal.recalbox.getIntParameter(parameterName)
                    //in text object
                    value: api.internal.recalbox.getIntParameter(parameterName) + "%"
                                        
                    onActivate: {
                        focus = true;
                    }
                    
                    Keys.onLeftPressed: {
                        api.internal.recalbox.setIntParameter(parameterName,slidervalue);
                        value = slidervalue + "%";                        
                        }
                        
                    Keys.onRightPressed: {
                        api.internal.recalbox.setIntParameter(parameterName,slidervalue);
                        value = slidervalue + "%";
                        }
                    
                    onFocusChanged: container.onFocus(this)
                    
                    KeyNavigation.up: optOutputAudio
//                    KeyNavigation.down: optVideoSettings
                    KeyNavigation.down: optStorageDevices
                }
//                SectionTitle {
//                    text: qsTr("Video Configuration") + api.tr
//                    first: true
//                }
//                MultivalueOption {
//                    id: optVideoSettings

//                    label: qsTr("Video Settings") + api.tr
//                    note: qsTr("set your display and resolution") + api.tr
//                    value: api.internal.settings.locales.currentName

//                    onActivate: {
//                        focus = true;
//                        localeBox.focus = true;
//                    }
//                    onFocusChanged: container.onFocus(this)
//                    KeyNavigation.up: optOutputVolume
//                    KeyNavigation.down: optNetworkSettings
//                }
//                SectionTitle {
//                    text: qsTr("Network") + api.tr
//                    first: true
//                }
//                MultivalueOption {
//                    id: optNetworkSettings

//                    label: qsTr("Network Settings") + api.tr
//                    note: qsTr("Settings network wifi or else") + api.tr
//                    value: api.internal.settings.locales.currentName

//                    onActivate: {
//                        focus = true;
//                        localeBox.focus = true;
//                    }
//                    onFocusChanged: container.onFocus(this)
//                    KeyNavigation.up: optVideoSettings
//                    KeyNavigation.down: optUpdateSettings
//                }
//                SectionTitle {
//                    text: qsTr("Update System") + api.tr
//                    first: true
//                }
//                MultivalueOption {
//                    id: optUpdateSettings

//                    label: qsTr("Update Settings") + api.tr
//                    note: qsTr("Update configuration menu") + api.tr
//                    value: api.internal.settings.locales.currentName

//                    onActivate: {
//                        focus = true;
//                        localeBox.focus = true;
//                    }
//                    onFocusChanged: container.onFocus(this)
//                    KeyNavigation.up: optNetworkSettings
//                    KeyNavigation.down: optStorageDevices
//                }
                SectionTitle {
                    text: qsTr("Storage Configuration") + api.tr
                    first: true
                }
                MultivalueOption {
                    id: optStorageDevices
                    //property to manage parameter name
                    property string parameterName : "boot.sharedevice"

                    label: qsTr("Storage device") + api.tr
                    note: qsTr("change to over storage") + api.tr
                    value: api.internal.recalbox.parameterslist.currentName(parameterName)
                    onActivate: {
                        //for callback by parameterslistBox
                        parameterslistBox.parameterName = parameterName;
                        parameterslistBox.callerid = optStorageDevices;
                        //to force update of list of parameters
                        api.internal.recalbox.parameterslist.currentName(parameterName);
                        parameterslistBox.model = api.internal.recalbox.parameterslist;
                        parameterslistBox.index = api.internal.recalbox.parameterslist.currentIndex;
                        //to transfer focus to parameterslistBox
                        parameterslistBox.focus = true;
                    }
                    onFocusChanged: container.onFocus(this)
                    KeyNavigation.up: optUpdateSettings
//                    KeyNavigation.down: optStorageCapacity
                    KeyNavigation.down: optLanguage
                }
//                SimpleButton {
//                    id: optStorageCapacity

//                    label: qsTr("Storage Capacity") + api.tr
//                    note: qsTr("Show Storage capacity") + api.tr
//                    onActivate: {
//                        focus = true;
//                        //                        localeBox.focus = true;
//                    }
//                    onFocusChanged: container.onFocus(this)
//                    KeyNavigation.up: optStorageDevices
//                    KeyNavigation.down: optLanguage
//                }
                SectionTitle {
                    text: qsTr("System Language") + api.tr
                    first: true
                }
                MultivalueOption {
                    id: optLanguage

                    label: qsTr("Language") + api.tr
                    note: qsTr("Set your language interface") + api.tr
                    value: api.internal.settings.locales.currentName

                    onActivate: {
                        focus = true;
                        localeBox.focus = true;
                    }
                    onFocusChanged: container.onFocus(this)
                    KeyNavigation.up: optStorageCapacity
                    KeyNavigation.down: optKbLayout
                }
                MultivalueOption {
                    id: optKbLayout

                    //property to manage parameter name
                    property string parameterName : "system.kblayout"

                    label: qsTr("Keyboard Layout") + api.tr
                    note: qsTr("Change keyboard layout language") + api.tr
                    value: api.internal.recalbox.parameterslist.currentName(parameterName)

                    onActivate: {
                        //for callback by parameterslistBox
                        parameterslistBox.parameterName = parameterName;
                        parameterslistBox.callerid = optKbLayout;
                        //to force update of list of parameters
                        api.internal.recalbox.parameterslist.currentName(parameterName);
                        parameterslistBox.model = api.internal.recalbox.parameterslist;
                        parameterslistBox.index = api.internal.recalbox.parameterslist.currentIndex;
                        //to transfer focus to parameterslistBox
                        parameterslistBox.focus = true;
                    }
                    onFocusChanged: container.onFocus(this);
                    KeyNavigation.up: optLanguage
                    KeyNavigation.down: optDebugMode
                }
                SectionTitle {
                    text: qsTr("System") + api.tr
                    first: true
                }
                ToggleOption {
                    id: optDebugMode

                    label: qsTr("Debug mode") + api.tr
                    note: qsTr("Give me your log baby !!! ;-)") + api.tr

                    checked: api.internal.recalbox.getBoolParameter("emulationstation.debuglogs")
                    onCheckedChanged: {
                        api.internal.recalbox.setBoolParameter("emulationstation.debuglogs",checked);
                    }
                    onFocusChanged: container.onFocus(this)
                    KeyNavigation.up: optKbLayout
                    KeyNavigation.down: optHideMouse
                }
                ToggleOption {
                    id: optHideMouse

                    label: qsTr("Enable mouse support") + api.tr
                    note: qsTr("By default the cursor is visible if there are any pointer devices connected.") + api.tr
                    
                    checked: api.internal.settings.mouseSupport
                    onCheckedChanged: {
                        api.internal.settings.mouseSupport = checked;
                    }
                    onFocusChanged: container.onFocus(this)
                    KeyNavigation.up: optDebugMode
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
