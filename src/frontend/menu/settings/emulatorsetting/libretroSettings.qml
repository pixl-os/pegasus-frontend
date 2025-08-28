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
    
//    anchors.fill: parent
    visible: 0 < (x + width) && x < Window.window.width

    enabled: focus

    property bool launchedAsDialogBox: false

    property var game
    property var system
    //to manage overloading
    property string prefix : game ? "override.retroarch" : "retroarch"
    property string prefixglobal : game ? "override.global" : "global"
    //to manage better title in screen ScreenHeader (if we want to change it during loading)
    property string titleHeader : game ? game.title +  " > Retroarch" :
                                  (system ? system.name + " > Retroarch" :
                                   qsTr("Advanced emulators settings > Retroarch") + api.tr)


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
    Flickable {
        id: container

        width: content.width
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: header.bottom
        anchors.bottom: parent.bottom

        contentWidth: content.width
        contentHeight: content.height

        clip: launchedAsDialogBox

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

                SectionTitle {
                    text: qsTr("Game screen") + api.tr
                    first: true
                    symbol: "\uf17f"
                }
                ToggleOption {
                    id: optPixelPerfect
                    // set focus only on first item
                    focus: true

                    label: qsTr("Pixel perfect") + api.tr
                    note: qsTr("Once enabled, your screen will be cropped, and you will have a pixel perfect image.") + api.tr

                    checked: api.internal.recalbox.getBoolParameter(prefixglobal + ".integerscale")
                    onCheckedChanged: {
                        api.internal.recalbox.setBoolParameter(prefixglobal + ".integerscale",checked);
                    }
                    onFocusChanged: container.onFocus(this)
                    KeyNavigation.down: optSmoothGame
                }
                ToggleOption {
                    id: optSmoothGame

                    label: qsTr("Smooth games") + api.tr
                    note: qsTr("Set smooth for all Retroarch core.") + api.tr

                    checked: api.internal.recalbox.getBoolParameter(prefixglobal + ".smooth")
                    onCheckedChanged: {
                        api.internal.recalbox.setBoolParameter(prefixglobal + ".smooth",checked);
                    }
                    onFocusChanged: container.onFocus(this)
                    KeyNavigation.down: optGameRewind
                }
                SectionTitle {
                    text: qsTr("Gameplay options") + api.tr
                    first: true
                    symbol: "\uf412"
                }
                ToggleOption {
                    id: optGameRewind

                    label: qsTr("Game rewind") + api.tr
                    note: qsTr("Set rewind for all Retroarch core.") + api.tr

                    checked: api.internal.recalbox.getBoolParameter(prefixglobal + ".rewind")
                    onCheckedChanged: {
                        api.internal.recalbox.setBoolParameter(prefixglobal + ".rewind",checked);
                    }
                    onFocusChanged: container.onFocus(this)
                    KeyNavigation.down: optAutoSave
                }
                ToggleOption {
                    id: optAutoSave

                    label: qsTr("Auto save/load") + api.tr
                    note: qsTr("Set autosave/load savestate for all Retroarch core.") + api.tr

                    checked: api.internal.recalbox.getBoolParameter(prefixglobal + ".autosave")
                    onCheckedChanged: {
                        api.internal.recalbox.setBoolParameter(prefixglobal + ".autosave",checked);
                    }
                    onFocusChanged: container.onFocus(this)
                    KeyNavigation.down: optSwapmenucontrol
                }
                SectionTitle {
                    text: qsTr("Menu options") + api.tr
                    first: true
                    symbol: "\uf412"
                }
                ToggleOption {
                    id: optSwapmenucontrol

                    label: qsTr("Swap menu validate") + api.tr
                    note: qsTr("Swap buttons for OK/Cancel in retroarch menu only.") + api.tr

                    checked: api.internal.recalbox.getBoolParameter(prefix + ".swap.menu.button")
                    onCheckedChanged: {
                        api.internal.recalbox.setBoolParameter(prefix + ".swap.menu.button",checked);
                    }
                    onFocusChanged: container.onFocus(this)
                    KeyNavigation.down: optLoadContentAnimation
                }
                ToggleOption {
                    id: optLoadContentAnimation

                    label: qsTr("Load content animations") + api.tr
                    note: qsTr("Show a little animation on launch game.") + api.tr

                    checked: api.internal.recalbox.getBoolParameter(prefix + ".load.content.animation")
                    onCheckedChanged: {
                        api.internal.recalbox.setBoolParameter(prefix + ".load.content.animation",checked);
                    }
                    onFocusChanged: container.onFocus(this)
                    KeyNavigation.down: optOzoneMenucolorTheme
                }
                MultivalueOption {
                    id: optOzoneMenucolorTheme
                    //property to manage parameter name
                    property string parameterName : prefix + ".color.theme.menu"

                    label: qsTr("Change menu color") + api.tr
                    note: qsTr("Change color of retroarch interface.") + api.tr

                    value: api.internal.recalbox.parameterslist.currentName(parameterName)

                    currentIndex: api.internal.recalbox.parameterslist.currentIndex;
                    count: api.internal.recalbox.parameterslist.count;

                    onActivate: {
                        //for callback by parameterslistBox
                        parameterslistBox.parameterName = parameterName;
                        parameterslistBox.callerid = optOzoneMenucolorTheme;
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
