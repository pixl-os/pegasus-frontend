// Pegasus Frontend
// Copyright (C) 2017-2019  Mátyás Mustoha
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


import "gamepad/preview" as GamepadPreview
import "gamepad"
import "qrc:/qmlutils" as PegasusUtils
import Pegasus.Model 0.12
import QtQuick 2.12
import QtQuick.Window 2.12


FocusScope {
    id: root

    signal close

    anchors.fill: parent
    enabled: focus
    visible: 0 < (x + width) && x < Window.window.width

    function triggerClose() {
        root.stopEscapeTimer();
        root.close();
    }
    readonly property var gamepad: isNewController ? gamepadList.model.get(newControllerIndex) : gamepadList.model.get(gamepadList.currentIndex)
    readonly property bool hasGamepads: (gamepad !== null) || (gamepadList.count !== 0)

    property ConfigField recordingField: null
 
	//properties for new controller case
    property int newControllerIndex : 0
    property bool isNewController: false

    function recordConfig(configField) {
        
        //console.log("function recordConfig(configField)");
        //console.log("configField : ",configField);
        //console.log("recordingField : ",recordingField);
        //if (recordingField !== null) console.log("recordingField.recording : ",recordingField.recording);
        
        // turn off the previously recording field
        if (recordingField !== null && configField !== recordingField)
           {
            recordingField.recording = false;
            //console.log("recordingField.recording = false");
           }
        
        // turn on the currently recording one
        recordingField = configField
        if (recordingField !== null)
           {
            recordingField.recording = true;
            //console.log("recordingField.recording = true");
           }
    
    }
    property real escapeDelay: 1500
    property real escapeStartTime: 0
    property real escapeProgress: 0

    property real validDelay: 1000 //quicker than B/Save/Quit command ;-)
    property real validStartTime: 0
    property real validProgress: 0
	property ConfigField fieldUnderConfiguration: null

    Timer {
        id: escapeTimer
        interval: 50
        repeat: true
        onTriggered: {
            var currentTime = new Date().getTime();
            escapeProgress = (currentTime - escapeStartTime) / escapeDelay;

            if (escapeProgress > 1.0)
                root.triggerClose();
        }
	}
    Timer {
        id: validTimer
        interval: 50
        repeat: true
        onTriggered: {
            var currentTime = new Date().getTime();
            validProgress = (currentTime - validStartTime) / validDelay;
			if (validProgress > 1.0)
				recordConfig(fieldUnderConfiguration);
		}
    }
    function stopEscapeTimer() {
        escapeTimer.stop();
        escapeStartTime = 0;
        escapeProgress = 0;
    }
    function stopValidTimer() {
        validTimer.stop();
        validStartTime = 0;
        validProgress = 0;
    }	
    Keys.onPressed: {
        if (api.keys.isCancel(event) && !event.isAutoRepeat) {
            event.accepted = true;
            escapeStartTime = new Date().getTime();
            escapeTimer.start();
        }
    }
    Keys.onReleased: {
        if (api.keys.isCancel(event) && !event.isAutoRepeat) {
            event.accepted = true;
            stopEscapeTimer();
        }
    }
    Connections {
        target: api.internal.gamepad
        function onButtonConfigured() { 
                                        //console.log("function onButtonConfigured()");
                                        recordConfig(null); 
                                      }
        function onAxisConfigured() { 
                                        //console.log("function onAxisConfigured()");
                                        recordConfig(null); 
                                    }
        function onConfigurationCanceled() {
                                            //console.log("function onConfigurationCanceled()");
                                            recordConfig(null); 
                                            }
    }
    Rectangle {
        id: deviceSelect
        width: parent.width
        height: vpx(70)
        color: themeColor.screenHeader
        opacity: 0.75
        anchors.top: parent.top

        focus: true
        Keys.forwardTo: isNewController ? [] : [gamepadList]
        KeyNavigation.down: configL1

        GamepadName {
            visible: !hasGamepads && !isNewController
            highlighted: deviceSelect.focus
            text: qsTr("No gamepads connected") + api.tr
        }
        ListView {
            id: gamepadList
            anchors.fill: parent

            clip: true
            highlightRangeMode: ListView.StrictlyEnforceRange
            highlightMoveDuration: 300
            orientation: ListView.Horizontal
			Component.onCompleted : currentIndex = (isNewController ? newControllerIndex : 0);

            model: api.internal.gamepad.devices

            delegate: Item {
                width: ListView.view.width
                height: ListView.view.height

                GamepadName {
                    text: {
						// to add info to notice that one or several controllers  is/are available !
                        console.log("Controller: #", newControllerIndex," - isNewController: ", isNewController);
                        if (modelData) {
                            var previous = "";
                            var next = "";
							if ((gamepadList.count > 1) && !isNewController)
							{								
								if (index !== 0) previous = "\uf3cf  "; // < from ionicons
								if (index !== (gamepadList.count-1)) next = "  \uf3d1"; // > from ionicons
							}
                            if (isNewController) return api.internal.gamepad.devices.get(newControllerIndex).name;
                            else return (previous + "#" + (index + 1) + ": " + modelData.name + " (" + modelData.deviceIndex + ")" + next);
						}
						else return ""; 						
					}
					highlighted: deviceSelect.focus
                }
            }
        }
    }
    Rectangle {
        width: parent.width
        color: themeColor.main
        anchors {
            top: deviceSelect.bottom
            bottom: parent.bottom
        }
    }
    FocusScope {
        id: layoutArea
        width: parent.width
        anchors {
            top: deviceSelect.bottom
            bottom: footer.top
        }
        property int horizontalOffset: vpx(-560)
        property int verticalSpacing: vpx(170)

        onActiveFocusChanged:
            if (!activeFocus) padPreview.currentButton = ""

        ConfigGroup {
            label: qsTr("left back") + api.tr
            anchors {
                left: parent.horizontalCenter
                leftMargin: parent.horizontalOffset
                verticalCenter: parent.verticalCenter
                verticalCenterOffset: -parent.verticalSpacing
            }
            ConfigField {
                focus: true
                id: configL1
                text: qsTr("shoulder") + api.tr
                onActiveFocusChanged:
                    if (activeFocus) padPreview.currentButton = "l1"

                pressed: gamepad && gamepad.buttonL1
				input: GamepadManager.GMButton.L1
				inputType: "button"

                KeyNavigation.right: configSelect
                KeyNavigation.down: configL2
            }
            ConfigField {
                id: configL2
                text: qsTr("trigger") + api.tr
                onActiveFocusChanged:
                    if (activeFocus) padPreview.currentButton = "l2"

                pressed: gamepad && gamepad.buttonL2
				input: GamepadManager.GMButton.L2
				inputType: "button"

                KeyNavigation.right: configR2
                KeyNavigation.down: configDpadUp
            }
        }
        ConfigGroup {
            label: qsTr("dpad") + api.tr
            anchors {
                left: parent.horizontalCenter
                leftMargin: parent.horizontalOffset
                verticalCenter: parent.verticalCenter
            }
            ConfigField {
                id: configDpadUp
                text: qsTr("up") + api.tr
                onActiveFocusChanged:
                    if (activeFocus) padPreview.currentButton = "dpup"

                pressed: gamepad && gamepad.buttonUp
				input: GamepadManager.GMButton.Up
				inputType: "button"

                KeyNavigation.right: configA
                KeyNavigation.down: configDpadDown
            }
            ConfigField {
                id: configDpadDown
                text: qsTr("down") + api.tr
                onActiveFocusChanged:
                    if (activeFocus) padPreview.currentButton = "dpdown"

                pressed: gamepad && gamepad.buttonDown
				input: GamepadManager.GMButton.Down
				inputType: "button"

                KeyNavigation.right: configB
                KeyNavigation.down: configDpadLeft
            }
            ConfigField {
                id: configDpadLeft
                text: qsTr("left") + api.tr
                onActiveFocusChanged:
                    if (activeFocus) padPreview.currentButton = "dpleft"

                pressed: gamepad && gamepad.buttonLeft
				input: GamepadManager.GMButton.Left
				inputType: "button"

                KeyNavigation.right: configX
                KeyNavigation.down: configDpadRight
            }
            ConfigField {
                id: configDpadRight
                text: qsTr("right") + api.tr
                onActiveFocusChanged:
                    if (activeFocus) padPreview.currentButton = "dpright"

                pressed: gamepad && gamepad.buttonRight
				input: GamepadManager.GMButton.Right
				inputType: "button"

                KeyNavigation.right: configY
                KeyNavigation.down: configLeftStickX
            }
        }
        ConfigGroup {
            label: qsTr("left stick") + api.tr
            anchors {
                left: parent.horizontalCenter
                leftMargin: parent.horizontalOffset
                verticalCenter: parent.verticalCenter
                verticalCenterOffset: parent.verticalSpacing
            }
            ConfigField {
                id: configLeftStickX
                text: qsTr("x axis") + api.tr
                onActiveFocusChanged:
                    if (activeFocus) padPreview.currentButton = "lx"

                pressed: gamepad && Math.abs(gamepad.axisLeftX) > 0.05
				input: GamepadManager.GMAxis.LeftX
				inputType: "axis"
 
                KeyNavigation.right: configRightStickX
                KeyNavigation.down: configLeftStickY
            }
            ConfigField {
                id: configLeftStickY
                text: qsTr("y axis") + api.tr
                onActiveFocusChanged:
                    if (activeFocus) padPreview.currentButton = "ly"

                pressed: gamepad && Math.abs(gamepad.axisLeftY) > 0.05
 				input: GamepadManager.GMAxis.LeftY
				inputType: "axis"
 
                KeyNavigation.right: configRightStickY
                KeyNavigation.down: configL3
            }
            ConfigField {
                id: configL3
                text: qsTr("press") + api.tr
                onActiveFocusChanged:
                    if (activeFocus) padPreview.currentButton = "l3"

                pressed: gamepad && gamepad.buttonL3
				input: GamepadManager.GMButton.L3
				inputType: "button"

                KeyNavigation.right: configR3
            }
        }
        ConfigGroup {
            label: qsTr("right back") + api.tr
            alignment: Text.AlignRight
            anchors {
                right: parent.horizontalCenter
                rightMargin: parent.horizontalOffset
                verticalCenter: parent.verticalCenter
                verticalCenterOffset: -parent.verticalSpacing
            }
            ConfigField {
                id: configR1
                text: qsTr("shoulder") + api.tr
                onActiveFocusChanged:
                    if (activeFocus) padPreview.currentButton = "r1"

                pressed: gamepad && gamepad.buttonR1
 				input: GamepadManager.GMButton.R1
				inputType: "button"

                KeyNavigation.down: configR2
            }
            ConfigField {
                id: configR2
                text: qsTr("trigger") + api.tr
                onActiveFocusChanged:
                    if (activeFocus) padPreview.currentButton = "r2"

                pressed: gamepad && gamepad.buttonR2
				input: GamepadManager.GMButton.R2
				inputType: "button"

                KeyNavigation.down: configA
            }
        }
        ConfigGroup {
            label: qsTr("abxy") + api.tr
            alignment: Text.AlignRight
            anchors {
                right: parent.horizontalCenter
                rightMargin: parent.horizontalOffset
                verticalCenter: parent.verticalCenter
            }
            ConfigField {
                id: configA
                text: "a"
                onActiveFocusChanged:
                {
                    //console.log("GamepadEditor.qml : activeFocus = ",activeFocus);
                    if (activeFocus) {
                        //console.log("GamepadEditor.qml : onActiveFocusChanged");
                        padPreview.currentButton = "a";
                    }
                }
                pressed: gamepad && gamepad.buttonSouth
				input: GamepadManager.GMButton.South
				inputType: "button"

                KeyNavigation.down: configB
            }
            ConfigField {
                id: configB
                text: "b"
                onActiveFocusChanged:
                    if (activeFocus) padPreview.currentButton = "b"

                pressed: gamepad && gamepad.buttonEast
				input: GamepadManager.GMButton.East
				inputType: "button"

                KeyNavigation.down: configX
            }
            ConfigField {
                id: configX
                text: "x"
                onActiveFocusChanged:
                    if (activeFocus) padPreview.currentButton = "x"

                pressed: gamepad && gamepad.buttonWest
				input: GamepadManager.GMButton.West
				inputType: "button"

                KeyNavigation.down: configY
            }
            ConfigField {
                id: configY
                text: "y"
                onActiveFocusChanged:
                    if (activeFocus) padPreview.currentButton = "y"

                pressed: gamepad && gamepad.buttonNorth
 				input: GamepadManager.GMButton.North
				inputType: "button"

                KeyNavigation.down: configRightStickX
            }
        }
        ConfigGroup {
            label: qsTr("right stick") + api.tr
            alignment: Text.AlignRight
            anchors {
                right: parent.horizontalCenter
                rightMargin: parent.horizontalOffset
                verticalCenter: parent.verticalCenter
                verticalCenterOffset: parent.verticalSpacing
            }
            ConfigField {
                id: configRightStickX
                text: qsTr("x axis") + api.tr
                onActiveFocusChanged:
                    if (activeFocus) padPreview.currentButton = "rx"

                pressed: gamepad && Math.abs(gamepad.axisRightX) > 0.05
 				input: GamepadManager.GMAxis.RightX
				inputType: "axis"
				
                KeyNavigation.down: configRightStickY
            }
            ConfigField {
                id: configRightStickY
                text: qsTr("y axis") + api.tr
                onActiveFocusChanged:
                    if (activeFocus) padPreview.currentButton = "ry"

                pressed: gamepad && Math.abs(gamepad.axisRightY) > 0.05
 				input: GamepadManager.GMAxis.RightY
				inputType: "axis"

                KeyNavigation.down: configR3
            }
            ConfigField {
                id: configR3
                text: qsTr("press") + api.tr
                onActiveFocusChanged:
                    if (activeFocus) padPreview.currentButton = "r3"

                pressed: gamepad && gamepad.buttonR3
				input: GamepadManager.GMButton.R3
				inputType: "button"
				
            }
        }
        Column {
            spacing: vpx(1)
            anchors {
                horizontalCenter: parent.horizontalCenter
                verticalCenter: parent.verticalCenter
                verticalCenterOffset: vpx(-220)
            }
            ConfigGroupLabel {
                text: qsTr("center") + api.tr
                anchors.horizontalCenter: parent.horizontalCenter
            }
            Row {
                spacing: vpx(1)
                property int alignment: Text.AlignHCenter

                ConfigField {
                    id: configSelect
                    text: qsTr("select") + api.tr
                    onActiveFocusChanged:
                        if (activeFocus) padPreview.currentButton = "select"

                    pressed: gamepad && gamepad.buttonSelect
					input: GamepadManager.GMButton.Select
					inputType: "button"

                    KeyNavigation.up: deviceSelect
                    KeyNavigation.down: configL1
                    KeyNavigation.right: configGuide
                }
                ConfigField {
                    id: configGuide
                    text: qsTr("guide") + api.tr
                    onActiveFocusChanged:
                        if (activeFocus) padPreview.currentButton = "guide"

                    pressed: gamepad && gamepad.buttonGuide
					input: GamepadManager.GMButton.Guide
					inputType: "button"

                    KeyNavigation.up: deviceSelect
                    KeyNavigation.right: configStart
                }
                ConfigField {
                    id: configStart
                    text: qsTr("start") + api.tr
                    onActiveFocusChanged:
                        if (activeFocus) padPreview.currentButton = "start"

                    pressed: gamepad && gamepad.buttonStart
					input: GamepadManager.GMButton.Start
					inputType: "button"

                    KeyNavigation.up: deviceSelect
                    KeyNavigation.down: configR1
                    KeyNavigation.right: configR1
                }
            }
        }
        GamepadPreview.Container {
            id: padPreview
            gamepad: root.gamepad
        }
    }
    Item {
        id: footer
        width: parent.width
        height: vpx(50)
        anchors.bottom: parent.bottom

        Rectangle {
            width: parent.width * 0.97
            height: vpx(1)
            color: "#777"
            anchors.top: parent.top
            anchors.horizontalCenter: parent.horizontalCenter
        }
        Canvas {
            width: backButtonIcon.width + vpx(4)
            height: width
            anchors.centerIn: backButtonIcon

            property real progress: escapeProgress
            onProgressChanged: requestPaint()
			visible: {
				if(recordingField !== null){
					if (recordingField.recording) return false; 
				}
				return true;
			}
			
            onPaint: {
                var ctx = getContext('2d');
                ctx.clearRect(0, 0, width, height);

                var center = width / 2;
                var startAngle = -Math.PI / 2

                ctx.beginPath();
                ctx.fillStyle = "#eee";
                ctx.moveTo(center, center);
                ctx.arc(center, center, center,
                        startAngle, startAngle + Math.PI * 2 * progress, false);
                ctx.fill();
            }
        }
        Rectangle {
            id: backButtonIcon
            height: label.height
            width: height
            radius: width * 0.5
            border { color: "#777"; width: vpx(1) }
            color: "transparent"
			visible: {
				if(recordingField !== null){
					if (recordingField.recording) return false; 
				}
                return true;
			}

            anchors {
                right: label.left
                verticalCenter: parent.verticalCenter
                verticalCenterOffset: vpx(1)
                margins: vpx(10)
            }
            Text {
                text: "B"
                color: escapeStartTime ? "#eee" : "#777"
                font {
                    family: global.fonts.sans
                    pixelSize: parent.height * 0.7
                }
                anchors.centerIn: parent
            }
        }
        Text {
            id: label
            text: qsTr("hold down to quit") + api.tr
            verticalAlignment: Text.AlignTop
			visible: {
				if(recordingField !== null){
                    if (recordingField.recording) return false;
                }
                return true;
			}

            color: escapeStartTime ? "#eee" : "#777"
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
		//add rectangle + text for 'valid' button
        Canvas {
            width: validButtonIcon.width + vpx(4)
            height: width
            anchors.centerIn: validButtonIcon
			visible: {
				if(recordingField !== null){
					if (recordingField.recording) return false; 
				}
				return true;
			}   
			
            property real progress: validProgress
            onProgressChanged: requestPaint()
			
            onPaint: {
                var ctx = getContext('2d');
                ctx.clearRect(0, 0, width, height);

                var center = width / 2;
                var startAngle = -Math.PI / 2

                ctx.beginPath();
                ctx.fillStyle = "#eee";
                ctx.moveTo(center, center);
                ctx.arc(center, center, center,
                        startAngle, startAngle + Math.PI * 2 * progress, false);
                ctx.fill();
            }
        }
        Rectangle {
            id: validButtonIcon
            height: label.height
            width: height
            radius: width * 0.5
            border { color: "#777"; width: vpx(1) }
            color: "transparent"
			visible: {
				if (deviceSelect.focus) return false;
				if(recordingField !== null){
					if (recordingField.recording) return false; 
				}
				return true;
			}			
            anchors {
                right: labelA.left
                verticalCenter: parent.verticalCenter
                verticalCenterOffset: vpx(1)
                margins: vpx(10)
            }
            Text {
                text: "A"
                color: "#777"
                font {
                    family: global.fonts.sans
                    pixelSize: parent.height * 0.7
                }
                anchors.centerIn: parent
            }
        }
        Text {
            id: labelA
            text: qsTr("hold down to edit") + api.tr
            verticalAlignment: Text.AlignTop
            color: "#777"
			visible: {
				if (deviceSelect.focus) return false;
				if(recordingField !== null){
					if (recordingField.recording) return false; 
				}
				return true;
			}
            
			font {
                family: global.fonts.sans
                pixelSize: vpx(22)
                capitalization: Font.SmallCaps
            }
            anchors {
                verticalCenter: parent.verticalCenter
                verticalCenterOffset: vpx(-1)
                right: backButtonIcon.left; rightMargin: parent.width * 0.015
            }
        }
		//add rectangle + text for 'wizard' launch
        Rectangle {
            id: wizardButtonIcon
            height: labelWizard.height
            width: height
            radius: width * 0.5
            border { color: "#777"; width: vpx(1) }
            color: "transparent"
			visible: (recordingField !== null) //18-08-21: change to hide this icon for the moment in case of wizard/stepbystep
			
            anchors {
                left: parent.left;
                verticalCenter: parent.verticalCenter
                verticalCenterOffset: vpx(1)
                margins: vpx(10)
            }
            Text {
                text: "?"
                color: "#777"
                font {
                    family: global.fonts.sans
                    pixelSize: parent.height * 0.7
                }
                anchors.centerIn: parent
            }
        }
        Text {
            id: labelWizard
            text: {
				if(recordingField !== null)	if (recordingField.recording) return (qsTr("press button") + "/" + qsTr("move axis") + api.tr);		
				//return (qsTr("press 3 times for 'step by step' conf") + api.tr);
				//18-08-21: replaced by empty string for the moment to avoid display and traduction in french.
				return (qsTr("") + api.tr);
			}
            verticalAlignment: Text.AlignTop
            color: "#777"
            font {
                family: global.fonts.sans
                pixelSize: vpx(22)
                capitalization: Font.SmallCaps
            }
            anchors {
                verticalCenter: parent.verticalCenter
                verticalCenterOffset: vpx(-1)
                left: wizardButtonIcon.right; leftMargin: parent.width * 0.005
            }
        }
		//add rectangle + text for 'directions' command
        Rectangle {
            id: directionsButtonIcon
            height: labelDirections.height
            width: height
            radius: width * 0.5
            border { color: "#777"; width: vpx(1) }
            color: "transparent"
			visible: {
				if(recordingField !== null){
					if (recordingField.recording) return false; 
				}
				return true;
			}            
			anchors {
                left: labelWizard.right;
                verticalCenter: parent.verticalCenter
                verticalCenterOffset: vpx(1)
                margins: vpx(10)
            }
            Text {
                text: "\uf1cb"
                color: "#777"
                font {
                    family: global.fonts.ion
                    pixelSize: parent.height
                }
                anchors.centerIn: parent
            }
        }
        Text {
            id: labelDirections
            text: qsTr("select input") + (isNewController ? "" : ("/" + qsTr("controller"))) + api.tr
            verticalAlignment: Text.AlignTop
            color: "#777"
			visible: {
				if(recordingField !== null){
					if (recordingField.recording) return false; 
				}
				return true;
			}            
			
            font {
                family: global.fonts.sans
                pixelSize: vpx(22)
                capitalization: Font.SmallCaps
            }
            anchors {
                verticalCenter: parent.verticalCenter
                verticalCenterOffset: vpx(-1)
                left: directionsButtonIcon.right; leftMargin: parent.width * 0.005
            }
        }  
    }
	
    MouseArea {
        anchors.fill: parent
        acceptedButtons: Qt.RightButton
        onClicked: root.triggerClose()
    }
    PegasusUtils.HorizontalSwipeArea {
        anchors.fill: parent
        onSwipeRight: root.triggerClose()
    }
}
