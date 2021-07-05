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
        function onShowPopup(title,message,delay) {
			//init parameters
			//popup.message = message;
			console.log("popup.height before: ",popup.height);			
			var lenght = 40;
			//test = "123456789 123456789 123456789 1234567890";
			popup.message = "123456789 123456789 123456789 1234567890";//for test purpose
    		//console.log("message.lenght: ",test.lenght);
			//return vpx(60);
			var height = 30 + (30 * (lenght/40));
			popup.height = height;  //vpx(120)
			console.log("popup.height after: ",popup.height);
			//popup.title = title;
			popup.title = "123456789 123456789 123456789 1234567890";//for test purpose
			//delay provided in second and interval is in ms
			popupDelay.interval = delay * 1000;
			//launch popen
			popup.open();
			popup.visible = true;
			//start timer to close popup automatically
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
		
		property int textSize: vpx(12)
		property int titleTextSize: vpx(12)

		width:  vpx(310)
		height: vpx(60)
				/* {
				 console.log("message.lenght: ",message.lenght);
				   //return vpx(60);
				 return vpx(30 + (30 * (message.lenght/40)));  //vpx(120)
				 } */
				
		background: Rectangle {
            anchors.fill: popup
            border.color: themeColor.textTitle
            //color: "transparent"
			color: themeColor.secondary
			opacity: 0.8
			radius: height/4
			Behavior on opacity { NumberAnimation { duration: 100 } }
		}
		//need to work in x/y, no anchor.top/bottom/left/right/etc... available
		x: (parent.width/2) - (width/2)//parent.width * 0.01
		y: parent.height - height - (parent.height * 0.03) //parent.height * 0.05

		modal: false
		focus: false
		visible: false
		closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutsideParent

		Column {
			id: dialogBox

			width: parent.width
			height: parent.height
			
			anchors.centerIn: parent
			//opacity: 0.8
			//Behavior on opacity { NumberAnimation { duration: 100 } }
			
			// title bar
/*  			Rectangle {
				id: titleBar
				width: parent.width
				height: popup.titleTextSize * 1.75 //2.25
				color: themeColor.main
				radius: height/4
				Text {
					id: titleText

					anchors {
						verticalCenter: parent.verticalCenter
						left: parent.left
						leftMargin: popup.titleTextSize * 0.5 //0.75
					}

					color: themeColor.textTitle
					font {
						bold: true
						pixelSize: popup.titleTextSize
						family: globalFonts.sans
					}
				}
			} */


			// text area
			Rectangle {
				width: parent.width
				height: parent.height //(popup.titleTextSize * 1.75) + (messageText.height + 3 * popup.textSize)
				color: "transparent" //themeColor.secondary

				Text {
					id: titleText
					elide: Text.ElideRight
					wrapMode: Text.WordWrap
					
					anchors {
						//verticalCenter: parent.verticalCenter
						top: parent.top
						left: parent.left
						right:  parent.right;
						leftMargin: popup.titleTextSize * 0.5 //0.75
						rightMargin: popup.titleTextSize * 0.5
					}
					width: parent.width - (2 * anchors.leftMargin)
					height: popup.titleTextSize * 1.25 //2.25
					color: themeColor.textTitle
					font {
						bold: true
						pixelSize: popup.titleTextSize
						family: globalFonts.sans
					}
				}
				
				Text {
					id: messageText
					elide: Text.ElideRight
					wrapMode: Text.WordWrap

					anchors {
						//verticalCenter: parent.verticalCenter
						top: titleText.bottom
						bottom: parent.bottom
						left: parent.left
						right: parent.right
						leftMargin: popup.titleTextSize * 0.5 //0.75
						rightMargin: popup.titleTextSize * 0.5 //0.75
					}
					//width: parent.width - 2 * popup.textSize
					width: parent.width - (2 * anchors.leftMargin)
					horizontalAlignment: Text.AlignHCenter
					verticalAlignment: Text.AlignVCenter
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
