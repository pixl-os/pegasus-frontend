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
import "common"
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
        if(root.gamepad !== null && typeof(root.gamepad) !== "undefined"){
            //console.log("root.gamepad.name : ", root.gamepad.name);
            //console.log("root.gamepad.deviceLayout : ", root.gamepad.deviceLayout);
            loaderPadPreview.enabled = false;
            loaderPadPreview.source = "";
            loaderPadPreview.layoutIndex = -1;
            loaderPadPreview.layoutName = "";
            loaderPadPreview.layoutAssetsPath = "";
            var fileToFind = "";
            var fileExists = false;
            loaderPadPreview.layoutName = layoutArea.getControllerLayoutName(root.gamepad)
            //console.log("loaderPadPreview.layoutName : " + loaderPadPreview.layoutName);
            //check if any file exists in share_init first
            loaderPadPreview.layoutAssetsPath = "file://recalbox/share_init/system/.pegasus-frontend/assets/gamepad/";
            fileToFind = "/recalbox/share_init/system/.pegasus-frontend/assets/gamepad/" + loaderPadPreview.layoutName + "/" + loaderPadPreview.layoutName + ".qml";
            //console.log("if [ -f " + fileToFind + " ]; then echo 'true' ; else echo 'false' ; fi ;");
            fileExists = api.internal.system.run("if [ -f " + fileToFind + " ]; then echo 'true' ; else echo 'false' ; fi ;").includes('true') ? true : false ;
            if(fileExists === false){
                //check if any file exists in share_init first
                loaderPadPreview.layoutAssetsPath = "file://recalbox/share/system/.pegasus-frontend/assets/gamepad/";
                fileToFind = "/recalbox/share/system/.pegasus-frontend/assets/gamepad/" + loaderPadPreview.layoutName + "/" + loaderPadPreview.layoutName + ".qml";
                //console.log("if [ -f " + fileToFind + " ]; then echo 'true' ; else echo 'false' ; fi ;");
                fileExists = api.internal.system.run("if [ -f " + fileToFind + " ]; then echo 'true' ; else echo 'false' ; fi ;").includes('true') ? true : false ;
            }
            if(fileExists !== false){
                //console.log("fileToload : " + "file:/" + fileToFind);
                layoutLoader.source = "file:/" + fileToFind
            }
            else{
                loaderPadPreview.layoutAssetsPath = "qrc:/frontend/assets/gamepad/";
                // get conttroller layout from embedded "MyControllerLayout" model
                loaderPadPreview.layoutIndex = layoutArea.getControllerLayoutIndex(root.gamepad);
                //try to load ContainerCustom.qml
                loaderPadPreview.layoutName = myControllerLayout.get(loaderPadPreview.layoutIndex).name
                //console.log("loaderPadPreview.layoutName : " + loaderPadPreview.layoutName);
                loaderPadPreview.source = myControllerLayout.get(loaderPadPreview.layoutIndex).qml
            }
            //console.log("loaderPadPreview.layoutIndex : " + loaderPadPreview.layoutIndex);
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
        KeyNavigation.down: configL1.visible ? configL1 : configSelect

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
            bottomMargin: vpx(10) + optControllerSkin.height
        }
        property int horizontalOffset: vpx(-560)
        property int verticalSpacing: vpx(170)

        //use loader to load container dynamically
        //list model to manage layout parameters (file name, etc...)
        ListModel {
            id: myControllerLayout
            //CONTROLLERS LAYOUT TO DISPLAY IN EDITOR depending of layout name
            ListElement { name: "default"; qml: "gamepad/preview/Container.qml"
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

                hasDpad : true;
                hasButtonsForDpad : false;
                hasScreenshotButton : false;

            } // By default

            /*ListElement {   name: "snes"; qml: "gamepad/preview/ContainerCustom.qml";

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

                            hasDpad : true;
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
                            //As B -> A
                            padAWidth : 71;
                            padAHeight : 70;
                            padATopY: 170;
                            padALeftX: 763;

                            //As A -> B
                            padBWidth : 71;
                            padBHeight : 71;
                            padBTopY: 237;
                            padBLeftX: 677;

                            //As Y -> X
                            padXWidth : 71;
                            padXHeight : 71;
                            padXTopY: 103;
                            padXLeftX: 677;

                            //As X -> Y
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

                            //to adapt contrast/brightness
                            contrast : 0.1
                            brightness: 0.2

            } //As SNES pad (but with L2/R2 to be compatible with switch online ones)*/

            /*ListElement {   name: "sn30proplus"; qml: "gamepad/preview/ContainerCustom.qml";

                            hasDedicatedGuide: true;
                            hasSelect: true;
                            hasStart: true;

                            hasA: true;
                            hasB: true;
                            hasX: true;
                            hasY: true;
                            hasNintendoPad : true;

                            hasL1 : true; hasR1 : true;
                            hasL2 : true; hasR2 : true;

                            hasLeftStick : true; hasRightStick : true;
                            hasL3 : true; hasR3 : true;

                            hasDpad : true;
                            hasButtonsForDpad : false;

                            hasScreenshotButton : false;

                            ratio: 0.7; padBaseSourceSizeWidth : 759 ; padBaseSourceSizeHeight : 604;
                            
                            //parameters for select
                            padSelectWidth : 58;
                            padSelectHeight : 20;
                            padSelectTopY: 211;
                            padSelectLeftX: 298;

                            //parameters for start
                            padStartWidth : 58;
                            padStartHeight : 20;
                            padStartTopY: 211;
                            padStartLeftX: 371;

                            //parameters for home/guide/hotkey
                            padGuideWidth : 32;
                            padGuideHeight : 34;
                            padGuideTopY: 335;
                            padGuideLeftX: 147;

                            //parameters for A/B/X/Y
                            //As B -> A
                            padAWidth : 57;
                            padAHeight : 55;
                            padATopY: 196;
                            padALeftX: 638;

                            //As A -> B
                            padBWidth : 56;
                            padBHeight : 55;
                            padBTopY: 250;
                            padBLeftX: 569;

                            //As Y -> X
                            padXWidth : 57;
                            padXHeight : 54;
                            padXTopY: 143;
                            padXLeftX: 569;

                            //As X -> Y
                            padYWidth : 57;
                            padYHeight : 55;
                            padYTopY: 196;
                            padYLeftX: 499;

                            //parameter for Dpad
                            dpadAreaTopY: 159;
                            dpadAreaBottomY: 289;
                            dpadAreaLeftX: 98;
                            dpadAreaRightX: 228;

                            //parameter for L1
                            padL1Width : 158;
                            padL1Height : 29;
                            padL1TopY: 96;
                            padL1LeftX: 91;

                            //parameter for R1
                            padR1Width : 159;
                            padR1Height : 30;
                            padR1TopY: 96;
                            padR1LeftX: 510;

                            //parameter for L2
                            padL2Width : 116;
                            padL2Height : 83;
                            padL2TopY: 0;
                            padL2LeftX: 128;

                            //parameter for R2
                            padR2Width : 116;
                            padR2Height : 83;
                            padR2TopY: 0;
                            padR2LeftX: 511;

                            //parameter for Left stick
                            lStickWidth : 79;
                            lStickHeight : 79;
                            lStickTopY: 298;
                            lStickLeftX: 228;

                            //parameter for Right stick
                            rStickWidth : 79;
                            rStickHeight : 74;
                            rStickTopY: 300;
                            rStickLeftX: 453;

                            //to adapt contrast/brightness
                            contrast : 0.1
                            brightness: 0.2

            } //As SN30PRO+ pad (but with L2/R2 to be compatible with switch online ones)*/

            /*ListElement {   name: "sn30pro"; qml: "gamepad/preview/ContainerCustom.qml";

                            hasDedicatedGuide: true;
                            hasSelect: true;
                            hasStart: true;

                            hasA: true;
                            hasB: true;
                            hasX: true;
                            hasY: true;
                            hasNintendoPad : true;

                            hasL1 : true; hasR1 : true;
                            hasL2 : true; hasR2 : true;

                            hasLeftStick : true; hasRightStick : true;
                            hasL3 : true; hasR3 : true;

                            hasDpad : true;
                            hasButtonsForDpad : false;

                            hasScreenshotButton : false;

                            ratio: 1.0; padBaseSourceSizeWidth : 653 ; padBaseSourceSizeHeight : 350;
                            
                            //parameters for select
                            padSelectWidth : 53;
                            padSelectHeight : 19;
                            padSelectTopY: 167;
                            padSelectLeftX: 253;

                            //parameters for start
                            padStartWidth : 53;
                            padStartHeight : 18 ;
                            padStartTopY: 167;
                            padStartLeftX: 318;

                            //parameters for guide/home/hotkey
                            padGuideWidth : 30;
                            padGuideHeight : 31;
                            padGuideTopY: 279;
                            padGuideLeftX: 117;

                            //parameters for A/B/X/Y
                            //As B -> A
                            padAWidth : 51;
                            padAHeight : 51;
                            padATopY: 154;
                            padALeftX: 558;

                            //As A -> B
                            padBWidth : 51;
                            padBHeight : 50;
                            padBTopY: 202;
                            padBLeftX: 496;

                            //As Y -> X
                            padXWidth : 49;
                            padXHeight : 49;
                            padXTopY: 106;
                            padXLeftX: 496;

                            //As X -> Y
                            padYWidth : 50;
                            padYHeight : 50;
                            padYTopY: 154;
                            padYLeftX: 434;

                            //parameter for Dpad
                            dpadAreaTopY: 121;
                            dpadAreaBottomY: 237;
                            dpadAreaLeftX: 74;
                            dpadAreaRightX: 190;

                            //parameter for L1
                            padL1Width : 145;
                            padL1Height : 29;
                            padL1TopY: 63;
                            padL1LeftX: 67;

                            //parameter for R1
                            padR1Width : 145;
                            padR1Height : 29;
                            padR1TopY: 63;
                            padR1LeftX: 442;

                            //parameter for L2
                            padL2Width : 151;
                            padL2Height : 46;
                            padL2TopY: 0;
                            padL2LeftX: 57;

                            //parameter for R2
                            padR2Width : 151;
                            padR2Height : 46;
                            padR2TopY: 0;
                            padR2LeftX: 446;

                            //parameter for Left stick
                            lStickWidth : 83;
                            lStickHeight : 82;
                            lStickTopY: 231;
                            lStickLeftX: 189;

                            //parameter for Right stick
                            rStickWidth : 82;
                            rStickHeight : 82;
                            rStickTopY: 231;
                            rStickLeftX: 381;

                            //to adapt contrast/brightness
                            contrast : 0.1
                            brightness: 0.2

            } //As SN30 PRO pad (but with L2/R2 to be compatible with switch online ones)*/

            /*ListElement {   name: "nes"; qml: "gamepad/preview/ContainerCustom.qml";

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

                            hasDpad : true;
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

                            //As B -> A
                            padAWidth : 69;
                            padAHeight : 68;
                            padATopY: 228;
                            padALeftX: 612;

                            //As A -> B
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

            } //As NES pad (but with L1/R1 to be compatible with switch online ones)*/

            /*ListElement {   name: "arcadestick"; qml: "gamepad/preview/ContainerCustom.qml";

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

                            hasLeftStick : true; hasRightStick : true; hasButtonsForRightStick : false;
                            hasL3 : false; hasR3 : false;

                            hasDpad : true;
                            hasButtonsForDpad : false;

                            hasScreenshotButton : false;

                            ratio: 0.9; padBaseSourceSizeWidth : 760 ; padBaseSourceSizeHeight : 507;
                            
                            //parameters for select
                            padSelectWidth : 41;
                            padSelectHeight : 21;
                            padSelectTopY: 95;
                            padSelectLeftX: 185;

                            //parameters for start
                            padStartWidth : 41;
                            padStartHeight : 21;
                            padStartTopY: 95;
                            padStartLeftX: 230;

                            //parameters for home/guide/hotkey
                            padGuideWidth : 30;
                            padGuideHeight : 30;
                            padGuideTopY: 40;
                            padGuideLeftX: 239 ;

                            //parameters for A/B/X/Y
                            //As A
                            padAWidth : 60;
                            padAHeight : 62;
                            padATopY: 296;
                            padALeftX: 335;

                            //As B
                            padBWidth : 62;
                            padBHeight : 63;
                            padBTopY: 263;
                            padBLeftX: 417;

                            //As X
                            padXWidth : 62;
                            padXHeight : 62;
                            padXTopY: 202;
                            padXLeftX: 352;

                            //As Y
                            padYWidth : 61;
                            padYHeight : 60;
                            padYTopY: 167;
                            padYLeftX: 435;

                            //parameter for Dpad
                            dpadAreaTopY: 216;
                            dpadAreaBottomY: 305;
                            dpadAreaLeftX: 109;
                            dpadAreaRightX: 196;

                            //parameter for L
                            padL1Width : 65;
                            padL1Height : 61;
                            padL1TopY: 167;
                            padL1LeftX: 613;

                            //parameter for R
                            padR1Width : 60;
                            padR1Height : 62;
                            padR1TopY: 166;
                            padR1LeftX: 526;

                            //parameter for ZL
                            padL2Width : 62;
                            padL2Height : 62;
                            padL2TopY: 264;
                            padL2LeftX: 597;

                            //parameter for ZR
                            padR2Width : 63;
                            padR2Height : 61;
                            padR2TopY: 265;
                            padR2LeftX: 507;

                            //parameter for Left stick - same as dpad
                            lStickWidth : 87;
                            lStickHeight : 89;
                            lStickTopY: 216;
                            lStickLeftX: 109;

                            //parameter for right stick - same as dpad
                            rStickWidth : 87;
                            rStickHeight : 89;
                            rStickTopY: 216;
                            rStickLeftX: 109;

                            //to adapt contrast/brightness
                            contrast : 0.1
                            brightness: 0.2

            } //As 8bitdo Arcade stick pad*/

            /*ListElement {   name: "xbox360"; qml: "gamepad/preview/ContainerCustom.qml";

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

                            hasDpad : true;
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

                            //parameters for home/guide/hotkey
                            padGuideWidth : 94;
                            padGuideHeight : 94;
                            padGuideTopY: 227;
                            padGuideLeftX: 434;

                            //parameters for A/B/X/Y
                            //As A
                            padAWidth : 65;
                            padAHeight : 67;
                            padATopY: 308;
                            padALeftX: 730;

                            //As B
                            padBWidth : 65;
                            padBHeight : 66;
                            padBTopY: 233;
                            padBLeftX: 806;

                            //As X
                            padXWidth : 66;
                            padXHeight : 67;
                            padXTopY: 233;
                            padXLeftX: 655;

                            //As Y
                            padYWidth : 66;
                            padYHeight : 67;
                            padYTopY: 158;
                            padYLeftX: 730;

                            //parameter for Dpad
                            dpadAreaTopY: 350;
                            dpadAreaBottomY: 525;
                            dpadAreaLeftX: 245;
                            dpadAreaRightX: 420;

                            //parameter for LB
                            padL1Width : 171;
                            padL1Height : 74;
                            padL1TopY: 77;
                            padL1LeftX: 113;

                            //parameter for RB
                            padR1Width : 173;
                            padR1Height : 72;
                            padR1TopY: 76;
                            padR1LeftX: 673;

                            //parameter for LT
                            padL2Width : 64;
                            padL2Height : 79;
                            padL2TopY: 0;
                            padL2LeftX: 194;

                            //parameter for RT
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

            } //As Microsoft XBOX 360 pad*/

            /*ListElement {   name: "xboxone"; qml: "gamepad/preview/ContainerCustom.qml";

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

                            hasDpad : true;
                            hasButtonsForDpad : false;

                            hasScreenshotButton : false;

                            ratio: 0.5; padBaseSourceSizeWidth : 961 ; padBaseSourceSizeHeight : 832;

                            //parameters for select
                            padSelectWidth : 43;
                            padSelectHeight : 41;
                            padSelectTopY: 327;
                            padSelectLeftX: 387;

                            //parameters for start
                            padStartWidth : 42;
                            padStartHeight : 42;
                            padStartTopY: 327;
                            padStartLeftX: 530;

                            //parameters for home/guide/hotkey
                            padGuideWidth : 76;
                            padGuideHeight : 73;
                            padGuideTopY: 215;
                            padGuideLeftX: 442;

                            //parameters for share //RFU
                            //padSelectWidth : 78;
                            //padSelectHeight : 48;
                            //padSelectTopY: 592;
                            //padSelectLeftX: 684;

                            //parameters for A/B/X/Y
                            //As A
                            padAWidth : 69;
                            padAHeight : 70;
                            padATopY: 382;
                            padALeftX: 695;

                            //As B
                            padBWidth : 65;
                            padBHeight : 68;
                            padBTopY: 321;
                            padBLeftX: 761;

                            //As X
                            padXWidth : 66;
                            padXHeight : 68;
                            padXTopY: 316;
                            padXLeftX: 631;

                            //As Y
                            padYWidth : 66;
                            padYHeight : 68;
                            padYTopY: 253;
                            padYLeftX: 695;

                            //parameter for Dpad
                            dpadAreaTopY: 432;
                            dpadAreaBottomY: 586;
                            dpadAreaLeftX: 277;
                            dpadAreaRightX: 429;

                            //parameter for LB
                            padL1Width : 188;
                            padL1Height : 74;
                            padL1TopY: 167;
                            padL1LeftX: 147;

                            //parameter for RB
                            padR1Width : 186;
                            padR1Height : 75;
                            padR1TopY: 167;
                            padR1LeftX: 631;

                            //parameter for LT
                            padL2Width : 120;
                            padL2Height : 154;
                            padL2TopY: 0;
                            padL2LeftX: 184;

                            //parameter for RT
                            padR2Width : 123;
                            padR2Height : 156;
                            padR2TopY: 0;
                            padR2LeftX: 665;

                            //parameter for Left stick
                            lStickWidth : 107;
                            lStickHeight : 110;
                            lStickTopY: 294;
                            lStickLeftX: 179;

                            //parameter for Right stick
                            rStickWidth : 107;
                            rStickHeight : 108;
                            rStickTopY: 441;
                            rStickLeftX: 555;

                            //to adapt contrast/brightness
                            contrast : 0.1
                            brightness: 0.2

            } //As Microsoft XBOX ONE*/

            /*ListElement {   name: "xboxseries"; qml: "gamepad/preview/ContainerCustom.qml";

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

                            hasDpad : true;
                            hasButtonsForDpad : false;

                            hasScreenshotButton : false;

                            ratio: 0.5; padBaseSourceSizeWidth : 961 ; padBaseSourceSizeHeight : 832;

                            //parameters for select
                            padSelectWidth : 43;
                            padSelectHeight : 41;
                            padSelectTopY: 327;
                            padSelectLeftX: 387;

                            //parameters for start
                            padStartWidth : 42;
                            padStartHeight : 42;
                            padStartTopY: 327;
                            padStartLeftX: 530;

                            //parameters for home/guide/hotkey
                            padGuideWidth : 76;
                            padGuideHeight : 73;
                            padGuideTopY: 215;
                            padGuideLeftX: 442;

                            //parameters for share //RFU
                            //padSelectWidth : 78;
                            //padSelectHeight : 48;
                            //padSelectTopY: 592;
                            //padSelectLeftX: 684;

                            //parameters for A/B/X/Y
                            //As A
                            padAWidth : 69;
                            padAHeight : 70;
                            padATopY: 382;
                            padALeftX: 695;

                            //As B
                            padBWidth : 65;
                            padBHeight : 68;
                            padBTopY: 321;
                            padBLeftX: 761;

                            //As X
                            padXWidth : 66;
                            padXHeight : 68;
                            padXTopY: 316;
                            padXLeftX: 631;

                            //As Y
                            padYWidth : 66;
                            padYHeight : 68;
                            padYTopY: 253;
                            padYLeftX: 695;

                            //parameter for Dpad
                            dpadAreaTopY: 432;
                            dpadAreaBottomY: 586;
                            dpadAreaLeftX: 277;
                            dpadAreaRightX: 429;

                            //parameter for LB
                            padL1Width : 188;
                            padL1Height : 74;
                            padL1TopY: 167;
                            padL1LeftX: 147;

                            //parameter for RB
                            padR1Width : 186;
                            padR1Height : 75;
                            padR1TopY: 167;
                            padR1LeftX: 631;

                            //parameter for LT
                            padL2Width : 120;
                            padL2Height : 154;
                            padL2TopY: 0;
                            padL2LeftX: 184;

                            //parameter for RT
                            padR2Width : 123;
                            padR2Height : 156;
                            padR2TopY: 0;
                            padR2LeftX: 665;

                            //parameter for Left stick
                            lStickWidth : 107;
                            lStickHeight : 110;
                            lStickTopY: 294;
                            lStickLeftX: 179;

                            //parameter for Right stick
                            rStickWidth : 107;
                            rStickHeight : 108;
                            rStickTopY: 441;
                            rStickLeftX: 555;

                            //to adapt contrast/brightness
                            contrast : 0.1
                            brightness: 0.2

            } //As Microsoft XBOX SERIE pad*/

            /*ListElement {   name: "xboxseries20years"; qml: "gamepad/preview/ContainerCustom.qml";

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

                            hasDpad : true;
                            hasButtonsForDpad : false;

                            hasScreenshotButton : false;

                            ratio: 0.3; padBaseSourceSizeWidth : 1447 ; padBaseSourceSizeHeight : 1264;

                            //parameters for select
                            padSelectWidth : 63;
                            padSelectHeight : 64;
                            padSelectTopY: 504;
                            padSelectLeftX: 584;

                            //parameters for start
                            padStartWidth : 65;
                            padStartHeight : 66;
                            padStartTopY: 504;
                            padStartLeftX: 795;

                            //parameters for home/guide/hotkey
                            padGuideWidth : 113;
                            padGuideHeight : 113;
                            padGuideTopY: 333;
                            padGuideLeftX: 664;

                            //parameters for share //RFU
                            //padSelectWidth : 78;
                            //padSelectHeight : 48;
                            //padSelectTopY: 592;
                            //padSelectLeftX: 684;

                            //parameters for A/B/X/Y
                            //As A
                            padAWidth : 97;
                            padAHeight : 96;
                            padATopY: 589;
                            padALeftX: 1046;

                            //As B
                            padBWidth : 96;
                            padBHeight : 97;
                            padBTopY: 495;
                            padBLeftX: 1144;

                            //As X
                            padXWidth : 100;
                            padXHeight : 100;
                            padXTopY: 489;
                            padXLeftX: 947;

                            //As Y
                            padYWidth : 97;
                            padYHeight : 96;
                            padYTopY: 394;
                            padYLeftX: 1046;

                            //parameter for Dpad
                            dpadAreaTopY: 665;
                            dpadAreaBottomY: 887;
                            dpadAreaLeftX: 421;
                            dpadAreaRightX: 641;

                            //parameter for LB
                            padL1Width : 289;
                            padL1Height : 111;
                            padL1TopY: 260;
                            padL1LeftX: 215;

                            //parameter for RB
                            padR1Width : 289;
                            padR1Height : 115;
                            padR1TopY: 260;
                            padR1LeftX: 939;

                            //parameter for LT
                            padL2Width : 185;
                            padL2Height : 237;
                            padL2TopY: 0;
                            padL2LeftX: 279;

                            //parameter for RT
                            padR2Width : 189;
                            padR2Height : 240;
                            padR2TopY: 0;
                            padR2LeftX: 985;

                            //parameter for Left stick
                            lStickWidth : 166;
                            lStickHeight : 166;
                            lStickTopY: 455;
                            lStickLeftX: 269;

                            //parameter for Right stick
                            rStickWidth : 166;
                            rStickHeight : 172;
                            rStickTopY: 671;
                            rStickLeftX: 832;

                            //to adapt contrast/brightness
                            contrast : 0.1
                            brightness: 0.2

            } //As Microsoft XBOX SERIE S/X 20 years pad*/

            /*ListElement {   name: "luna"; qml: "gamepad/preview/ContainerCustom.qml";

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

                            hasDpad : true;
                            hasButtonsForDpad : false;

                            hasScreenshotButton : false;

                            ratio: 0.4; padBaseSourceSizeWidth : 1123 ; padBaseSourceSizeHeight : 949;

                            //parameters for select
                            padSelectWidth : 48;
                            padSelectHeight : 49;
                            padSelectTopY: 313;
                            padSelectLeftX: 435;

                            //parameters for start
                            padStartWidth : 46;
                            padStartHeight : 46;
                            padStartTopY: 316;
                            padStartLeftX: 642;

                            //parameters for home/guide/hotkey
                            padGuideWidth : 106;
                            padGuideHeight : 105;
                            padGuideTopY: 287;
                            padGuideLeftX: 509;

                            //parameters for share (screenshot) //RFU
                            // padSelectWidth : 78;
                            //padSelectHeight : 48;
                            //padSelectTopY: 592;
                            //padSelectLeftX: 684;

                            //parameters for A/B/X/Y
                            //As A
                            padAWidth : 74;
                            padAHeight : 75;
                            padATopY: 437;
                            padALeftX: 822;

                            //As B
                            padBWidth : 73;
                            padBHeight : 75;
                            padBTopY: 357;
                            padBLeftX: 900;

                            //As X
                            padXWidth : 75;
                            padXHeight : 74;
                            padXTopY: 357;
                            padXLeftX: 741;

                            //As Y
                            padYWidth : 73;
                            padYHeight : 74;
                            padYTopY: 277;
                            padYLeftX: 821;

                            //parameter for Dpad
                            dpadAreaTopY: 473;
                            dpadAreaBottomY: 662;
                            dpadAreaLeftX: 319;
                            dpadAreaRightX: 495;

                            //parameter for LB
                            padL1Width : 197;
                            padL1Height : 116;
                            padL1TopY: 180;
                            padL1LeftX: 125;

                            //parameter for RB
                            padR1Width : 196;
                            padR1Height : 116;
                            padR1TopY: 181;
                            padR1LeftX: 807;

                            //parameter for LT
                            padL2Width : 201;
                            padL2Height : 185;
                            padL2TopY: 4;
                            padL2LeftX: 122;

                            //parameter for RT
                            padR2Width : 202;
                            padR2Height : 183;
                            padR2TopY: 2;
                            padR2LeftX: 802;

                            //parameter for Left stick
                            lStickWidth : 132;
                            lStickHeight : 130;
                            lStickTopY: 312;
                            lStickLeftX: 198;

                            //parameter for Right stick
                            rStickWidth : 131;
                            rStickHeight : 131;
                            rStickTopY: 503;
                            rStickLeftX: 647;

                            //to adapt contrast/brightness
                            contrast : 0.1
                            brightness: 0.2

            } //As Amazon luna*/

            /*ListElement {   name: "ps4"; qml: "gamepad/preview/ContainerCustom.qml";

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

                            hasDpad : true;
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

                            //parameters for home/guide/hotkey
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
                            contrast : 0.1
                            brightness: 0.2

                            //to manage change of led colors
                            rgbLedColor: "0,0,255" //default value as blue
                            rgbLedLuminosity:  3.0

            } //As Sony PS4 pad*/

            /*ListElement {   name: "ps5"; qml: "gamepad/preview/ContainerCustom.qml";

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

                            hasDpad : true;
                            hasButtonsForDpad : true;

                            hasScreenshotButton : false;

                            ratio: 0.3; padBaseSourceSizeWidth : 1496 ; padBaseSourceSizeHeight : 1201;

                            //parameters for select
                            padSelectWidth : 44;
                            padSelectHeight : 70;
                            padSelectTopY: 295;
                            padSelectLeftX: 378;

                            //parameters for start
                            padStartWidth : 44;
                            padStartHeight : 70;
                            padStartTopY: 298;
                            padStartLeftX: 1075;

                            //parameters for home/guide/hotkey
                            padGuideWidth : 94;
                            padGuideHeight : 71;
                            padGuideTopY: 653;
                            padGuideLeftX: 702;

                            //parameters for A/B/X/Y

                            //As cross
                            padAWidth : 98;
                            padAHeight : 99;
                            padATopY: 555;
                            padALeftX: 1163;

                            //As cycle
                            padBWidth : 100;
                            padBHeight : 98;
                            padBTopY: 446;
                            padBLeftX: 1273;

                            //As square
                            padXWidth : 99;
                            padXHeight : 101;
                            padXTopY: 445;
                            padXLeftX: 1054;

                            //As Triangle
                            padYWidth : 99;
                            padYHeight : 97;
                            padYTopY: 335;
                            padYLeftX: 1164;

                            //parameter for Dpad with dedicated buttons and separated
                            dpadUpWidth : 91;
                            dpadUpHeight : 113;
                            dpadUpTopY: 368;
                            dpadUpLeftX: 237;

                            dpadDownWidth : 92;
                            dpadDownHeight : 112;
                            dpadDownTopY: 512;
                            dpadDownLeftX: 236;

                            dpadLeftWidth : 112;
                            dpadLeftHeight : 92;
                            dpadLeftTopY: 451;
                            dpadLeftLeftX: 153;

                            dpadRightWidth : 112;
                            dpadRightHeight : 91;
                            dpadRightTopY: 449;
                            dpadRightLeftX: 298;

                            //parameter for L1
                            padL1Width : 198;
                            padL1Height : 68;
                            padL1TopY: 211;
                            padL1LeftX: 182;

                            //parameter for R1
                            padR1Width : 199;
                            padR1Height : 68;
                            padR1TopY: 211;
                            padR1LeftX: 1113;

                            //parameter for L2
                            padL2Width : 184;
                            padL2Height : 175;
                            padL2TopY: 0;
                            padL2LeftX: 187;

                            //parameter for R2
                            padR2Width : 184;
                            padR2Height : 176;
                            padR2TopY: 0;
                            padR2LeftX: 1117;

                            //parameter for Left stick
                            lStickWidth : 174;
                            lStickHeight : 170;
                            lStickTopY: 617;
                            lStickLeftX: 423;

                            //parameter for Right stick
                            rStickWidth : 172;
                            rStickHeight : 172;
                            rStickTopY: 617;
                            rStickLeftX: 902;

                            //to adapt contrast/brightness
                            contrast : 0.1
                            brightness: 0.2

            } //As Sony PS5 pad*/

            /*ListElement {   name: "n64"; qml: "gamepad/preview/ContainerCustom.qml";

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

                            hasDpad : true;
                            hasButtonsForDpad : false;

                            hasScreenshotButton : false;

                            ratio: 0.6; padBaseSourceSizeWidth : 858 ; padBaseSourceSizeHeight : 751;

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

                            //parameters for home/guide/hotkey (Home of Nintendo Switch N64 controller or Home button of Mayflash N64 Adapter V2 - only on player 1)
                            padGuideWidth : 36;
                            padGuideHeight : 17;
                            padGuideTopY: 61;
                            padGuideLeftX: 527;

                            //parameters for A/B (X/Y not used for the moment)
                            //As A
                            padAWidth : 66;
                            padAHeight : 61;
                            padATopY: 375;
                            padALeftX: 620;

                            //As B
                            padBWidth : 69;
                            padBHeight : 64;
                            padBTopY: 325;
                            padBLeftX: 559;

                            //As X
                            padXWidth : 0;
                            padXHeight : 0;
                            padXTopY: 0;
                            padXLeftX: 0;

                            //As Y
                            padYWidth : 0;
                            padYHeight : 0;
                            padYTopY: 0;
                            padYLeftX: 0;

                            //parameter for Dpad
                            dpadAreaTopY: 267;
                            dpadAreaBottomY: 391;
                            dpadAreaLeftX: 97;
                            dpadAreaRightX: 227;

                            //parameter for L
                            padL1Width : 187;
                            padL1Height : 89;
                            padL1TopY: 91;
                            padL1LeftX: 73;

                            //parameter for R
                            padR1Width : 186;
                            padR1Height : 89;
                            padR1TopY: 91;
                            padR1LeftX: 603;

                            //parameter for Z
                            padL2Width : 73;
                            padL2Height : 86;
                            padL2TopY: 605;
                            padL2LeftX: 178;

                            //parameter for ZR (ZR on nintendo switch N64 controller)
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
                            //parameter for Up
                            rStickUpWidth : 52;
                            rStickUpHeight : 56;
                            rStickUpTopY: 232;
                            rStickUpLeftX: 698;

                            //parameter for Down
                            rStickDownWidth : 51;
                            rStickDownHeight : 50;
                            rStickDownTopY: 327;
                            rStickDownLeftX: 696;

                            //parameter for Left
                            rStickLeftWidth : 53;
                            rStickLeftHeight : 55;
                            rStickLeftTopY: 281;
                            rStickLeftLeftX: 643;

                            //parameter for Right
                            rStickRightWidth : 52;
                            rStickRightHeight : 55;
                            rStickRightTopY: 273;
                            rStickRightLeftX: 748;

                            //to adapt contrast/brightness
                            contrast : 0.1
                            brightness: 0.2

            } //As Nintendo 64 pad (but C buttons are on RStick, no X/Y, Z as L2, ZR as R2)*/

            /*ListElement {   name: "wiimote"; qml: "gamepad/preview/ContainerCustom.qml";

                            hasDedicatedGuide: true;
                            hasSelect: true;
                            hasStart: true;

                            hasA: true;
                            hasB: true;
                            hasX: true;
                            hasY: true;
                            hasNintendoPad : false;

                            hasL1 : false; hasR1 : false;
                            hasL2 : false; hasR2 : false;

                            hasLeftStick : false; hasRightStick : false; hasButtonsForRightStick : false;
                            hasL3 : false; hasR3 : false;

                            hasDpad : true;
                            hasButtonsForDpad : false;

                            hasScreenshotButton : false;

                            ratio: 0.9; padBaseSourceSizeWidth : 290 ; padBaseSourceSizeHeight : 502;

                            //parameters for select
                            padSelectWidth : 22;
                            padSelectHeight : 22;
                            padSelectTopY: 228;
                            padSelectLeftX: 183;

                            //parameters for start
                            padStartWidth : 22;
                            padStartHeight : 22;
                            padStartTopY: 228;
                            padStartLeftX: 251;

                            //parameters for home/guide/hotkey (Home of Nintendo Wiimote controller)
                            padGuideWidth : 21;
                            padGuideHeight : 22;
                            padGuideTopY: 228;
                            padGuideLeftX: 217;

                            //parameters for A/B/X(1)/Y(2)
                            //As A
                            padAWidth : 40;
                            padAHeight : 41;
                            padATopY: 135;
                            padALeftX: 208;

                            //As B
                            padBWidth : 50;
                            padBHeight : 68;
                            padBTopY: 76;
                            padBLeftX: 36;

                            //As 1
                            padXWidth : 27;
                            padXHeight : 26;
                            padXTopY: 356;
                            padXLeftX: 215;

                            //As 2
                            padYWidth : 28;
                            padYHeight : 27;
                            padYTopY: 400;
                            padYLeftX: 215;

                            //parameter for Dpad
                            dpadAreaTopY: 49;
                            dpadAreaBottomY: 110;
                            dpadAreaLeftX: 197;
                            dpadAreaRightX: 258;

                            //nunchuck isn't define and no picture
                            //parameter for C
                            //padL2Width : 73;
                            //padL2Height : 86;
                            //padL2TopY: 605;
                            //padL2LeftX: 178;

                            //parameter for Z
                            //padL2Width : 73;
                            //padL2Height : 86;
                            //padL2TopY: 605;
                            //padL2LeftX: 178;

                            //parameter for Left stick
                            //lStickWidth : 81;
                            //lStickHeight : 71;
                            //lStickTopY: 477;
                            //lStickLeftX: 390;

                            //to adapt contrast/brightness
                            contrast : 0.1
                            brightness: 0.2

            } //As Nintendo Wiimote pad (but C buttons are on RStick, no X/Y, Z as L2, ZR as R2)*/

            /*ListElement {   name: "switchpro"; qml: "gamepad/preview/ContainerCustom.qml";

                            hasDedicatedGuide: true;
                            hasSelect: true;
                            hasStart: true;

                            hasA: true;
                            hasB: true;
                            hasX: true;
                            hasY: true;
                            hasNintendoPad : true;

                            hasL1 : true; hasR1 : true;
                            hasL2 : true; hasR2 : true;

                            hasLeftStick : true; hasRightStick : true; hasButtonsForRightStick : false;
                            hasL3 : true; hasR3 : true;

                            hasDpad : true;
                            hasButtonsForDpad : false;

                            hasScreenshotButton : false;

                            ratio: 0.6; padBaseSourceSizeWidth : 875 ; padBaseSourceSizeHeight : 699;
                            
                            //parameters for select
                            padSelectWidth : 37;
                            padSelectHeight : 38;
                            padSelectTopY: 190;
                            padSelectLeftX: 310;

                            //parameters for start
                            padStartWidth : 38;
                            padStartHeight : 38;
                            padStartTopY: 190;
                            padStartLeftX: 527;

                            //parameters for home/guide/hotkey
                            padGuideWidth : 37;
                            padGuideHeight : 38;
                            padGuideTopY: 256;
                            padGuideLeftX: 481;

                            //parameters for screenshot -> share //RFU
                            //padShareWidth : 36;
                            //padShareHeight : 35;
                            //padShareTopY: 257;
                            //padShareLeftX: 357;

                            //parameters for A/B/X/Y
                            //As B -> A
                            padAWidth : 64;
                            padAHeight : 64;
                            padATopY: 243;
                            padALeftX: 705;

                            //As A -> B
                            padBWidth : 66;
                            padBHeight : 62;
                            padBTopY: 302;
                            padBLeftX: 636;

                            //As Y -> X
                            padXWidth : 66;
                            padXHeight : 64;
                            padXTopY: 183;
                            padXLeftX: 636;

                            //As X -> Y
                            padYWidth : 64;
                            padYHeight : 64;
                            padYTopY: 243;
                            padYLeftX: 568;

                            //parameter for Dpad
                            dpadAreaTopY: 328;
                            dpadAreaBottomY: 462;
                            dpadAreaLeftX: 235;
                            dpadAreaRightX: 369;

                            //parameter for L
                            padL1Width : 209;
                            padL1Height : 70;
                            padL1TopY: 92;
                            padL1LeftX: 98;

                            //parameter for R
                            padR1Width : 206;
                            padR1Height : 69;
                            padR1TopY: 92;
                            padR1LeftX: 571;

                            //parameter for ZL
                            padL2Width : 158;
                            padL2Height : 70;
                            padL2TopY: 0;
                            padL2LeftX: 102;

                            //parameter for ZR
                            padR2Width : 153;
                            padR2Height : 72;
                            padR2TopY: 0;
                            padR2LeftX: 603;

                            //parameter for Left stick
                            lStickWidth : 100;
                            lStickHeight : 98;
                            lStickTopY: 226;
                            lStickLeftX: 146;

                            //parameter for Right stick
                            rStickWidth : 100;
                            rStickHeight : 99;
                            rStickTopY: 345;
                            rStickLeftX: 503;

                            //to adapt contrast/brightness
                            contrast : 0.1
                            brightness: 0.2

            } //As switchpro pad*/
            
            /*ListElement {   name: "stadia"; qml: "gamepad/preview/ContainerCustom.qml";

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

                            hasDpad : true;
                            hasButtonsForDpad : false;

                            hasScreenshotButton : false;

                            ratio: 0.6; padBaseSourceSizeWidth : 824 ; padBaseSourceSizeHeight : 680;
                            
                            //parameters for select
                            padSelectWidth : 41;
                            padSelectHeight : 19;
                            padSelectTopY: 195;
                            padSelectLeftX: 297;

                            //parameters for start
                            padStartWidth : 41;
                            padStartHeight : 21;
                            padStartTopY: 195;
                            padStartLeftX: 486;

                            //parameters for home/guide/hotkey
                            padGuideWidth : 55;
                            padGuideHeight : 54;
                            padGuideTopY: 336;
                            padGuideLeftX: 384;
                            
                            //parameters for screenshot -> share //RFU
                            //padShareWidth : 32;
                            //padShareHeight : 29;
                            //padShareTopY: 242;
                            //padShareLeftX: 455;

                            //parameters for A/B/X/Y
                            //As A
                            padAWidth : 51;
                            padAHeight : 50;
                            padATopY: 282;
                            padALeftX: 620;

                            //As B
                            padBWidth : 51;
                            padBHeight : 45;
                            padBTopY: 237;
                            padBLeftX: 673;

                            //As X
                            padXWidth : 51;
                            padXHeight : 48;
                            padXTopY: 233;
                            padXLeftX: 565;

                            //As Y
                            padYWidth : 53;
                            padYHeight : 45;
                            padYTopY: 188;
                            padYLeftX: 617;

                            //parameter for Dpad
                            dpadAreaTopY: 199;
                            dpadAreaBottomY: 319;
                            dpadAreaLeftX: 115;
                            dpadAreaRightX: 249;

                            //parameter for LB
                            padL1Width : 119;
                            padL1Height : 39;
                            padL1TopY: 143;
                            padL1LeftX: 121;

                            //parameter for RB
                            padR1Width : 116;
                            padR1Height : 39;
                            padR1TopY: 143;
                            padR1LeftX: 587;

                            //parameter for LT
                            padL2Width : 132;
                            padL2Height : 128;
                            padL2TopY: 0;
                            padL2LeftX: 107;

                            //parameter for RT
                            padR2Width : 131;
                            padR2Height : 122;
                            padR2TopY: 0;
                            padR2LeftX: 575;

                            //parameter for Left stick
                            lStickWidth : 91;
                            lStickHeight : 86;
                            lStickTopY: 300;
                            lStickLeftX: 235;

                            //parameter for Right stick
                            rStickWidth : 94;
                            rStickHeight : 83;
                            rStickTopY: 301;
                            rStickLeftX: 496;

                            //to adapt contrast/brightness
                            contrast : 0.1
                            brightness: 0.2

            } //As Google STADIA pad*/

        }

        //DEPREACTED function used in the past when conf/media was hardcoded/loaded in Pegasus-Frontend
        //function to dynamically set container layout from gamepad name using internal ListModel
        function getControllerLayoutIndex(gamepad) {
            var controllerName = gamepad.name
            var deviceLayout = gamepad.deviceLayout
            var layoutName = "";
            var layoutQml = "";
            let type = "controller";
            let i = 0;
            if (deviceLayout !== ""){
                //to get the one proposed from gamepad input.cfg deviceLayout if not empty
                for(var l = 0; l < myControllerLayout.count;l++)
                {
                    if(myControllerLayout.get(l).name === deviceLayout){
                        layoutQml = myControllerLayout.get(l).qml;
                        return l;
                    }
                }
                //if nothing found, we will search from name
            }
            //split name that could contain the name + hid name separated by ' - '
            const names = controllerName.split(" - ");
            if(names.length >= 2){
                controllerName = names[1]; //to keep only the hid part if exist
            }
            //search assets using the good type
            do{
                const keywords = myDeviceAssets.get(i).keywords.split(",");
                for(var j = 0; j < keywords.length;j++)
                {
                    if (isKeywordFound(controllerName, "", keywords[j]) && (myDeviceAssets.get(i).type === type ) && (keywords[j] !== "")){
                        layoutName = myDeviceAssets.get(i).layout;
                        const exclusions = myDeviceAssets.get(i).exclusions.split(",");
                        for(var j2 = 0; j2 < exclusions.length; j2++)
                        {
                            if (isExclusionFound(controllerName, "", exclusions[j2])){
                                layoutName = "";
                            }
                        }
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
            }while ((layoutQml === "") && (layoutName !== "default") && (i < myDeviceAssets.count))
            if (layoutQml === ""){
                //to get default one if empty
                for(var l2 = 0; l2 < myControllerLayout.count;l2++)
                {
                    if(myControllerLayout.get(l2).name === "default"){
                        layoutQml = myControllerLayout.get(l2).qml;
                        return l2;
                    }
                }
            }
            //if issue/never reach
            return -1;
        }

        //new function to get deviceLayout from controllerName if deviceLayout is not yet provided from input.cfg
        function getControllerLayoutName(gamepad) {
            let layoutName = "";
            let controllerName = "";
            let type = "controller";
            let i = 0;

            //check first if deviceLayout is not provided from input.cfg
            if((typeof(gamepad.deviceLayout) !== "undefined") && (gamepad.deviceLayout !== null) && gamepad.deviceLayout !== ""){
                //to get the one proposed from gamepad input.cfg deviceLayout if not empty
                layoutName = gamepad.deviceLayout;
                return layoutName
            }

            //split name that could contain the name + hid name separated by ' - '
            const names = gamepad.name.split(" - ");
            if(names.length >= 2){
                controllerName = names[1]; //to keep only the hid part if exist
            }
            else{
                controllerName = gamepad.name;
            }

            //search asset using the good type
            do{
                const keywords = myDeviceAssets.get(i).keywords.split(",");
                for(var j = 0; j < keywords.length;j++)
                {
                    if (isKeywordFound(controllerName, "", keywords[j]) && (myDeviceAssets.get(i).type === type ) && (keywords[j] !== "")){
                        layoutName = myDeviceAssets.get(i).layout;
                        const exclusions = myDeviceAssets.get(i).exclusions.split(",");
                        for(var j2 = 0; j2 < exclusions.length; j2++)
                        {
                            if (isExclusionFound(controllerName, "", exclusions[j2])){
                                layoutName = "";
                                break;
                            }
                        }
                        //return layoutName if anyone match and not excluded
                        if((typeof(layoutName) !== "undefined") && (layoutName !== null) && (layoutName !== "")){
                            return layoutName
                        }
                    }
                }
                i = i + 1;
            }while (i < myDeviceAssets.count)

            //if issue/never reach
            return "default";
        }

        //function to set all parameters to be used by "ContainerCustom.qml"
        //these parameters could be provdied by ListModel myControllerLayout
        //or using QML loaded dynamically from:
        // /recalbox/share_init/system/.pegasus-frontend/assets/gamepad/
        // or to let user to add new skins (take care: existing device layout should exists/knows to add any new skin)
        // /recalbox/share/system/.pegasus-frontend/assets/gamepad/
        function setParameters(){
            var index = loaderPadPreview.layoutIndex;
            //console.log("loaderPadPreview.layoutIndex:" + loaderPadPreview.layoutIndex);
            var name = loaderPadPreview.layoutName;
            //console.log("loaderPadPreview.layoutName:" + loaderPadPreview.layoutName);
            //console.log("layoutLoader : " + layoutLoader.toString())
            //console.log("layoutLoader.item : " + layoutLoader.item.toString())
            //console.log("layoutLoader.item.get(0) : " + layoutLoader.item.get(0).toString())
            var layout;
            if(index === -1){
                if((typeof(layoutLoader.item) !== "undefined") && (layoutLoader.item !== null)){
                    layout = layoutLoader.item.get(0);
                }
            }
            else{
                //console.log("layout = myControllerLayout.get(index)");
                layout = myControllerLayout.get(index);  //layout from myControllerLayout ListModel and selected ListElement
            }
            if((typeof(layout) !== "undefined") && (layout !== null)){
                if(layout.qml.includes("ContainerCustom")){ //if we use the one that we could customize

                    //Settings of layout availability features list
                    if(typeof(layout.hasSelect) !== 'undefined') root.padPreview.hasSelect = layout.hasSelect;
                    if(typeof(layout.hasStart) !== 'undefined') root.padPreview.hasStart = layout.hasStart;

                    if(typeof(layout.hasDedicatedGuide) !== 'undefined') root.padPreview.hasDedicatedGuide = layout.hasDedicatedGuide;

                    if(typeof(layout.hasDpad) !== 'undefined') root.padPreview.hasDpad = layout.hasDpad;
                    if(typeof(layout.hasButtonsForDpad) !== 'undefined') root.padPreview.hasButtonsForDpad = layout.hasButtonsForDpad;

                    if(typeof(layout.hasA) !== 'undefined') root.padPreview.hasA = layout.hasA;
                    if(typeof(layout.hasB) !== 'undefined') root.padPreview.hasB = layout.hasB;
                    if(typeof(layout.hasX) !== 'undefined') root.padPreview.hasX = layout.hasX;
                    if(typeof(layout.hasY) !== 'undefined') root.padPreview.hasY = layout.hasY;

                    if(typeof(layout.hasL1) !== 'undefined') root.padPreview.hasL1 = layout.hasL1;
                    if(typeof(layout.hasR1) !== 'undefined') root.padPreview.hasR1 = layout.hasR1;

                    if(typeof(layout.hasL2) !== 'undefined') root.padPreview.hasL2 = layout.hasL2;
                    if(typeof(layout.hasR2) !== 'undefined') root.padPreview.hasR2 = layout.hasR2;


                    if(typeof(layout.hasLeftStick) !== 'undefined') root.padPreview.hasLeftStick = layout.hasLeftStick;
                    if(typeof(layout.hasRightStick) !== 'undefined') root.padPreview.hasRightStick = layout.hasRightStick;
                    if(typeof(layout.hasButtonsForRightStick) !== 'undefined') root.padPreview.hasButtonsForRightStick = layout.hasButtonsForRightStick;

                    //L3/R3 included in left/right sticks
                    if(typeof(layout.hasL3) !== 'undefined') root.padPreview.hasL3 = layout.hasL3;
                    if(typeof(layout.hasR3) !== 'undefined') root.padPreview.hasR3 = layout.hasR3;

                    if(typeof(layout.hasScreenshotButton) !== 'undefined') root.padPreview.hasScreenshotButton = layout.hasScreenshotButton;

                    //Settings of parameters for base
                    if(typeof(layout.ratio) !== 'undefined') root.padPreview.ratio = layout.ratio;
                    if(typeof(layout.padBaseSourceSizeWidth) !== 'undefined') root.padPreview.padBaseSourceSizeWidth = layout.padBaseSourceSizeWidth;
                    if(typeof(layout.padBaseSourceSizeHeight) !== 'undefined') root.padPreview.padBaseSourceSizeHeight = layout.padBaseSourceSizeHeight;

                    //Settings of parameters for select
                    if(typeof(layout.padSelectWidth) !== 'undefined') root.padPreview.padSelectWidth = layout.padSelectWidth;
                    if(typeof(layout.padSelectHeight) !== 'undefined') root.padPreview.padSelectHeight = layout.padSelectHeight;
                    if(typeof(layout.padSelectTopY) !== 'undefined') root.padPreview.padSelectTopY = layout.padSelectTopY;
                    if(typeof(layout.padSelectLeftX) !== 'undefined') root.padPreview.padSelectLeftX = layout.padSelectLeftX;

                    //Settings of parameters for start
                    if(typeof(layout.padStartWidth) !== 'undefined') root.padPreview.padStartWidth = layout.padStartWidth;
                    if(typeof(layout.padStartHeight) !== 'undefined') root.padPreview.padStartHeight = layout.padStartHeight;
                    if(typeof(layout.padStartTopY) !== 'undefined') root.padPreview.padStartTopY = layout.padStartTopY;
                    if(typeof(layout.padStartLeftX) !== 'undefined') root.padPreview.padStartLeftX = layout.padStartLeftX;

                    //Settings of parameters for guide
                    if(typeof(layout.padGuideWidth) !== 'undefined') root.padPreview.padGuideWidth = layout.padGuideWidth;
                    if(typeof(layout.padGuideHeight) !== 'undefined') root.padPreview.padGuideHeight = layout.padGuideHeight;
                    if(typeof(layout.padGuideTopY) !== 'undefined') root.padPreview.padGuideTopY = layout.padGuideTopY;
                    if(typeof(layout.padGuideLeftX) !== 'undefined') root.padPreview.padGuideLeftX = layout.padGuideLeftX;

                    //Settings of parameters for A/B/X/Y
                    if(typeof(layout.padABXYAreaTopY) !== 'undefined') root.padPreview.padABXYAreaTopY = layout.padABXYAreaTopY;
                    if(typeof(layout.padABXYAreaBottomY) !== 'undefined') root.padPreview.padABXYAreaBottomY = layout.padABXYAreaBottomY;
                    if(typeof(layout.padABXYAreaLeftX) !== 'undefined') root.padPreview.padABXYAreaLeftX = layout.padABXYAreaLeftX;
                    if(typeof(layout.padABXYAreaRightX) !== 'undefined') root.padPreview.padABXYAreaRightX = layout.padABXYAreaRightX;

                    if(typeof(layout.padAWidth) !== 'undefined') root.padPreview.padAWidth = layout.padAWidth;
                    if(typeof(layout.padAHeight) !== 'undefined') root.padPreview.padAHeight = layout.padAHeight;
                    if(typeof(layout.padATopY) !== 'undefined') root.padPreview.padATopY = layout.padATopY;
                    if(typeof(layout.padALeftX) !== 'undefined') root.padPreview.padALeftX = layout.padALeftX;

                    if(typeof(layout.padBWidth) !== 'undefined') root.padPreview.padBWidth = layout.padBWidth;
                    if(typeof(layout.padBHeight) !== 'undefined') root.padPreview.padBHeight = layout.padBHeight;
                    if(typeof(layout.padBTopY) !== 'undefined') root.padPreview.padBTopY = layout.padBTopY;
                    if(typeof(layout.padBLeftX) !== 'undefined') root.padPreview.padBLeftX = layout.padBLeftX;

                    if(typeof(layout.padXWidth) !== 'undefined') root.padPreview.padXWidth = layout.padXWidth;
                    if(typeof(layout.padXHeight) !== 'undefined') root.padPreview.padXHeight = layout.padXHeight;
                    if(typeof(layout.padXTopY) !== 'undefined') root.padPreview.padXTopY = layout.padXTopY;
                    if(typeof(layout.padXLeftX) !== 'undefined') root.padPreview.padXLeftX = layout.padXLeftX;

                    if(typeof(layout.padYWidth) !== 'undefined') root.padPreview.padYWidth = layout.padYWidth;
                    if(typeof(layout.padYHeight) !== 'undefined') root.padPreview.padYHeight = layout.padYHeight;
                    if(typeof(layout.padYTopY) !== 'undefined') root.padPreview.padYTopY = layout.padYTopY;
                    if(typeof(layout.padYLeftX) !== 'undefined') root.padPreview.padYLeftX = layout.padYLeftX;

                    if(typeof(layout.hasNintendoPad) !== 'undefined') root.padPreview.hasNintendoPad = layout.hasNintendoPad;

                    //Settings of parameters for L1/R1/L2/R2/L3/R3
                    if(typeof(layout.padL1Width) !== 'undefined') root.padPreview.padL1Width = layout.padL1Width;
                    if(typeof(layout.padL1Height) !== 'undefined') root.padPreview.padL1Height = layout.padL1Height;
                    if(typeof(layout.padL1TopY) !== 'undefined') root.padPreview.padL1TopY = layout.padL1TopY;
                    if(typeof(layout.padL1LeftX) !== 'undefined') root.padPreview.padL1LeftX = layout.padL1LeftX;

                    if(typeof(layout.padL2Width) !== 'undefined') root.padPreview.padL2Width = layout.padL2Width;
                    if(typeof(layout.padL2Height) !== 'undefined') root.padPreview.padL2Height = layout.padL2Height;
                    if(typeof(layout.padL2TopY) !== 'undefined') root.padPreview.padL2TopY = layout.padL2TopY;
                    if(typeof(layout.padL2LeftX) !== 'undefined') root.padPreview.padL2LeftX = layout.padL2LeftX;

                    if(typeof(layout.padR1Width) !== 'undefined') root.padPreview.padR1Width = layout.padR1Width;
                    if(typeof(layout.padR1Height) !== 'undefined') root.padPreview.padR1Height = layout.padR1Height;
                    if(typeof(layout.padR1TopY) !== 'undefined') root.padPreview.padR1TopY = layout.padR1TopY;
                    if(typeof(layout.padR1LeftX) !== 'undefined') root.padPreview.padR1LeftX = layout.padR1LeftX;

                    if(typeof(layout.padR2Width) !== 'undefined') root.padPreview.padR2Width = layout.padR2Width;
                    if(typeof(layout.padR2Height) !== 'undefined') root.padPreview.padR2Height = layout.padR2Height;
                    if(typeof(layout.padR2TopY) !== 'undefined') root.padPreview.padR2TopY = layout.padR2TopY;
                    if(typeof(layout.padR2LeftX) !== 'undefined') root.padPreview.padR2LeftX = layout.padR2LeftX;

                    //Settings of parameters for Dpad
                    if(typeof(layout.dpadAreaTopY) !== 'undefined') root.padPreview.dpadAreaTopY = layout.dpadAreaTopY;
                    if(typeof(layout.dpadAreaBottomY) !== 'undefined') root.padPreview.dpadAreaBottomY = layout.dpadAreaBottomY;
                    if(typeof(layout.dpadAreaLeftX) !== 'undefined') root.padPreview.dpadAreaLeftX = layout.dpadAreaLeftX;
                    if(typeof(layout.dpadAreaRightX) !== 'undefined') root.padPreview.dpadAreaRightX = layout.dpadAreaRightX;

                    //Settings of parameters for Dpad using dedicated buttons for each directions
                    if(typeof(layout.dpadUpWidth) !== 'undefined') root.padPreview.dpadUpWidth = layout.dpadUpWidth;
                    if(typeof(layout.dpadUpHeight) !== 'undefined') root.padPreview.dpadUpHeight = layout.dpadUpHeight;
                    if(typeof(layout.dpadUpTopY) !== 'undefined') root.padPreview.dpadUpTopY = layout.dpadUpTopY;
                    if(typeof(layout.dpadUpLeftX) !== 'undefined') root.padPreview.dpadUpLeftX = layout.dpadUpLeftX;

                    if(typeof(layout.dpadDownWidth) !== 'undefined') root.padPreview.dpadDownWidth = layout.dpadDownWidth;
                    if(typeof(layout.dpadDownHeight) !== 'undefined') root.padPreview.dpadDownHeight = layout.dpadDownHeight;
                    if(typeof(layout.dpadDownTopY) !== 'undefined') root.padPreview.dpadDownTopY = layout.dpadDownTopY;
                    if(typeof(layout.dpadDownLeftX) !== 'undefined') root.padPreview.dpadDownLeftX = layout.dpadDownLeftX;

                    if(typeof(layout.dpadLeftWidth) !== 'undefined') root.padPreview.dpadLeftWidth = layout.dpadLeftWidth;
                    if(typeof(layout.dpadLeftHeight) !== 'undefined') root.padPreview.dpadLeftHeight = layout.dpadLeftHeight;
                    if(typeof(layout.dpadLeftTopY) !== 'undefined') root.padPreview.dpadLeftTopY = layout.dpadLeftTopY;
                    if(typeof(layout.dpadLeftLeftX) !== 'undefined') root.padPreview.dpadLeftLeftX = layout.dpadLeftLeftX;

                    if(typeof(layout.dpadRightWidth) !== 'undefined') root.padPreview.dpadRightWidth = layout.dpadRightWidth;
                    if(typeof(layout.dpadRightHeight) !== 'undefined') root.padPreview.dpadRightHeight = layout.dpadRightHeight;
                    if(typeof(layout.dpadRightTopY) !== 'undefined') root.padPreview.dpadRightTopY = layout.dpadRightTopY;
                    if(typeof(layout.dpadRightLeftX) !== 'undefined') root.padPreview.dpadRightLeftX = layout.dpadRightLeftX;

                    //Settings of parameters for lStick/rStick
                    if(typeof(layout.lStickWidth) !== 'undefined') root.padPreview.lStickWidth = layout.lStickWidth;
                    if(typeof(layout.lStickHeight) !== 'undefined') root.padPreview.lStickHeight = layout.lStickHeight;
                    if(typeof(layout.lStickTopY) !== 'undefined') root.padPreview.lStickTopY = layout.lStickTopY;
                    if(typeof(layout.lStickLeftX) !== 'undefined') root.padPreview.lStickLeftX = layout.lStickLeftX;

                    if(typeof(layout.rStickWidth) !== 'undefined') root.padPreview.rStickWidth = layout.rStickWidth;
                    if(typeof(layout.rStickHeight) !== 'undefined') root.padPreview.rStickHeight = layout.rStickHeight;
                    if(typeof(layout.rStickTopY) !== 'undefined') root.padPreview.rStickTopY = layout.rStickTopY;
                    if(typeof(layout.rStickLeftX) !== 'undefined') root.padPreview.rStickLeftX = layout.rStickLeftX;

                    //Settings of parameter for rStick Buttons
                    if(typeof(layout.rStickUpWidth) !== 'undefined') root.padPreview.rStickUpWidth = layout.rStickUpWidth;
                    if(typeof(layout.rStickUpHeight) !== 'undefined') root.padPreview.rStickUpHeight = layout.rStickUpHeight;
                    if(typeof(layout.rStickUpTopY) !== 'undefined') root.padPreview.rStickUpTopY = layout.rStickUpTopY;
                    if(typeof(layout.rStickUpLeftX) !== 'undefined') root.padPreview.rStickUpLeftX = layout.rStickUpLeftX;

                    if(typeof(layout.rStickDownWidth) !== 'undefined') root.padPreview.rStickDownWidth = layout.rStickDownWidth;
                    if(typeof(layout.rStickDownHeight) !== 'undefined') root.padPreview.rStickDownHeight = layout.rStickDownHeight;
                    if(typeof(layout.rStickDownTopY) !== 'undefined') root.padPreview.rStickDownTopY = layout.rStickDownTopY;
                    if(typeof(layout.rStickDownLeftX) !== 'undefined') root.padPreview.rStickDownLeftX = layout.rStickDownLeftX;

                    if(typeof(layout.rStickLeftWidth) !== 'undefined') root.padPreview.rStickLeftWidth = layout.rStickLeftWidth;
                    if(typeof(layout.rStickLeftHeight) !== 'undefined') root.padPreview.rStickLeftHeight = layout.rStickLeftHeight;
                    if(typeof(layout.rStickLeftTopY) !== 'undefined') root.padPreview.rStickLeftTopY = layout.rStickLeftTopY;
                    if(typeof(layout.rStickLeftLeftX) !== 'undefined') root.padPreview.rStickLeftLeftX = layout.rStickLeftLeftX;

                    if(typeof(layout.rStickRightWidth) !== 'undefined') root.padPreview.rStickRightWidth = layout.rStickRightWidth;
                    if(typeof(layout.rStickRightHeight) !== 'undefined') root.padPreview.rStickRightHeight = layout.rStickRightHeight;
                    if(typeof(layout.rStickRightTopY) !== 'undefined') root.padPreview.rStickRightTopY = layout.rStickRightTopY;
                    if(typeof(layout.rStickRightLeftX) !== 'undefined') root.padPreview.rStickRightLeftX = layout.rStickRightLeftX;

                    //Settings of contrast/brightness
                    //console.log("typeof(layout.brightness) : ",typeof(layout.brightness));
                    //console.log("layout.brightness : ", layout.brightness);
                    //console.log("typeof(layout.contrast) : ",typeof(layout.contrast));
                    //console.log("layout.contrast : ", layout.contrast);

                    //to set specific brightness/contrast for L/R Buttons, start/select/guide & DPADs independent buttons.
                    if((typeof(layout.contrast) !== 'undefined') && (layout.contrast !== 0)) root.padPreview.contrast = layout.contrast;
                    if((typeof(layout.brightness) !== 'undefined') && (layout.brightness !== 0)) root.padPreview.brightness = layout.brightness;

                    //to manage led color (if exists and accessible from pixL)
                    if(typeof(layout.rgbLedColor) !== 'undefined'){
                       root.padPreview.rgbLedColor = api.internal.recalbox.getStringParameter("controllers.led.color.rgb.pad" + gamepadList.currentIndex,"");
                       //console.log("root.padPreview.rgbLedColor : ", root.padPreview.rgbLedColor);
                    }
                    if((typeof(layout.rgbLedLuminosity) !== 'undefined') && (layout.rgbLedLuminosity !== 1.0)) root.padPreview.rgbLedLuminosity = layout.rgbLedLuminosity;

                    //set name at the end to avoid error/warning to early ;-)
                    //console.log("root.padPreview.name before : " + root.padPreview.name);
                    //console.log("layout.name : " + layout.name)
                    if(typeof(optControllerSkin.skinName) !== "undefined" ){
                        //console.log("optControllerSkin.skinName : ", optControllerSkin.skinName , "");
                        root.padPreview.name = layout.name + optControllerSkin.skinName;
                    }
                    else{
                        //console.log("api.internal.recalbox.getStringParameter(layout.name + '.controller.skin', '') : ",api.internal.recalbox.getStringParameter(layout.name + ".controller.skin", ""));
                        root.padPreview.name = layout.name + api.internal.recalbox.getStringParameter(layout.name + "." + root.gamepad.deviceGUID + ".controller.skin", "");
                    }
                    //Add a way to select specific Controller Layout Element/values from QML model provided for a specific optControllerSkin
                    var fileToFind = loaderPadPreview.layoutAssetsPath.replace("file:/","") + root.padPreview.name + "/" + root.padPreview.name + ".qml"
                    //console.log("fileToFind : " + fileToFind);
                    var fileExists = api.internal.system.run("if [ -f " + fileToFind + " ]; then echo 'true' ; else echo 'false' ; fi ;").includes('true') ? true : false ;
                    //console.log("fileExists : " + fileExists);
                    if(fileExists !== false){
                        //console.log("loaderPadPreview.layoutAssetsPath : " + loaderPadPreview.layoutAssetsPath);
                        //if file doesn't exists, no loading in this case, just a warning visible in log
                        skinLoader.source = loaderPadPreview.layoutAssetsPath + root.padPreview.name + "/" + root.padPreview.name + ".qml"
                    }
                }
            }
        }

        // The Loader attempts to load a file for layout (is the full mapping for a layout detected/declared)
        Loader {
            id: layoutLoader
            source: ""
            active: true // Start loading immediately if true

            onStatusChanged: {
                //console.log("layoutLoader onStatusChanged");
                if (status === Loader.Loading) {
                    //console.log("layoutLoader Loader.Loading");
                    //RFU
                }
                else if (status === Loader.Ready) {
                    //console.log("layoutLoader Loader.Ready");
                    // SUCCESS: File was found and loaded. Proceed with data merge.
                    //console.log("layoutLoader found and loaded successfully.")
                    //console.log("layoutLoader : " + layoutLoader.toString())
                    //console.log("layoutLoader.item : " + layoutLoader.item.toString())
                    //console.log("layoutLoader.item.get(0) : " + layoutLoader.item.get(0).toString())
                    if((typeof(layoutLoader.item.get(0).qml) !== "undefined") && (layoutLoader.item.get(0).qml !== "")){
                        loaderPadPreview.layoutName = layoutLoader.item.get(0).name
                        loaderPadPreview.layoutIndex = -1; //to deactivate usage of index and MyController model
                        //console.log("loaderPadPreview.source  = layoutLoader.item.get(0).qml;")
                        loaderPadPreview.source  = layoutLoader.item.get(0).qml;
                        loaderPadPreview.enabled = true;
                    }
                    else{
                        // Unload the component in this case
                        layoutLoader.source = ""
                    }
                }
                else if (status === Loader.Error) {
                    // FAILURE: File was NOT found in resources (or had a syntax error).
                    //console.warn("QML file NOT found or failed to load. Skipping merge.")
                    if(loaderPadPreview.layoutIndex !== -1){
                        loaderPadPreview.layoutName = myControllerLayout.get(loaderPadPreview.layoutIndex).name;
                        loaderPadPreview.source = myControllerLayout.get(loaderPadPreview.layoutIndex).qml;
                        loaderPadPreview.enabled = true;
                    }
                    // Unload the component in this case
                    layoutLoader.source = ""
                }
            }
        }

        // The Loader attempts to load a file for skin (could be partial and not mandatory)
        Loader {
            id: skinLoader
            source: ""
            active: true // Start loading immediately if true

            onStatusChanged: {
                //console.log("skinLoader onStatusChanged");
                if (status === Loader.Loading) {
                    console.log("skinLoaderoutLoader Loader.Loading");
                    //RFU
                }
                else if (status === Loader.Ready) {
                    console.log("skinLoader Loader.Ready");
                    // SUCCESS: File was found and loaded. Proceed with data merge.
                    //console.log("skinLoader found and loaded successfully.")
                    //console.log("skinLoader : " + skinLoader.toString())
                    //console.log("skinLoader.item : " + skinLoader.item.toString())
                    //console.log("skinLoader.item.get(0) : " + skinLoader.item.get(0).toString())
                    layoutArea.loadAndMergeSingleElement(skinLoader.item.get(0))
                    skinLoader.source = ""
                }
                else if (status === Loader.Error) {
                    // FAILURE: File was NOT found in resources (or had a syntax error).
                    console.warn("QML file NOT found or failed to load. Skipping merge.")
                    // Unload the component in this case
                    skinLoader.source = ""
                }
            }
        }

        function loadAndMergeSingleElement(container) {

            if((root.padPreview !== null) && (typeof(root.padPreview) !== "undefined")){
                // 1. Get the loaded QtObject container
                var deviceModel = root.padPreview;

                // 2. Check for success and ensure there's at least one child (the ListElement)
                if (!container) {
                    console.warn("Could not load or find ListElement.")
                    return
                }

                // 3. The single ListElement is the first child
                var newElement = container;

                // 4. Dynamically build the new object (QVariantMap)
                var newObject = {}
                var keys = Object.keys(newElement)
                //console.log("keys.length : " + keys.length);
                for (var k = 0; k < keys.length; k++) {
                    var keyName = keys[k];
                    var keyValue = newElement[keyName]
                    //console.log("Update : " + keyName + " = " + keyValue);
                    deviceModel[keyName] = keyValue;
                }
            }
        }

        Loader {
            id: loaderPadPreview
            anchors.fill: parent
            enabled: false
            property int layoutIndex
            property string layoutName
            property string layoutAssetsPath
            asynchronous: false
            onStatusChanged: {
                //console.log("onStatusChanged");
                if (loaderPadPreview.status === Loader.Loading) {
                    console.log("loaderPadPreview Loader.Loading");
                    //RFU
                }
                else if (loaderPadPreview.status === Loader.Ready) {
                    console.log("loaderPadPreview Loader.Ready");
                    if(loaderPadPreview.item != null){
                        root.padPreview = loaderPadPreview.item;
                        //check if model has AssetsPath
                        if((typeof(root.padPreview.assetsPath) !== "undefined") && (optControllerSkin.internalvalue === "")){
                            root.padPreview.assetsPath = loaderPadPreview.layoutAssetsPath;
                        }
                        else{
                            // 1. Split the string into an array using the delimiter '/'
                            let pathParts = optControllerSkin.internalvalue.split("/");
                            // 2. Access the last element of the array using 'length - 1'
                            var skinName = pathParts[pathParts.length - 1].replace(loaderPadPreview.layoutName,"")
                            // 3. check if model has AssetsPath before update
                            if(typeof(root.padPreview.assetsPath) !== "undefined"){
                                //console.log("0 - root.padPreview.assetsPath : " + root.padPreview.assetsPath);
                                //take path of this skin to have the assetsPath
                                root.padPreview.assetsPath = "file:/" + optControllerSkin.internalvalue.replace(loaderPadPreview.layoutName + skinName,"");
                            }
                            //console.log("0.1 - root.padPreview.assetsPath : " + root.padPreview.assetsPath);
                        }
                        //set dynamically the layout
                        //console.log("loaderPadPreview parent.setParameters()");
                        parent.setParameters();
                        //console.log("loaderPadPreview root.gamepad : ", root.gamepad);
                        if(root.gamepad !== null){
                            loaderPadPreview.item.gamepad = root.gamepad;
                        }
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

                KeyNavigation.right: configR2.visible ? configR2 : configSelect
                KeyNavigation.down: configDpadUp
            }
            visible: (typeof(root.padPreview) !== 'undefined') ? ((typeof(root.padPreview.hasL1) !== 'undefined') ? root.padPreview.hasL1 : true) : false
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
                KeyNavigation.up: configL2.visible ? configL2 : configSelect
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
 
                KeyNavigation.right: (typeof(root.padPreview) !== 'undefined') ? ((typeof(root.padPreview.hasButtonsForRightStick) !== 'undefined') ?
                                     ((root.padPreview.hasButtonsForRightStick === true) ? configRightStickPlusX : configRightStickX) : configRightStickX)
                                     : configRightStickX
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
 
                KeyNavigation.right: (typeof(root.padPreview) !== 'undefined') ? ((typeof(root.padPreview.hasButtonsForRightStick) !== 'undefined') ?
                                     ((root.padPreview.hasButtonsForRightStick === true) ? configRightStickMinusY : configRightStickY) : configRightStickY)
                                     : configRightStickY
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
                KeyNavigation.down: optControllerSkin
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
            visible: (typeof(root.padPreview) !== 'undefined') ? ((typeof(root.padPreview.hasR1) !== 'undefined') ? root.padPreview.hasR1 : true) : false
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
                                                   configX : (typeof(root.padPreview) !== 'undefined') ?
                                                       ((typeof(root.padPreview.hasButtonsForRightStick) !== 'undefined') ?
                                                            (root.padPreview.hasButtonsForRightStick ? configRightStickMinusX : configRightStickX)
                                                       : configRightStickX)
                                                   : configRightStickX )
                                              : configX )
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
                KeyNavigation.down: optControllerSkin
            }
        }
        Column {
            spacing: vpx(1)
            anchors {
                horizontalCenter: parent.horizontalCenter
                verticalCenter: parent.verticalCenter
                verticalCenterOffset: vpx(-230)
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
                    KeyNavigation.left: configL1
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

        Column {
            id: contentColumn
            spacing: vpx(1)

            anchors.horizontalCenter: parent.horizontalCenter
            anchors.horizontalCenterOffset: vpx(15)
            anchors.bottom: parent.bottom
            anchors.bottomMargin: vpx(-60)

            width: root.width * 0.5
            height: implicitHeight

            MultivalueOption {
                id: optControllerSkin

                //property to manage parameter name
                property string parameterName : loaderPadPreview.layoutName !== "" ? loaderPadPreview.layoutName + "." + root.gamepad.deviceGUID + ".controller.skin" : ""
                property string skinName : ""
                label: qsTr("Controller skin") + api.tr
                value: parameterName !== "" ? api.internal.recalbox.parameterslist.currentName(parameterName) : ""
                internalvalue: parameterName !== "" ? api.internal.recalbox.parameterslist.currentInternalName(parameterName): ""
                currentIndex: api.internal.recalbox.parameterslist.currentIndex
                count: api.internal.recalbox.parameterslist.count
                /*onParameterNameChanged: {
                    console.log("optControllerSkin.parameterName : " + parameterName)
                    console.log("loaderPadPreview.layoutName : " + loaderPadPreview.layoutName)
                }*/

                onInternalvalueChanged: {
                    //change layout skin if needed
                    if(internalvalue === ""){
                        skinName = "";
                        if(loaderPadPreview.status === Loader.Ready){
                            if(loaderPadPreview.layoutName !== ""){
                                root.padPreview.name = loaderPadPreview.layoutName;
                            }
                        }
                    }
                    else{
                        // 1. Split the string into an array using the delimiter '/'
                        let pathParts = internalvalue.split("/");
                        // 2. Access the last element of the array using 'length - 1'
                        skinName = pathParts[pathParts.length - 1].replace(loaderPadPreview.layoutName,"")
                        // 3. check if model has AssetsPath before update
                        if(typeof(root.padPreview) !== "undefined"){
                            if(typeof(root.padPreview.assetsPath) !== "undefined"){
                                //console.log("1 - root.padPreview.assetsPath : " + root.padPreview.assetsPath);
                                //take path of this skin to have the assetsPath
                                //but due to biding, WARNING WILL BE GENERATED DURING UPDATE of VALUES but no bad effect in UI
                                //only warning as following when we change the assetsPath value
                                //2025-10-24T02:32:39 [w] qrc:/frontend/menu/settings/gamepad/preview/PadTriggerCustom.qml:46:5: QML Image: Cannot open: file://recalbox/share_init/system/.pegasus-frontend/assets/gamepad/xboxseriespink/r2_xboxseriespink.png
                                root.padPreview.name = loaderPadPreview.layoutName + skinName
                                root.padPreview.assetsPath = "file:/" + internalvalue.replace(loaderPadPreview.layoutName + skinName,"");
                                loaderPadPreview.layoutAssetsPath = "file:/" + internalvalue.replace(loaderPadPreview.layoutName + skinName,"");
                                //console.log("2 - root.padPreview.assetsPath : " + root.padPreview.assetsPath);
                            }
                        }
                    }
                    //console.log("optControllerSkin.onInternalvalueChanged - skinName : " + skinName);
                    //console.log("optControllerSkin layoutArea.setParameters()");
                    //console.log("optControllerSkin loaderPadPreview.layoutName : " + loaderPadPreview.layoutName);
                    layoutArea.setParameters();
                }

                onActiveFocusChanged:{
                    if (activeFocus) padPreview.currentButton = "";
                }

                onActivate: {
                    //for callback by parameterslistBox
                    parameterslistBox.parameterName = parameterName;
                    parameterslistBox.callerid = optControllerSkin;

                    //to customize Box display
                    parameterslistBox.has_picture = true;
                    parameterslistBox.firstlist_minimum_width_purcentage = 0.53;
                    parameterslistBox.firstlist_maximum_width_purcentage = 0.53;
                    parameterslistBox.box_maximum_width = 750;
                    parameterslistBox.box_minimum_width = 750;
                    parameterslistBox.max_listitem_displayed = 5;

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
                    //console.log("updated value : " + value)
                    internalvalue = api.internal.recalbox.parameterslist.currentInternalName(parameterName);
                    //console.log("updated internalvalue : " + internalvalue)
                }

                onFocusChanged:{
                    if(focus){
                        api.internal.recalbox.parameterslist.currentName(parameterName);
                        currentIndex = api.internal.recalbox.parameterslist.currentIndex;
                        count = api.internal.recalbox.parameterslist.count;
                    }
                }
                KeyNavigation.up: configL3
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
        onClose: {
            callerid.focus = true
            callerid.forceActiveFocus()
        }
        onSelect: {
          //console.log("onSelect - callerid.parameterName : " + callerid.parameterName);
          //console.log("onSelect - index : " + index.toString());
            callerid.keypressed = true;
            //to use the good parameter
            api.internal.recalbox.parameterslist.currentName(callerid.parameterName);
            //to update index of parameterlist QAbstractList
            api.internal.recalbox.parameterslist.currentIndex = index;
            //to force update of display of selected value
            callerid.value = api.internal.recalbox.parameterslist.currentName(callerid.parameterName);
            callerid.internalvalue = api.internal.recalbox.parameterslist.currentInternalName(callerid.parameterName);
            //console.log("onSelect - callerid.value : " + callerid.value);
            callerid.currentIndex = api.internal.recalbox.parameterslist.currentIndex;
            //console.log("onSelect - callerid.currentIndex : " + callerid.currentIndex.toString());
            callerid.count = api.internal.recalbox.parameterslist.count;
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
