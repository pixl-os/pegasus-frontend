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
    property string prefix : game ? ("override." + emulator + ".gameconfig") : (emulator + ".gameconfig")
    //to manage better title in screen ScreenHeader (if we want to change it during loading)
    property string titleHeader: game ? game.title +  " > " + emulator + " > " + qsTr("Game configuration") + api.tr :
        (system ? system.name + " > " + emulator + " > " + qsTr("Game configuration") + api.tr :
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

                Item {
                    width: parent.width
                    height: implicitHeight + vpx(30)
                }

                //to let display spinner during loading of gameprofile xml file
                Timer {
                    id: loadingTimer
                    interval: 1 // wait 1s before reading xml file
                    repeat: false
                    running: true
                    triggeredOnStart: false
                    onTriggered: {
                        if(game){
                            var path = game.files.get(0).path; // full path of rom
                            var word = path.split('/'); // to split by /
                            var rom = word[word.length-1].split('.')[0]; // to keep rom name without extension
                            xmlModel.source = "file://usr/bin/teknoparrot/GameProfiles/" + rom + ".xml";
                        }
                    }
                }

                SectionTitle {
                    id: gameProfileLoading
                    text: qsTr("Read TeknoParrot XML Game Profie file...") + api.tr
                    first: false
                    visible: true
                    //Spinner Loader for discovered devices section
                    Loader {
                        id: spinnerloader
                        anchors.left: parent.right
                        anchors.leftMargin: vpx(30)
                        anchors.bottom: parent.bottom
                        anchors.bottomMargin: vpx(30)
                        active: gameProfileLoading.visible
                        sourceComponent: spinner
                    }

                    Component {
                        id: spinner
                        Rectangle{
                            Image {
                                id: imageSpinner
                                source: "../../assets/loading.png"
                                width: vpx(30)
                                height: vpx(30)
                                asynchronous: true
                                sourceSize { width: vpx(50); height: vpx(50) }
                                RotationAnimator on rotation {
                                    loops: Animator.Infinite;
                                    from: 0;
                                    to: 360;
                                    duration: 3000
                                }
                            }
                        }
                    }
                }

                //teknoaprrot xml file content example... with ConfigValues only
                // <?xml version="1.0" encoding="utf-8"?>
                // <GameProfile xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xsd="http://www.w3.org/2001/XMLSchema">
                // ....
                //     <ConfigValues>
                //         <FieldInformation>
                //             <CategoryName>General</CategoryName>
                //             <FieldName>Input API</FieldName>
                //             <FieldValue>RawInput</FieldValue>
                //             <FieldType>Dropdown</FieldType>
                //             <FieldOptions>
                //                 <string>DirectInput</string>
                //                 <string>XInput</string>
                //                 <string>RawInput</string>
                //             </FieldOptions>
                //         </FieldInformation>
                //         <FieldInformation>
                //             <CategoryName>General</CategoryName>
                //             <FieldName>FreePlay</FieldName>
                //             <FieldValue>0</FieldValue>
                //             <FieldType>Bool</FieldType>
                //         </FieldInformation>
                //         <FieldInformation>
                //             <CategoryName>Crosshair</CategoryName>
                //             <FieldName>Enable</FieldName>
                //             <FieldValue>0</FieldValue>
                //             <FieldType>Bool</FieldType>
                //         </FieldInformation>
                //         <FieldInformation>
                //             <CategoryName>Crosshair</CategoryName>
                //             <FieldName>Use Custom</FieldName>
                //             <FieldValue>0</FieldValue>
                //             <FieldType>Bool</FieldType>
                //             <Hint>Place P1.png into TC5\Binaries\Win64</Hint>
                //         </FieldInformation>
                //         <FieldInformation>
                //             <CategoryName>Border</CategoryName>
                //             <FieldName>Enable</FieldName>
                //             <FieldValue>0</FieldValue>
                //             <FieldType>Bool</FieldType>
                //             <Hint>Place Border.png into TC5\Binaries\Win64</Hint>
                //         </FieldInformation>
                //         <FieldInformation>
                //             <CategoryName>Border</CategoryName>
                //             <FieldName>Scale</FieldName>
                //             <FieldValue>0</FieldValue>
                //             <FieldType>Bool</FieldType>
                //             <Hint>Scale image to resolution</Hint>
                //         </FieldInformation>
                //         <FieldInformation>
                //             <CategoryName>General</CategoryName>
                //             <FieldName>Render Hook</FieldName>
                //             <FieldValue>Present</FieldValue>
                //             <FieldType>Dropdown</FieldType>
                //             <FieldOptions>
                //                 <string>EndScene</string>
                //                 <string>Present</string>
                //             </FieldOptions>
                //         </FieldInformation>
                //         <FieldInformation>
                //             <CategoryName>General</CategoryName>
                //             <FieldName>Windowed</FieldName>
                //             <FieldValue>0</FieldValue>
                //             <FieldType>Bool</FieldType>
                //         </FieldInformation>
                //         <FieldInformation>
                //             <CategoryName>General</CategoryName>
                //             <FieldName>Player 2</FieldName>
                //             <FieldValue>0</FieldValue>
                //             <FieldType>Bool</FieldType>
                //         </FieldInformation>
                //         <FieldInformation>
                //             <CategoryName>General</CategoryName>
                //             <FieldName>Use Relative Input</FieldName>
                //             <FieldValue>0</FieldValue>
                //             <FieldType>Bool</FieldType>
                //         </FieldInformation>
                //         <FieldInformation>
                //             <CategoryName>General</CategoryName>
                //             <FieldName>Player 1 Relative Sensitivity</FieldName>
                //             <FieldValue>8</FieldValue>
                //             <FieldType>Slider</FieldType>
                //             <FieldMin>1</FieldMin>
                //             <FieldMax>50</FieldMax>
                //             <FieldOptions></FieldOptions>
                //         </FieldInformation>
                //         <FieldInformation>
                //             <CategoryName>General</CategoryName>
                //             <FieldName>Player 2 Relative Sensitivity</FieldName>
                //             <FieldValue>8</FieldValue>
                //             <FieldType>Slider</FieldType>
                //             <FieldMin>1</FieldMin>
                //             <FieldMax>50</FieldMax>
                //             <FieldOptions></FieldOptions>
                //         </FieldInformation>
                //         <FieldInformation>
                //             <CategoryName>Arguments</CategoryName>
                //             <FieldName>Text Language</FieldName>
                //             <FieldValue>English</FieldValue>
                //             <FieldType>Dropdown</FieldType>
                //             <FieldOptions>
                //                 <string>English</string>
                //                 <string>Spanish</string>
                //                 <string>Portuguese</string>
                //                 <string>Russian</string>
                //                 <string>Thai</string>
                //                 <string>Korean</string>
                //                 <string>Italian</string>
                //                 <string>Indonesian</string>
                //             </FieldOptions>
                //         </FieldInformation>
                //         <FieldInformation>
                //             <CategoryName>Arguments</CategoryName>
                //             <FieldName>Voice Language</FieldName>
                //             <FieldValue>English</FieldValue>
                //             <FieldType>Dropdown</FieldType>
                //             <FieldOptions>
                //                 <string>English</string>
                //                 <string>Japanese</string>
                //             </FieldOptions>
                //         </FieldInformation>
                //         <FieldInformation>
                //             <CategoryName>Arguments</CategoryName>
                //             <FieldName>Custom Arguments</FieldName>
                //             <FieldValue></FieldValue>
                //             <FieldType>Text</FieldType>
                //         </FieldInformation>
                //         <FieldInformation>
                //             <CategoryName>Score</CategoryName>
                //             <FieldName>Enable Submission</FieldName>
                //             <FieldValue>0</FieldValue>
                //             <FieldType>Bool</FieldType>
                //             <FieldOptions></FieldOptions>
                //         </FieldInformation>
                //         <FieldInformation>
                //             <CategoryName>Score</CategoryName>
                //             <FieldName>Enable GUI</FieldName>
                //             <FieldValue>0</FieldValue>
                //             <FieldType>Bool</FieldType>
                //             <FieldOptions></FieldOptions>
                //         </FieldInformation>
                //         <FieldInformation>
                //             <CategoryName>Score</CategoryName>
                //             <FieldName>Enable Capture</FieldName>
                //             <FieldValue>0</FieldValue>
                //             <FieldType>Bool</FieldType>
                //             <FieldOptions></FieldOptions>
                //         </FieldInformation>
                //     </ConfigValues>
                // </GameProfile>'

                // Define the XML Parser Model
                XmlListModel {
                    id: xmlModel
                    source: ""
                    query: "/GameProfile/ConfigValues/FieldInformation"

                    // Map the XML tags to model roles
                    XmlRole { name: "category"; query: "CategoryName/string()" }
                    XmlRole { name: "name"; query: "FieldName/string()" }
                    XmlRole { name: "value"; query: "FieldValue/string()" }
                    XmlRole { name: "min"; query: "FieldMin/string()"}
                    XmlRole { name: "max"; query: "FieldMax/string()"}
                    XmlRole { name: "type"; query: "FieldType/string()" }
                    XmlRole { name: "hint"; query: "Hint/string()" }
                    // Fetch the raw concatenated string content of all child <string> tags inside FieldOptions
                    XmlRole { name: "optionsRaw"; query: "FieldOptions/string()" }

                    // 1. Storage for our final sorted data
                    property var sortedConfigData: []

                    // Triggered automatically when the XML data is fully loaded
                    onCountChanged: {
                        if (count > 0 && count === xmlModel.count) {
                            var tempArray = [];

                            // Step 1: Extract all items into a plain JavaScript array
                            for (var i = 0; i < count; i++) {
                                var currentItem = get(i);
                                // FIX: Create a real dynamic ListModel instance for this specific item's options
                                var optionsModel = Qt.createQmlObject('import QtQuick 2.0; ListModel {}', xmlModel);

                                // Parse the raw FieldOptions string if it exists
                                if (currentItem.optionsRaw) {
                                    var rawTokens = currentItem.optionsRaw.split(/\s+/).filter(function(token) {
                                        return token.length > 0;
                                    });

                                    // Append each option as an object into our dynamic options ListModel
                                    for (var k = 0; k < rawTokens.length; k++) {
                                        var cleanedOption = rawTokens[k].replace(/ /g, "_");
                                        optionsModel.append({ "name": cleanedOption });
                                    }
                                }

                                tempArray.push({
                                    "category": currentItem.category,
                                    "name": currentItem.name,
                                    "value": currentItem.value,
                                    "min": currentItem.min,
                                    "max": currentItem.max,
                                    "type": currentItem.type,
                                    "hint": currentItem.hint,
                                    "options": optionsModel // Now a true ListModel component!
                                });
                            }

                            // Step 2: Multi-level Sort (Category first, then Name)
                            tempArray.sort(function(a, b) {
                                var catA = a.category.toLowerCase();
                                var catB = b.category.toLowerCase();

                                // 1st Level: Handle "general" priority
                                if (catA === "general" && catB !== "general") return -1;
                                if (catB === "general" && catA !== "general") return 1;

                                // 2nd Level: Compare categories alphabetically
                                var catCompare = catA.localeCompare(catB);

                                // 3rd Level: If categories are identical, sort by name alphabetically
                                if (catCompare === 0) {
                                    var nameA = a.name.toLowerCase();
                                    var nameB = b.name.toLowerCase();
                                    return nameA.localeCompare(nameB);
                                }

                                return catCompare;
                            });

                            // Step 3: Assign the beautifully sorted array to our local property
                            xmlModel.sortedConfigData = tempArray;
                        }
                    }
                }

                Repeater {
                    id: gameOptions
                    model: xmlModel.sortedConfigData
                    property int selectedButtonIndex : 0

                    delegate: Item {
                        id: rowContainer
                        width: parent.width
                        visible: true
                        height: visible ? (showSection ? (sectionHeader.height + toggleItem.height) : toggleItem.height) : 0

                        property bool showSection: {
                            if (index === 0) return true;
                            var prev = xmlModel.sortedConfigData[index - 1];
                            return prev ? (prev.category !== modelData.category) : false;
                        }

                        SectionTitle {
                            id: sectionHeader
                            width: parent.width
                            text: qsTr(modelData.category) + api.tr
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

                            visible: modelData.type === "Dropdown"

                            //property to manage parameter name
                            property string parameterName: prefix + "." + modelData.category.toLowerCase() + "." + modelData.name.toLowerCase().replace(/ /g, "_");


                            focus:{
                                if (index === gameOptions.selectedButtonIndex){
                                    if(visible){
                                        return true;
                                    }
                                }
                                return false;
                            }

                            label: qsTr(modelData.name) + api.tr
                            note: modelData.hint ? modelData.hint : null

                            value: visible ? api.internal.recalbox.getStringParameter(parameterName, modelData.value) : ""

                            currentIndex:{
                                if(visible){
                                    for(var i=0; i < modelData.options.count; i++){
                                        //console.log("MultivalueOption currentIndex : ",i);
                                        //console.log("modelData.options.get(i).name : ",modelData.options.get(i).name);
                                        //console.log("modelData.value : ",value);
                                        if(modelData.options.get(i).name === value) return i;
                                    }
                                    return 0;
                                }
                                return 0;
                            }
                            count: visible ? modelData.options.count : 0

                            font: globalFonts.awesome

                            onValueChanged: {
                                if(visible){
                                    api.internal.recalbox.setStringParameter(parameterName, value)
                                }
                            }

                            onActivate: {
                                if(visible){
                                    //for callback by parameterslistBox
                                    parameterslistBox.parameterName = parameterName;
                                    parameterslistBox.callerid = multivalueItem;
                                    //to force update of list of parameters
                                    parameterslistBox.model = modelData.options;
                                    parameterslistBox.index = currentIndex;
                                    //to transfer focus to parameterslistBox
                                    parameterslistBox.focus = true;
                                }
                            }

                            onSelect: {
                                if(visible){
                                    value = modelData.options.get(index).name;
                                }
                            }

                            onFocusChanged:{
                                container.onFocus(this)
                            }
                        }

                        ToggleOption {
                            id: toggleItem
                            width: parent.width
                            anchors.top: sectionHeader.bottom

                            visible: modelData.type === "Bool"
                            //property to manage parameter name
                            property string parameterName: prefix + "." + modelData.category.toLowerCase() + "." + modelData.name.toLowerCase().replace(/ /g, "_")

                            focus:{
                                if (index === gameOptions.selectedButtonIndex){
                                    if(visible){
                                        return true;
                                    }
                                }
                                return false;
                            }

                            label: qsTr(modelData.name) + api.tr
                            note: modelData.hint ? modelData.hint : null

                            property bool defaultVal: (modelData.value === "1" || modelData.value === "true")
                            checked: visible ? api.internal.recalbox.getBoolParameter(parameterName, defaultVal) : false
                            onCheckedChanged: {
                                if(visible){
                                    api.internal.recalbox.setBoolParameter(parameterName,checked);
                                }
                            }

                            onFocusChanged: container.onFocus(this)
                        }

                        SliderOption {
                            id: sliderItem
                            width: parent.width
                            anchors.top: sectionHeader.bottom

                            //property to manage parameter name
                            property string parameterName: prefix + "." + modelData.category.toLowerCase() + "." + modelData.name.toLowerCase().replace(/ /g, "_")

                            visible: modelData.type === "Slider"

                            focus:{
                                if (index === gameOptions.selectedButtonIndex){
                                    if(visible){
                                        return true;
                                    }
                                }
                                return false;
                            }

                            label: qsTr(modelData.name) + api.tr
                            note: modelData.hint ? modelData.hint : null

                            // in slider object
                            max : visible ? parseFloat(modelData.max) : 0
                            min : visible ? parseFloat(modelData.min) : 0
                            slidervalue : visible ? api.internal.recalbox.getIntParameter(parameterName, modelData.value) : min
                            // in text object
                            value: visible ? api.internal.recalbox.getIntParameter(parameterName, modelData.value) : 0

                            onActivate: {
                                focus = true;
                            }

                            Keys.onLeftPressed: {
                                if(visible){
                                    api.internal.recalbox.setIntParameter(parameterName,slidervalue);
                                    value = slidervalue;
                                }
                            }

                            Keys.onRightPressed: {
                                if(visible){
                                    api.internal.recalbox.setIntParameter(parameterName,slidervalue);
                                    value = slidervalue;
                                }
                            }

                            onFocusChanged: container.onFocus(this)
                        }

                        SimpleButton {
                            id: textItem
                            width: parent.width
                            anchors.top: sectionHeader.bottom

                            //property to manage parameter name
                            property string parameterName: prefix + "." + modelData.category.toLowerCase() + "." + modelData.name.toLowerCase().replace(/ /g, "_")

                            visible: modelData.type === "Text"

                            focus:{
                                if (index === gameOptions.selectedButtonIndex){
                                    if(visible){
                                        return true;
                                  }
                                }
                                return false;
                            }

                            label: qsTr(modelData.name) + api.tr
                            note: modelData.hint ? modelData.hint : null

                            TextFieldOption {
                                id: textFieldItem
                                anchors.right: parent.right
                                anchors.verticalCenter: parent.verticalCenter
                                horizontalAlignment: TextInput.AlignRight
                                placeholderText: "                       "
                                text: visible ? api.internal.recalbox.getStringParameter(parent.parameterName, modelData.value) : ""
                                echoMode: TextInput.Normal
                                inputMethodHints: Qt.ImhNoPredictiveText
                                onEditingFinished: {
                                    if(visible) api.internal.recalbox.setStringParameter(parent.parameterName, textFieldItem.text);
                                }
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
                            //console.log("index before: ",index)
                            if (event.key === Qt.Key_Up) {
                                if (index !== 0) {
                                    gameOptions.selectedButtonIndex = index-1;
                                }
                                else {
                                    gameOptions.selectedButtonIndex = 0;
                                }
                                event.accepted = true;
                            }
                            else if (event.key === Qt.Key_Down) {
                                if (index < gameOptions.count-1) {
                                    gameOptions.selectedButtonIndex = index+1;
                                }
                                else {
                                    gameOptions.selectedButtonIndex = gameOptions.count-1;
                                }
                                event.accepted = true;
                            }
                            else {
                                event.accepted = false;
                            }
                            //console.log("gameOptions.selectedButtonIndex after: ",gameOptions.selectedButtonIndex)

                            // On applique le défilement au Flickable/ScrollView
                            //console.log("container.contentY - before: ", container.contentY);
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

                    onCountChanged: {
                        if (count > 0 && count === xmlModel.count) {
                            Qt.callLater(function() {
                                gameProfileLoading.visible = false;
                            });
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

    MultivalueBox {
        id: parameterslistBox
        z: 3

        //properties to manage parameter
        property string parameterName
        property MultivalueOption callerid

        //to use index from parameterlist QAbstractList
        //index: callerid.currentIndex
        //reuse same model
        //model: callerid.modelData.options
        onClose: content.focus = true
        onSelect: {
            callerid.keypressed = true;
            callerid.currentIndex = index;
            callerid.value = model.get(index).name;
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
