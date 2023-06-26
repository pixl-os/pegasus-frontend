// Pegasus Frontend
//
// Created by BozoTheGeek 10/05/2021
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
    
    anchors.fill: parent
    visible: 0 < (x + width) && x < Window.window.width

    enabled: focus

    property var system;
    // check if is a libretro emulator for dynamic entry
    property bool isLibretroCore
    // check if is model2emu for dynamic entry
    property bool isModel2Emu

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
        text: qsTr("Advanced emulators settings > ") + api.tr + system.name
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

                SectionTitle {
                    text: qsTr("Game screen") + api.tr
                    first: true
                    symbol: "\uf17f"
                }
                MultivalueOption {
                    id: optSystemGameRatio
                    // set focus only on first item
                    focus: true

                    //property to manage parameter name
                    property string parameterName : system.shortName + ".ratio"

                    label: qsTr("Game ratio") + api.tr
                    note: qsTr("Set ratio for this system (auto,4/3,16/9,16/10,etc...)") + api.tr

                    value: api.internal.recalbox.parameterslist.currentName(parameterName)
                    onActivate: {
                        //for callback by parameterslistBox
                        parameterslistBox.parameterName = parameterName;
                        parameterslistBox.callerid = optSystemGameRatio;
                        //to force update of list of parameters
                        api.internal.recalbox.parameterslist.currentName(parameterName);
                        parameterslistBox.model = api.internal.recalbox.parameterslist;
                        parameterslistBox.index = api.internal.recalbox.parameterslist.currentIndex;
                        //to transfer focus to parameterslistBox
                        parameterslistBox.focus = true;
                    }
                    onFocusChanged: container.onFocus(this)
                    KeyNavigation.down: isModel2Emu ? optModel2emuOption1 : optSystemSmoothGame
                }

//************************************************ libretro cores options *****************************************************************
                ToggleOption {
                    id: optSystemSmoothGame

                    label: qsTr("Smooth games") + api.tr
                    note: qsTr("Set smooth for this system") + api.tr

                    checked: api.internal.recalbox.getBoolParameter(system.shortName + ".smooth")
                    onCheckedChanged: {
                        api.internal.recalbox.setBoolParameter(system.shortName + ".smooth",checked);
                    }
                    onFocusChanged: container.onFocus(this)
                    KeyNavigation.down: optSystemShaderSet
                    // not visible if not libretro Core
                    visible : isLibretroCore
                }
                MultivalueOption {
                    id: optSystemShaderSet
                    //property to manage parameter name
                    property string parameterName : system.shortName + ".shaderset"

                    label: qsTr("Predefined shaders") + api.tr
                    note: qsTr("Set predefined Shader effect for this system") + api.tr

                    value: api.internal.recalbox.parameterslist.currentName(parameterName)
                    onActivate: {
                        //for callback by parameterslistBox
                        parameterslistBox.parameterName = parameterName;
                        parameterslistBox.callerid = optSystemShaderSet;
                        //to force update of list of parameters
                        api.internal.recalbox.parameterslist.currentName(parameterName);
                        parameterslistBox.model = api.internal.recalbox.parameterslist;
                        parameterslistBox.index = api.internal.recalbox.parameterslist.currentIndex;
                        //to transfer focus to parameterslistBox
                        parameterslistBox.focus = true;
                    }
                    onFocusChanged: container.onFocus(this)
                    KeyNavigation.down: optGlobalShader
                    // not visible if not libretro Core
                    visible : isLibretroCore
                }
                MultivalueOption {
                    id: optGlobalShader
                    //property to manage parameter name
                    property string parameterName : system.shortName + ".shaders"

                    label: qsTr("Shaders") + api.tr
                    note: qsTr("Set prefered Shader effect") + api.tr

                    value: api.internal.recalbox.parameterslist.currentName(parameterName)
                    onActivate: {
                        //for callback by parameterslistBox
                        parameterslistBox.parameterName = parameterName;
                        parameterslistBox.callerid = optGlobalShader;
                        //to force update of list of parameters
                        api.internal.recalbox.parameterslist.currentName(parameterName);
                        parameterslistBox.model = api.internal.recalbox.parameterslist;
                        parameterslistBox.index = api.internal.recalbox.parameterslist.currentIndex;
                        //to transfer focus to parameterslistBox
                        parameterslistBox.focus = true;
                    }
                    onFocusChanged: container.onFocus(this)
                    KeyNavigation.down: optSystemOverlays
                    // not visible if not libretro Core
                    visible : isLibretroCore
                }
                ToggleOption {
                    id: optSystemOverlays

                    label: qsTr("Set overlay") + api.tr
                    note: qsTr("Set overlay on this system") + api.tr

                    checked: api.internal.recalbox.getBoolParameter(system.shortName + ".recalboxoverlays")
                    onCheckedChanged: {
                        api.internal.recalbox.setBoolParameter(system.shortName + ".recalboxoverlays",checked);
                    }
                    onFocusChanged: container.onFocus(this)
                    KeyNavigation.down: optSystemGameRewind
                    // not visible if not libretro Core
                    visible : isLibretroCore
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

                    label: qsTr("Game rewind") + api.tr
                    note: qsTr("Set rewind for this system 'Only work with Retroarch'") + api.tr

                    checked: api.internal.recalbox.getBoolParameter(system.shortName + ".rewind")
                    onCheckedChanged: {
                        api.internal.recalbox.setBoolParameter(system.shortName + ".rewind",checked);
                    }
                    onFocusChanged: container.onFocus(this)
                    KeyNavigation.down: optSystemAutoSave
                    // not visible if not libretro Core
                    visible : isLibretroCore
                }
                ToggleOption {
                    id: optSystemAutoSave

                    label: qsTr("Auto save/load") + api.tr
                    note: qsTr("Set autosave/load savestate for this system") + api.tr

                    checked: api.internal.recalbox.getBoolParameter(system.shortName + ".autosave")
                    onCheckedChanged: {
                        api.internal.recalbox.setBoolParameter(system.shortName + ".autosave",checked);
                    }
                    onFocusChanged: container.onFocus(this)
                    // not visible if not libretro Core
                    visible : isLibretroCore
                }
//************************************************ Model 2 emulator options *****************************************************************
                ToggleOption {
                    id: optModel2emuOption1
                    label: qsTr("fakeGouraud") + api.tr
                    note: qsTr("Tries to guess Per-vertex colour (gouraud) from the Model2 per-poly information (flat)") + api.tr

                    checked: api.internal.recalbox.getBoolParameter("model2emu.fakeGouraud")
                    onCheckedChanged: {
                        api.internal.recalbox.setBoolParameter("model2emu.fakeGouraud",checked);
                    }
                    onFocusChanged: container.onFocus(this)
                    // not visible if not model 2 emulator
                    visible : isModel2Emu
                }
//************************************************ emulators/cores selections *****************************************************************
                SectionTitle {
                    text: qsTr("Core options") + api.tr
                    first: true
                    symbol: "\uf179"
                }
                
                ButtonGroup  { id: radioGroup }
                
                Repeater {
                    id: emulatorButtons
                    model: system.emulatorsCount
                    SimpleButton {
                        // system.getCoreAt(index) not visible if not libretro Core for standalone just show emulator name
                        label: system.getNameAt(index) !== system.getCoreAt(index) ? system.getNameAt(index) + " " + system.getCoreAt(index) : system.getNameAt(index) ;
                        // '-' character between long name and version only if version is not empty
                        note: system.getCoreLongNameAt(index) + ((system.getCoreVersionAt(index) !== "") ? (" - " + system.getCoreVersionAt(index)) : "") ;

                        onActivate: {
                            //console.log("onActivate");
                            focus = true;
                            api.internal.recalbox.setStringParameter(system.shortName + ".emulator",system.getNameAt(index));
                            api.internal.recalbox.setStringParameter(system.shortName + ".core",system.getCoreAt(index));
                            radioButton.checked = true;
                        }
                        
                        onFocusChanged: container.onFocus(this)
                        KeyNavigation.up: (index !== 0) ?  emulatorButtons.itemAt(index-1) : (isModel2Emu ? optModel2emuOption1 : optSystemAutoSave)
                        KeyNavigation.down: (index < emulatorButtons.count) ? emulatorButtons.itemAt(index+1) : emulatorButtons.itemAt(emulatorButtons.count - 1)
                        
                        RadioButton {
                            id: radioButton

                            anchors.right: parent.right
                            anchors.rightMargin: horizontalPadding
                            anchors.verticalCenter: parent.verticalCenter
                            

                            onCheckedChanged: {
                                //console.log("onCheckedChanged");
                                api.internal.recalbox.setStringParameter(system.shortName + ".emulator",system.getNameAt(index));
                                api.internal.recalbox.setStringParameter(system.shortName + ".core",system.getCoreAt(index));
                                // check is libretro for filter menu
                                if(system.getNameAt(index) === "libretro")
                                    isLibretroCore = true
                                else
                                    isLibretroCore = false
                                //console.log("isLibretroCore =", isLibretroCore);

                                // check is model2emu for filter menu
                                if(system.getNameAt(index) === "model2emu")
                                    isModel2Emu = true
                                else
                                    isModel2Emu = false
                                //console.log("isModel2Emu =", isModel2Emu);

                            }

                            checked: {
                                var emulator = api.internal.recalbox.getStringParameter(system.shortName + ".emulator");
                                var core = api.internal.recalbox.getStringParameter(system.shortName + ".core");
                                //console.log("index =",index);
                                //console.log("emulator =", emulator);
                                //console.log("core =", core);
                                //console.log("is default =",system.isDefaultEmulatorAt(index));
                                //console.log("system.getNameAt(index) =", system.getNameAt(index));
                                //console.log("system.getCoreAt(index) =", system.getCoreAt(index));

                                if (((emulator === system.getNameAt(index)) && (core === system.getCoreAt(index))) ||
                                   (system.isDefaultEmulatorAt(index) && ((core === "") || (emulator === "")))){
                                    return true;
                                }
                                else {
                                    return false;
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
            //to update index of parameterlist QAbstractList
            api.internal.recalbox.parameterslist.currentIndex = index;
            //to force update of display of selected value
            callerid.value = api.internal.recalbox.parameterslist.currentName(parameterName);
        }
    }
}
