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
import QtMultimedia 5.12
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
    //Flags to know if any parameter needing reboot or restart
    property bool needReboot : false
    property bool needRestart : false
    //Flag to know if we load from start/restart of pegasus or from ending of game session
    property bool loadingState : false
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
    property string backgroundThemeColor : api.internal.recalbox.getStringParameter("system.menu.color")
    property string selectedThemeColor : api.internal.recalbox.getStringParameter("system.selected.color")
    property string textThemeColor : api.internal.recalbox.getStringParameter("system.text.color")
    property var themeColor: {

        var background = "#404040"
        var _secondary = "#535353"

        var _textTitle = "#B0E0E6"
        var _textLabel = "#eeeeee"
        var _textSublabel = "#999999"

        var accent = "#32CD32"

        if (backgroundThemeColor === "Original") {
            background = "#404040"
            _secondary = "#535353"
        }
        else if (backgroundThemeColor === "Black") {
            background = "#1a1a1a"
            _secondary = "#303030"
        }
        else if (backgroundThemeColor === "White") {
            background = "#ebebeb"
            _secondary = "#dfdfdf"
        }
        else if (backgroundThemeColor === "Gray") {
            background = "#666666"
            _secondary = "#757575"
        }
        else if (backgroundThemeColor === "Blue") {
            background = "#1d253d"
            _secondary = "#333A50"
        }
        else if (backgroundThemeColor === "Green") {
            background = "#054b16"
            _secondary = "#1D5D2D"
        }
        else if (backgroundThemeColor === "Red") {
            background = "#520000"
            _secondary = "#631919"
        }
        else if (backgroundThemeColor === "Purple") {
            background = "#684791"
            _secondary = "#77599C"
        }

        if (textThemeColor === "Original") {
            _textTitle = "#bfe6eb"
            _textLabel = "#b7e3e8"
            _textSublabel = "#B0E0E6"
        }
        else if (textThemeColor === "Black") {
            _textTitle = "#000000"
            _textLabel = "#000000"
            _textSublabel = "#000000"
        }
        else if (textThemeColor === "White") {
            _textTitle = "#e5e5e5"
            _textLabel = "#f2f2f2"
            _textSublabel = "#ffffff"
        }
        else if (textThemeColor === "Gray") {
            _textTitle = "#9a9a9a"
            _textLabel = "#8d8d8d"
            _textSublabel = "#818181"
        }
        else if (textThemeColor === "Blue") {
            _textTitle = "#52a3d8"
            _textLabel = "#3d98d3"
            _textSublabel = "#288dcf"
        }
        else if (textThemeColor === "Green") {
            _textTitle = "#83bf5a"
            _textLabel = "#74b746"
            _textSublabel = "#65b032"
        }
        else if (textThemeColor === "Red") {
            _textTitle = "#ea5360"
            _textLabel = "#e73e4c"
            _textSublabel = "#e52939"
        }
        else if (textThemeColor === "Purple") {
            _textTitle = "#9b7ec0"
            _textLabel = "#8e6fb8"
            _textSublabel = "#825fb1"
        }

        if (selectedThemeColor === "Dark Green") {
            accent = "#288928";
        }
        else if (selectedThemeColor === "Light Green") {
            accent = "#65b032";
        }
        else if (selectedThemeColor === "Turquoise") {
            accent = "#288e80";
        }
        else if (selectedThemeColor === "Dark Red") {
            accent = "#ab283b";
        }
        else if (selectedThemeColor === "Light Red") {
            accent = "#e52939";
        }
        else if (selectedThemeColor === "Dark Pink") {
            accent = "#c52884";
        }
        else if (selectedThemeColor === "Light Pink") {
            accent = "#ee6694";
        }
        else if (selectedThemeColor === "Dark Blue") {
            accent = "#30519c";
        }
        else if (selectedThemeColor === "Light Blue") {
            accent = "#288dcf";
        }
        else if (selectedThemeColor === "Orange") {
            accent = "#ed5b28";
        }
        else if (selectedThemeColor === "Yellow") {
            accent = "#ed9728";
        }
        else if (selectedThemeColor === "Magenta") {
            accent = "#b857c6";
        }
        else if (selectedThemeColor === "Purple") {
            accent = "#825fb1";
        }
        else if (selectedThemeColor === "Dark Gray") {
            accent = "#5e5c5d";
        }
        else if (selectedThemeColor === "Light Gray") {
            accent = "#818181";
        }
        else if (selectedThemeColor === "Dark Gray") {
            accent = "#5e5c5d";
        }
        else if (selectedThemeColor === "Steel") {
            accent = "#768294";
        }
        else if (selectedThemeColor === "Stone") {
            accent = "#658780";
        }
        else if (selectedThemeColor === "Dark Brown") {
            accent = "#806044";
        }
        else if (selectedThemeColor === "Light Brown") {
            accent = "#7e715c";
        }

        return {
            main:               background,
            secondary:          _secondary,
            screenHeader:       _secondary,
            screenUnderline:    accent,
            underline:          accent,
            textTitle:          _textTitle,
            textLabel:          _textLabel,
            textSublabel:       _textSublabel,
            textSectionTitle:   accent,
            textValue:          _textLabel,
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

        //to know if Guide button still released
        property bool guideButtonPressed: false

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

        property alias source: theme.source
        readonly property url apiThemePath: api.internal.settings.themes.currentQmlPath
        onApiThemePathChanged: theme.source = Qt.binding(getThemeFile)

        Loader {
            id: theme
            anchors.fill: parent

            focus: true
            enabled: focus

            // Input releasing
            Keys.onReleased: {
                // Guide
                if (api.keys.isGuide(event) && !event.isAutoRepeat) {
                    //console.log("Keys.onReleased: api.keys.isGuide(event)");
                    event.accepted = true;
                    global.guideButtonPressed = false;
                }
            }

            // Input handling
            Keys.onPressed: {
                // Guide
                if (api.keys.isGuide(event) && !event.isAutoRepeat) {
                    //console.log("Keys.onPressed: api.keys.isGuide(event)");
                    event.accepted = true;
                    global.guideButtonPressed = true;
                }
                // Menu
                if (api.keys.isMenu(event) && !event.isAutoRepeat && !global.guideButtonPressed) {
                    //console.log("Keys.onPressed: api.keys.isMenu(event)");
                    event.accepted = true;
                    mainMenu.focus = true;
                }

                if (api.keys.isNetplay(event) && api.internal.recalbox.getBoolParameter("global.netplay") && !global.guideButtonPressed){
                    event.accepted = true;
                    subscreen.setSource("menu/settings/NetplayRooms.qml", {"isCallDirectly": true});
                    subscreen.focus = true;
                    content.state = "sub";
                }


                if (event.key === Qt.Key_F5) {
                    event.accepted = true;
                    pegasusReloadTheme();
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
                powerDialog.source = "dialogs/RebootDialog.qml";
                powerDialog.item.message = qsTr("The system will reboot. Are you sure?");
                powerDialog.focus = true;
            }
            function onRequestRestart() {
                powerDialog.source = "dialogs/RestartDialog.qml";
                powerDialog.item.message = qsTr("Pegasus will restart. Are you sure?");
                powerDialog.focus = true;
            }
            function onRequestRebootForSettings() {
                powerDialog.source = "dialogs/RebootDialog.qml";
                powerDialog.item.message = qsTr("Parameter(s) changed - the system needs to reboot to take into account.\nAre you sure?");
                powerDialog.focus = true;
            }
            function onRequestRestartForSettings() {
                powerDialog.source = "dialogs/RestartDialog.qml";
                powerDialog.item.message = qsTr("Parameter(s) changed - Pegasus needs to restart to take into account.\nAre you sure?");
                powerDialog.focus = true;
            }
            function onRequestQuit() {
                theme.source = "";
                api.memory.unset("repoStatusRefreshTime");
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
            //icon could be empty, with a icon code or with a reference to any layout
            //init parameters
            popup.title = title;
            popup.message = message;
            //getIcon() is used optionaly but icon should be set to empty string if not use
            //getIconFont is a global property to get font in same time of icon selected by the getIcon()
            //if empty we search icon from message and title
            if(icon === "") {
                //certainly popup dedicated to controller will be better finally - to do later
                popup.icon = getIcon(message,"");
                popup.iconfont = getIconFont;
            }
            else {
                //if hexa code including "\u"
                if(icon.toLowerCase().includes("\\u")){
                  popup.icon = icon;
                  popup.iconfont = globalFonts.sans; //default font
                }
                else{
                    //we have to search icon using sentence or layout keyword as "ps5", "ps4", "nes", etc...
                    popup.icon = getIcon(icon,"");
                    popup.iconfont = getIconFont;
                }
            }
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
                                     { "title": qsTr("New controller") + " : " + msg, "message": qsTr("Press any button to continue") + "\n(" + qsTr("please read instructions at the bottom of next view to understand possible actions") + "\n" + qsTr("mouse and keyboard could be used to help configuration") + ")" });
            genericMessage.focus = true;
        }
        function onEventLoadingStarted() {
            console.log("onEventLoadingStarted()");
            splashScreen.focus = true;
            loadingState = true;
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

    // SOUND EFFECTS
    // for use in menu set sfxNav.play()
    // only used for + / - volume indication
    // for this moment use the same sound of gameOs default theme
    SoundEffect {
        id: sfxNav
        source: "qrc:/frontend/assets/navigation.wav"
        volume: 1.0
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

    property int counter: 0 //counter use for debug
    property bool previousVirtualKeyboardVisibility: false
    property bool forcedSelectAll: false;
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
    //ADD HERE new ListElement to add new component updatable
    ListModel {
        id: componentsListModel
        ListElement { componentName: "Pegasus-frontend"; repoUrl:"https://api.github.com/repos/pixl-os/pegasus-frontend/releases";icon: "qrc:/frontend/assets/logopegasus.png"; picture: ""; multiVersions: false}
        ListElement { componentName: "Libretro FBNeo"; repoUrl:"https://api.github.com/repos/pixl-os/FBNeo/releases";icon:""; picture: ""; multiVersions: false}
        ListElement { componentName: "Libretro Mame"; repoUrl:"https://api.github.com/repos/pixl-os/mame/releases";icon:""; picture: ""; multiVersions: false}
        ListElement { componentName: "Xemu"; repoUrl:"https://api.github.com/repos/pixl-os/xemu/releases";icon:""; picture: ""; multiVersions: false}
        ListElement { componentName: "Supermodel"; repoUrl:"https://api.github.com/repos/pixl-os/Supermodel/releases";icon:""; picture: ""; multiVersions: false}
        ListElement { componentName: "Dolphin-emu"; repoUrl:"https://api.github.com/repos/pixl-os/dolphin/releases";icon:""; picture: ""; multiVersions: false}
        ListElement { componentName: "Pcsx2"; repoUrl:"https://api.github.com/repos/pixl-os/pcsx2/releases";icon:""; picture: ""; multiVersions: false}
        ListElement { componentName: "Citra-emu"; repoUrl:"https://api.github.com/repos/pixl-os/citra-nightly/releases";icon:""; picture: ""; multiVersions: false}
        ListElement { componentName: "shinretro"; repoUrl:"https://api.github.com/repos/pixl-os/shinretro/releases";icon:""; picture: ""; multiVersions: false}
        ListElement { componentName: "Nvidia driver"; repoLocal:"/recalbox/system/hardware/videocard/releases-nvidia.json";icon:"qrc:/frontend/assets/logonvidia.png"; picture: ""; multiVersions: true}
    }

    //to store and know if we are running in a pixL OS in Beta (For beta testing only) or Release version (Release include pre-release/public beta)
    property bool isBeta: false
    property bool isRelease: false

    Timer{ //timer to add pixL-OS Beta or Release component
        id: addUpdateTimer
        repeat: false
        running: true
        triggeredOnStart: true
        onTriggered: {
            //check version via recalbox.version
            //if "beta"/"release" terms are found
            isBeta = (api.internal.system.run("grep -i 'beta' /recalbox/recalbox.version") === "") ? false : true
            isRelease = (api.internal.system.run("grep -i 'release' /recalbox/recalbox.version") === "") ? false : true
            if(isRelease === true){// to propose release or pre-release in priority
                componentsListModel.append({ componentName: "pixL-OS", repoUrl:"https://updates.pixl-os.com/release-pixl-os.json",icon: "qrc:/frontend/assets/logo.png", picture: "qrc:/frontend/assets/backgroundpixl.png", multiVersions: false});
            }
            else if(isBeta === true){ // to propose beta only if we have already a beta version installed
                componentsListModel.append({ componentName: "pixL-OS (Beta)", repoUrl:"https://updates.pixl-os.com/beta-pixl-os.json",icon: "qrc:/frontend/assets/logobeta.png", picture: "qrc:/frontend/assets/backgroundpixl.png", multiVersions: false});
            }
            //stop timer
            addUpdateTimer.stop();
            //start other timers
            repoStatusRefreshTimer.start();
            updatePopupTimer.start();
        }
    }

    Timer {//timer to download last versions
        id: repoStatusRefreshTimer
        interval: 60000 * 30 // Check every 30 minutes and at start
        repeat: true
        running: false
        triggeredOnStart: true
        onTriggered: {
            var before = api.memory.get("repoStatusRefreshTime");
            console.log("repoStatusRefreshTime restored : ", before);
            //check if we restart the front end or not in the last 30 minutes
            //if before is empty, updates will be checked
            //if now is upper or equal than before + interval, updates will be checked
            //if now is less than before + interval, we do nothing
            if(Date.now() < (parseInt(before) + interval)){
                //do nothing, no check of repo, use only existing json from /tmp
            }
            else {
                //store info in memory and launch check of updates
                console.log("repoStatusRefreshTime saved :    ", Date.now());
                api.memory.set("repoStatusRefreshTime", Date.now());
                //loop to launch download of all json repository files
                for(var i = 0;i < componentsListModel.count; i++){
                    if((typeof(componentsListModel.get(i).repoUrl) !== "undefined") && (componentsListModel.get(i).repoUrl !== ""))
                    {
                        api.internal.updates.getRepoInfo(componentsListModel.get(i).componentName,componentsListModel.get(i).repoUrl);
                    }
                    else if((typeof(componentsListModel.get(i).repoLocal) !== "undefined") && (componentsListModel.get(i).repoLocal !== ""))
                    {
                        api.internal.updates.getRepoInfo(componentsListModel.get(i).componentName,componentsListModel.get(i).repoLocal);
                    }
                }
            }
            //start timer to check one minute later the result
            jsonStatusRefreshTimer.running = false;
            jsonStatusRefreshTimer.running = true;
        }
    }

    property int numberOfUpdates: 0
    property string listOfUpdates : ""
    Timer {//timer to check json after download
        id: jsonStatusRefreshTimer
        interval: 20000 // check after 20 seconds now
        repeat: false // no need to repeat
        running: false
        triggeredOnStart: false
        onTriggered: {
            for(var i = 0;i < componentsListModel.count; i++){
                //check all components (including pre-release for the moment and without filter)
                numberOfUpdates = 0;
                listOfUpdates = "";
                var updateVersionIndexFound = api.internal.updates.hasUpdate(componentsListModel.get(i).componentName , isBeta, (typeof(componentsListModel.get(i).multiVersions) !== "undefined") ? componentsListModel.get(i).multiVersions : false );
                if(updateVersionIndexFound !== -1){
                    numberOfUpdates = numberOfUpdates + 1;
                    componentsListModel.setProperty(i,"hasUpdate", true);
                    componentsListModel.setProperty(i,"hasInstallNotified", false);
                    componentsListModel.setProperty(i,"UpdateVersionIndex", updateVersionIndexFound);
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


    Timer{ //timer to check status of updates (installed or not) and popup message if needed
        id: updatePopupTimer
        interval: 10000 // check every 10 seconds - one by one popup
        repeat: true // repeat to check regularly
        running: false
        triggeredOnStart: false
        onTriggered: {
            if(api.internal.updates.hasAnyUpdate()){
                //search if any udpate is not install or installed with additional actions as restart/reboot/retry
                for(var i=0; i < componentsListModel.count ;i++){
                    var item = componentsListModel.get(i);
                    if(typeof(item.hasUpdate) !== "undefined"){
                        if(item.hasUpdate === true){
                            if(item.hasInstallNotified === false){
                                var installError = api.internal.updates.getInstallationError(item.componentName);
                                var installProgress = api.internal.updates.getInstallationProgress(item.componentName);
                                //check if installed or error detected
                                if((installProgress === 1.0) || (installError > 0)){
                                    //to popup to alert about this udpate
                                    //init parameters
                                    popup.title = item.componentName;
                                    if(installError === 0){
                                        popup.message = qsTr("Update done !");
                                    }
                                    else if(installError === -1){
                                        popup.message = qsTr("Update done, need restart !");
                                    }
                                    else if(installError === -2){
                                        popup.message = qsTr("Update done, need reboot !");
                                    }
                                    else if(installError > 0){
                                        popup.message = qsTr("Update failed !");
                                    }
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
                                    //deactivate update to confirm that's one is install and without operation to do
                                    componentsListModel.setProperty(i,"hasInstallNotified", true);
                                    break;
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    //***********************************************************END OF UPDATES PARTS*******************************************************************

    //***********************************************************BEGIN OF BLUETOOTH RESTART*************************************************************
    Timer {//timer to restart bluetooth service and power on
        id:bluetoothRestartTimer
        interval: 2000 //to be sure to restart after initial loading started only...
        repeat: false // no need to repeat
        running: api.internal.recalbox.getBoolParameter("controllers.bluetooth.startreset")  && loadingState
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

    //***********************************************************BEGIN OF DATA MODELS*******************************************************************
    //list model to manage type of devices
    ListModel {
        id: myDeviceTypes
        ListElement { type: "controller"; keywords: "controller,gamepad,stick"} //as XBOX for the moment, need icon for 360
        ListElement { type: "audio"; keywords: "audio,av,headset,speaker"} //as XBOX for the moment, need icon for 360
    }
    //list model to manage icons of devices
    ListModel {
        id: myDeviceIcons //now include also layout definition

        //CONTROLLERS PART
        ListElement { icon: "\uf2ef"; keywords: "x360,xbox360,xbox 360,x-box 360"; type:"controller"; iconfont: "awesome"; layout: "xbox360"} //as XBOX for the moment, need icon for 360
        ListElement { icon: "\uf2f0"; keywords: "xboxone,xbox one,x-box one"; type:"controller"; iconfont: "awesome"; layout: "xboxone"}
        ListElement { icon: "\uf2f0"; keywords: "xbox series"; type:"controller"; iconfont: "awesome"} //as XBOX one for the moment, need icon for series
        ListElement { icon: "\uf2ee"; keywords: "xbox,microsoft"; type:"controller"; iconfont: "awesome"} //as XBOX for the moment

        ListElement { icon: "\uf0cf"; keywords: "ps5,playstation 5,dualsense,wireless controller"; type:"controller"; iconfont: "awesome"; layout: "ps5"} // add wireless controller as usual PS name used by Sony
        ListElement { icon: "\uf2ca"; keywords: "ps4,playstation 4,dualshock 4,wireless controller"; type:"controller"; iconfont: "awesome"; layout: "ps4"} // add wireless controller as usual PS name used by Sony
        ListElement { icon: "\uf2c9"; keywords: "ps3,playstation 3,dualshock 3"; type:"controller"; iconfont: "awesome"}
        ListElement { icon: "\uf2c8"; keywords: "ps2,playstation 2,dualshock 2"; type:"controller"; iconfont: "awesome"}
        ListElement { icon: "\uf275"; keywords: "ps1,psx,playstation,dualshock 1"; type:"controller"; iconfont: "awesome"}

        ListElement { icon: "\uf26a"; keywords: "mastersystem,master system"; type:"controller"; iconfont: "awesome"}
        ListElement { icon: "\uf26b"; keywords: "megadrive,mega drive,md/gen,sega genesis"; type:"controller"; iconfont: "awesome"}

        ListElement { icon: "\uf25e"; keywords: "snes,super nintendo"; type:"controller"; iconfont: "awesome"; layout: "snes"}
        ListElement { icon: "\uf25c"; keywords: "nes,nintendo entertainment system"; type:"controller" ; iconfont: "awesome"; layout: "nes"}
        ListElement { icon: "\uf262"; keywords: "gc,gamecube"; type:"controller"; iconfont: "awesome"}
        //huijia added for n64 due to mayflash n64 controller adapter v1 detected as "HuiJia  USB GamePad"
        //other hujia devices exists for NES, SNES and gamecube, but will be detected upper if needed.
        ListElement { icon: "\uf260"; keywords: "n64,nintendo 64,nintendo64,huijia"; type:"controller" ; iconfont: "awesome"; layout: "n64"}
        ListElement { icon: "\uf263"; keywords: "wii"; type:"controller"; iconfont: "awesome"}
        //need to keep only 'pro controller' in case of nintendo switch pro controller as it is the HID name (internal name)
        //in the future, we have other controller as "pro controller", the layout detection should be complexified
        ListElement { icon: "\uf0ca"; keywords: "pro controller"; type:"controller"; iconfont: "awesome";  layout: "switchpro"}
        ListElement { icon: "\uf0c8"; keywords: "joy-con (l)"; type:"controller"; iconfont: "awesome"}
        ListElement { icon: "\uf0c9"; keywords: "joy-con (r)"; type:"controller"; iconfont: "awesome"}


        //27/02/2022 2 controllers added snakebyte idroid:con and 8bitdo sn30 pro+
        ListElement { icon: "\uf0cb"; keywords: "idroid"; type:"controller"; iconfont: "awesome"}
        ListElement { icon: "\uf0cc"; keywords: "8bitdo sn30 pro+,8bitdo sn30 pro plus,8bitdo pro 2"; type:"controller"; iconfont: "awesome"}

        //28/02/2022 to add wheels/cockpit devices
        ListElement { icon: "\uf0c7"; keywords: "cockpit,wheel"; type:"controller"; iconfont: "awesome"}

        //28/02/2022 to add arcade panel device
        //2 codes exists "\uf0cd" & "\uf0ce", respectivelly fill and transparent version
        ListElement { icon: "\uf0cd"; keywords: "dragonrise,xinmo,xin-mo,j-pac,jpac"; type:"controller"; iconfont: "awesome"}

        //AUDIO PART
        //add here specific headset tested, keep it in lowercase and as displayed in bluetooth detection
        //04/10/21: add 'plt focus'
        //06/10/21: add 'qcy50' and 'jbl go'
        ListElement { icon: "\uf1e2"; keywords: "headset,plt focus,qcy50,jbl go"; type:"audio"; iconfont: "awesome"}
        ListElement { icon: "\uf1e1"; keywords: "speaker"; type:"audio"; iconfont: "awesome"}
        ListElement { icon: "\uf1b0"; keywords: ""; types:"audio"; iconfont: "awesome"} //as generic icon for audio

    }
    //little function to faciliate check of value in 2 name and service from a keyword
    function isKeywordFound(name,service,keyword){
        if(typeof(name) !== "undefined" && typeof(service) !== "undefined"){
            if(name.toLowerCase().includes(keyword)||service.toLowerCase().includes(keyword)){
                return true;
            }
            else return false;
        }
        else return false
    }

    //to change icon size for audio ones especially and keep standard one for others.
    function getIconRatio(icon){
        var ratio;
        switch(icon){
        case "\uf1e2":
            ratio = 2;
            break;
        case "\uf1e1":
            ratio = 2;
            break;
        case "\uf1b0":
            ratio = 2;
            break;
        case "\uf0c8":
            ratio = 2.5
            break;
        case "\uf0c9":
            ratio = 2.5
            break;
        default:
            ratio = 3;
            break;
        }
        return ratio;
    }
    property string getIconFont : globalFonts.sans //default value
    //function to dynamically set icon "character" from name and/or service
    function getIcon(name,service){
        var icon = "";
        let type = "";
        let i = 0;
        //search icon from name equal to layout value
        do{
            const layout = myDeviceIcons.get(i).layout;
            if(layout === name){
                icon = myDeviceIcons.get(i).icon;
                if (myDeviceIcons.get(i).iconfont === "awesome") getIconFont = globalFonts.awesome;
                else if (myDeviceIcons.get(i).iconfont === "ion") getIconFont = globalFonts.ion;
                else getIconFont = globalFonts.sans; //as default one for the moment
            }
            i = i + 1;
        }while (icon === "" && i < myDeviceIcons.count)
        //check if any icon has been found
        if(icon !== "") return icon;
        //reset counter
        i = 0;
        //search the good type
        do{
            const typeKeywords = myDeviceTypes.get(i).keywords.split(",");
            for(var j = 0; j < typeKeywords.length;j++)
            {
                if (isKeywordFound(name, service, typeKeywords[j])) type = myDeviceTypes.get(i).type;
            }
            i = i + 1;
        }while (type === "" && i < myDeviceTypes.count)
        //reset counter
        i = 0;
        //searchIcon using the good type
        do{
            const iconKeywords = myDeviceIcons.get(i).keywords.split(",");
            for(var k = 0; k < iconKeywords.length;k++)
            {
                //split name that could contain the name + hid name separated by ' - '
                const names = name.split(" - ");
                if(names.length >= 2){
                    name = names[1]; //to keep only the hid part if exist
                }
                if (isKeywordFound(name, service, iconKeywords[k]) && (myDeviceIcons.get(i).type === type || ((type === "") && (iconKeywords[k] !== "")))){
                    icon = myDeviceIcons.get(i).icon;
                    if (myDeviceIcons.get(i).iconfont === "awesome") getIconFont = globalFonts.awesome;
                    else if (myDeviceIcons.get(i).iconfont === "ion") getIconFont = globalFonts.ion;
                    else getIconFont = globalFonts.sans; //as default one for the moment
                }
            }
            i = i + 1;
        }while (icon === "" && i < myDeviceIcons.count)

        return icon;
    }


    //***********************************************************END OF DATA MODELS*********************************************************************

    //***********************************************************BEGIN OF GENERIC FUNCTIONS ACCESSIBLE ALSO FOR THEMES*************************************************************
    function getThemeFile() {
        if (api.internal.meta.isLoading)
            return "";
        if (api.collections.count === 0)
            return "messages/NoGamesError.qml";
        return content.apiThemePath;
    }

    function pegasusReloadTheme(){
        //unload theme
        content.source = "";
        //clear qml cache
        api.internal.meta.clearQMLCache();
        //clear javascript garbage collector
        gc();
        api.internal.system.run("sleep 1");
        //reload theme
        content.source = Qt.binding(getThemeFile);
    }
    //***********************************************************END OF GENERIC FUNCTIONS ACCESSIBLE ALSO FOR THEMES***************************************************************

}
