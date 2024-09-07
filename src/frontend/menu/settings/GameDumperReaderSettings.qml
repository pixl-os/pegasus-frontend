// Pegasus Frontend
// Created by BozoTheGeek 31/08/2024

import "common"
import "qrc:/qmlutils" as PegasusUtils
import QtQuick 2.12
import QtQuick.Window 2.12

FocusScope {
    id: root

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
                    note: qsTr("Move 'Save' from cartridge to play with it (if not already move)\n(Unfortunatelly we can't write USB-NES save securely from Linux - known bug)") + api.tr
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
                //NOT USED FINALLY, NOT STABLE IN LINUX with USBNES :-(
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
                    note: qsTr("Enable saving of rom information identified by the dumper\n(stored in your roms directory and named 'usb-nes.romlist.txt')") + api.tr
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
                    note: qsTr("Move 'Save' from cartridge to play with it (if not already move)\n(see also RETRODE documentation to know 'save support' by system)") + api.tr
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
                    KeyNavigation.down: optRETRODESaveReadOnly
                    visible: optRETRODEDumper.checked
                }
                ToggleOption {
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
                }
                ToggleOption {
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
                }
                ToggleOption {
                    id: optRETRODESaveROMInfo
                    //dumpers.retrode.romlist=0 by default
                    label: qsTr("Save rom information in file") + api.tr
                    note: qsTr("Enable saving of rom information identified by the dumper\n(stored in your roms directory and named 'retrode.romlist.txt')") + api.tr
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
                    KeyNavigation.down: optRETRODEdetectionDelay
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
                    //KeyNavigation.down: RFU
                    visible: optRETRODEDumper.checked && optRETRODEforceSystem.value != "auto"
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
