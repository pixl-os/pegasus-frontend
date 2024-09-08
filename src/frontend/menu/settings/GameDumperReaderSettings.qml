// Pegasus Frontend
// Created by BozoTheGeek 31/08/2024

import "common"
import "qrc:/qmlutils" as PegasusUtils
import QtQuick 2.12
import QtQuick.Window 2.12

FocusScope {
    id: root

    //loader to load confirm dialog
    Loader {
        id: confirmDialog
        anchors.fill: parent
        z:10
    }

    Connections {
        target: confirmDialog.item
        function onAccept() {
            //update configuration in RETRODE.CFG
            //to see spinner
            api.internal.system.run("sleep 2");
            //to force change of focus
            var mountpoint = api.internal.system.run("cat /tmp/RETRODE.mountpoint 2>/dev/null | tr -d '\\n' | tr -d '\\r'");
            //console.log("RETRODE mountpoint : ", mountpoint)
            if(mountpoint.includes("/usb")) {
                //copy RETRODE.CFG first in tmp to modify it
                api.internal.system.run("cp " + mountpoint + "/RETRODE.CFG /tmp/RETRODE.CFG");
                //update HID MODE (with comments ;-)
                api.internal.system.run("sed -i 's/\\[HIDMode\\].*/\\[HIDMode\\] " + api.internal.recalbox.getIntParameter("dumpers.retrode.hid.mode",0) + " ; 0: Off; 1: 4Joy+Mouse; 2: 2Joy; 3: KB; 4: iCade/g' /tmp/RETRODE.CFG");
                //update Blink controllers
                api.internal.system.run("sed -i 's/\\[blinkControllers\\].*/\\[blinkControllers\\] " + api.internal.recalbox.getIntParameter("dumpers.retrode.blink.controllers",1) + "/g' /tmp/RETRODE.CFG");
                //update Detection Delay (with comments ;-)
                api.internal.system.run("sed -i 's/\\[detectionDelay\\].*/\\[detectionDelay\\] " + api.internal.recalbox.getIntParameter("dumpers.retrode.detection.delay",5) + "  ; how long to wait after cart insertion\\/removal/g' /tmp/RETRODE.CFG");
                //update Force System
                api.internal.system.run("sed -i 's/\\[forceSystem\\].*/\\[forceSystem\\] " + api.internal.recalbox.getStringParameter("dumpers.retrode.force.system","auto") + "/g' /tmp/RETRODE.CFG");
                //update Force Size
                api.internal.system.run("sed -i 's/\\[forceSize\\].*/\\[forceSize\\] " + api.internal.recalbox.getIntParameter("dumpers.retrode.force.size",0) + "/g' /tmp/RETRODE.CFG");
                //update Force Mapper
                api.internal.system.run("sed -i 's/\\[forceMapper\\].*/\\[forceMapper\\] " + api.internal.recalbox.getIntParameter("dumpers.retrode.force.mapper",0) + "/g' /tmp/RETRODE.CFG");
                //recopy now from TMP to mountPoint and sync to be sure about udpate ;-)
                api.internal.system.run("dd if=/tmp/RETRODE.CFG of=" + mountpoint + "/RETRODE.CFG");
            }
            content.focus = true;
        }
        function onCancel() {
            //do nothing
            content.focus = true;
        }
    }

    signal close

    anchors.fill: parent
    enabled: focus
    visible: 0 < (x + width) && x < Window.window.width

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
        text: qsTr("Games > Game Reader/Dumper settings") + api.tr
        z: 2
    }

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

                width: root.width * 0.7
                height: implicitHeight

                Item {
                    width: parent.width
                    height: implicitHeight + vpx(30)
                }

                ToggleOption {
                    id: optUSBNESDumper
                    //dumpers.usbnes.enabled=0
                    // set focus only on first item
                    focus: true
                    SectionTitle {
                        text: qsTr("USB-NES dumper") + api.tr
                        first: true
                        symbol: "\uf25c"
                        symbolFontFamily: globalFonts.awesome
                        symbolFontSize: vpx(40)
                    }

                    checked: api.internal.recalbox.getBoolParameter("dumpers.usbnes.enabled",false);
                    onCheckedChanged: {
                        if(checked !== api.internal.recalbox.getBoolParameter("dumpers.usbnes.enabled",false)){
                            api.internal.recalbox.setBoolParameter("dumpers.usbnes.enabled",checked);
                        }
                    }
                    onFocusChanged: container.onFocus(this)
                    KeyNavigation.down: optUSBNESMoveSave
                }
                ToggleOption {
                    id: optUSBNESMoveSave
                    //dumpers.usbnes.movesave=0 by default
                    label: qsTr("Cartridge SRAM in your saves") + api.tr
                    note: qsTr("Move 'Save' from cartridge to play with it (if not already move)\n(Unfortunatelly retroach/usb-nes are not compatible to update SRAM directly)") + api.tr
                    checked: api.internal.recalbox.getBoolParameter("dumpers.usbnes.movesave",false);
                    onCheckedChanged: {
                        if(checked !== api.internal.recalbox.getBoolParameter("dumpers.usbnes.movesave",false)){
                            api.internal.recalbox.setBoolParameter("dumpers.usbnes.movesave",checked);
                        }
                    }
                    onFocusChanged: container.onFocus(this)
                    KeyNavigation.down: optUSBNESSaveDump
                    visible: optUSBNESDumper.checked
                }
                ToggleOption {
                    id: optUSBNESSaveDump
                    //dumpers.usbnes.savedump=0 by default
                    label: qsTr("Cartridge ROM in your dumps") + api.tr
                    note: qsTr("Copy and rename 'Rom' from cartridge to keep it\n(will be in 'dumps' share directory)") + api.tr
                    checked: api.internal.recalbox.getBoolParameter("dumpers.usbnes.savedump",false);
                    onCheckedChanged: {
                        if(checked !== api.internal.recalbox.getBoolParameter("dumpers.usbnes.savedump",false)){
                            api.internal.recalbox.setBoolParameter("dumpers.usbnes.savedump",checked);
                        }
                    }
                    onFocusChanged: container.onFocus(this)
                    KeyNavigation.down: optUSBNESSaveROMInfo
                    visible: optUSBNESDumper.checked
                }
                //NOT USED FINALLY, NOT STABLE IN LINUX with USBNES and RETROACH is not really able like for RETRODE :-(
                /*ToggleOption {
                    id: optUSBNESWriteSave
                    //dumpers.usbnes.writesave=0 by default
                    label: qsTr("'Save' file writing to cartridge") + api.tr
                    note: qsTr("Enable write of save to cartridge\n(USB-NES should connected/resetted after configuration change)") + api.tr
                    checked: api.internal.recalbox.getBoolParameter("dumpers.usbnes.writesave",false);
                    onCheckedChanged: {
                        if(checked !== api.internal.recalbox.getBoolParameter("dumpers.usbnes.writesave",false)){
                            api.internal.recalbox.setBoolParameter("dumpers.usbnes.writesave",checked);
                        }
                    }
                    onFocusChanged: container.onFocus(this)
                    KeyNavigation.down: optUSBNESSaveROMInfo
                    visible: optUSBNESDumper.checked
                }*/
                ToggleOption {
                    id: optUSBNESSaveROMInfo
                    //dumpers.usbnes.romlist=0 by default
                    label: qsTr("Save rom information in file") + api.tr
                    note: qsTr("Enable saving of rom information identified by the dumper\n(stored in your roms directory and named 'usb-nes.romlist.csv')") + api.tr
                    checked: api.internal.recalbox.getBoolParameter("dumpers.usbnes.romlist",false);
                    onCheckedChanged: {
                        if(checked !== api.internal.recalbox.getBoolParameter("dumpers.usbnes.romlist",false)){
                            api.internal.recalbox.setBoolParameter("dumpers.usbnes.romlist",checked);
                        }
                    }
                    onFocusChanged: container.onFocus(this)
                    KeyNavigation.down: optRETRODEDumper
                    visible: optUSBNESDumper.checked
                }
                ToggleOption {
                    id: optRETRODEDumper
                    //dumpers.retrode.enabled=0
                    SectionTitle {
                        text: qsTr("RETRODE dumper") + api.tr
                        symbol: "\uf25e / \uf26b"
                        symbolFontFamily: globalFonts.awesome
                        symbolFontSize: vpx(40)
                        first: true
                    }

                    checked: api.internal.recalbox.getBoolParameter("dumpers.retrode.enabled",false);
                    onCheckedChanged: {
                        if(checked !== api.internal.recalbox.getBoolParameter("dumpers.retrode.enabled",false)){
                            api.internal.recalbox.setBoolParameter("dumpers.retrode.enabled",checked);
                        }
                    }
                    onFocusChanged: container.onFocus(this)
                    KeyNavigation.down: optRETRODEMoveSave
                }
                ToggleOption {
                    id: optRETRODEMoveSave
                    //dumpers.retrode.movesave=0 by default
                    label: qsTr("Cartridge SRAM in your saves") + api.tr
                    note: qsTr("Move 'Save' from cartridge to play with it (if not already move)\n(Unfortunatelly retroach/retrode are not compatible to update SRAM directly)") + api.tr
                    checked: api.internal.recalbox.getBoolParameter("dumpers.retrode.movesave",false);
                    onCheckedChanged: {
                        if(checked !== api.internal.recalbox.getBoolParameter("dumpers.retrode.movesave",false)){
                            api.internal.recalbox.setBoolParameter("dumpers.retrode.movesave",checked);
                        }
                    }
                    onFocusChanged: container.onFocus(this)
                    KeyNavigation.down: optRETRODESaveDump
                    visible: optRETRODEDumper.checked
                }
                ToggleOption {
                    id: optRETRODESaveDump
                    //dumpers.retrode.savedump=0 by default
                    label: qsTr("Cartridge ROM in your dumps") + api.tr
                    note: qsTr("Copy and rename 'Rom' from cartridge to keep it\n(will be in 'dumps' share directory)") + api.tr
                    checked: api.internal.recalbox.getBoolParameter("dumpers.retrode.savedump",false);
                    onCheckedChanged: {
                        if(checked !== api.internal.recalbox.getBoolParameter("dumpers.retrode.savedump",false)){
                            api.internal.recalbox.setBoolParameter("dumpers.retrode.savedump",checked);
                        }
                    }
                    onFocusChanged: container.onFocus(this)
                    KeyNavigation.down: optRETRODESaveROMInfo
                    visible: optRETRODEDumper.checked
                }
                //RFU: paremeter finally not use (retroarch can't manage sav directly from cartrideg (need to rename to .srm and can't focus one file :()
                /*ToggleOption {
                    id: optRETRODESaveReadOnly
                    //dumpers.retrode.save.readonly=1 by default
                    label: qsTr("Cartridge SRAM readonly") + api.tr
                    note: qsTr("Deactivate readonly to save directly in cartridge\n(see also RETRODE documentation to know 'save support' by system)") + api.tr
                    checked: api.internal.recalbox.getBoolParameter("dumpers.retrode.save.readonly",true);
                    onCheckedChanged: {
                        if(checked !== api.internal.recalbox.getBoolParameter("dumpers.retrode.save.readonly",true)){
                            api.internal.recalbox.setBoolParameter("dumpers.retrode.save.readonly",checked);
                        }
                    }
                    onFocusChanged: container.onFocus(this)
                    KeyNavigation.down: optRETRODEfilenameChecksum
                    visible: optRETRODEDumper.checked && !optRETRODEMoveSave.checked
                }*/
                //RFU: no usage of this feature for the moment
                /*ToggleOption {
                    id: optRETRODEfilenameChecksum
                    //dumpers.retrode.filename.checksum=1 by default
                    label: qsTr("Checksum/Game Code in file name") + api.tr
                    note: qsTr("Add 4-digit checksum or game code in rom file name\n(see RETRODE documentation for more details on this parameter)") + api.tr
                    checked: api.internal.recalbox.getBoolParameter("dumpers.retrode.filename.checksum",true);
                    onCheckedChanged: {
                        if(checked !== api.internal.recalbox.getBoolParameter("dumpers.retrode.filename.checksum",true)){
                            api.internal.recalbox.setBoolParameter("dumpers.retrode.filename.checksum",checked);
                        }
                    }
                    onFocusChanged: container.onFocus(this)
                    KeyNavigation.down: optRETRODESaveROMInfo
                    visible: optRETRODEDumper.checked
                }*/
                ToggleOption {
                    id: optRETRODESaveROMInfo
                    //dumpers.retrode.romlist=0 by default
                    label: qsTr("Save rom information in file") + api.tr
                    note: qsTr("Enable saving of rom information identified by the dumper\n(stored in your roms directory and named 'retrode.romlist.csv')") + api.tr
                    checked: api.internal.recalbox.getBoolParameter("dumpers.retrode.romlist",false);
                    onCheckedChanged: {
                        if(checked !== api.internal.recalbox.getBoolParameter("dumpers.retrode.romlist",false)){
                            api.internal.recalbox.setBoolParameter("dumpers.retrode.romlist",checked);
                        }
                    }
                    onFocusChanged: container.onFocus(this)
                    KeyNavigation.down: optRETRODEHidMode
                    visible: optRETRODEDumper.checked
                }
                MultivalueOption {
                    id: optRETRODEHidMode

                    //property to manage parameter name
                    property string parameterName :"dumpers.retrode.hid.mode"

                    label: qsTr("Controllers mode") + api.tr
                    note: qsTr("Select a mode to manage Retrode controller ports\n(see RETRODE documentation for more details on this parameter)") + api.tr

                    value: api.internal.recalbox.parameterslist.currentName(parameterName)

                    currentIndex: api.internal.recalbox.parameterslist.currentIndex;
                    count: api.internal.recalbox.parameterslist.count;

                    onActivate: {
                        //for callback by parameterslistBox
                        parameterslistBox.parameterName = parameterName;
                        parameterslistBox.callerid = optRETRODEHidMode;
                        //to force update of list of parameters
                        api.internal.recalbox.parameterslist.currentName(parameterName);
                        parameterslistBox.model = api.internal.recalbox.parameterslist;
                        parameterslistBox.index = api.internal.recalbox.parameterslist.currentIndex;
                        //to transfer focus to parameterslistBox
                        parameterslistBox.focus = true;
                    }

                    onValueChanged: {
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
                    visible: optRETRODEDumper.checked
                    KeyNavigation.down: optRETRODEBlinkControllers
                }
                ToggleOption {
                    id: optRETRODEBlinkControllers
                    //dumpers.retrode.blink.controllers=1 by default
                    label: qsTr("Blink controllers") + api.tr
                    note: qsTr("to blink green led when we press on gamepad controls (activated by default)\n(see RETRODE documentation for more details on this parameter)") + api.tr
                    checked: api.internal.recalbox.getBoolParameter("dumpers.retrode.blink.controllers",true);
                    onCheckedChanged: {
                        if(checked !== api.internal.recalbox.getBoolParameter("dumpers.retrode.blink.controllers",true)){
                            api.internal.recalbox.setBoolParameter("dumpers.retrode.blink.controllers",checked);
                        }
                    }
                    onFocusChanged: container.onFocus(this)
                    KeyNavigation.down: optRETRODEdetectionDelay
                    visible: optRETRODEDumper.checked
                }
                SliderOption {
                    id: optRETRODEdetectionDelay

                    //property to manage parameter name
                    property string parameterName : "dumpers.retrode.detection.delay"

                    //property of SliderOption to set
                    label: qsTr("Detection delay") + api.tr
                    note: qsTr("Specifies the lag between insertion/removal and the triggering of re-detection routine\n(set to 5 usually)") + api.tr
                    // in slider object
                    max : 255
                    min : 0
                    slidervalue: api.internal.recalbox.getIntParameter(parameterName,5);
                    value: api.internal.recalbox.getIntParameter(parameterName,5)

                    Keys.onLeftPressed: {
                        api.internal.recalbox.setIntParameter(parameterName,slidervalue);
                        value = slidervalue;
                        sfxNav.play();
                    }
                    Keys.onRightPressed: {
                        api.internal.recalbox.setIntParameter(parameterName,slidervalue);
                        value = slidervalue;
                        sfxNav.play();
                    }

                    onFocusChanged: container.onFocus(this)
                    visible: optRETRODEDumper.checked
                    KeyNavigation.down: optRETRODEforceSystem
                }
                MultivalueOption {
                    id: optRETRODEforceSystem

                    //property to manage parameter name
                    property string parameterName :"dumpers.retrode.force.system"

                    label: qsTr("Force System") + api.tr
                    note: qsTr("Select a system to force rom detection or leave 'auto' (default value)") + api.tr

                    value: api.internal.recalbox.parameterslist.currentName(parameterName)

                    currentIndex: api.internal.recalbox.parameterslist.currentIndex;
                    count: api.internal.recalbox.parameterslist.count;

                    onActivate: {
                        //for callback by parameterslistBox
                        parameterslistBox.parameterName = parameterName;
                        parameterslistBox.callerid = optRETRODEforceSystem;
                        //to force update of list of parameters
                        api.internal.recalbox.parameterslist.currentName(parameterName);
                        parameterslistBox.model = api.internal.recalbox.parameterslist;
                        parameterslistBox.index = api.internal.recalbox.parameterslist.currentIndex;
                        //to transfer focus to parameterslistBox
                        parameterslistBox.focus = true;
                    }

                    onValueChanged: {
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
                    visible: optRETRODEDumper.checked
                    KeyNavigation.down: optRETRODEforceSize
                }
                MultivalueOption {
                    id: optRETRODEforceSize

                    //property to manage parameter name
                    property string parameterName :"dumpers.retrode.force.size"

                    label: qsTr("Force Size") + api.tr
                    note: qsTr("Select a size to force rom size or leave 'auto' (default value)\n(see RETRODE documentation for more details on this parameter)") + api.tr

                    value: api.internal.recalbox.parameterslist.currentName(parameterName)

                    currentIndex: api.internal.recalbox.parameterslist.currentIndex;
                    count: api.internal.recalbox.parameterslist.count;

                    onActivate: {
                        //for callback by parameterslistBox
                        parameterslistBox.parameterName = parameterName;
                        parameterslistBox.callerid = optRETRODEforceSize;
                        //to force update of list of parameters
                        api.internal.recalbox.parameterslist.currentName(parameterName);
                        parameterslistBox.model = api.internal.recalbox.parameterslist;
                        parameterslistBox.index = api.internal.recalbox.parameterslist.currentIndex;
                        //to transfer focus to parameterslistBox
                        parameterslistBox.focus = true;
                    }

                    onValueChanged: {
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
                    visible: optRETRODEDumper.checked && optRETRODEforceSystem.value != "auto"
                    KeyNavigation.down: optRETRODEforceMapper
                }
                ToggleOption {
                    id: optRETRODEforceMapper
                    //dumpers.retrode.force.mapper=0 by default
                    label: qsTr("Force Mapper") + api.tr
                    note: qsTr("to select alternative mapper (0 is default value)\n(see RETRODE documentation for more details on this parameter)") + api.tr
                    checked: api.internal.recalbox.getBoolParameter("dumpers.retrode.force.mapper",false);
                    onCheckedChanged: {
                        if(checked !== api.internal.recalbox.getBoolParameter("dumpers.retrode.force.mapper",false)){
                            api.internal.recalbox.setBoolParameter("dumpers.retrode.force.mapper",checked);
                        }
                    }
                    onFocusChanged: container.onFocus(this)
                    KeyNavigation.down: optRETRODESettingsApply
                    visible: optRETRODEDumper.checked && optRETRODEforceSystem.value != "auto"
                }
                // to apply settings
                SimpleButton {
                    id: optRETRODESettingsApply
                    Rectangle {
                        id: containerValidate
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
                            text : "\uf2ba  " + qsTr("Update RETRODE.CFG (apply changes)") + api.tr
                        }
                    }
                    onActivate: {
                        //force save in recalbox.conf file before to execute script
                        api.internal.recalbox.saveParameters();
                        //check if retrode available

                        //to force change of focus
                        var mountpoint = api.internal.system.run("cat /tmp/RETRODE.mountpoint 2>/dev/null | tr -d '\\n' | tr -d '\\r'");
                        //console.log("RETRODE mountpoint : ", mountpoint)
                        if(mountpoint.includes("/usb")) {
                            confirmDialog.focus = false;
                            confirmDialog.setSource("../../dialogs/Generic3ChoicesDialog.qml",
                                                    { "title": "RETRODE",
                                                      "message": qsTr("Are you ready to change settings of your device now ?<br>(After, it's adviced to re-plug retrode device to fully apply new settings)") + api.tr,
                                                      "symbol": "",
                                                      "symbolfont" : global.fonts.awesome,
                                                      "firstchoice": qsTr("Yes") + api.tr,
                                                      "secondchoice": "",
                                                      "thirdchoice": qsTr("No") + api.tr});
                            //to force change of focus
                            confirmDialog.focus = true;
                        }
                        else{
                            //no retrode connected
                            //add dialogBox to alert about the issue
                            genericMessage.setSource("../../dialogs/GenericContinueDialog.qml",
                                                     { "title": qsTr("RETRODE not connected ?"), "message": qsTr("Sorry, we can't update now the configuration<br>Your RETRODE device seems not connected to your pixL !")});
                            genericMessage.focus = true;
                        }
                    }
                    onFocusChanged: container.onFocus(this)
                    visible: optRETRODEDumper.checked
                }

                Item {
                    width: parent.width
                    height: implicitHeight + vpx(30)
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

        //reuse same model
        model: api.internal.recalbox.parameterslist.model
        //to use index from parameterlist QAbstractList
        index: api.internal.recalbox.parameterslist.currentIndex

        onClose: content.focus = true
        onSelect: {
            callerid.keypressed = true;
            //to use the good parameter
            api.internal.recalbox.parameterslist.currentName(callerid.parameterName);
            //to update index of parameterlist QAbstractList
            api.internal.recalbox.parameterslist.currentIndex = index;
            //to force update of display of selected value
            callerid.value = api.internal.recalbox.parameterslist.currentName(callerid.parameterName);
            callerid.currentIndex = api.internal.recalbox.parameterslist.currentIndex;
            callerid.count = api.internal.recalbox.parameterslist.count;
        }
    }
}
