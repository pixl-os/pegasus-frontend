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

                    currentIndex: api.internal.recalbox.parameterslist.currentIndex;
                    count: api.internal.recalbox.parameterslist.count;

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
                        backgroundThemeColor = api.internal.recalbox.getStringParameter(parameterName);
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

                    KeyNavigation.down: optTextColorConfig

                }
                MultivalueOption {
                    id: optTextColorConfig

                    //property to manage parameter name
                    property string parameterName : "system.text.color"

                    label: qsTr("choose text color interface") + api.tr
                    note: qsTr("Change text color only in interface") + api.tr

                    value: api.internal.recalbox.parameterslist.currentName(parameterName)

                    currentIndex: api.internal.recalbox.parameterslist.currentIndex;
                    count: api.internal.recalbox.parameterslist.count;

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
                        textThemeColor = api.internal.recalbox.getStringParameter(parameterName);
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

                    KeyNavigation.down: optSelectedColorConfig

                }
                MultivalueOption {
                    id: optSelectedColorConfig

                    //property to manage parameter name
                    property string parameterName : "system.selected.color"

                    label: qsTr("choose selected color interface") + api.tr
                    note: qsTr("Change selected color only in interface") + api.tr

                    value: api.internal.recalbox.parameterslist.currentName(parameterName)

                    currentIndex: api.internal.recalbox.parameterslist.currentIndex;
                    count: api.internal.recalbox.parameterslist.count;

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
                            selectedThemeColor = api.internal.recalbox.getStringParameter(parameterName);
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
                    KeyNavigation.down: optTheme
                }
                SectionTitle {
                    text: qsTr("Theme management") + api.tr
                    first: true
                    symbol: "\uf17f"
                }
                MultivalueOption {
                    id: optTheme

                    label: qsTr("Theme") + api.tr
                    note: qsTr("Change theme system interface") + api.tr

                    value: api.internal.settings.themes.currentName

                    currentIndex: api.internal.settings.themes.currentIndex;
                    count: api.internal.settings.themes.count

                    onActivate: {
                        //for callback by themeBox
                        themeBox.callerid = optTheme;
                        //to force update of list of parameters
                        themeBox.model = api.internal.settings.themes;
                        themeBox.index = api.internal.settings.themes.currentIndex;
                        //to transfer focus to themeBox
                        themeBox.focus = true;
                    }

                    onSelect: {
                        //to update index
                        api.internal.settings.themes.currentIndex = index;
                        //to force update of display of selected value
                        value = api.internal.settings.themes.currentName;
                    }

                    onFocusChanged:{
                        if(focus){
                            value = api.internal.settings.themes.currentName
                            currentIndex = api.internal.settings.themes.currentIndex;
                            count = api.internal.settings.themes.count;
                        }
                        container.onFocus(this)
                    }

                    KeyNavigation.down: optThemeKeepLoaded
                }
                ToggleOption {
                    id: optThemeKeepLoaded

                    label: qsTr("Keep Theme Loaded (Beta)") + api.tr
                    note: qsTr("Themes could stay loaded during gaming to avoid reloading after(Theme should be compatible)") + api.tr

                    checked: api.internal.recalbox.getBoolParameter("pegasus.theme.keeploaded")
                    onCheckedChanged: {
                        api.internal.recalbox.setBoolParameter("pegasus.theme.keeploaded",checked);
                    }
                    onFocusChanged: container.onFocus(this)
                    KeyNavigation.down: optMultiWindows
                }
                ToggleOption {
                    id: optMultiWindows

                    label: qsTr("Multi-Windows (Beta)") + api.tr
                    note: qsTr("Once enabled, you can run emulators in separate windows and keep pegasus/theme activated") + api.tr

                    checked: api.internal.recalbox.getBoolParameter("pegasus.multiwindows")
                    onCheckedChanged: {
                        api.internal.recalbox.setBoolParameter("pegasus.multiwindows",checked);
                    }
                    onFocusChanged: container.onFocus(this)
                    KeyNavigation.down: optHideEmbeddedGames
                }
                SectionTitle {
                    text: qsTr("Games library loading") + api.tr
                    first: true
                    symbol: "\uf1d9"
                }
                ToggleOption {
                    id: optHideEmbeddedGames

                    label: qsTr("Hide embedded games") + api.tr
                    note: qsTr("Once enabled, default games embedded from pixL will be hide") + api.tr

                    checked: api.internal.recalbox.getBoolParameter("pegasus.embedded.games.hide",false)
                    onCheckedChanged: {
                        api.internal.recalbox.setBoolParameter("pegasus.embedded.games.hide",checked);
                    }
                    onFocusChanged: container.onFocus(this)
                    KeyNavigation.down: optGamelistsOnly

                }
                ToggleOption {
                    id: optGamelistsOnly

                    label: qsTr("Gamelist only") + api.tr
                    note: qsTr("Once enabled, only files from gamelist will be take into account.\n(Best game file loading ;-)") + api.tr

                    checked: api.internal.recalbox.getBoolParameter("pegasus.gamelistonly",false)
                    onCheckedChanged: {
                        api.internal.recalbox.setBoolParameter("pegasus.gamelistonly",checked);
                    }
                    onFocusChanged: container.onFocus(this)
                    KeyNavigation.down: optGamelistsFirst

                }
                ToggleOption {
                    id: optGamelistsFirst

                    label: qsTr("Gamelist first (Beta)") + api.tr
                    note: qsTr("Once enabled, system gamelist will be seach in priority else game files will be search.\n(Intermediate game file loading)") + api.tr

                    checked: api.internal.recalbox.getBoolParameter("pegasus.gamelistfirst",true)
                    onCheckedChanged: {
                        api.internal.recalbox.setBoolParameter("pegasus.gamelistfirst",checked);
                    }
                    onFocusChanged: container.onFocus(this)
                    KeyNavigation.down: optDeactivateSkraperMedia

                }
                ToggleOption {
                    id: optDeactivateSkraperMedia

                    label: qsTr("Deactivate Skraper media") + api.tr
                    note: qsTr("Once enabled, only media from gamelist will be take into account.\n(Best loading ;-) / Less Media :-( )") + api.tr

                    checked: api.internal.recalbox.getBoolParameter("pegasus.deactivateskrapermedia",false)
                    onCheckedChanged: {
                        api.internal.recalbox.setBoolParameter("pegasus.deactivateskrapermedia",checked);
                    }
                    onFocusChanged: container.onFocus(this)
                    KeyNavigation.down: optMediaList

                }
                ToggleOption {
                    id: optMediaList

                    label: qsTr("Medialist (Beta)") + api.tr
                    note: qsTr("Once enabled, during Skraper media scan a media.xml is generated.\n(Quick loading ;-) / All Media :-) )") + api.tr

                    checked: api.internal.recalbox.getBoolParameter("pegasus.usemedialist",true)
                    onCheckedChanged: {
                        api.internal.recalbox.setBoolParameter("pegasus.usemedialist",checked);
                    }
                    onFocusChanged: container.onFocus(this)
                    KeyNavigation.down: optOnDemandMedia
                    visible: !optDeactivateSkraperMedia.checked
                }
                ToggleOption {
                    id: optOnDemandMedia

                    label: qsTr("Media 'On Demand' (Beta)") + api.tr
                    note: qsTr("Once enabled, media could be loaded dynamically and when it's requested.\n(Less memory used :-) / More impact ;-| )") + api.tr

                    checked: api.internal.recalbox.getBoolParameter("pegasus.mediaondemand",false)
                    onCheckedChanged: {
                        api.internal.recalbox.setBoolParameter("pegasus.mediaondemand",checked);
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
    MultivalueBox {
        id: themeBox
        z: 3

        property MultivalueOption callerid

        //reuse same model
        model: api.internal.settings.themes
        //to use index from themes QAbstractList
        index: api.internal.settings.themes.currentIndex

        onClose: content.focus = true
        onSelect: {
            callerid.keypressed = true;
            //to update index of locales QAbstractList
            api.internal.settings.themes.currentIndex = index;
            //to force update of display of selected value
            callerid.value = api.internal.settings.themes.currentName;
            callerid.currentIndex = api.internal.settings.themes.currentIndex;
            callerid.count = api.internal.settings.themes.count;
        }
    }
}
