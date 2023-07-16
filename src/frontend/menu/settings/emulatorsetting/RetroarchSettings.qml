// Pegasus Frontend
//
// Created by BozoTheGeek 10/05/2021
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
        text: qsTr("Advanced emulators settings > Retroarch") + api.tr
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
                ToggleOption {
                    id: optPixelPerfect
                    // set focus only on first item
                    focus: true

                    label: qsTr("Pixel perfect") + api.tr
                    note: qsTr("Once enabled, your screen will be cropped, and you will have a pixel perfect image.") + api.tr

                    checked: api.internal.recalbox.getBoolParameter("global.integerscale")
                    onCheckedChanged: {
                        api.internal.recalbox.setBoolParameter("global.integerscale",checked);
                    }
                    onFocusChanged: container.onFocus(this)
                    KeyNavigation.down: optSmoothGame
                }
                ToggleOption {
                    id: optSmoothGame

                    label: qsTr("Smooth games") + api.tr
                    note: qsTr("Set smooth for all Retroarch core.") + api.tr

                    checked: api.internal.recalbox.getBoolParameter("global.smooth")
                    onCheckedChanged: {
                        api.internal.recalbox.setBoolParameter("global.smooth",checked);
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

                    checked: api.internal.recalbox.getBoolParameter("global.rewind")
                    onCheckedChanged: {
                        api.internal.recalbox.setBoolParameter("global.rewind",checked);
                    }
                    onFocusChanged: container.onFocus(this)
                    KeyNavigation.down: optAutoSave
                }
                ToggleOption {
                    id: optAutoSave

                    label: qsTr("Auto save/load") + api.tr
                    note: qsTr("Set autosave/load savestate for all Retroarch core.") + api.tr

                    checked: api.internal.recalbox.getBoolParameter("global.autosave")
                    onCheckedChanged: {
                        api.internal.recalbox.setBoolParameter("global.autosave",checked);
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

                    checked: api.internal.recalbox.getBoolParameter("retroarch.swap.menu.button")
                    onCheckedChanged: {
                        api.internal.recalbox.setBoolParameter("retroarch.swap.menu.button",checked);
                    }
                    onFocusChanged: container.onFocus(this)
                    KeyNavigation.down: optLoadContentAnimation
                }
                ToggleOption {
                    id: optLoadContentAnimation

                    label: qsTr("Load content animations") + api.tr
                    note: qsTr("Show a little animation on launch game.") + api.tr

                    checked: api.internal.recalbox.getBoolParameter("retroarch.load.content.animation")
                    onCheckedChanged: {
                        api.internal.recalbox.setBoolParameter("retroarch.load.content.animation",checked);
                    }
                    onFocusChanged: container.onFocus(this)
                    KeyNavigation.down: optOzoneMenucolorTheme
                }
                MultivalueOption {
                    id: optOzoneMenucolorTheme
                    //property to manage parameter name
                    property string parameterName : "retroarch.color.theme.menu"

                    label: qsTr("Change menu color") + api.tr
                    note: qsTr("Change color of retroarch interface.") + api.tr

                    value: api.internal.recalbox.parameterslist.currentName(parameterName)
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
                    onFocusChanged: container.onFocus(this)
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
