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


import "mainmenu"
import "qrc:/qmlutils" as PegasusUtils
import QtQuick 2.12


FocusScope {
    id: root

    width: vpx(350)
    height: parent.height
    visible: x < parent.width && 0 < x + width
    enabled: focus
    onFocusChanged: {
        //console.log("MainMenuPanel onFocusChanged");
        //deactivate first the menu
        mbUpdates.enabled = false;
        if(api.internal.updates.hasAnyUpdate()){
            //search if any udpate is not install or installed with additional actions as restart/reboot/retry
            for(var i=0; i < componentsListModel.count ;i++){
                var item = componentsListModel.get(i);
                if(typeof(item.hasUpdate) !== "undefined"){
                    if(item.hasUpdate === true){
                        var installError = api.internal.updates.getInstallationError(item.componentName);
                        var installProgress = api.internal.updates.getInstallationProgress(item.componentName);
                        //check if installed or error detected
                        if((installProgress === 1.0) && (installError === 0)){
                            //installed without next action, we could remove flag of updates
                            componentsListModel.setProperty(i,"hasUpdate", false);
                        }
                        else{
                            mbUpdates.enabled = true;
                            break; //to exit from 'for'
                        }
                    }
                }
            }
        }
    }

    signal close
    signal showUpdates
    signal showAccountSettings
    signal showControllersSettings
    signal showGamesSettings
    signal showInterfaceSettings
    signal showSystemSettings
    //    signal showSettingsScreen
    //    signal showHelpScreen

    signal requestShutdown
    signal requestReboot
    signal requestRestart
    signal requestRebootForSettings
    signal requestRestartForSettings
    signal requestQuit

    Keys.onPressed: {
        if ((api.keys.isCancel(event) || api.keys.isMenu(event)) && !event.isAutoRepeat) {
            event.accepted = true;
            if(needReboot === true){
                requestRebootForSettings();
            }
            else if(needRestart === true){
                requestRestartForSettings();
            }
            //reset flags
            needReboot = false;
            needRestart = false;
            root.close();
        }
    }
    MouseArea {
        anchors.fill: parent
        acceptedButtons: Qt.RightButton
        onClicked: root.close()
    }
    Rectangle {
        color: themeColor.main
        anchors.fill: parent
    }
    Column {
        width: parent.width
        anchors.bottom: parent.bottom
        anchors.bottomMargin: vpx(30)

        PrimaryMenuItem {
            id: mbUpdates
            text: qsTr("Updates") + api.tr
            onActivated: {
                focus = true;
                root.showUpdates();
            }
            selected: focus

            enabled: false
            visible: enabled
            symbol:"\uf2c6"
            animated: true
            KeyNavigation.down: mbAccountSettings
        }
        PrimaryMenuItem {
            id: mbAccountSettings
            text: qsTr("Accounts") + api.tr
            onActivated: {
                focus = true;
                root.showAccountSettings();
            }
            selected: focus

            enabled: api.internal.meta.allowSettings
            visible: enabled
            symbol:"\uf41a"
            KeyNavigation.up: mbUpdates.enabled ? mbUpdates : scopeQuit
            KeyNavigation.down: mbControllersSettings
        }
        PrimaryMenuItem {
            id: mbControllersSettings
            text: qsTr("Controllers") + api.tr
            onActivated: {
                focus = true;
                root.showControllersSettings();
            }
            selected: focus

            enabled: api.internal.meta.allowSettings
            visible: enabled
            symbol:"\uf181"
            KeyNavigation.down: mbInterfaceSettings
        }
        PrimaryMenuItem {
            id: mbInterfaceSettings
            text: qsTr("Interface") + api.tr
            onActivated: {
                focus = true;
                root.showInterfaceSettings();
            }
            selected: focus

            enabled: api.internal.meta.allowSettings
            visible: enabled
            symbol:"\uf17f"
            KeyNavigation.down: mbGamesSettings
        }
        PrimaryMenuItem {
            id: mbGamesSettings
            text: qsTr("Games") + api.tr
            onActivated: {
                focus = true;
                root.showGamesSettings();
            }
            selected: focus

            enabled: api.internal.meta.allowSettings
            visible: enabled
            symbol:"\uf221"
            KeyNavigation.down: mbSystemSettings
        }
        PrimaryMenuItem {
            id: mbSystemSettings
            text: qsTr("Settings") + api.tr
            onActivated: {
                focus = true;
                // tmp file generate on Xinit start
                //api.internal.system.run("glxinfo -B > /tmp/glxinfo.txt");
                root.showSystemSettings();
            }
            selected: focus

            enabled: api.internal.meta.allowSettings
            visible: enabled
            symbol:"\uf412"
            KeyNavigation.down: scopeQuit
        }
        RollableMenuItem {
            id: scopeQuit
            name: qsTr("Quit") + api.tr

            enabled: callable
            visible: callable
            readonly property bool callable: mbQuitShutdown.callable
                                             || mbQuitReboot.callable
                                             || mbQuitExit.callable

            Component.onCompleted: {
                const first_callable = [mbQuitShutdown, mbQuitReboot,mbQuitExit].find(e => e.callable);
                if (first_callable) {
                    first_callable.focus = true;
                    scopeQuit.focus = true;
                } else {
                    mbHelp.focus = true;
                }
            }
            entries: [
                SecondaryMenuItem {
                    id: mbQuitRestart
                    text: qsTr("Restart") + api.tr
                    onActivated: requestRestart()

                    readonly property bool callable: api.internal.meta.allowRestart
                    enabled: callable
                    visible: callable

                    KeyNavigation.down: mbQuitShutdown
                },
                SecondaryMenuItem {
                    id: mbQuitShutdown
                    text: qsTr("Shutdown") + api.tr
                    onActivated: requestShutdown()

                    readonly property bool callable: api.internal.meta.allowShutdown
                    enabled: callable
                    visible: callable

                    KeyNavigation.down: mbQuitReboot
                },
                SecondaryMenuItem {
                    id: mbQuitReboot
                    text: qsTr("Reboot") + api.tr
                    onActivated: requestReboot()

                    readonly property bool callable: api.internal.meta.allowReboot
                    enabled: callable
                    visible: callable

                    KeyNavigation.down: mbQuitExit
                },
                SecondaryMenuItem {
                    id: mbQuitExit
                    text: qsTr("Exit Pegasus") + api.tr
                    onActivated: requestQuit()

                    readonly property bool callable: api.internal.meta.allowAppClose
                    enabled: callable
                    visible: callable

                    KeyNavigation.down: mbQuitShutdown
                }
            ]
            KeyNavigation.down: mbUpdates.enabled ? mbUpdates : mbAccountSettings
        }
    }
    PegasusUtils.HorizontalSwipeArea {
        anchors.fill: parent
        onSwipeRight: close()
    }
}
