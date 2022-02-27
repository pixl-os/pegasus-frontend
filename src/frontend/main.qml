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


import "qrc:/qmlutils" as PegasusUtils
import QtQuick 2.12
import QtQuick.Window 2.12
import QtQuick.Controls 2.15
import "dialogs"
import "global"
import QtQuick.VirtualKeyboard 2.15
import QtQuick.VirtualKeyboard.Settings 2.15

Window {
    id: appWindow
    visible: true
    width: 1280
    height: 720
    title: "Pegasus"
    color: "#000"

    visibility: api.internal.settings.fullscreen
                ? Window.FullScreen : Window.AutomaticVisibility

    //for debug reason on QT creator to know if we are or not on a real recalbox/pixl
    property var hostname: api.internal.system.run("hostname");
    //function to know if we are on standard linux for testing
    function isDebugEnv()
    {
        //for the moment, we use the hostname only, to improve later if possible
        if (hostname.toLowerCase().includes("recalbox")||hostname.toLowerCase().includes("pixl"))
        {
            return false;
        }
        else
        {
            return true;
        }
    }

    /*onClosing: {
        theme.source = "";
        api.internal.system.quit();
    }*/

    // Color palette set with 'themeColor.main' or else
    property var themeColor: {
        return {
            main:               "#404040",
            secondary:          "#606060",
            screenHeader:       "#606060",
            screenUnderline:    "#32CD32",
            underline:          "#32CD32",
            textTitle:          "#B0E0E6",
            textLabel:          "#eee",
            textSublabel:       "#999",
            textSectionTitle:   "#32CD32",
            textValue:          "#eee",
        }
    }
    FontLoader { id: sansFont; source: "/fonts/Roboto-Regular.ttf" }
    FontLoader { id: sansBoldFont; source: "/fonts/Roboto-Bold.ttf" }
    FontLoader { id: monoFont; source: "/fonts/RobotoMono-Regular.ttf" }
    FontLoader { id: condensedFont; source: "/fonts/RobotoCondensed-Regular.ttf" }
    FontLoader { id: condensedBoldFont; source: "/fonts/RobotoCondensed-Bold.ttf" }
    FontLoader { id: awesomeWebFont; source: "/fonts/fontawesome_webfont.ttf" }
    FontLoader { id: ionIconsFont; source: "/fonts/ionicons.ttf" }

    // a globally available utility object
    QtObject {
        id: global

        readonly property real winScale: Math.min(width / 1280.0, height / 720.0)

        property QtObject fonts: QtObject {
            readonly property string sans: sansFont.name
            readonly property string sansBold: sansBoldFont.name
            readonly property string condensed: condensedFont.name
            readonly property string condensedBold: condensedBoldFont.name
            readonly property string mono: monoFont.name
            readonly property string awesome : awesomeWebFont.name
            readonly property string ion : ionIconsFont.name
        }
    }


    // legacy global objects
    QtObject {
        id: globalFonts
        readonly property string sans: global.fonts.sans
        readonly property string condensed: global.fonts.condensed
        readonly property string awesome: global.fonts.awesome
        readonly property string ion: global.fonts.ion
    }
    function vpx(value) {
        return global.winScale * value;
    }


    // the main content
    FocusScope {
        id: content
        anchors.fill: parent
        enabled: focus

        signal onClose

        Loader {
            id: theme
            anchors.fill: parent

            focus: true
            enabled: focus

            readonly property url apiThemePath: api.internal.settings.themes.currentQmlPath

            function getThemeFile() {
                if (api.internal.meta.isLoading)
                    return "";
                if (api.collections.count === 0)
                    return "messages/NoGamesError.qml";

                return apiThemePath;
            }
            onApiThemePathChanged: source = Qt.binding(getThemeFile)

            Keys.onPressed: {
                if (api.keys.isMenu(event)) {
                    event.accepted = true;
                    mainMenu.focus = true;
                }

                if (api.keys.isNetplay(event) && api.internal.recalbox.getBoolParameter("global.netplay")){
                    event.accepted = true;
                    subscreen.setSource("menu/settings/NetplayRooms.qml", {"isCallDirectly": true});
                    subscreen.focus = true;
                    content.state = "sub";
                }


                if (event.key === Qt.Key_F5) {
                    event.accepted = true;

                    theme.source = "";
                    api.internal.meta.clearQMLCache();
                    theme.source = Qt.binding(getThemeFile);
                }
            }

            source: getThemeFile()
            asynchronous: true
            onStatusChanged: {
                if (status == Loader.Error)
                    source = "messages/ThemeError.qml";
            }
            onLoaded: item.focus = focus
            onFocusChanged: if (item) item.focus = focus
        }

        Loader {
            id: mainMenu
            anchors.fill: parent

            source: focus ? "MenuLayer.qml" : "" //reset source to force reload of menu and to avoid bad effects
            asynchronous: true

            onLoaded: item.focus = focus
            onFocusChanged: if (item) item.focus = focus
            enabled: focus
        }
        Connections {
            target: mainMenu.item

            function onClose() { theme.focus = true; }

            function onRequestShutdown() {
                powerDialog.source = "dialogs/ShutdownDialog.qml"
                powerDialog.focus = true;
            }
            function onRequestReboot() {
                powerDialog.source = "dialogs/RebootDialog.qml"
                powerDialog.focus = true;
            }
            function onRequestRestart() {
                powerDialog.source = "dialogs/RestartDialog.qml"
                powerDialog.focus = true;
            }
            function onRequestQuit() {
                theme.source = "";
                api.internal.system.quit();
            }
        }
        PegasusUtils.HorizontalSwipeArea {
            id: menuSwipe

            width: vpx(40)
            height: parent.height
            anchors.right: parent.right

            onSwipeLeft: {
                if (!mainMenu.focus)
                    mainMenu.focus = true;
            }
        }
        Loader {
            id: subscreen
            asynchronous: true

            width: parent.width
            height: parent.height
            anchors.left: content.right

            enabled: focus
            onLoaded: item.focus = focus
            onFocusChanged: if (item) item.focus = focus
        }
        Connections {
            target: subscreen.item
            function onClose() {
                content.focus = true;
                content.state = "";
                theme.visible = true;
                theme.focus = true;
            }
        }
        states: [
            State {
                name: "sub"
                AnchorChanges {
                    target: subscreen
                    anchors.left: undefined
                    anchors.right: parent.right
                }
            }
        ]
        // fancy easing curves, a la material design
        readonly property var bezierDecelerate: [ 0,0, 0.2,1, 1,1 ]
        readonly property var bezierSharp: [ 0.4,0, 0.6,1, 1,1 ]
        readonly property var bezierStandard: [ 0.4,0, 0.2,1, 1,1 ]

        transitions: [
            Transition {
                from: ""; to: "sub"
                AnchorAnimation {
                    duration: 425
                    easing { type: Easing.Bezier; bezierCurve: content.bezierStandard }
                }
                onRunningChanged: if (!running) theme.visible = false;
            },
            Transition {
                from: "sub"; to: ""
                AnchorAnimation {
                    duration: 400
                    easing { type: Easing.Bezier; bezierCurve: content.bezierSharp }
                }
                onRunningChanged: if (!running) {
                                      subscreen.source = "";
                                  }
            }
        ]
    }

    Loader {
        id: powerDialog
        anchors.fill: parent
    }
    Connections {
        target: powerDialog.item
        function onCancel() { content.focus = true; }
    }

    Loader {
        id: multifileSelector
        anchors.fill: parent
    }
    Connections {
        target: multifileSelector.item
        function onCancel() { content.focus = true; }
    }

    Loader {
        id: genericMessage
        anchors.fill: parent
    }
    Connections {
        target: genericMessage.item
        function onClose() { content.focus = true; }
    }

    Loader {
        id: genericPopup
        anchors.fill: parent
    }
    Connections {
        target: genericPopup.item
        function onClose() { content.focus = true; }
    }

    Loader {
        id: cdRomPopupLoader
        anchors.fill: parent
        sourceComponent: cdRomPopup
    }
    Connections {
        target: cdRomPopupLoader.item

        function onAccept() {
            content.focus = true;
            // connect game to launcher
            api.connectGameFiles(api.internal.singleplay.game);
            // launch this Game
            api.internal.singleplay.game.launch();
            // remove tmp file
            api.internal.system.run("rm -f /tmp/cd.conf");
        }
        function onSecondChoice() {
            // eject disk and delete tmp file
            content.focus = true;
            api.internal.system.run("rm -f /tmp/cd.conf | eject");
        }
        function onCancel() {
            // return back and remove tmp file
            content.focus = true;
            api.internal.system.run("rm -f /tmp/cd.conf");
        }
    }

    property string gameCdRom: ""

    Component {
        id: cdRomPopup
        CdRomDialog
        {
            focus: true
            // title: qsTr("Disk drive")
            //symbol:"\uf275"
            message:qsTr("A game is in the disk drive : ") + gameCdRom
            firstchoice: qsTr("Launch")
            secondchoice: qsTr("Eject")
            thirdchoice: qsTr("Back")
            system: gameCdRom
        }
    }

    // Timer to show the popup cdrom
    Timer {
        id: popupCdromDelay

        interval: 5000
        repeat: true
        running: splashScreen.focus ? false : true
        onTriggered: {
            gameCdRom = api.internal.system.run("grep -s -e 'system =' /tmp/cd.conf");
//console.log(gameCdRom)
            if(gameCdRom.includes("system =")) {
                cdRomPopupLoader.focus = true;
                //just set "cdrom" as title of this game (optional)
                api.internal.singleplay.setTitle("cdrom");
                //set rom full path
                api.internal.singleplay.setFile("cdrom://drive1.cue");
                //set system to select to run this rom
                api.internal.singleplay.setSystem("psx"); //using shortName
            }
        }
    }

    //Event from API Back-end
    Connections {
        target: api

        function onEventSelectGameFile(game) {
            multifileSelector.setSource("dialogs/MultifileSelector.qml", {"game": game})
            multifileSelector.focus = true;
        }
        function onEventLaunchError(msg) {
            genericMessage.setSource("dialogs/GenericOkDialog.qml",
                                     { "title": qsTr("Error"), "message": msg });
            genericMessage.focus = true;
        }
        function onShowPopup(title,message,icon,delay) {
            //init parameters
            popup.title = title;
            popup.message = message;
            //icon is optional but should be set to empty string if not use
            popup.icon = icon;
            popup.iconfont = globalFonts.sans;
            //delay provided in second and interval is in ms
            popupDelay.interval = delay * 1000;

            //Open popup and set it as showable to have animation
            popup.open();
            popup.showing = true;
            //start timer to close popup automatically
            popupDelay.restart();
        }
        function onNewController(idx, msg) {
            console.log("New controller detected: #", idx," - ", msg);
            subscreen.setSource("menu/settings/GamepadEditor.qml", {"newControllerIndex": idx, "isNewController": true});
            subscreen.focus = true;
            content.state = "sub";

            //add dialogBox
            genericMessage.setSource("dialogs/GenericContinueDialog.qml",
                                     { "title": qsTr("New type of controller detected") + " : " + msg, "message": qsTr("Press any button to continue") + "\n(" + qsTr("please read instructions at the bottom of next view to understand possible actions") + "\n" + qsTr("mouse and keyboard could be used to help configuration") + ")" });
            genericMessage.focus = true;
        }
        function onEventLoadingStarted() {
            splashScreen.focus = true;
        }
    }

    SplashLayer {
        id: splashScreen
        focus: true
        enabled: false
        visible: focus

        property bool dataLoading: api.internal.meta.loading
        property bool skinLoading: theme.status === Loader.Null || theme.status === Loader.Loading
        showDataProgressText: dataLoading

        function hideMaybe() {
            if (focus && !dataLoading && !skinLoading) {
                content.focus = true;
                api.internal.meta.resetLoadingState();
            }
        }
        onSkinLoadingChanged: hideMaybe()
        onDataLoadingChanged: hideMaybe()
    }

    // Timer to show the popup
    Timer {
        id: popupDelay

        interval: 5000
        onTriggered: {
            popup.showing = false;
        }
    }
    Popup {
        id: popup

        property alias title: titleText.text
        property alias message: messageText.text
        property alias icon: iconText.text

        property int titleTextSize: vpx(14)
        property int textSize: vpx(12)
        property int iconSize: vpx(60)

        property alias iconfont: iconText.font.family

        width:  (message.lenght > title.lenght) ? vpx(message.length * 7.5 + ((icon.length !== 0) ? 50 : 0)) + popup.titleTextSize : vpx(title.length * 7.5 + ((icon.length !== 0) ? 50 : 0) + popup.titleTextSize) //vpx(200)
        height: vpx(70)

        background: Rectangle {
            anchors.fill: parent
            border.color: themeColor.textTitle
            color: themeColor.secondary
            opacity: 0.8
            radius: height/4
            Behavior on opacity { NumberAnimation { duration: 100 } }
        }
        //need to work in x/y, no anchor.top/bottom/left/right/etc... available
        x: (parent.width/2) - (width/2)//parent.width * 0.01
        //do animation on y using showing boolean
        property bool showing: false
        property int position: showing ? (height + (parent.height * 0.03)) : 0
        y: parent.height - position

        Behavior on position {
            NumberAnimation {duration: 500}
        }

        modal: false
        focus: false
        visible: true
        closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutsideParent

        Column {
            id: dialogBox

            width: parent.width
            height: parent.height

            // text areas
            Rectangle {
                width: parent.width
                height: parent.height

                color: "transparent"

                Text {
                    id: titleText
                    elide: Text.ElideRight
                    wrapMode: Text.WordWrap

                    anchors {
                        top: parent.top
                        left: parent.left
                        right:  parent.right;
                        leftMargin: popup.titleTextSize * 0.5
                        rightMargin: popup.titleTextSize * 0.5
                    }
                    width: parent.width - (2 * anchors.leftMargin)
                    height: popup.titleTextSize * 1.2
                    color: themeColor.textTitle
                    fontSizeMode: Text.Fit
                    minimumPixelSize: popup.titleTextSize - vpx(2)
                    font {
                        bold: true
                        pixelSize: popup.titleTextSize
                        family: globalFonts.sans
                    }
                }

                Text {
                    id: iconText

                    anchors {
                        top: titleText.bottom
                        bottom: parent.bottom
                        right:  parent.right;
                        rightMargin: popup.titleTextSize * 0.1
                    }
                    width: height
                    color: themeColor.textTitle
                    fontSizeMode: Text.Fit
                    minimumPixelSize: popup.iconSize - vpx(10)
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                    font {
                        pixelSize: popup.iconSize
                        family: globalFonts.sans
                    }
                }

                Text {
                    id: messageText
                    elide: Text.ElideRight
                    wrapMode: Text.WordWrap

                    anchors {
                        top: titleText.bottom
                        bottom: parent.bottom
                        left: parent.left
                        right: (popup.icon !== "") ? iconText.left : parent.right
                        leftMargin: popup.titleTextSize * 0.5
                        rightMargin: popup.titleTextSize * 0.5
                    }
                    width: parent.width - (2 * anchors.leftMargin)
                    verticalAlignment: Text.AlignVCenter
                    color: themeColor.textLabel
                    fontSizeMode: Text.Fit
                    minimumPixelSize: popup.textSize - vpx(4)
                    font {
                        pixelSize: popup.textSize
                        family: globalFonts.sans
                    }
                }
            }
        }
    }

    //***********************************************************BEGIN OF NETPLAY PARTS*******************************************************************
    //Loader/Component/Connection to manage netplay room dialog
    Loader {
        id: netplayRoomDialog
        anchors.fill: parent
        z:10
        sourceComponent: netplayRoomComponent
        active: false
        asynchronous: true
        //to set value via loader
        property var game
        property var game_logo: game ? game.assets.logo : null
        property var game_name: game ? game.title : null
    }
    Component {
        id: netplayRoomComponent
        NetplayDialog {
            title: qsTr("Create Netplay room ?") + api.tr
            message: netplayRoomDialog.game_name
            symbol: ""
            firstchoice: qsTr("Play") + api.tr
            secondchoice: ""
            thirdchoice: qsTr("Cancel") + api.tr

            //Specific to Netplay
            game_logo: netplayRoomDialog.game_logo
            is_to_create_room: true
        }
    }
    Connections {
        target: netplayRoomDialog.item
        function onAccept() {
            //check that pseudo is empty and if yes, it's set to "Anonymous"
            if(api.internal.recalbox.getStringParameter("global.netplay.nickname") === ""){
                api.internal.recalbox.setStringParameter("global.netplay.nickname", "Anonymous");
                //save it for configgen
                api.internal.recalbox.saveParameters();
            }
            netplayRoomDialog.game.launchNetplay(
                        2, "", "",
                        api.internal.recalbox.getBoolParameter("netplay.password.useforplayer") ? api.internal.recalbox.parameterslist.currentName("netplay.password.client"):"",
                        api.internal.recalbox.getBoolParameter("netplay.password.useforviewer") ? api.internal.recalbox.parameterslist.currentName("netplay.password.viewer"):"",
                        false,
                        "",
                        "",
                        "");

            netplayRoomDialog.active = false;
            content.focus = true;
        }

        function onCancel() {
            //do nothing
            netplayRoomDialog.active = false;
            content.focus = true;
        }
    }

    //functions provided for themes
    //to check if game is ready and well configured to run a netplay
    function isReadyForNetplay(game)
    {
        if(api.internal.recalbox.getBoolParameter("global.netplay")){
            //get collection shortname from game
            var shortName = game.collections.get(0).shortName;
            if(api.internal.recalbox.getStringParameter("global.netplay.systems").toLowerCase().includes(shortName.toLowerCase())){
                //get emulator & core selected or by default
                var emulator = api.internal.recalbox.getStringParameter(shortName + ".emulator");
                //console.log("emulator: ",emulator);
                var core = api.internal.recalbox.getStringParameter(shortName + ".core");
                //console.log("core: ",core);
                if((emulator === "") || (core === "")){ //in case of emulator/core not well saved in recalbox.conf
                    for(var i = 0; i < game.collections.get(0).emulatorsCount ; i++){
                        //get default one
                        if(game.collections.get(0).isDefaultEmulatorAt(i)){
                            /*console.log("default emulator: ",game.collections.get(0).getNameAt(i));
                            console.log("default core: ",game.collections.get(0).getCoreAt(i));
                            console.log("default core has netplay ? ",game.collections.get(0).hasNetplayAt(i));*/
                            if(game.collections.get(0).getNameAt(i).toLowerCase().includes("libretro")){
                                //And return if has netplay or not
                                return game.collections.get(0).hasNetplayAt(i);
                            }
                            else return false; // only libretro supported today
                        }
                    }
                    //return false if not found..strange ?!
                    return false;
                }
                //if libretro emulator and only
                else if(emulator.toLowerCase().includes("libretro")){
                    for(var j = 0; j < game.collections.get(0).emulatorsCount ; j++){
                        /*console.log("emulator to check: ",game.collections.get(0).getNameAt(j));
                        console.log("core to check: ",game.collections.get(0).getCoreAt(j));
                        get if one is matching*/
                        if(game.collections.get(0).getCoreAt(j) === core){
                            /*console.log("found emulator: ",game.collections.get(0).getNameAt(j));
                            console.log("found core: ",game.collections.get(0).getCoreAt(j));
                            And return if has netplay or not*/
                            return game.collections.get(0).hasNetplayAt(j);
                        }
                    }
                    //return false if not found..strange ?!
                    return false;
                }
                else return false; //not libretro core
            }
            else return false; //not netplay system
        }
        else return false; //no netplay activated from menu
    }
    //***********************************************************END OF NETPLAY PARTS*********************************************************************

    //***********************************************************BEGIN OF VIRTUAL KEYBOARD PARTS**********************************************************
    //loader for input panel for virtual keyboard
    Loader {
        id: inputPanelLoader
        anchors.fill: parent
        z:10
        sourceComponent: inputPanelComponent
        active: true
        asynchronous: true
    }
    Component {
        id: inputPanelComponent
        //to manage virtual keyboard
        Rectangle{
            anchors.fill: parent
            color: "transparent"
            visible: Qt.inputMethod.visible && api.internal.settings.virtualKeyboardSupport

            /*  Keyboard input panel.

                The keyboard is anchored to the bottom of the application.
            */
            InputPanel {
                id: inputPanel
                z: 89
                y: yPositionWhenHidden
                x: Screen.orientation === Qt.LandscapeOrientation ? 0 : (parent.width-parent.height) / 2
                width: Screen.orientation === Qt.LandscapeOrientation ? parent.width : parent.height
                height: (Screen.orientation === Qt.LandscapeOrientation ? parent.height : parent.width) - keyboard.height
                visible: Qt.inputMethod.visible && api.internal.settings.virtualKeyboardSupport

                property real yPositionWhenHidden: Screen.orientation === Qt.LandscapeOrientation ? parent.height : parent.width + (parent.height-parent.width) / 2
                states: State {
                    name: "visible"
                    /*  The visibility of the InputPanel can be bound to the Qt.inputMethod.visible property,
                        but then the handwriting input panel and the keyboard input panel can be visible
                        at the same time. Here the visibility is bound to InputPanel.active property instead,
                        which allows the handwriting panel to control the visibility when necessary.
                    */
                    when: inputPanel.active
                    PropertyChanges {
                        target: inputPanel
                        y: inputPanel.yPositionWhenHidden - inputPanel.height
                    }
                }
                transitions: Transition {
                    id: inputPanelTransition
                    from: ""
                    to: "visible"
                    reversible: true
                    enabled: !VirtualKeyboardSettings.fullScreenMode
                    ParallelAnimation {
                        NumberAnimation {
                            properties: "y"
                            duration: 250
                            easing.type: Easing.InOutQuad
                        }
                    }
                }
                AutoScroller {
                    id:autoScroller
                    verticalLimit: (Qt.inputMethod.visible && api.internal.settings.virtualKeyboardSupport) ? inputPanel.y + vpx(20) : 0 //for margin
                }
            }
        }
    }

    //to manage event/input/focus/status during edition with virtual Keyboard

    property var counter: 0 //counter use for debug
    property var previousVirtualKeyboardVisibility: false
    property var forcedSelectAll: false;
    property var activeInput;

    function virtualKeyboardOnReleased(ev){
        ev.accepted = true;
        return ev.accepted;
    }

    function virtualKeyboardOnPressed(ev,input,editionActive){
        activeInput = input;
        //console.log("searchbar.Keys.onPressed : ", counter++);
        //console.log("previousVirtualKeyboardVisibility : ",previousVirtualKeyboardVisibility);
        //console.log("ev.key : ", ev.key);
        //console.log("editionActive : ",editionActive);
        //console.log("input.focus : ",input.focus);
        //console.log("cursorVisible : ",	input.cursorVisible);
        //console.log("Qt.inputMethod.visible : ",Qt.inputMethod.visible);
        //console.log("Qt.Key_Return : ",Qt.Key_Return);
        //console.log("Qt.Key_Enter : ",Qt.Key_Enter);
        //console.log("Qt.Key_Backspace : ",Qt.Key_Backspace);
		// Accept
        if (api.keys.isAccept(ev) && !ev.isAutoRepeat) {
            //console.log("isAccept");
            ev.accepted = true;
            //for all cases
            if (!editionActive) {
                //console.log("# Use case 1 : with or without virtual keyboard");
                input.readOnly = false;
                editionActive = false;
                input.focus = false;
                input.focus = true;
                editionActive = true;
                input.selectAll();
                //for virtual keyboard only
                if (api.internal.settings.virtualKeyboardSupport) previousVirtualKeyboardVisibility = true;
            }
            //for virtual keyboard
            else if(editionActive && (!Qt.inputMethod.visible && api.internal.settings.virtualKeyboardSupport) && (previousVirtualKeyboardVisibility === false)){
                //console.log("# Use case 2 : virtual keyboard has been removed");
                //force refresh to display keyboard
                editionActive = false;
                input.focus = false;
                editionActive = false;
                input.focus = true;
                input.readOnly = false;
                if(forcedSelectAll) input.selectAll();
                //for virtual keyboard only
                if (api.internal.settings.virtualKeyboardSupport) previousVirtualKeyboardVisibility = true;
            }
            //for standard keyboard
            else if(editionActive && !api.internal.settings.virtualKeyboardSupport){
                //console.log("# Use case 3 : if edition is active and usage of standard keyboard only");
                editionActive = false;
                input.cursorVisible = false;
                input.readOnly = true;
				input.cursorPosition = 0;

            }
            //for virtual keyboard
            else if ((ev.key !== Qt.Key_Return) && (ev.key !== Qt.Key_Enter)){
                //console.log("# Use case 4 : if virtual keyboard visible and PRESS A");
				if(Qt.inputMethod.visible && api.internal.settings.virtualKeyboardSupport){
                    //console.log("# Use case 4 bis : if virtual keyboard visible and PRESS A");
                    keyEmitter.keyPressed(appWindow, Qt.Key_Return);
                    keyEmitter.keyReleased(appWindow, Qt.Key_Return);
                }
            }
            else if (ev.key === Qt.Key_Return){
                editionActive = false;
                input.cursorVisible = false;
                input.readOnly = true;
				input.cursorPosition = 0;
            }

            //for virtual keyboard only
            if (api.internal.settings.virtualKeyboardSupport) previousVirtualKeyboardVisibility = Qt.inputMethod.visible;
        }
        // Cancel
        else if (api.keys.isCancel(ev) && !ev.isAutoRepeat) {
            //console.log("isCancel");
            ev.accepted = true;

            //for virtual keyboard
            if(editionActive && Qt.inputMethod.visible && api.internal.settings.virtualKeyboardSupport){
                //console.log("# Use case 1 : exit from keyboard");
                editionActive = false;
                input.cursorVisible = false;
                input.readOnly = true;
				input.cursorPosition = 0;
            }
            //for virtual keyboard
            else if (editionActive && !Qt.inputMethod.visible && api.internal.settings.virtualKeyboardSupport) {
                //console.log("# Use case 2 : editon active & virtual keyboard not visible");
                input.focus = true;
                editionActive = false;
                input.cursorVisible = false;
                input.readOnly = true;
				input.cursorPosition = 0;
            }
            //for standard keyboard
            else if (editionActive && Qt.inputMethod.visible && !api.internal.settings.virtualKeyboardSupport){
                //console.log("# Use case 3 : edtion active with standard keyboard visible");
                editionActive = false;
                input.cursorVisible = false;
                input.readOnly = true;
				input.cursorPosition = 0;
            }
            else if(editionActive === false && input.readOnly === true) //if already in readonly and not active, we have to let control to parents
            {
                ev.accepted = false;
            }
        }

        return ev.accepted, input.focus, editionActive ;
    }
    //***********************************************************END OF VIRTUAL KEYBOARD PARTS**********************************************************

    //***********************************************************BEGIN OF UPDATES PARTS*****************************************************************
    ListModel {
        id: componentsListModel
        ListElement { componentName: "Pegasus-frontend"; repoUrl:"https://api.github.com/repos/bozothegeek/pegasus-frontend/releases";icon: "qrc:/frontend/assets/logopegasus.png"; picture: ""}
        //ListElement { componentName: "RetroArch"; repoUrl:"https://api.github.com/repos/bozothegeek/pegasus-frontend/releases";icon: "qrc:/frontend/assets/libretro-retroarch-simple-logo.png"; picture: ""}
        //ADD HERE new ListElement to add new component updatable
    }

    Timer {//timer to download last versions
        id: repoStatusRefreshTimer
        interval: 60000 * 30 // Check every 30 minutes and at start
        repeat: true
        running: true
        triggeredOnStart: true
        onTriggered: {
            //loop to launch download of all json repository files
            for(var i = 0;i < componentsListModel.count; i++){
                api.internal.updates.getRepoInfo(componentsListModel.get(i).componentName,componentsListModel.get(i).repoUrl);
            }
            //start timer to check one minute later the result
            jsonStatusRefreshTimer.running = false;
            jsonStatusRefreshTimer.running = true;
        }
    }

    property var numberOfUpdates: 0
    property var listOfUpdates : ""
    Timer {//timer to check json after download (1 minute later)
        id: jsonStatusRefreshTimer
        interval: 5000 //60000 // check after 1 minute / 5 seconds for test ;-)
        repeat: false // no need to repeat
        running: false
        triggeredOnStart: false
        onTriggered: {
            for(var i = 0;i < componentsListModel.count; i++){
                //check all components (including pre-release for the moment and without filter)
                numberOfUpdates = 0;
                listOfUpdates = "";
                if(api.internal.updates.hasUpdate(componentsListModel.get(i).componentName , true)){
                    numberOfUpdates = numberOfUpdates + 1;
                    componentsListModel.setProperty(i,"hasUpdate", true);
                    //contruct string about all udpates
                    listOfUpdates = listOfUpdates + (listOfUpdates !== "" ? " / " : "") + componentsListModel.get(i).componentName;
                }
            }
            if(numberOfUpdates !== 0){
                //to popup to alert about all udpates
                //init parameters
                popup.title = (numberOfUpdates === 1) ?  (qsTr("Update available") + api.tr) : (qsTr("Updates available") + api.tr);
                popup.message = listOfUpdates;
                //icon is optional but should be set to empty string if not use
                popup.icon = "\uf2c6";
                popup.iconfont = global.fonts.ion;
                //delay provided in second and interval is in ms
                popupDelay.interval = 5 * 1000;
                //Open popup and set it as showable to have animation
                popup.open();
                popup.showing = true;
                //start timer to close popup automatically
                popupDelay.restart();
            }
        }
    }
    //***********************************************************END OF UPDATES PARTS*******************************************************************

    //***********************************************************BEGIN OF BLUETOOTH RESTART*************************************************************
    Timer {//timer to restart bluetooth service and power on
        id:bluetoothRestartTimer
        interval: 500 //to restart quicker ;-)
        repeat: false // no need to repeat
        running: api.internal.recalbox.getBoolParameter("controllers.bluetooth.startreset")
        triggeredOnStart: false
        onTriggered: {
            console.log("bluetoothRestartTimer triggered !");
            if (!isDebugEnv()){
                api.internal.system.run("/etc/init.d/S40bluetooth restart");
                api.internal.system.run("bluetoothctl power on");
            }
        }
    }
    //***********************************************************END OF BLUETOOTH RESTART***************************************************************

}
