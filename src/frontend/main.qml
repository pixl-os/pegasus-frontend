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


    //    onClosing: {
    //        theme.source = "";
    //        api.internal.system.quit();
    //    }

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

            //            Keys.onPressed: {
            //                if (api.keys.isCancel(event) || api.keys.isMenu(event)) {
            //                    event.accepted = true;
            //                    mainMenu.focus = true;
            //                }
            Keys.onPressed: {
                if (api.keys.isMenu(event)) {
                    event.accepted = true;
                    mainMenu.focus = true;
                }

                if (api.keys.isNetplay(event) && api.internal.recalbox.getBoolParameter("global.netplay")){
                    event.accepted = true;
                    //netplayMenu.focus = true;
                    //console.log("api.keys.isNetplay(event)");
					subscreen.setSource("menu/settings/NetplayInformation.qml", {"isCallDirectly": true});
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
            // deleteLastCollection();
            content.focus = true;
            api.internal.system.run('python /usr/bin/emulatorlauncher.pyc -p1index 0 -p1guid 050000005e040000e002000003090000 -p1name "Xbox One Wireless Controller" -p1nbaxes 6 -p1nbhats 1 -p1nbbuttons 11 -p1devicepath /dev/input/event18 -p2index 1 -p2guid 050000005e040000e002000003090000 -p2name "Xbox One Wireless Controller" -p2nbaxes 6 -p2nbhats 1 -p2nbbuttons 11 -p2devicepath /dev/input/event19 -system psx -rom cdrom://drive1.cue -emulator libretro -core mednafen_psx_hw -ratio auto');
        }
        function onSecondChoice() {
            // eject disk
            api.internal.system.run("eject");
            // return back
            content.focus = true;
        }
        function onCancel() {
            // return back
            content.focus = true;
        }
    }
    //list model to manage icons of devices
    ListModel {
        id: mySystemIcons

        ListElement { icon: "\uf275"; keywords: "psx"; type:"controller"}
        ListElement { icon: "\uf294"; keywords: "dreamcast"; type:"controller"}
        ListElement { icon: "\uf26b"; keywords: "segacd"; type:"controller"}
        ListElement { icon: "\uf27f"; keywords: "pcenginecd"; type:"controller"}
    }
    Component {
        id: cdRomPopup
        CdRomDialog
        {
            focus: true
//            title: qsTr("Disk drive")
            symbol: "\uf275"
            message: gameCdRom + qsTr("A game is in the disk drive")
            firstchoice: qsTr("Launch")
            secondchoice: qsTr("Eject")
            thirdchoice: qsTr("Back")
        }
    }

    property string gameCdRom: ""

    // Timer to show the popup cdrom
    Timer {
        id: popupCdromDelay

        interval: 8000
        repeat: true
        running: true
        onTriggered: {
            gameCdRom = api.internal.system.run("cat /tmp/cd.conf");
            if(gameCdRom.includes("system")) {
                cdRomPopupLoader.active = false;
                cdRomPopupLoader.active = true;
                cdRomPopupLoader.focus = true;
            }
        }
    }

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

        width:  vpx(200)
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
                           //console.log("default emulator: ",game.collections.get(0).getNameAt(i));
                           //console.log("default core: ",game.collections.get(0).getCoreAt(i));
                           //console.log("default core has netplay ? ",game.collections.get(0).hasNetplayAt(i));
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
                        //console.log("emulator to check: ",game.collections.get(0).getNameAt(j));
                        //console.log("core to check: ",game.collections.get(0).getCoreAt(j));
                        //get if one is matching
                        if(game.collections.get(0).getCoreAt(j) === core){
                            //console.log("found emulator: ",game.collections.get(0).getNameAt(j));
                            //console.log("found core: ",game.collections.get(0).getCoreAt(j));
                            //And return if has netplay or not
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
}
