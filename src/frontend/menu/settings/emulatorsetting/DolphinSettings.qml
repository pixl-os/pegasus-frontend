// Pegasus Frontend
//
// Created by Strodown 17/07/2023
//

import "../common"
import "qrc:/qmlutils" as PegasusUtils
import QtQuick 2.12
import QtQuick.Controls 2.12
import QtQuick.Window 2.12

FocusScope {
    id: root

    signal close

    width: parent.width
    height: parent.height
    
    anchors.fill: parent
    visible: 0 < (x + width) && x < Window.window.width

    enabled: focus

    Keys.onPressed: {
        if (api.keys.isCancel(event) && !event.isAutoRepeat) {
            event.accepted = true;
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
        text: qsTr("Advanced emulators settings > Dolphin-emu") + api.tr
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
                    id: optInternalResolution
                    // set focus only on first item
                    focus: true

                    //property to manage parameter name
                    property string parameterName : "dolphin.resolution"

                    label: qsTr("Internal Resolution") + api.tr
                    note: qsTr("Controls the rendering resolution. \nA high resolution greatly improves visual quality, \nBut cause issues in certain games.") + api.tr

                    value: api.internal.recalbox.parameterslist.currentName(parameterName)

                    currentIndex: api.internal.recalbox.parameterslist.currentIndex;
                    count: api.internal.recalbox.parameterslist.count;

                    onActivate: {
                        //for callback by parameterslistBox
                        parameterslistBox.parameterName = parameterName;
                        parameterslistBox.callerid = optInternalResolution;
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

                    KeyNavigation.down: optVsync
                }
                ToggleOption {
                    id: optVsync

                    label: qsTr("Enable Vsync") + api.tr
                    note: qsTr("Enable Vsync for best rendering, but improve performance.") + api.tr

                    checked: api.internal.recalbox.getBoolParameter("dolphin.vsync")
                    onCheckedChanged: {
                        api.internal.recalbox.setBoolParameter("dolphin.vsync",checked);
                    }
                    onFocusChanged: container.onFocus(this)
                    KeyNavigation.down: optWideScreenHack
                }
                ToggleOption {
                    id: optWideScreenHack

                    label: qsTr("Enable Widescreen Hack") + api.tr
                    note: qsTr("Force screen ratio to 16/9.") + api.tr

                    checked: api.internal.recalbox.getBoolParameter("dolphin.widescreenhack")
                    onCheckedChanged: {
                        api.internal.recalbox.setBoolParameter("dolphin.widescreenhack",checked);
                    }
                    onFocusChanged: container.onFocus(this)
                    KeyNavigation.down: optAntiAliasing
                }
                MultivalueOption {
                    id: optAntiAliasing

                    //property to manage parameter name
                    property string parameterName : "dolphin.antialiasing"

                    label: qsTr("Anti-Aliasing") + api.tr
                    note: qsTr("Reduce the amount of aliasing caused by rasterizing 3d graphics.") + api.tr

                    value: api.internal.recalbox.parameterslist.currentName(parameterName)

                    currentIndex: api.internal.recalbox.parameterslist.currentIndex;
                    count: api.internal.recalbox.parameterslist.count;

                    onActivate: {
                        //for callback by parameterslistBox
                        parameterslistBox.parameterName = parameterName;
                        parameterslistBox.callerid = optAntiAliasing;
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

                    KeyNavigation.down: optCheats
                }
                SectionTitle {
                    text: qsTr("Gameplay options") + api.tr
                    first: true
                    symbol: "\uf412"
                }
                ToggleOption {
                    id: optCheats

                    label: qsTr("Enable Cheats") + api.tr
                    note: qsTr("Ingames cheats enable.") + api.tr

                    checked: api.internal.recalbox.getBoolParameter("dolphin.cheats")
                    onCheckedChanged: {
                        api.internal.recalbox.setBoolParameter("dolphin.cheats",checked);
                    }
                    onFocusChanged: container.onFocus(this)
                    KeyNavigation.down: optAutoDiscChange
                }
                ToggleOption {
                    id: optAutoDiscChange

                    label: qsTr("Enable Auto Disc Change") + api.tr
                    note: qsTr("Automatically changes discs in game.") + api.tr

                    checked: api.internal.recalbox.getBoolParameter("dolphin.disc.change")
                    onCheckedChanged: {
                        api.internal.recalbox.setBoolParameter("dolphin.disc.change",checked);
                    }
                    onFocusChanged: container.onFocus(this)
                    KeyNavigation.down: optWiiSensorsBars
                }
                SectionTitle {
                    text: qsTr("Controllers") + api.tr
                    first: true
                    symbol:"\uf262 / \uf263"
                    symbolFontFamily: globalFonts.awesome
                    symbolFontSize: vpx(40)
                }
                ToggleOption {
                    id: optWiiSensorsBars
                    //wii.sensorbar.position=1
                    label: qsTr("Wiimote sensor bar position") + api.tr
                    note: qsTr("set position to 1 for the sensor bar at the top of the screen, to 0 for the sensor bar at the bottom") + api.tr

                    checked: api.internal.recalbox.getBoolParameter("wii.sensorbar.position")
                    onCheckedChanged: {
                        api.internal.recalbox.setBoolParameter("wii.sensorbar.position",checked);
                    }
                    onFocusChanged: container.onFocus(this)
                    KeyNavigation.down: optRealWiimotes
                }
                ToggleOption {
                    id: optRealWiimotes
                    //wii.realwiimotes=0
                    label: qsTr("Use authentics Wiimotes controllers") + api.tr
                    note: qsTr("Use authentics Wiimotes pads in Wii games") + api.tr

                    checked: api.internal.recalbox.getBoolParameter("wii.realwiimotes")
                    onCheckedChanged: {
                        api.internal.recalbox.setBoolParameter("wii.realwiimotes",checked);
                    }
                    onFocusChanged: container.onFocus(this)
                    KeyNavigation.down: optEmulatedWiimotesNunchuk
                }
                ToggleOption {
                    id: optEmulatedWiimotesNunchuk
                    //wii.emulatedwiimotes.nunchuck=1
                    label: qsTr("Activate nunchuck") + api.tr
                    note: qsTr("For emulated Wiimotes using gamepads") + api.tr

                    checked: api.internal.recalbox.getBoolParameter("wii.emulatedwiimotes.nunchuck",true)
                    onCheckedChanged: {
                        api.internal.recalbox.setBoolParameter("wii.emulatedwiimotes.nunchuck",checked);
                    }
                    onFocusChanged: container.onFocus(this)
                    visible: !optRealWiimotes.checked
                    KeyNavigation.down: optEmulatedWiimotesButtonsMapping
                }
                MultivalueOption {
                    id: optEmulatedWiimotesButtonsMapping

                    //property to manage parameter name
                    property string parameterName :"wii.emulatedwiimotes.buttons.mapping"
                    label: qsTr("Buttons mapping") + api.tr
                    note: qsTr("A/B/1/2 buttons position for emulated Wiimotes using gamepads") + api.tr

                    value: api.internal.recalbox.parameterslist.currentName(parameterName)

                    currentIndex: api.internal.recalbox.parameterslist.currentIndex;
                    count: api.internal.recalbox.parameterslist.count;

                    onActivate: {
                        //for callback by parameterslistBox
                        parameterslistBox.parameterName = parameterName;
                        parameterslistBox.callerid = optEmulatedWiimotesButtonsMapping;
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

                    KeyNavigation.down: optGcControllers
                    visible: !optRealWiimotes.checked
                }

                ToggleOption {
                    id: optGcControllers
                    //gamecube.realgamecubepads=0
                    label: qsTr("Use authentics Gamecube pads") + api.tr
                    note: qsTr("Use authentics Gamecube pads in Gamecube emulator") + api.tr

                    checked: api.internal.recalbox.getBoolParameter("gamecube.realgamecubepads")
                    onCheckedChanged: {
                        api.internal.recalbox.setBoolParameter("gamecube.realgamecubepads",checked);
                    }
                    onFocusChanged: container.onFocus(this)
                    //KeyNavigation.down: RFU
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
