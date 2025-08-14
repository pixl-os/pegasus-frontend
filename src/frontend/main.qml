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
import QtMultimedia 5.15
import "dialogs"
import "global"
import "menu/settings/common"
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

    //TIPS: properties to preload during launch of pegasus-fe and avoid "slow" effect during loading of menus
    property string preload_global_shaders: api.internal.recalbox.parameterslist.currentName("global.shaders")
    property string preload_boot_sharedevice: api.internal.recalbox.parameterslist.currentName("boot.sharedevice")
    property string preload_teknoparrot_wine: api.internal.recalbox.parameterslist.currentName("teknoparrot.wine")
    property string preload_teknoparrot_wineappimage: api.internal.recalbox.parameterslist.currentName("teknoparrot.wineappimage")

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
        property bool buttonLongPress: false

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
        anchors.leftMargin: sindenInnerBorderRectangle.border.width + sindenOuterBorderRectangle.border.width
        anchors.rightMargin: sindenInnerBorderRectangle.border.width + sindenOuterBorderRectangle.border.width
        anchors.topMargin: sindenInnerBorderRectangle.border.width + sindenOuterBorderRectangle.border.width
        anchors.bottomMargin: sindenInnerBorderRectangle.border.width + sindenOuterBorderRectangle.border.width

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
                    event.accepted = true;
                    timerButtonPressed.stop()
                    global.guideButtonPressed = false;
                    global.buttonLongPress = false;
                }
                // Netplay
                else if (api.keys.isNetplay(event) && !event.isAutoRepeat && !global.guideButtonPressed && !global.buttonLongPress){
                    //console.log("Keys.onReleased: api.keys.isNetplay(event)");
                    event.accepted = true;

                    //set fullscreen due to "large" buttons
                    subdialog.fullscreen = true;
                    subdialog.setSource("menu/settings/NetplayRooms.qml", {"isCallDirectly": true});
                    subdialog.focus = true;
                    //subscreen.setSource("menu/settings/NetplayRooms.qml", {"isCallDirectly": true});
                    //subscreen.focus = true;
                    //content.state = "sub";

                    //stop longpress timer also to avoid border effect
                    timerButtonPressed.stop()
                    global.guideButtonPressed = false;
                    global.buttonLongPress = false;
                }
            }

            Timer {
              id: timerButtonPressed
              interval: 1000 // more than 1 second press is considered as long press
              running: false
              triggeredOnStart: false
              repeat: false
              onTriggered: {
                  global.buttonLongPress = true;
              }
            }

            // Input handling
            Keys.onPressed: {
                //if (api.keys.isGuide(event)) console.log("Keys.onPressed: saw as guide");
                //if (api.keys.isNetplay(event)) console.log("Keys.onPressed: saw as netplay");
                //start timer to detect button long press
                if((global.buttonLongPress == false) && (timerButtonPressed.running  == false))  timerButtonPressed.restart();
                // Guide
                if (api.keys.isGuide(event) && !event.isAutoRepeat) {
                    //console.log("Keys.onPressed: api.keys.isGuide(event)");
                    event.accepted = true;
                    global.guideButtonPressed = true
                }
                // Netplay
                else if (api.keys.isNetplay(event) && !event.isAutoRepeat && !global.guideButtonPressed && global.buttonLongPress){
                    event.accepted = true;
                    //reset long press in this case
                    timerButtonPressed.stop()
                    global.buttonLongPress = false;
                }
                // Menu(s)
                else if (api.keys.isMenu(event) && !event.isAutoRepeat) {
                    //console.log("Keys.onPressed: api.keys.isMenu(event)");
                    event.accepted = true;

                    var lastAction = api.internal.system.currentAction();
                    var lastGame;
                    var lastCollection;
                    if(lastAction === "gamelistbrowsing"){ //to open a "system" menu (with selected game included)
                        //case when we browse in a listview/gridview
                        lastCollection = api.internal.system.currentCollection();
                        //set not fullscreen due to be more like a popup dialogbox
                        subdialog.fullscreen = false;
                        subdialog.setSource("menu/settings/SystemsEmulatorConfiguration.qml", {"system": lastCollection, "launchedAsDialogBox": true});
                        subdialog.focus = true;
                    }
                    else if(lastAction === "gameviewselected"){ //to open a "game" menu only (to update override .cfg file)
                        //case when we select a view focus on a game (not in listview/gridview or other collections)
                        lastCollection = api.internal.system.currentCollection();
                        lastGame = api.internal.system.currentGame();
                        //set not fullscreen due to be more like a popup dialogbox
                        subdialog.fullscreen = false;
                        subdialog.setSource("menu/settings/SystemsEmulatorConfiguration.qml", {"system": lastCollection, "game": lastGame , "launchedAsDialogBox": true});
                        subdialog.focus = true;
                    }
                    else{ //default "general" menu by default
                        mainMenu.focus = true;
                    }
                }
                //To refresh theme
                else if (event.key === Qt.Key_F5) {
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
                api.internal.recalbox.setStringParameter("updates.lastchecktime", "")
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
            id: subdialog
            asynchronous: true
            opacity: focus ? 1 : 0
            property bool fullscreen: true
            property real screenratio: fullscreen ? 1.0 : 0.8
            width: parent.width * screenratio
            height: parent.height * screenratio
            scale: focus ? 1.0 : 0

            Behavior on opacity { PropertyAnimation { duration: 500 } }
            Behavior on scale { NumberAnimation { duration: 500; easing.type: Easing.Linear }
            }

            anchors.centerIn: parent

            Rectangle {
                anchors.fill: parent
                color: themeColor.main
                z: -1
            }
            visible: focus
            enabled: focus
            onLoaded: item.focus = focus
            onFocusChanged: if (item) item.focus = focus
        }
        Connections {
            target: subdialog.item
            function onClose() {
                content.focus = true;
                content.state = "";
                theme.visible = true;
                theme.focus = true;
            }
        }

        Loader {
            id: subscreen
            asynchronous: true

            width: parent.width
            height: parent.height
            anchors.left: content.right

            Rectangle {
                anchors.fill: parent
                color: themeColor.main
                z: -1
            }

            visible: focus
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

    //cdRomDialogBox loader/connection/component/timer
    Loader {
        id: cdRomDialogBoxLoader
        anchors.fill: parent
        sourceComponent: cdRomDialogBox
    }
    Connections {
        target: cdRomDialogBoxLoader.item

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
        id: cdRomDialogBox
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
        id: cdRomDialogBoxTimer

        interval: 5000
        triggeredOnStart: false
        repeat: true
        running: splashScreen.focus ? false : true
        onTriggered: {
            var CdConf = api.internal.system.run("grep -s -e 'system =' /tmp/cd.conf | tr -d '\\n' | tr -d '\\r'");
            //console.log("CdConf : ", CdConf)
            if(CdConf.includes("system =")) {
                gameCdRom = CdConf.split(' ')[2];
                //console.log("gameCdRom : ", gameCdRom)
                cdRomDialogBoxLoader.visible = true;
                cdRomDialogBoxLoader.focus = true;
                //just set "cdrom" as title of this game (optional)
                api.internal.singleplay.setTitle("cdrom");
                //read CDROM.device file to know last drive index inserted + add 1 for retroarch indexes
                var driveIndex = parseInt(api.internal.system.run("grep -i '/sr' /tmp/CDROM.device | tr -d '\\n' | tr -d '\\r'").split('r')[1]) + 1;
                //console.log("File: cdrom://drive" + driveIndex.toString() + ".cue");
                //set rom full path
                api.internal.singleplay.setFile("cdrom://drive" + driveIndex.toString() + ".cue");
                //set system to select to run this rom
                api.internal.singleplay.setSystem(gameCdRom); //using shortName
            }
            else{
                gameCdRom = "";
                cdRomDialogBoxLoader.focus = false;
                cdRomDialogBoxLoader.visible = false;
            }
        }
    }

    //cartridge loader/connection/component/timer
    Loader {
        id: cartridgeDialogBoxLoader
        anchors.fill: parent
        sourceComponent: cartridgeDialogBox
    }
    Connections {
        target: cartridgeDialogBoxLoader.item

        function onAccept() {
            content.focus = true;            
            //copy save game from cartridge to saves "share" directory
            //For usbnes case (using nes system only and one file name for sav)
            var romcrc32 = "";
            var targetedSave = "";
            var targetedRom = "";
            var existingSave = "";
            if(gameCartridge_save.includes("rom.sav") && api.internal.recalbox.getBoolParameter("dumpers.usbnes.movesave",false)){
                //get crc32 to ahve it in name of files as reference to improve unicity
                romcrc32 = api.internal.system.run("cat /tmp/USBNES.romcrc32 | tr -d '\\n' | tr -d '\\r'");
                //rename .sav to .srm to be compatible with retroarch cores and need to have same name than rom ;-)
                targetedSave = "/recalbox/share/saves/" + gameCartridge_system + "/" + gameCartridge_name + " (" + gameCartridge_region + ")" + " (" + gameCartridge_type + ") [" + romcrc32.split(' ')[0] + "].srm";
                targetedRom = "/recalbox/share/extractions/" + gameCartridge_name + " (" + gameCartridge_region + ")" + " (" + gameCartridge_type + ") [" + romcrc32.split(' ')[0] + "].nes";
                existingSave = api.internal.system.run("ls '"+ targetedSave + "' 2>/dev/null  | tr -d '\\n' | tr -d '\\r'");
                //for the moment: we don't recopy save if already exists for this rom / no proposal to erase in this case
                //manual move/erase to do in share saves directory in this case
                if(!existingSave.includes("/recalbox/share/saves/")){
                    //copy of save
                    api.internal.system.run("cp '" + gameCartridge_save + "' '" + targetedSave + "'");
                }
                //mandatory copy of rom in /extractions to be able to rename rom (.nes) and to match with targeted save file (.srm) (we will erase in this case if already exists)
                //copy of rom
                api.internal.system.run("cp '" + gameCartridge_rom + "' '" + targetedRom + "'");
                //need to reset rom full path in this case
                api.internal.singleplay.setFile(targetedRom);
            }
            //For retrode case (using multiple systems) and not as usbnes ;-)
            else if((gameCartridge_save !== "") & !gameCartridge_save.includes("rom.sav") && api.internal.recalbox.getBoolParameter("dumpers.retrode.movesave",false)){
                //get crc32 to ahve it in name of files as reference to improve unicity
                romcrc32 = api.internal.system.run("cat /tmp/RETRODE.romcrc32 | tr -d '\\n' | tr -d '\\r'");
                //copy with existing extension for the moment to retroarch cores and need to have same name than rom but just adding CRC32 ;-)
                var resultArray = gameCartridge_rom.split("/");
                var filename = resultArray[resultArray.length -1]; // Get the last component of the path
                // Regular expression to match file name and extension
                var regex = new RegExp("(.+?)(\.[^\.]+)$");
                // Apply the regular expression to the file name
                var match = regex.exec(filename);
                // If a match is found, extract the file name and extension
                var romExt = "";
                var romName = "";
                if (match) {
                    romName = match[1];
                    romExt = match[2];
                }
                resultArray = gameCartridge_save.split("/");
                filename = resultArray[resultArray.length -1]; // Get the last component of the path
                //force every save file to use .srm extension for the moment when we move it and use it with in retroarch
                var savExt = ".srm";
                //RFU
                // Apply the regular expression to the file name
                //match = regex.exec(filename);
                // If a match is found, extract the file name and extension
                //var savExt = "";
                //var savName = "";
                //if (match) {
                //    savName = match[1];
                //    savExt = match[2];
                //}
                targetedSave = "/recalbox/share/saves/" + gameCartridge_system + "/" + romName + " [" + romcrc32.split(' ')[0] + "]" + savExt;
                targetedRom = "/recalbox/share/extractions/" + romName + " [" + romcrc32.split(' ')[0] + "]" + romExt;
                existingSave = api.internal.system.run("ls '"+ targetedSave + "' 2>/dev/null  | tr -d '\\n' | tr -d '\\r'");
                //for the moment: we don't recopy save if already exists for this rom / no proposal to erase in this case
                //manual move/erase to do in share saves directory in this case
                if(!existingSave.includes("/recalbox/share/saves/")){
                    //copy of save
                    api.internal.system.run("cp '" + gameCartridge_save + "' '" + targetedSave + "'");
                }
                //mandatory copy of rom in /extractions to be able to rename rom nd to match with targeted save file (we will erase in this case if already exists)
                //copy of rom
                api.internal.system.run("cp '" + gameCartridge_rom + "' '" + targetedRom + "'");
                //need to reset rom full path in this case
                api.internal.singleplay.setFile(targetedRom);
            }
            // connect game to launcher
            api.connectGameFiles(api.internal.singleplay.game);
            // launch this Game
            api.internal.singleplay.game.launch();
        }
        function onCancel() {
            // return back and remove tmp file
            content.focus = true;
        }
    }

    property string gameCartridge: ""
    property string gameCartridge_name: ""
    property string gameCartridge_state: "" //as "unknown","identified","reloaded","unplugged" and "disconnected"
    property string gameCartridge_system: ""
    property string gameCartridge_type: ""
    property string gameCartridge_region: "" //contains initial region identified from rom
    property string gameCartridge_region_regex: "" //contains the regex to search by region in collections (especially for NESDB 2.0 for the moment)
    property string gameCartridge_crc32: "" //use for SNES/SFC for the moment
    property string gameCartridge_save: "" //to know file path of save file
    property string gameCartridge_rom: "" //to know file path of rom file

    property string usbnesVersion: "" //to store version at mount
    property string retrodeVersion: "" //to store version at mount

    Component {
        id: cartridgeDialogBox
        CartridgeDialog
        {
            focus: true
            message: qsTr("A game is in the cartridge reader") + ":<br>" + gameCartridge //on 2 lines now
            firstchoice: qsTr("Launch")
            secondchoice: ""
            thirdchoice: qsTr("Back")
            game_crc32: gameCartridge_crc32
            game_region: gameCartridge_region_regex
            game_system: gameCartridge_system
            game_type: gameCartridge_type
            game_state: gameCartridge_state
            game_name: gameCartridge_name
            game_save: gameCartridge_save
        }
    }

    //list model to manage regions (example from NES 2.0 DB xml to NoIntro ones)... bu we can't manage 'exotic ones' ;-)
    ListModel {
        id: regionSSModel
        ListElement { region: "eu"; regex: "\\(.*europe.*\\)|\\[.*europe.*\\]"; nes20db: "PAL"}
        ListElement { region: "jp"; regex: "\\(.*japan.*\\)|\\[.*japan.*\\]"; nes20db: "Japan"}
        ListElement { region: "us"; regex: "\\(.*usa.*\\)|\\[.*usa.*\\]"; nes20db: "North America"}
        ListElement { region: "ch"; regex: "\\(.*china.*\\)|\\[.*china.*\\]"; nes20db: "China"}
        ListElement { region: "wor"; regex: "\\(.*world.*\\)|\\[.*world.*\\]"; nes20db: "Elsewhere"}
    }

    //List of RETRODE SYSTEM (order is important, should be like in RETRODE.CFG
    property string retrode_systems_list : "snes,megadrive,n64,gb|gbc,gba,mastersystem,gamegear"

    function getRegionIndex(nes20dbname){
        for(var i = 0; i < regionSSModel.count; i++){
            if(nes20dbname === regionSSModel.get(i).nes20db){
                return i;
            }
        }
        return -1; //return if not found
    }

    // Timer to show the dialog box for cartridge (USB-NES)
    Timer {
        id: dialogBoxUSBNESTimer
        interval: 5000
        triggeredOnStart: false
        repeat: true
        running: (splashScreen.focus) ? false : true
        property bool cartridge_plugged: false
        onTriggered: {
            if (!api.internal.recalbox.getBoolParameter("dumpers.usbnes.enabled",false)){
                //do nothing if not enabled but we keep timer running for detection
                return;
            }
            var mountpoint = api.internal.system.run("cat /tmp/USBNES.mountpoint 2>/dev/null | tr -d '\\n' | tr -d '\\r'");
            //console.log("USB-NES mountpoint : ", mountpoint)
            if(mountpoint.includes("/usb")) {
                //console.log("USB-NES cartridge plugged: ", cartridge_plugged)
                //check any change ?
                var readflag = api.internal.system.run("cat " + mountpoint + "/pixl-read.flag" + " | tr -d '\\n' | tr -d '\\r'");
                //console.log("USB-NES readflag: ", readflag);
                if(readflag !== "true"){
                    //get size of the rom detected
                    var romsize = api.internal.system.run("wc -c "+ mountpoint + "/rom.nes  | tr -d '\\n' | tr -d '\\r'");
                    //console.log("USB-NES romsize: ", romsize)
                    //get previous crc32 if exists (including complete path of rom) to be able to compare it with previous one
                    var previousromcrc32 = api.internal.system.run("cat /tmp/USBNES.romcrc32 | tr -d '\\n' | tr -d '\\r'");
                    //console.log("USB-NES previousromcrc32: ", previousromcrc32)
                    //generate crc32 of the rom detected (including complete path of rom) to be able to compare it with previous one
                    //(don't try to match with screenscrapper one where header is added and/or done on zip file)
                    var romcrc32 = api.internal.system.run("crc32 " + mountpoint + "/rom.nes | tr -d '\\n' | tr -d '\\r'");
                    //console.log("USB-NES romcrc32: ", romcrc32)
                    if((parseInt(romsize) > 16)){
                        cartridge_plugged = true;
                        if(romcrc32 === previousromcrc32){
                            gameCartridge_state = "reloaded";
                            //show popup to say that is a reset
                            apiconnection.onShowPopup(qsTr("Video game cartridge reader"), qsTr("USB-NES cartridge reloaded"),"",2);
                        }
                        //just set "cartridge" as title of this game (optional)
                        api.internal.singleplay.setTitle("cartridge");
                        //set rom full path
                        gameCartridge_rom = mountpoint + "/rom.nes";
                        api.internal.singleplay.setFile(gameCartridge_rom);
                        //set system to select to run this rom
                        api.internal.singleplay.setSystem("nes"); //using shortName
                        //store new crc32 (including complete path of rom) and store it for the moment
                        api.internal.system.run("echo '" + romcrc32 + "' | tr -d '\\n' | tr -d '\\r' > /tmp/USBNES.romcrc32");
                        //RFU: generate md5 (including complete path of rom) and store it for the moment
                        //api.internal.system.run("md5sum " + mountpoint + "/rom.nes | tr -d '\\n' | tr -d '\\r' > /tmp/USBNES.rommd5");
                        //calculate sha1 for PRG-ROM/SHR-ROM (don't try to match with screenscrapper one where it's done on full .nes/.zip file and including header)
                        var romsha1=api.internal.system.run("python3 /recalbox/scripts/nes_tools/nes_header_tools.py " + mountpoint + " rom.nes | tr -d '\\n' | tr -d '\\r'");
                        //console.log("USB-NES romsha1: ", romsha1);
                        //get info from nes 2.0 DB xml file
                        var rominfo=api.internal.system.run("grep -i " + romsha1 + " /recalbox/scripts/nes_tools/nes20db.xml -A4 -B3 | grep -i '<game>' | sed -n 's/.*<!-- \\(.*\\).nes.*/\\1/p' | tr -d '\\n' | tr -d '\\r'");
                        //console.log("USB-NES rominfo: ", rominfo);
                        if(rominfo !== ""){
                            //check also if sav game exist
                            var savinfo=api.internal.system.run("ls "+ mountpoint + "/rom.sav 2>/dev/null  | tr -d '\\n' | tr -d '\\r'");
                            //console.log("USB-NES savinfo: ", savinfo);
                            var savinfoflag = "N";
                            gameCartridge_save = "";
                            if(savinfo !== ""){
                                savinfoflag = "Y";
                                //just communicate that sav is available
                                gameCartridge_save = mountpoint + "/rom.sav";
                            }
                            gameCartridge_state = "identified";
                            gameCartridge = rominfo;
                            //rominfo.split('\\')[1] + " (" + rominfo.split('\\')[0].split(" ")[1] + ")" + " - " + rominfo.split('\\')[0].split(" ")[0];
                            //to take first part that could contain type (licenced/playchoise/Vs. System/unlicensed...) and region (optionaly: PAL, North America, Japan, China, Taiwan & HongKong, ElseWhere, South Korea...)
                            //we will manage only cartdridge format and what we ahve with no-intro ;-)
                            var type_region = rominfo.split('\\')[0];
                            //console.log("USB-NES type_region: ", type_region);
                            gameCartridge_type = type_region.split(' ')[0];
                            //console.log("USB-NES gameCartridge_type: ", gameCartridge_type);
                            gameCartridge_region = type_region.replace(gameCartridge_type,"");
                            //finally we trim region here for later
                            var regex = RegExp("^\\s*(.*?)\\s*$");
                            gameCartridge_region = gameCartridge_region.replace(regex, "$1");
                            //console.log("USB-NES region: '",gameCartridge_region,"'");
                            if(gameCartridge_region !== ""){
                                var region_index = getRegionIndex(gameCartridge_region);
                                if(region_index !== -1){
                                    gameCartridge_region_regex = regionSSModel.get(region_index).regex;
                                }
                                else gameCartridge_region_regex = "";
                            }
                            else gameCartridge_region_regex = "";
                            //check if option to save rominfo/sha1 is requested
                            if(api.internal.recalbox.getBoolParameter("dumpers.usbnes.romlist",false)){
                                var existingFile = ""
                                existingFile = api.internal.system.run("ls /recalbox/share/roms/usb-nes.romlist.csv 2>/dev/null | tr -d '\\n' | tr -d '\\r'");
                                if(!existingFile.includes("usb-nes.romlist.csv")){
                                    //if no file exists, let create it with column titles
                                    api.internal.system.run("echo 'GAME TITLE;REGION;TYPE;WORKS;SAVE FOUND;SHA1 for PRG-ROM/SHR-ROM;DUMPER VERSION;WHEN;COMMENT' >> /recalbox/share/roms/usb-nes.romlist.csv");
                                }

                                var existingRom = ""
                                existingRom = api.internal.system.run("grep -i " + romsha1 + " /recalbox/share/roms/usb-nes.romlist.csv | tr -d '\\n' | tr -d '\\r'");
                                //console.log("existingRom : ",existingRom);
                                if(existingRom === ""){
                                    //format GAME TITLE,REGION,TYPE,WORKS,SAVE FOUND;SHA1 for PRG-ROM/SHR-ROM,DUMPER VERSION,WHEN,COMMENT
                                    var now = new Date();
                                    var formattedDateTime = now.toString("yyyy-MM-dd hh:mm:ss");
                                    //console.log("Formatted date and time:", formattedDateTime);
                                    if(usbnesVersion === ""){
                                        //read USB-NES version and store it in global variable
                                        usbnesVersion = api.internal.system.run("cat " + mountpoint + "/version.txt | grep -o '[^[:space:]]*' | tr '\\n' ' '");
                                    }
                                    //console.log('echo "' + rominfo.split('\\')[1] + ';' + region + ';' + gameCartridge_type + ';' +  'Y' + ';' + savinfoflag + ';' +  romsha1 + ';' + usbnesVersion  + ';' + formattedDateTime + ';' + 'no comment for the moment' + '" >> /recalbox/share/roms/usb-nes.romlist.csv');
                                    api.internal.system.run('echo "' + rominfo.split('\\')[1] + ';' + region + ';' + gameCartridge_type + ';' +  'Y' + ';' + savinfoflag + ';' +  romsha1 + ';' + usbnesVersion  + ';' + formattedDateTime + ';' + 'no comment for the moment' + '" >> /recalbox/share/roms/usb-nes.romlist.csv');

                                }
                            }
                            gameCartridge_system = "nes";
                            //to do last because will trig changes
                            gameCartridge_crc32 = "";
                            //remove data between [] and () in name as: (rev 1), (rev 2)
                            regex = /\([^()]*\)|\[[^\]]*\]/;
                            gameCartridge_name = rominfo.split('\\')[1].replace(regex, "");
                            //dump of rom if request
                            if(api.internal.recalbox.getBoolParameter("dumpers.usbnes.savedump",false)){
                                var targetedDump = "/recalbox/share/dumps/" + gameCartridge_name + " (" + gameCartridge_region + ")" + " (" + gameCartridge_type + ") [" + romcrc32.split(' ')[0] + "].nes";
                                //console.log("ls '"+ targetedDump + "' 2>/dev/null  | tr -d '\\n' | tr -d '\\r'");
                                var existingDump = api.internal.system.run("ls '"+ targetedDump + "' 2>/dev/null  | tr -d '\\n' | tr -d '\\r'");
                                //console.log("existingDump : ",existingDump);
                                //for the moment: we don't dump rom if already exists in dumps directory / no proposal to erase in this case
                                //manual move/erase to do in share dumps directory in this case
                                if(!existingDump.includes("/recalbox/share/dumps/")){
                                    //copy of rom as dump
                                    //console.log("cp '" + gameCartridge_rom + "' '" + targetedDump + "'");
                                    api.internal.system.run("cp '" + gameCartridge_rom + "' '" + targetedDump + "'");
                                }
                            }
                        }
                        else{
                            //for message in dialog box
                            gameCartridge = qsTr("unknown game / not recognized");
                            //to set data of game
                            gameCartridge_region = "";
                            gameCartridge_system = "nes";
                            gameCartridge_state = "unknown";
                            gameCartridge_crc32 = "";
                            gameCartridge_name = "";
                        }

                        //propose cartridge dialog box in this case
                        cartridgeDialogBoxLoader.visible = true; //to show
                        cartridgeDialogBoxLoader.focus = true; //to have focus
                    }
                    else if((parseInt(romsize) <= 16) && (cartridge_plugged === true)){
                        cartridge_plugged = false;
                        //remove potential previous files about rom
                        api.internal.system.run("rm /tmp/USBNES.romcrc32");
                        //RFU: api.internal.system.run("rm /tmp/USBNES.rommd5");
                        cartridgeDialogBoxLoader.focus = false; //to unfocus if displayed
                        cartridgeDialogBoxLoader.visible = false; //to hide if displayed
                        //show popup to say that game has been removed
                        apiconnection.onShowPopup(qsTr("Video game cartridge reader"), qsTr("USB-NES cartridge unplugged"),"",3);
                        gameCartridge = "";
                        gameCartridge_region = "";
                        gameCartridge_system = "";
                        gameCartridge_state = "unplugged";
                        gameCartridge_crc32 = "";
                        gameCartridge_name = "";
                    }
                    else if((parseInt(romsize) <= 16)){
                        cartridgeDialogBoxLoader.focus = false; //to unfocus if displayed
                        cartridgeDialogBoxLoader.visible = false; //to hide if displayed
                        //show popup to alert that we didn't detected the game
                        apiconnection.onShowPopup(qsTr("Video game cartridge reader"), qsTr("USB-NES no cartridge detected"),"",3);
                        gameCartridge = "";
                        gameCartridge_region = "";
                        gameCartridge_system = "";
                        gameCartridge_state = "";
                        gameCartridge_crc32 = "";
                        gameCartridge_name = "";
                    }
                    //console.log("USB-NES gameCartridge (full description from NESDB 2.0) : ", gameCartridge);
                    //console.log("USB-NES gameCartridge_region (no-intro regions) : ", gameCartridge_region);
                    //console.log("USB-NES gameCartridge_system (pixL system shortname): ", gameCartridge_system);
                    //console.log("USB-NES gameCartridge_state : ", gameCartridge_state);
                    //console.log("USB-NES gameCartridge_name (name extracted to help for search in gamelists): ", gameCartridge_name);
                    //set read.flag to "true"
                    api.internal.system.run("echo '" + true + "' | tr -d '\\n' | tr -d '\\r' > " + mountpoint + "/pixl-read.flag");
                }
            }
        }
    }

    // Timer to show the dialog box for cartridge (RETRODE)
    Timer {
        id: dialogBoxRETRODETimer
        interval: 5000
        triggeredOnStart: false
        repeat: true
        running: (splashScreen.focus) ? false : true
        property bool cartridge_plugged: false
        onTriggered: {
            if (!api.internal.recalbox.getBoolParameter("dumpers.retrode.enabled",false)){
                //do nothing if not enabled but we keep timer running for detection
                return;
            }
            var mountpoint = api.internal.system.run("cat /tmp/RETRODE.mountpoint 2>/dev/null | tr -d '\\n' | tr -d '\\r'");
            //console.log("RETRODE mountpoint : ", mountpoint)
            if(mountpoint.includes("/usb")) {
                //console.log("RETRODE cartridge plugged: ", cartridge_plugged)
                //get list of extensions from RETRODE.CFG (always with this order in this file after restart and conf : snes,megadrive,n64,gb,gba,mastersystem,gamegear)
                //console.log("grep -i 'RomExt' "+ mountpoint + "/RETRODE.CFG  | awk -F' ' '{print $2}' | paste -s -d ',' | tr -d '\\n' | tr -d '\\r'");
                var romsExt = api.internal.system.run("grep -i 'RomExt' "+ mountpoint + "/RETRODE.CFG  | awk -F' ' '{print $2}' | paste -s -d ',' | tr -d '\\n' | tr -d '\\r'");
                //console.log("RETRODE romsExt ",romsExt);
                //find rom using existing extension
                var fileFound = "";
                var systemFound = "";
                for(var i=0; i<7; i++){
                    //console.log("ls " + mountpoint + "/*." + romsExt.split(",")[i] + " 2>/dev/null | tr -d '\\n' | tr -d '\\r'");
                    fileFound = api.internal.system.run("ls " + mountpoint + "/*." + romsExt.split(",")[i] + " 2>/dev/null  | tr -d '\\n' | tr -d '\\r'");
                    //console.log("RETRODE fileFound for ",retrode_systems_list.split(",")[i], " : ", fileFound)
                    if(fileFound !== ""){
                        systemFound = retrode_systems_list.split(",")[i];
                        //console.log("RETRODE systemFound : ",systemFound)
                        break;
                    }
                }
                //check if flag available
                var readflag = api.internal.system.run("ls " + mountpoint + "/*.flag 2>/dev/null  | tr -d '\\n' | tr -d '\\r'");
                if(fileFound !== "" && !readflag.includes("pixl-read")){
                    //add dialogBox to show spinner
                    genericMessage.setSource("dialogs/GenericWaitDialog.qml",
                                             { "title": qsTr("RETRODE"), "message": qsTr("ROM is loading from reader/dumper...")});
                    genericMessage.focus = true;
                    //run step 2 to let display the MessageBox
                    dialogBoxRETRODETimer_step2.mountpoint=mountpoint;
                    dialogBoxRETRODETimer_step2.fileFound=fileFound;
                    dialogBoxRETRODETimer_step2.romExt=romsExt.split(",")[i];
                    dialogBoxRETRODETimer_step2.systemFound=systemFound;
                    dialogBoxRETRODETimer_step2.start();
                }
                else if(fileFound === "" && cartridge_plugged === true && readflag.includes("pixl-read")){
                    cartridge_plugged = false;
                    //remove potential previous files about rom
                    api.internal.system.run("rm /tmp/RETRODE.romcrc32");
                    //RFU: api.internal.system.run("rm /tmp/RETRODE.rommd5");
                    cartridgeDialogBoxLoader.focus = false; //to unfocus if displayed
                    cartridgeDialogBoxLoader.visible = false; //to hide if displayed
                    //show popup to say that game has been removed
                    apiconnection.onShowPopup(qsTr("Video game cartridge reader"), qsTr("RETRODE cartridge unplugged"),"",3);
                    gameCartridge = "";
                    gameCartridge_region = "";
                    gameCartridge_system = "";
                    gameCartridge_crc32 = "";
                    gameCartridge_state = "unplugged";
                    gameCartridge_name = "";
                }
                else if(!readflag.includes("pixl-read")){
                    cartridgeDialogBoxLoader.focus = false; //to unfocus if displayed
                    cartridgeDialogBoxLoader.visible = false; //to hide if displayed
                    //show popup to alert that we didn't detected the game
                    apiconnection.onShowPopup(qsTr("Video game cartridge reader"), qsTr("RETRODE no cartridge detected"),"",3);
                    gameCartridge = "";
                    gameCartridge_region = "";
                    gameCartridge_system = "";
                    gameCartridge_crc32 = "";
                    gameCartridge_state = ""
                    gameCartridge_name = "";
                }
                //console.log("RETRODE gameCartridge (from file name) : ", gameCartridge);
                //console.log("RETRODE gameCartridge_region (no-intro regions) : ", gameCartridge_region);
                //console.log("RETRODE gameCartridge_system (pixL system shortname): ", gameCartridge_system);
                //console.log("RETRODE gameCartridge_crc32 (as in gamelist for snes): ", gameCartridge_crc32);
                //console.log("RETRODE gameCartridge_state : ", gameCartridge_state);
                //console.log("RETRODE gameCartridge_name (name extracted to help for search in gamelists): ", gameCartridge_name);
                //set read.flag but empty
                api.internal.system.run("echo '' | tr -d '\\n' | tr -d '\\r' > " + mountpoint + "/pixl-read.flag");
            }
        }
    }

    // Timer to show the dialog box for cartridge (RETRODE)
    Timer {
        id: dialogBoxRETRODETimer_step2
        interval: 500
        triggeredOnStart: false
        repeat: false
        running: false
        property bool cartridge_plugged: false
        //see after property coming from previous step
        property string mountpoint: ""
        property string fileFound: ""
        property string systemFound: ""
        property string romExt: ""
        onTriggered: {
            //console.log("RETRODE mountpoint : ", mountpoint)
            if(mountpoint.includes("/usb")) {
                //console.log("RETRODE cartridge plugged: ", cartridge_plugged)
                //console.log("RETRODE romExt ",romExt);
                //console.log("RETRODE fileFound for ",systemFound, " : ", fileFound)
                //get size of the rom detected
                var romsize = api.internal.system.run("wc -c "+ fileFound + "  | tr -d '\\n' | tr -d '\\r'");
                if(isDebugEnv()) api.internal.system.run("sleep 4"); //to simulate slownness when we read rom file for the first time
                genericMessage.focus = false;
                //console.log("RETRODE romsize: ", romsize)
                //get previous crc32 if exists (including complete path of rom) to be able to compare it with previous one
                var previousromcrc32 = api.internal.system.run("cat /tmp/RETRODE.romcrc32 | tr -d '\\n' | tr -d '\\r'");
                //console.log("RETRODE previousromcrc32: ", previousromcrc32)
                //generate crc32 of the rom detected (including complete path of rom) to be able to compare it with previous one
                var romcrc32 = api.internal.system.run("crc32 " + fileFound + " | tr -d '\\n' | tr -d '\\r'");
                //console.log("RETRODE romcrc32: ", romcrc32)
                if(romcrc32 === previousromcrc32){
                    gameCartridge_state = "reloaded";
                    //show popup to say that is a reset
                    apiconnection.onShowPopup(qsTr("Video game cartridge reader"), qsTr("RETRODE cartridge reloaded"),"",2);
                }
                //just set "cartridge" as title of this game (optional)
                api.internal.singleplay.setTitle("cartridge");
                //set rom full path
                gameCartridge_rom = fileFound;
                api.internal.singleplay.setFile(gameCartridge_rom);
                //set system to select to run this rom
                api.internal.singleplay.setSystem(systemFound.split("|")[0]); //using shortName or take first one if several use the same extension
                //store new crc32 (including complete path of rom) and store it for the moment
                api.internal.system.run("echo '" + romcrc32 + "' | tr -d '\\n' | tr -d '\\r' > /tmp/RETRODE.romcrc32");
                //RFU: generate md5 (including complete path of rom) and store it for the moment
                //api.internal.system.run("md5sum " + mountpoint + "/rom.nes | tr -d '\\n' | tr -d '\\r' > /tmp/RETRODE.rommd5");
                //get info from file name (first part)
                var romfilename=fileFound.replace(mountpoint + "/","");
                var rominfo=romfilename.replace("." + romExt,"");
                //console.log("RETRODE rominfo: ", rominfo);
                if(rominfo !== ""){
                    //check also if sav game exist
                    //but we should exclude 3 files for that
                    var value1 = "pixl-read.flag";
                    var value2 = romfilename;
                    var value3 = "RETRODE.CFG"
                    //console.log("ls -1 "+ mountpoint + " 2>/dev/null | grep -vE '^(" + value1 +"|" + value2 + "|" + value3 + ")$' | tr -d '\\n' | tr -d '\\r'");
                    var savinfo=api.internal.system.run("ls -1 "+ mountpoint + " 2>/dev/null | grep -vE '^(" + value1 +"|" + value2 + "|" + value3 + ")$' | tr -d '\\n' | tr -d '\\r'");
                    //console.log("RETRODE savinfo: ", savinfo);
                    var savinfoflag = "N";
                    gameCartridge_save = "";
                    if(savinfo !== ""){
                        savinfoflag = "Y";
                        //just communicate that sav is available
                        gameCartridge_save = mountpoint + "/" + savinfo;
                    }
                    gameCartridge_state = "identified";
                    //console.log("RETRODE gameCartridge_state: ", gameCartridge_state);
                    gameCartridge = rominfo;
                    //console.log("RETRODE gameCartridge: ", gameCartridge);
                    gameCartridge_type = ""; //empty for RETRODE
                    //console.log("RETRODE gameCartridge_type: ", gameCartridge_type);
                    gameCartridge_region = ""; //empty for RETRODE
                    //console.log("RETRODE gameCartridge_region: ", gameCartridge_region);
                    gameCartridge_name = ""; //let it empty to search only by crc32
                    //console.log("RETRODE gameCartridge_name: ", gameCartridge_name);
                    //check if option to save rominfo/crc32 is requested
                    if(api.internal.recalbox.getBoolParameter("dumpers.retrode.romlist",false)){
                        var existingFile = ""
                        existingFile = api.internal.system.run("ls /recalbox/share/roms/retrode.romlist.csv 2>/dev/null | tr -d '\\n' | tr -d '\\r'");
                        if(!existingFile.includes("retrode.romlist.csv")){
                            //if no file exists, let create it with column titles
                            api.internal.system.run("echo 'GAME TITLE;SYSTEM;WORKS;SAVE FOUND;CRC32 FILE CHECKSUM;DUMPER VERSION;WHEN;COMMENT' >> /recalbox/share/roms/retrode.romlist.csv");
                        }
                        var existingRom = ""
                        existingRom = api.internal.system.run("grep -i " + romcrc32 + " /recalbox/share/roms/retrode.romlist.csv | tr -d '\\n' | tr -d '\\r'");
                        //console.log("existingRom : ",existingRom);
                        if(existingRom === ""){
                            //format GAME TITLE,SYSTEM,WORKS,SAVE FOUND;CRC32 FILE CHECKSUM,DUMPER VERSION,WHEN,COMMENT
                            var now = new Date();
                            var formattedDateTime = now.toString("yyyy-MM-dd hh:mm:ss");
                            //console.log("Formatted date and time:", formattedDateTime);
                            if(retrodeVersion === ""){
                                //read RETRODE version and store it in global variable
                                retrodeVersion = api.internal.system.run("cat " + mountpoint + "/RETRODE.CFG | awk 'NR == 1 {print}' | awk -F ' ' '{print $2$3}' | grep -o '[^[:space:]]*' | tr '\\n' ' '");
                            }
                            //console.log('echo "' + rominfo + ';' + systemFound + ';' + 'Y' + ';' + savinfo + ';' +  romcrc32.split(" ")[0] + ';' + retrodeVersion  + ';' + formattedDateTime + ';' + 'no comment for the moment' + '" >> /recalbox/share/roms/retrode.romlist.csv');
                            api.internal.system.run('echo "' + rominfo + ';' + systemFound + ';' +  'Y' + ';' + savinfo + ';' +  romcrc32.split(" ")[0] + ';' + retrodeVersion  + ';' + formattedDateTime + ';' + 'no comment for the moment' + '" >> /recalbox/share/roms/retrode.romlist.csv');
                        }
                    }
                    gameCartridge_system = systemFound;
                    //to do last because will trig changes
                    gameCartridge_crc32 = romcrc32.split(" ")[0];//need to take first part only because file name/path is inlcuded in result of CRC32 calculation
                    //console.log("RETRODE gameCartridge_crc32: ", gameCartridge_crc32);
                    //dump of rom if request
                    if(api.internal.recalbox.getBoolParameter("dumpers.retrode.savedump",false)){
                        var targetedDump = "/recalbox/share/dumps/" + rominfo + " [" + gameCartridge_crc32 + "]." + romExt;
                        //console.log("ls '"+ targetedDump + "' 2>/dev/null  | tr -d '\\n' | tr -d '\\r'");
                        var existingDump = api.internal.system.run("ls '"+ targetedDump + "' 2>/dev/null  | tr -d '\\n' | tr -d '\\r'");
                        //console.log("existingDump : ",existingDump);
                        //for the moment: we don't dump rom if already exists in dumps directory / no proposal to erase in this case
                        //manual move/erase to do in share dumps directory in this case
                        if(!existingDump.includes("/recalbox/share/dumps/")){
                            //copy of rom as dump
                            //console.log("cp '" + gameCartridge_rom + "' '" + targetedDump + "'");
                            api.internal.system.run("cp '" + gameCartridge_rom + "' '" + targetedDump + "'");
                        }
                    }
                }
                //propose cartridge dialog box in this case
                cartridgeDialogBoxLoader.visible = true; //to show
                cartridgeDialogBoxLoader.focus = true; //to have focus
                //console.log("RETRODE gameCartridge (from file name) : ", gameCartridge);
                //console.log("RETRODE gameCartridge_region (no-intro regions) : ", gameCartridge_region);
                //console.log("RETRODE gameCartridge_system (pixL system shortname): ", gameCartridge_system);
                //console.log("RETRODE gameCartridge_crc32 (as in gamelist for snes): ", gameCartridge_crc32);
                //console.log("RETRODE gameCartridge_state : ", gameCartridge_state);
                //console.log("RETRODE gameCartridge_name (name extracted to help for search in gamelists): ", gameCartridge_name);
            }
        }
    }

    //Event from API Back-end
    Connections {
        id: apiconnection
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
            //console.log("New controller detected: #", idx," - ", msg);
            subscreen.setSource("menu/settings/GamepadEditor.qml", {"newControllerIndex": idx, "isNewController": true});
            subscreen.focus = true;
            content.state = "sub";

            //add dialogBox
            genericMessage.setSource("dialogs/GenericContinueDialog.qml",
                                     { "title": qsTr("New controller") + " : " + msg, "message": qsTr("Press any button to continue") + "\n(" + qsTr("please read instructions at the bottom of next view to understand possible actions") + "\n" + qsTr("mouse and keyboard could be used to help configuration") + ")" });
            genericMessage.focus = true;
        }
        function onRequestAction(action, parameterList) {
            //console.log("New action requested : ", action);
            //console.log("parameterList content : ", parameterList);
            if(action === "shutdown"){
                powerDialog.source = "dialogs/ShutdownDialog.qml"
                powerDialog.focus = true;
            }
            else if(action === "reboot"){
                powerDialog.source = "dialogs/RebootDialog.qml";
                powerDialog.item.message = qsTr("The system will reboot. Are you sure?");
                powerDialog.focus = true;
            }
            else if(action === "restart"){
                powerDialog.source = "dialogs/RestartDialog.qml";
                powerDialog.item.message = qsTr("Pegasus will restart. Are you sure?");
                powerDialog.focus = true;
            }
            else if(action === "usbmount-add"){
                powerDialog.source = "dialogs/RestartDialog.qml";
                powerDialog.item.message = qsTr("New USB device detected with ROMS directory, do you want to parse it now ?");
                powerDialog.focus = true;
            }
            else if(action === "usbmount-remove"){
                powerDialog.source = "dialogs/RestartDialog.qml";
                powerDialog.item.message = qsTr("USB device removed, do you want to refresh list of games ?");
                powerDialog.focus = true;
            }
            else if(action === "retrode-remove" && api.internal.recalbox.getBoolParameter("dumpers.retrode.enabled",false)){
                apiconnection.onShowPopup("Video game cartridge reader", "RETRODE removed","",3);
                //remove potential previous files about rom
                api.internal.system.run("rm /tmp/RETRODE.romcrc32");
                api.internal.system.run("rm /tmp/RETRODE.rommd5");
                //remove cartridge also and stop timer to find roms/saves from RETRODE
                dialogBoxRETRODETimer.cartridge_plugged = false;
                dialogBoxRETRODETimer.stop();
                //for message in dialog box
                gameCartridge = qsTr("retrode removed");
                //to set data of game
                gameCartridge_region = "";
                gameCartridge_state = "disconnected";
                gameCartridge_name = "";
            }
            else if(action.includes("retrode-") && api.internal.recalbox.getBoolParameter("dumpers.retrode.enabled",false)){
                var retrodeDevice = action.split("-")[1];
                var retrodeMountpoint = action.split("-")[2];
                apiconnection.onShowPopup("Video game cartridge reader", "RETRODE mounted from " + retrodeDevice + " to " + retrodeMountpoint,"",3);
                //read RETRODE version and store it in global variable
                retrodeVersion = api.internal.system.run("cat " + retrodeMountpoint + "/RETRODE.CFG | awk 'NR == 1 {print}' | awk -F ' ' '{print $2$3}' | grep -o '[^[:space:]]*' | tr '\\n' ' '");
                //run timer to find roms/saves from RETRODE
                dialogBoxRETRODETimer.cartridge_plugged = false;
                dialogBoxRETRODETimer.start();
            }
            else if(action === "usbnes-remove"  && api.internal.recalbox.getBoolParameter("dumpers.usbnes.enabled",false)){
                apiconnection.onShowPopup("Video game cartridge reader", "USB-NES removed","",3);
                //remove potential previous files about rom
                api.internal.system.run("rm /tmp/USBNES.romcrc32");
                api.internal.system.run("rm /tmp/USBNES.rommd5");
                //remove cartridge also and stop timer to find roms/saves from USBNES
                dialogBoxUSBNESTimer.cartridge_plugged = false;
                dialogBoxUSBNESTimer.stop();
                //for message in dialog box
                gameCartridge = qsTr("usb-nes removed");
                //to set data of game
                gameCartridge_region = "";
                gameCartridge_system = "nes";
                gameCartridge_state = "disconnected";
                gameCartridge_name = "";
            }
            else if(action.includes("usbnes-")  && api.internal.recalbox.getBoolParameter("dumpers.usbnes.enabled",false)){
                var usbnesDevice = action.split("-")[1];
                var usbnesMountpoint = action.split("-")[2];
                apiconnection.onShowPopup("Video game cartridge reader", "USB-NES mounted from " + usbnesDevice + " to " + usbnesMountpoint,"",3);
                //read USB-NES version and store it in global variable
                usbnesVersion = api.internal.system.run("cat " + usbnesMountpoint + "/version.txt | grep -o '[^[:space:]]*' | tr '\\n' ' '");
                //run timer to find roms/saves from USBNES
                dialogBoxUSBNESTimer.cartridge_plugged = false;
                dialogBoxUSBNESTimer.start();
            }
            else if(action === "cdrom-eject"){
                apiconnection.onShowPopup("Video game CD-ROM reader", "CD-ROM ejected","",3);
                cdRomDialogBoxTimer.stop();
                gameCdRom = "";
            }
            else if(action.includes("cdrom-")){
                var cdromDevice = action.split("-")[1];
                var cdromMountpoint = action.split("-")[2];
                apiconnection.onShowPopup("Video game CD-ROM reader", "CD-ROM mounted from " + cdromDevice + " to " + cdromMountpoint,"",3);
                cdRomDialogBoxTimer.start();
            }
        }
        function onEventLoadingStarted() {
            //console.log("onEventLoadingStarted()");
            splashScreen.focus = true;
            loadingState = true;
        }
    }

    SplashLayer {
        id: splashScreen
        focus: true
        enabled: false
        visible: focus
        z: 10
        property bool dataLoading: api.internal.meta.loading
        property bool skinLoading: theme.status === Loader.Null || theme.status === Loader.Loading
        showDataProgressText: dataLoading

        function hideMaybe() {
            console.log("Splashcreen hiding by focus/z level");
            if (focus && !dataLoading && !skinLoading) {
                //focus on theme content
                content.focus = true;
                //put splashscreen behind
                z = -1
                //remove focus from splashcreen
                focus = false;
                //reset splashscreen loading bar
                api.internal.meta.resetLoadingState();
            }
            else if (focus){
                //set in front
                z = 10;
                //remove focus from theme content
                content.focus = false;
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

        width: (messageText.text.length > titleText.text.length ? messageText.text.length * vpx(5) : titleText.text.length * vpx(7.5)) + ((icon.length !== 0) ? iconSize : vpx(20)) + vpx(15)
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
                    }
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
                        rightMargin: vpx(5)
                        bottomMargin: vpx(5)
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
                        rightMargin: vpx(3)
                        bottomMargin: vpx(2)
                    }
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
                x: 0
                width: parent.width
                height: parent.height - keyboard.height
                visible: Qt.inputMethod.visible && api.internal.settings.virtualKeyboardSupport
                property real yPositionWhenHidden: parent.height
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
        ListElement { componentName: "Pixl-patches"; repoUrl:"https://api.github.com/repos/pixl-os/pixl-patches/releases";icon: ""; picture: ""; multiVersions: false}
        ListElement { componentName: "Mame"; repoUrl:"https://api.github.com/repos/pixl-os/mamedev-mame/releases";icon:""; picture: ""; multiVersions: false}
        ListElement { componentName: "Libretro Mame"; repoUrl:"https://api.github.com/repos/pixl-os/libretro-mame/releases";icon:""; picture: ""; multiVersions: false}
        ListElement { componentName: "Libretro FBNeo"; repoUrl:"https://api.github.com/repos/pixl-os/FBNeo/releases";icon:""; picture: ""; multiVersions: false}
        ListElement { componentName: "Xemu"; repoUrl:"https://api.github.com/repos/pixl-os/xemu/releases";icon:""; picture: ""; multiVersions: false}
        ListElement { componentName: "Cemu"; repoUrl:"https://api.github.com/repos/pixl-os/cemu/releases";icon:""; picture: ""; multiVersions: false}
        ListElement { componentName: "Supermodel"; repoUrl:"https://api.github.com/repos/pixl-os/Supermodel/releases";icon:""; picture: ""; multiVersions: false}
        ListElement { componentName: "Dolphin-emu"; repoUrl:"https://api.github.com/repos/pixl-os/dolphin/releases";icon:""; picture: ""; multiVersions: false}
        ListElement { componentName: "Pcsx2"; repoUrl:"https://api.github.com/repos/pixl-os/pcsx2/releases";icon:""; picture: ""; multiVersions: false}
        ListElement { componentName: "Citra-emu"; repoUrl:"https://api.github.com/repos/pixl-os/citra-nightly/releases";icon:""; picture: ""; multiVersions: false}
        ListElement { componentName: "shinretro"; repoUrl:"https://api.github.com/repos/pixl-os/shinretro/releases";icon:""; picture: ""; multiVersions: false}
        ListElement { componentName: "Nvidia driver"; repoLocal:"/recalbox/system/hardware/videocard/releases-nvidia.json";icon:"qrc:/frontend/assets/logonvidia.png"; picture: ""; multiVersions: true}
        //to install local plugin ;-) from /recalbox/share/plugin
        ListElement { componentName: "Plugin"; repoLocal:"/recalbox/share/plugin/plugin.json";icon:""; picture: ""; multiVersions: false}
    }

    //to store and know if we are running in a pixL OS in Beta (For beta testing only) or Release version (Release include pre-release/public beta) + if Dev mode is activated
    property bool isDev: false
    property bool isBeta: false
    property bool isRelease: false

    Timer{ //timer to add pixL-OS Dev, Beta or Release component + manage "dev" mode
        id: addUpdateTimer
        repeat: false
        running: true
        triggeredOnStart: true
        onTriggered: {
            //check if not dev version is requested from recalbox.conf
            /*
            # ------------ F - UPDATES ------------ #
            ## Automatically check for updates at start (0,1)
            updates.enabled=1
            # Update type : default to stable (only dev is checked today)
            updates.type=stable
            updates.devuser=your_personal_github_user
            */
            //running if updates activated
            if(api.internal.recalbox.getBoolParameter("updates.enabled") === true){
                //check that 'dev' updates is not selected
                if(api.internal.recalbox.getStringParameter("updates.type") !== "dev"){
                    //check version via recalbox.version
                    //if "beta"/"release" terms are found or if "dev" is forced in updates type
                    isBeta = (api.internal.system.run("grep -i 'beta' /recalbox/recalbox.version") === "") ? false : true
                    isRelease = (api.internal.system.run("grep -i 'release' /recalbox/recalbox.version") === "") ? false : true
                    if(isRelease === true){// to propose release or pre-release in priority
                        componentsListModel.append({ componentName: "pixL-OS", repoUrl:"https://updates.pixl-os.com/release-pixl-os.json",icon: "qrc:/frontend/assets/logo.png", picture: "qrc:/frontend/assets/backgroundpixl.png", multiVersions: false, downloaddirectory: "/recalbox/share/system/upgrade"});
                    }
                    else if(isBeta === true){ // to propose beta only if we have already a beta version installed
                        componentsListModel.append({ componentName: "pixL-OS (Beta)", repoUrl:"https://updates.pixl-os.com/beta-pixl-os.json",icon: "qrc:/frontend/assets/logobeta.png", picture: "qrc:/frontend/assets/backgroundpixl.png", multiVersions: false, downloaddirectory: "/recalbox/share/system/upgrade"});
                    }
                }
                else{// for dev testing only about updates
                    isDev = true;
                    if(api.internal.recalbox.getStringParameter("updates.devuser") !== ""){
                        //console.log("devuser : ", api.internal.recalbox.getStringParameter("updates.devuser"))
                        //take all existing repo and duplicate it for the devuser (especially for core/emulator updates)
                        var existingCount = componentsListModel.count;
                        for(var i = 0;i < existingCount; i++){
                            if((typeof(componentsListModel.get(i).repoUrl) !== "undefined") && (componentsListModel.get(i).repoUrl !== ""))
                            {
                                //console.log("component created for dev purpose : ", componentsListModel.get(i).componentName + " (Dev)")
                                componentsListModel.get(i).componentName = componentsListModel.get(i).componentName + " (Dev)"
                                componentsListModel.get(i).repoUrl = componentsListModel.get(i).repoUrl.replace("pixl-os", api.internal.recalbox.getStringParameter("updates.devuser"))
                            }
                            else if((typeof(componentsListModel.get(i).repoLocal) !== "undefined") && (componentsListModel.get(i).repoLocal !== ""))
                            {
                                //don't replicate local repo
                            }
                        }
                    }
                    //check that 'dev' updates is not selected
                    if(api.internal.recalbox.getStringParameter("updates.format") !== "raw"){
                        componentsListModel.append({ componentName: "pixL-OS (Dev)", repoUrl:"https://updates.pixl-os.com/dev-pixl-os.json",icon: "qrc:/frontend/assets/logobeta.png", picture: "qrc:/frontend/assets/backgroundpixl.png", multiVersions: false, downloaddirectory: "/recalbox/share/system/upgrade"});
                    }
                    else {
                        componentsListModel.append({ componentName: "pixL-OS (Dev)", repoUrl:"https://updates.pixl-os.com/dev-raw-pixl-os.json",icon: "qrc:/frontend/assets/logobeta.png", picture: "qrc:/frontend/assets/backgroundpixl.png", multiVersions: false, downloaddirectory: "/boot/update"});
                    }
                }
            }
            //stop timer
            addUpdateTimer.stop();
            //start other timers
            repoStatusRefreshTimer.start(); //for "remote" update/repo
            localStatusRefreshTimer.start(); //for "local" update/plugin
            pluginFileCheckTimer.start(); //for check of plugin availability/unzip
            updatePopupTimer.start();
            checkUpgradeTimer.start();

        }
    }

    Timer{//timer to check and alert about upgrade
        id: checkUpgradeTimer
        interval: 5000 // Check after 5 s
        repeat: false //check and display popup only one time
        running: false
        triggeredOnStart: false
        onTriggered: {
            var upgradeFailed = api.internal.system.run("test -f /tmp/upgradefailed && echo 'true' || echo 'false'").includes("true") ? true : false
            var upgraded = api.internal.system.run("test -f /tmp/upgraded && echo 'true' || echo 'false'").includes("true") ? true : false
            //check if upgraded or failed
            if((upgradeFailed === true) || (upgraded === true)){
                //to popup to alert about upgrade
                //init parameters
                popup.title = qsTr("Information");
                if(upgradeFailed === true){
                    popup.message = qsTr("Upgrade failed !");
                }
                else if(upgraded === true){
                    popup.message = qsTr("Upgrade done !");
                }
                //icon is optional but should be set to empty string if not use
                popup.icon = "\uf2c6";
                popup.iconfont = global.fonts.ion;
                //delay provided in second and interval is in ms
                popupDelay.interval = 10 * 1000;
                //Open popup and set it as showable to have animation
                popup.open();
                popup.showing = true;
                //start timer to close popup automatically
                popupDelay.restart();
            }
        }
    }

    Timer {//timer to download last versions (from online repo only)
        id: repoStatusRefreshTimer
        interval: 60000 * 30 // Check every 30 minutes and at start
        repeat: true
        running: false
        triggeredOnStart: true
        onTriggered: {
            //only if updates are enabled from recalbox.conf
            //console.log("updates.enabled : ",api.internal.recalbox.getBoolParameter("updates.enabled"));
            if(api.internal.recalbox.getBoolParameter("updates.enabled") === true){
                var before = api.internal.recalbox.getStringParameter("updates.lastchecktime")
                //console.log("updates.lastchecktime read: ", before);
                //check if we restart the front end or not in the last 30 minutes
                //if before is empty, updates will be checked
                //if now is upper or equal than before + interval, updates will be checked
                //if now is less than before + interval, we do nothing
                if((Date.now() < (parseInt(before) + interval)) && (api.internal.recalbox.getStringParameter("updates.type") !== "dev")){
                    //do nothing, no check of repo, use only existing json from /tmp
                }
                else {
                    //store info in memory and launch check of updates
                    //console.log("updates.lastchecktime write: ", Date.now());
                    api.internal.recalbox.setStringParameter("updates.lastchecktime", Date.now())
                    //loop to launch download of all json repository files
                    for(var i = 0;i < componentsListModel.count; i++){
                        if((typeof(componentsListModel.get(i).repoUrl) !== "undefined") && (componentsListModel.get(i).repoUrl !== ""))
                        {
                            api.internal.updates.getRepoInfo(componentsListModel.get(i).componentName,componentsListModel.get(i).repoUrl);
                        }
                    }
                }
                //start timer to check 30s later the result
                //check if not already run finally
                if(jsonStatusRefreshTimer.running !== true){
                    jsonStatusRefreshTimer.running = true;
                }
            }
        }
    }

    property int numberOfUpdates : 0
    property string listOfUpdates : ""
    Timer {//timer to check json after download
        id: jsonStatusRefreshTimer
        interval: 30000 // check after 30 seconds now
        repeat: false // no need to repeat
        running: false
        triggeredOnStart: false
        onTriggered: {
            for(var i = 0;i < componentsListModel.count; i++){
                //check all components (including pre-release for the moment and without filter)
                numberOfUpdates = 0;
                listOfUpdates = "";
                //to check only remote update/repo
                if((typeof(componentsListModel.get(i).repoUrl) !== "undefined") && (componentsListModel.get(i).repoUrl !== ""))
                {
                    var updateVersionIndexFound = api.internal.updates.hasUpdate(componentsListModel.get(i).componentName , (isBeta || isDev), (typeof(componentsListModel.get(i).multiVersions) !== "undefined") ? componentsListModel.get(i).multiVersions : false );
                    if(updateVersionIndexFound !== -1){
                        numberOfUpdates = numberOfUpdates + 1;
                        componentsListModel.setProperty(i,"hasUpdate", true);
                        componentsListModel.setProperty(i,"hasInstallNotified", false);
                        componentsListModel.setProperty(i,"UpdateVersionIndex", updateVersionIndexFound);
                        //contruct string about all udpates
                        listOfUpdates = listOfUpdates + (listOfUpdates !== "" ? " / " : "") + componentsListModel.get(i).componentName;
                    }
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
            //just to be sure that variable is set to false at the end
            jsonStatusRefreshTimer.running = false;
        }
    }

    property bool hasPlugin : false
    Timer {//timer to detect .plugin "zip compressed" file
        id: pluginFileCheckTimer
        interval: 3000 // Check every 3 seconds and at start
        repeat: true
        running: false
        triggeredOnStart: true
        onTriggered: {
            hasPlugin = api.internal.updates.hasPlugin();
            //console.log("hasPlugin: " + hasPlugin);
        }
    }

    Timer {//timer to download last versions (from "local" / "plugin" only)
        id: localStatusRefreshTimer
        interval: 5000 // Check every 5 seconds and at start
        repeat: true
        running: false
        triggeredOnStart: true
        onTriggered: {
            //only if updates are enabled from recalbox.conf
            //console.log("updates.enabled : ",api.internal.recalbox.getBoolParameter("updates.enabled"));
            if(api.internal.recalbox.getBoolParameter("updates.enabled") === true){
                //loop to check all json from lcoal "repository" files
                for(var i = 0;i < componentsListModel.count; i++){
                    if((typeof(componentsListModel.get(i).repoLocal) !== "undefined") && (componentsListModel.get(i).repoLocal !== ""))
                    {
                        api.internal.updates.getRepoInfo(componentsListModel.get(i).componentName,componentsListModel.get(i).repoLocal);
                    }
                }
                //start timer to check 10s later the result
                //check if not already run finally
                if(jsonLocalStatusRefreshTimer.running !== true){
                    jsonLocalStatusRefreshTimer.running = true;
                }
            }
        }
    }

    property int numberOfLocalUpdates : 0
    property string listOfLocalUpdates : ""
    Timer {//timer to check json after download
        id: jsonLocalStatusRefreshTimer
        interval: 5000 // check after 5 seconds now
        repeat: false // no need to repeat
        running: false
        triggeredOnStart: false
        onTriggered: {

            for(var i = 0;i < componentsListModel.count; i++){
                //check all components (including pre-release for the moment and without filter)
                numberOfLocalUpdates = 0;
                listOfLocalUpdates = "";
                //to check only local update/plugin
                if((typeof(componentsListModel.get(i).repoLocal) !== "undefined") && (componentsListModel.get(i).repoLocal !== ""))
                {
                    var updateVersionIndexFound = api.internal.updates.hasUpdate(componentsListModel.get(i).componentName , (isBeta || isDev), (typeof(componentsListModel.get(i).multiVersions) !== "undefined") ? componentsListModel.get(i).multiVersions : false );
                    if(updateVersionIndexFound !== -1){
                        numberOfLocalUpdates = numberOfLocalUpdates + 1;
                        componentsListModel.setProperty(i,"hasUpdate", true);
                        componentsListModel.setProperty(i,"hasInstallNotified", false);
                        componentsListModel.setProperty(i,"UpdateVersionIndex", updateVersionIndexFound);
                        //contruct string about all udpates
                        listOfLocalUpdates = listOfLocalUpdates + (listOfLocalUpdates !== "" ? " / " : "") + componentsListModel.get(i).componentName;
                    }
                }
            }

            if(numberOfLocalUpdates !== 0){
                //to popup to alert about all udpates
                //init parameters
                popup.title = (numberOfLocalUpdates === 1) ?  (qsTr("Update available") + api.tr) : (qsTr("Updates available") + api.tr);
                popup.message = listOfLocalUpdates;
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
            //just to be sure that variable is set to false at the end
            jsonLocalStatusRefreshTimer.running = false;
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
            //console.log("bluetoothRestartTimer triggered !");
            if (!isDebugEnv()){
                api.internal.system.run("/etc/init.d/S40bluetoothd restart");
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
        ListElement { icon: "\uf2f0"; keywords: "xboxone,xbox one,x-box one,xbox wireless"; type:"controller"; iconfont: "awesome"; layout: "xboxone"} //as layout XBOX SERIES, need layout XBOX ONE
        ListElement { icon: "\uf2f0"; keywords: "xbox series"; type:"controller"; iconfont: "awesome"; layout: "xboxseries"} //as XBOX one for the moment, need icon for series
        ListElement { icon: "\uf2f0"; keywords: "xbox series 20 years"; type:"controller"; iconfont: "awesome"; layout: "xboxseries20years"} //as XBOX one for icon, need icon for series and layout defined in input.cfg so that it can be used only for this controller
        ListElement { icon: "\uf2ee"; keywords: "xbox,microsoft"; type:"controller"; iconfont: "awesome"} //as XBOX for the moment

        ListElement { icon: "\uf0cf"; keywords: "ps5,playstation 5,dualsense"; type:"controller"; iconfont: "awesome"; layout: "ps5"} // add wireless controller as usual PS name used by Sony
        ListElement { icon: "\uf2ca"; keywords: "ps4,playstation 4,dualshock 4,wireless controller"; type:"controller"; iconfont: "awesome"; layout: "ps4"} // add wireless controller as usual PS name used by Sony
        ListElement { icon: "\uf2c9"; keywords: "ps3,playstation 3,dualshock 3"; type:"controller"; iconfont: "awesome"}
        ListElement { icon: "\uf2c8"; keywords: "ps2,playstation 2,dualshock 2"; type:"controller"; iconfont: "awesome"}
        ListElement { icon: "\uf275"; keywords: "ps1,psx,playstation,dualshock 1"; type:"controller"; iconfont: "awesome"}

        ListElement { icon: "\uf26a"; keywords: "mastersystem,master system"; type:"controller"; iconfont: "awesome"}
        ListElement { icon: "\uf26b"; keywords: "megadrive,mega drive,md/gen,sega genesis"; type:"controller"; iconfont: "awesome"}
        
        //8bitdo sfc30 and snes30 added to be considered as SNES controller
        ListElement { icon: "\uf25e"; keywords: "snes,super nintendo,sfc30,snes30"; type:"controller"; iconfont: "awesome"; layout: "snes"}
        ListElement { icon: "\uf25c"; keywords: "nes,nintendo entertainment system"; type:"controller" ; iconfont: "awesome"; layout: "nes"}
        ListElement { icon: "\uf262"; keywords: "gc,gamecube"; type:"controller"; iconfont: "awesome"}

        //huijia added for n64 due to mayflash n64 controller adapter v1 detected as "HuiJia  USB GamePad"
        //other hujia devices exists for NES, SNES, gamecube, Wii, but will be detected upper if needed.
        ListElement { icon: "\uf260"; keywords: "n64,nintendo 64,nintendo64,huijia"; type:"controller" ; iconfont: "awesome"; layout: "n64"}
        ListElement { icon: "\uf263"; keywords: "wii remote,rvl-cnt-01-tr"; type:"controller"; iconfont: "awesome"} //layout deactivated because not finished finally, called "wiimote"
        
        //need to keep only 'pro controller' in case of nintendo switch pro controller as it is the HID name (internal name)
        //in the future, we have other controller as "pro controller", the layout detection should be complexified
        ListElement { icon: "\uf0ca"; keywords: "switch pro,pro controller"; type:"controller"; iconfont: "awesome";  layout: "switchpro"}
        ListElement { icon: "\uf0c8"; keywords: "joy-con (l)"; type:"controller"; iconfont: "awesome"}
        ListElement { icon: "\uf0c9"; keywords: "joy-con (r)"; type:"controller"; iconfont: "awesome"}

        //27/02/2022 2 controllers added snakebyte idroid:con, 8bitdo sn30 pro+
        ListElement { icon: "\uf0cb"; keywords: "idroid"; type:"controller"; iconfont: "awesome"}
        ListElement { icon: "\uf0cc"; keywords: "sn30 pro+,sn30 pro plus"; type:"controller"; iconfont: "awesome"; layout: "sn30proplus"}
        //27/02/2022 2 controllers added 8bitdo pro 2
        ListElement { icon: "\uf0cc"; keywords: "8bitdo pro 2"; type:"controller"; iconfont: "awesome"}
        //07/10/2024 2 controllers added 8bitdo arcade stick, 8bitdo sf30/sn30 pro and google stadia
        ListElement { icon: "\uf0d1"; keywords: "stadia"; type:"controller"; iconfont: "awesome"; layout: "stadia"}
        ListElement { icon: "\uf0d2"; keywords: "8bitdo arcade stick,n30 Arcade Stick"; type:"controller"; iconfont: "awesome"; layout: "arcadestick"} //match only in bluetooth else detected as xbox :-(
        ListElement { icon: "\uf0d3"; keywords: "sn30 pro,sf30 pro"; type:"controller"; iconfont: "awesome"; layout: "sn30pro"}

        //28/02/2022 to add wheels/cockpit devices
        ListElement { icon: "\uf0c7"; keywords: "cockpit,wheel"; type:"controller"; iconfont: "awesome"}

        //28/02/2022 to add arcade panel device
        //2 codes exists "\uf0cd" & "\uf0ce", respectivelly fill and transparent version
        ListElement { icon: "\uf0cd"; keywords: "dragonrise,xinmo,xin-mo,j-pac,jpac"; type:"controller"; iconfont: "awesome"}

        //27/12/2024 1 controller added amazon luna
        ListElement { icon: "\uf2f0"; keywords: "amazon,luna"; type:"controller"; iconfont: "awesome"; layout: "luna"} //icon as XBOX one for the moment, need icon for luna

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
        //var iconcode = parseInt(icon.charCodeAt(0));
        //console.log("getIcon 1 - name: " + name + " - iconcode: " + iconcode);
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
        //console.log("getIcon 2 - name: " + name + " - type: " + type);
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
        //iconcode = parseInt(icon.charCodeAt(0));
        //console.log("getIcon 3 - name: " + name + " - type: " + type + " - iconcode: " + iconcode);
        return icon;
    }


    //***********************************************************END OF DATA MODELS*********************************************************************

    //***********************************************************BEGIN OF GENERIC FUNCTIONS ACCESSIBLE ALSO FOR THEMES*************************************************************
    function getThemeFile() {
        if (api.internal.meta.isLoading)
            return "";
        if (api.collections.count === 0)
            return "messages/NoGamesError.qml";
        var themePath = "";
        themePath = content.apiThemePath.toString();
        if(!themePath.includes("theme.qml")){
            return "messages/ThemeError.qml";
        }
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

    function gameSettings(collection,game) {
        //set not fullscreen due to be more like a popup dialogbox
        subdialog.fullscreen = false;
        subdialog.setSource("menu/settings/SystemsEmulatorConfiguration.qml", {"system": collection, "game": game , "launchedAsDialogBox": true});
        subdialog.focus = true;
    }

    function systemSettings(collection) {
        //set not fullscreen due to be more like a popup dialogbox
        subdialog.fullscreen = false;
        subdialog.setSource("menu/settings/SystemsEmulatorConfiguration.qml", {"system": collection, "launchedAsDialogBox": true});
        subdialog.focus = true;
    }
    //***********************************************************END OF GENERIC FUNCTIONS ACCESSIBLE ALSO FOR THEMES***************************************************************

    //***********************************************************BEGIN OF LIGHTGUNS MANAGEMENT *************************************************************
    //to display a crossair for lightguns
    Image {
        id: lightgunCrosshair
        source: "assets/white_crosshair.png"
        width: vpx(50)
        height: vpx(50)
        x: 0
        y: 0
        smooth: true
        asynchronous: true
        visible: false
        z: 3
    }

    //properties to know number of lightguns connected and by type
    property int nb_sinden_lightgun: 0
    property int nb_dolphinbar_lightgun: 0
    property int nb_lightgun: nb_sinden_lightgun + nb_dolphinbar_lightgun
    //zone to detect if gun is triggered
    MouseArea {
        anchors.fill: parent
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        propagateComposedEvents: true
        hoverEnabled: ((nb_lightgun > 0) && (lightgunCrosshair.visible === true)) ? true : false
        cursorShape: ((nb_lightgun > 0) && (lightgunCrosshair.visible === true)) ? Qt.BlankCursor : api.internal.settings.mouseSupport ? Qt.PointingHandCursor : Qt.BlankCursor

        onPositionChanged: {
            if (nb_lightgun > 0){
                lightgunCrosshair.x = mouse.x - (lightgunCrosshair.width/2);
                lightgunCrosshair.y = mouse.y - (lightgunCrosshair.height/2);
                lightgunCrosshair.visible = true;
            }
            else lightgunCrosshair.visible = false;
        }

        onClicked: {
            //for sinden lightgun only
            if(nb_sinden_lightgun > 0) {
                if(sindenBorderImage.visible === false || sindenInnerBorderRectangle.visible === false){
                    //sindenBorderImage.visible = true;
                    sindenInnerBorderRectangle.visible = true;
                    sindenOuterBorderRectangle.visible = true;
                }
                //to reload source if conf changed and if already visible
                let bordersize = api.internal.recalbox.getStringParameter("lightgun.sinden.bordersize","superthin");
                let bordercolor = api.internal.recalbox.getStringParameter("lightgun.sinden.bordercolor","white");
                //console.log("bordersize : ", bordersize);
                //console.log("bordercolor : ", bordercolor);
                switch (bordersize) {
                  case 'superthin':
                      //0.5 % of width: 1280
                      sindenInnerBorderRectangle.border.width = parseInt(appWindow.width*0.5 / 100);
                      //0 % of width: 1280
                      sindenOuterBorderRectangle.border.width = 0
                      break;
                  case 'thin':
                      //1 % of width: 1280
                      sindenInnerBorderRectangle.border.width = parseInt(appWindow.width*1 / 100);
                      //0 % of width: 1280
                      sindenOuterBorderRectangle.border.width = 0
                    break;
                  case 'medium':
                      //2 % of width: 1280
                      sindenInnerBorderRectangle.border.width = parseInt(appWindow.width*2 / 100);
                      //0 % of width: 1280
                      sindenOuterBorderRectangle.border.width = 0
                    break;
                  case 'big':
                      //2 % of width: 1280
                      sindenInnerBorderRectangle.border.width = parseInt(appWindow.width*2 / 100);
                      //1 % of width: 1280
                      sindenOuterBorderRectangle.border.width = parseInt(appWindow.width*1 / 100);
                    break;
                  default:
                }
                switch (bordercolor) {
                  case 'white':
                      sindenInnerBorderRectangle.border.color =  "#ffffff"; //"white";
                    break;
                  case 'red':
                      sindenInnerBorderRectangle.border.color =  "red";
                    break;
                  case 'green':
                      sindenInnerBorderRectangle.border.color =  "green";
                    break;
                  case 'blue':
                      sindenInnerBorderRectangle.border.color =  "blue";
                    break;
                  default:
                      sindenInnerBorderRectangle.border.color =  "white";
                }
            }
            else {
                sindenBorderImage.visible = false;
                sindenOuterBorderRectangle.visible = false;
                sindenInnerBorderRectangle.visible = false;
            }
            //to manage directly crosshair display
            if(nb_lightgun > 0) {
                if(lightgunCrosshair.visible === false){
                    lightgunCrosshair.visible = true;
                    //for first click to display border
                    mouse.accepted = true;
                }
                else mouse.accepted = false;
                //to start or restart timer to let display the border/crosshair if click
                crossHairBorderHidingDelay.restart();
            }
            else {
                lightgunCrosshair.visible = false;
                mouse.accepted = false;
            }
        }
        /*onReleased: mouse.accepted = false;
        onPressed: mouse.accepted = false;
        onDoubleClicked: mouse.accepted = false;
        onPositionChanged: mouse.accepted = false;
        onPressAndHold: mouse.accepted = false;*/
    }

    //NOT USED: to display "image" border for sinden lightgun - used for testing to be reused in the future
    Image {
        id: sindenBorderImage
        anchors.fill: parent
        source: "" //"assets/sinden/SindenBorder" + api.internal.recalbox.getStringParameter("lightgun.sinden.border","WhiteMedium_Wide") + ".png"
        sourceSize: Qt.size(parent.width, parent.height)
        fillMode: Image.Stretch
        smooth: true
        asynchronous: true
        anchors.centerIn: parent
        visible: false
        z: 3
    }

    Rectangle {
        id: sindenOuterBorderRectangle
                anchors.fill: parent
                border.color: "#000000"
                border.width: 0
                color: "transparent"
                opacity: 1.0
                Behavior on opacity { NumberAnimation { duration: 100 } }
                visible: false //splashScreen.focus ? false : true
                z: 4
    }

    Rectangle {
        id: sindenInnerBorderRectangle
                anchors.fill: parent
                anchors.leftMargin: sindenOuterBorderRectangle.border.width
                anchors.rightMargin: sindenOuterBorderRectangle.border.width
                anchors.topMargin: sindenOuterBorderRectangle.border.width
                anchors.bottomMargin: sindenOuterBorderRectangle.border.width

                border.color: "#ffffff"
                border.width: 0
                color: "transparent"
                opacity: 1.0
                Behavior on opacity { NumberAnimation { duration: 100 } }
                visible: false //splashScreen.focus ? false : true
                z: 3
    }

    // Timer to show the sinden lightgun border selected from menu and if gun plugged (manage also crossHair for sinden or dolphinbar)
    Timer {
        id: crossHairBorderTimer
        interval: 2000
        repeat: true
        running: splashScreen.focus ? false : true
        onTriggered: {
            nb_sinden_lightgun = parseInt(api.internal.system.run("if (test -e /var/run/sinden-lightguns.count) ; then cat /var/run/sinden-lightguns.count; else echo 0; fi;"));
            nb_dolphinbar_lightgun = parseInt(api.internal.system.run("if (test -e /var/run/dolphinbar-mouse.count) ; then cat /var/run/dolphinbar-mouse.count; else echo 0; fi;"));
            nb_lightgun = nb_sinden_lightgun + nb_dolphinbar_lightgun;
            if(nb_sinden_lightgun <= 0) {
                sindenBorderImage.visible = false;
                sindenInnerBorderRectangle.visible = false;
                sindenInnerBorderRectangle.border.width = 0;
                sindenOuterBorderRectangle.visible = false;
                sindenOuterBorderRectangle.border.width = 0;
            }
            if(nb_lightgun <=0) {
                lightgunCrosshair.visible = false;
            }
        }
    }

    Timer {
        id: crossHairBorderHidingDelay
        interval: 60000 // 1 minutes
        repeat: false
        running: false
        triggeredOnStart: false
        onTriggered: {
            //hide sinden lightgun border + crosshair after 60 seconds without inactivity with mouse/gun
            sindenBorderImage.visible = false;
            sindenInnerBorderRectangle.visible = false;
            sindenOuterBorderRectangle.visible = false;
            sindenInnerBorderRectangle.border.width = 0;
            sindenOuterBorderRectangle.border.width = 0;
            lightgunCrosshair.visible = false;
        }
    }
    //*********************************************************** END OF LIGHTGUNS MANAGEMENT *************************************************************

    //*********************************************************** START OF SLIDERS MANAGEMENT *************************************************************

    // Timer to show the sliders during a limited after update
    Timer {
        id: sliderVisibilityTimer
        interval: 1000
        repeat: false
        running: false
        triggeredOnStart: false
        onTriggered: {
            optOutputVolume.opacity = 0
            optBrightness.opacity = 0
        }
    }

    SliderVertical {
        id: optOutputVolume

        //property to manage parameter name
        property string parameterName : "audio.volume"
        height: parent.height / 6
        width: parent.height / 6
        x: 0
        y : 0

        // in slider object
        max : 100
        min : 0
        slidervalue: api.internal.recalbox.audioVolume
        //value: api.internal.recalbox.audioVolume + "%"

        symbol: "\uf11c"

        visible: true
        focus: false
        opacity: 0

        Behavior on opacity {
            PropertyAnimation {
                duration: 500
            }
        }

        property bool completed : false
        Component.onCompleted:{
            completed = true;
        }

        onSlidervalueChanged: {
            if(completed){
                opacity = 1;
                optBrightness.opacity = 0;
                sliderVisibilityTimer.restart()
                if(slidervalue >= 75){
                    symbol = "\uf11c"
                }
                else if(slidervalue >= 50){
                    symbol = "\uf11e"
                }
                else if(slidervalue >= 25){
                    symbol = "\uf11e"
                }
                else symbol = "\uf263" //mute
            }
        }
    }

    SliderVertical {
        id: optBrightness

        //property to manage parameter name
        property string parameterName : "screen.brightness"
        height: parent.height / 6
        width: parent.height / 6
        x: 0
        y : 0

        // in slider object
        max : 100
        min : 0
        slidervalue: api.internal.recalbox.screenBrightness
        //value: api.internal.recalbox.screenBrightness + "%"

        symbol: "\uf4b7"

        visible: true
        focus: false
        opacity: 0

        Behavior on opacity {
            PropertyAnimation {
                duration: 500
            }
        }

        property bool completed : false
        Component.onCompleted:{
            completed = true;
        }

        onSlidervalueChanged: {
            if(completed){
                opacity = 1;
                optOutputVolume.opacity = 0;
                sliderVisibilityTimer.restart();
            }
        }
    }
    //*********************************************************** END OF SLIDERS MANAGEMENT *************************************************************
}
