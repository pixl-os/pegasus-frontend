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
    signal openKeySettings

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
        text: qsTr("Interface") + api.tr
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

//                SectionTitle {
//                    text: qsTr("Screensaver") + api.tr
//                    first: true
//                }
//                SimpleButton {
//                    id: optScreensaverSettings

//                    // set focus only on firt item
//                    focus: true

//                    label: qsTr("Screensaver settings") + api.tr
//                    note: qsTr("set screensaver on dim, demo mode, etc") + api.tr

//                    onActivate: {
//                        focus = true;
//                        localeBox.focus = true;
//                    }
//                    onFocusChanged: container.onFocus(this)
//                    KeyNavigation.down: optScreenHelp
//                }
//                SectionTitle {
//                    text: qsTr("Help Menu") + api.tr
//                    first: true
//                }
//                ToggleOption {
//                    id: optScreenHelp

//                    label: qsTr("On Screen Help Menu") + api.tr
//                    note: qsTr("Show Help navigation on bottom screen") + api.tr

//                    onCheckedChanged: {
//                        //api.internal.settings.fullscreen = checked;
//                    }
//                    onFocusChanged: container.onFocus(this)
//                    KeyNavigation.up: optScreensaverSettings
//                    KeyNavigation.down: optMenuControlsConfig
//                }
                SectionTitle {
                    text: qsTr("Customize interface") + api.tr
                    first: true
                    symbol: "\uf132"
                }
                MultivalueOption {
                    id: optBackgroungColorConfig
                    //set focus only on firt item
                    focus: true

                    //property to manage parameter name
                    property string parameterName : "system.menu.color"

                    label: qsTr("choose background color interface") + api.tr
                    note: qsTr("Change background color only in interface") + api.tr
                    value: api.internal.recalbox.parameterslist.currentName(parameterName)

                    onActivate: {
                        //for callback by parameterslistBox
                        parameterslistBox.parameterName = parameterName;
                        parameterslistBox.callerid = optBackgroungColorConfig;
                        //to force update of list of parameters
                        api.internal.recalbox.parameterslist.currentName(parameterName);
                        parameterslistBox.model = api.internal.recalbox.parameterslist;
                        parameterslistBox.index = api.internal.recalbox.parameterslist.currentIndex;
                        //to transfer focus to parameterslistBox
                        parameterslistBox.focus = true;
                    }
                    onValueChanged: {
                        backgroundThemeColor = value
                    }
                    onFocusChanged: container.onFocus(this)
                    KeyNavigation.down: optTextColorConfig

                }
                MultivalueOption {
                    id: optTextColorConfig

                    //property to manage parameter name
                    property string parameterName : "system.text.color"

                    label: qsTr("choose text color interface") + api.tr
                    note: qsTr("Change text color only in interface") + api.tr
                    value: api.internal.recalbox.parameterslist.currentName(parameterName)

                    onActivate: {
                        //for callback by parameterslistBox
                        parameterslistBox.parameterName = parameterName;
                        parameterslistBox.callerid = optTextColorConfig;
                        //to force update of list of parameters
                        api.internal.recalbox.parameterslist.currentName(parameterName);
                        parameterslistBox.model = api.internal.recalbox.parameterslist;
                        parameterslistBox.index = api.internal.recalbox.parameterslist.currentIndex;
                        //to transfer focus to parameterslistBox
                        parameterslistBox.focus = true;
                    }
                    onValueChanged: {
                        textThemeColor = value
                    }
                    onFocusChanged: container.onFocus(this)
                    KeyNavigation.down: optSelectedColorConfig

                }
                MultivalueOption {
                    id: optSelectedColorConfig

                    //property to manage parameter name
                    property string parameterName : "system.selected.color"

                    label: qsTr("choose selected color interface") + api.tr
                    note: qsTr("Change selected color only in interface") + api.tr
                    value: api.internal.recalbox.parameterslist.currentName(parameterName)

                    onActivate: {
                        //for callback by parameterslistBox
                        parameterslistBox.parameterName = parameterName;
                        parameterslistBox.callerid = optSelectedColorConfig;
                        //to force update of list of parameters
                        api.internal.recalbox.parameterslist.currentName(parameterName);
                        parameterslistBox.model = api.internal.recalbox.parameterslist;
                        parameterslistBox.index = api.internal.recalbox.parameterslist.currentIndex;
                        //to transfer focus to parameterslistBox
                        parameterslistBox.focus = true;
                    }
                    onValueChanged: {
                        selectedThemeColor = value
                    }
                    onFocusChanged: container.onFocus(this)
                    KeyNavigation.down: optMenuControlsConfig

                }
                SimpleButton {
                    id: optMenuControlsConfig

                    label: qsTr("Change menu controls") + api.tr
                    note: qsTr("Change control assignation only in menu") + api.tr
                    //pointer moved in SimpleButton desactived on default
                    pointerIcon: true

                    onActivate: {
                        focus = true;
                        root.openKeySettings();
                    }
                    onFocusChanged: container.onFocus(this)
//                    KeyNavigation.up: optScreenHelp
//                    KeyNavigation.down: optPopupSettings
                    KeyNavigation.down: optMultiWindows

                }
//                SimpleButton {
//                    id: optPopupSettings

//                    label: qsTr("Popup settings") + api.tr
//                    note: qsTr("configure popup animation and more") + api.tr
//                    onActivate: {
//                        focus = true;
//                        localeBox.focus = true;
//                    }
//                    onFocusChanged: container.onFocus(this)
//                    KeyNavigation.up: optMenuControlsConfig
//                    KeyNavigation.down: optTheme
//                }
                ToggleOption {
                    id: optMultiWindows

                    label: qsTr("Multi-Windows") + api.tr
                    note: qsTr("Once enabled, you can run emulators in separate windows and keep pegasus/theme activated") + api.tr

                    checked: api.internal.recalbox.getBoolParameter("pegasus.multiwindows")
                    onCheckedChanged: {
                        api.internal.recalbox.setBoolParameter("pegasus.multiwindows",checked);
                    }
                    onFocusChanged: container.onFocus(this)
                    KeyNavigation.down: optTheme
                }
                MultivalueOption {
                    id: optTheme

                    label: qsTr("Theme") + api.tr
                    note: qsTr("Change theme system interface") + api.tr
                    value: api.internal.settings.themes.currentName

                    onActivate: {
                        focus = true;
                        themeBox.focus = true;
                    }
                    onFocusChanged: container.onFocus(this)
                    KeyNavigation.down: optThemeKeepLoaded
                }
                ToggleOption {
                    id: optThemeKeepLoaded

                    label: qsTr("Keep Theme Loaded") + api.tr
                    note: qsTr("Themes could stay loaded during gaming to avoid reloading after(Theme should be compatible)") + api.tr

                    checked: api.internal.recalbox.getBoolParameter("pegasus.theme.keeploaded")
                    onCheckedChanged: {
                        api.internal.recalbox.setBoolParameter("pegasus.theme.keeploaded",checked);
                    }
                    onFocusChanged: container.onFocus(this)
                    KeyNavigation.down: optGamelistsOnly
                }
                ToggleOption {
                    id: optGamelistsOnly

                    label: qsTr("Gamelist only") + api.tr
                    note: qsTr("Once enabled, only files from gamelist will be take into account. \n(Best game file loading ;-)") + api.tr

                    checked: api.internal.recalbox.getBoolParameter("emulationstation.gamelistonly")
                    onCheckedChanged: {
                        api.internal.recalbox.setBoolParameter("emulationstation.gamelistonly",checked);
                    }
                    onFocusChanged: container.onFocus(this)
                    KeyNavigation.down: optDeactivateSkraperMedia

                }
                ToggleOption {
                    id: optDeactivateSkraperMedia

                    label: qsTr("Deactivate Skraper media") + api.tr
                    note: qsTr("Once enabled, only media from gamelist will be take into account. \n ( Best loading ;-) / Less Media :-( )") + api.tr

                    checked: api.internal.recalbox.getBoolParameter("pegasus.deactivateskrapermedia")
                    onCheckedChanged: {
                        api.internal.recalbox.setBoolParameter("pegasus.deactivateskrapermedia",checked);
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
