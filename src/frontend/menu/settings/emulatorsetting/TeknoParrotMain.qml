// Pegasus Frontend
//
// Created by BozoTheGeek 26/05/2025
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
        text: qsTr("Advanced emulators settings > TeknoParrot") + api.tr
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
                    id: optTeknoparrotOption1
                    // set focus only on first item
                    focus: true

                    label: qsTr("Xinput") + api.tr
                    note: qsTr("Enable Xinput mode for controllers (auto mapping forced and manage vibration) \nelse Dinput will be used. (on change, need reboot)") + api.tr

                    checked: api.internal.recalbox.getBoolParameter("teknoparrot.xinput",false) //deactivated by default to use Dinput
                    onCheckedChanged: {
                        if(checked !== api.internal.recalbox.getBoolParameter("teknoparrot.xinput",false)){
                            api.internal.recalbox.setBoolParameter("teknoparrot.xinput",checked);
                        }
                    }
                    onFocusChanged: container.onFocus(this)
                    KeyNavigation.down: optTeknoparrotOption2
                }
                MultivalueOption {
                    id: optTeknoparrotOption2

                    //property to manage parameter name
                    property string parameterName : "teknoparrot.windowed"

                    label: qsTr("Windowed") + api.tr
                    note: qsTr("Start as 'windowed' is adviced for some GPU/Game") + api.tr

                    value: api.internal.recalbox.parameterslist.currentName(parameterName)

                    currentIndex: api.internal.recalbox.parameterslist.currentIndex;
                    count: api.internal.recalbox.parameterslist.count;

                    onActivate: {
                        //for callback by parameterslistBox
                        parameterslistBox.parameterName = parameterName;
                        parameterslistBox.callerid = optTeknoparrotOption2;
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

                    KeyNavigation.down: optTeknoparrotOption3
                }
                ToggleOption {
                    id: optTeknoparrotOption3
                    label: qsTr("Frame limiter") + api.tr
                    note: qsTr("Activated to prevent games running too fast") + api.tr

                    checked: api.internal.recalbox.getBoolParameter("teknoparrot.framelimiter", true)
                    onCheckedChanged: {
                        api.internal.recalbox.setBoolParameter("teknoparrot.framelimiter",checked);
                    }
                    onFocusChanged: container.onFocus(this)
                    KeyNavigation.down: optTeknoparrotOption4
                }
                ToggleOption {
                    id: optTeknoparrotOption4
                    label: qsTr("Launch UI first") + api.tr
                    note: qsTr("Start UI first to be able to change/verify conf if needed.\n(need mouse/keyboard to navigate)") + api.tr

                    checked: api.internal.recalbox.getBoolParameter("teknoparrot.launch.ui", false)
                    onCheckedChanged: {
                        api.internal.recalbox.setBoolParameter("teknoparrot.launch.ui",checked);
                    }
                    onFocusChanged: container.onFocus(this)
                    KeyNavigation.down: optTeknoparrotOption5
                }
                ToggleOption {
                    id: optTeknoparrotOption5
                    label: qsTr("Show launcher") + api.tr
                    note: qsTr("To show launcher console from Open Parrot") + api.tr

                    checked: api.internal.recalbox.getBoolParameter("teknoparrot.show.launcher", false)
                    onCheckedChanged: {
                        api.internal.recalbox.setBoolParameter("teknoparrot.show.launcher",checked);
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
