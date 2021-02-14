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
            api.internal.recalbox.saveParameters();
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
        text: qsTr("Settings") + api.trs
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

        readonly property int yBreakpoint: height * 0.5
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
                    text: qsTr("System") + api.tr
                    first: true
                }
               
                MultivalueOption {
                    id: optKbLayout
                    
                    //property to manage parameter name
                    property string parameterName : "system.kblayout"
                    
                    focus: true

                    label: qsTr("Keyboard Layout") + api.tr 
                    
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
                    onFocusChanged: {
                        container.onFocus(this);
                    }

                    KeyNavigation.down: optGlobalRatio
                    
                }

                MultivalueOption {
                    id: optGlobalRatio
                    
                    //property to manage parameter name
                    property string parameterName : "global.ratio"
                    
                    focus: true

                    label: qsTr("Ratio") + api.tr 
                    
                    value: api.internal.recalbox.parameterslist.currentName(parameterName)
                    
                    onActivate: {
                        //for callback by parameterslistBox
                        parameterslistBox.parameterName = parameterName;
                        parameterslistBox.callerid = optGlobalRatio;
                        //to force update of list of parameters
                        api.internal.recalbox.parameterslist.currentName(parameterName);
                        parameterslistBox.model = api.internal.recalbox.parameterslist;
                        parameterslistBox.index = api.internal.recalbox.parameterslist.currentIndex;
                        //to transfer focus to parameterslistBox
                        parameterslistBox.focus = true;
                    }
                    onFocusChanged: {
                        container.onFocus(this);
                    }

                    KeyNavigation.down: optDebugMode
                }   
               
                ToggleOption {
                    id: optDebugMode

                    label: qsTr("Debug mode") + api.tr
                    note: qsTr("Give me your log baby !!! ;-)") + api.tr

                    checked: api.internal.recalbox.getBoolParameter("emulationstation.debuglogs")
                    onCheckedChanged: {
                        focus = true;
                        api.internal.recalbox.setBoolParameter("emulationstation.debuglogs",checked);
                    }
                    onFocusChanged: container.onFocus(this)

                    KeyNavigation.down: optVideoMode
                }
                
                MultivalueOption {
                    id: optVideoMode

                    focus: true

                    label: qsTr("video mode") + api.tr
                    value: api.internal.recalbox.getStringParameter("global.videomode")

                    onActivate: {
                        focus = true;
                    }
                    onFocusChanged: container.onFocus(this)

                    KeyNavigation.down: optLanguage
                }

                MultivalueOption {
                    id: optSoundSettings

                    focus: true

                    label: qsTr("Sound Settings") + api.tr
                    value: api.internal.settings.locales.currentName

                    onActivate: {
                        focus = true;
                        localeBox.focus = true;
                    }
                    onFocusChanged: container.onFocus(this)

                    KeyNavigation.down: optVideoSettings
                    KeyNavigation.up: optKeyboardLanguage
                }

                MultivalueOption {
                    id: optVideoSettings

                    focus: true

                    label: qsTr("Video Settings") + api.tr
                    value: api.internal.settings.locales.currentName

                    onActivate: {
                        focus = true;
                        localeBox.focus = true;
                    }
                    onFocusChanged: container.onFocus(this)

                    KeyNavigation.down: optNetworkSettings
                }

                MultivalueOption {
                    id: optNetworkSettings

                    focus: true

                    label: qsTr("Network Settings") + api.tr
                    value: api.internal.settings.locales.currentName

                    onActivate: {
                        focus = true;
                        localeBox.focus = true;
                    }
                    onFocusChanged: container.onFocus(this)

                    KeyNavigation.down: optUpdateSettings
                }

                MultivalueOption {
                    id: optUpdateSettings

                    focus: true

                    label: qsTr("Update Settings") + api.tr
                    value: api.internal.settings.locales.currentName

                    onActivate: {
                        focus = true;
                        localeBox.focus = true;
                    }
                    onFocusChanged: container.onFocus(this)

                    KeyNavigation.down: optStorageSettings
                }

                MultivalueOption {
                    id: optStorageSettings

                    focus: true

                    label: qsTr("Storage Settings") + api.tr
                    value: api.internal.settings.locales.currentName

                    onActivate: {
                        focus = true;
                        localeBox.focus = true;
                    }
                    onFocusChanged: container.onFocus(this)

                    KeyNavigation.down: optLanguage
                }

                SectionTitle {
                    text: qsTr("System Language") + api.tr
                    first: true
                }

                MultivalueOption {
                    id: optLanguage

                    focus: true

                    label: qsTr("Language") + api.tr
                    value: api.internal.settings.locales.currentName

                    onActivate: {
                        focus = true;
                        localeBox.focus = true;
                    }
                    onFocusChanged: container.onFocus(this)

                    KeyNavigation.down: optKeyboardLanguage
                }

                MultivalueOption {
                    id: optKeyboardLanguage

                    focus: true

                    label: qsTr("Keyboard Language") + api.tr
                    value: api.internal.settings.locales.currentName

                    onActivate: {
                        focus = true;
                        localeBox.focus = true;
                    }
                    onFocusChanged: container.onFocus(this)

                    KeyNavigation.down: optSoundSettings
                }

//                ToggleOption {
//                    id: optFullscreen

//                    label: qsTr("Fullscreen mode") + api.tr
//                    note: qsTr("On some platforms this setting may have no effect.") + api.tr

//                    checked: api.internal.settings.fullscreen
//                    onCheckedChanged: {
//                        focus = true;
//                        api.internal.settings.fullscreen = checked;
//                    }
//                    onFocusChanged: container.onFocus(this)

//                    KeyNavigation.down: optKeyboardConfig
//                }

//                SectionTitle {
//                    text: qsTr("Controls") + api.tr
//                }

//                SimpleButton {
//                    id: optKeyboardConfig

//                    label: qsTr("Change controls...") + api.tr
//                    onActivate: {
//                        focus = true;
//                        root.openKeySettings();
//                    }
//                    onFocusChanged: container.onFocus(this)

//                    KeyNavigation.down: optGamepadConfig
//                }

//                SimpleButton {
//                    id: optGamepadConfig

//                    label: qsTr("Change gamepad layout...") + api.tr
//                    onActivate: {
//                        focus = true;
//                        root.openGamepadSettings();
//                    }
//                    onFocusChanged: container.onFocus(this)

//                    KeyNavigation.down: optHideMouse
//                }

//                ToggleOption {
//                    id: optHideMouse

//                    label: qsTr("Enable mouse support") + api.tr
//                    note: qsTr("By default the cursor is visible if there are any pointer devices connected.") + api.tr

//                    checked: api.internal.settings.mouseSupport
//                    onCheckedChanged: {
//                        focus = true;
//                        api.internal.settings.mouseSupport = checked;
//                    }
//                    onFocusChanged: container.onFocus(this)

//                    KeyNavigation.down: optEditGameDirs
//                }

//                SectionTitle {
//                    text: qsTr("Gaming") + api.tr
//                }
//                SimpleButton {
//                    id: optEditGameDirs

//                    label: qsTr("Set game directories...") + api.tr
//                    onActivate: {
//                        focus = true;
//                        root.openGameDirSettings();
//                    }
//                    onFocusChanged: container.onFocus(this)

//                    KeyNavigation.down: optEditProviders
//                }
//                SimpleButton {
//                    id: optEditProviders

//                    label: qsTr("Enable/disable data sources...") + api.tr
//                    onActivate: {
//                        focus = true;
//                        root.openProviderSettings();
//                    }
//                    onFocusChanged: container.onFocus(this)
//                }

                Item {
                    width: parent.width
                    height: vpx(25)
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
