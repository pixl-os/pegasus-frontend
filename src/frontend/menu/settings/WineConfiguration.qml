// Pegasus Frontend
//
// Created by BozoTheGeek 26/05/2025
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
    property string titleHeader: game ? game.title +  " > " + qsTr("Wine configuration") + api.tr :
        (system ? system.name + " > " + qsTr("Wine configuration") + api.tr :
         emulator + " > " + qsTr("Wine configuration") + api.tr)

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

                // Your checkVisibility function stays here
                function checkVisibility(item) {
                    if (!item || !item.visible) return;
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

                //put from here options
                //****************************** section to manage wine version of this emulator*****************************************
                SectionTitle {
                    text: qsTr("Wine 'Bottle' configuration") + api.tr
                    first: true
                    symbol: "\uf2f2"
                    symbolFontFamily: globalFonts.ion
                }
                MultivalueOption {
                    id: optWineBottle

                    //property to manage parameter name
                    property string parameterName : prefix + ".winebottle"

                    // set focus only on first item
                    focus: true

                    label: qsTr("Wine 'bottle' to use") + api.tr
                    note: qsTr("Select existing one or 'New bottle' to create one") + api.tr

                    //keep usual method of loading for this first list to force to be check as first one
                    //because impact a lot the display of other parameter lists ;-)
                    value: api.internal.recalbox.parameterslist.currentName(parameterName)
                    internalvalue: api.internal.recalbox.parameterslist.currentInternalName(parameterName)
                    currentIndex: api.internal.recalbox.parameterslist.currentIndex
                    count: api.internal.recalbox.parameterslist.count

                    // // Logic to update visibleInFlickable based on scroll position
                    // // This is less efficient as it's checked for ALL items
                    // property bool visibleInFlickable: false // Custom property to track visibility
                    // // Initial check
                    // Component.onCompleted: parent.checkVisibility(this)
                    // // check if visibility changed
                    // onVisibleChanged: parent.checkVisibility(this)

                    onActivate: {
                        //for callback by parameterslistBox
                        parameterslistBox.parameterName = parameterName;
                        parameterslistBox.callerid = optWineBottle;
                        //to force update of list of parameters
                        api.internal.recalbox.parameterslist.currentName(parameterName);
                        parameterslistBox.model = api.internal.recalbox.parameterslist;
                        parameterslistBox.index = api.internal.recalbox.parameterslist.currentIndex;
                        //to transfer focus to parameterslistBox
                        parameterslistBox.focus = true;
                    }

                    onInternalvalueChanged: {
                        //console.log("onSelect - internalvalue: '", internalvalue, "'");
                        if(internalvalue !== ""){
                            optBottleInfo.visible = true;
                            wineInfoTimer.triggeredOnStart = true;
                            wineInfoTimer.start();
                        }
                        else{
                            optBottleInfo.visible = false;
                            //reset color
                            optWineBottle.color = themeColor.textValue;
                            //in addition, we are writing empty value to force update of override if needed
                            //when bottle is deleted for example and from an other game/system for wine
                            api.internal.recalbox.setStringParameter(parameterName, "")
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
                    visible: false
                    width: parseInt(parent.width/5)*4
                    showUnderline: false
                    wrapMode: Text.NoWrap
                    launchedAsDialogBox: root.launchedAsDialogBox
                    property string bottle_name: "" //optWineBottle.internalvalue.split('/').pop()
                    property string bottle_path: "" //optWineBottle.internalvalue
                    property string bottle_size : ""
                    property string bottle_engine : "" //bottle_name.replace(/^\.[^_]*_/, "").split("__")[0];
                    property string bottle_appimage : ""
                    property string bottle_wine : "" //wine/wine32/wine64
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
                           "<i>" + qsTr("Wine binary") + "</i>: " + api.tr + "<b>" + bottle_wine + "</b>" + "<br>" +
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
                            optBottleInfo.bottle_name = optWineBottle.internalvalue.split('/').pop();
                            optBottleInfo.bottle_path = optWineBottle.internalvalue;
                            var parts = optBottleInfo.bottle_name.replace(/^\.[^_]*_/, "").split("__")
                            optBottleInfo.bottle_engine = parts[0];
                            if(parts.length > 1){
                                optBottleInfo.bottle_wine = parts[1];
                            }
                            else{
                                optBottleInfo.bottle_wine = "";
                            }
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
                            optWineBottle.color = themeColor.textValue;
                            //check if AppImage file exists
                            if(api.internal.system.run("test -f \"/usr/wine/" + optBottleInfo.bottle_engine + ".AppImage\" && echo \"true\" | tr -d '\\n' | tr -d '\\r'") === "true"){
                                optBottleInfo.bottle_appimage = optBottleInfo.bottle_engine + ".AppImage";
                            }
                            else{
                                optBottleInfo.bottle_appimage = "";
                                //check if engine "directory" exists
                                console.log("test -d \"/usr/wine/" + optBottleInfo.bottle_engine + "\" && echo \"true\" | tr -d '\\n' | tr -d '\\r'")
                                if(api.internal.system.run("test -d \"/usr/wine/" + optBottleInfo.bottle_engine + "\" && echo \"true\" | tr -d '\\n' | tr -d '\\r'") !== "true"){
                                    optBottleInfo.bottle_engine = optBottleInfo.bottle_engine + " " + "<font color='#FF0000'>" + qsTr("(missing - need to re-install before to use this prefix)") + api.tr + "</font>";
                                    optWineBottle.color = "red";
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
                        height: vpx(150)
                        width: parseInt(parent.width/5)
                        anchors.top: parent.top
                        anchors.topMargin: vpx(15)
                        anchors.left: parent.right
                        //anchors.leftMargin: vpx(15)
                        //anchors.right: optWineBottle.right
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
                                if(name.includes("lutris"))
                                    return "qrc:/frontend/assets/lutris.png" //Wine from GloriousEggroll
                                if(name.includes("ge") && name.includes("proton"))
                                    return "qrc:/frontend/assets/ge-proton.png" //Wine from GloriousEggroll
                                if(name.includes("wine"))
                                    return "qrc:/frontend/assets/wine.png" //Wine from Kron4ek/Vanialla/Staging/TKG
                                return "";
                            }
                            //anchors.verticalCenter: parent.verticalCenter
                            //anchors.horizontalCenter: parent.horizontalCenter

                            // Centering is still fine, it will center the "natural" sized image
                            //anchors.centerIn: parent
                            fillMode: Image.PreserveAspectFit
                            smooth: true
                            visible: true
                        }

                        /*Image {
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
                        }*/
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
                                                  "message": qsTr("Are you sure to delete this bottle ?\n (" + optWineBottle.value + ")") + api.tr,
                                                  "symbol": "\uf431",
                                                  "symbolfont" : global.fonts.ion,
                                                  "firstchoice": qsTr("Yes") + api.tr,
                                                  "secondchoice": "",
                                                  "thirdchoice": qsTr("No") + api.tr});
                        //to force change of focus
                        confirmDialog.focus = true;
                    }
                    onFocusChanged: container.onFocus(this)
                    visible: optWineBottle.internalvalue !== "" ? true : false
                    KeyNavigation.down: optWineEngine
                }

                MultivalueOption {
                    id: optWineEngine

                    //property to manage parameter name
                    property string parameterName : prefix + ".wine"

                    label: qsTr("Wine 'engine'") + api.tr
                    note: qsTr("Select the one to use, keep 'AUTO' if you don't know") + api.tr

                    // Logic to update visibleInFlickable based on scroll position
                    // This is less efficient as it's checked for ALL items
                    property bool visibleInFlickable: false // Custom property to track visibility
                    // Initial check
                    Component.onCompleted: parent.checkVisibility(this)
                    // check if visibility changed
                    onVisibleChanged: parent.checkVisibility(this)

                    onActivate: {
                        //for callback by parameterslistBox
                        parameterslistBox.parameterName = parameterName;
                        parameterslistBox.callerid = optWineEngine;
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
                    visible: (optWineBottle.internalvalue === "") ? true : false
                    KeyNavigation.down: optWineAppImage
                }
                MultivalueOption {
                    id: optWineAppImage

                    //property to manage parameter name
                    property string parameterName : prefix + ".wineappimage"

                    label: qsTr("Wine AppImage") + api.tr
                    note: qsTr("Select the one to use, keep 'AUTO' if you don't know") + api.tr

                    // Logic to update visibleInFlickable based on scroll position
                    // This is less efficient as it's checked for ALL items
                    property bool visibleInFlickable: false // Custom property to track visibility
                    // Initial check
                    Component.onCompleted: parent.checkVisibility(this)
                    // check if visibility changed
                    onVisibleChanged: parent.checkVisibility(this)

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
                    visible: (optWineBottle.internalvalue === "") ? true : false
                    KeyNavigation.down: optWineArch
                }
                MultivalueOption {
                    id: optWineArch

                    //property to manage parameter name
                    property string parameterName : prefix + ".winearch"

                    label: qsTr("Wine architecture") + api.tr
                    note: qsTr("Select the one to use, keep 'AUTO' if you don't know") + api.tr

                    // Logic to update visibleInFlickable based on scroll position
                    // This is less efficient as it's checked for ALL items
                    property bool visibleInFlickable: false // Custom property to track visibility
                    // Initial check
                    Component.onCompleted: parent.checkVisibility(this)
                    // check if visibility changed
                    onVisibleChanged: parent.checkVisibility(this)

                    onActivate: {
                        //for callback by parameterslistBox
                        parameterslistBox.parameterName = parameterName;
                        parameterslistBox.callerid = optWineArch;
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
                    visible: optWineBottle.internalvalue === "" ? true : false
                    KeyNavigation.down: optWindowsVersion
                }
                MultivalueOption {
                    id: optWindowsVersion

                    //property to manage parameter name
                    property string parameterName : prefix + ".winver"

                    label: qsTr("Windows version") + api.tr
                    note: qsTr("Select the one to use, keep 'AUTO' if you don't know") + api.tr

                    // Logic to update visibleInFlickable based on scroll position
                    // This is less efficient as it's checked for ALL items
                    property bool visibleInFlickable: false // Custom property to track visibility
                    // Initial check
                    Component.onCompleted: parent.checkVisibility(this)
                    // check if visibility changed
                    onVisibleChanged: parent.checkVisibility(this)

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
                    visible: optWineBottle.internalvalue === "" ? true : false
                    KeyNavigation.down: optWineDllOverrides
                }
                MulticheckOption {
                    id: optWineDllOverrides

                    //property to manage parameter name
                    property string parameterName : prefix + ".winedlloverrides"

                    label: qsTr("DLL overrides") + api.tr
                    note: qsTr("Select DLL overrides to apply (all selected by default)") + api.tr

                    // Logic to update visibleInFlickable based on scroll position
                    // This is less efficient as it's checked for ALL items
                    property bool visibleInFlickable: false // Custom property to track visibility
                    // Initial check
                    Component.onCompleted: parent.checkVisibility(this)
                    // check if visibility changed
                    onVisibleChanged: parent.checkVisibility(this)

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
                    visible: optWineBottle.internalvalue === "" ? true : false
                    KeyNavigation.down: optWineSoftRenderer
                }

                //****************************** section to manage wine version of this emulator *****************************************
                SectionTitle {
                    text: qsTr("Wine 'Renderer' configuration") + api.tr
                    first: true
                    symbol: "\uf2dd"
                    symbolFontFamily: globalFonts.ion
                }
                ToggleOption {
                    id: optWineSoftRenderer
                    label: qsTr("Wine Software renderer") + api.tr
                    note: qsTr("Enable software renderer for wine") + api.tr

                    checked: api.internal.recalbox.getBoolParameter(prefix + ".winesoftrenderer")
                    onCheckedChanged: {
                        if(checked !== api.internal.recalbox.getBoolParameter(prefix + ".winesoftrenderer",false)){
                            api.internal.recalbox.setBoolParameter(prefix + ".winesoftrenderer",checked);
                        }
                    }
                    onFocusChanged: container.onFocus(this)
                    KeyNavigation.down: optWineRenderer
                }
                MultivalueOption {
                    id: optWineRenderer

                    //property to manage parameter name
                    property string parameterName : prefix + ".winerenderer"

                    label: qsTr("Wine renderer") + api.tr
                    note: qsTr("Select the one to use, keep 'auto' if you don't know") + "\n" +
                          qsTr("('auto' let emulator to select the best renderer itself)") + api.tr

                    // Logic to update visibleInFlickable based on scroll position
                    // This is less efficient as it's checked for ALL items
                    property bool visibleInFlickable: false // Custom property to track visibility
                    // Initial check
                    Component.onCompleted: parent.checkVisibility(this)
                    // check if visibility changed
                    onVisibleChanged: parent.checkVisibility(this)

                    onActivate: {
                        //for callback by parameterslistBox
                        parameterslistBox.parameterName = parameterName;
                        parameterslistBox.callerid = optWineRenderer;
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

                    KeyNavigation.down: optWineDxvkFramerate
                }
                MultivalueOption {
                    id: optWineDxvkFramerate
                    visible: optWineRenderer.internalvalue !== "gl" ? true : false
                    //property to manage parameter name
                    property string parameterName : prefix + ".winedxvkframerate"

                    label: qsTr("Wine DXVK framerate") + api.tr
                    note: qsTr("DXVK Framerate (FPS Limit especially for vulkan/DXVK (DirectX 9 to 11))") + api.tr

                    // Logic to update visibleInFlickable based on scroll position
                    // This is less efficient as it's checked for ALL items
                    property bool visibleInFlickable: false // Custom property to track visibility
                    // Initial check
                    Component.onCompleted: parent.checkVisibility(this)
                    // check if visibility changed
                    onVisibleChanged: parent.checkVisibility(this)

                    onActivate: {
                        //for callback by parameterslistBox
                        parameterslistBox.parameterName = parameterName;
                        parameterslistBox.callerid = optWineDxvkFramerate;
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
                    KeyNavigation.down: optWineDxvkMethod
                }
                MultivalueOption {
                    id: optWineDxvkMethod
                    visible: optWineRenderer.internalvalue !== "gl" ? true : false
                    //property to manage parameter name
                    property string parameterName : prefix + ".winedxvkmethod"

                    label: qsTr("Wine DXVK/VKD8D method") + api.tr
                    note: qsTr("this 'DLLs' installation methodoloy can impact game behaviors") + api.tr

                    // Logic to update visibleInFlickable based on scroll position
                    // This is less efficient as it's checked for ALL items
                    property bool visibleInFlickable: false // Custom property to track visibility
                    // Initial check
                    Component.onCompleted: parent.checkVisibility(this)
                    // check if visibility changed
                    onVisibleChanged: parent.checkVisibility(this)

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
                }
                SectionTitle {
                    text: qsTr("Wine 'Software' configuration") + api.tr
                    first: true
                    symbol: "\uf22d"
                    symbolFontFamily: globalFonts.ion
                }
                MultivalueOption {
                    id: optWineAudioDriver

                    //property to manage parameter name
                    property string parameterName : prefix + ".wineaudiodriver"

                    label: qsTr("Wine audio driver") + api.tr
                    note: qsTr("Select the one to use, keep 'AUTO' if you don't know") + api.tr

                    // Logic to update visibleInFlickable based on scroll position
                    // This is less efficient as it's checked for ALL items
                    property bool visibleInFlickable: false // Custom property to track visibility
                    // Initial check
                    Component.onCompleted: parent.checkVisibility(this)
                    // check if visibility changed
                    onVisibleChanged: parent.checkVisibility(this)

                    onActivate: {
                        //for callback by parameterslistBox
                        parameterslistBox.parameterName = parameterName;
                        parameterslistBox.callerid = optWineAudioDriver;
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
                    KeyNavigation.down: optWineVirtualDesktop
                }                
                ToggleOption {
                    id: optWineVirtualDesktop
                    label: qsTr("Wine Virtual Desktop") + api.tr
                    note: qsTr("Enable software launching in desktop for wine") + api.tr

                    checked: api.internal.recalbox.getBoolParameter(prefix + ".winevirtualdesktop", false)
                    onCheckedChanged: {
                        if(checked !== api.internal.recalbox.getBoolParameter(prefix + ".winevirtualdesktop",false)){
                            api.internal.recalbox.setBoolParameter(prefix + ".winevirtualdesktop",checked);
                        }
                    }
                    onFocusChanged: container.onFocus(this)
                    KeyNavigation.down: optWineNVapi
                }
                SectionTitle {
                    text: qsTr("Wine 'Performance' configuration") + api.tr
                    first: true
                    symbol: "\uf37f"
                    symbolFontFamily: globalFonts.ion
                }
                ToggleOption {
                    id: optWineNVapi
                    label: qsTr("Wine NVAPI") + api.tr
                    note: qsTr("Enable NVIDIA api for wine") + api.tr

                    checked: api.internal.recalbox.getBoolParameter(prefix + ".winenvapi", false)
                    onCheckedChanged: {
                        if(checked !== api.internal.recalbox.getBoolParameter(prefix + ".winenvapi",false)){
                            api.internal.recalbox.setBoolParameter(prefix + ".winenvapi",checked);
                        }
                    }
                    onFocusChanged: container.onFocus(this)
                    KeyNavigation.down: optWineFullScreenFSR
                }
                ToggleOption {
                    id: optWineFullScreenFSR
                    label: qsTr("Wine Fullscreen FSR") + api.tr
                    note: qsTr("Enables AMD FidelityFX Super Resolution (FSR).\n(globally for fullscreen games)") + api.tr

                    checked: api.internal.recalbox.getBoolParameter(prefix + ".winefullscreenfsr", false)
                    onCheckedChanged: {
                        if(checked !== api.internal.recalbox.getBoolParameter(prefix + ".winefullscreenfsr",false)){
                            api.internal.recalbox.setBoolParameter(prefix + ".winefullscreenfsr",checked);
                        }
                    }
                    onFocusChanged: container.onFocus(this)
                    KeyNavigation.down: optWineFullScreenIntegerScaling
                }
                ToggleOption {
                    id: optWineFullScreenIntegerScaling
                    label: qsTr("Wine Fullscreen Integer Scaling") + api.tr
                    note: qsTr("Enables integer scaling for fullscreen games.\n(Useful for pixel-perfect scaling on high-DPI displays)") + api.tr

                    checked: api.internal.recalbox.getBoolParameter(prefix + ".winefullscreenintegerscaling", false)
                    onCheckedChanged: {
                        if(checked !== api.internal.recalbox.getBoolParameter(prefix + ".winefullscreenintegerscaling",false)){
                            api.internal.recalbox.setBoolParameter(prefix + ".winefullscreenintegerscaling",checked);
                        }
                    }
                    onFocusChanged: container.onFocus(this)
                    KeyNavigation.down: optWineDisableFullScreenHack
                }
                ToggleOption {
                    id: optWineDisableFullScreenHack
                    label: qsTr("Wine Disable Fullscreen Hack") + api.tr
                    note: qsTr("Disables Wine's fullscreen hack.\n(which sometimes causes issues with certain games)") + api.tr

                    checked: api.internal.recalbox.getBoolParameter(prefix + ".winedisablefullscreenhack", true)
                    onCheckedChanged: {
                        if(checked !== api.internal.recalbox.getBoolParameter(prefix + ".winedisablefullscreenhack",false)){
                            api.internal.recalbox.setBoolParameter(prefix + ".winedisablefullscreenhack",checked);
                        }
                    }
                    onFocusChanged: container.onFocus(this)
                    KeyNavigation.down: optWineESync
                }
                ToggleOption {
                    id: optWineESync
                    label: qsTr("Wine Esync") + api.tr
                    note: qsTr("Enables Esync (Eventfd Synchronization).\n(Can improve performance in multi-threaded games)") + api.tr

                    checked: api.internal.recalbox.getBoolParameter(prefix + ".wineesync", true)
                    onCheckedChanged: {
                        if(checked !== api.internal.recalbox.getBoolParameter(prefix + ".wineesync",false)){
                            api.internal.recalbox.setBoolParameter(prefix + ".wineesync",checked);
                        }
                    }
                    onFocusChanged: container.onFocus(this)
                    KeyNavigation.down: optWineFSync
                }
                ToggleOption {
                    id: optWineFSync
                    label: qsTr("Wine Fsync") + api.tr
                    note: qsTr("Enables Fsync (Futex Synchronization).\n(A newer, more performant alternative to Esync)") + api.tr

                    checked: api.internal.recalbox.getBoolParameter(prefix + ".winefsync", true)
                    onCheckedChanged: {
                        if(checked !== api.internal.recalbox.getBoolParameter(prefix + ".winefsync",false)){
                            api.internal.recalbox.setBoolParameter(prefix + ".winefsync",checked);
                        }
                    }
                    onFocusChanged: container.onFocus(this)
                    KeyNavigation.down: btnCleanEmulatorBottles
                }
                //****************************** section to manage all wine version and bottles *****************************************
                SectionTitle {
                    text: qsTr("Wine 'Advanced' functions") + api.tr
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
                            text : "\uf2ba  " + qsTr("Clean All ") + " " + emulator + " " + qsTr("Wine bottle(s)") + api.tr
                        }
                    }
                    onActivate: {
                        //to force change of focus
                        confirmDialog.callerid = "btnCleanEmulatorBottles"
                        confirmDialog.focus = false;
                        confirmDialog.setSource("../../dialogs/Generic3ChoicesDialog.qml",
                                                { "title": emulator + " " + qsTr("Wine Bottles") + api.tr,
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
                    //keep visible all times now if any bottle is not well name and need to remove alls
                    //visible: optWineBottle.count > 1 ? true : false
                    KeyNavigation.down: btnManageWineEmbedded
                }

                // to install/uninstall wine/proton versions
                SimpleButton {
                    id: btnManageWineEmbedded
                    Rectangle {
                        id: containerValidateManageWineEmbedded
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
                            text : "\uf2ba  " + qsTr("Manage") + " " + qsTr("Wine engine(s)") + api.tr
                        }
                    }
                    onActivate: {
                        //to force change of focus
                        confirmDialog.callerid = "btnManageWineEmbedded"
                        confirmDialog.focus = false;
                        confirmDialog.setSource("../../dialogs/Generic3ChoicesDialog.qml",
                                                { "title": qsTr("pixL ProtonUp-Qt") + api.tr,
                                                  "message": qsTr("Ready to manage your Wine engine(s) ?") + api.tr,
                                                  "symbol": "\uf431",
                                                  "symbolfont" : global.fonts.ion,
                                                  "firstchoice": qsTr("Yes") + api.tr,
                                                  "secondchoice": "",
                                                  "thirdchoice": qsTr("No") + api.tr});
                        //to force change of focus
                        confirmDialog.focus = true;
                    }
                    onFocusChanged: container.onFocus(this)
                    KeyNavigation.down: optWineDebug
                }
                SectionTitle {
                    text: qsTr("Wine 'Developer' configuration") + api.tr
                    first: true
                    symbol: "\uf2ce"
                    symbolFontFamily: globalFonts.ion
                }
                MulticheckOption {
                    id: optWineDebug

                    //property to manage parameter name
                    property string parameterName : prefix + ".winedebug"

                    label: qsTr("Wine Debug") + api.tr
                    note: qsTr("Especially for developer/beta testers to help analysis from debug logs") + api.tr

                    // Logic to update visibleInFlickable based on scroll position
                    // This is less efficient as it's checked for ALL items
                    property bool visibleInFlickable: false // Custom property to track visibility
                    // Initial check
                    Component.onCompleted: parent.checkVisibility(this)
                    // check if visibility changed
                    onVisibleChanged: parent.checkVisibility(this)

                    onActivate: {
                        //for callback by parameterslistBox
                        parameterscheckBox.parameterName = parameterName;
                        parameterscheckBox.callerid = optWineDebug;
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

                    KeyNavigation.down: optWineHUD
                }

                MultivalueOption {
                    id: optWineHUD
                    visible: optWineRenderer.internalvalue !== "gl" ? true : false
                    //property to manage parameter name
                    property string parameterName : prefix + ".winehud"

                    label: qsTr("Wine DXVK/VKD3D HUD") + api.tr
                    note: qsTr("Especially for vulkan/DXVK (DirectX 9 to 11) or VKD3D (Direct 12) features") + api.tr

                    // Logic to update visibleInFlickable based on scroll position
                    // This is less efficient as it's checked for ALL items
                    property bool visibleInFlickable: false // Custom property to track visibility
                    // Initial check
                    Component.onCompleted: parent.checkVisibility(this)
                    // check if visibility changed
                    onVisibleChanged: parent.checkVisibility(this)

                    onActivate: {
                        //for callback by parameterslistBox
                        parameterslistBox.parameterName = parameterName;
                        parameterslistBox.callerid = optWineHUD;
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
                    KeyNavigation.down: btnLaunchWineCfg
                }

                //to launch wine cfg from bottle clearly defined (could create wineprefix if missing)
                SimpleButton {
                    id: btnLaunchWineCfg
                    visible: (optWineBottle.internalvalue !== "") ? true : false
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
                            text : "\uf2ba  " + qsTr("Launch Winecfg from wine bottle") + api.tr
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
                    visible: (optWineBottle.internalvalue !== "") ? true : false
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
                    visible: (optWineBottle.internalvalue !== "") ? true : false
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
                    api.internal.system.run("rm -rf " + optWineBottle.internalvalue);
                    api.internal.system.run("rm -rf " + optWineBottle.internalvalue + "*_dlls");

                }
                else{//for dev testing
                    api.internal.system.run("sleep 1.0");
                    api.internal.system.run("rm -rf " + optWineBottle.internalvalue);
                    console.log("rm -rf " + optWineBottle.internalvalue);
                    //api.internal.system.run("rm -rf " + optWineBottle.internalvalue + "*_dlls");
                    //console.log("rm -rf " + optWineBottle.internalvalue + "*_dlls");
                }

                //set to new bottle after removing one
                api.internal.recalbox.setStringParameter(optWineBottle.parameterName,"");

                //reset parameterlist cache
                optWineBottle.value = api.internal.recalbox.parameterslist.currentName(optWineBottle.parameterName + ".resetcache");

                //to force update of display of selected value
                optWineBottle.internalvalue = api.internal.recalbox.parameterslist.currentInternalName(optWineBottle.parameterName);
                optWineBottle.currentIndex = api.internal.recalbox.parameterslist.currentIndex;
                optWineBottle.count = api.internal.recalbox.parameterslist.count;

                //to manage focus
                content.focus = true;
                optWineBottle.focus = false;
                optWineBottle.focus = true;
                optWineBottle.forceActiveFocus();
                optWineBottle.underline.visible = true;
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
                    api.internal.system.run("rm -r /recalbox/." + emulator + "*wine*");
                    api.internal.system.run("rm -r /recalbox/." + emulator + "*Wine*");
                    api.internal.system.run("rm -r /recalbox/share/saves/usersettings/." + emulator + "*wine*");
                    api.internal.system.run("rm -r /recalbox/share/saves/usersettings/." + emulator + "*Wine*");
                }
                else{//for simulate and see more the spinner
                    api.internal.system.run("sleep 5");
                }
                //set to new bottle after removing all
                api.internal.recalbox.setStringParameter(optWineBottle.parameterName,"");

                //reset parameterlist cache
                optWineBottle.value = api.internal.recalbox.parameterslist.currentName(optWineBottle.parameterName + ".resetcache");

                //to force update of display of selected value
                optWineBottle.internalvalue = api.internal.recalbox.parameterslist.currentInternalName(optWineBottle.parameterName);
                optWineBottle.currentIndex = api.internal.recalbox.parameterslist.currentIndex;
                optWineBottle.count = api.internal.recalbox.parameterslist.count;

                //to manage focus
                content.focus = true;
            }
            else if (confirmDialog.callerid === "btnManageWineEmbedded"){
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
                //console.log("cp " + initUserDirectory + ".config/pupgui/config.ini" + " " + userDirectory + ".config/pupgui/config.ini");
                api.internal.system.run("cp " + initUserDirectory + ".config/pupgui/config.ini" + " " + userDirectory + ".config/pupgui/config.ini")

                //update ProtonUp-Qt conf to select the good installation (proton or wine)
                api.internal.system.run("sed -i 's|^installdir = .*|installdir = /usr/wine/|' " + userDirectory + ".config/pupgui/config.ini");
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
                //reset parameterlist cache
                optWineEngine.value = api.internal.recalbox.parameterslist.currentName(optWineEngine.parameterName + ".resetcache");

                //to manage focus
                content.focus = true;
            }
            else{
                if (!isDebugEnv()){
                    //LIMIT: if everything is set in "auto" we can't determine the prefix to select
                    var env = ""
                    var wine = ""
                    var command = ""
                    if(optWineBottle.internalvalue !== ""){
                        env = "WINEPREFIX=" + optWineBottle.internalvalue
                        console.log("env: " + env);

                        if(api.internal.system.run("test -d \"/usr/wine/" + optBottleInfo.bottle_engine + "\" && echo \"true\" | tr -d '\\n' | tr -d '\\r'") === "true"){
                            wine = "/usr/wine/" + optBottleInfo.bottle_engine + "/bin/" + optWineBottle.internalvalue.split("__")[1];
                        }
                        else if(api.internal.system.run("test -f \"/usr/wine/" + optBottleInfo.bottle_engine + ".AppImage\" && echo \"true\" | tr -d '\\n' | tr -d '\\r'") === "true"){
                            wine = "/usr/wine/" + optBottleInfo.bottle_engine + ".AppImage";
                        }
                    }
                    if(env !== ""){
                        if(optWineArch.internalvalue !== "" ){
                            if (confirmDialog.callerid === "btnLaunchWineCfg"){
                                command = env + " " + wine + " winecfg";
                            }
                            else if (confirmDialog.callerid === "btnLaunchRegedit"){
                                command = env + " " + wine + " regedit";
                            }
                            else if (confirmDialog.callerid === "btnLaunchControllerSettings"){
                                command = env + " " + wine + " control joy.cpl";
                            }
                            console.log("command: " + command);
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
                //to manage focus
                content.focus = true;
            }
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
