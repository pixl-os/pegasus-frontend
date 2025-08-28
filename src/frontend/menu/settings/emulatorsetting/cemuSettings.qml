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
    
//    anchors.fill: parent
    visible: 0 < (x + width) && x < Window.window.width

    enabled: focus

    property bool launchedAsDialogBox: false

    property var game
    property var system
    //to manage overloading
    property string prefix : game ? "override.cemu" : "cemu"

    //to manage better title in screen ScreenHeader (if we want to change it during loading)
    property string titleHeader : game ? game.title +  " > Cemu" :
                                  (system ? system.name + " > Cemu" :
                                         qsTr("Advanced emulators settings > Cemu") + api.tr)


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
        text: titleHeader
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

        clip: launchedAsDialogBox

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

                width: launchedAsDialogBox ? root.width * 0.9 : root.width * 0.7
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
//                MultivalueOption {
//                    id: optInternalResolution
//                    // set focus only on first item
//                    focus: true

//                    //property to manage parameter name
//                    property string parameterName : prefix + ".resolution"

//                    label: qsTr("Internal Resolution") + api.tr
//                    note: qsTr("Controls the rendering resolution. \nA high resolution greatly improves visual quality,But cause issues in certain games") + api.tr

//                    value: api.internal.recalbox.parameterslist.currentName(parameterName)
//                    onActivate: {
//                        //for callback by parameterslistBox
//                        parameterslistBox.parameterName = parameterName;
//                        parameterslistBox.callerid = optInternalResolution;
//                        //to force update of list of parameters
//                        api.internal.recalbox.parameterslist.currentName(parameterName);
//                        parameterslistBox.model = api.internal.recalbox.parameterslist;
//                        parameterslistBox.index = api.internal.recalbox.parameterslist.currentIndex;
//                        //to transfer focus to parameterslistBox
//                        parameterslistBox.focus = true;
//                    }
//                    onFocusChanged: container.onFocus(this)
//                    KeyNavigation.down: optTextureFilter
//                }
                MultivalueOption {
                    id: optUpscaleFilter
                    // set focus only on first item
                    focus: true

                    //property to manage parameter name
                    property string parameterName : prefix + ".upscale.filter"

                    label: qsTr("Upscale Filter") + api.tr
                    note: qsTr("Used when the game resolution is smaller than the windows size.") + api.tr

                    value: api.internal.recalbox.parameterslist.currentName(parameterName)

                    currentIndex: api.internal.recalbox.parameterslist.currentIndex;
                    count: api.internal.recalbox.parameterslist.count;

                    onActivate: {
                        //for callback by parameterslistBox
                        parameterslistBox.parameterName = parameterName;
                        parameterslistBox.callerid = optUpscaleFilter;
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

                    KeyNavigation.down: optTextureFilter
                }
                MultivalueOption {
                    id: optTextureFilter

                    //property to manage parameter name
                    property string parameterName : prefix + ".downscale.filter"

                    label: qsTr("Downscale Filter") + api.tr
                    note: qsTr("Used when the game resolution is bigger than the windows size.") + api.tr

                    value: api.internal.recalbox.parameterslist.currentName(parameterName)

                    currentIndex: api.internal.recalbox.parameterslist.currentIndex;
                    count: api.internal.recalbox.parameterslist.count;

                    onActivate: {
                        //for callback by parameterslistBox
                        parameterslistBox.parameterName = parameterName;
                        parameterslistBox.callerid = optTextureFilter;
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
                MultivalueOption {
                    id: optVsync

                    //property to manage parameter name
                    property string parameterName : prefix + ".vsync"

                    label: qsTr("Vsync") + api.tr
                    note: qsTr("Choose your vertical sync type.") + api.tr

                    value: api.internal.recalbox.parameterslist.currentName(parameterName)

                    currentIndex: api.internal.recalbox.parameterslist.currentIndex;
                    count: api.internal.recalbox.parameterslist.count;

                    onActivate: {
                        //for callback by parameterslistBox
                        parameterslistBox.parameterName = parameterName;
                        parameterslistBox.callerid = optVsync;
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

                    KeyNavigation.down: optAsyncCompile
                }
                SectionTitle {
                    text: qsTr("Core options") + api.tr
                    first: true
                    symbol: "\uf179"
                }
                ToggleOption {
                    id: optAsyncCompile

                    label: qsTr("Enable Async Compilation shaders") + api.tr
                    note: qsTr("Async shaders and pipeline compilation, reduce stutter at the cost of objects. \nNot rendering for a short time, vulkan only.") + api.tr

                    checked: api.internal.recalbox.getBoolParameter(prefix + ".async.compile")
                    onCheckedChanged: {
                        api.internal.recalbox.setBoolParameter(prefix + ".async.compile",checked);
                    }
                    onFocusChanged: container.onFocus(this)
                    KeyNavigation.down: optSDLUseButtonLabels
                }
                ToggleOption {
                    id: optSDLUseButtonLabels

                    property string parameterName :prefix + ".use.sdl.button.labels"
                    label: qsTr("Use SDL button labels for mappings") + api.tr
                    note: qsTr("Feature to match button letters as requested on screen\nElse XBOX mapping will be used for all controllers") + api.tr
                    //set env variable to SDL_GAMECONTROLLER_USE_BUTTON_LABELS=1 by default
                    checked: api.internal.recalbox.getBoolParameter(parameterName, true)
                    onCheckedChanged: {
                        api.internal.recalbox.setBoolParameter(parameterName,checked);
                    }
                    onFocusChanged: container.onFocus(this)
                    KeyNavigation.down: optRumblePower
                }
                SliderOption {
                    id: optRumblePower

                    //property to manage parameter name
                    property string parameterName : prefix + ".rumble"

                    //property of SliderOption to set
                    label: qsTr("Rumble power") + api.tr
                    note: qsTr("Set power of rumble used in cemu") + api.tr
                    // in slider object
                    max : 100
                    min : 0
                    slidervalue : api.internal.recalbox.getIntParameter(parameterName,0)
                    // in text object
                    value: api.internal.recalbox.getIntParameter(parameterName) + "%"

                    onActivate: {
                        focus = true;
                    }

                    Keys.onLeftPressed: {
                        api.internal.recalbox.setIntParameter(parameterName,slidervalue);
                        value = slidervalue + "%";
                        if(!isDebugEnv()) api.internal.system.runAsync("python /recalbox/scripts/pixl-rumble-test.py " + slidervalue + " " + slidervalue + " 300");
                    }

                    Keys.onRightPressed: {
                        api.internal.recalbox.setIntParameter(parameterName,slidervalue);
                        value = slidervalue + "%";
                        if(!isDebugEnv()) api.internal.system.runAsync("python /recalbox/scripts/pixl-rumble-test.py " + slidervalue + " " + slidervalue + " 300");
                    }

                    onFocusChanged: container.onFocus(this)

                    KeyNavigation.down: optGamepadActivated
                }
                SectionTitle {
                    text: qsTr("Gamepad screen") + api.tr
                    first: true
                    symbol: "\uf2ea"
                    symbolFontFamily: globalFonts.awesome
                    symbolFontSize: vpx(45)
                }
                ToggleOption {
                    id: optGamepadActivated

                    label: qsTr("Enable Wii U Gamepad") + api.tr
                    note: qsTr("Activate Wii U Gamepad usage in game") + api.tr

                    checked: api.internal.recalbox.getBoolParameter(prefix + ".gamepad.activated",false)
                    onCheckedChanged: {
                        api.internal.recalbox.setBoolParameter(prefix + ".gamepad.activated",checked);
                    }
                    onFocusChanged: container.onFocus(this)
                    KeyNavigation.down: optGamepadAtStart
                }
                ToggleOption {
                    id: optGamepadAtStart

                    label: qsTr("Show Gamepad at start") + api.tr
                    note: qsTr("Show gamepad window at front of game window and at start\n(else could be show/hide using HOTKEY+R1)") + api.tr

                    checked: api.internal.recalbox.getBoolParameter(prefix + ".gamepad.at.start",false)
                    onCheckedChanged: {
                        api.internal.recalbox.setBoolParameter(prefix + ".gamepad.at.start",checked);
                    }
                    onFocusChanged: container.onFocus(this)
                    visible: optGamepadActivated.checked
                    KeyNavigation.down: optGamepadOnSecondDisplay
                }
                ToggleOption {
                    id: optGamepadOnSecondDisplay

                    label: qsTr("Show Gamepad on second display (Beta)") + api.tr
                    note: qsTr("Need to have a second display (physical or virtual) connected\nand activated from 'video configuration' to work") + api.tr

                    checked: api.internal.recalbox.getBoolParameter(prefix + ".gamepad.on.second.display",false)
                    onCheckedChanged: {
                        api.internal.recalbox.setBoolParameter(prefix + ".gamepad.on.second.display",checked);
                    }
                    onFocusChanged: container.onFocus(this)
                    visible: optGamepadActivated.checked
                }
                Item {
                    width: parent.width
                    height: launchedAsDialogBox ? implicitHeight + vpx(50) : implicitHeight + vpx(30)
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
    Item {
        id: footer
        width: parent.width
        height: vpx(50)
        anchors.bottom: parent.bottom
        z:2
        visible: launchedAsDialogBox

        //Rectangle for the transparent background
        Rectangle {
            anchors.fill: parent
            color: themeColor.screenHeader
            opacity: 0.75
        }

        //rectangle for the gray line
        Rectangle {
            width: parent.width * 0.97
            height: vpx(1)
            color: "#777"
            anchors.top: parent.top
            anchors.horizontalCenter: parent.horizontalCenter
        }

        //for the help to exit
        Rectangle {
            id: backButtonIcon
            height: labelB.height
            width: height
            radius: width * 0.5
            border { color: "#777"; width: vpx(1) }
            color: "transparent"
            visible: {
                return true;
            }

            anchors {
                right: labelB.left
                verticalCenter: parent.verticalCenter
                verticalCenterOffset: vpx(1)
                margins: vpx(10)
            }
            Text {
                text: "B"
                color: "#777"
                font {
                    family: global.fonts.sans
                    pixelSize: parent.height * 0.7
                }
                anchors.centerIn: parent
            }
        }

        Text {
            id: labelB
            text: qsTr("Back") + api.tr
            verticalAlignment: Text.AlignTop
            visible: {
                return true;
            }

            color: "#777"
            font {
                family: global.fonts.sans
                pixelSize: vpx(22)
                capitalization: Font.SmallCaps
            }
            anchors {
                verticalCenter: parent.verticalCenter
                verticalCenterOffset: vpx(-1)
                right: parent.right; rightMargin: parent.width * 0.015
            }
        }
    }
}
