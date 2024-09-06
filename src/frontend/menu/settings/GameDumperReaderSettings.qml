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
                    }

                    checked: api.internal.recalbox.getBoolParameter("dumpers.usbnes.enabled",false);
                    onCheckedChanged: {
                        if(checked !== api.internal.recalbox.getBoolParameter("dumpers.usbnes.enabled",false)){
                            api.internal.recalbox.setBoolParameter("dumpers.usbnes.enabled",checked);
                        }
                    }
                    symbol: "\uf29a"
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
                //NOT STABLE IN LINUX with USBNES :-(
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
                        first: true
                    }

                    checked: api.internal.recalbox.getBoolParameter("dumpers.retrode.enabled",false);
                    onCheckedChanged: {
                        if(checked !== api.internal.recalbox.getBoolParameter("dumpers.retrode.enabled",false)){
                            api.internal.recalbox.setBoolParameter("dumpers.retrode.enabled",checked);
                        }
                    }
                    symbol: "\uf29a"
                    onFocusChanged: container.onFocus(this)
                    //KeyNavigation.down: optUSBNESReadSave
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
