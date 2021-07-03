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


Window {
    id: appWindow
    visible: true
    width: 1280
    height: 720
    title: "Pegasus"
    color: "#000"

    visibility: api.internal.settings.fullscreen
                ? Window.FullScreen : Window.AutomaticVisibility

//    onClosing: {
//        theme.source = "";
//        api.internal.system.quit();
//    }

    // Color palette set with 'themeColor.main' or else
    property var themeColor: {
        return {
//            main:               "#333",
//            secondary:          "#222",
//            screenHeader:       "#222",
//            screenUnderline:    "#555",
//            underline:          "green",
//            textTitle:          "#eee",
//            textLabel:          "#eee",
//            textSublabel:       "#999",
//            textSectionTitle:   "green",
//            textValue:          "#c0c0c0",
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

            source: "MenuLayer.qml"
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
//            function onRequestQuit() {
//                theme.source = "";
//                api.internal.system.quit();
//            }
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
        function onShowPopup(msg,time) {
			popup.message = msg;
			popup.title = "for test purpose";
			popup.open();
			popup.visible = true;
			//start timer to close popup automatically
			popupDelay.interval = time * 1000;
			popupDelay.restart();

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
            popup.close();
        }
    }

 	Popup {
		id: popup
		
		property alias title: titleText.text
		property alias message: messageText.text
		
		property int textSize: vpx(8)
		property int titleTextSize: vpx(10)

		width: 500
		height: 150
		background: Rectangle {
            anchors.fill: popup
            border.color: "transparent"
            color: "transparent"
		}
		x: parent.width * 0.01
		y: parent.height * 0.05

		modal: false
		focus: false
		visible: false
		closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutsideParent

		Column {
			id: dialogBox

			width: parent.width
			height: parent.height
			
			anchors.centerIn: parent
			//scale: 1.0

			//Behavior on scale { NumberAnimation { duration: 125 } }

			// title bar
 			Rectangle {
				id: titleBar
				width: parent.width
				height: popup.titleTextSize * 2.25
				color: themeColor.main

				Text {
					id: titleText

					anchors {
						verticalCenter: parent.verticalCenter
						left: parent.left
						leftMargin: popup.titleTextSize * 0.75
					}

					color: themeColor.textTitle
					font {
						bold: true
						pixelSize: popup.titleTextSize
						family: globalFonts.sans
					}
				}
			}


			// text area
			Rectangle {
				width: parent.width
				height: messageText.height + 3 * popup.textSize
				color: themeColor.secondary
				//radius: height / 2
				
				Text {
					id: messageText

					anchors.centerIn: parent
					width: parent.width - 2 * popup.textSize

					wrapMode: Text.WordWrap
					horizontalAlignment: Text.AlignHCenter

					color: themeColor.textTitle
					font {
						pixelSize: popup.textSize
						family: globalFonts.sans
					}
				}
			}
		}
	}
}
