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
    signal openNetplayInformation
    signal openGameDirSettings
    signal openMenuBoxSettings

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
        text: qsTr("Account") + api.tr
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
                    text: qsTr("Retroachievement") + api.tr
                    first: true
                }
                ToggleOption {
                    id: optRetroachievementActivate
                    // set focus only on first item
                    focus: true

                    label: qsTr("Activate Retroachievement") + api.tr
                    note: qsTr("Unlock Trophées") + api.tr

                    checked: api.internal.recalbox.getBoolParameter("global.retroachievements")
                    onCheckedChanged: {
                        focus = true;
                        api.internal.recalbox.setBoolParameter("global.retroachievements",checked);
                    }
                    onFocusChanged: container.onFocus(this)
                    KeyNavigation.up: optNetplayPswdViewer
                    KeyNavigation.down: optRetroachievementLoginIn
                }
                SimpleButton {
                    id: optRetroachievementLoginIn

                    label: qsTr("Connect Retroachievement") + api.tr
                    note: qsTr("Connect your account retroachievement") + api.tr
                    onActivate: {
                        focus = true;
                        root.openMenuBoxSettings();
                    }
                    onFocusChanged: container.onFocus(this)
                    KeyNavigation.down: optHardcoreRetroachievementActivate
                }
                ToggleOption {
                    id: optHardcoreRetroachievementActivate

                    label: qsTr("Hardcore Retroachievement") + api.tr
                    note: qsTr("Unlock Trophées without cheats and rewind") + api.tr

                    checked: api.internal.recalbox.getBoolParameter("global.retroachievements.hardcore")
                    onCheckedChanged: {
                        focus = true;
                        api.internal.recalbox.setBoolParameter("global.retroachievements.hardcore",checked);
                    }
                    onFocusChanged: container.onFocus(this)
                    KeyNavigation.down: optNetplayInformation
                }
                SectionTitle {
                    text: qsTr("Netplay") + api.tr
                    first: true
                }
                SimpleButton {
                    id: optNetplayInformation

                    label: qsTr("Netplay Information") + api.tr
                    note: qsTr("Show netplay information roms etc ...") + api.tr
                    //                    value: api.internal.settings.locales.currentName

                    onActivate: {
                        focus = true;
                        root.openNetplayInformation();
                    }
                    onFocusChanged: container.onFocus(this)
                    KeyNavigation.down: optNetplayActivate
                }
                ToggleOption {
                    id: optNetplayActivate

                    label: qsTr("Activate Netplay") + api.tr
                    note: qsTr("Play with your friends online") + api.tr

                    checked: api.internal.recalbox.getBoolParameter("global.netplay")
                    onCheckedChanged: {
                        focus = true;
                        api.internal.recalbox.setBoolParameter("global.netplay.active",checked);
                        //                        pop menu if activate
                        //                        root.openGameDirSettings();
                    }
                    onFocusChanged: container.onFocus(this)
                    KeyNavigation.down: optNetplayNickname
                }
                MultivalueOption {
                    id: optNetplayNickname

                    label: qsTr("Netplay Nickname") + api.tr
                    note: qsTr("Set your Netplay nickname") + api.tr

                    //                    value: api.internal.settings.locales.currentName

                    onActivate: {
                        focus = true;
                        root.openMenuBoxSettings();
                    }
                    onFocusChanged: container.onFocus(this)
                    KeyNavigation.down: optNetplayPswdClientActivate
                }
                SectionTitle {
                    text: qsTr("Password Netplay") + api.tr
                    first: true
                }
                ToggleOption {
                    id: optNetplayPswdClientActivate

                    label: qsTr("Activate password Netplay players") + api.tr
                    note: qsTr("Set password for other players join your game") + api.tr

                    checked: api.internal.recalbox.getBoolParameter("netplay.password.useforplayer")
                    onCheckedChanged: {
                        focus = true;
                        api.internal.recalbox.setBoolParameter("netplay.password.useforplayer",checked);
                        //                        pop menu if activate
                        //                        root.openGameDirSettings();
                    }
                    onFocusChanged: container.onFocus(this)
                    KeyNavigation.down: optNetplayPswdClient
                }
                MultivalueOption {
                    id: optNetplayPswdClient
                    //property to manage parameter name
                    property string parameterName : "netplay.password.client"

                    label: qsTr("Password Netplay players") + api.tr
                    note: qsTr("Choose password for players session") + api.tr
                    value: api.internal.recalbox.parameterslist.currentName(parameterName)
                    onActivate: {
                        //for callback by parameterslistBox
                        parameterslistBox.parameterName = parameterName;
                        parameterslistBox.callerid = optNetplayPswdClient;
                        //to force update of list of parameters
                        api.internal.recalbox.parameterslist.currentName(parameterName);
                        parameterslistBox.model = api.internal.recalbox.parameterslist;
                        parameterslistBox.index = api.internal.recalbox.parameterslist.currentIndex;
                        //to transfer focus to parameterslistBox
                        parameterslistBox.focus = true;
                    }
                    onFocusChanged: container.onFocus(this)
                    KeyNavigation.down: optNetplayPswdViewerActivate
                }
                ToggleOption {
                    id: optNetplayPswdViewerActivate

                    label: qsTr("Activate password for Netplay viewer") + api.tr
                    note: qsTr("Set password for viewer ") + api.tr

                    checked: api.internal.recalbox.getBoolParameter("netplay.password.useforviewer")
                    onCheckedChanged: {
                        focus = true;
                        api.internal.recalbox.setBoolParameter("netplay.password.useforviewer",checked);
                        //                        pop menu if activate
                        //                        root.openGameDirSettings();
                    }
                    onFocusChanged: container.onFocus(this)
                    KeyNavigation.down: optNetplayPswdViewer
                }
                MultivalueOption {
                    id: optNetplayPswdViewer
                    //property to manage parameter name
                    property string parameterName : "netplay.password.viewer"

                    label: qsTr("Password Netplay Spectator") + api.tr
                    note: qsTr("Set password for netplay spectator") + api.tr
                    value: api.internal.recalbox.parameterslist.currentName(parameterName)
                    onActivate: {
                        //for callback by parameterslistBox
                        parameterslistBox.parameterName = parameterName;
                        parameterslistBox.callerid = optNetplayPswdViewer
                        //to force update of list of parameters
                        api.internal.recalbox.parameterslist.currentName(parameterName);
                        parameterslistBox.model = api.internal.recalbox.parameterslist;
                        parameterslistBox.index = api.internal.recalbox.parameterslist.currentIndex;
                        //to transfer focus to parameterslistBox
                        parameterslistBox.focus = true;
                    }
                    onFocusChanged: container.onFocus(this)
                    KeyNavigation.down: optRetroachievementActivate
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
