// Pegasus Frontend
//
// Created by BozoTheGeek 26/05/2025 (from previous Model2emuSettings to be able to manage additional submenu)
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

    width: parent.width
    height: parent.height
    
//    anchors.fill: parent
    visible: 0 < (x + width) && x < Window.window.width

    enabled: focus

    property bool launchedAsDialogBox: false

    property var game
    property var system
    //to manage overloading
    property string prefix : game ? "override.model2emu" : "model2emu"
    //to manage better title in screen ScreenHeader (if we want to change it during loading)
    property string titleHeader: game ? game.title +  " > Model2emu" :
        (system ? system.name + " > Model2emu" :
         qsTr("Advanced emulators settings > Model2emu") + api.tr)

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

                ToggleOption {
                    id: optModel2emuOption1
                    // set focus only on first item
                    focus: true

                    label: qsTr("Xinput") + api.tr
                    note: qsTr("Enable Xinput mode for controllers (auto mapping forced and manage vibration) \nelse Dinput will be used. (on change, need reboot)") + api.tr

                    checked: api.internal.recalbox.getBoolParameter(prefix + ".xinput",false) //deactivated by default to use Dinput
                    onCheckedChanged: {
                        if(checked !== api.internal.recalbox.getBoolParameter(prefix + ".xinput",false)){
                            api.internal.recalbox.setBoolParameter(prefix + ".xinput",checked);
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

                    checked: api.internal.recalbox.getBoolParameter(prefix + ".fakeGouraud")
                    onCheckedChanged: {
                        api.internal.recalbox.setBoolParameter(prefix + ".fakeGouraud",checked);
                    }
                    onFocusChanged: container.onFocus(this)
                    KeyNavigation.down: optModel2emuOption21
                }
                ToggleOption {
                    id: optModel2emuOption21
                    label: qsTr("Bilinear Filtering") + api.tr
                    note: qsTr("Enables bilinear filtering of textures.") + api.tr

                    checked: api.internal.recalbox.getBoolParameter(prefix + ".bilinearFiltering")
                    onCheckedChanged: {
                        api.internal.recalbox.setBoolParameter(prefix + ".bilinearFiltering",checked);
                    }
                    onFocusChanged: container.onFocus(this)
                    KeyNavigation.down: optModel2emuOption3
                }
                ToggleOption {
                    id: optModel2emuOption3
                    label: qsTr("Trilinear Filtering") + api.tr
                    note: qsTr("Enables mipmap usage and trilinear filtering. (doesn’t work with some games, DoA for example)") + api.tr

                    checked: api.internal.recalbox.getBoolParameter(prefix + ".trilinearFiltering")
                    onCheckedChanged: {
                        api.internal.recalbox.setBoolParameter(prefix + ".trilinearFiltering",checked);
                    }
                    onFocusChanged: container.onFocus(this)
                    KeyNavigation.down: optModel2emuOption4
                }
                ToggleOption {
                    id: optModel2emuOption4
                    label: qsTr("Filter Tilemaps") + api.tr
                    note: qsTr("Enables bilinear filtering on tilemaps. (looks good, but can cause some stretch artifacts)") + api.tr

                    checked: api.internal.recalbox.getBoolParameter(prefix + ".filterTilemaps")
                    onCheckedChanged: {
                        api.internal.recalbox.setBoolParameter(prefix + ".filterTilemaps",checked);
                    }
                    onFocusChanged: container.onFocus(this)
                    KeyNavigation.down: optModel2emuOption5
                }
                ToggleOption {
                    id: optModel2emuOption5
                    label: qsTr("Force Managed") + api.tr
                    note: qsTr("Forces the DX driver to use Managed textures instead of Dynamic.") + api.tr

                    checked: api.internal.recalbox.getBoolParameter(prefix + ".forceManaged")
                    onCheckedChanged: {
                        api.internal.recalbox.setBoolParameter(prefix + ".forceManaged",checked);
                    }
                    onFocusChanged: container.onFocus(this)
                    KeyNavigation.down: optModel2emuOption6
                }
                ToggleOption {
                    id: optModel2emuOption6
                    label: qsTr("Enable MIP") + api.tr
                    note: qsTr("Enables Direct3D Automipmap generation.") + api.tr

                    checked: api.internal.recalbox.getBoolParameter(prefix + ".enableMIP")
                    onCheckedChanged: {
                        api.internal.recalbox.setBoolParameter(prefix + ".enableMIP",checked);
                    }
                    onFocusChanged: container.onFocus(this)
                    KeyNavigation.down: optModel2emuOption7
                }
                ToggleOption {
                    id: optModel2emuOption7
                    label: qsTr("Mesh Transparency") + api.tr
                    note: qsTr("Enabled meshed polygons for translucency.") + api.tr

                    checked: api.internal.recalbox.getBoolParameter(prefix + ".meshTransparency")
                    onCheckedChanged: {
                        api.internal.recalbox.setBoolParameter(prefix + ".meshTransparency",checked);
                    }
                    onFocusChanged: container.onFocus(this)
                    KeyNavigation.down: optModel2emuOption8
                }
                ToggleOption {
                    id: optModel2emuOption8
                    label: qsTr("Full screen anti-aliasing") + api.tr
                    note: qsTr("Enable full screen antialiasing in Direct3D.") + api.tr

                    checked: api.internal.recalbox.getBoolParameter(prefix + ".fullscreenAA")
                    onCheckedChanged: {
                        api.internal.recalbox.setBoolParameter(prefix + ".fullscreenAA",checked);
                    }
                    onFocusChanged: container.onFocus(this)
                    KeyNavigation.down: optModel2emuOption9
                }
                ToggleOption {
                    id: optModel2emuOption9
                    label: qsTr("Scanlines") + api.tr
                    note: qsTr("Enable default scanlines.") + api.tr

                    checked: api.internal.recalbox.getBoolParameter(prefix + ".scanlines")
                    onCheckedChanged: {
                        api.internal.recalbox.setBoolParameter(prefix + ".scanlines",checked);
                    }
                    onFocusChanged: container.onFocus(this)
                    KeyNavigation.down: optwineConfiguration
                }
                SimpleButton {
                    id: optwineConfiguration
                    label: qsTr("Wine configuration") + api.tr
                    onActivate: {
                        focus = true;
                        root.openWineConfiguration();
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
