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
                    text: qsTr("Screensaver") + api.tr
                    first: true
                }
                SimpleButton {
                    id: optScreensaverSettings

                    // set focus only on firt item
                    focus: true

                    label: qsTr("Screensaver settings") + api.tr
                    note: qsTr("set screensaver on dim, demo mode, etc") + api.tr

                    onActivate: {
                        focus = true;
                        localeBox.focus = true;
                    }
                    onFocusChanged: container.onFocus(this)
                    KeyNavigation.up: optTheme
                    KeyNavigation.down: optScreenHelp
                }
                SectionTitle {
                    text: qsTr("Help Menu") + api.tr
                    first: true
                }
                ToggleOption {
                    id: optScreenHelp

                    label: qsTr("On Screen Help Menu") + api.tr
                    note: qsTr("Show Help navigation on bottom screen") + api.tr

                    //                    checked: api.internal.settings.fullscreen
                    onCheckedChanged: {
                        focus = true;
                        //                        api.internal.settings.fullscreen = checked;
                    }
                    onFocusChanged: container.onFocus(this)
                    KeyNavigation.down: optMenuControlsConfig
                }
                SectionTitle {
                    text: qsTr("Customize interface") + api.tr
                    first: true
                }
                SimpleButton {
                    id: optMenuControlsConfig

                    label: qsTr("Change menu controls") + api.tr
                    note: qsTr("change control assignation only in menu") + api.tr
                    onActivate: {
                        focus = true;
                        root.openKeySettings();
                    }
                    onFocusChanged: container.onFocus(this)
                    KeyNavigation.down: optPopupSettings
                }
                SimpleButton {
                    id: optPopupSettings

                    label: qsTr("Popup settings") + api.tr
                    note: qsTr("configure popup animation and more") + api.tr
                    onActivate: {
                        focus = true;
                        localeBox.focus = true;
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
                    KeyNavigation.down: optScreensaverSettings
                }
                Item {
                    width: parent.width
                    height: vpx(30)
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
