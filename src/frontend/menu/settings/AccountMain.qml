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
    signal openNetplayRooms
    signal openGameDirSettings
    //signal openMenuBoxSettings

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
        text: qsTr("Accounts") + api.tr
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

        boundsBehavior: api.internal.settings.virtualKeyboardSupport ? Flickable.DragAndOvershootBounds : Flickable.StopAtBounds
        boundsMovement: api.internal.settings.virtualKeyboardSupport ? Flickable.DragAndOvershootBounds : Flickable.StopAtBounds

        readonly property int yBreakpoint: height * 0.7
        readonly property int maxContentY: contentHeight - height

        function onFocus(item) {
            if (item.focus && !(Qt.inputMethod.visible && api.internal.settings.virtualKeyboardSupport))
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
                    id: optRetroachievementActivate
                    // set focus only on first item
                    focus: true
                    SectionTitle {
                        text: qsTr("Retroachievement") + api.tr
                        first: true
                        symbol: "\uf39b"
                    }
                    // label: qsTr("Activate retroachievement") + api.tr
                    // note: qsTr("Achievements to your favourites retro games.") + api.tr

                    checked: api.internal.recalbox.getBoolParameter("global.retroachievements")
                    onCheckedChanged: api.internal.recalbox.setBoolParameter("global.retroachievements",checked);
                    onFocusChanged: container.onFocus(this)
                    KeyNavigation.down: optRetroachievementUsername
                }
                SimpleButton {
                    id: optRetroachievementUsername

                    label: qsTr("Username") + api.tr
                    note: qsTr("If you don't have an account go to the site :\n https://retroachievements.org/") + api.tr

                    TextFieldOption {
                        id: retroachievementUsername
                        anchors.right: parent.right
                        anchors.verticalCenter: parent.verticalCenter
                        horizontalAlignment: TextInput.AlignRight
                        placeholderText: qsTr("Pseudo") + api.tr
                        text: api.internal.recalbox.getStringParameter("global.retroachievements.username")
                        echoMode: TextInput.Normal
                        inputMethodHints: Qt.ImhNoPredictiveText
                        onEditingFinished: api.internal.recalbox.setStringParameter("global.retroachievements.username", retroachievementUsername.text)
                    }
                    onFocusChanged: container.onFocus(this)
                    KeyNavigation.down: optRetroachievementPassword
                    visible: optRetroachievementActivate.checked
                }
                SimpleButton {
                    id: optRetroachievementPassword

                    label: qsTr("Password") + api.tr
                    note: qsTr("then login with your username and password") + api.tr

                    TextFieldOption {
                        id: retroachievementPassword
                        anchors.right: parent.right
                        anchors.verticalCenter: parent.verticalCenter
                        placeholderText: qsTr("Password") + api.tr
                        text: api.internal.recalbox.getStringParameter("global.retroachievements.password")
                        horizontalAlignment: TextInput.AlignRight
                        echoMode: TextInput.PasswordEchoOnEdit
                        inputMethodHints: Qt.ImhNoAutoUppercase | Qt.ImhPreferLowercase | Qt.ImhSensitiveData | Qt.ImhNoPredictiveText
                        onEditingFinished: api.internal.recalbox.setStringParameter("global.retroachievements.password", retroachievementPassword.text)
                    }
                    onFocusChanged: container.onFocus(this)
                    KeyNavigation.down: optHardcoreRetroachievementActivate
                    visible: optRetroachievementActivate.checked
                }
                ToggleOption {
                    id: optHardcoreRetroachievementActivate

                    label: qsTr("Hardcore retroachievement") + api.tr
                    note: qsTr("Unlock trophies without cheats and rewind. \nOnly work with Retroarch cores.") + api.tr

                    checked: api.internal.recalbox.getBoolParameter("global.retroachievements.hardcore")
                    onCheckedChanged: api.internal.recalbox.setBoolParameter("global.retroachievements.hardcore",checked);
                    onFocusChanged: container.onFocus(this)
                    KeyNavigation.down: optScreenshootsAchievementActivate
                    visible: optRetroachievementActivate.checked
                }
                ToggleOption {
                    id: optScreenshootsAchievementActivate
                    label: qsTr("Auto screenshot") + api.tr
                    note: qsTr("Take an screenshot when an achievement is triggere.") + api.tr

                    checked: api.internal.recalbox.getBoolParameter("global.retroachievements.screenshot")
                    onCheckedChanged: api.internal.recalbox.setBoolParameter("global.retroachievements.screenshot",checked);
                    onFocusChanged: container.onFocus(this)
                    KeyNavigation.down: optUnlockSoundsAchievementActivate
                    visible: optRetroachievementActivate.checked
                }
                ToggleOption {
                    id: optUnlockSoundsAchievementActivate
                    label: qsTr("Activate unlock sounds") + api.tr
                    note: qsTr("Play Sounds if you unlock a trophies.") + api.tr

                    checked: api.internal.recalbox.getBoolParameter("global.retroachievements.unlock.sound")
                    onCheckedChanged: api.internal.recalbox.setBoolParameter("global.retroachievements.unlock.sound",checked);
                    onFocusChanged: container.onFocus(this)
                    KeyNavigation.down: optChallengeIndicators
                    visible: optRetroachievementActivate.checked
                }
                ToggleOption {
                    id: optChallengeIndicators
                    label: qsTr("Challenge indicators") + api.tr
                    note: qsTr("Allow achievements to display an on-screen indicator while the achievement can be earned.") + api.tr

                    checked: api.internal.recalbox.getBoolParameter("global.retroachievements.challenge.indicators")
                    onCheckedChanged: api.internal.recalbox.setBoolParameter("global.retroachievements.challenge.indicators",checked);
                    onFocusChanged: container.onFocus(this)
                    KeyNavigation.down: optLeaderboardIndicators
                    visible: optRetroachievementActivate.checked
                }
                MultivalueOption {
                    id: optLeaderboardIndicators
                    //property to manage parameter name
                    property string parameterName : "global.retroachievements.leaderboard.indicators"

                    label: qsTr("Leaderboard indicators") + api.tr
                    note: qsTr("Shows a message when a leaderboard activates..") + api.tr

                    value: api.internal.recalbox.parameterslist.currentName(parameterName)

                    currentIndex: api.internal.recalbox.parameterslist.currentIndex;
                    count: api.internal.recalbox.parameterslist.count;

                    onActivate: {
                        //for callback by parameterslistBox
                        parameterslistBox.parameterName = parameterName;
                        parameterslistBox.callerid = optLeaderboardIndicators;
                        //to force update of list of parameters
                        api.internal.recalbox.parameterslist.currentName(parameterName);
                        parameterslistBox.model = api.internal.recalbox.parameterslist;
                        parameterslistBox.index = api.internal.recalbox.parameterslist.currentIndex;
                        //to transfer focus to parameterslistBox
                        parameterslistBox.focus = true;
                    }
                    onSelect: {
                        //to force to be on the good parameter selected
                        api.internal.recalbox.parameterslist.currentName(parameterName);
                        //to update index of parameterlist QAbstractList
                        api.internal.recalbox.parameterslist.currentIndex = index;
                        //to force update of display of selected value
                        value = api.internal.recalbox.parameterslist.currentName(parameterName);
                    }

                    onFocusChanged:{
                        if(focus){
                            api.internal.recalbox.parameterslist.currentName(parameterName);
                            currentIndex = api.internal.recalbox.parameterslist.currentIndex;
                            count = api.internal.recalbox.parameterslist.count;
                        }
                        container.onFocus(this)
                    }

                    KeyNavigation.down: optRAIconsInLists
                    visible: optRetroachievementActivate.checked
                }
                ToggleOption {
                    id: optRAIconsInLists
                    label: qsTr("Retroachievement Games search (Beta)") + api.tr
                    note: qsTr("Check and identify games with retroachievents.\nUsing md5 hash calculation during list loading (could be slow during first scrollings)") + api.tr

                    checked: api.internal.recalbox.getBoolParameter("global.retroachievements.games.search")
                    onCheckedChanged: api.internal.recalbox.setBoolParameter("global.retroachievements.games.search",checked);
                    onFocusChanged: container.onFocus(this)
                    KeyNavigation.down: optNetplayActivate
                    visible: optRetroachievementActivate.checked
                }
                ToggleOption {
                    id: optNetplayActivate
                    SectionTitle {
                        text: qsTr("Netplay") + api.tr
                        first: true
                        symbol: "\uf343"
                    }
                    // label: qsTr("Activate netplay") + api.tr
                    // note: qsTr("Play with your friends online") + api.tr

                    checked: api.internal.recalbox.getBoolParameter("global.netplay")
                    onCheckedChanged: api.internal.recalbox.setBoolParameter("global.netplay",checked);
                    onFocusChanged: container.onFocus(this)
                    KeyNavigation.down: optNetplayNickname
                }
                SimpleButton {
                    id: optNetplayNickname

                    label: qsTr("Netplay nickname") + api.tr
                    note: qsTr("Set your netplay nickname") + api.tr

                    TextFieldOption {
                        id: netplayNickname
                        anchors.right: parent.right
                        anchors.verticalCenter: parent.verticalCenter
                        horizontalAlignment: TextInput.AlignRight
                        placeholderText: qsTr("Nickname") + api.tr
                        text: api.internal.recalbox.getStringParameter("global.netplay.nickname")
                        echoMode: TextInput.Normal
                        inputMethodHints: Qt.ImhNoPredictiveText
                        onEditingFinished: api.internal.recalbox.setStringParameter("global.netplay.nickname", netplayNickname.text)
                    }

                    onFocusChanged: container.onFocus(this)
                    KeyNavigation.down: optNetplayRooms
                    visible: optNetplayActivate.checked
                }
                SimpleButton {
                    id: optNetplayRooms

                    label: qsTr("Netplay rooms") + api.tr
                    note: qsTr("Play online on many systems.\n (current games online, Friends, etc...)") + api.tr
                    //pointer moved in SimpleButton desactived on default
                    pointerIcon: true

                    onActivate: {
                        focus = true;
                        root.openNetplayRooms();
                    }
                    onFocusChanged: container.onFocus(this)
                    KeyNavigation.down: optNetplayPswdClientActivate
                    visible: optNetplayActivate.checked
                }
                SectionTitle {
                    text: qsTr("Password netplay") + api.tr
                    first: true
                    visible: optNetplayActivate.checked
                    symbol: "\uf071"
                    symbolFontFamily: global.fonts.awesome //global.fonts.ion is used by default
                }
                ToggleOption {
                    id: optNetplayPswdClientActivate

                    label: qsTr("Activate password netplay players") + api.tr
                    note: qsTr("Set password for other players join your game") + api.tr

                    checked: api.internal.recalbox.getBoolParameter("netplay.password.useforplayer")
                    onCheckedChanged: api.internal.recalbox.setBoolParameter("netplay.password.useforplayer",checked);
                    onFocusChanged: container.onFocus(this)
                    KeyNavigation.down: optNetplayPswdClient
                    visible: optNetplayActivate.checked
                }
                MultivalueOption {
                    id: optNetplayPswdClient

                    //property to manage parameter name
                    property string parameterName : "netplay.password.client"

                    label: qsTr("Password netplay players") + api.tr
                    note: qsTr("Choose password for join session") + api.tr

                    value: api.internal.recalbox.parameterslist.currentName(parameterName)

                    currentIndex: api.internal.recalbox.parameterslist.currentIndex;
                    count: api.internal.recalbox.parameterslist.count;

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

                    onSelect: {
                        //to force to be on the good parameter selected
                        api.internal.recalbox.parameterslist.currentName(parameterName);
                        //to update index of parameterlist QAbstractList
                        api.internal.recalbox.parameterslist.currentIndex = index;
                        //to force update of display of selected value
                        value = api.internal.recalbox.parameterslist.currentName(parameterName);
                    }

                    onFocusChanged:{
                        if(focus){
                            api.internal.recalbox.parameterslist.currentName(parameterName);
                            currentIndex = api.internal.recalbox.parameterslist.currentIndex;
                            count = api.internal.recalbox.parameterslist.count;
                        }
                        container.onFocus(this)
                    }

                    KeyNavigation.down: optNetplayPswdViewerActivate
                    visible: optNetplayPswdClientActivate.checked && optNetplayActivate.checked
                }
                ToggleOption {
                    id: optNetplayPswdViewerActivate

                    label: qsTr("Activate password for netplay spectator") + api.tr
                    note: qsTr("Set password for netplay spectator") + api.tr

                    checked: api.internal.recalbox.getBoolParameter("netplay.password.useforviewer")
                    onCheckedChanged: api.internal.recalbox.setBoolParameter("netplay.password.useforviewer",checked);
                    onFocusChanged: container.onFocus(this)
                    KeyNavigation.down: optNetplayPswdViewer
                    visible: optNetplayActivate.checked
                }
                MultivalueOption {
                    id: optNetplayPswdViewer

                    //property to manage parameter name
                    property string parameterName : "netplay.password.viewer"

                    label: qsTr("Password netplay spectator") + api.tr
                    note: qsTr("Choose password for netplay spectator") + api.tr

                    value: api.internal.recalbox.parameterslist.currentName(parameterName)

                    currentIndex: api.internal.recalbox.parameterslist.currentIndex;
                    count: api.internal.recalbox.parameterslist.count;

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

                    onSelect: {
                        //to force to be on the good parameter selected
                        api.internal.recalbox.parameterslist.currentName(parameterName);
                        //to update index of parameterlist QAbstractList
                        api.internal.recalbox.parameterslist.currentIndex = index;
                        //to force update of display of selected value
                        value = api.internal.recalbox.parameterslist.currentName(parameterName);
                    }

                    onFocusChanged:{
                        if(focus){
                            api.internal.recalbox.parameterslist.currentName(parameterName);
                            currentIndex = api.internal.recalbox.parameterslist.currentIndex;
                            count = api.internal.recalbox.parameterslist.count;
                        }
                        container.onFocus(this)
                    }

                    visible: optNetplayPswdViewerActivate.checked && optNetplayActivate.checked
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
            callerid.keypressed = true;
            //to use the good parameter
            api.internal.recalbox.parameterslist.currentName(callerid.parameterName);
            //to update index of parameterlist QAbstractList
            api.internal.recalbox.parameterslist.currentIndex = index;
            //to force update of display of selected value
            callerid.value = api.internal.recalbox.parameterslist.currentName(callerid.parameterName);
            callerid.currentIndex = api.internal.recalbox.parameterslist.currentIndex;
            callerid.count = api.internal.recalbox.parameterslist.count;
        }
    }
}
