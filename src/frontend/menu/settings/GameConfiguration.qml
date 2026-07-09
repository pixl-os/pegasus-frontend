// Pegasus Frontend
//
// Created by BozoTheGeek 08/07/2026
//

import "common"
import "qrc:/qmlutils" as PegasusUtils
import QtQuick 2.12
import QtQuick.Controls 2.12
import QtQuick.Window 2.12
import QtQuick.XmlListModel 2.0

FocusScope {
    id: root

    signal close

    width: parent.width
    height: parent.height
    
    //anchors.fill: parent
    visible: 0 < (x + width) && x < Window.window.width

    enabled: focus

    property string emulator;
    property bool launchedAsDialogBox: false

    property var game
    property var system
    //to manage overloading
    property string prefix : game ? ("override." + emulator) : emulator
    //to manage better title in screen ScreenHeader (if we want to change it during loading)
    property string titleHeader: game ? game.title +  " > " + qsTr("Game configuration") + api.tr :
        (system ? system.name + " > " + qsTr("Game configuration") + api.tr :
         emulator + " > " + qsTr("Game configuration") + api.tr)

    //function to elide text string from right
    function elideStringFromRight(text, maxLength) {
      if (text.length > maxLength) {
        return text.substring(0, maxLength - 3) + '...';
      }
      return text;
    }

    //function to elide text string from left
    function elideStringFromLeft(text, maxLength) {
      if (text.length > maxLength) {
        return '...' + text.substring(text.length - (maxLength - 3));
      }
      return text;
    }

    /**
     * Generates an 8-digit ID based on a CRC32 hash of three values.
     * Mirroring the logic of Python's zlib.crc32(combined) % 100_000_000.
     */
    function generate8DigitId(val1, val2, val3) {
        var combined = val1 + "|" + val2 + "|" + val3;
        console.log("combined : " + combined);

        // 1. Create the table locally if it doesn't exist
        // Using a static-like pattern in JS
        if (typeof generate8DigitId.crcTable === 'undefined') {
            generate8DigitId.crcTable = [];
            for (var n = 0; n < 256; n++) {
                var c = n;
                for (var k = 0; k < 8; k++) {
                    c = ((c & 1) ? (0xEDB88320 ^ (c >>> 1)) : (c >>> 1));
                }
                generate8DigitId.crcTable[n] = c;
            }
        }

        var table = generate8DigitId.crcTable;
        var crc = 0 ^ (-1); // Equivalent to 0xFFFFFFFF

        // 2. Process characters
        for (var i = 0; i < combined.length; i++) {
            var code = combined.charCodeAt(i);

            // Handling UTF-8 encoding for multi-byte characters
            if (code < 0x80) {
                crc = (crc >>> 8) ^ table[(crc ^ code) & 0xFF];
            } else if (code < 0x800) {
                crc = (crc >>> 8) ^ table[(crc ^ (192 | (code >> 6))) & 0xFF];
                crc = (crc >>> 8) ^ table[(crc ^ (128 | (code & 63))) & 0xFF];
            } else {
                crc = (crc >>> 8) ^ table[(crc ^ (224 | (code >> 12))) & 0xFF];
                crc = (crc >>> 8) ^ table[(crc ^ (128 | ((code >> 6) & 63))) & 0xFF];
                crc = (crc >>> 8) ^ table[(crc ^ (128 | (code & 63))) & 0xFF];
            }
        }

        // 3. Finalize and force unsigned 32-bit
        var finalCrc = (crc ^ (-1)) >>> 0;
        console.log("finalCrc : " + finalCrc);

        console.log("finalCrc % 100000000 : " + finalCrc % 100000000);
        return (finalCrc % 100000000).toString().padStart(8, '0');
    }

    function removeExistingValues(firstString, secondString) {
        // 1. Convert the first string into an array of words
        // The regex /\s+/ splits by any whitespace (space, tabs, or newlines)
        let firstArray = firstString.split(/\s+/);
        //console.log("firstArray : " + firstArray)
        // 2. Convert the second string into an array
        let secondArray = secondString.split(/\s+/);
        //console.log("secondArray : " + secondArray)

        // 3. Filter the first array: Keep item ONLY if it's NOT in the second array
        let filteredArray = firstArray.filter(item => {
            return secondArray.indexOf(item) === -1;
        });
        //console.log("filteredArray : " + filteredArray)
        // 4. Join the result back into a space-separated string
        return filteredArray.join(" ");
    }

    Keys.onPressed: {
        if (api.keys.isCancel(event) && !event.isAutoRepeat) {
            event.accepted = true;
            root.close();
        }
    }
    PegasusUtils.HorizontalSwipeArea {
        anchors.fill: parent
        onSwipeRight: root.close()
    }
    MouseArea {
        anchors.fill: parent
        acceptedButtons: Qt.RightButton
        onClicked: root.close()
    }
    ScreenHeader {
        id: header
        text: titleHeader
        z: 2
    }

    clip: launchedAsDialogBox

    Flickable {
        id: container

        width: content.width
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: header.bottom
        anchors.bottom: parent.bottom

        contentWidth: content.width
        contentHeight: content.height

        //Behavior on contentY { PropertyAnimation { duration: 100 } }
        Behavior on contentY { NumberAnimation { duration: 200; easing.type: Easing.OutQuad }}

        boundsBehavior: Flickable.StopAtBounds
        boundsMovement: Flickable.StopAtBounds

        readonly property int yBreakpoint: height * 0.7
        readonly property int maxContentY: contentHeight - height

        function onFocus(item) {
            if (item.focus)
                contentY = Math.min(Math.max(0, item.y - yBreakpoint), maxContentY);
        }

        Timer {
            id: visibilityThrottle
            interval: 50 // Run check every 50ms during scroll
            repeat: false
            triggeredOnStart: false
            onTriggered: {
                for (var i = 0; i < contentColumn.children.length; i++) {
                    var child = contentColumn.children[i];
                    if (child.hasOwnProperty("parameterName") && child.hasOwnProperty("visibleInFlickable")) {
                        contentColumn.checkVisibility(child);
                    }
                }
            }
        }

        // Trigger check whenever the user scrolls
        onContentYChanged: {
            if(!visibilityThrottle.running)
                visibilityThrottle.start();
        }

        FocusScope {
            id: content

            focus: true
            enabled: focus

            width: contentColumn.width
            height: contentColumn.height

            Column {
                id: contentColumn
                spacing: vpx(5)

                width: launchedAsDialogBox ? root.width * 0.9 : root.width * 0.7

                height: implicitHeight

                //implicitHeight: childrenRect.height

                Item {
                    width: parent.width
                    height: implicitHeight + vpx(30)
                }

                // Your checkVisibility function stays here
                function checkVisibility(item) {
                    if (!item || !item.visible) return false;
                    //console.log("item.parameterName: ",item.parameterName);
                    // mapToItem(container, ...) works because 'container' is
                    // the visual viewport. This returns the position relative
                    // to the top-left of the visible area on screen.
                    var rectInFlickable = item.mapToItem(container, 0, 0);
                    //console.log("rectInFlickable.x : ",rectInFlickable.x);
                    //console.log("rectInFlickable.y : ",rectInFlickable.y);
                    //console.log("container.width : ",container.width);
                    //console.log("container.height : ",container.height);
                    //console.log("item.width : ",item.width);
                    //console.log("item.height : ",item.height);

                    var intersects =
                        rectInFlickable.x < container.width &&
                        rectInFlickable.x + item.width > 0 &&
                        rectInFlickable.y < container.height &&
                        rectInFlickable.y + item.height > 0;

                    //console.log("intersects : ",intersects);

                    if (item.visibleInFlickable !== intersects) {
                        if (intersects) {
                            // Load data only when entering the screen
                            if(item.isMultivalueOption){
                                item.value = api.internal.recalbox.parameterslist.currentName(item.parameterName);
                            }
                            else if(item.isMulticheckOption){
                                item.value = api.internal.recalbox.parameterslist.currentNameChecked(item.parameterName);
                            }
                            item.internalvalue = api.internal.recalbox.parameterslist.currentInternalName(item.parameterName);
                            item.currentIndex = api.internal.recalbox.parameterslist.currentIndex;
                            item.count = api.internal.recalbox.parameterslist.count;
                        }
                        item.visibleInFlickable = intersects;
                    }
                }

                // Inline XML for demonstration (you can change 'source' to a file path like "file:///path/to/file.xml")
                readonly property string xmlData: '<?xml version="1.0" encoding="utf-8"?>
                <GameProfile>
                    <ConfigValues>
                        <FieldInformation>
                            <CategoryName>General</CategoryName>
                            <FieldName>FreePlay</FieldName>
                            <FieldValue>0</FieldValue>
                            <FieldType>Bool</FieldType>
                        </FieldInformation>
                        <FieldInformation>
                            <CategoryName>Crosshair</CategoryName>
                            <FieldName>Enable</FieldName>
                            <FieldValue>0</FieldValue>
                            <FieldType>Bool</FieldType>
                        </FieldInformation>
                    </ConfigValues>
                </GameProfile>'
                readonly property string xmlDataTC5: '<?xml version="1.0" encoding="utf-8"?>
<GameProfile xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xsd="http://www.w3.org/2001/XMLSchema">
    <GamePath></GamePath>
    <TestMenuParameter></TestMenuParameter>
    <TestMenuIsExecutable>false</TestMenuIsExecutable>
    <ExtraParameters></ExtraParameters>
    <TestMenuExtraParameters></TestMenuExtraParameters>
    <EmulationProfile>TimeCrisis5</EmulationProfile>
    <GameProfileRevision>17</GameProfileRevision>
    <HasSeparateTestMode>false</HasSeparateTestMode>
    <EmulatorType>TeknoParrot</EmulatorType>
    <ExecutableName>RSLauncher.exe</ExecutableName>
    <Is64Bit>true</Is64Bit>
    <InvertedMouseAxis>true</InvertedMouseAxis>
    <GunGame>true</GunGame>
    <xAxisMin>0</xAxisMin>
    <xAxisMax>255</xAxisMax>
    <yAxisMin>0</yAxisMin>
    <yAxisMax>255</yAxisMax>
    <ConfigValues>
        <FieldInformation>
            <CategoryName>General</CategoryName>
            <FieldName>Input API</FieldName>
            <FieldValue>RawInput</FieldValue>
            <FieldType>Dropdown</FieldType>
            <FieldOptions>
                <string>DirectInput</string>
                <string>XInput</string>
                <string>RawInput</string>
            </FieldOptions>
        </FieldInformation>
        <FieldInformation>
            <CategoryName>General</CategoryName>
            <FieldName>FreePlay</FieldName>
            <FieldValue>0</FieldValue>
            <FieldType>Bool</FieldType>
        </FieldInformation>
        <FieldInformation>
            <CategoryName>Crosshair</CategoryName>
            <FieldName>Enable</FieldName>
            <FieldValue>0</FieldValue>
            <FieldType>Bool</FieldType>
        </FieldInformation>
        <FieldInformation>
            <CategoryName>Crosshair</CategoryName>
            <FieldName>Use Custom</FieldName>
            <FieldValue>0</FieldValue>
            <FieldType>Bool</FieldType>
            <Hint>Place P1.png into TC5\Binaries\Win64</Hint>
        </FieldInformation>
        <FieldInformation>
            <CategoryName>Border</CategoryName>
            <FieldName>Enable</FieldName>
            <FieldValue>0</FieldValue>
            <FieldType>Bool</FieldType>
            <Hint>Place Border.png into TC5\Binaries\Win64</Hint>
        </FieldInformation>
        <FieldInformation>
            <CategoryName>Border</CategoryName>
            <FieldName>Scale</FieldName>
            <FieldValue>0</FieldValue>
            <FieldType>Bool</FieldType>
            <Hint>Scale image to resolution</Hint>
        </FieldInformation>
        <FieldInformation>
            <CategoryName>General</CategoryName>
            <FieldName>Render Hook</FieldName>
            <FieldValue>Present</FieldValue>
            <FieldType>Dropdown</FieldType>
            <FieldOptions>
                <string>EndScene</string>
                <string>Present</string>
            </FieldOptions>
        </FieldInformation>
        <FieldInformation>
            <CategoryName>General</CategoryName>
            <FieldName>Windowed</FieldName>
            <FieldValue>0</FieldValue>
            <FieldType>Bool</FieldType>
        </FieldInformation>
        <FieldInformation>
            <CategoryName>General</CategoryName>
            <FieldName>Player 2</FieldName>
            <FieldValue>0</FieldValue>
            <FieldType>Bool</FieldType>
        </FieldInformation>
        <FieldInformation>
            <CategoryName>General</CategoryName>
            <FieldName>Use Relative Input</FieldName>
            <FieldValue>0</FieldValue>
            <FieldType>Bool</FieldType>
        </FieldInformation>
        <FieldInformation>
            <CategoryName>General</CategoryName>
            <FieldName>Player 1 Relative Sensitivity</FieldName>
            <FieldValue>8</FieldValue>
            <FieldType>Slider</FieldType>
            <FieldMin>1</FieldMin>
            <FieldMax>50</FieldMax>
            <FieldOptions></FieldOptions>
        </FieldInformation>
        <FieldInformation>
            <CategoryName>General</CategoryName>
            <FieldName>Player 2 Relative Sensitivity</FieldName>
            <FieldValue>8</FieldValue>
            <FieldType>Slider</FieldType>
            <FieldMin>1</FieldMin>
            <FieldMax>50</FieldMax>
            <FieldOptions></FieldOptions>
        </FieldInformation>
        <FieldInformation>
            <CategoryName>Arguments</CategoryName>
            <FieldName>Text Language</FieldName>
            <FieldValue>English</FieldValue>
            <FieldType>Dropdown</FieldType>
            <FieldOptions>
                <string>English</string>
                <string>Spanish</string>
                <string>Portuguese</string>
                <string>Russian</string>
                <string>Thai</string>
                <string>Korean</string>
                <string>Italian</string>
                <string>Indonesian</string>
            </FieldOptions>
        </FieldInformation>
        <FieldInformation>
            <CategoryName>Arguments</CategoryName>
            <FieldName>Voice Language</FieldName>
            <FieldValue>English</FieldValue>
            <FieldType>Dropdown</FieldType>
            <FieldOptions>
                <string>English</string>
                <string>Japanese</string>
            </FieldOptions>
        </FieldInformation>
        <FieldInformation>
            <CategoryName>Arguments</CategoryName>
            <FieldName>Custom Arguments</FieldName>
            <FieldValue></FieldValue>
            <FieldType>Text</FieldType>
        </FieldInformation>
        <FieldInformation>
            <CategoryName>Score</CategoryName>
            <FieldName>Enable Submission</FieldName>
            <FieldValue>0</FieldValue>
            <FieldType>Bool</FieldType>
            <FieldOptions></FieldOptions>
        </FieldInformation>
        <FieldInformation>
            <CategoryName>Score</CategoryName>
            <FieldName>Enable GUI</FieldName>
            <FieldValue>0</FieldValue>
            <FieldType>Bool</FieldType>
            <FieldOptions></FieldOptions>
        </FieldInformation>
        <FieldInformation>
            <CategoryName>Score</CategoryName>
            <FieldName>Enable Capture</FieldName>
            <FieldValue>0</FieldValue>
            <FieldType>Bool</FieldType>
            <FieldOptions></FieldOptions>
        </FieldInformation>
    </ConfigValues>
    <JoystickButtons>
        <JoystickButtons>
            <ButtonName>Coin</ButtonName>
            <InputMapping>Coin1</InputMapping>
        </JoystickButtons>
        <JoystickButtons>
            <ButtonName>Test</ButtonName>
            <InputMapping>Test</InputMapping>
        </JoystickButtons>
        <JoystickButtons>
            <ButtonName>Service Sw</ButtonName>
            <InputMapping>Service1</InputMapping>
        </JoystickButtons>
        <JoystickButtons>
            <ButtonName>Gun Trigger</ButtonName>
            <InputMapping>P1Button1</InputMapping>
        </JoystickButtons>
        <JoystickButtons>
            <ButtonName>Gun Button</ButtonName>
            <InputMapping>P1Button2</InputMapping>
        </JoystickButtons>
        <JoystickButtons>
            <ButtonName>Left Pedal</ButtonName>
            <InputMapping>P1Button3</InputMapping>
        </JoystickButtons>
        <JoystickButtons>
            <ButtonName>Right Pedal</ButtonName>
            <InputMapping>P1Button4</InputMapping>
        </JoystickButtons>
        <JoystickButtons>
            <ButtonName>Up Select Sw</ButtonName>
            <InputMapping>P2Button1</InputMapping>
        </JoystickButtons>
        <JoystickButtons>
            <ButtonName>Down Select Sw</ButtonName>
            <InputMapping>P2Button2</InputMapping>
        </JoystickButtons>
        <JoystickButtons>
            <ButtonName>Enter Sw</ButtonName>
            <InputMapping>P2Button3</InputMapping>
        </JoystickButtons>
        <JoystickButtons>
            <ButtonName>Player 1 Gun X</ButtonName>
            <InputMapping>Analog0</InputMapping>
            <AnalogType>AnalogJoystick</AnalogType>
            <HideWithRawInput>true</HideWithRawInput>
            <HideWithRelativeAxis>true</HideWithRelativeAxis>
        </JoystickButtons>
        <JoystickButtons>
            <ButtonName>Player 1 Gun Y</ButtonName>
            <InputMapping>Analog2</InputMapping>
            <AnalogType>AnalogJoystickReverse</AnalogType>
            <HideWithRawInput>true</HideWithRawInput>
            <HideWithRelativeAxis>true</HideWithRelativeAxis>
        </JoystickButtons>
        <JoystickButtons>
            <ButtonName>Player 1 Light Gun</ButtonName>
            <InputMapping>P1LightGun</InputMapping>
            <HideWithDirectInput>true</HideWithDirectInput>
            <HideWithXInput>true</HideWithXInput>
        </JoystickButtons>
        <JoystickButtons>
            <ButtonName>Player 1 Gun Y Up</ButtonName>
            <InputMapping>P1RelativeUp</InputMapping>
            <HideWithoutRelativeAxis>true</HideWithoutRelativeAxis>
            <HideWithRawInput>true</HideWithRawInput>
        </JoystickButtons>
        <JoystickButtons>
            <ButtonName>Player 1 Gun Y Down</ButtonName>
            <InputMapping>P1RelativeDown</InputMapping>
            <HideWithoutRelativeAxis>true</HideWithoutRelativeAxis>
            <HideWithRawInput>true</HideWithRawInput>
        </JoystickButtons>
        <JoystickButtons>
            <ButtonName>Player 1 Gun X Left</ButtonName>
            <InputMapping>P1RelativeLeft</InputMapping>
            <HideWithoutRelativeAxis>true</HideWithoutRelativeAxis>
            <HideWithRawInput>true</HideWithRawInput>
        </JoystickButtons>
        <JoystickButtons>
            <ButtonName>Player 1 Gun X Right</ButtonName>
            <InputMapping>P1RelativeRight</InputMapping>
            <HideWithoutRelativeAxis>true</HideWithoutRelativeAxis>
            <HideWithRawInput>true</HideWithRawInput>
        </JoystickButtons>
    </JoystickButtons>
</GameProfile>'


                // Define the XML Parser Model
                XmlListModel {
                    id: xmlModel
                    source: "file://usr/bin/teknoparrot/GameProfiles/TC5.xml"
                    //xml:     contentColumn.xmlDataTC5
                    query: "/GameProfile/ConfigValues/FieldInformation"

                    // Map the XML tags to model roles
                    XmlRole { name: "category"; query: "CategoryName/string()" }
                    XmlRole { name: "name"; query: "FieldName/string()" }
                    XmlRole { name: "value"; query: "FieldValue/string()" }
                    XmlRole { name: "type"; query: "FieldType/string()" }
                }

                Repeater {
                    id: gameOptions
                    model: xmlModel
                    property int selectedButtonIndex : 0

                    delegate: Item {
                        id: rowContainer
                        width: parent.width
                        visible: true
                        height: visible ? (showSection ? (sectionHeader.height + toggleItem.height) : toggleItem.height) : 0

                        property bool showSection: {
                            if (index === 0) return true;
                            var prev = xmlModel.get(index - 1);
                            return prev ? (prev.category !== model.category) : false;
                        }

                        // Expose le bouton interne pour que les lignes voisines puissent le cibler
                        //property alias targetItem: toggleItem

                        SectionTitle {
                            id: sectionHeader
                            width: parent.width
                            text: qsTr(model.category) + api.tr
                            first: index === 0
                            //symbol: "\uf11c"
                            visible: rowContainer.showSection
                            height: visible ? implicitHeight : 0
                            anchors.top: parent.top
                        }

                        MultivalueOption {
                            id: multivalueItem
                            width: parent.width
                            anchors.top: sectionHeader.bottom

                            //property to manage parameter name
                            property string parameterName: prefix + "." + model.category.toLowerCase() + "." + model.name.toLowerCase()

                            visible: model.type === "Dropdown"

                            focus:{
                                if (index === gameOptions.selectedButtonIndex){
                                    if(visible){
                                        return true;
                                    }
                                }
                                return false;
                            }

                            label: qsTr(model.category) + " - " + qsTr(model.name) + api.tr
                            note: "for debug - index : " + index.toString()

                            value: api.internal.recalbox.parameterslist.currentName(parameterName)
                            internalvalue: api.internal.recalbox.audioDevice

                            currentIndex: api.internal.recalbox.parameterslist.currentIndex;
                            count: api.internal.recalbox.parameterslist.count;

                            font: globalFonts.awesome

                            onInternalvalueChanged: {
                                value = api.internal.recalbox.parameterslist.currentName(parameterName, internalvalue);
                                //console.log("value = ", value);
                                count = api.internal.recalbox.parameterslist.count;
                                //console.log("count = ", count);
                                currentIndex = api.internal.recalbox.parameterslist.currentIndex;
                                //console.log("currentIndex = ", currentIndex);unt);
                            }

                            onActivate: {
                                //for callback by parameterslistBox
                                parameterslistBox.parameterName = parameterName;
                                parameterslistBox.callerid = multivalueItem;
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
                            }

                            onFocusChanged:{
                                if(focus){
                                    api.internal.recalbox.parameterslist.currentName(parameterName);
                                    currentIndex = api.internal.recalbox.parameterslist.currentIndex;
                                    count = api.internal.recalbox.parameterslist.count;
                                }
                                container.onFocus(this)
                            }
                        }

                        ToggleOption {
                            id: toggleItem
                            width: parent.width
                            anchors.top: sectionHeader.bottom

                            visible: model.type === "Bool"

                            focus:{
                                if (index === gameOptions.selectedButtonIndex){
                                    if(visible){
                                        return true;
                                    }
                                }
                                return false;
                            }

                            label: qsTr(model.category) + " - " + qsTr(model.name) + api.tr
                            note: "for debug - index : " + index.toString()

                            property string configKey: prefix + "." + model.category.toLowerCase() + "." + model.name.toLowerCase()
                            property bool defaultVal: (model.value === "1" || model.value === "true")
                            checked: api.internal.recalbox.getBoolParameter(configKey, defaultVal)

                            onFocusChanged:{
                                container.onFocus(this);
                            }
                        }

                        SliderOption {
                            id: sliderItem
                            width: parent.width
                            anchors.top: sectionHeader.bottom

                            //property to manage parameter name
                            property string parameterName: prefix + "." + model.category.toLowerCase() + "." + model.name.toLowerCase()

                            visible: model.type === "Slider"

                            focus:{
                                if (index === gameOptions.selectedButtonIndex){
                                    if(visible){
                                        return true;
                                    }
                                }
                                return false;
                            }

                            label: qsTr(model.category) + " - " + qsTr(model.name) + api.tr
                            note: "for debug - index : " + index.toString()

                            // in slider object
                            max : 100
                            min : 0
                            slidervalue : api.internal.recalbox.getIntParameter(parameterName)
                            // in text object
                            value: api.internal.recalbox.getIntParameter(parameterName) + "%"

                            onActivate: {
                                focus = true;
                            }

                            Keys.onLeftPressed: {
                                api.internal.recalbox.setIntParameter(parameterName,slidervalue);
                                value = slidervalue + "%";
                            }

                            Keys.onRightPressed: {
                                api.internal.recalbox.setIntParameter(parameterName,slidervalue);
                                value = slidervalue + "%";
                            }

                            onFocusChanged: container.onFocus(this)
                        }

                        SimpleButton {
                            id: textItem
                            width: parent.width
                            anchors.top: sectionHeader.bottom

                            //property to manage parameter name
                            property string parameterName: prefix + "." + model.category.toLowerCase() + "." + model.name.toLowerCase()

                            visible: model.type === "Text"

                            focus:{
                                if (index === gameOptions.selectedButtonIndex){
                                    if(visible){
                                        return true;
                                  }
                                }
                                return false;
                            }

                            label: qsTr(model.category) + " - " + qsTr(model.name) + api.tr
                            note: "for debug - index : " + index.toString()

                            TextFieldOption {
                                id: textFieldItem
                                anchors.right: parent.right
                                anchors.verticalCenter: parent.verticalCenter
                                horizontalAlignment: TextInput.AlignRight
                                placeholderText: "                       "
                                text: api.internal.recalbox.getStringParameter(parent.parameterName)
                                echoMode: TextInput.Normal
                                inputMethodHints: Qt.ImhNoPredictiveText
                                onEditingFinished: api.internal.recalbox.setStringParameter(parent.parameterName, textFieldItem.text)
                            }
                            onFocusChanged: container.onFocus(this)
                        }

                        onFocusChanged: {
                            if (focus) {
                                // On signale le focus à l'API Recalbox si nécessaire
                                container.onFocus(this);
                            }
                        }

                        Keys.onPressed: {
                            //verify if finally other lists are empty or not when we are just before to change list
                            //it's a tip to refresh the KeyNavigations value just before to change from one list to an other
                            //console.log("index before: ",index)
                            if ((event.key === Qt.Key_Up) && !event.isAutoRepeat) {
                                if (index !== 0) {
                                    KeyNavigation.up = gameOptions.itemAt(index-1);
                                    gameOptions.selectedButtonIndex = index-1;
                                }
                                else {
                                    KeyNavigation.up = gameOptions.itemAt(0)
                                    gameOptions.selectedButtonIndex = 0;
                                }
                                event.accepted = true;
                            }
                            else if ((event.key === Qt.Key_Down) && !event.isAutoRepeat) {
                                if (index < gameOptions.count-1){
                                    KeyNavigation.down = gameOptions.itemAt(index+1);
                                    gameOptions.selectedButtonIndex = index+1;
                                }
                                else {
                                    KeyNavigation.down = gameOptions.itemAt(gameOptions.count-1);
                                    gameOptions.selectedButtonIndex = gameOptions.count-1;
                                }
                                event.accepted = true;
                            }
                            else{
                                event.accepted = false;
                            }
                            console.log("gameOptions.selectedButtonIndex aftre: ",gameOptions.selectedButtonIndex)

                            // On applique le défilement au Flickable/ScrollView
                            console.log("container.contentY - before: ", container.contentY);
                            var absoluteY = contentColumn.children[index].y;

                            // Ta formule mathématique corrigée pour centrer l'élément
                            var targetY = Math.min(
                                Math.max(0, absoluteY - (container.height * 0.4)),
                                container.contentHeight - container.height
                            );

                            container.contentY = targetY;
                            //console.log("container.contentY - after: ", container.contentY);
                            //container.contentY = Math.min(Math.max(0, y - (height * 0.7)), container.contentHeight - height);
                        }
                    }
                }

                Item {
                    width: parent.width
                    height: launchedAsDialogBox ? implicitHeight + vpx(50) : implicitHeight + vpx(30)
                }
            }
        }
    }

    //loader to load confirm dialog
    Loader {
        id: confirmDialog
        anchors.fill: parent
        z:10
        property string callerid: ""
    }

    MulticheckBox {
        id: parameterscheckBox
        z: 3

        //properties to manage parameter
        property string parameterName
        property string previousValue
        property MulticheckOption callerid

        //reuse same model
        model: api.internal.recalbox.parameterslist.model
        //to use index from parameterlist QAbstractList
        index: api.internal.recalbox.parameterslist.currentIndex
        //to load "checked" status for each indexes
        isChecked: api.internal.recalbox.parameterslist.isChecked()

        onClose: {
            content.focus = true
        }

        onCheck: {
            //console.log("parameterscheckBox::onCheck index : ", index, " checked : ", checked, " callerid.parameterName : ", callerid.parameterName);
            callerid.keypressed = true;
            //to use the good parameter
            api.internal.recalbox.parameterslist.currentNameChecked(callerid.parameterName);
            //to update index of parameterlist QAbstractList
            api.internal.recalbox.parameterslist.currentIndex = index;
            api.internal.recalbox.parameterslist.currentIndexChecked = checked;
            //to force update of display of selected value
            callerid.value = api.internal.recalbox.parameterslist.currentNameChecked(callerid.parameterName);
            callerid.currentIndex = api.internal.recalbox.parameterslist.currentIndex;
            callerid.count = api.internal.recalbox.parameterslist.count;
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
        onClose: content.focus = true
        onSelect: {
            /*console.log(callerid.label," onSelect count : ", callerid.count);
            console.log(callerid.label," onSelect currentindex : ", callerid.currentIndex);
            console.log(callerid.label," onSelect newindex : ", index);
            console.log(callerid.label," onSelect value : ", callerid.value);
            console.log(callerid.label," onSelect internalvalue : ", callerid.internalvalue);*/
            //to use the good parameter

            if(typeof(callerid.command) === "undefined") api.internal.recalbox.parameterslist.currentName(callerid.parameterName);
            else api.internal.recalbox.parameterslist.currentNameFromSystem(callerid.parameterName,callerid.command,callerid.optionsList);

            callerid.keypressed = true;
            //to update index of parameterlist QAbstractList
            api.internal.recalbox.parameterslist.currentIndex = index;
            callerid.count = api.internal.recalbox.parameterslist.count;
            callerid.currentIndex = index;

            //to force update of display of selected value
            if(typeof(callerid.command) === "undefined"){
                callerid.value = api.internal.recalbox.parameterslist.currentName(callerid.parameterName);
                callerid.internalvalue = api.internal.recalbox.parameterslist.currentInternalName(parameterName);
            }
            else {
                callerid.value = api.internal.recalbox.parameterslist.currentNameFromSystem(callerid.parameterName,callerid.command,callerid.optionsList);
            }
        }
    }
    Item {
        id: footer
        width: parent.width
        height: vpx(50)
        anchors.bottom: parent.bottom
        z:2
        visible: launchedAsDialogBox

        //Rectangle for the transparent background
        Rectangle {
            anchors.fill: parent
            color: themeColor.screenHeader
            opacity: 0.75
        }

        //rectangle for the gray line
        Rectangle {
            width: parent.width * 0.97
            height: vpx(1)
            color: "#777"
            anchors.top: parent.top
            anchors.horizontalCenter: parent.horizontalCenter
        }

        //for the help to exit
        Rectangle {
            id: backButtonIcon
            height: labelB.height
            width: height
            radius: width * 0.5
            border { color: "#777"; width: vpx(1) }
            color: "transparent"
            visible: {
                return true;
            }

            anchors {
                right: labelB.left
                verticalCenter: parent.verticalCenter
                verticalCenterOffset: vpx(1)
                margins: vpx(10)
            }
            Text {
                text: "B"
                color: "#777"
                font {
                    family: global.fonts.sans
                    pixelSize: parent.height * 0.7
                }
                anchors.centerIn: parent
            }
        }

        Text {
            id: labelB
            text: qsTr("Back") + api.tr
            verticalAlignment: Text.AlignTop
            visible: {
                return true;
            }

            color: "#777"
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
    }
}
