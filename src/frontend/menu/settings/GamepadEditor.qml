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


//import "gamepad/preview" as GamepadPreview
import "gamepad"
import "qrc:/qmlutils" as PegasusUtils
import Pegasus.Model 0.12
import QtQuick 2.15
import QtQuick.Window 2.12


FocusScope {
    id: root

    property int selectedGamepadIndex: 0

    property var padPreview

    signal close

    anchors.fill: parent
    enabled: focus
    visible: 0 < (x + width) && x < Window.window.width

    function triggerClose() {
        root.stopEscapeTimer();
        root.close();
    }
    readonly property var gamepad: {
        if(isNewController) return gamepadList.model.get(newControllerIndex);
        else{
            var selectedGamepad = gamepadList.model.get(gamepadList.currentIndex);
            //console.log("Selected gamepad.deviceId : ", selectedGamepad.deviceId);
            //console.log("Selected gamepad.deviceIndex : ",selectedGamepad.deviceIndex);
            //console.log("Selected gamepad.deviceInstance : ",selectedGamepad.deviceInstance);
            return selectedGamepad;
        }
    }
    onGamepadChanged: {
        //console.log("onGamepadChanged");
        //to force reload of Pad Preview when we change gamepad
        if(root.gamepad !== null){
            //console.log("root.gamepad.name : ", root.gamepad.name);
            loaderPadPreview.enabled = false;
            loaderPadPreview.source = "";
            loaderPadPreview.layoutIndex = layoutArea.getControllerLayoutIndex(root.gamepad.name);
            loaderPadPreview.source = myControllerLayout.get(loaderPadPreview.layoutIndex).qml;
            loaderPadPreview.enabled = true;
        }
    }

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
        if (recordingField != null && configField !== recordingField)
           {
            recordingField.recording = false;
            //console.log("recordingField.recording = false");
           }
        
        // turn on the currently recording one
        recordingField = configField
        if (recordingField != null)
           {
            recordingField.recording = true;
            //console.log("recordingField.recording = true");
           }
    }

    function resetConfig(inputType,text) {
        //display dialog box to alert that nutton/axis is reset now
        genericMessage.setSource("../../dialogs/GenericOkDialog.qml",
                                 { "title": qsTr("Reset") + " " + inputType, "message": qsTr("You remove now the assignment of ") + text.toUpperCase() });
        genericMessage.focus = true;
    }

    property real escapeDelay: 1500
    property real escapeStartTime: 0
    property real escapeProgress: 0

    property real validDelay: 1000 //quicker than B/Save/Quit command ;-)
    property real validStartTime: 0
    property real validProgress: 0

    property real resetDelay: 2000 //quicker than A/B/Valid/Record/Save/Quit command ;-)
    property real resetStartTime: 0
    property real resetProgress: 0

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
    Timer {
        id: resetTimer
        interval: 50
        repeat: true
        onTriggered: {
            var currentTime = new Date().getTime();
            resetProgress = (currentTime - resetStartTime) / resetDelay;
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
    function stopResetTimer() {
        resetTimer.stop();
        resetStartTime = 0;
        resetProgress = 0;
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
            Component.onCompleted : {
                gamepadList.currentIndex = (isNewController ? newControllerIndex : selectedGamepadIndex);
                //console.log("Controller: #", isNewController ? newControllerIndex : selectedGamepadIndex," - isNewController: ", isNewController);
                //console.log("gamepadList.currentIndex : ", gamepadList.currentIndex);
			}

            model: api.internal.gamepad.devices

            delegate: Item {
                width: ListView.view.width
                height: ListView.view.height

                GamepadName {
                    id:gamepadname
                    TextMetrics {
                        id: endOfLineMetrics
                        font: gamepadname.font
                        text: {
                            // to add info to notice that one or several controllers  is/are available !
                            var endOfLine = "";
                            if (modelData) {
                                endOfLine = "... (" + api.internal.gamepad.devices.get(newControllerIndex).deviceInstance + ")";
                                if ((gamepadList.count > 1) && !isNewController)
                                {
                                    if (gamepadList.currentIndex !== (gamepadList.count-1)) endOfLine = endOfLine + "  \uf3d1"; // < from ionicons
                                }
                            }
                            return endOfLine;
                        }
                    }
                    TextMetrics {
                        id: textMetrics
                        font: gamepadname.font
                        elide: Text.ElideRight
                        elideWidth: root.width - ((gamepadname.anchors.leftMargin * 2) + endOfLineMetrics.boundingRect.width)
                        text: {
                            //console.log("root.width:",root.width);
                            // to add info to notice that one or several controllers  is/are available !
                            if (modelData) {
                                var previous = "";
                                if ((gamepadList.count > 1) && !isNewController)
                                {
                                    if (gamepadList.currentIndex !== 0) previous = "\uf3cf  "; // < from ionicons
                                }
                                if (isNewController){
                                    return  api.internal.gamepad.devices.get(newControllerIndex).name;

                                }
                                else
                                {
                                    return previous + "#" + (gamepadList.currentIndex + 1) + ": " + api.internal.gamepad.devices.get(gamepadList.currentIndex).name;
                                }
                            }
                            else return "";
                        }
                    }
                    text: {
                        // to add info to notice that one or several controllers  is/are available !
                        if (modelData) {
                            var next = "";
							if ((gamepadList.count > 1) && !isNewController)
							{								
                                if (gamepadList.currentIndex !== (gamepadList.count-1)) next = "  \uf3d1"; // < from ionicons
							}

                            var elidePadding = ""
                            if(textMetrics.elidedText.length < textMetrics.text.length){
                                elidePadding = "..."
                            }

                            //console.log("GamepadName index : ",index);
                            //console.log("textMetrics.elidedText: ",textMetrics.elidedText);
                            //console.log("textMetrics.Text: ",textMetrics.text);
                            if (isNewController){
                                return textMetrics.elidedText + elidePadding + " (" + api.internal.gamepad.devices.get(newControllerIndex).deviceInstance + ")";
                            }
                            else
                            {
                                return textMetrics.elidedText + elidePadding + " (" + api.internal.gamepad.devices.get(gamepadList.currentIndex).deviceInstance + ")" + next;
                            }
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

        //use loader to load container dynamically
        //list model to manage layout parameters (file name, etc...)
        ListModel {
            id: myControllerLayout
            //CONTROLLERS LAYOUT TO DISPLAY IN EDITOR depending of layout name
            ListElement { name: "default"; qml: "gamepad/preview/Container.qml"} // By default

            ListElement {   name: "snes"; qml: "gamepad/preview/ContainerCustom.qml";

                            hasDedicatedGuide: false;
                            hasSelect: true;
                            hasStart: true;

                            hasA: true;
                            hasB: true;
                            hasX: true;
                            hasY: true;
                            hasNintendoPad : true;

                            hasL1 : true; hasR1 : true;
                            hasL2 : true; hasR2 : true;

                            hasLeftStick : false; hasRightStick : false;
                            hasL3 : false; hasR3 : false;

                            hadDpad : true;
                            hasButtonsForDpad : false;

                            hasScreenshotButton : false;

                            ratio: 0.8; padBaseSourceSizeWidth : 906 ; padBaseSourceSizeHeight : 398;
                            //parameters for select
                            padSelectWidth : 69;
                            padSelectHeight : 59;
                            padSelectTopY: 205;
                            padSelectLeftX: 334;

                            //parameters for start
                            padStartWidth : 69;
                            padStartHeight : 59;
                            padStartTopY: 205;
                            padStartLeftX: 432;

                            //parameters for A/B/X/Y
                            padAWidth : 71;
                            padAHeight : 70;
                            padATopY: 170;
                            padALeftX: 763;

                            padBWidth : 71;
                            padBHeight : 71;
                            padBTopY: 237;
                            padBLeftX: 677;

                            padXWidth : 71;
                            padXHeight : 71;
                            padXTopY: 103;
                            padXLeftX: 677;

                            padYWidth : 73;
                            padYHeight : 72;
                            padYTopY: 170;
                            padYLeftX: 590;

                            //parameter for Dpad
                            dpadAreaTopY: 126;
                            dpadAreaBottomY: 285;
                            dpadAreaLeftX: 112;
                            dpadAreaRightX: 270;

                            //parameter for L1
                            padL1Width : 198;
                            padL1Height : 37;
                            padL1TopY: 0;
                            padL1LeftX: 97;

                            //parameter for R1
                            padR1Width : 198;
                            padR1Height : 36;
                            padR1TopY: 1;
                            padR1LeftX: 612;

                            //parameter for L2
                            padL2Width : 48;
                            padL2Height : 5;
                            padL2TopY: 4;
                            padL2LeftX: 350;

                            //parameter for R2
                            padR2Width : 54;
                            padR2Height : 6;
                            padR2TopY: 4;
                            padR2LeftX: 509;

            } //As SNES pad (but with L2/R2 to be compatible with switch online ones)

            ListElement {   name: "nes"; qml: "gamepad/preview/ContainerCustom.qml";

                            hasDedicatedGuide: false;
                            hasSelect: true;
                            hasStart: true;

                            hasA: true;
                            hasB: true;
                            hasNintendoPad : true
                            hasX: false;
                            hasY: false;

                            hasL1 : true; hasR1 : true;
                            hasL2 : false; hasR2 : false;

                            hasLeftStick : false; hasRightStick : false;
                            hasL3 : false; hasR3 : false;

                            hadDpad : true;
                            hasButtonsForDpad : false;

                            hasScreenshotButton : false;

                            ratio: 0.8; padBaseSourceSizeWidth : 778 ; padBaseSourceSizeHeight : 347;
                            //parameters for select
                            padSelectWidth : 62;
                            padSelectHeight : 25;
                            padSelectTopY: 245;
                            padSelectLeftX: 279;

                            //parameters for start
                            padStartWidth : 62;
                            padStartHeight : 25;
                            padStartTopY: 245;
                            padStartLeftX: 380;

                            //parameters for A/B (no X/Y in this case)

                            padAWidth : 69;
                            padAHeight : 68;
                            padATopY: 228;
                            padALeftX: 612;

                            padBWidth : 69;
                            padBHeight : 67;
                            padBTopY: 228;
                            padBLeftX: 511;

                            //parameter for Dpad
                            dpadAreaTopY: 163;
                            dpadAreaBottomY: 289;
                            dpadAreaLeftX: 64;
                            dpadAreaRightX: 205;

                            //parameter for L1
                            padL1Width : 53;
                            padL1Height : 12;
                            padL1TopY: 7;
                            padL1LeftX: 213;
                            //parameter for R1
                            padR1Width : 52;
                            padR1Height : 12;
                            padR1TopY: 7;
                            padR1LeftX: 473;

                            //to adapt contrast/brightness
                            contrast : 0.4
                            brightness: 0.6

            } //As NES pad (but with L1/R1 to be compatible with switch online ones)

            ListElement {   name: "xbox360"; qml: "gamepad/preview/ContainerCustom.qml";

                            hasDedicatedGuide: true;
                            hasSelect: true;
                            hasStart: true;

                            hasA: true;
                            hasB: true;
                            hasX: true;
                            hasY: true;
                            hasNintendoPad : false;

                            hasL1 : true; hasR1 : true;
                            hasL2 : true; hasR2 : true;

                            hasLeftStick : true; hasRightStick : true;
                            hasL3 : true; hasR3 : true;

                            hadDpad : true;
                            hasButtonsForDpad : false;

                            hasScreenshotButton : false;

                            ratio: 0.6; padBaseSourceSizeWidth : 958 ; padBaseSourceSizeHeight : 751;

                            //parameters for select
                            padSelectWidth : 50;
                            padSelectHeight : 43;
                            padSelectTopY: 252;
                            padSelectLeftX: 352;

                            //parameters for start
                            padStartWidth : 50;
                            padStartHeight : 43;
                            padStartTopY: 252;
                            padStartLeftX: 558;

                            //parameters for guide/hotkey
                            padGuideWidth : 94;
                            padGuideHeight : 94;
                            padGuideTopY: 227;
                            padGuideLeftX: 434;

                            //parameters for A/B/X/Y
                            padAWidth : 65;
                            padAHeight : 67;
                            padATopY: 308;
                            padALeftX: 730;

                            padBWidth : 65;
                            padBHeight : 66;
                            padBTopY: 233;
                            padBLeftX: 806;

                            padXWidth : 66;
                            padXHeight : 67;
                            padXTopY: 233;
                            padXLeftX: 655;

                            padYWidth : 66;
                            padYHeight : 67;
                            padYTopY: 158;
                            padYLeftX: 730;

                            //parameter for Dpad
                            dpadAreaTopY: 357;
                            dpadAreaBottomY: 516;
                            dpadAreaLeftX: 253;
                            dpadAreaRightX: 411;

                            //parameter for L1
                            padL1Width : 171;
                            padL1Height : 74;
                            padL1TopY: 77;
                            padL1LeftX: 113;

                            //parameter for R1
                            padR1Width : 173;
                            padR1Height : 72;
                            padR1TopY: 76;
                            padR1LeftX: 673;

                            //parameter for L2
                            padL2Width : 64;
                            padL2Height : 79;
                            padL2TopY: 0;
                            padL2LeftX: 194;

                            //parameter for R2
                            padR2Width : 62;
                            padR2Height : 77;
                            padR2TopY: 1;
                            padR2LeftX: 701;

                            //parameter for Left stick
                            lStickWidth : 127;
                            lStickHeight : 128;
                            lStickTopY: 202;
                            lStickLeftX: 131;

                            //parameter for Right stick
                            rStickWidth : 129;
                            rStickHeight : 129;
                            rStickTopY: 374;
                            rStickLeftX: 553;

                            //to adapt contrast/brightness
                            contrast : 0.1
                            brightness: 0.2

            } //As Microsoft XBOX 360 pad

            ListElement {   name: "ps4"; qml: "gamepad/preview/ContainerCustom.qml";

                            hasDedicatedGuide: true;
                            hasSelect: true;
                            hasStart: true;

                            hasA: true;
                            hasB: true;
                            hasX: true;
                            hasY: true;
                            hasNintendoPad : false;

                            hasL1 : true; hasR1 : true;
                            hasL2 : true; hasR2 : true;

                            hasLeftStick : true; hasRightStick : true;
                            hasL3 : true; hasR3 : true;

                            hadDpad : true;
                            hasButtonsForDpad : true;

                            hasScreenshotButton : false;

                            ratio: 0.5; padBaseSourceSizeWidth : 1267 ; padBaseSourceSizeHeight : 857;

                            //parameters for select
                            padSelectWidth : 44;
                            padSelectHeight : 74;
                            padSelectTopY: 134;
                            padSelectLeftX: 359;

                            //parameters for start
                            padStartWidth : 42;
                            padStartHeight : 74;
                            padStartTopY: 136;
                            padStartLeftX: 868;

                            //parameters for guide/hotkey
                            padGuideWidth : 65;
                            padGuideHeight : 66;
                            padGuideTopY: 437;
                            padGuideLeftX: 598;

                            //parameters for A/B/X/Y

                            //As cross
                            padAWidth : 95;
                            padAHeight : 96;
                            padATopY: 342;
                            padALeftX: 975;

                            //As cycle
                            padBWidth : 96;
                            padBHeight : 94;
                            padBTopY: 251;
                            padBLeftX: 1066;

                            //As square
                            padXWidth : 95;
                            padXHeight : 94;
                            padXTopY: 250;
                            padXLeftX: 885;

                            //As Triangle
                            padYWidth : 94;
                            padYHeight : 96;
                            padYTopY: 160;
                            padYLeftX: 975;

                            //parameter for Dpad with dedicated buttons and separated
                            dpadUpWidth : 69;
                            dpadUpHeight : 89;
                            dpadUpTopY: 189;
                            dpadUpLeftX: 213;

                            dpadDownWidth : 67;
                            dpadDownHeight : 89;
                            dpadDownTopY: 309;
                            dpadDownLeftX: 215;

                            dpadLeftWidth : 89;
                            dpadLeftHeight : 70;
                            dpadLeftTopY: 259;
                            dpadLeftLeftX: 145;

                            dpadRightWidth : 88;
                            dpadRightHeight : 70;
                            dpadRightTopY: 259;
                            dpadRightLeftX: 264;

                            //parameter for L1
                            padL1Width : 161;
                            padL1Height : 37;
                            padL1TopY: 61;
                            padL1LeftX: 173;

                            //parameter for R1
                            padR1Width : 160;
                            padR1Height : 36;
                            padR1TopY: 65;
                            padR1LeftX: 938;

                            //parameter for L2
                            padL2Width : 144;
                            padL2Height : 72;
                            padL2TopY: 0;
                            padL2LeftX: 190;

                            //parameter for R2
                            padR2Width : 143;
                            padR2Height : 73;
                            padR2TopY: 1;
                            padR2LeftX: 933;

                            //parameter for Left stick
                            lStickWidth : 156;
                            lStickHeight : 156;
                            lStickTopY: 386;
                            lStickLeftX: 358;

                            //parameter for Right stick
                            rStickWidth : 156;
                            rStickHeight : 156;
                            rStickTopY: 389;
                            rStickLeftX: 754;

                            //to adapt contrast/brightness
                            contrast : 0.4
                            brightness: 0.6
            } //As Sony PS4 pad

            ListElement {   name: "n64"; qml: "gamepad/preview/ContainerCustom.qml";

                            hasDedicatedGuide: true;
                            hasSelect: true;
                            hasStart: true;

                            hasA: true;
                            hasB: true;
                            hasX: false;
                            hasY: false;
                            hasNintendoPad : false;

                            hasL1 : true; hasR1 : true;
                            hasL2 : true; hasR2 : true;

                            hasLeftStick : true; hasRightStick : true; hasButtonsForRightStick : true;
                            hasL3 : false; hasR3 : false;

                            hadDpad : true;
                            hasButtonsForDpad : false;

                            hasScreenshotButton : false;

                            ratio: 0.6; padBaseSourceSizeWidth : 858 ; padBaseSourceSizeHeight : 752;

                            //parameters for select (Screenshot button on Nintendo Switch one)
                            padSelectWidth : 34;
                            padSelectHeight : 24;
                            padSelectTopY: 58;
                            padSelectLeftX: 300;

                            //parameters for start
                            padStartWidth : 63;
                            padStartHeight : 56;
                            padStartTopY: 333;
                            padStartLeftX: 399;

                            //parameters for guide/hotkey (Home of Nintendo Switch N64 controller or Home button of Mayflash N64 Adapter V2 - only on player 1)
                            padGuideWidth : 36;
                            padGuideHeight : 17;
                            padGuideTopY: 61;
                            padGuideLeftX: 527;

                            //parameters for A/B (X/Y not used for the moment)
                            padAWidth : 66;
                            padAHeight : 61;
                            padATopY: 375;
                            padALeftX: 620;

                            padBWidth : 69;
                            padBHeight : 64;
                            padBTopY: 325;
                            padBLeftX: 559;

                            padXWidth : 0;
                            padXHeight : 0;
                            padXTopY: 0;
                            padXLeftX: 0;

                            padYWidth : 0;
                            padYHeight : 0;
                            padYTopY: 0;
                            padYLeftX: 0;

                            //parameter for Dpad
                            dpadAreaTopY: 267;
                            dpadAreaBottomY: 391;
                            dpadAreaLeftX: 97;
                            dpadAreaRightX: 227;

                            //parameter for L1 (L)
                            padL1Width : 187;
                            padL1Height : 89;
                            padL1TopY: 91;
                            padL1LeftX: 73;

                            //parameter for R1 (R)
                            padR1Width : 186;
                            padR1Height : 89;
                            padR1TopY: 91;
                            padR1LeftX: 603;

                            //parameter for L2 (Z)
                            padL2Width : 73;
                            padL2Height : 86;
                            padL2TopY: 605;
                            padL2LeftX: 178;

                            //parameter for R2 (ZR on nintendo switch N64 controller)
                            padR2Width : 49;
                            padR2Height : 21;
                            padR2TopY: 82;
                            padR2LeftX: 522;

                            //parameter for Left stick
                            lStickWidth : 81;
                            lStickHeight : 71;
                            lStickTopY: 477;
                            lStickLeftX: 390;

                            //parameter for Right stick
                            //need to set the area as when we have a stick to display green lines
                            rStickWidth : 157;
                            rStickHeight : 146;
                            rStickTopY: 230;
                            rStickLeftX: 643;

                            //parameters to manage C buttons
                            rStickUpWidth : 52;
                            rStickUpHeight : 56;
                            rStickUpTopY: 232;
                            rStickUpLeftX: 698;

                            rStickDownWidth : 51;
                            rStickDownHeight : 50;
                            rStickDownTopY: 327;
                            rStickDownLeftX: 696;

                            rStickLeftWidth : 53;
                            rStickLeftHeight : 55;
                            rStickLeftTopY: 281;
                            rStickLeftLeftX: 643;

                            rStickRightWidth : 52;
                            rStickRightHeight : 55;
                            rStickRightTopY: 273;
                            rStickRightLeftX: 748;

                            //to adapt contrast/brightness
                            contrast : 0.1
                            brightness: 0.2

            } //As Nintendo 64 pad (but C buttons are on RStick, no X/Y, Z as L2, ZR as R2)

        }

        //function to dynamically set container layout from gamepad name
        function getControllerLayoutIndex(controllerName) {
            var layoutName = "";
            var layoutQml = "";
            let type = "controller";
            let i = 0;
            //split name that could contain the name + hid name separated by ' - '
            const names = controllerName.split(" - ");
            if(names.length >= 2){
                controllerName = names[1]; //to keep only the hid part if exist
            }
            //searchIcon using the good type
            do{
                const keywords = myDeviceIcons.get(i).keywords.split(",");
                for(var j = 0; j < keywords.length;j++)
                {
                    if (isKeywordFound(controllerName, "", keywords[j]) && (myDeviceIcons.get(i).type === type ) && (keywords[j] !== "")){
                        layoutName = myDeviceIcons.get(i).layout;
                        for(var k = 0; k < myControllerLayout.count;k++)
                        {
                            if(myControllerLayout.get(k).name === layoutName){
                                layoutQml = myControllerLayout.get(k).qml;
                                return k;
                            }
                        }
                        //select default one if no Layout available
                        layoutName = "default";
                        break; // to exit for also
                    }
                }
                i = i + 1;
            }while ((layoutQml === "") && (layoutName !== "default") && (i < myDeviceIcons.count))
            if (layoutQml === ""){
                //to get default one if empty
                for(var l = 0; l < myControllerLayout.count;l++)
                {
                    if(myControllerLayout.get(l).name === "default"){
                        layoutQml = myControllerLayout.get(l).qml;
                        return l;
                    }
                }
            }
            //if issue/never reach
            return -1;
        }

        function setParameters(index){

            if(myControllerLayout.get(index).qml.includes("ContainerCustom")){ //if we use the one that we could customize

                //Settings of layout availability features list
                if(typeof(myControllerLayout.get(index).hasSelect) !== 'undefined') root.padPreview.hasSelect = myControllerLayout.get(index).hasSelect;
                if(typeof(myControllerLayout.get(index).hasStart) !== 'undefined') root.padPreview.hasStart = myControllerLayout.get(index).hasStart;

                if(typeof(myControllerLayout.get(index).hasDedicatedGuide) !== 'undefined') root.padPreview.hasDedicatedGuide = myControllerLayout.get(index).hasDedicatedGuide;

                if(typeof(myControllerLayout.get(index).hasDpad) !== 'undefined') root.padPreview.hasDpad = myControllerLayout.get(index).hasDpad;
                if(typeof(myControllerLayout.get(index).hasButtonsForDpad) !== 'undefined') root.padPreview.hasButtonsForDpad = myControllerLayout.get(index).hasButtonsForDpad;

                if(typeof(myControllerLayout.get(index).hasA) !== 'undefined') root.padPreview.hasA = myControllerLayout.get(index).hasA;
                if(typeof(myControllerLayout.get(index).hasB) !== 'undefined') root.padPreview.hasB = myControllerLayout.get(index).hasB;
                if(typeof(myControllerLayout.get(index).hasX) !== 'undefined') root.padPreview.hasX = myControllerLayout.get(index).hasX;
                if(typeof(myControllerLayout.get(index).hasY) !== 'undefined') root.padPreview.hasY = myControllerLayout.get(index).hasY;

                if(typeof(myControllerLayout.get(index).hasL1) !== 'undefined') root.padPreview.hasL1 = myControllerLayout.get(index).hasL1;
                if(typeof(myControllerLayout.get(index).hasR1) !== 'undefined') root.padPreview.hasR1 = myControllerLayout.get(index).hasR1;

                if(typeof(myControllerLayout.get(index).hasL2) !== 'undefined') root.padPreview.hasL2 = myControllerLayout.get(index).hasL2;
                if(typeof(myControllerLayout.get(index).hasR2) !== 'undefined') root.padPreview.hasR2 = myControllerLayout.get(index).hasR2;


                if(typeof(myControllerLayout.get(index).hasLeftStick) !== 'undefined') root.padPreview.hasLeftStick = myControllerLayout.get(index).hasLeftStick;
                if(typeof(myControllerLayout.get(index).hasRightStick) !== 'undefined') root.padPreview.hasRightStick = myControllerLayout.get(index).hasRightStick;
                if(typeof(myControllerLayout.get(index).hasButtonsForRightStick) !== 'undefined') root.padPreview.hasButtonsForRightStick = myControllerLayout.get(index).hasButtonsForRightStick;

                //L3/R3 included in left/right sticks
                if(typeof(myControllerLayout.get(index).hasL3) !== 'undefined') root.padPreview.hasL3 = myControllerLayout.get(index).hasL3;
                if(typeof(myControllerLayout.get(index).hasR3) !== 'undefined') root.padPreview.hasR3 = myControllerLayout.get(index).hasR3;

                if(typeof(myControllerLayout.get(index).hasScreenshotButton) !== 'undefined') root.padPreview.hasScreenshotButton = myControllerLayout.get(index).hasScreenshotButton;

                //Settings of parameters for base
                if(typeof(myControllerLayout.get(index).ratio) !== 'undefined') root.padPreview.ratio = myControllerLayout.get(index).ratio;
                if(typeof(myControllerLayout.get(index).padBaseSourceSizeWidth) !== 'undefined') root.padPreview.padBaseSourceSizeWidth = myControllerLayout.get(index).padBaseSourceSizeWidth;
                if(typeof(myControllerLayout.get(index).padBaseSourceSizeHeight) !== 'undefined') root.padPreview.padBaseSourceSizeHeight = myControllerLayout.get(index).padBaseSourceSizeHeight;

                //Settings of parameters for select
                if(typeof(myControllerLayout.get(index).padSelectWidth) !== 'undefined') root.padPreview.padSelectWidth = myControllerLayout.get(index).padSelectWidth;
                if(typeof(myControllerLayout.get(index).padSelectHeight) !== 'undefined') root.padPreview.padSelectHeight = myControllerLayout.get(index).padSelectHeight;
                if(typeof(myControllerLayout.get(index).padSelectTopY) !== 'undefined') root.padPreview.padSelectTopY = myControllerLayout.get(index).padSelectTopY;
                if(typeof(myControllerLayout.get(index).padSelectLeftX) !== 'undefined') root.padPreview.padSelectLeftX = myControllerLayout.get(index).padSelectLeftX;

                //Settings of parameters for start
                if(typeof(myControllerLayout.get(index).padStartWidth) !== 'undefined') root.padPreview.padStartWidth = myControllerLayout.get(index).padStartWidth;
                if(typeof(myControllerLayout.get(index).padStartHeight) !== 'undefined') root.padPreview.padStartHeight = myControllerLayout.get(index).padStartHeight;
                if(typeof(myControllerLayout.get(index).padStartTopY) !== 'undefined') root.padPreview.padStartTopY = myControllerLayout.get(index).padStartTopY;
                if(typeof(myControllerLayout.get(index).padStartLeftX) !== 'undefined') root.padPreview.padStartLeftX = myControllerLayout.get(index).padStartLeftX;

                //Settings of parameters for guide
                if(typeof(myControllerLayout.get(index).padGuideWidth) !== 'undefined') root.padPreview.padGuideWidth = myControllerLayout.get(index).padGuideWidth;
                if(typeof(myControllerLayout.get(index).padGuideHeight) !== 'undefined') root.padPreview.padGuideHeight = myControllerLayout.get(index).padGuideHeight;
                if(typeof(myControllerLayout.get(index).padGuideTopY) !== 'undefined') root.padPreview.padGuideTopY = myControllerLayout.get(index).padGuideTopY;
                if(typeof(myControllerLayout.get(index).padGuideLeftX) !== 'undefined') root.padPreview.padGuideLeftX = myControllerLayout.get(index).padGuideLeftX;

                //Settings of parameters for A/B/X/Y
                if(typeof(myControllerLayout.get(index).padABXYAreaTopY) !== 'undefined') root.padPreview.padABXYAreaTopY = myControllerLayout.get(index).padABXYAreaTopY;
                if(typeof(myControllerLayout.get(index).padABXYAreaBottomY) !== 'undefined') root.padPreview.padABXYAreaBottomY = myControllerLayout.get(index).padABXYAreaBottomY;
                if(typeof(myControllerLayout.get(index).padABXYAreaLeftX) !== 'undefined') root.padPreview.padABXYAreaLeftX = myControllerLayout.get(index).padABXYAreaLeftX;
                if(typeof(myControllerLayout.get(index).padABXYAreaRightX) !== 'undefined') root.padPreview.padABXYAreaRightX = myControllerLayout.get(index).padABXYAreaRightX;

                if(typeof(myControllerLayout.get(index).padAWidth) !== 'undefined') root.padPreview.padAWidth = myControllerLayout.get(index).padAWidth;
                if(typeof(myControllerLayout.get(index).padAHeight) !== 'undefined') root.padPreview.padAHeight = myControllerLayout.get(index).padAHeight;
                if(typeof(myControllerLayout.get(index).padATopY) !== 'undefined') root.padPreview.padATopY = myControllerLayout.get(index).padATopY;
                if(typeof(myControllerLayout.get(index).padALeftX) !== 'undefined') root.padPreview.padALeftX = myControllerLayout.get(index).padALeftX;

                if(typeof(myControllerLayout.get(index).padBWidth) !== 'undefined') root.padPreview.padBWidth = myControllerLayout.get(index).padBWidth;
                if(typeof(myControllerLayout.get(index).padBHeight) !== 'undefined') root.padPreview.padBHeight = myControllerLayout.get(index).padBHeight;
                if(typeof(myControllerLayout.get(index).padBTopY) !== 'undefined') root.padPreview.padBTopY = myControllerLayout.get(index).padBTopY;
                if(typeof(myControllerLayout.get(index).padBLeftX) !== 'undefined') root.padPreview.padBLeftX = myControllerLayout.get(index).padBLeftX;

                if(typeof(myControllerLayout.get(index).padXWidth) !== 'undefined') root.padPreview.padXWidth = myControllerLayout.get(index).padXWidth;
                if(typeof(myControllerLayout.get(index).padXHeight) !== 'undefined') root.padPreview.padXHeight = myControllerLayout.get(index).padXHeight;
                if(typeof(myControllerLayout.get(index).padXTopY) !== 'undefined') root.padPreview.padXTopY = myControllerLayout.get(index).padXTopY;
                if(typeof(myControllerLayout.get(index).padXLeftX) !== 'undefined') root.padPreview.padXLeftX = myControllerLayout.get(index).padXLeftX;

                if(typeof(myControllerLayout.get(index).padYWidth) !== 'undefined') root.padPreview.padYWidth = myControllerLayout.get(index).padYWidth;
                if(typeof(myControllerLayout.get(index).padYHeight) !== 'undefined') root.padPreview.padYHeight = myControllerLayout.get(index).padYHeight;
                if(typeof(myControllerLayout.get(index).padYTopY) !== 'undefined') root.padPreview.padYTopY = myControllerLayout.get(index).padYTopY;
                if(typeof(myControllerLayout.get(index).padYLeftX) !== 'undefined') root.padPreview.padYLeftX = myControllerLayout.get(index).padYLeftX;

                if(typeof(myControllerLayout.get(index).hasNintendoPad) !== 'undefined') root.padPreview.hasNintendoPad = myControllerLayout.get(index).hasNintendoPad;

                //Settings of parameters for L1/R1/L2/R2/L3/R3
                if(typeof(myControllerLayout.get(index).padL1Width) !== 'undefined') root.padPreview.padL1Width = myControllerLayout.get(index).padL1Width;
                if(typeof(myControllerLayout.get(index).padL1Height) !== 'undefined') root.padPreview.padL1Height = myControllerLayout.get(index).padL1Height;
                if(typeof(myControllerLayout.get(index).padL1TopY) !== 'undefined') root.padPreview.padL1TopY = myControllerLayout.get(index).padL1TopY;
                if(typeof(myControllerLayout.get(index).padL1LeftX) !== 'undefined') root.padPreview.padL1LeftX = myControllerLayout.get(index).padL1LeftX;

                if(typeof(myControllerLayout.get(index).padL2Width) !== 'undefined') root.padPreview.padL2Width = myControllerLayout.get(index).padL2Width;
                if(typeof(myControllerLayout.get(index).padL2Height) !== 'undefined') root.padPreview.padL2Height = myControllerLayout.get(index).padL2Height;
                if(typeof(myControllerLayout.get(index).padL2TopY) !== 'undefined') root.padPreview.padL2TopY = myControllerLayout.get(index).padL2TopY;
                if(typeof(myControllerLayout.get(index).padL2LeftX) !== 'undefined') root.padPreview.padL2LeftX = myControllerLayout.get(index).padL2LeftX;

                if(typeof(myControllerLayout.get(index).padR1Width) !== 'undefined') root.padPreview.padR1Width = myControllerLayout.get(index).padR1Width;
                if(typeof(myControllerLayout.get(index).padR1Height) !== 'undefined') root.padPreview.padR1Height = myControllerLayout.get(index).padR1Height;
                if(typeof(myControllerLayout.get(index).padR1TopY) !== 'undefined') root.padPreview.padR1TopY = myControllerLayout.get(index).padR1TopY;
                if(typeof(myControllerLayout.get(index).padR1LeftX) !== 'undefined') root.padPreview.padR1LeftX = myControllerLayout.get(index).padR1LeftX;

                if(typeof(myControllerLayout.get(index).padR2Width) !== 'undefined') root.padPreview.padR2Width = myControllerLayout.get(index).padR2Width;
                if(typeof(myControllerLayout.get(index).padR2Height) !== 'undefined') root.padPreview.padR2Height = myControllerLayout.get(index).padR2Height;
                if(typeof(myControllerLayout.get(index).padR2TopY) !== 'undefined') root.padPreview.padR2TopY = myControllerLayout.get(index).padR2TopY;
                if(typeof(myControllerLayout.get(index).padR2LeftX) !== 'undefined') root.padPreview.padR2LeftX = myControllerLayout.get(index).padR2LeftX;

                //Settings of parameters for Dpad
                if(typeof(myControllerLayout.get(index).dpadAreaTopY) !== 'undefined') root.padPreview.dpadAreaTopY = myControllerLayout.get(index).dpadAreaTopY;
                if(typeof(myControllerLayout.get(index).dpadAreaBottomY) !== 'undefined') root.padPreview.dpadAreaBottomY = myControllerLayout.get(index).dpadAreaBottomY;
                if(typeof(myControllerLayout.get(index).dpadAreaLeftX) !== 'undefined') root.padPreview.dpadAreaLeftX = myControllerLayout.get(index).dpadAreaLeftX;
                if(typeof(myControllerLayout.get(index).dpadAreaRightX) !== 'undefined') root.padPreview.dpadAreaRightX = myControllerLayout.get(index).dpadAreaRightX;

                //Settings of parameters for Dpad using dedicated buttons for each directions
                if(typeof(myControllerLayout.get(index).dpadUpWidth) !== 'undefined') root.padPreview.dpadUpWidth = myControllerLayout.get(index).dpadUpWidth;
                if(typeof(myControllerLayout.get(index).dpadUpHeight) !== 'undefined') root.padPreview.dpadUpHeight = myControllerLayout.get(index).dpadUpHeight;
                if(typeof(myControllerLayout.get(index).dpadUpTopY) !== 'undefined') root.padPreview.dpadUpTopY = myControllerLayout.get(index).dpadUpTopY;
                if(typeof(myControllerLayout.get(index).dpadUpLeftX) !== 'undefined') root.padPreview.dpadUpLeftX = myControllerLayout.get(index).dpadUpLeftX;

                if(typeof(myControllerLayout.get(index).dpadDownWidth) !== 'undefined') root.padPreview.dpadDownWidth = myControllerLayout.get(index).dpadDownWidth;
                if(typeof(myControllerLayout.get(index).dpadDownHeight) !== 'undefined') root.padPreview.dpadDownHeight = myControllerLayout.get(index).dpadDownHeight;
                if(typeof(myControllerLayout.get(index).dpadDownTopY) !== 'undefined') root.padPreview.dpadDownTopY = myControllerLayout.get(index).dpadDownTopY;
                if(typeof(myControllerLayout.get(index).dpadDownLeftX) !== 'undefined') root.padPreview.dpadDownLeftX = myControllerLayout.get(index).dpadDownLeftX;

                if(typeof(myControllerLayout.get(index).dpadLeftWidth) !== 'undefined') root.padPreview.dpadLeftWidth = myControllerLayout.get(index).dpadLeftWidth;
                if(typeof(myControllerLayout.get(index).dpadLeftHeight) !== 'undefined') root.padPreview.dpadLeftHeight = myControllerLayout.get(index).dpadLeftHeight;
                if(typeof(myControllerLayout.get(index).dpadLeftTopY) !== 'undefined') root.padPreview.dpadLeftTopY = myControllerLayout.get(index).dpadLeftTopY;
                if(typeof(myControllerLayout.get(index).dpadLeftLeftX) !== 'undefined') root.padPreview.dpadLeftLeftX = myControllerLayout.get(index).dpadLeftLeftX;

                if(typeof(myControllerLayout.get(index).dpadRightWidth) !== 'undefined') root.padPreview.dpadRightWidth = myControllerLayout.get(index).dpadRightWidth;
                if(typeof(myControllerLayout.get(index).dpadRightHeight) !== 'undefined') root.padPreview.dpadRightHeight = myControllerLayout.get(index).dpadRightHeight;
                if(typeof(myControllerLayout.get(index).dpadRightTopY) !== 'undefined') root.padPreview.dpadRightTopY = myControllerLayout.get(index).dpadRightTopY;
                if(typeof(myControllerLayout.get(index).dpadRightLeftX) !== 'undefined') root.padPreview.dpadRightLeftX = myControllerLayout.get(index).dpadRightLeftX;

                //Settings of parameters for lStick/rStick
                if(typeof(myControllerLayout.get(index).lStickWidth) !== 'undefined') root.padPreview.lStickWidth = myControllerLayout.get(index).lStickWidth;
                if(typeof(myControllerLayout.get(index).lStickHeight) !== 'undefined') root.padPreview.lStickHeight = myControllerLayout.get(index).lStickHeight;
                if(typeof(myControllerLayout.get(index).lStickTopY) !== 'undefined') root.padPreview.lStickTopY = myControllerLayout.get(index).lStickTopY;
                if(typeof(myControllerLayout.get(index).lStickLeftX) !== 'undefined') root.padPreview.lStickLeftX = myControllerLayout.get(index).lStickLeftX;

                if(typeof(myControllerLayout.get(index).rStickWidth) !== 'undefined') root.padPreview.rStickWidth = myControllerLayout.get(index).rStickWidth;
                if(typeof(myControllerLayout.get(index).rStickHeight) !== 'undefined') root.padPreview.rStickHeight = myControllerLayout.get(index).rStickHeight;
                if(typeof(myControllerLayout.get(index).rStickTopY) !== 'undefined') root.padPreview.rStickTopY = myControllerLayout.get(index).rStickTopY;
                if(typeof(myControllerLayout.get(index).rStickLeftX) !== 'undefined') root.padPreview.rStickLeftX = myControllerLayout.get(index).rStickLeftX;

                //Settings of parameter for rStick Buttons
                if(typeof(myControllerLayout.get(index).rStickUpWidth) !== 'undefined') root.padPreview.rStickUpWidth = myControllerLayout.get(index).rStickUpWidth;
                if(typeof(myControllerLayout.get(index).rStickUpHeight) !== 'undefined') root.padPreview.rStickUpHeight = myControllerLayout.get(index).rStickUpHeight;
                if(typeof(myControllerLayout.get(index).rStickUpTopY) !== 'undefined') root.padPreview.rStickUpTopY = myControllerLayout.get(index).rStickUpTopY;
                if(typeof(myControllerLayout.get(index).rStickUpLeftX) !== 'undefined') root.padPreview.rStickUpLeftX = myControllerLayout.get(index).rStickUpLeftX;

                if(typeof(myControllerLayout.get(index).rStickDownWidth) !== 'undefined') root.padPreview.rStickDownWidth = myControllerLayout.get(index).rStickDownWidth;
                if(typeof(myControllerLayout.get(index).rStickDownHeight) !== 'undefined') root.padPreview.rStickDownHeight = myControllerLayout.get(index).rStickDownHeight;
                if(typeof(myControllerLayout.get(index).rStickDownTopY) !== 'undefined') root.padPreview.rStickDownTopY = myControllerLayout.get(index).rStickDownTopY;
                if(typeof(myControllerLayout.get(index).rStickDownLeftX) !== 'undefined') root.padPreview.rStickDownLeftX = myControllerLayout.get(index).rStickDownLeftX;

                if(typeof(myControllerLayout.get(index).rStickLeftWidth) !== 'undefined') root.padPreview.rStickLeftWidth = myControllerLayout.get(index).rStickLeftWidth;
                if(typeof(myControllerLayout.get(index).rStickLeftHeight) !== 'undefined') root.padPreview.rStickLeftHeight = myControllerLayout.get(index).rStickLeftHeight;
                if(typeof(myControllerLayout.get(index).rStickLeftTopY) !== 'undefined') root.padPreview.rStickLeftTopY = myControllerLayout.get(index).rStickLeftTopY;
                if(typeof(myControllerLayout.get(index).rStickLeftLeftX) !== 'undefined') root.padPreview.rStickLeftLeftX = myControllerLayout.get(index).rStickLeftLeftX;

                if(typeof(myControllerLayout.get(index).rStickRightWidth) !== 'undefined') root.padPreview.rStickRightWidth = myControllerLayout.get(index).rStickRightWidth;
                if(typeof(myControllerLayout.get(index).rStickRightHeight) !== 'undefined') root.padPreview.rStickRightHeight = myControllerLayout.get(index).rStickRightHeight;
                if(typeof(myControllerLayout.get(index).rStickRightTopY) !== 'undefined') root.padPreview.rStickRightTopY = myControllerLayout.get(index).rStickRightTopY;
                if(typeof(myControllerLayout.get(index).rStickRightLeftX) !== 'undefined') root.padPreview.rStickRightLeftX = myControllerLayout.get(index).rStickRightLeftX;

                //Settings of contrast/brightness
                //console.log("typeof(myControllerLayout.get(index).brightness) : ",typeof(myControllerLayout.get(index).brightness));
                //console.log("myControllerLayout.get(index).brightness : ", myControllerLayout.get(index).brightness);
                //console.log("typeof(myControllerLayout.get(index).contrast) : ",typeof(myControllerLayout.get(index).contrast));
                //console.log("myControllerLayout.get(index).contrast : ", myControllerLayout.get(index).contrast);

                //to set specific brightness/contrast for L/R Buttons, start/select/guide & DPADs independent buttons.
                if((typeof(myControllerLayout.get(index).contrast) !== 'undefined') && (myControllerLayout.get(index).contrast !== 0)) root.padPreview.contrast = myControllerLayout.get(index).contrast;
                if((typeof(myControllerLayout.get(index).brightness) !== 'undefined') && (myControllerLayout.get(index).brightness !== 0)) root.padPreview.brightness = myControllerLayout.get(index).brightness;

                //set name at the end to avoid error/warning to early ;-)
                root.padPreview.name = myControllerLayout.get(index).name;
            }
        }

        Loader {
            id: loaderPadPreview
            anchors.fill: parent
            enabled: false
            property var layoutIndex
            asynchronous: false
            onStatusChanged: {
                //console.log("onStatusChanged");
                if (loaderPadPreview.status === Loader.Loading) {
                    //console.log("Loader.Loading");
                    //RFU
                }
                else if (loaderPadPreview.status === Loader.Ready) {
                    //console.log("Loader.Ready");
                    if(loaderPadPreview.item != null){
                        root.padPreview = loaderPadPreview.item
                        //set dynamically the layoutIndex
                        parent.setParameters(layoutIndex);
                    }
                    //console.log("root.gamepad : ", root.gamepad);
                    if(root.gamepad !== null){
                            loaderPadPreview.item.gamepad = root.gamepad;
                    }
                }
                else if (status == Loader.Error){
                     //RFU
                     console.log("Error to load QML for this controller !");
                }
            }
        }

        onActiveFocusChanged:
            if (!activeFocus && padPreview) padPreview.currentButton = ""

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
                visible: (typeof(root.padPreview) !== 'undefined') ? ((typeof(root.padPreview.hasL1) !== 'undefined') ? root.padPreview.hasL1 : true) : false
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
                visible: (typeof(root.padPreview) !== 'undefined') ? ((typeof(root.padPreview.hasL2) !== 'undefined') ? root.padPreview.hasL2 : true) : false
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
                    if (activeFocus && padPreview) padPreview.currentButton = "dpup";

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
                    if (activeFocus && padPreview) padPreview.currentButton = "dpdown"

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
                    if (activeFocus && padPreview) padPreview.currentButton = "dpleft"

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
                    if (activeFocus && padPreview) padPreview.currentButton = "dpright"

                pressed: gamepad && gamepad.buttonRight
				input: GamepadManager.GMButton.Right
				inputType: "button"

                KeyNavigation.right: configY
                KeyNavigation.down: configLeftStickX
            }
        }
        ConfigGroup {
            visible: (typeof(root.padPreview) !== 'undefined') ? ((typeof(root.padPreview.hasLeftStick) !== 'undefined') ? root.padPreview.hasLeftStick : true) : false
            label: qsTr("left stick") + api.tr
            anchors {
                left: parent.horizontalCenter
                leftMargin: parent.horizontalOffset
                verticalCenter: parent.verticalCenter
                verticalCenterOffset: parent.verticalSpacing
            }
            ConfigField {
                id: configLeftStickX
                text: recording ? qsTr("go x axis to left") + api.tr  : qsTr("x axis") + api.tr
                onActiveFocusChanged:
                    if (activeFocus) padPreview.currentButton = "lx"

                pressed: gamepad && Math.abs(gamepad.axisLeftX) > 0.05
				input: GamepadManager.GMAxis.LeftX
				inputType: "axis"
 
                KeyNavigation.right: (typeof(root.padPreview) !== 'undefined') ? ((typeof(root.padPreview.hasButtonsForRightStick) !== 'undefined') ? configRightStickPlusX : configRightStickX) : configRightStickX
                KeyNavigation.down: configLeftStickY
            }
            ConfigField {
                id: configLeftStickY
                text: recording ? qsTr("go y axis to up") + api.tr  : qsTr("y axis") + api.tr
                onActiveFocusChanged:
                    if (activeFocus) padPreview.currentButton = "ly"

                pressed: gamepad && Math.abs(gamepad.axisLeftY) > 0.05
 				input: GamepadManager.GMAxis.LeftY
				inputType: "axis"
 
                KeyNavigation.right: (typeof(root.padPreview) !== 'undefined') ? ((typeof(root.padPreview.hasButtonsForRightStick) !== 'undefined') ? configRightStickMinusY : configRightStickY) : configRightStickY
                KeyNavigation.down: configL3
            }
            ConfigField {
                id: configL3
                visible: (typeof(root.padPreview) !== 'undefined') ? ((typeof(root.padPreview.hasL3) !== 'undefined') ? root.padPreview.hasL3 : true) : false
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
                visible: (typeof(root.padPreview) !== 'undefined') ? ((typeof(root.padPreview.hasR1) !== 'undefined') ? root.padPreview.hasR1 : true) : false
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
                visible: (typeof(root.padPreview) !== 'undefined') ? ((typeof(root.padPreview.hasR2) !== 'undefined') ? root.padPreview.hasR2 : true) : false
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
                visible: (typeof(root.padPreview) !== 'undefined') ? ((typeof(root.padPreview.hasA) !== 'undefined') ? root.padPreview.hasA : true) : false
                text: "a"
                onActiveFocusChanged:
                {
                    //console.log("GamepadEditor.qml : activeFocus = ",activeFocus);
                    if (activeFocus && padPreview) {
                        //console.log("GamepadEditor.qml : onActiveFocusChanged");
                        padPreview.currentButton = "a";
                    }
                }

                pressed: gamepad &&
                         ((typeof(root.padPreview) !== 'undefined') ?
                              (typeof(root.padPreview.hasNintendoPad) !== 'undefined' ?
                                   (root.padPreview.hasNintendoPad ?  gamepad.buttonEast : gamepad.buttonSouth)
                                 : gamepad.buttonSouth)
                            : gamepad.buttonSouth );
                input: ((typeof(root.padPreview) !== 'undefined') ?
                            (typeof(root.padPreview.hasNintendoPad) !== 'undefined' ?
                                 (root.padPreview.hasNintendoPad ?  GamepadManager.GMButton.East : GamepadManager.GMButton.South)
                               : GamepadManager.GMButton.South)
                          : GamepadManager.GMButton.South );
                inputType: "button"

                KeyNavigation.down: configB
            }
            ConfigField {
                id: configB
                visible: (typeof(root.padPreview) !== 'undefined') ? ((typeof(root.padPreview.hasB) !== 'undefined') ? root.padPreview.hasB : true) : false
                text: "b"
                onActiveFocusChanged:
                    if (activeFocus && padPreview) padPreview.currentButton = "b"

                pressed: gamepad &&
                         ((typeof(root.padPreview) !== 'undefined') ?
                              (typeof(root.padPreview.hasNintendoPad) !== 'undefined' ?
                                   (root.padPreview.hasNintendoPad ?  gamepad.buttonSouth : gamepad.buttonEast)
                                 : gamepad.buttonEast)
                            : gamepad.buttonEast );
                input: ((typeof(root.padPreview) !== 'undefined') ?
                            (typeof(root.padPreview.hasNintendoPad) !== 'undefined' ?
                                 (root.padPreview.hasNintendoPad ?  GamepadManager.GMButton.South : GamepadManager.GMButton.East)
                               : GamepadManager.GMButton.East)
                          : GamepadManager.GMButton.East );
                inputType: "button"

                KeyNavigation.down: ((typeof(root.padPreview) !== 'undefined') ?
                                         (typeof(root.padPreview.hasX) !== 'undefined' ?
                                              (root.padPreview.hasX ?
                                                   configX : (typeof(root.padPreview) !== 'undefined') ? ((typeof(root.padPreview.hasButtonsForRightStick) !== 'undefined') ? (root.padPreview.hasButtonsForRightStick ? configRightStickMinusX : configRightStickX) : configRightStickX) : configRightStickX )
                                              : configRightStickX )
                                      : configX)
            }
            ConfigField {
                id: configX
                visible: (typeof(root.padPreview) !== 'undefined') ? ((typeof(root.padPreview.hasX) !== 'undefined') ? root.padPreview.hasX : true) : false

                text: "x"
                onActiveFocusChanged:
                    if (activeFocus && padPreview) padPreview.currentButton = "x"

                pressed: gamepad &&
                         ((typeof(root.padPreview) !== 'undefined') ?
                              (typeof(root.padPreview.hasNintendoPad) !== 'undefined' ?
                                   (root.padPreview.hasNintendoPad ?  gamepad.buttonNorth : gamepad.buttonWest)
                                 : gamepad.buttonWest)
                            : gamepad.buttonWest );
                input: ((typeof(root.padPreview) !== 'undefined') ?
                            (typeof(root.padPreview.hasNintendoPad) !== 'undefined' ?
                                 (root.padPreview.hasNintendoPad ?  GamepadManager.GMButton.North : GamepadManager.GMButton.West)
                               : GamepadManager.GMButton.West)
                          : GamepadManager.GMButton.West );
				inputType: "button"

                KeyNavigation.down: configY
            }
            ConfigField {
                id: configY
                visible: (typeof(root.padPreview) !== 'undefined') ? ((typeof(root.padPreview.hasY) !== 'undefined') ? root.padPreview.hasY : true) : false
                text: "y"
                onActiveFocusChanged:
                    if (activeFocus && padPreview) padPreview.currentButton = "y"

                pressed: gamepad &&
                         ((typeof(root.padPreview) !== 'undefined') ?
                              (typeof(root.padPreview.hasNintendoPad) !== 'undefined' ?
                                   (root.padPreview.hasNintendoPad ?  gamepad.buttonWest : gamepad.buttonNorth)
                                 : gamepad.buttonNorth)
                            : gamepad.buttonNorth );
                input: ((typeof(root.padPreview) !== 'undefined') ?
                            (typeof(root.padPreview.hasNintendoPad) !== 'undefined' ?
                                 (root.padPreview.hasNintendoPad ?  GamepadManager.GMButton.West : GamepadManager.GMButton.North)
                               : GamepadManager.GMButton.North)
                          : GamepadManager.GMButton.North );
				inputType: "button"

                KeyNavigation.down: (typeof(root.padPreview) !== 'undefined') ? ((typeof(root.padPreview.hasButtonsForRightStick) !== 'undefined') ? (root.padPreview.hasButtonsForRightStick ? configRightStickPlusX : configRightStickX) : configRightStickX) : configRightStickX
            }
        }
        ConfigGroup {
            visible: (typeof(root.padPreview) !== 'undefined') ? ((typeof(root.padPreview.hasRightStick) !== 'undefined') ? root.padPreview.hasRightStick : true) : false
            label: qsTr("right stick") + api.tr
            alignment: Text.AlignRight
            anchors {
                right: parent.horizontalCenter
                rightMargin: parent.horizontalOffset
                verticalCenter: parent.verticalCenter
                verticalCenterOffset: parent.verticalSpacing
            }
            ConfigField {
                visible : (typeof(root.padPreview) !== 'undefined') ? ((typeof(root.padPreview.hasButtonsForRightStick) !== 'undefined') ? !root.padPreview.hasButtonsForRightStick : true) : false
                id: configRightStickX
                text: recording ? qsTr("go x axis to left") + api.tr  : qsTr("x axis") + api.tr
                onActiveFocusChanged:
                    if (activeFocus) padPreview.currentButton = "rx"

                pressed: gamepad && Math.abs(gamepad.axisRightX) > 0.05
 				input: GamepadManager.GMAxis.RightX
				inputType: "axis"
				
                KeyNavigation.down: configRightStickY
            }
            ConfigField {
                visible : (typeof(root.padPreview) !== 'undefined') ? ((typeof(root.padPreview.hasButtonsForRightStick) !== 'undefined') ? !root.padPreview.hasButtonsForRightStick : true) : false
                id: configRightStickY
                text: recording ? qsTr("go y axis to up") + api.tr  : qsTr("y axis") + api.tr
                onActiveFocusChanged:
                    if (activeFocus) padPreview.currentButton = "ry"

                pressed: gamepad && Math.abs(gamepad.axisRightY) > 0.05
 				input: GamepadManager.GMAxis.RightY
				inputType: "axis"

                KeyNavigation.down: configR3
            }

            ConfigField {
                visible : (typeof(root.padPreview) !== 'undefined') ? ((typeof(root.padPreview.hasButtonsForRightStick) !== 'undefined') ? root.padPreview.hasButtonsForRightStick : false) : false
                id: configRightStickMinusX
                text: recording ? qsTr("press button at left") + api.tr  : qsTr("-x axis") + api.tr
                onActiveFocusChanged:
                    if (activeFocus) padPreview.currentButton = "rx"

                pressed: gamepad && gamepad.axisRightX < -0.05
                input: GamepadManager.GMAxis.RightX
                sign: "-"
                inputType: "axis"
                KeyNavigation.left: configLeftStickX
                KeyNavigation.down: configRightStickPlusX
            }

            ConfigField {
                visible : (typeof(root.padPreview) !== 'undefined') ? ((typeof(root.padPreview.hasButtonsForRightStick) !== 'undefined') ? root.padPreview.hasButtonsForRightStick : false) : false
                id: configRightStickPlusX
                text: recording ? qsTr("press button at right") + api.tr  : qsTr("+x axis") + api.tr
                onActiveFocusChanged:
                    if (activeFocus) padPreview.currentButton = "rx"

                pressed: gamepad && gamepad.axisRightX > 0.05
                input: GamepadManager.GMAxis.RightX
                sign: "+"
                inputType: "axis"
                KeyNavigation.left: configLeftStickX
                KeyNavigation.up: configRightStickMinusX
                KeyNavigation.down: configRightStickMinusY
            }

            ConfigField {
                visible : (typeof(root.padPreview) !== 'undefined') ? ((typeof(root.padPreview.hasButtonsForRightStick) !== 'undefined') ? root.padPreview.hasButtonsForRightStick : false) : false
                id: configRightStickMinusY
                text: recording ? qsTr("press button to up") + api.tr  : qsTr("-y axis") + api.tr
                onActiveFocusChanged:
                    if (activeFocus) padPreview.currentButton = "ry"

                pressed: gamepad && gamepad.axisRightY < -0.05
                input: GamepadManager.GMAxis.RightY
                sign: "-"
                inputType: "axis"
                KeyNavigation.left: configLeftStickY
                KeyNavigation.down: configRightStickPlusY
            }

            ConfigField {
                visible : (typeof(root.padPreview) !== 'undefined') ? ((typeof(root.padPreview.hasButtonsForRightStick) !== 'undefined') ? root.padPreview.hasButtonsForRightStick : false) : false
                id: configRightStickPlusY
                text: recording ? qsTr("press button to down") + api.tr  : qsTr("+y axis") + api.tr
                onActiveFocusChanged:
                    if (activeFocus) padPreview.currentButton = "ry"

                pressed: gamepad && gamepad.axisRightY > 0.05
                input: GamepadManager.GMAxis.RightY
                sign: "+"
                inputType: "axis"
                KeyNavigation.left: configLeftStickY
                KeyNavigation.down: configR3
            }

            ConfigField {
                id: configR3
                visible: (typeof(root.padPreview) !== 'undefined') ? ((typeof(root.padPreview.hasR3) !== 'undefined') ? root.padPreview.hasR3 : true) : false
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
                        if (activeFocus && padPreview) padPreview.currentButton = "select"

                    pressed: gamepad && gamepad.buttonSelect
					input: GamepadManager.GMButton.Select
					inputType: "button"

                    KeyNavigation.up: deviceSelect
                    KeyNavigation.down: configL1
                    KeyNavigation.right: configGuide
                }
                ConfigField {
                    id: configGuide
                    text: qsTr("guide/hotkey") + api.tr
                    onActiveFocusChanged:
                        if (activeFocus && padPreview) padPreview.currentButton = "guide"

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
                        if (activeFocus && padPreview) padPreview.currentButton = "start"

                    pressed: gamepad && gamepad.buttonStart
					input: GamepadManager.GMButton.Start
					inputType: "button"

                    KeyNavigation.up: deviceSelect
                    KeyNavigation.down: configR1
                    KeyNavigation.right: configR1
                }
            }
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


        //Help for 'back' button (using canvas)
        Canvas {
            width: backButtonIcon.width + vpx(4)
            height: width
            anchors.centerIn: backButtonIcon

            property real progress: escapeProgress
            onProgressChanged: requestPaint()
			visible: {
                if(recordingField != null){
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
                if(recordingField != null){
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
                text: ((typeof(root.padPreview) !== 'undefined') ?
                           (typeof(root.padPreview.hasNintendoPad) !== 'undefined' ?
                                (root.padPreview.hasNintendoPad ?  "A" : "B")
                              : "B")
                              : "B" );
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
                if(recordingField != null){
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

        //Help for 'valid' button (using canvas)
        Canvas {
            width: validButtonIcon.width + vpx(4)
            height: width
            anchors.centerIn: validButtonIcon
			visible: {
                if(recordingField != null){
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
                if(recordingField != null){
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
                text: ((typeof(root.padPreview) !== 'undefined') ?
                           (typeof(root.padPreview.hasNintendoPad) !== 'undefined' ?
                                (root.padPreview.hasNintendoPad ?  "B" : "A")
                              : "A")
                              : "A" );
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
                if(recordingField != null){
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

        //Help for 'details' button (using canvas)
        Canvas {
            width: detailsButtonIcon.width + vpx(4)
            height: width
            anchors.centerIn: detailsButtonIcon
            visible: {
                if(recordingField != null){
                    if (recordingField.recording) return false;
                }
                return true;
            }

            property real progress: resetProgress
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
            id: detailsButtonIcon
            height: label.height
            width: height
            radius: width * 0.5
            border { color: "#777"; width: vpx(1) }
            color: "transparent"
            visible: {
                if (deviceSelect.focus) return false;
                if(recordingField != null){
                    if (recordingField.recording) return false;
                }
                return true;
            }
            anchors {
                right: labelX.left
                verticalCenter: parent.verticalCenter
                verticalCenterOffset: vpx(1)
                margins: vpx(10)
            }
            Text {
                text: ((typeof(root.padPreview) !== 'undefined') ?
                           (typeof(root.padPreview.hasNintendoPad) !== 'undefined' ?
                                (root.padPreview.hasNintendoPad ?  "Y" : "X")
                              : "X")
                              : "X" );
                color: "#777"
                font {
                    family: global.fonts.sans
                    pixelSize: parent.height * 0.7
                }
                anchors.centerIn: parent
            }
        }
        Text {
            id: labelX
            text: qsTr("hold down to remove assignment") + api.tr
            verticalAlignment: Text.AlignTop
            color: "#777"
            visible: {
                if (deviceSelect.focus) return false;
                if(recordingField != null){
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
                right: validButtonIcon.left; rightMargin: parent.width * 0.015
            }
        }


        //Help for 'wizard' launch (RFU)
        Rectangle {
            id: wizardButtonIcon
            height: labelWizard.height
            width: height
            radius: width * 0.5
            border { color: "#777"; width: vpx(1) }
            color: "transparent"
            visible: (recordingField != null) //18-08-21: change to hide this icon for the moment in case of wizard/stepbystep
			
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
                if(recordingField != null)	if (recordingField.recording) return (qsTr("press button") + "/" + qsTr("move axis") + api.tr);
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

        //help for 'directions' commands
        Rectangle {
            id: directionsButtonIcon
            height: labelDirections.height
            width: height
            radius: width * 0.5
            border { color: "#777"; width: vpx(1) }
            color: "transparent"
			visible: {
                if(recordingField != null){
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
                if(recordingField != null){
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
