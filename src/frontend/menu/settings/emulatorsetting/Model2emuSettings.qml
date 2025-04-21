// Pegasus Frontend
//
// Created by Strodown 17/07/2023
//

import "../common"
import "qrc:/qmlutils" as PegasusUtils
import QtQuick 2.12
import QtQuick.Controls 2.12
import QtQuick.Window 2.12

FocusScope {
    id: root

    signal close

    width: parent.width
    height: parent.height
    
    anchors.fill: parent
    visible: 0 < (x + width) && x < Window.window.width

    enabled: focus

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
        text: qsTr("Advanced emulators settings > Model2emu") + api.tr
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
                    id: optModel2emuOption1
                    // set focus only on first item
                    focus: true

                    label: qsTr("Xinput") + api.tr
                    note: qsTr("Enable Xinput mode for controllers (auto mapping forced and manage vibration) \nelse Dinput will be used. (on change, need reboot)") + api.tr

                    checked: api.internal.recalbox.getBoolParameter("model2emu.xinput",false) //deactivated by default to use Dinput
                    onCheckedChanged: {
                        if(checked !== api.internal.recalbox.getBoolParameter("model2emu.xinput",false)){
                            api.internal.recalbox.setBoolParameter("model2emu.xinput",checked);
                            //need to reboot to take change into account !
                            needReboot = true;
                        }
                    }
                    onFocusChanged: container.onFocus(this)
                    KeyNavigation.down: optModel2emuOption2
                }
                ToggleOption {
                    id: optModel2emuOption2
                    label: qsTr("Fake Gouraud") + api.tr
                    note: qsTr("Tries to guess Per-vertex colour (gouraud) from the Model2 per-poly information (flat).") + api.tr

                    checked: api.internal.recalbox.getBoolParameter("model2emu.fakeGouraud")
                    onCheckedChanged: {
                        api.internal.recalbox.setBoolParameter("model2emu.fakeGouraud",checked);
                    }
                    onFocusChanged: container.onFocus(this)
                    KeyNavigation.down: optModel2emuOption21
                }
                ToggleOption {
                    id: optModel2emuOption21
                    label: qsTr("Bilinear Filtering") + api.tr
                    note: qsTr("Enables bilinear filtering of textures.") + api.tr

                    checked: api.internal.recalbox.getBoolParameter("model2emu.bilinearFiltering")
                    onCheckedChanged: {
                        api.internal.recalbox.setBoolParameter("model2emu.bilinearFiltering",checked);
                    }
                    onFocusChanged: container.onFocus(this)
                    KeyNavigation.down: optModel2emuOption3
                }
                ToggleOption {
                    id: optModel2emuOption3
                    label: qsTr("Trilinear Filtering") + api.tr
                    note: qsTr("Enables mipmap usage and trilinear filtering. (doesn’t work with some games, DoA for example)") + api.tr

                    checked: api.internal.recalbox.getBoolParameter("model2emu.trilinearFiltering")
                    onCheckedChanged: {
                        api.internal.recalbox.setBoolParameter("model2emu.trilinearFiltering",checked);
                    }
                    onFocusChanged: container.onFocus(this)
                    KeyNavigation.down: optModel2emuOption4
                }
                ToggleOption {
                    id: optModel2emuOption4
                    label: qsTr("Filter Tilemaps") + api.tr
                    note: qsTr("Enables bilinear filtering on tilemaps. (looks good, but can cause some stretch artifacts)") + api.tr

                    checked: api.internal.recalbox.getBoolParameter("model2emu.filterTilemaps")
                    onCheckedChanged: {
                        api.internal.recalbox.setBoolParameter("model2emu.filterTilemaps",checked);
                    }
                    onFocusChanged: container.onFocus(this)
                    KeyNavigation.down: optModel2emuOption5
                }
                ToggleOption {
                    id: optModel2emuOption5
                    label: qsTr("Force Managed") + api.tr
                    note: qsTr("Forces the DX driver to use Managed textures instead of Dynamic.") + api.tr

                    checked: api.internal.recalbox.getBoolParameter("model2emu.forceManaged")
                    onCheckedChanged: {
                        api.internal.recalbox.setBoolParameter("model2emu.forceManaged",checked);
                    }
                    onFocusChanged: container.onFocus(this)
                    KeyNavigation.down: optModel2emuOption6
                }
                ToggleOption {
                    id: optModel2emuOption6
                    label: qsTr("Enable MIP") + api.tr
                    note: qsTr("Enables Direct3D Automipmap generation.") + api.tr

                    checked: api.internal.recalbox.getBoolParameter("model2emu.enableMIP")
                    onCheckedChanged: {
                        api.internal.recalbox.setBoolParameter("model2emu.enableMIP",checked);
                    }
                    onFocusChanged: container.onFocus(this)
                    KeyNavigation.down: optModel2emuOption7
                }
                ToggleOption {
                    id: optModel2emuOption7
                    label: qsTr("Mesh Transparency") + api.tr
                    note: qsTr("Enabled meshed polygons for translucency.") + api.tr

                    checked: api.internal.recalbox.getBoolParameter("model2emu.meshTransparency")
                    onCheckedChanged: {
                        api.internal.recalbox.setBoolParameter("model2emu.meshTransparency",checked);
                    }
                    onFocusChanged: container.onFocus(this)
                    KeyNavigation.down: optModel2emuOption8
                }
                ToggleOption {
                    id: optModel2emuOption8
                    label: qsTr("Full screen anti-aliasing") + api.tr
                    note: qsTr("Enable full screen antialiasing in Direct3D.") + api.tr

                    checked: api.internal.recalbox.getBoolParameter("model2emu.fullscreenAA")
                    onCheckedChanged: {
                        api.internal.recalbox.setBoolParameter("model2emu.fullscreenAA",checked);
                    }
                    onFocusChanged: container.onFocus(this)
                    KeyNavigation.down: optModel2emuOption9
                }
                ToggleOption {
                    id: optModel2emuOption9
                    label: qsTr("Scanlines") + api.tr
                    note: qsTr("Enable default scanlines.") + api.tr

                    checked: api.internal.recalbox.getBoolParameter("model2emu.scanlines")
                    onCheckedChanged: {
                        api.internal.recalbox.setBoolParameter("model2emu.scanlines",checked);
                    }
                    onFocusChanged: container.onFocus(this)
                    KeyNavigation.down: optWineEngine
                }
                //****************************** section to manage wine version of this emulator*****************************************
                SectionTitle {
                    text: qsTr("Wine 'Bottle' configuration") + api.tr
                    first: true
                    symbol: "\uf26f"
                    symbolFontFamily: globalFonts.ion
                }
                MultivalueOption {
                    id: optWineEngine

                    //property to manage parameter name
                    property string parameterName : "model2emu.wine"

                    label: qsTr("Wine 'engine'") + api.tr
                    note: qsTr("Select the one to use, keep 'AUTO' if you don't know") + api.tr

                    value: api.internal.recalbox.parameterslist.currentName(parameterName)

                    currentIndex: api.internal.recalbox.parameterslist.currentIndex;
                    count: api.internal.recalbox.parameterslist.count;

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
                    }

                    onFocusChanged:{
                        if(focus){
                            api.internal.recalbox.parameterslist.currentName(parameterName);
                            currentIndex = api.internal.recalbox.parameterslist.currentIndex;
                            count = api.internal.recalbox.parameterslist.count;
                        }
                        container.onFocus(this)
                    }

                    KeyNavigation.down: optWineAppImage
                }
                MultivalueOption {
                    id: optWineAppImage

                    //property to manage parameter name
                    property string parameterName : "model2emu.wineappimage"

                    label: qsTr("Wine AppImage") + api.tr
                    note: qsTr("Select the one to use, keep 'AUTO' if you don't know") + api.tr

                    value: api.internal.recalbox.parameterslist.currentName(parameterName)

                    currentIndex: api.internal.recalbox.parameterslist.currentIndex;
                    count: api.internal.recalbox.parameterslist.count;

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
                    }

                    onFocusChanged:{
                        if(focus){
                            api.internal.recalbox.parameterslist.currentName(parameterName);
                            currentIndex = api.internal.recalbox.parameterslist.currentIndex;
                            count = api.internal.recalbox.parameterslist.count;
                        }
                        container.onFocus(this)
                    }

                    KeyNavigation.down: optWineArch
                }
                MultivalueOption {
                    id: optWineArch

                    //property to manage parameter name
                    property string parameterName : "model2emu.winearch"

                    label: qsTr("Wine architecture") + api.tr
                    note: qsTr("Select the one to use, keep 'AUTO' if you don't know") + api.tr

                    value: api.internal.recalbox.parameterslist.currentName(parameterName)

                    currentIndex: api.internal.recalbox.parameterslist.currentIndex;
                    count: api.internal.recalbox.parameterslist.count;

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
                    }

                    onFocusChanged:{
                        if(focus){
                            api.internal.recalbox.parameterslist.currentName(parameterName);
                            currentIndex = api.internal.recalbox.parameterslist.currentIndex;
                            count = api.internal.recalbox.parameterslist.count;
                        }
                        container.onFocus(this)
                    }

                    KeyNavigation.down: optWineVer
                }
                MultivalueOption {
                    id: optWineVer

                    //property to manage parameter name
                    property string parameterName : "model2emu.winver"

                    label: qsTr("Windows version") + api.tr
                    note: qsTr("Select the one to use, keep 'AUTO' if you don't know") + api.tr

                    value: api.internal.recalbox.parameterslist.currentName(parameterName)

                    currentIndex: api.internal.recalbox.parameterslist.currentIndex;
                    count: api.internal.recalbox.parameterslist.count;

                    onActivate: {
                        //for callback by parameterslistBox
                        parameterslistBox.parameterName = parameterName;
                        parameterslistBox.callerid = optWineVer;
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

                    KeyNavigation.down: btnCleanModel2emuBottles
                }
                // to clean/delete "bottle" before re-installation
                SimpleButton {
                    id: btnCleanModel2emuBottles
                    Rectangle {
                        id: containerValidateCleanModel2emuBottles
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
                            text : "\uf2ba  " + qsTr("Clean Model2emu wine bottle(s) (to re-install)") + api.tr
                        }
                    }
                    onActivate: {
                        //to force change of focus
                        confirmDialog.focus = false;
                        confirmDialog.setSource("../../../dialogs/Generic3ChoicesDialog.qml",
                                                { "title": "Model2emu Wine Bottles",
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
                    KeyNavigation.down: optWineRenderer
                }

                //****************************** section to manage wine version of this emulator*****************************************
                SectionTitle {
                    text: qsTr("Wine 'Software' configuration") + api.tr
                    first: true
                    symbol: "\uf26f"
                    symbolFontFamily: globalFonts.ion
                }
                MultivalueOption {
                    id: optWineRenderer

                    //property to manage parameter name
                    property string parameterName : "model2emu.winerenderer"

                    label: qsTr("Wine renderer") + api.tr
                    note: qsTr("Select the one to use, keep 'AUTO' if you don't know") + api.tr

                    value: api.internal.recalbox.parameterslist.currentName(parameterName)

                    currentIndex: api.internal.recalbox.parameterslist.currentIndex;
                    count: api.internal.recalbox.parameterslist.count;

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
                    }

                    onFocusChanged:{
                        if(focus){
                            api.internal.recalbox.parameterslist.currentName(parameterName);
                            currentIndex = api.internal.recalbox.parameterslist.currentIndex;
                            count = api.internal.recalbox.parameterslist.count;
                        }
                        container.onFocus(this)
                    }

                    KeyNavigation.down: optWineSoftRenderer
                }
                ToggleOption {
                    id: optWineSoftRenderer
                    label: qsTr("Wine Software renderer") + api.tr
                    note: qsTr("Enable software renderer for wine") + api.tr

                    checked: api.internal.recalbox.getBoolParameter("model2emu.winesoftrenderer")
                    onCheckedChanged: {
                        api.internal.recalbox.setBoolParameter("model2emu.winesoftrenderer",checked);
                    }
                    onFocusChanged: container.onFocus(this)
                    KeyNavigation.down: optWineAudioDriver
                }
                MultivalueOption {
                    id: optWineAudioDriver

                    //property to manage parameter name
                    property string parameterName : "model2emu.wineaudiodriver"

                    label: qsTr("Wine audio driver") + api.tr
                    note: qsTr("Select the one to use, keep 'AUTO' if you don't know") + api.tr

                    value: api.internal.recalbox.parameterslist.currentName(parameterName)

                    currentIndex: api.internal.recalbox.parameterslist.currentIndex;
                    count: api.internal.recalbox.parameterslist.count;

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
                }
                Item {
                    width: parent.width
                    height: implicitHeight + vpx(30)
                }
            }
        }
    }

    //loader to load confirm dialog
    Loader {
        id: confirmDialog
        anchors.fill: parent
        z:10
    }

    Connections {
        target: confirmDialog.item
        function onAccept() {
            //remove model2emu bottles
            if (!isDebugEnv()){
                api.internal.system.run("sleep 1 ; mount -o remount,rw /; rm -r /recalbox/.model2emu_* ; mount -o remount,ro /");
            }
            else{//for simulate and see more the spinner
                api.internal.system.run("sleep 5");
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
