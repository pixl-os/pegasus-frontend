// Pegasus Frontend
//
// Created by Strodown 17/07/2023
// Updated by BozoTheGeek 06/08/2025 to manage system and override configurations
//
import "emulatorsetting"
import "common"
import "qrc:/qmlutils" as PegasusUtils
import QtQuick 2.12
import QtQuick.Controls 2.12
import QtQuick.Window 2.12

FocusScope {
    id: root

    signal close
    signal openEmulatorSettings(var emulator)
    width: parent.width
    height: parent.height
    
    //anchors.fill: parent
    visible: 0 < (x + width) && x < Window.window.width

    enabled: focus

    property var game
    property var system
    property string prefix : system.shortName
    property bool launchedAsDialogBox: false
    // check if is a libretro emulator for dynamic entry
    property bool isLibretroCore
    property bool hasOverlaySupport
    //to have current emulator/core selected
    property string emulator
    property string core
    //to manage better title in screen ScreenHeader (if we want to change it during loading)
    property string titleHeader : game ? game.title : qsTr("Settings systems > ") + api.tr + system.name

    //function to get icon from teknoparrot if nothing available from scrap
    function teknoParrotIcon(gameData) {
        if (gameData){
            if(gameData.collections.get(0).getCoreAt(0) === "teknoparrot"){
                var path = gameData.files.get(0).path;
                var words = path.split('/')
                //add management of "-" to manage several versions of the same game in the same system
                //examples naming in this case:
                //DO6.tp or DO6-1.tp or DO6-proto.tp or DO6-v25.1.tp
                var romname = words[words.length-1].split('.')[0].split('-')[0];
                //console.log("words[words.length-1].split('.')[0].split('-')[0] : " + words[words.length-1].split('.')[0].split('-')[0])
                return "file:///usr/bin/teknoparrot/Icons/" + romname + ".png";
            }
        }
        return ""
    }

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

    onGameChanged: {
        if(typeof(game) !== "undefined"){
            var romfile = game.files.get(0).path;
            prefix = "override." + system.shortName
            api.internal.recalbox.loadParametersFromOverride(romfile + ".recalbox.conf");
        }
    }

    Keys.onPressed: {
        if (api.keys.isCancel(event) && !event.isAutoRepeat) {
            event.accepted = true;
            if(game){
                api.internal.recalbox.saveParametersInOverride();
            }
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
        text: root.titleHeader
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
                    height: game ? vpx(10) : implicitHeight + vpx(30)
                    visible: true
                }
                SimpleButton {
                    id: optGameInfo
                    visible: game ? true : false
                    width: parent.width - ((height/9)*16)
                    showUnderline: false
                    wrapMode: Text.NoWrap
                    launchedAsDialogBox: root.launchedAsDialogBox
                    property string override_exists: "false"
                    property string override_file : ""
                    property string padtokey_exists: "false"
                    property string padtokey_file: ""
                    property string keys_exists: "false"
                    property string keys_file: ""
                    property string rom_size : ""
                    property string rom_file: game ? game.files.get(0).path : ""
                    property var rom_file_split: game ? rom_file.split('/') : ""
                    property string game_filename: (game && (rom_file !== "") && (typeof(rom_file) !== "undefined")) ? rom_file_split[rom_file_split.length-1] : ""
                    property string extension: game && game_filename !== "" ? game_filename.split('.')[1] : ""
                    property string game_fileextension: game && extension !== "" ? extension[extension.length-1] : ""
                    //property string game_logo: game ? game.assets.logo : ""
                    label: qsTr("File: ") + api.tr + elideStringFromLeft(rom_file,80)
                    note:  qsTr("Size: ") + api.tr + rom_size + "\n"
                            + qsTr("Override: ") + api.tr
                            + (override_exists === "true" ? game_filename + ".recalbox.conf" : "" ) + "\n"
                            + "PadToKey: "
                            + (padtokey_exists === "true" ? game_filename + ".p2k.cfg" : "" ) + "\n"
                            + "Evmapy: "
                            + (keys_exists === "true" ? game_filename + ".p2k.keys" : "" ) + "\n"
                    Component.onCompleted: {
                        if(game){
                            gameInfoTimer.start();
                        }
                    }
                    pointerIcon: false

                    //timer to update game information
                    Timer {
                        id: gameInfoTimer
                        interval: 600 // Run the timer after 600 ms
                        repeat: false
                        running: false
                        triggeredOnStart: false
                        onTriggered: {
                            optGameInfo.override_file = optGameInfo.rom_file + ".recalbox.conf";
                            optGameInfo.override_exists = api.internal.system.run("test -f \"" + optGameInfo.rom_file + ".recalbox.conf\" && echo \"true\" | tr -d '\\n' | tr -d '\\r'");
                            optGameInfo.padtokey_file = optGameInfo.rom_file + ".p2k.cfg";
                            optGameInfo.padtokey_exists = api.internal.system.run("test -f \"" + optGameInfo.rom_file + ".p2k.cfg\" && echo \"true\" | tr -d '\\n' | tr -d '\\r'");
                            optGameInfo.keys_file = optGameInfo.rom_file + ".keys";
                            optGameInfo.keys_exists = api.internal.system.run("test -f \"" + optGameInfo.rom_file + ".keys\" && echo \"true\" | tr -d '\\n' | tr -d '\\r'");
                            optGameInfo.rom_size = "";
                            //test if not directory to have size of the rom quickly
                            //console.log("test -d \"" + optGameInfo.rom_file + "\" && echo \"true\" | tr -d '\\n' | tr -d '\\r'");
                            if(api.internal.system.run("test -d \"" + optGameInfo.rom_file + "\" && echo \"true\" | tr -d '\\n' | tr -d '\\r'") !== "true"){
                                optGameInfo.rom_size = api.internal.system.run("du -sh \"" + optGameInfo.rom_file + "\" | awk '{print $1}' | tr -d '\\n' | tr -d '\\r'");
                                optGameInfo.rom_size = optGameInfo.rom_size + qsTr("Bytes") + api.tr + " (" + qsTr("file") + api.tr + ")"
                            }
                            else{
                                if(api.internal.system.run("test -f \"/tmp/" + optGameInfo.game_filename + ".size\" && echo \"true\" | tr -d '\\n' | tr -d '\\r'") === "true"){
                                    optGameInfo.rom_size = api.internal.system.run("cat \"/tmp/" + optGameInfo.game_filename + ".size\"");
                                    optGameInfo.rom_size = optGameInfo.rom_size + qsTr("Bytes") + api.tr + " (" + qsTr("directory") + api.tr + ")";
                                }
                                else{
                                    optGameInfo.rom_size = "";
                                    api.internal.system.runAsync("du -sh \"" + optGameInfo.rom_file + "\" | awk '{print $1}' | tr -d '\\n' | tr -d '\\r' > \"/tmp/" + optGameInfo.game_filename + ".size\"", "thread");
                                    directorySizeTimer.start();
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
                            if(api.internal.system.run("test -f \"/tmp/" + optGameInfo.game_filename + ".size\" && echo \"true\" | tr -d '\\n' | tr -d '\\r'") === "true"){
                                optGameInfo.rom_size = api.internal.system.run("cat \"/tmp/" + optGameInfo.game_filename + ".size\"");
                                optGameInfo.rom_size = optGameInfo.rom_size + qsTr("Bytes") + api.tr + " (" + qsTr("directory") + api.tr + ")";
                                running = false; //to stop the timer
                            }
                        }
                    }

                    Rectangle {
                        height: parent.height
                        color: "transparent"
                        width: (parent.height/9)*16

                        anchors.left: parent.right
                        anchors.leftMargin: vpx(45)
                        visible: true
                        Image {
                            id: background
                            asynchronous: true
                            height: parent.height
                            width: parent.width
                            source: game ? game.assets.screenshot : ""
                            anchors.verticalCenter: parent.verticalCenter
                            anchors.horizontalCenter: parent.horizontalCenter
                            fillMode: Image.PreserveAspectFit
                            smooth: true
                            visible: true
                        }
                        Image {
                            id: logo
                            asynchronous: true
                            height: parent.height/2
                            width: background.width
                            source: game ? game.assets.logo : ""
                            anchors.verticalCenter: parent.verticalCenter
                            anchors.horizontalCenter: parent.horizontalCenter
                            fillMode: Image.PreserveAspectFit
                            smooth: true
                            visible: true
                        }
                        Image {
                            id: tplogo
                            asynchronous: true
                            height: ((game.assets.logo === "") && (game.assets.screenshot === "")) ? (parent.height/4)*3 : parent.height/2
                            width: background.width
                            source: game ? (game.assets.logo === "" ? teknoParrotIcon(game) : "") : ""
                            anchors.verticalCenter: parent.verticalCenter
                            anchors.horizontalCenter: parent.horizontalCenter
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
                    launchedAsDialogBox: true
                }
                MultivalueOption {
                    id: optSystemGameRatio
                    // set focus only on first item
                    focus: true

                    //property to manage parameter name
                    property string parameterName : prefix + ".ratio"

                    label: qsTr("Game ratio") + api.tr
                    note: qsTr("Set ratio for this system (auto,4/3,16/9,16/10,etc...)") + api.tr

                    value: api.internal.recalbox.parameterslist.currentName(parameterName)

                    currentIndex: api.internal.recalbox.parameterslist.currentIndex;
                    count: api.internal.recalbox.parameterslist.count;

                    onActivate: {
                        //to force update of list of parameters
                        api.internal.recalbox.parameterslist.currentName(parameterName);
                        //to customize Box display
                        parameterslistBox.firstlist_title = qsTr("Game ratio") + api.tr
                        //for callback by parameterslistBox
                        parameterslistBox.index = api.internal.recalbox.parameterslist.currentIndex;
                        parameterslistBox.callerid = optSystemGameRatio;
                        parameterslistBox.model = api.internal.recalbox.parameterslist;
                        parameterslistBox.parameterName = parameterName;
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

                    KeyNavigation.down: optSystemSmoothGame
                }
                ToggleOption {
                    id: optSystemSmoothGame

                    //property to manage parameter name
                    property string suffix: ".smooth"
                    property string parameterName : prefix + suffix

                    label: qsTr("Smooth games") + api.tr
                    note: qsTr("Set smooth for this system") + api.tr

                    checked:{
                        if(prefix === system.shortName){
                            return api.internal.recalbox.getBoolParameter(parameterName, api.internal.recalbox.getBoolParameter("global" + suffix))
                        }
                        else{
                            return api.internal.recalbox.getBoolParameter(parameterName, api.internal.recalbox.getBoolParameter(system.shortName + suffix, api.internal.recalbox.getBoolParameter("global" + suffix)))
                        }
                    }
                    onCheckedChanged:{
                        if(checked !== api.internal.recalbox.getBoolParameter(parameterName, api.internal.recalbox.getBoolParameter(system.shortName + suffix, api.internal.recalbox.getBoolParameter("global" + suffix)))){
                            api.internal.recalbox.setBoolParameter(parameterName,checked);
                        }
                    }

                    onFocusChanged: container.onFocus(this)
                    KeyNavigation.down: optSystemShaderSet
                    // not visible if not libretro Core
                    visible : isLibretroCore
                }
                MultivalueOption {
                    id: optSystemShaderSet

                    //property to manage parameter name
                    property string parameterName : prefix + ".shaderset"

                    label: qsTr("Predefined shaders") + api.tr
                    note: qsTr("Set predefined Shader effect for this system") + api.tr

                    value: api.internal.recalbox.parameterslist.currentName(parameterName)
                    internalvalue: api.internal.recalbox.parameterslist.currentInternalName(parameterName);

                    currentIndex: api.internal.recalbox.parameterslist.currentIndex;
                    count: api.internal.recalbox.parameterslist.count;

                    onValueChanged: {
                        //to force to udpate internal value also
                        internalvalue = api.internal.recalbox.parameterslist.currentInternalName(parameterName);
                    }

                    onActivate: {
                        //to force update of list of parameters
                        api.internal.recalbox.parameterslist.currentName(parameterName);
                        //to customize Box display
                        parameterslistBox.firstlist_title = qsTr("Predefined shader") + api.tr
                        parameterslistBox.has_picture = true;
                        parameterslistBox.firstlist_minimum_width_purcentage = 0.30
                        parameterslistBox.firstlist_maximum_width_purcentage = 0.30
                        parameterslistBox.max_listitem_displayed = 9;

                        //for callback by parameterslistBox
                        parameterslistBox.index = api.internal.recalbox.parameterslist.currentIndex;
                        parameterslistBox.callerid = optSystemShaderSet;
                        parameterslistBox.model = api.internal.recalbox.parameterslist;
                        parameterslistBox.parameterName = parameterName;
                        //to transfer focus to parameterslistBox
                        parameterslistBox.focus = true;
                    }

                    onSelect: {
                        //console.log("onSelect " + parameterName + " - index:" + str(index));
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

                    KeyNavigation.down: optSystemShaderBorderCoverage
                    // not visible if not libretro Core
                    visible : isLibretroCore
                }

                SliderOption {
                    id: optSystemShaderBorderCoverage

                    //property to manage parameter name
                    property string parameterName : prefix + ".shaderbordercoverage"

                    //property of SliderOption to set
                    label: qsTr("Overlay Shader Border Coverage") + api.tr
                    note: qsTr("Additional Border Coverage to manage shader above overlay as Mega Bezel") + api.tr
                    // in slider object
                    max : 15
                    min : 0
                    slidervalue : api.internal.recalbox.getIntParameter(parameterName,4)
                    // in text object
                    value: api.internal.recalbox.getIntParameter(parameterName,4) + "%"

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

                    KeyNavigation.down: optSystemShader
                    // not visible if not libretro Core
                    visible : isLibretroCore && (optSystemShaderSet.internalvalue === "megabezel_above_overlay" ? true : false)
                }

                MultivalueOption {
                    id: optSystemShader

                    //property to manage parameter name
                    property string parameterName : prefix + ".shaders"

                    label: qsTr("Shaders") + api.tr
                    note: qsTr("Set prefered Shader effect") + api.tr

                    value: api.internal.recalbox.parameterslist.currentName(parameterName)

                    currentIndex: api.internal.recalbox.parameterslist.currentIndex;
                    count: api.internal.recalbox.parameterslist.count;

                    onActivate: {
                        //to force update of list of parameters
                        api.internal.recalbox.parameterslist.currentName(parameterName);

                        //to customize Box display
                        parameterslistBox.firstlist_title = qsTr("Directory") + api.tr
                        parameterslistBox.firstlist_symbol = "\uf180"
                        parameterslistBox.secondlist_title = qsTr("Shader") + api.tr
                        parameterslistBox.secondlist_symbol = "\uf2df"
                        parameterslistBox.firstlist_minimum_width_purcentage = 0.23
                        parameterslistBox.secondlist_minimum_width_purcentage = 0.43
                        parameterslistBox.splitted_list = true;
                        parameterslistBox.has_picture = true;
                        parameterslistBox.max_listitem_displayed = 7;                        

                        //for callback by parameterslistBox
                        parameterslistBox.index = api.internal.recalbox.parameterslist.currentIndex;
                        parameterslistBox.model = api.internal.recalbox.parameterslist;
                        parameterslistBox.callerid = optSystemShader;
                        parameterslistBox.parameterName = parameterName;
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

                    KeyNavigation.down: optSystemOverlays
                    // not visible if not libretro Core
                    visible : isLibretroCore
                }
                ToggleOption {
                    id: optSystemOverlays

                    //property to manage parameter name
                    property string suffix: ".recalboxoverlays"
                    property string parameterName : prefix + suffix

                    label: qsTr("Set overlay") + api.tr
                    note: qsTr("Set overlay on this system") + api.tr

                    checked:{
                        if(prefix === system.shortName){
                            return api.internal.recalbox.getBoolParameter(parameterName, api.internal.recalbox.getBoolParameter("global" + suffix))
                        }
                        else{
                            return api.internal.recalbox.getBoolParameter(parameterName, api.internal.recalbox.getBoolParameter(system.shortName + suffix, api.internal.recalbox.getBoolParameter("global" + suffix)))
                        }
                    }
                    onCheckedChanged:{
                        if(checked !== api.internal.recalbox.getBoolParameter(parameterName, api.internal.recalbox.getBoolParameter(system.shortName + suffix, api.internal.recalbox.getBoolParameter("global" + suffix)))){
                            api.internal.recalbox.setBoolParameter(parameterName,checked);
                        }
                    }

                    onFocusChanged: container.onFocus(this)
                    KeyNavigation.down: optSystemGameRewind
                    // not visible if not libretro Core
                    visible : hasOverlaySupport
                }
                SectionTitle {
                    text: qsTr("Gameplay options") + api.tr
                    first: true
                    symbol: "\uf412"
                    // not visible if not libretro Core
                    visible : isLibretroCore
                }
                ToggleOption {
                    id: optSystemGameRewind

                    //property to manage parameter name
                    property string suffix: ".rewind"
                    property string parameterName : prefix + suffix

                    label: qsTr("Game rewind") + api.tr
                    note: qsTr("Set rewind for this system 'Only work with Retroarch'") + api.tr

                    checked:{
                        if(prefix === system.shortName){
                            return api.internal.recalbox.getBoolParameter(parameterName, api.internal.recalbox.getBoolParameter("global" + suffix))
                        }
                        else{
                            return api.internal.recalbox.getBoolParameter(parameterName, api.internal.recalbox.getBoolParameter(system.shortName + suffix, api.internal.recalbox.getBoolParameter("global" + suffix)))
                        }
                    }
                    onCheckedChanged:{
                        if(checked !== api.internal.recalbox.getBoolParameter(parameterName, api.internal.recalbox.getBoolParameter(system.shortName + suffix, api.internal.recalbox.getBoolParameter("global" + suffix)))){
                            api.internal.recalbox.setBoolParameter(parameterName,checked);
                        }
                    }

                    onFocusChanged: container.onFocus(this)
                    KeyNavigation.down: optSystemAutoSave
                    // not visible if not libretro Core
                    visible : isLibretroCore
                }
                ToggleOption {
                    id: optSystemAutoSave

                    //property to manage parameter name
                    property string suffix: ".autosave"
                    property string parameterName : prefix + suffix

                    label: qsTr("Auto save/load") + api.tr
                    note: qsTr("Set autosave/load savestate for this system") + api.tr

                    checked:{
                        if(prefix === system.shortName){
                            return api.internal.recalbox.getBoolParameter(parameterName, api.internal.recalbox.getBoolParameter("global" + suffix))
                        }
                        else{
                            return api.internal.recalbox.getBoolParameter(parameterName, api.internal.recalbox.getBoolParameter(system.shortName + suffix, api.internal.recalbox.getBoolParameter("global" + suffix)))
                        }
                    }
                    onCheckedChanged:{
                        if(checked !== api.internal.recalbox.getBoolParameter(parameterName, api.internal.recalbox.getBoolParameter(system.shortName + suffix, api.internal.recalbox.getBoolParameter("global" + suffix)))){
                            api.internal.recalbox.setBoolParameter(parameterName,checked);
                        }
                    }
                    onFocusChanged: container.onFocus(this)
                    KeyNavigation.down: emulatorButtons.count > 1 ? optAutoCoreSelection : emulatorButtons.itemAt(0)
                    // not visible if not libretro Core
                    visible : isLibretroCore
                }
                SectionTitle {
                    text: qsTr("Core options") + api.tr
                    first: true
                    symbol: "\uf179"
                }
                ToggleOption {
                    id: optAutoCoreSelection

                    //property to manage parameter name
                    property string suffix: ".autoselection"
                    property string parameterName : prefix + suffix

                    label: qsTr("Auto emulator/core selection") + api.tr
                    note: qsTr("To select the best ones to use from rom extensions (if needed)") + api.tr

                    checked:{
                        if(prefix === system.shortName){
                            return api.internal.recalbox.getBoolParameter(parameterName, api.internal.recalbox.getBoolParameter("global" + suffix))
                        }
                        else{
                            return api.internal.recalbox.getBoolParameter(parameterName, api.internal.recalbox.getBoolParameter(system.shortName + suffix, api.internal.recalbox.getBoolParameter("global" + suffix)))
                        }
                    }
                    onCheckedChanged:{
                        if(checked !== api.internal.recalbox.getBoolParameter(parameterName, api.internal.recalbox.getBoolParameter(system.shortName + suffix, api.internal.recalbox.getBoolParameter("global" + suffix)))){
                            api.internal.recalbox.setBoolParameter(parameterName,checked);
                        }
                    }

                    onFocusChanged: container.onFocus(this)
                    visible: emulatorButtons.count > 1 ? true : false
                    KeyNavigation.down: emulatorButtons.itemAt(0)
                }

                ButtonGroup  { id: radioGroup }
                
                Repeater {
                    id: emulatorButtons
                    model: system.emulatorsCount
                    SimpleButton {
                        // system.getCoreAt(index) not visible if not libretro Core for standalone just show emulator name
                        label: system.getNameAt(index) !== system.getCoreAt(index) ? system.getNameAt(index) + " " + system.getCoreAt(index) : system.getNameAt(index) ;
                        // '-' character between long name and version only if version is not empty
                        note: system.getCoreLongNameAt(index) + ((system.getCoreVersionAt(index) !== "") ? (" - " + system.getCoreVersionAt(index)) : "") + "\n" +
                              qsTr("rom extensions") + ": " + system.getCoreExtensionsAt(index);

                        onActivate: {
                            focus = true;
                            radioButton.checked = true;
                            api.internal.recalbox.setStringParameter(prefix + ".emulator",system.getNameAt(index));
                            api.internal.recalbox.setStringParameter(prefix + ".core",system.getCoreAt(index));
                        }
                        onFocusChanged: container.onFocus(this)
                        KeyNavigation.up: (index !== 0) ?  emulatorButtons.itemAt(index-1) : ((emulatorButtons.count > 1) ? optAutoCoreSelection : optSystemAutoSave)
                        KeyNavigation.down: (index < (emulatorButtons.count - 1)) ? emulatorButtons.itemAt(index+1) : optLaunchAdvancedEmulatorSettings

                        RadioButton {
                            id: radioButton

                            anchors.right: parent.right
                            anchors.rightMargin: horizontalPadding
                            anchors.verticalCenter: parent.verticalCenter
                            
                            checked: {
                                var emulator = api.internal.recalbox.getStringParameter(prefix + ".emulator");
                                var core = api.internal.recalbox.getStringParameter(prefix + ".core");
                                //console.log("index=",index);
                                //console.log("emulator=", emulator);
                                //console.log("core=", core);
                                //console.log("is default=",system.isDefaultEmulatorAt(index));
                                
                                if (((emulator === system.getNameAt(index)) && (core === system.getCoreAt(index))) ||
                                    (system.isDefaultEmulatorAt(index) && ((core === "") || (emulator === "")))){
                                     return true;
                                }
                                else return false;
                            }
                            onCheckedChanged: {
                                if(checked){
                                    emulator = system.getNameAt(index);
                                    core = system.getCoreAt(index);
                                    //console.log("index=",index);
                                    //console.log("emulator=", emulator);
                                    //console.log("core=", core);
                                    //console.log("is default=",system.isDefaultEmulatorAt(index));

                                    if(emulator === "libretro")
                                        isLibretroCore = true;
                                    else
                                        isLibretroCore = false;

                                    //check to confirm overlay support
                                    switch (emulator) {
                                      case 'libretro':
                                          hasOverlaySupport = true;
                                        break;
                                      case 'model2emu':
                                          hasOverlaySupport = true;
                                        break;
                                      case 'supermodel':
                                          hasOverlaySupport = true;
                                        break;
                                      case 'dolphin':
                                          hasOverlaySupport = true;
                                        break;
                                      case 'dolphin-triforce':
                                          hasOverlaySupport = true;
                                        break;
                                      case 'pcsx2':
                                          hasOverlaySupport = true;
                                        break;
                                      case 'xemu':
                                          hasOverlaySupport = true;
                                        break;
                                      default:
                                          hasOverlaySupport = false;
                                    }
                                }
                            }
                            ButtonGroup.group: radioGroup
                        }
                        Text {
                            id: pointer

                            anchors.right: radioButton.left
                            anchors.rightMargin: horizontalPadding
                            anchors.verticalCenter: parent.verticalCenter

                            color: themeColor.textValue
                            font.pixelSize: fontSize
                            font.family: globalFonts.ion

                            text : system.isDefaultEmulatorAt(index) ? ("(" + qsTr("Default") + ")" + api.tr): ""
                        }
                    }

                }
                SimpleButton {
                    id: optLaunchAdvancedEmulatorSettings
                    label: qsTr("Change Configuration for emulator selected") + api.tr
                    note: ""
                    pointerIcon: true
                    visible: false
                    onActivate: {
                        focus = true;
                        root.openEmulatorSettings(emulator);
                    }
                    // loader to check if QML file exists
                    Loader {
                        id: myLoader
                        // Attempt to load the file
                        source: typeof(emulator) !== "undefined" && emulator !== "" ? "emulatorsetting/" + emulator + "Settings.qml" : ""
                        onStatusChanged: {
                            if (status === Loader.Error) {
                                console.log("Failed to load component !");
                                // Handle the error, e.g., show a placeholder UI
                                parent.visible = false;
                            }
                        }
                        onLoaded: {
                            //console.log("Content loaded!");
                            // You can access properties and functions of the loaded item
                            if (item) {
                                //console.log("Object acessibled!");
                                parent.visible = true;
                            }
                        }
                    }
                    onFocusChanged: container.onFocus(this)
                    KeyNavigation.down: containerDeleteOverrideFile
                }
                //to be able to delete "override" file
                SimpleButton {
                    id: btnDeleteOverrideFile
                    visible: game ? (optGameInfo.override_exists === "true" ? true : false) : false
                    Rectangle {
                        id: containerDeleteOverrideFile
                        width: parent.width
                        height: parent.height
                        anchors.verticalCenter: parent.verticalCenter
                        anchors.horizontalCenter: parent.horizontalCenter
                        color: parent.focus ? "red" : themeColor.secondary
                        opacity : parent.focus ? 1 : 0.3
                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            anchors.horizontalCenter: parent.horizontalCenter
                            color: themeColor.textValue
                            font.pixelSize: vpx(30)
                            font.family: globalFonts.ion
                            text : "\uf4c5  " + qsTr("Delete override file and exit") + api.tr
                        }
                    }
                    onActivate: {
                        //to force change of focus
                        confirmDialog.callerid = "btnDeleteOverrideFile"
                        confirmDialog.focus = false;
                        confirmDialog.setSource("../../dialogs/Generic3ChoicesDialog.qml",
                                                { "title": prefix + " " + qsTr("Override file deletion") + api.tr,
                                                  "message": qsTr("Are you sure to delete \n'" + optGameInfo.override_file + "'\nfile and exit ?") + api.tr,
                                                  "symbol": "\uf4c5",
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
            if (confirmDialog.callerid === "btnDeleteOverrideFile"){
                if(typeof(game) !== "undefined"){
                    var romfile = game.files.get(0).path;
                    api.internal.system.run("mount -o remount,rw /; sleep 1; rm -f " + romfile + ".recalbox.conf" + " ; sleep 1; mount -o remount,ro /");
                    optGameInfo.override_exists = "false";
                    btnDeleteOverrideFile.visible = false;
                    optSystemGameRatio.focus = true;
                    root.close();
                }
            }
            content.focus = true;
        }
        function onCancel() {
            //do nothing
            content.focus = true;
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
            text: qsTr("Exit") + api.tr
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
