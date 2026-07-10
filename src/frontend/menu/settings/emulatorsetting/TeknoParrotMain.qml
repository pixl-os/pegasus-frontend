// Pegasus Frontend
//
// Created by BozoTheGeek 26/05/2025
//

import "../common"
import "qrc:/qmlutils" as PegasusUtils
import QtQuick 2.12
import QtQuick.Controls 2.12
import QtQuick.Window 2.12

FocusScope {
    id: root

    signal close
    signal openWineConfiguration
    signal openProtonConfiguration
    signal openGameConfiguration

    width: parent.width
    height: parent.height
    
//    anchors.fill: parent
    visible: 0 < (x + width) && x < Window.window.width

    enabled: focus

    property bool launchedAsDialogBox: false

    property var game
    property var system
    //to manage overloading
    property string prefix : game ? "override.teknoparrot" : "teknoparrot"
    //to manage better title in screen ScreenHeader (if we want to change it during loading)
    property string titleHeader: game ? game.title +  " > TeknoParrot" :
        (system ? system.name + " > TeknoParrot" :
         qsTr("Advanced emulators settings > TeknoParrot") + api.tr)

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

                //to display info on selected wine bottle
                SimpleButton {
                    id: optGameInfo
                    visible: game ? true : false
                    width: parseInt(parent.width/4)*3
                    showUnderline: false
                    wrapMode: Text.NoWrap
                    launchedAsDialogBox: root.launchedAsDialogBox
                    property string game_path: game ? game.files.get(0).path : ""
                    property string rom_name: {
                        if(optGameInfo.game_path !== ""){
                            var words = optGameInfo.game_path.split('/')
                            //add management of "-" to manage several versions of the same game in the same system
                            //examples naming in this case:
                            //DO6.tp or DO6-1.tp or DO6-proto.tp or DO6-v25.1.tp
                            return words[words.length-1].split('.')[0].split('-')[0];
                        }
                        else return ""
                    }
                    property string game_genre: ""
                    property string exe_path: ""
                    property string exe_arch : "" // 32 or 64 bits
                    property string teknoParrotDescription: "<br><br><br><br><br>"
                    labelFormat: Text.RichText
                    label: "<u>" + qsTr("TeknoParrot Information for this game:") + "</u>"
                    // Set the format to RichText
                    noteFormat: Text.RichText
                    note:  "<i>" + qsTr("Teknoparrot Rom Name:") + "</i>: " + api.tr + "<b>" + rom_name + "</b>" + "<br>" +
                           "<i>" + qsTr("Teknoparrot Game Genre:") + "</i>: " + api.tr + "<b>" + game_genre + "</b>" + "<br>" +
                           //removed to limit number of lines/info already from previous screen in fact
                           //"<i>" + qsTr("Teknoparrot Game path:") + "</i>: " + api.tr + "<b>" + game_path + "</b>" + "<br>" +
                           "<i>" + qsTr("Executable Path") + "</i>: " + api.tr + "<b>" + exe_path + "</b>" + "<br>" +
                           "<i>" + qsTr("Executable architecture") + "</i>: " + api.tr + "<b>" + exe_arch + "</b>" + "<br>" +
                           teknoParrotDescription
                    Component.onCompleted: {
                        gameInfoTimer.triggeredOnStart = false;
                        gameInfoTimer.start();
                    }
                    pointerIcon: false

                    //timer to update game information
                    Timer {
                        id: gameInfoTimer
                        interval: 200 // Run the timer after 200 ms
                        repeat: false
                        running: false
                        triggeredOnStart: false
                        onTriggered: {

                            //MetaData JSON file format:
                            // {
                            //   "game_name": "Battle Fantasia",
                            //   "game_genre": "Fighting",
                            //   "icon_name": "BattleFantasia.png",
                            //   "platform": "Taito Type X2",
                            //   "release_year": "2007",
                            //   "nvidia": "OK",
                            //   "nvidia_issues": null,
                            //   "amd": "OK",
                            //   "amd_issues": null,
                            //   "intel": "NO_INFO",
                            //   "intel_issues": null,
                            //   "general_issues": null
                            // }
                            var JSONpath = "/usr/bin/teknoparrot/Metadata/" + optGameInfo.rom_name + ".json";
                            const fileContent = api.internal.system.run("cat \"" + JSONpath + "\"");
                            const teknoParrotData = JSON.parse(fileContent);
                            optGameInfo.game_genre = teknoParrotData.game_genre
                            optGameInfo.teknoParrotDescription = "Platform: <b>" + teknoParrotData.platform + "</b><br>" +
                                          "Known compatibilities:<br>" +
                                          "+ AMD : " + teknoParrotData.amd +
                                          ((teknoParrotData.amd_issues !== null) ? " - issues : " + teknoParrotData.amd_issues + "<br>" : "<br>") +
                                          "+ Intel : " + teknoParrotData.intel +
                                          ((teknoParrotData.intel_issues !== null) ? " - issues : " + teknoParrotData.intel_issues + "<br>" : "<br>") +
                                          "+ Nvidia : " + teknoParrotData.nvidia +
                                          ((teknoParrotData.nvidia_issues !== null) ? " - issues : " + teknoParrotData.nvidia_issues + "<br>" : "<br>") +
                                          ((teknoParrotData.general_issues !== null) ? "General issues : " + teknoParrotData.general_issues : "")

                            console.log("sed -n 's/.*<GameExecutableLocation>\\(.*\\)<\\/GameExecutableLocation>.*/\\1/p' /usr/bin/teknoparrot/GameSetup/" + optGameInfo.rom_name + ".xml | tr -d '\\n' | tr -d '\\r'");
                            optGameInfo.exe_path = api.internal.system.run("sed -n 's/.*<GameExecutableLocation>\\(.*\\)<\\/GameExecutableLocation>.*/\\1/p' /usr/bin/teknoparrot/GameSetup/" + optGameInfo.rom_name + ".xml | tr -d '\\n' | tr -d '\\r'");
                            optGameInfo.exe_path = optGameInfo.exe_path.replace(/\\/g, "/");
                            //check if missing or not
                            if(api.internal.system.run("test -f \"" + optGameInfo.game_path + "/" + optGameInfo.exe_path + "\" && echo \"true\" | tr -d '\\n' | tr -d '\\r'") === "true"){
                                console.log("sh /recalbox/scripts/pixl-arch-exe.sh \"" + optGameInfo.game_path + "/" + optGameInfo.exe_path + "\" | tr -d '\\n' | tr -d '\\r'");
                                optGameInfo.exe_arch = api.internal.system.run("sh /recalbox/scripts/pixl-arch-exe.sh \"" + optGameInfo.game_path + "/" + optGameInfo.exe_path + "\" | tr -d '\\n' | tr -d '\\r'");
                                optGameInfo.exe_path = optGameInfo.exe_path + "<font color='#2ECC71'> (" + qsTr("Found") + api.tr + ")" + "</font>";
                            }
                            else{
                                optGameInfo.exe_path = "<font color='#FF0000'>" + optGameInfo.exe_path + " (" + qsTr("Missing") + api.tr + ")" + "</font>";
                                optGameInfo.exe_arch = qsTr("N/A") + api.tr;
                            }
                        }
                    }

                    Rectangle {
                        color: "transparent"
                        height: parseInt(parent.width/4) + vpx(15)
                        width: parseInt(parent.width/4)
                        anchors.top: parent.top
                        anchors.topMargin: vpx(15)
                        anchors.left: parent.right
                        //anchors.leftMargin: vpx(15)
                        //anchors.right: optWineBottle.right
                        //anchors.rightMargin: vpx(15)

                        visible: true

                        Image {
                            id: teknoparrotGameLogo
                            asynchronous: true
                            height: parent.height
                            width: parent.width
                            source: {
                                if(game){
                                    var path = game.files.get(0).path;
                                    var words = path.split('/')
                                    //add management of "-" to manage several versions of the same game in the same system
                                    //examples naming in this case:
                                    //DO6.tp or DO6-1.tp or DO6-proto.tp or DO6-v25.1.tp
                                    var romname = words[words.length-1].split('.')[0].split('-')[0];
                                    return "file:///usr/bin/teknoparrot/Icons/" + romname + ".png";
                                }
                                else return "";
                            }

                            // Centering is still fine, it will center the "natural" sized image
                            fillMode: Image.PreserveAspectFit
                            smooth: true
                            visible: true
                        }
                    }
                }

                SectionTitle {
                    text: qsTr("Game screen") + api.tr
                    first: true
                    symbol: "\uf17f"
                }
                MultivalueOption {
                    id: optTeknoparrotOption7

                    // set focus only on first item
                    focus: true

                    //property to manage parameter name
                    property string parameterName : prefix + ".screen.resolution"

                    label: qsTr("Screen/Window resolution") + api.tr
                    note: qsTr("To adpat resolution in full screen/windowed") + api.tr

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
                        parameterslistBox.callerid = optTeknoparrotOption7;
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

                    KeyNavigation.down: optTeknoparrotOption71
                }
                MultivalueOption {
                    id: optTeknoparrotOption71

                    //property to manage parameter name
                    property string parameterName : prefix + ".game.resolution"

                    label: qsTr("Internal game resolution") + api.tr
                    note: qsTr("To scale to internal game resolution (for specific case)") + api.tr

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
                        parameterslistBox.callerid = optTeknoparrotOption71;
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

                    KeyNavigation.down: optTeknoparrotOption2
                }
                MultivalueOption {
                    id: optTeknoparrotOption2

                    //property to manage parameter name
                    property string parameterName : prefix + ".windowed"

                    label: qsTr("Windowed") + api.tr
                    note: qsTr("Start as 'windowed' is adviced for some GPU/Game") + api.tr

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
                        parameterslistBox.callerid = optTeknoparrotOption2;
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

                    KeyNavigation.down: optTeknoparrotOption6
                }
                ToggleOption {
                    id: optTeknoparrotOption6
                    label: qsTr("Rotate 'Tate' Game") + api.tr
                    note: qsTr("To rotate gamez from Open Parrot") + api.tr

                    checked: api.internal.recalbox.getBoolParameter(prefix + ".rotate.tate", false)
                    onCheckedChanged: {
                        if(checked !== api.internal.recalbox.getBoolParameter(prefix + ".rotate.tate",false)){
                            api.internal.recalbox.setBoolParameter(prefix + ".rotate.tate",checked);
                        }
                    }
                    onFocusChanged: container.onFocus(this)
                    KeyNavigation.down: optTeknoparrotOption1
                }

                SectionTitle {
                    text: qsTr("Controllers") + api.tr
                    first: true
                    symbol: "\uf181"
                    symbolFontFamily: globalFonts.ion
                }
                ToggleOption {
                    id: optTeknoparrotOption1

                    label: qsTr("Xinput") + api.tr
                    note: qsTr("Enable Xinput mode for controllers (auto mapping forced and manage vibration) \nelse Dinput will be used. (on change, need reboot)") + api.tr

                    checked: api.internal.recalbox.getBoolParameter(prefix + ".xinput",false) //deactivated by default to use Dinput
                    onCheckedChanged: {
                        if(checked !== api.internal.recalbox.getBoolParameter(prefix + ".xinput",false)){
                            api.internal.recalbox.setBoolParameter(prefix + ".xinput",checked);
                        }
                    }
                    onFocusChanged: container.onFocus(this)
                    KeyNavigation.down: optTeknoparrotDeadZone
                }
                SliderOption {
                    id: optTeknoparrotDeadZone

                    //property to manage parameter name
                    property string parameterName : prefix + ".deadzone"

                    //property of SliderOption to set
                    label: qsTr("Set dead zone Controller") + api.tr
                    note: qsTr("the default value is 2% (min: 0% - max 30%).") + api.tr
                    // in slider object
                    max : 30
                    min : 0
                    slidervalue : api.internal.recalbox.getIntParameter(parameterName,2)
                    // in text object
                    value: api.internal.recalbox.getIntParameter(parameterName,2) + "%"
                    onActivate: {
                        focus = true;
                    }
                    Keys.onLeftPressed: {
                        api.internal.recalbox.setIntParameter(parameterName,slidervalue);
                        value = slidervalue + "%";
                        sfxNav.play();
                    }
                    Keys.onRightPressed: {
                        api.internal.recalbox.setIntParameter(parameterName,slidervalue);
                        value = slidervalue + "%";
                        sfxNav.play();
                    }
                    onFocusChanged: container.onFocus(this)
                    KeyNavigation.down: optTeknoparrotOption32
                }
                MultivalueOption {
                    id: optTeknoparrotOption32

                    //property to manage parameter name
                    property string parameterName : prefix + ".versus.controller.mapping"

                    label: qsTr("'Versus' games controller mapping") + api.tr
                    note: qsTr("To adapt mappings to your habit/controller/panel") + api.tr

                    // Logic to update visibleInFlickable based on scroll position
                    // This is less efficient as it's checked for ALL items
                    property bool visibleInFlickable: false // Custom property to track visibility
                    // Initial check
                    Component.onCompleted: parent.checkVisibility(this)
                    // check if visibility changed
                    onVisibleChanged: parent.checkVisibility(this)

                    onActivate: {
                        //to force update of list of parameters
                        api.internal.recalbox.parameterslist.currentName(parameterName);
                        parameterslistBox.parameterName = parameterName;

                        //to customize Box display
                        parameterslistBox.has_picture = true;
                        parameterslistBox.firstlist_minimum_width_purcentage = 0.55;
                        parameterslistBox.firstlist_maximum_width_purcentage = 0.55;
                        parameterslistBox.box_maximum_width = 800;
                        parameterslistBox.box_minimum_width = 800;
                        parameterslistBox.has_picture = true;
                        parameterslistBox.max_listitem_displayed = 5;

                        //to force update of list of parameters
                        parameterslistBox.callerid = optTeknoparrotOption32;
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

                    KeyNavigation.down: optTeknoparrotOption33
                }
                ToggleOption {
                    id: optTeknoparrotOption33

                    property string parameterName: prefix + ".switch.dpad.leftstick"

                    label: qsTr("Switch D-PAD/Left Stick") + api.tr
                    note: qsTr("Enable possibility to switch to left stick if we prefer") + api.tr

                    checked: api.internal.recalbox.getBoolParameter(parameterName,false) //deactivated by default to use DPAD in priority for versus game
                    onCheckedChanged: {
                        if(checked !== api.internal.recalbox.getBoolParameter(parameterName,false)){
                            api.internal.recalbox.setBoolParameter(parameterName,checked);
                        }
                    }
                    onFocusChanged: container.onFocus(this)
                    KeyNavigation.down: optTeknoparrotMenuService
                }
                ToggleOption {
                    id: optTeknoparrotMenuService

                    property string parameterName: prefix + ".menu.service"
                    label: qsTr("Activate Test/Service menu access") + api.tr
                    note: qsTr("Enable accces to Test/Service menu using usually L3/R3 buttons") + api.tr

                    checked: api.internal.recalbox.getBoolParameter(parameterName,false) //deactivated by default
                    onCheckedChanged: {
                        if(checked !== api.internal.recalbox.getBoolParameter(parameterName,false)){
                            api.internal.recalbox.setBoolParameter(parameterName,checked);
                        }
                    }
                    onFocusChanged: container.onFocus(this)
                    KeyNavigation.down: optGameConfiguration
                }

                // SectionTitle {
                //     text: qsTr("'Game' configuration") + api.tr
                //     first: true
                //     symbol: "\uf179"
                // }

                SimpleButton {
                    id: optGameConfiguration
                    visible: game ? true : false
                    label: qsTr("'Game' configuration") + api.tr
                    onActivate: {
                        focus = true;
                        root.openGameConfiguration();
                    }
                    onFocusChanged: container.onFocus(this)
                    //pointer moved in SimpleButton desactived on default
                    pointerIcon: true
                    KeyNavigation.down: optTeknoparrotAdvancedConf
                }

                // ToggleOption {
                //     id: optTeknoparrotOption3
                //     label: qsTr("Frame limiter") + api.tr
                //     note: qsTr("Activated to prevent games running too fast") + api.tr

                //     checked: api.internal.recalbox.getBoolParameter(prefix + ".framelimiter", true)
                //     onCheckedChanged: {
                //        if(checked !== api.internal.recalbox.getBoolParameter(prefix + ".framelimiter",true)){
                //            api.internal.recalbox.setBoolParameter(prefix + ".framelimiter",checked);
                //        }
                //     }
                //     onFocusChanged: container.onFocus(this)
                //     KeyNavigation.down: optTeknoparrotOption6
                // }
                // ToggleOption {
                //     id: optTeknoparrotOption31
                //     label: qsTr("Force Free Play") + api.tr
                //     note: qsTr("Activate Free Play automatically if manageable by emulator") + api.tr

                //     checked: api.internal.recalbox.getBoolParameter(prefix + ".force.freeplay", true)
                //     onCheckedChanged: {
                //         if(checked !== api.internal.recalbox.getBoolParameter(prefix + ".force.freeplay",true)){
                //             api.internal.recalbox.setBoolParameter(prefix + ".force.freeplay",checked);
                //         }
                //     }
                //     onFocusChanged: container.onFocus(this)
                //     KeyNavigation.down: optTeknoparrotAdvancedConf
                // }

                ToggleOption {
                    id: optTeknoparrotAdvancedConf
                    SectionTitle {
                        text: qsTr("'Advanced' configuration") + api.tr
                        first: true
                        symbol: "\uf412"
                    }
                    checked: api.internal.recalbox.getBoolParameter(prefix + ".advanced.configuration", false)
                    onCheckedChanged: {
                        if(checked !== api.internal.recalbox.getBoolParameter(prefix + ".advanced.configuration",false)){
                            api.internal.recalbox.setBoolParameter(prefix + ".advanced.configuration",checked);

                        }
                    }
                    onFocusChanged: container.onFocus(this)
                    KeyNavigation.down: optTeknoparrotOption4
                }
                ToggleOption {
                    id: optTeknoparrotOption4
                    label: qsTr("Launch UI first") + api.tr
                    note: qsTr("Start UI first to be able to change/verify conf if needed.\n(need mouse/keyboard to navigate)") + api.tr

                    checked: api.internal.recalbox.getBoolParameter(prefix + ".launch.ui", false)
                    onCheckedChanged: {
                        if(checked !== api.internal.recalbox.getBoolParameter(prefix + ".launch.ui",false)){
                            api.internal.recalbox.setBoolParameter(prefix + ".launch.ui",checked);
                        }
                    }
                    onFocusChanged: container.onFocus(this)
                    KeyNavigation.down: optTeknoparrotOption8
                    visible: optTeknoparrotAdvancedConf.checked
                }
                ToggleOption {
                    id: optTeknoparrotOption8
                    label: qsTr("Use UI Game Profile(s) if exists") + api.tr
                    note: qsTr("To let you use your own Game/Controller Settings.\n(for testing usually)") + api.tr

                    checked: api.internal.recalbox.getBoolParameter(prefix + ".keep.userprofile.from.ui", false)
                    onCheckedChanged: {
                        if(checked !== api.internal.recalbox.getBoolParameter(prefix + ".keep.userprofile.from.ui",false)){
                            api.internal.recalbox.setBoolParameter(prefix + ".keep.userprofile.from.ui",checked);
                        }
                    }
                    onFocusChanged: container.onFocus(this)
                    KeyNavigation.down: optTeknoparrotOption81
                    visible: optTeknoparrotAdvancedConf.checked
                }
                ToggleOption {
                    id: optTeknoparrotOption81
                    visible: optTeknoparrotAdvancedConf.checked ? (optTeknoparrotOption8.checked === true ? false : true) : false
                    label: qsTr("Overwrite UI Game Profile(s) by pixL") + api.tr
                    note: qsTr("To have generated Game/Controller Settings from UI\n(as default)") + api.tr

                    checked: api.internal.recalbox.getBoolParameter(prefix + ".save.userprofile.for.ui", true)
                    onCheckedChanged: {
                        if(checked !== api.internal.recalbox.getBoolParameter(prefix + ".save.userprofile.for.ui",true)){
                            api.internal.recalbox.setBoolParameter(prefix + ".save.userprofile.for.ui",checked);
                        }
                    }
                    onFocusChanged: container.onFocus(this)
                    KeyNavigation.down: optTeknoparrotOption5                    
                }
                ToggleOption {
                    id: optTeknoparrotOption5
                    label: qsTr("Show launcher") + api.tr
                    note: qsTr("To show launcher console from Open Parrot") + api.tr

                    checked: api.internal.recalbox.getBoolParameter(prefix + ".show.launcher", false)
                    onCheckedChanged: {
                        if(checked !== api.internal.recalbox.getBoolParameter(prefix + ".show.launcher",false)){
                            api.internal.recalbox.setBoolParameter(prefix + ".show.launcher",checked);
                        }
                    }
                    onFocusChanged: container.onFocus(this)
                    KeyNavigation.down: optTeknoparrotRunnerConf
                    visible: optTeknoparrotAdvancedConf.checked
                }

                ToggleOption {
                    id: optTeknoparrotRunnerConf
                    SectionTitle {
                        text: qsTr("'Runner' configuration") + api.tr
                        first: true
                        symbol: "\uf26f" //TO DO: fusee ?!
                        symbolFontFamily: globalFonts.ion
                    }
                    checked: api.internal.recalbox.getBoolParameter(prefix + ".runner.configuration", false)
                    onCheckedChanged: {
                        if(checked !== api.internal.recalbox.getBoolParameter(prefix + ".runner.configuration",false)){
                            api.internal.recalbox.setBoolParameter(prefix + ".runner.configuration",checked);
                        }
                    }
                    onFocusChanged: container.onFocus(this)
                    KeyNavigation.down: optTeknoparrotRunnerType
                }
                MultivalueOption {
                    id: optTeknoparrotRunnerType

                    //property to manage parameter name
                    property string parameterName : prefix + ".runner.type"

                    label: qsTr("'Runner' type used to launch TeknoParrot") + api.tr
                    note: qsTr("To manage different cases (if needed)") + api.tr

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
                        parameterslistBox.callerid = optTeknoparrotRunnerType;
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

                    KeyNavigation.down: optWineConfiguration
                    visible: optTeknoparrotRunnerConf.checked
                }
                SimpleButton {
                    id: optWineConfiguration
                    visible: optTeknoparrotRunnerConf.checked && (optTeknoparrotRunnerType.value === "Wine") ? true : false
                    label: qsTr("'Wine' configuration") + api.tr
                    onActivate: {
                        focus = true;
                        root.openWineConfiguration();
                    }
                    onFocusChanged: container.onFocus(this)
                    //pointer moved in SimpleButton desactived on default
                    pointerIcon: true
                    KeyNavigation.down: optProtonConfiguration
                }
                SimpleButton {
                    id: optProtonConfiguration
                    visible: optTeknoparrotRunnerConf.checked && (optTeknoparrotRunnerType.value === "Proton") ? true : false
                    label: qsTr("'Proton' configuration") + api.tr
                    onActivate: {
                        focus = true;
                        root.openProtonConfiguration();
                    }
                    onFocusChanged: container.onFocus(this)
                    //pointer moved in SimpleButton desactived on default
                    pointerIcon: true
                }

                Item {
                    width: parent.width
                    height: launchedAsDialogBox ? implicitHeight + vpx(50) : implicitHeight + vpx(30)
                }
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
        onClose: content.focus = true
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
