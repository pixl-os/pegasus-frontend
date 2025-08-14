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
    signal openBiosCheckingSettings
    signal openSystemsAdvancedEmulatorSettings
    signal openAdvancedEmulatorSettings
    signal openGameDumperReaderSettings


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
        text: qsTr("Games") + api.tr
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
                    text: qsTr("Game screen") + api.tr
                    first: true
                    symbol: "\uf17f"
                }
                MultivalueOption {
                    id: optGlobalGameRatio

                    // set focus only on first item
                    focus: true

                    //property to manage parameter name
                    property string parameterName : "global.ratio"

                    label: qsTr("Game ratio") + api.tr
                    note: qsTr("Set ratio for all emulators (auto,4/3,16/9,16/10,etc...)") + api.tr

                    value: api.internal.recalbox.parameterslist.currentName(parameterName)

                    currentIndex: api.internal.recalbox.parameterslist.currentIndex;
                    count: api.internal.recalbox.parameterslist.count;

                    onActivate: {
                        //for callback by parameterslistBox
                        parameterslistBox.parameterName = parameterName;
                        parameterslistBox.callerid = optGlobalGameRatio;
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

                    KeyNavigation.down: optGlobalShaderSet
                }
                MultivalueOption {
                    id: optGlobalShaderSet

                    //property to manage parameter name
                    property string parameterName : "global.shaderset"

                    label: qsTr("Predefined shader") + api.tr
                    note: qsTr("Set predefined Shader effect") + api.tr

                    value: api.internal.recalbox.parameterslist.currentName(parameterName)
                    internalvalue: api.internal.recalbox.parameterslist.currentInternalName(parameterName);

                    currentIndex: api.internal.recalbox.parameterslist.currentIndex;
                    count: api.internal.recalbox.parameterslist.count;

                    onValueChanged: {
                        //to force to udpate internal value also
                        internalvalue = api.internal.recalbox.parameterslist.currentInternalName(parameterName);
                    }

                    onActivate: {
                        //for callback by parameterslistBox
                        parameterslistBox.parameterName = parameterName;
                        parameterslistBox.callerid = optGlobalShaderSet;
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

                    KeyNavigation.down: optGlobalShaderBorderCoverage
                }
                SliderOption {
                    id: optGlobalShaderBorderCoverage

                    //property to manage parameter name
                    property string parameterName : "global.shaderbordercoverage"
                    visible: optGlobalShaderSet.internalvalue === "megabezel_above_overlay" ? true : false
                    //property of SliderOption to set
                    label: qsTr("Overlay Shader Border Coverage") + api.tr
                    note: qsTr("Additional Border Coverage to manage shader above overlay as Mega Bezel") + api.tr
                    // in slider object
                    max : 15
                    min : 0
                    slidervalue : api.internal.recalbox.getIntParameter(parameterName,4)
                    // in text object
                    value: api.internal.recalbox.getIntParameter(parameterName,4) + "%"

                    onActivate: {
                        focus = true;
                    }

                    Keys.onLeftPressed: {
                        api.internal.recalbox.setIntParameter(parameterName,slidervalue);
                        value = slidervalue + "%";
                        sfxNav.play();
                    }

                    Keys.onRightPressed: {
                        api.internal.recalbox.setIntParameter(parameterName,slidervalue);
                        value = slidervalue + "%";
                        sfxNav.play();
                    }

                    onFocusChanged: container.onFocus(this)

                    KeyNavigation.down: optGlobalShader
                }
                MultivalueOption {
                    id: optGlobalShader

                    //property to manage parameter name
                    property string parameterName : "global.shaders"

                    label: qsTr("Shaders") + api.tr
                    note: qsTr("Set prefered Shader effect") + api.tr

                    value: api.internal.recalbox.parameterslist.currentName(parameterName)

                    currentIndex: api.internal.recalbox.parameterslist.currentIndex;
                    count: api.internal.recalbox.parameterslist.count;

                    onActivate: {
                        //to force update of list of parameters
                        api.internal.recalbox.parameterslist.currentName(parameterName);

                        //to customize Box display
                        parameterslistBox.firstlist_title = qsTr("Directory") + api.tr
                        parameterslistBox.secondlist_title = qsTr("Shader") + api.tr
                        parameterslistBox.firstlist_minimum_width_purcentage = 0.23
                        parameterslistBox.secondlist_minimum_width_purcentage = 0.43
                        parameterslistBox.splitted_list = true;
                        parameterslistBox.has_picture = true;
                        parameterslistBox.max_listitem_displayed = 7;                        

                        //for callback by parameterslistBox
                        parameterslistBox.index = api.internal.recalbox.parameterslist.currentIndex;
                        parameterslistBox.model = api.internal.recalbox.parameterslist;
                        parameterslistBox.callerid = optGlobalShader;
                        parameterslistBox.parameterName = parameterName;
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

                    KeyNavigation.down: optGlobalOverlays
                }
                ToggleOption {
                    id: optGlobalOverlays

                    label: qsTr("Set overlays") + api.tr
                    note: qsTr("Set overlays for all systems") + api.tr

                    checked: api.internal.recalbox.getBoolParameter("global.recalboxoverlays")
                    onCheckedChanged: {
                        api.internal.recalbox.setBoolParameter("global.recalboxoverlays",checked);
                    }
                    onFocusChanged: container.onFocus(this)
                    KeyNavigation.down: optShowFramerate
                }
                ToggleOption {
                    id: optShowFramerate

                    label: qsTr("Show framerate") + api.tr
                    note: qsTr("Show FPS in game") + api.tr

                    checked: api.internal.recalbox.getBoolParameter("global.showfps")
                    onCheckedChanged: {
                        api.internal.recalbox.setBoolParameter("global.showfps",checked);
                    }
                    onFocusChanged: container.onFocus(this)
                    KeyNavigation.down: optBiosChecking
                }
                SectionTitle {
                    text: qsTr("Other options") + api.tr
                    first: true
                    symbol: "\uf1d9"
                }
                SimpleButton {
                    id: optBiosChecking

                    label: qsTr("Bios Checking") + api.tr
                    note: qsTr("Check all necessary bios !") + api.tr
                    pointerIcon: true

                    onActivate: {
                        focus = true;
                        root.openBiosCheckingSettings();
                    }
                    onFocusChanged: container.onFocus(this)
                    KeyNavigation.down: optSystemsAdvancedEmulator
                }
                SimpleButton {
                    id: optSystemsAdvancedEmulator

                    label: qsTr("Settings systems") + api.tr
                    note: qsTr("choose emulators, ratio and more per systems") + api.tr
                    //pointer moved in SimpleButton desactived on default
                    pointerIcon: true

                    onActivate: {
                        focus = true;
                        root.openSystemsAdvancedEmulatorSettings();
                    }
                    onFocusChanged: container.onFocus(this)
                    KeyNavigation.down: optAdvancedEmulator
                }
                SimpleButton {
                    id: optAdvancedEmulator

                    label: qsTr("Advanced emulators settings") + api.tr
                    note: qsTr("Configuration per emulators, resolution, antialiasing, etc...") + api.tr
                    //pointer moved in SimpleButton desactived on default
                    pointerIcon: true

                    onActivate: {
                        focus = true;
                        root.openAdvancedEmulatorSettings();
                    }
                    onFocusChanged: container.onFocus(this)
                    KeyNavigation.down: optGameDumperReaderSettings
                }
                SimpleButton {
                    id: optGameDumperReaderSettings

                    label: qsTr("Game Reader/Dumper settings") + api.tr
                    note: qsTr("Configure device(s) to read/dump your game") + api.tr
                    //pointer moved in SimpleButton desactived on default
                    pointerIcon: true

                    onActivate: {
                        focus = true;
                        root.openGameDumperReaderSettings();
                    }
                    onFocusChanged: container.onFocus(this)
                    // KeyNavigation.down: RFU
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

        //has_picture: (callerid !== null) ? ((typeof(callerid.has_picture) !== "undefined") ? callerid.has_picture : false) : false
        //max_listitem_displayed: (callerid !== null) ? ((typeof(callerid.max_listitem_displayed) !== "undefined") ? callerid.max_listitem_displayed : 10) : 10
        //splitted_list: (callerid !== null) ? ((typeof(callerid.splitted_list) !== "undefined") ? callerid.splitted_list : false) : false

        //to use index from parameterlist QAbstractList
        index: api.internal.recalbox.parameterslist.currentIndex
        //reuse same model
        model: api.internal.recalbox.parameterslist
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
