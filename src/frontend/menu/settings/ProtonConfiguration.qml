// Pegasus Frontend
//
// Created by BozoTheGeek 01/08/2025
//

import "common"
import "qrc:/qmlutils" as PegasusUtils
import QtQuick 2.12
import QtQuick.Controls 2.12
import QtQuick.Window 2.12

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
    property string titleHeader: game ? game.title +  " > " + qsTr("Proton configuration") + api.tr :
        (system ? system.name + " > " + qsTr("Proton configuration") + api.tr :
         emulator + " > " + qsTr("Proton configuration") + api.tr)
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

        Behavior on contentY { PropertyAnimation { duration: 100 } }
        boundsBehavior: Flickable.StopAtBounds
        boundsMovement: Flickable.StopAtBounds

        readonly property int yBreakpoint: height * 0.7
        readonly property int maxContentY: contentHeight - height

        function onFocus(item) {
            if (item.focus)
                contentY = Math.min(Math.max(0, item.y - yBreakpoint), maxContentY);
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

                // Inside your delegate or item that needs to check visibility
                function checkVisibility(item) {
                    // Map the item's local coordinates to the Flickable's content coordinates
                    // This gives you the item's rectangle relative to the Flickable's content.
                    var itemXInContent = mapToItem(container.contentItem, 0, 0).x;
                    var itemYInContent = mapToItem(container.contentItem, 0, 0).y;

                    // Define the item's rectangle in the Flickable's content coordinate system
                    var itemRectInContent = Qt.rect(itemXInContent, itemYInContent, item.width, item.height);

                    // Define the Flickable's visible rectangle (its viewport)
                    // This is relative to contentX and contentY, so it's (0,0, width, height) of the visible area
                    // Adjust flickableRect to be in the content's coordinate system, shifted by contentX/contentY
                    var flickableVisibleRect = Qt.rect(container.contentX, container.contentY, container.width, container.height);

                    // Now, perform the intersection check manually or using helper functions if available.
                    // The `intersects` property/method on QRectF is for C++ API.
                    // For pure QML `Qt.rect`, you usually define an intersection logic like this:

                    var intersects =
                        itemRectInContent.x < flickableVisibleRect.x + flickableVisibleRect.width &&
                        itemRectInContent.x + itemRectInContent.width > flickableVisibleRect.x &&
                        itemRectInContent.y < flickableVisibleRect.y + flickableVisibleRect.height &&
                        itemRectInContent.y + itemRectInContent.height > flickableVisibleRect.y;

                    var visibleInFlickable = intersects;
                    if((item.visibleInFlickable !== visibleInFlickable) &&  (visibleInFlickable === true)){
                        item.value = api.internal.recalbox.parameterslist.currentName(item.parameterName);
                        item.internalvalue = api.internal.recalbox.parameterslist.currentInternalName(item.parameterName);
                        item.currentIndex = api.internal.recalbox.parameterslist.currentIndex;
                        item.count = api.internal.recalbox.parameterslist.count;
                    }
                    item.visibleInFlickable = visibleInFlickable;
                }
                //put from here options
                //****************************** section to manage wine version of this emulator*****************************************
                SectionTitle {
                    text: qsTr("Proton 'Bottle' configuration") + api.tr
                    first: true
                    symbol: "\uf2f2"
                    symbolFontFamily: globalFonts.ion
                }
                MultivalueOption {
                    id: optProtonbottle

                    //property to manage parameter name
                    property string parameterName : prefix + ".protonbottle"

                    // set focus only on first item
                    focus: true

                    label: qsTr("Proton 'bottle' to use") + api.tr
                    note: qsTr("Select existing one or 'New bottle' to create one") + api.tr

                    value: api.internal.recalbox.parameterslist.currentName(parameterName)
                    internalvalue: api.internal.recalbox.parameterslist.currentInternalName(parameterName)
                    currentIndex: api.internal.recalbox.parameterslist.currentIndex
                    count: api.internal.recalbox.parameterslist.count

                    onActivate: {
                        //for callback by parameterslistBox
                        parameterslistBox.parameterName = parameterName;
                        parameterslistBox.callerid = optProtonbottle;
                        //to force update of list of parameters
                        api.internal.recalbox.parameterslist.currentName(parameterName);
                        parameterslistBox.model = api.internal.recalbox.parameterslist;
                        parameterslistBox.index = api.internal.recalbox.parameterslist.currentIndex;
                        //to transfer focus to parameterslistBox
                        parameterslistBox.focus = true;
                    }

                    onInternalvalueChanged: {
                        console.log("onSelect - internalvalue: '", internalvalue, "'");
                        if(internalvalue !== ""){
                            wineInfoTimer.triggeredOnStart = true;
                            wineInfoTimer.start();
                        }
                        else{
                            //reset color
                            optProtonbottle.color = themeColor.textValue;
                        }
                    }

                    onSelect: {
                        //to force to be on the good parameter selected
                        api.internal.recalbox.parameterslist.currentName(parameterName);
                        //to update index of parameterlist QAbstractList
                        api.internal.recalbox.parameterslist.currentIndex = index;
                        //to force update of display of selected value
                        value = api.internal.recalbox.parameterslist.currentName(parameterName);
                        internalvalue = api.internal.recalbox.parameterslist.currentInternalName(parameterName);
                    }

                    onFocusChanged:{
                        if(focus){
                            api.internal.recalbox.parameterslist.currentName(parameterName);
                            currentIndex = api.internal.recalbox.parameterslist.currentIndex;
                            count = api.internal.recalbox.parameterslist.count;
                        }
                        container.onFocus(this)
                    }
                    KeyNavigation.down: btnCleanSelectedBottle
                }

                //to display info on selected wine bottle
                SimpleButton {
                    id: optBottleInfo
                    visible: optProtonbottle.internalvalue !== "" ? true : false
                    width: parseInt(parent.width/6)*5
                    showUnderline: false
                    wrapMode: Text.NoWrap
                    launchedAsDialogBox: root.launchedAsDialogBox
                    property string bottle_name: "" //optProtonbottle.internalvalue.split('/').pop()
                    property string bottle_path: "" //optProtonbottle.internalvalue
                    property string bottle_size : ""
                    property string bottle_engine : "" //bottle_name.replace(/^\.[^_]*_/, "").split("__")[0];
                    property string bottle_appimage : ""
                    property string bottle_arch : "" //win32/win64/wow64
                    property string bottle_winver : "" //win95 to win11
                    property string bottle_env : ""

                    labelFormat: Text.RichText
                    label: "<u>" + qsTr("Information about selected bottle:") + "</u>"
                    // Set the format to RichText
                    noteFormat: Text.RichText
                    note:  "<i>" + qsTr("Size") + "</i>: " + api.tr + "<b>" + bottle_size + "</b>" + "<br>" +
                           ((bottle_engine !== "" && bottle_appimage === "") ?   ("<i>" + qsTr("Engine used") + "</i>: " + api.tr + "<b>" + bottle_engine + "</b>" + "<br>") : "") +
                           (bottle_appimage !== "" ? ("<i>" + qsTr("AppImage used") + "</i>: " + api.tr + "<b>" + bottle_appimage + "</b>" + "<br>") : "")  +
                           "<i>" + qsTr("Architecture") + "</i>: " + api.tr + "<b>" + bottle_arch + "</b>" + "<br>" +
                           "<i>" + qsTr("Windows version") + "</i>: " + api.tr + "<b>" + bottle_winver + "</b>" + "<br>" +
                           "<i>" + qsTr("Environment") + "</i>: " + api.tr + "<br>" + "<b>" + bottle_env + "</b>"

                    Component.onCompleted: {
                        wineInfoTimer.triggeredOnStart = false;
                        wineInfoTimer.start();
                    }
                    pointerIcon: false

                    //timer to update game information
                    Timer {
                        id: wineInfoTimer
                        interval: 600 // Run the timer after 600 ms
                        repeat: false
                        running: false
                        triggeredOnStart: false
                        onTriggered: {
                            //to update
                            optBottleInfo.bottle_name = optProtonbottle.internalvalue.split('/').pop();
                            optBottleInfo.bottle_path = optProtonbottle.internalvalue;
                            optBottleInfo.bottle_engine = optBottleInfo.bottle_name.replace(/^\.[^_]*_/, "").split("__")[0];
                            //to calculate size
                            optBottleInfo.bottle_size = "";
                            api.internal.system.runAsync("du -sh \"" + optBottleInfo.bottle_path + "\" | awk '{print $1}' | tr -d '\\n' | tr -d '\\r' > \"/tmp/" + optBottleInfo.bottle_name + ".size\"", "thread");
                            directorySizeTimer.start();
                            //to get architecture
                            //example: sed -n 's/^#arch=//p' user.reg
                            optBottleInfo.bottle_arch = api.internal.system.run("sed -n 's/^#arch=//p' \"" + optBottleInfo.bottle_path + "/user.reg\" | tr -d '\\n' | tr -d '\\r'");
                            //to get winver
                            optBottleInfo.bottle_winver = api.internal.system.run("grep '\"ProductName\"' " + optBottleInfo.bottle_path + "/system.reg | grep 'Windows [0-9]' | uniq | cut -d'\"' -f4 | tr -d '\\n' | tr -d '\\r'");
                            optBottleInfo.bottle_winver = optBottleInfo.bottle_winver + " / " + api.internal.system.run("grep '\"ProductName\"=\"Windows' " + optBottleInfo.bottle_path + "/system.reg -B10 | grep -i '\"DisplayVersion\"' | uniq | cut -d'\"' -f4 | tr -d '\\n' | tr -d '\\r'");
                            optBottleInfo.bottle_winver = optBottleInfo.bottle_winver + " / " + api.internal.system.run("grep '\"ProductName\"=\"Windows' " + optBottleInfo.bottle_path + "/system.reg -B10 | grep -i '\"CurrentVersion\"' | uniq | cut -d'\"' -f4 | tr -d '\\n' | tr -d '\\r'");
                            //to get env details
                            //xargs -n 10 < winetricks.log
                            //keep only 2 lines for the moment
                            optBottleInfo.bottle_env = api.internal.system.run("xargs -n 8 < " + optBottleInfo.bottle_path + "/winetricks.log | head -n 4") + "...";
                            //reset color
                            optProtonbottle.color = themeColor.textValue;
                            //check if AppImage file exists
                            if(api.internal.system.run("test -f \"/usr/proton/" + optBottleInfo.bottle_engine + ".AppImage\" && echo \"true\" | tr -d '\\n' | tr -d '\\r'") === "true"){
                                optBottleInfo.bottle_appimage = optBottleInfo.bottle_engine + ".AppImage";
                            }
                            else{
                                optBottleInfo.bottle_appimage = "";
                                //check if engine "directory" exists
                                console.log("test -d \"/usr/wine/" + optBottleInfo.bottle_engine + "\" && echo \"true\" | tr -d '\\n' | tr -d '\\r'")
                                if(api.internal.system.run("test -d \"/usr/proton/" + optBottleInfo.bottle_engine + "\" && echo \"true\" | tr -d '\\n' | tr -d '\\r'") !== "true"){
                                    optBottleInfo.bottle_engine = optBottleInfo.bottle_engine + " " + "<font color='#FF0000'>" + qsTr("(missing - need to re-install before to use this prefix)") + api.tr + "</font>";
                                    optProtonbottle.color = "red";
                                }
                            }
                        }
                    }

                    //timer to update game information
                    Timer {
                        id: directorySizeTimer
                        interval: 500 // Run the timer every 500 ms
                        repeat: true
                        running: false
                        triggeredOnStart: true
                        onTriggered: {
                            if(api.internal.system.run("test -f \"/tmp/" + optBottleInfo.bottle_name + ".size\" && echo \"true\" | tr -d '\\n' | tr -d '\\r'") === "true"){
                                optBottleInfo.bottle_size = api.internal.system.run("cat \"/tmp/" + optBottleInfo.bottle_name + ".size\"");
                                optBottleInfo.bottle_size = optBottleInfo.bottle_size + qsTr("Bytes") + api.tr + " (" + qsTr("directory") + api.tr + ")";
                                running = false; //to stop the timer
                            }
                        }
                    }

                    Rectangle {
                        color: "transparent"
                        height: vpx(140)
                        width: parseInt(parent.width/5)
                        anchors.top: parent.top
                        anchors.topMargin: vpx(15)
                        anchors.left: parent.right
                        //anchors.leftMargin: vpx(15)
                        //anchors.right: optProtonbottle.right
                        //anchors.rightMargin: vpx(15)


                        visible: true

                        Image {
                            id: enginelogo
                            asynchronous: true
                            height: parent.height
                            width: parent.width
                            source: {
                                // Store it in a temporary variable to avoid calling toLowerCase() multiple times
                                let name = optBottleInfo.bottle_name.toLowerCase();
                                if(name.includes("ge") && name.includes("proton"))
                                    return "qrc:/frontend/assets/ge-proton.png"
                                if(name.includes("umu") && name.includes("proton"))
                                    return "qrc:/frontend/assets/owc.png" // umu-proton come from "Open Wine Components" repo
                                return "";
                            }
                            //anchors.verticalCenter: parent.verticalCenter
                            //anchors.horizontalCenter: parent.horizontalCenter

                            // Centering is still fine, it will center the "natural" sized image
                            anchors.centerIn: parent
                            fillMode: Image.PreserveAspectFit
                            smooth: true
                            visible: true
                        }

                        Image {
                            id: emulatorlogo
                            asynchronous: true
                            height: vpx(40)
                            source: {
                                return "qrc:/frontend/assets/" + emulator + ".png"
                            }
                            //anchors.centerIn: parent

                            anchors.verticalCenter: enginelogo.bottom
                            anchors.horizontalCenter: enginelogo.right
                            fillMode: Image.PreserveAspectFit
                            smooth: true
                            visible: true
                        }
                    }
                }

                // to clean/delete "bottle" selected
                SimpleButton {
                    id: btnCleanSelectedBottle
                    Rectangle {
                        id: containerValidateSelectedEmulatorBottles
                        width: parent.width
                        height: parent.height
                        anchors.verticalCenter: parent.verticalCenter
                        anchors.horizontalCenter: parent.horizontalCenter
                        color: parent.focus ? themeColor.underline : themeColor.secondary
                        opacity : parent.focus ? 1 : 0.3
                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            anchors.horizontalCenter: parent.horizontalCenter
                            color: themeColor.textValue
                            font.pixelSize: vpx(30)
                            font.family: globalFonts.ion
                            text : "\uf2ba  " + qsTr("Remove selected Wine bottle") + api.tr
                        }
                    }
                    onActivate: {
                        //to force change of focus
                        confirmDialog.callerid = "btnCleanSelectedBottle"
                        confirmDialog.focus = false;
                        confirmDialog.setSource("../../dialogs/Generic3ChoicesDialog.qml",
                                                { "title": qsTr("Wine Bottle") + api.tr,
                                                  "message": qsTr("Are you sure to delete this bottle ?\n (" + optProtonbottle.value + ")") + api.tr,
                                                  "symbol": "\uf431",
                                                  "symbolfont" : global.fonts.ion,
                                                  "firstchoice": qsTr("Yes") + api.tr,
                                                  "secondchoice": "",
                                                  "thirdchoice": qsTr("No") + api.tr});
                        //to force change of focus
                        confirmDialog.focus = true;
                    }
                    onFocusChanged: container.onFocus(this)
                    visible: optProtonbottle.internalvalue !== "" ? true : false
                    KeyNavigation.down: optProtonEngine
                }

                MultivalueOption {
                    id: optProtonEngine

                    //property to manage parameter name
                    property string parameterName : prefix + ".proton"

                    label: qsTr("Proton 'engine'") + api.tr
                    note: qsTr("Select the one to use, keep 'AUTO' if you don't know") + api.tr

                    value: api.internal.recalbox.parameterslist.currentName(parameterName)
                    internalvalue: api.internal.recalbox.parameterslist.currentInternalName(parameterName)
                    currentIndex: api.internal.recalbox.parameterslist.currentIndex
                    count: api.internal.recalbox.parameterslist.count
                    onActivate: {
                        //for callback by parameterslistBox
                        parameterslistBox.parameterName = parameterName;
                        parameterslistBox.callerid = optProtonEngine;
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
                        internalvalue = api.internal.recalbox.parameterslist.currentInternalName(parameterName);
                    }

                    onFocusChanged:{
                        if(focus){
                            api.internal.recalbox.parameterslist.currentName(parameterName);
                            currentIndex = api.internal.recalbox.parameterslist.currentIndex;
                            count = api.internal.recalbox.parameterslist.count;
                        }
                        container.onFocus(this)
                    }
                    visible: optProtonbottle.internalvalue === "" ? true : false
                    KeyNavigation.down: optProtonArch
                }
		//RFU
                /*MultivalueOption {
                    id: optWineAppImage

                    //property to manage parameter name
                    property string parameterName : prefix + ".wineappimage"

                    label: qsTr("Wine AppImage") + api.tr
                    note: qsTr("Select the one to use, keep 'AUTO' if you don't know") + api.tr

                    value: api.internal.recalbox.parameterslist.currentName(parameterName)
                    internalvalue: api.internal.recalbox.parameterslist.currentInternalName(parameterName)
                    currentIndex: api.internal.recalbox.parameterslist.currentIndex
                    count: api.internal.recalbox.parameterslist.count

                    onActivate: {
                        //for callback by parameterslistBox
                        parameterslistBox.parameterName = parameterName;
                        parameterslistBox.callerid = optWineAppImage;
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
                        internalvalue = api.internal.recalbox.parameterslist.currentInternalName(parameterName);
                    }

                    onFocusChanged:{
                        if(focus){
                            api.internal.recalbox.parameterslist.currentName(parameterName);
                            currentIndex = api.internal.recalbox.parameterslist.currentIndex;
                            count = api.internal.recalbox.parameterslist.count;
                        }
                        container.onFocus(this)
                    }
                    visible: optProtonbottle.internalvalue === "" ? true : false
                    KeyNavigation.down: optWineArch
                }*/
                MultivalueOption {
                    id: optProtonArch

                    //property to manage parameter name
                    property string parameterName : prefix + ".proton.winearch"

                    label: qsTr("Proton architecture") + api.tr
                    note: qsTr("Select the one to use, keep 'AUTO' if you don't know") + api.tr

                    value: api.internal.recalbox.parameterslist.currentName(parameterName)
                    internalvalue: api.internal.recalbox.parameterslist.currentInternalName(parameterName)
                    currentIndex: api.internal.recalbox.parameterslist.currentIndex
                    count: api.internal.recalbox.parameterslist.count

                    onActivate: {
                        //for callback by parameterslistBox
                        parameterslistBox.parameterName = parameterName;
                        parameterslistBox.callerid = optProtonArch;
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
                        internalvalue = api.internal.recalbox.parameterslist.currentInternalName(parameterName);
                    }

                    onFocusChanged:{
                        if(focus){
                            api.internal.recalbox.parameterslist.currentName(parameterName);
                            currentIndex = api.internal.recalbox.parameterslist.currentIndex;
                            count = api.internal.recalbox.parameterslist.count;
                        }
                        container.onFocus(this)
                    }
                    visible: optProtonbottle.internalvalue === "" ? true : false
                    //RFU: KeyNavigation.down: optWindowsVersion
                    KeyNavigation.down: optProtonSoftRenderer
                }
                //RFU
                /*MultivalueOption {
                    id: optWindowsVersion

                    //property to manage parameter name
                    property string parameterName : prefix + ".winver"

                    label: qsTr("Windows version") + api.tr
                    note: qsTr("Select the one to use, keep 'AUTO' if you don't know") + api.tr

                    value: api.internal.recalbox.parameterslist.currentName(parameterName)
                    currentIndex: api.internal.recalbox.parameterslist.currentIndex
                    count: api.internal.recalbox.parameterslist.count

                    onActivate: {
                        //for callback by parameterslistBox
                        parameterslistBox.parameterName = parameterName;
                        parameterslistBox.callerid = optWindowsVersion;
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
		    visible: optProtonbottle.internalvalue === "" ? true : false
                    KeyNavigation.down: optProtonSoftRenderer
                }*/
		//RFU	
                /*MulticheckOption {
                    id: optWineDllOverrides

                    //property to manage parameter name
                    property string parameterName : prefix + ".winedlloverrides"

                    label: qsTr("DLL overrides") + api.tr
                    note: qsTr("Select DLL overrides to apply (all selected by default)") + api.tr

                    value: api.internal.recalbox.parameterslist.currentNameChecked(parameterName)

                    currentIndex: api.internal.recalbox.parameterslist.currentIndex;
                    count: api.internal.recalbox.parameterslist.count;

                    onActivate: {
                        //for callback by parameterslistBox
                        parameterscheckBox.parameterName = parameterName;
                        parameterscheckBox.callerid = optWineDllOverrides;
                        parameterscheckBox.isChecked = api.internal.recalbox.parameterslist.isChecked();
                        //to force update of list of parameters
                        api.internal.recalbox.parameterslist.currentNameChecked(parameterName);
                        parameterscheckBox.model = api.internal.recalbox.parameterslist;
                        parameterscheckBox.index = api.internal.recalbox.parameterslist.currentIndex;
                        //to transfer focus to parameterscheckBox
                        parameterscheckBox.focus = true;
                        //to save previous value and know if we need restart or not finally
                        parameterscheckBox.previousValue = api.internal.recalbox.getStringParameter(parameterName)
                    }

                    onFocusChanged:{
                        if(focus){
                            api.internal.recalbox.parameterslist.currentNameChecked(parameterName);
                            currentIndex = api.internal.recalbox.parameterslist.currentIndex;
                            count = api.internal.recalbox.parameterslist.count;
                            parameterscheckBox.isChecked = api.internal.recalbox.parameterslist.isChecked();
                        }
                        container.onFocus(this)
                    }
                    visible: optProtonbottle.internalvalue === "" ? true : false
                    KeyNavigation.down: optProtonSoftRenderer
                }*/

                //****************************** section to manage wine version of this emulator*****************************************
                SectionTitle {
                    text: qsTr("Proton 'Renderer' configuration") + api.tr
                    first: true
                    symbol: "\uf2dd"
                    symbolFontFamily: globalFonts.ion
                }
                ToggleOption {
                    id: optProtonSoftRenderer
                    label: qsTr("Proton Software renderer") + api.tr
                    note: qsTr("Enable software renderer for wine") + api.tr

                    checked: api.internal.recalbox.getBoolParameter(prefix + ".proton.winesoftrenderer")
                    onCheckedChanged: {
                        if(checked !== api.internal.recalbox.getBoolParameter(prefix + ".proton.winesoftrenderer",false)){
                        	api.internal.recalbox.setBoolParameter(prefix + ".proton.winesoftrenderer",checked);
                        }
                    }
                    onFocusChanged: container.onFocus(this)
                    KeyNavigation.down: optProtonRenderer
                }
                MultivalueOption {
                    id: optProtonRenderer

                    //property to manage parameter name
                    property string parameterName : prefix + ".proton.winerenderer"

                    label: qsTr("Proton renderer") + api.tr
                    note: qsTr("Select the one to use, keep 'auto' if you don't know") + "\n" +
                          qsTr("('auto' let emulator to select the best renderer itself)") + api.tr

                    // Logic to update visibleInFlickable based on scroll position
                    // This is less efficient as it's checked for ALL items
                    property bool visibleInFlickable: false // Custom property to track visibility
                    onXChanged: parent.checkVisibility(this)
                    // Initial check
                    Component.onCompleted: parent.checkVisibility(this)

                    onActivate: {
                        //for callback by parameterslistBox
                        parameterslistBox.parameterName = parameterName;
                        parameterslistBox.callerid = optProtonRenderer;
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
                        internalvalue = api.internal.recalbox.parameterslist.currentInternalName(parameterName);
                    }

                    onFocusChanged:{
                        if(focus){
                            api.internal.recalbox.parameterslist.currentName(parameterName);
                            count = api.internal.recalbox.parameterslist.count;
                            currentIndex = api.internal.recalbox.parameterslist.currentIndex;
                        }
                        container.onFocus(this)
                    }

                    KeyNavigation.down: optProtonDxvkFramerate
                }
                MultivalueOption {
                    id: optProtonDxvkFramerate
                    visible: optProtonRenderer.internalvalue !== "gl" ? true : false
                    //property to manage parameter name
                    property string parameterName : prefix + ".proton.winedxvkframerate"

                    label: qsTr("Proton DXVK framerate") + api.tr
                    note: qsTr("DXVK Framerate (FPS Limit especially for vulkan/DXVK (DirectX 9 to 11))") + api.tr

                    // Logic to update visibleInFlickable based on scroll position
                    // This is less efficient as it's checked for ALL items
                    property bool visibleInFlickable: false // Custom property to track visibility
                    onXChanged: parent.checkVisibility(this)
                    // Initial check
                    Component.onCompleted: parent.checkVisibility(this)

                    onActivate: {
                        //for callback by parameterslistBox
                        parameterslistBox.parameterName = parameterName;
                        parameterslistBox.callerid = optProtonDxvkFramerate;
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
                    //KeyNavigation.down: optWineDxvkMethod
                    KeyNavigation.down: optProtonAudioDriver
                }
		//RFU
                /*MultivalueOption {
                    id: optWineDxvkMethod
                    visible: optWineRenderer.internalvalue !== "gl" ? true : false
                    //property to manage parameter name
                    property string parameterName : prefix + ".winedxvkmethod"

                    label: qsTr("Wine DXVK/VKD8D method") + api.tr
                    note: qsTr("this 'DLLs' installation methodoloy can impact game behaviors") + api.tr

                    // Logic to update visibleInFlickable based on scroll position
                    // This is less efficient as it's checked for ALL items
                    property bool visibleInFlickable: false // Custom property to track visibility
                    onXChanged: parent.checkVisibility(this)
                    // Initial check
                    Component.onCompleted: parent.checkVisibility(this)

                    onActivate: {
                        //for callback by parameterslistBox
                        parameterslistBox.parameterName = parameterName;
                        parameterslistBox.callerid = optWineDxvkMethod;
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
                    KeyNavigation.down: optWineAudioDriver
                }*/
                SectionTitle {
                    text: qsTr("Wine 'Software' configuration") + api.tr
                    first: true
                    symbol: "\uf22d"
                    symbolFontFamily: globalFonts.ion
                }
                MultivalueOption {
                    id: optProtonAudioDriver

                    //property to manage parameter name
                    property string parameterName : prefix + ".proton.wineaudiodriver"

                    label: qsTr("Proton audio driver") + api.tr
                    note: qsTr("Select the one to use, keep 'AUTO' if you don't know") + api.tr

                    // Logic to update visibleInFlickable based on scroll position
                    // This is less efficient as it's checked for ALL items
                    property bool visibleInFlickable: false // Custom property to track visibility
                    onXChanged: parent.checkVisibility(this)
                    // Initial check
                    Component.onCompleted: parent.checkVisibility(this)

                    onActivate: {
                        //for callback by parameterslistBox
                        parameterslistBox.parameterName = parameterName;
                        parameterslistBox.callerid = optProtonAudioDriver;
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
                    //RFU
                    //KeyNavigation.down: optWineVirtualDesktop
                    KeyNavigation.down: optProtonNVapi
                }                
		//RFU
                /*ToggleOption {
                    id: optProtonVirtualDesktop
                    label: qsTr("Proton Virtual Desktop") + api.tr
                    note: qsTr("Enable software launching in desktop for wine") + api.tr

                    checked: api.internal.recalbox.getBoolParameter(prefix + ".proton.winevirtualdesktop", false)
                    onCheckedChanged: {
                        api.internal.recalbox.setBoolParameter(prefix + ".proton.winevirtualdesktop",checked);
                    }
                    onFocusChanged: container.onFocus(this)
                    KeyNavigation.down: optProtonNVapi
                }*/
                SectionTitle {
                    text: qsTr("Proton 'Performance' configuration") + api.tr
                    first: true
                    symbol: "\uf37f"
                    symbolFontFamily: globalFonts.ion
                }
                ToggleOption {
                    id: optProtonNVapi
                    label: qsTr("Proton NVAPI") + api.tr
                    note: qsTr("Enable NVIDIA api for wine") + api.tr

                    checked: api.internal.recalbox.getBoolParameter(prefix + ".proton.winenvapi", false)
                    onCheckedChanged: {
		                if(checked !== api.internal.recalbox.getBoolParameter(prefix + ".proton.winenvapi",false)){
                       	    api.internal.recalbox.setBoolParameter(prefix + ".proton.winenvapi",checked);
                        }
                    }
                    onFocusChanged: container.onFocus(this)
                    KeyNavigation.down: optProtonFullScreenFSR
                }
                ToggleOption {
                    id: optProtonFullScreenFSR
                    label: qsTr("Proton Fullscreen FSR") + api.tr
                    note: qsTr("Enables AMD FidelityFX Super Resolution (FSR).\n(globally for fullscreen games)") + api.tr

                    checked: api.internal.recalbox.getBoolParameter(prefix + ".proton.winefullscreenfsr", false)
                    onCheckedChanged: {
		                if(checked !== api.internal.recalbox.getBoolParameter(prefix + ".proton.winefullscreenfsr",false)){
                        	api.internal.recalbox.setBoolParameter(prefix + ".proton.winefullscreenfsr",checked);
                        }
                    }
                    onFocusChanged: container.onFocus(this)
                    KeyNavigation.down: optProtonFullScreenIntegerScaling
                }
                ToggleOption {
                    id: optProtonFullScreenIntegerScaling
                    label: qsTr("Proton Fullscreen Integer Scaling") + api.tr
                    note: qsTr("Enables integer scaling for fullscreen games.\n(Useful for pixel-perfect scaling on high-DPI displays)") + api.tr

                    checked: api.internal.recalbox.getBoolParameter(prefix + ".proton.winefullscreenintegerscaling", false)
                    onCheckedChanged: {
		                if(checked !== api.internal.recalbox.getBoolParameter(prefix + ".proton.winefullscreenintegerscaling",false)){
                        	api.internal.recalbox.setBoolParameter(prefix + ".proton.winefullscreenintegerscaling",checked);
                        }
                    }
                    onFocusChanged: container.onFocus(this)
                    KeyNavigation.down: optProtonDisableFullScreenHack
                }
                ToggleOption {
                    id: optProtonDisableFullScreenHack
                    label: qsTr("Proton Disable Fullscreen Hack") + api.tr
                    note: qsTr("Disables Wine's fullscreen hack.\n(which sometimes causes issues with certain games)") + api.tr

                    checked: api.internal.recalbox.getBoolParameter(prefix + ".proton.winedisablefullscreenhack", true)
                    onCheckedChanged: {
		        if(checked !== api.internal.recalbox.getBoolParameter(prefix + ".proton.winedisablefullscreenhack",true)){
                        	api.internal.recalbox.setBoolParameter(prefix + ".proton.winedisablefullscreenhack",checked);
                        }
                    }
                    onFocusChanged: container.onFocus(this)
                    KeyNavigation.down: optProtonESync
                }
                ToggleOption {
                    id: optProtonESync
                    label: qsTr("Proton Esync") + api.tr
                    note: qsTr("Enables Esync (Eventfd Synchronization).\n(Can improve performance in multi-threaded games)") + api.tr

                    checked: api.internal.recalbox.getBoolParameter(prefix + ".proton.wineesync", true)
                    onCheckedChanged: {
		                if(checked !== api.internal.recalbox.getBoolParameter(prefix + ".proton.wineesync",true)){
                        	api.internal.recalbox.setBoolParameter(prefix + ".proton.wineesync",checked);
                        }
                    }
                    onFocusChanged: container.onFocus(this)
                    KeyNavigation.down: optProtonFSync
                }
                ToggleOption {
                    id: optProtonFSync
                    label: qsTr("Proton Fsync") + api.tr
                    note: qsTr("Enables Fsync (Futex Synchronization).\n(A newer, more performant alternative to Esync)") + api.tr

                    checked: api.internal.recalbox.getBoolParameter(prefix + ".proton.winefsync", true)
                    onCheckedChanged: {
		        if(checked !== api.internal.recalbox.getBoolParameter(prefix + ".proton.winefsync",true)){
                        	api.internal.recalbox.setBoolParameter(prefix + ".proton.winefsync",checked);
                        }
                    }
                    onFocusChanged: container.onFocus(this)
                    KeyNavigation.down: btnCleanEmulatorBottles
                }
                //****************************** section to manage all proton version and bottles *****************************************
                SectionTitle {
                    text: qsTr("Proton 'Advanced' functions") + api.tr
                    first: true
                    symbol: "\uf35d"
                    symbolFontFamily: globalFonts.ion
                }
         
                // to clean/delete "bottle" before re-installation
                SimpleButton {
                    id: btnCleanEmulatorBottles
                    Rectangle {
                        id: containerValidateCleanEmulatorBottles
                        width: parent.width
                        height: parent.height
                        anchors.verticalCenter: parent.verticalCenter
                        anchors.horizontalCenter: parent.horizontalCenter
                        color: parent.focus ? themeColor.underline : themeColor.secondary
                        opacity : parent.focus ? 1 : 0.3
                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            anchors.horizontalCenter: parent.horizontalCenter
                            color: themeColor.textValue
                            font.pixelSize: vpx(30)
                            font.family: globalFonts.ion
                            text : "\uf2ba  " + qsTr("Clean All ") + " " + emulator + " " + qsTr("Proton bottle(s)") + api.tr
                        }
                    }
                    onActivate: {
                        //to force change of focus
                        confirmDialog.callerid = "btnCleanEmulatorBottles"
                        confirmDialog.focus = false;
                        confirmDialog.setSource("../../dialogs/Generic3ChoicesDialog.qml",
                                                { "title": emulator + " " + qsTr("Proton Bottles") + api.tr,
                                                  "message": qsTr("Are you sure to delete existing bottles ?") + api.tr,
                                                  "symbol": "\uf431",
                                                  "symbolfont" : global.fonts.ion,
                                                  "firstchoice": qsTr("Yes") + api.tr,
                                                  "secondchoice": "",
                                                  "thirdchoice": qsTr("No") + api.tr});
                        //to force change of focus
                        confirmDialog.focus = true;
                    }
                    onFocusChanged: container.onFocus(this)
                    visible: optProtonbottle.count > 1 ? true : false
                    KeyNavigation.down: btnManageProtonEmbedded
                }

                // to install/uninstall wine/proton versions
                SimpleButton {
                    id: btnManageProtonEmbedded
                    Rectangle {
                        id: containerValidateManageProtonEmbedded
                        width: parent.width
                        height: parent.height
                        anchors.verticalCenter: parent.verticalCenter
                        anchors.horizontalCenter: parent.horizontalCenter
                        color: parent.focus ? themeColor.underline : themeColor.secondary
                        opacity : parent.focus ? 1 : 0.3
                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            anchors.horizontalCenter: parent.horizontalCenter
                            color: themeColor.textValue
                            font.pixelSize: vpx(30)
                            font.family: globalFonts.ion
                            text : "\uf2ba  " + qsTr("Manage") + " " + qsTr("Proton engine(s)") + api.tr
                        }
                    }
                    onActivate: {
                        //to force change of focus
                        confirmDialog.callerid = "btnManageProtonEmbedded"
                        confirmDialog.focus = false;
                        confirmDialog.setSource("../../dialogs/Generic3ChoicesDialog.qml",
                                                { "title": qsTr("pixL ProtonUp-Qt") + api.tr,
                                                  "message": qsTr("Ready to manage your Proton engine(s) ?") + api.tr,
                                                  "symbol": "\uf431",
                                                  "symbolfont" : global.fonts.ion,
                                                  "firstchoice": qsTr("Yes") + api.tr,
                                                  "secondchoice": "",
                                                  "thirdchoice": qsTr("No") + api.tr});
                        //to force change of focus
                        confirmDialog.focus = true;
                    }
                    onFocusChanged: container.onFocus(this)
                    KeyNavigation.down: optProtonDebug
                }
                SectionTitle {
                    text: qsTr("Proton 'Developer' configuration") + api.tr
                    first: true
                    symbol: "\uf2ce"
                    symbolFontFamily: globalFonts.ion
                }
                MulticheckOption {
                    id: optProtonDebug

                    //property to manage parameter name
                    property string parameterName : prefix + ".proton.winedebug"

                    label: qsTr("Proton Debug") + api.tr
                    note: qsTr("Especially for developer/beta testers to help analysis from debug logs") + api.tr

                    value: api.internal.recalbox.parameterslist.currentNameChecked(parameterName)

                    currentIndex: api.internal.recalbox.parameterslist.currentIndex;
                    count: api.internal.recalbox.parameterslist.count;

                    onActivate: {
                        //for callback by parameterslistBox
                        parameterscheckBox.parameterName = parameterName;
                        parameterscheckBox.callerid = optProtonDebug;
                        parameterscheckBox.isChecked = api.internal.recalbox.parameterslist.isChecked();
                        //to force update of list of parameters
                        api.internal.recalbox.parameterslist.currentNameChecked(parameterName);
                        parameterscheckBox.model = api.internal.recalbox.parameterslist;
                        parameterscheckBox.index = api.internal.recalbox.parameterslist.currentIndex;
                        //to transfer focus to parameterscheckBox
                        parameterscheckBox.focus = true;
                        //to save previous value and know if we need restart or not finally
                        parameterscheckBox.previousValue = api.internal.recalbox.getStringParameter(parameterName)
                    }

                    onFocusChanged:{
                        if(focus){
                            api.internal.recalbox.parameterslist.currentNameChecked(parameterName);
                            currentIndex = api.internal.recalbox.parameterslist.currentIndex;
                            count = api.internal.recalbox.parameterslist.count;
                            parameterscheckBox.isChecked = api.internal.recalbox.parameterslist.isChecked();
                        }
                        container.onFocus(this)
                    }

                    KeyNavigation.down: optProtonHUD
                }
                MultivalueOption {
                    id: optProtonHUD
                    visible: optProtonRenderer.internalvalue !== "gl" ? true : false
                    //property to manage parameter name
                    property string parameterName : prefix + ".proton.winehud"

                    label: qsTr("Proton DXVK/VKD3D HUD") + api.tr
                    note: qsTr("Especially for vulkan/DXVK (DirectX 9 to 11) or VKD3D (Direct 12) features") + api.tr

                    // Logic to update visibleInFlickable based on scroll position
                    // This is less efficient as it's checked for ALL items
                    property bool visibleInFlickable: false // Custom property to track visibility
                    onXChanged: parent.checkVisibility(this)
                    // Initial check
                    Component.onCompleted: parent.checkVisibility(this)

                    onActivate: {
                        //for callback by parameterslistBox
                        parameterslistBox.parameterName = parameterName;
                        parameterslistBox.callerid = optProtonHUD;
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
                    //RFU
                    //KeyNavigation.down: btnLaunchWineCfg
                }

                //RFU
		//to launch wine cfg from bottle clearly defined (could create wineprefix if missing)
		/*SimpleButton {
                    id: btnLaunchWineCfg
                    visible: (optProtonEngine.internalvalue !== "") || (optProtonAppImage.internalvalue !== "") ? true : false
                    Rectangle {
                        id: containerValidateLaunchWineCfg
                        width: parent.width
                        height: parent.height
                        anchors.verticalCenter: parent.verticalCenter
                        anchors.horizontalCenter: parent.horizontalCenter
                        color: parent.focus ? themeColor.underline : themeColor.secondary
                        opacity : parent.focus ? 1 : 0.3
                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            anchors.horizontalCenter: parent.horizontalCenter
                            color: themeColor.textValue
                            font.pixelSize: vpx(30)
                            font.family: globalFonts.ion
                            text : "\uf2ba  " + qsTr("Launch Winecfg from Proton bottle") + api.tr
                        }
                    }
                    onActivate: {
                        //to force change of focus
                        confirmDialog.callerid = "btnLaunchWineCfg"
                        confirmDialog.focus = false;
                        confirmDialog.setSource("../../dialogs/Generic3ChoicesDialog.qml",
                                                { "title": emulator + " " + qsTr("Winecfg") + api.tr,
                                                  "message": qsTr("Are you sure to launch Winecfg ?") + api.tr,
                                                  "symbol": "\uf431",
                                                  "symbolfont" : global.fonts.ion,
                                                  "firstchoice": qsTr("Yes") + api.tr,
                                                  "secondchoice": "",
                                                  "thirdchoice": qsTr("No") + api.tr});
                        //to force change of focus
                        confirmDialog.focus = true;
                    }
                    onFocusChanged: container.onFocus(this)
                    KeyNavigation.down: btnLaunchRegedit
                }

                //to launch wine regedit from bottle clearly defined (could create wineprefix if missing)
                SimpleButton {
                    id: btnLaunchRegedit
                    visible: (optWineEngine.internalvalue !== "") || (optWineAppImage.internalvalue !== "") ? true : false
                    Rectangle {
                        id: containerValidateLaunchRegedit
                        width: parent.width
                        height: parent.height
                        anchors.verticalCenter: parent.verticalCenter
                        anchors.horizontalCenter: parent.horizontalCenter
                        color: parent.focus ? themeColor.underline : themeColor.secondary
                        opacity : parent.focus ? 1 : 0.3
                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            anchors.horizontalCenter: parent.horizontalCenter
                            color: themeColor.textValue
                            font.pixelSize: vpx(30)
                            font.family: globalFonts.ion
                            text : "\uf2ba  " + qsTr("Launch regedit from wine bottle") + api.tr
                        }
                    }
                    onActivate: {
                        //to force change of focus
                        confirmDialog.callerid = "btnLaunchRegedit"
                        confirmDialog.focus = false;
                        confirmDialog.setSource("../../dialogs/Generic3ChoicesDialog.qml",
                                                { "title": emulator + " " + qsTr("Regedit") + api.tr,
                                                  "message": qsTr("Are you sure to launch regedit ?") + api.tr,
                                                  "symbol": "\uf431",
                                                  "symbolfont" : global.fonts.ion,
                                                  "firstchoice": qsTr("Yes") + api.tr,
                                                  "secondchoice": "",
                                                  "thirdchoice": qsTr("No") + api.tr});
                        //to force change of focus
                        confirmDialog.focus = true;
                    }
                    onFocusChanged: container.onFocus(this)
                    KeyNavigation.down: btnLaunchControllerSettings
                }

                //to launch wine control joy.cpl from bottle clearly defined (could create wineprefix if missing)
                SimpleButton {
                    id: btnLaunchControllerSettings
                    visible: (optWineEngine.internalvalue !== "") || (optWineAppImage.internalvalue !== "") ? true : false
                    Rectangle {
                        id: containerValidateControllerSettings
                        width: parent.width
                        height: parent.height
                        anchors.verticalCenter: parent.verticalCenter
                        anchors.horizontalCenter: parent.horizontalCenter
                        color: parent.focus ? themeColor.underline : themeColor.secondary
                        opacity : parent.focus ? 1 : 0.3
                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            anchors.horizontalCenter: parent.horizontalCenter
                            color: themeColor.textValue
                            font.pixelSize: vpx(30)
                            font.family: globalFonts.ion
                            text : "\uf2ba  " + qsTr("Launch Controller panel from wine bottle") + api.tr
                        }
                    }
                    onActivate: {
                        //to force change of focus
                        confirmDialog.callerid = "btnLaunchControllerSettings"
                        confirmDialog.focus = false;
                        confirmDialog.setSource("../../dialogs/Generic3ChoicesDialog.qml",
                                                { "title": emulator + " " + qsTr("Controller panel") + api.tr,
                                                  "message": qsTr("Are you sure to launch 'control joy.cpl' ?") + api.tr,
                                                  "symbol": "\uf431",
                                                  "symbolfont" : global.fonts.ion,
                                                  "firstchoice": qsTr("Yes") + api.tr,
                                                  "secondchoice": "",
                                                  "thirdchoice": qsTr("No") + api.tr});
                        //to force change of focus
                        confirmDialog.focus = true;
                    }
                    onFocusChanged: container.onFocus(this)
                }*/

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

    Connections {
        target: confirmDialog.item
        function onAccept() {
            //to remove only selected bottle
            if (confirmDialog.callerid === "btnCleanSelectedBottle"){
                if (!isDebugEnv()){
                    //unlock file system and delete
                    api.internal.system.run("mount -o remount,rw /");
                    //kill wine/exe in memory that could block deletion
                    api.internal.system.run('pkill -9 "/.exe"');
                    api.internal.system.run('pkill -9 wine');
                    api.internal.system.run("sleep 1.0");
                    api.internal.system.run("rm -rf " + optProtonbottle.internalvalue);

                }
                else{//for dev testing
                    api.internal.system.run("sleep 1.0");
                    api.internal.system.run("rm -rf " + optProtonbottle.internalvalue);
                    console.log("rm -rf " + optProtonbottle.internalvalue);
                }
                //reset parameterlist cache
                optProtonbottle.value = api.internal.recalbox.parameterslist.currentName(optProtonbottle.parameterName + ".resetcache");
                //to force update of display of selected value
                optProtonbottle.internalvalue = api.internal.recalbox.parameterslist.currentInternalName(optProtonbottle.parameterName);
                optProtonbottle.currentIndex = api.internal.recalbox.parameterslist.currentIndex;
                optProtonbottle.count = api.internal.recalbox.parameterslist.count;

            }
            //remove emulator bottles
            else if (confirmDialog.callerid === "btnCleanEmulatorBottles"){
                if (!isDebugEnv()){
                    //unlock file system and delete
                    api.internal.system.run("mount -o remount,rw /");
                    //kill wine/exe in memory that could block deletion
                    api.internal.system.run('pkill -9 "/.exe"');
                    api.internal.system.run('pkill -9 wine');
                    api.internal.system.run("sleep 1.0");
                    api.internal.system.run("rm -r /recalbox/." + emulator + "*proton*");
                    api.internal.system.run("rm -r /recalbox/." + emulator + "*Proton*");
                    api.internal.system.run("rm -r /recalbox/share/saves/usersettings/." + emulator + "*proton*");
                    api.internal.system.run("rm -r /recalbox/share/saves/usersettings/." + emulator + "*Proton*");
                }
                else{//for simulate and see more the spinner
                    api.internal.system.run("sleep 5");
                }
                //reset parameterlist cache
                optProtonbottle.value = api.internal.recalbox.parameterslist.currentName(optProtonbottle.parameterName + ".resetcache");
                //to force update of display of selected value
                optProtonbottle.internalvalue = api.internal.recalbox.parameterslist.currentInternalName(optProtonbottle.parameterName);
                optProtonbottle.currentIndex = api.internal.recalbox.parameterslist.currentIndex;
                optProtonbottle.count = api.internal.recalbox.parameterslist.count;
            }
            else if (confirmDialog.callerid === "btnManageProtonEmbedded"){
                var userDirectory = "";
                var initUserDirectory = "";
                if (!isDebugEnv()){
                    //provide write access
                    api.internal.system.run("mount -o remount,rw /");
                    userDirectory = "/recalbox/share/system/";
                    initUserDirectory = "/recalbox/share_init/system/";
                }
                else{
                    userDirectory = "~/";
                    initUserDirectory = "/recalbox/share_init/system/";
                }
                //always reset configuration file from share_init to be well configured
                api.internal.system.run("cp " + initUserDirectory + ".config/pupgui/config.ini" + userDirectory + ".config/pupgui/config.ini")

                //update ProtonUp-Qt conf to select the good installation (proton or wine)
                api.internal.system.run("sed -i 's|^installdir = .*|installdir = /usr/proton/|' /recalbox/share/system/.config/pupgui/config.ini");
                //update color for pixL Theme
                // main:               background,
                api.internal.system.run("sed -i 's|^background = .*|background = " + themeColor.main + "|' " + userDirectory + ".config/pupgui/config.ini");
                // secondary:          _secondary,
                api.internal.system.run("sed -i 's|^_secondary = .*|_secondary = " + themeColor.secondary + "|' " + userDirectory + ".config/pupgui/config.ini");
                // textTitle:          _textTitle,
                api.internal.system.run("sed -i 's|^_texttitle = .*|_texttitle = " + themeColor.textTitle + "|' " + userDirectory + ".config/pupgui/config.ini");
                // textLabel:          _textLabel,
                api.internal.system.run("sed -i 's|^_textlabel = .*|_textlabel = " + themeColor.textLabel + "|' " + userDirectory + ".config/pupgui/config.ini");
                // textSublabel:       _textSublabel,
                api.internal.system.run("sed -i 's|^_textsublabel = .*|_textsublabel = " + themeColor.textSublabel + "|' " + userDirectory + ".config/pupgui/config.ini");
                // textSectionTitle:   accent,
                api.internal.system.run("sed -i 's|^accent = .*|accent = " + themeColor.textSectionTitle + "|' " + userDirectory + ".config/pupgui/config.ini");
                if (!isDebugEnv()){
                    //Launch protonUp-QT AppImage
                    api.internal.system.run("/usr/bin/ProtonUp-Qt.AppImage");
                }
                else{
                    //Launch protonUp-QT AppImage from dev project / or from home specific directory
                    api.internal.system.run("~/ProtonUp-Qt-pixL/ProtonUp-Qt-2.14.0-x86_64.AppImage");
                }
                //force refreash of list of WINE engine/appimage if needed
                //TO DO
            }
	    //RFU
            /*else{
                if (!isDebugEnv()){
                    //LIMIT: if everything is set in "auto" we can't determine the prefix to select
                    var env = ""
                    var wine = ""
                    var command = ""
                    var prefixroot = api.internal.recalbox.getStringParameter(prefix + ".wineprefixroot","/recalbox")
                    if(optWineEngine.internalvalue !== ""){
                        env = "WINEPREFIX=" + prefixroot + "/." + emulator + "_" + optWineEngine.value.replace(" (32 bit)","").replace(" (64 bit)","").trim().replace(" ","_")
                        wine = optWineEngine.internalvalue
                    }
                    else if(optWineAppImage.internalvalue !== ""){
                        env = "WINEPREFIX=" + prefixroot + "/." + emulator + "_" + optWineAppImage.value.replace(" (embedded)","")
                        wine = "/usr/wine/wine"
                    }
                    if(env !== ""){
                        if(optWineArch.internalvalue !== "" ){
                            env = env + "_" + optWineArch.internalvalue;
                            if (confirmDialog.callerid === "btnLaunchWineCfg"){
                                command = env + " " + wine + " winecfg";
                            }
                            else if (confirmDialog.callerid === "btnLaunchRegedit"){
                                command = env + " " + wine + " regedit";
                            }
                            else if (confirmDialog.callerid === "btnLaunchControllerSettings"){
                                command = env + " " + wine + " control joy.cpl";
                            }
                            console.log("winecfg command: " + command);
                            api.internal.system.run(command);
                        }
                        else {//we can't determine the prefix to use from pegasus-fe
                            console.log("wine prefix can't be determine to execute winecfg");
                        }
                    }
                }
                else{//for simulate and see more the spinner
                    api.internal.system.run("sleep 5");
                }
            }*/
            content.focus = true;
        }
        function onCancel() {
            //do nothing
            content.focus = true;
        }
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
