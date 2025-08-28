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

    //to be able to have region selected
    property string region : ""

    //loader to load confirm dialog
    Loader {
        id: launchPS2BIOS
        anchors.fill: parent
        z:10
    }

    Connections {
        target: launchPS2BIOS.item
        function onAccept() {
            //launch "game" to use BIOS
            //just set "bios" as title of this game (optional)
            api.internal.singleplay.setTitle("bios(" + region + ")");
            //set rom full path (fake rom with "bios(region)" in this case)
            //important to have paranthesis around the region and the "bios" term to be well detected by configgen
            api.internal.singleplay.setFile("/recalbox/share/roms/ps2/bios(" + region + ")");
            //set system to select to run this rom
            api.internal.singleplay.setSystem("ps2"); //using shortName
            //connect game to launcher
            api.connectGameFiles(api.internal.singleplay.game);
            //launch this Game
            api.internal.singleplay.game.launch();
            content.focus = true;
        }
        function onCancel() {
            //do nothing
            content.focus = true;
        }
    }

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
    property string prefix : game ? "override.pcsx2" : "pcsx2"
    //to manage better title in screen ScreenHeader (if we want to change it during loading)
    property string titleHeader: game ? game.title +  " > Pcsx2" :
        (system ? system.name + " > Pcsx2" :
         qsTr("Advanced emulators settings > Pcsx2") + api.tr)

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
                MultivalueOption {
                    id: optInternalResolution
                    // set focus only on first item
                    focus: true

                    //property to manage parameter name
                    property string parameterName : prefix + ".resolution"

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
                    note: qsTr("Vertical syncronisation.") + api.tr

                    checked: api.internal.recalbox.getBoolParameter(prefix + ".vsync")
                    onCheckedChanged: {
                        api.internal.recalbox.setBoolParameter(prefix + ".vsync",checked);
                    }
                    onFocusChanged: container.onFocus(this)
                    KeyNavigation.down: optAnisotropy
                }
                MultivalueOption {
                    id: optAnisotropy

                    //property to manage parameter name
                    property string parameterName : prefix + ".anisotropy"

                    label: qsTr("Anisotropy") + api.tr
                    note: qsTr("Reduce the amount of aliasing caused by rasterizing 3d graphics.") + api.tr

                    value: api.internal.recalbox.parameterslist.currentName(parameterName)

                    currentIndex: api.internal.recalbox.parameterslist.currentIndex;
                    count: api.internal.recalbox.parameterslist.count;

                    onActivate: {
                        //for callback by parameterslistBox
                        parameterslistBox.parameterName = parameterName;
                        parameterslistBox.callerid = optAnisotropy;
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

                    KeyNavigation.down: optTVShaders
                }
                MultivalueOption {
                    id: optTVShaders

                    //property to manage parameter name
                    property string parameterName : prefix + ".tvshaders"

                    label: qsTr("Tv Shaders") + api.tr
                    note: qsTr("Set your shaders effect.") + api.tr

                    value: api.internal.recalbox.parameterslist.currentName(parameterName)

                    currentIndex: api.internal.recalbox.parameterslist.currentIndex;
                    count: api.internal.recalbox.parameterslist.count;

                    onActivate: {
                        //for callback by parameterslistBox
                        parameterslistBox.parameterName = parameterName;
                        parameterslistBox.callerid = optTVShaders;
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
                    KeyNavigation.down: optGUI
                }
                ToggleOption {
                    id: optGUI

                    label: qsTr("Enable Graphical User Interface at start") + api.tr
                    note: qsTr("To access PCSX2 GUI at start") + api.tr

                    checked: api.internal.recalbox.getBoolParameter(prefix + ".gui",false)
                    onCheckedChanged: {
                        api.internal.recalbox.setBoolParameter(prefix + ".gui",checked);
                    }
                    onFocusChanged: container.onFocus(this)
                    KeyNavigation.down: optCrosshairs
                }
                SectionTitle {
                    text: qsTr("Lightguns") + api.tr
                    first: true
                    symbol: "\uf0d0"
                    symbolFontFamily: global.fonts.awesome //global.fonts.ion is used by default
                }
                ToggleOption {
                    id: optCrosshairs

                    label: qsTr("Crosshairs") + api.tr
                    note: qsTr("Active crosshairs on lightgun games.") + api.tr

                    checked: api.internal.recalbox.getBoolParameter(prefix + ".crosshairs",true)
                    onCheckedChanged: {
                        api.internal.recalbox.setBoolParameter(prefix + ".crosshairs",checked);
                    }
                    onFocusChanged: container.onFocus(this)
                    KeyNavigation.down: optSplitscreenHack
                }
                ToggleOption {
                    id: optSplitscreenHack

                    label: qsTr("Split screen hack (Beta)") + api.tr
                    note: qsTr("Hack to be able to play to split screen games as Time Crisis games\n(will be activated only if 2 guns connected)") + api.tr

                    checked: api.internal.recalbox.getBoolParameter(prefix + ".splitscreen.hack",true)
                    onCheckedChanged: {
                        api.internal.recalbox.setBoolParameter(prefix + ".splitscreen.hack",checked);
                    }
                    onFocusChanged: container.onFocus(this)
                    KeyNavigation.down: optSplitscreenFullStretch
                }
                ToggleOption {
                    id: optSplitscreenFullStretch
                    visible: optSplitscreenHack.checked
                    label: qsTr("Split screen full stretch (Beta)") + api.tr
                    note: qsTr("To maximize high of game view for split screen games\n(but not adviced to keep good ratio)") + api.tr

                    checked: api.internal.recalbox.getBoolParameter(prefix + ".splitscreen.fullstretch",false)
                    onCheckedChanged: {
                        api.internal.recalbox.setBoolParameter(prefix + ".splitscreen.fullstretch",checked);
                    }
                    onFocusChanged: container.onFocus(this)
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

                    checked: api.internal.recalbox.getBoolParameter(prefix + ".cheats",false)
                    onCheckedChanged: {
                        api.internal.recalbox.setBoolParameter(prefix + ".cheats",checked);
                    }
                    onFocusChanged: container.onFocus(this)
                    KeyNavigation.down: optFastBoot
                }
                ToggleOption {
                    id: optFastBoot

                    label: qsTr("Fast Boot") + api.tr
                    note: qsTr("To start game directly without Bios loading introduction\n(Not compatible with all games/hacks)") + api.tr

                    checked: api.internal.recalbox.getBoolParameter(prefix + ".fastboot",false)
                    onCheckedChanged: {
                        api.internal.recalbox.setBoolParameter(prefix + ".fastboot",checked);
                    }
                    onFocusChanged: container.onFocus(this)
                    KeyNavigation.down: optInjectSystemLanguage
                }
                ToggleOption {
                    id: optInjectSystemLanguage

                    label: qsTr("Inject System Language in BIOS") + api.tr
                    note: qsTr("Set PS2 BIOS System language from pixL's one") + api.tr

                    checked: api.internal.recalbox.getBoolParameter(prefix + ".injectsystemlanguage",true)
                    onCheckedChanged: {
                        api.internal.recalbox.setBoolParameter(prefix + ".injectsystemlanguage",checked);
                    }
                    onFocusChanged: container.onFocus(this)
                    KeyNavigation.down: btnLaunchEuropeBIOS
                }
                // to apply settings
                SimpleButton {
                    id: btnLaunchEuropeBIOS
                    Rectangle {
                        //id: containerValidate
                        width: parent.width
                        height: parent.height
                        anchors.verticalCenter: parent.verticalCenter
                        anchors.horizontalCenter: parent.horizontalCenter
                        color: parent.focus ? themeColor.underline : themeColor.secondary
                        opacity : parent.focus ? 1 : 0.3
                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            anchors.horizontalCenter: parent.horizontalCenter
                            color: themeColor.textValue
                            font.pixelSize: vpx(30)
                            font.family: globalFonts.ion
                            text : "\uf2ba  " + qsTr("Launch PS2 BIOS - Europe (to configure)") + api.tr
                        }
                    }
                    onActivate: {
                        //to force change of focus
                        launchPS2BIOS.focus = false;
                        launchPS2BIOS.setSource("../../../dialogs/Generic3ChoicesDialog.qml",
                                                { "title": "PS2 BIOS (Europe)",
                                                  "message": qsTr("Do you want to launch this BIOS now ?") + api.tr,
                                                  "symbol": "\uf412",
                                                  "symbolfont" : global.fonts.ion,
                                                  "firstchoice": qsTr("Yes") + api.tr,
                                                  "secondchoice": "",
                                                  "thirdchoice": qsTr("No") + api.tr});
                        //Save region selected for later
                        region = "europe";
                        //to force change of focus
                        launchPS2BIOS.focus = true;
                    }
                    onFocusChanged: container.onFocus(this)
                    KeyNavigation.down: btnLaunchJapanBIOS
                }
                SimpleButton {
                    id: btnLaunchJapanBIOS
                    Rectangle {
                        //id: containerValidate
                        width: parent.width
                        height: parent.height
                        anchors.verticalCenter: parent.verticalCenter
                        anchors.horizontalCenter: parent.horizontalCenter
                        color: parent.focus ? themeColor.underline : themeColor.secondary
                        opacity : parent.focus ? 1 : 0.3
                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            anchors.horizontalCenter: parent.horizontalCenter
                            color: themeColor.textValue
                            font.pixelSize: vpx(30)
                            font.family: globalFonts.ion
                            text : "\uf2ba  " + qsTr("Launch PS2 BIOS - Japan (to configure)") + api.tr
                        }
                    }
                    onActivate: {
                        //to force change of focus
                        launchPS2BIOS.focus = false;
                        launchPS2BIOS.setSource("../../../dialogs/Generic3ChoicesDialog.qml",
                                                { "title": "PS2 BIOS (Japan)",
                                                  "message": qsTr("Do you want to launch this BIOS now ?") + api.tr,
                                                  "symbol": "\uf412",
                                                  "symbolfont" : global.fonts.ion,
                                                  "firstchoice": qsTr("Yes") + api.tr,
                                                  "secondchoice": "",
                                                  "thirdchoice": qsTr("No") + api.tr});
                        //Save region selected for later
                        region = "japan";
                        //to force change of focus
                        launchPS2BIOS.focus = true;
                    }
                    onFocusChanged: container.onFocus(this)
                    KeyNavigation.down: btnLaunchUsaBIOS
                }
                SimpleButton {
                    id: btnLaunchUsaBIOS
                    Rectangle {
                        //id: containerValidate
                        width: parent.width
                        height: parent.height
                        anchors.verticalCenter: parent.verticalCenter
                        anchors.horizontalCenter: parent.horizontalCenter
                        color: parent.focus ? themeColor.underline : themeColor.secondary
                        opacity : parent.focus ? 1 : 0.3
                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            anchors.horizontalCenter: parent.horizontalCenter
                            color: themeColor.textValue
                            font.pixelSize: vpx(30)
                            font.family: globalFonts.ion
                            text : "\uf2ba  " + qsTr("Launch PS2 BIOS - USA (to configure)") + api.tr
                        }
                    }
                    onActivate: {
                        //to force change of focus
                        launchPS2BIOS.focus = false;
                        launchPS2BIOS.setSource("../../../dialogs/Generic3ChoicesDialog.qml",
                                                { "title": "PS2 BIOS (USA)",
                                                  "message": qsTr("Do you want to launch this BIOS now ?") + api.tr,
                                                  "symbol": "\uf412",
                                                  "symbolfont" : global.fonts.ion,
                                                  "firstchoice": qsTr("Yes") + api.tr,
                                                  "secondchoice": "",
                                                  "thirdchoice": qsTr("No") + api.tr});
                        //Save region selected for later
                        region = "usa";
                        //to force change of focus
                        launchPS2BIOS.focus = true;
                    }
                    onFocusChanged: container.onFocus(this)
                    KeyNavigation.down: btnLaunchAsiaBIOS
                }
                SimpleButton {
                    id: btnLaunchAsiaBIOS
                    Rectangle {
                        id: containerValidate
                        width: parent.width
                        height: parent.height
                        anchors.verticalCenter: parent.verticalCenter
                        anchors.horizontalCenter: parent.horizontalCenter
                        color: parent.focus ? themeColor.underline : themeColor.secondary
                        opacity : parent.focus ? 1 : 0.3
                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            anchors.horizontalCenter: parent.horizontalCenter
                            color: themeColor.textValue
                            font.pixelSize: vpx(30)
                            font.family: globalFonts.ion
                            text : "\uf2ba  " + qsTr("Launch PS2 BIOS - Asia (to configure)") + api.tr
                        }
                    }
                    onActivate: {
                        //to force change of focus
                        launchPS2BIOS.focus = false;
                        launchPS2BIOS.setSource("../../../dialogs/Generic3ChoicesDialog.qml",
                                                { "title": "PS2 BIOS (Asia)",
                                                  "message": qsTr("Do you want to launch this BIOS now ?") + api.tr,
                                                  "symbol": "\uf412",
                                                  "symbolfont" : global.fonts.ion,
                                                  "firstchoice": qsTr("Yes") + api.tr,
                                                  "secondchoice": "",
                                                  "thirdchoice": qsTr("No") + api.tr});
                        //Save region selected for later
                        region = "asia";
                        //to force change of focus
                        launchPS2BIOS.focus = true;
                    }
                    onFocusChanged: container.onFocus(this)
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
