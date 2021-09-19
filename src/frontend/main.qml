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
        id: confirmDialog
        anchors.fill: parent
    }
    Connections {
        target: confirmDialog.item
        function onCancel() { content.focus = true; }
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
}
