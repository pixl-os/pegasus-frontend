// Pegasus Frontend
//
// Created by BozoTheGeek 10/05/2021
//

import "common"
import "qrc:/qmlutils" as PegasusUtils
import QtQuick 2.15
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
        text: qsTr("Games > Advanced Emulator > " + system.name ) + api.tr
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
                    text: qsTr("Game Screen") + api.tr
                    first: true
                }
                MultivalueOption {
                    id: optSystemGameRatio
                    // set focus only on first item
                    focus: true

                    //property to manage parameter name
                    property string parameterName : system.shortName + ".ratio"

                    label: qsTr("Game Ratio") + api.tr
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
                    //KeyNavigation.up: optSystemEmulator
                    KeyNavigation.down: optSystemSmoothGame
                }
                ToggleOption {
                    id: optSystemSmoothGame

                    label: qsTr("Smooth Games") + api.tr
                    note: qsTr("Set smooth for this system") + api.tr

                    checked: api.internal.recalbox.getBoolParameter(system.shortName + ".smooth")
                    onCheckedChanged: {
                        focus = true;
                        api.internal.recalbox.setBoolParameter(system.shortName + ".smooth",checked);
                    }
                    onFocusChanged: container.onFocus(this)
                    KeyNavigation.up: optSystemGameRatio
                    KeyNavigation.down: optSystemShader
                }
                MultivalueOption {
                    id: optSystemShader
                    //property to manage parameter name
                    property string parameterName : system.shortName + ".shaderset"

                    label: qsTr("Shaders") + api.tr
                    note: qsTr("Set prefered Shader effect for this system") + api.tr

                    value: api.internal.recalbox.parameterslist.currentName(parameterName)
                    onActivate: {
                        //for callback by parameterslistBox
                        parameterslistBox.parameterName = parameterName;
                        parameterslistBox.callerid = optSystemShader;
                        //to force update of list of parameters
                        api.internal.recalbox.parameterslist.currentName(parameterName);
                        parameterslistBox.model = api.internal.recalbox.parameterslist;
                        parameterslistBox.index = api.internal.recalbox.parameterslist.currentIndex;
                        //to transfer focus to parameterslistBox
                        parameterslistBox.focus = true;
                    }
                    onFocusChanged: container.onFocus(this)
                    KeyNavigation.up: optSystemSmoothGame
                    KeyNavigation.down: optSystemGameRewind
                }
                SectionTitle {
                    text: qsTr("Gameplay Option") + api.tr
                    first: true
                }
                ToggleOption {
                    id: optSystemGameRewind

                    label: qsTr("Game Rewind") + api.tr
                    note: qsTr("Set rewind for this system 'Only work with Retroarch' ") + api.tr

                    checked: api.internal.recalbox.getBoolParameter(system.shortName + ".rewind")
                    onCheckedChanged: {
                        focus = true;
                        api.internal.recalbox.setBoolParameter(system.shortName + ".rewind",checked);
                    }
                    onFocusChanged: container.onFocus(this)
                    KeyNavigation.up: optSystemShader
                    KeyNavigation.down: optSystemAutoSave
                }
                ToggleOption {
                    id: optSystemAutoSave

                    label: qsTr("Auto Save/load") + api.tr
                    note: qsTr("Set autosave/load savestate for this system") + api.tr

                    checked: api.internal.recalbox.getBoolParameter(system.shortName + ".autosave")
                    onCheckedChanged: {
                        focus = true;
                        api.internal.recalbox.setBoolParameter(system.shortName + ".autosave",checked);
                    }
                    onFocusChanged: container.onFocus(this)
                    KeyNavigation.up: optSystemGameRewind
                }
                SectionTitle {
                    text: qsTr("Core options") + api.tr
                    first: true
                }
                
                ButtonGroup  { id: radioGroup }
                
                Repeater {
                    id: emulatorButtons
                    model: system.emulatorsCount
                    SimpleButton {
                        label: qsTr(system.GetNameAt(index) + " " + system.GetCoreAt(index)) + api.tr

                        onActivate: {
                            focus = true;
                            radioButton.checked = true;
                            api.internal.recalbox.setStringParameter(system.shortName + ".emulator",system.GetNameAt(index));
                            api.internal.recalbox.setStringParameter(system.shortName + ".core",system.GetCoreAt(index));
                        }
                        
                        onFocusChanged: container.onFocus(this)
                        KeyNavigation.up: (index != 0) ?  emulatorButtons.itemAt(index-1) : optSystemAutoSave
                        KeyNavigation.down: (index < emulatorButtons.count) ? emulatorButtons.itemAt(index+1) : emulatorButtons.itemAt(emulatorButtons.count - 1)
                        
                        RadioButton {
                            id: radioButton

                            anchors.right: parent.right
                            anchors.rightMargin: horizontalPadding
                            anchors.verticalCenter: parent.verticalCenter
                            
                            checked: {
                                var emulator = api.internal.recalbox.getStringParameter(system.shortName + ".emulator");
                                var core = api.internal.recalbox.getStringParameter(system.shortName + ".core");
                                console.log("index=",index);
                                console.log("emulator=", emulator);
                                console.log("core=", core);
                                console.log("is default=",system.isDefaultEmulatorAt(index));
                                
                                if ((emulator == system.GetNameAt(index)) && (core == system.GetCoreAt(index))){
                                    return true;
                                }
                                else if (system.isDefaultEmulatorAt(index) && ((core == "") || (emulator == ""))){
                                    return true;
                                }
                                else return false;
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
