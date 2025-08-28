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
    signal openProtonConfiguration

    width: parent.width
    height: parent.height
    
//    anchors.fill: parent
    visible: 0 < (x + width) && x < Window.window.width

    enabled: focus

    property bool launchedAsDialogBox: false

    property var game
    property var system
    //to manage overloading
    property string prefix : game ? "override.teknoparrot" : "teknoparrot"
    //to manage better title in screen ScreenHeader (if we want to change it during loading)
    property string titleHeader: game ? game.title +  " > TeknoParrot" :
        (system ? system.name + " > TeknoParrot" :
         qsTr("Advanced emulators settings > TeknoParrot") + api.tr)

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
                    text: qsTr("'Game' configuration") + api.tr
                    first: true
                    symbol: "\uf26f" //TO DO: fusee ?!
                    symbolFontFamily: globalFonts.ion
                }
                ToggleOption {
                    id: optTeknoparrotOption1
                    // set focus only on first item
                    focus: true

                    label: qsTr("Xinput") + api.tr
                    note: qsTr("Enable Xinput mode for controllers (auto mapping forced and manage vibration) \nelse Dinput will be used. (on change, need reboot)") + api.tr

                    checked: api.internal.recalbox.getBoolParameter(prefix + ".xinput",false) //deactivated by default to use Dinput
                    onCheckedChanged: {
                        if(checked !== api.internal.recalbox.getBoolParameter(prefix + ".xinput",false)){
                            api.internal.recalbox.setBoolParameter(prefix + ".xinput",checked);
                        }
                    }
                    onFocusChanged: container.onFocus(this)
                    KeyNavigation.down: optTeknoparrotOption2
                }
                MultivalueOption {
                    id: optTeknoparrotOption2

                    //property to manage parameter name
                    property string parameterName : prefix + ".windowed"

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

                    KeyNavigation.down: optTeknoparrotOption7
                }
                MultivalueOption {
                    id: optTeknoparrotOption7

                    //property to manage parameter name
                    property string parameterName : prefix + ".screen.resolution"

                    label: qsTr("Screen/Window resolution") + api.tr
                    note: qsTr("To adpat resolution in full screen/windowed") + api.tr

                    value: api.internal.recalbox.parameterslist.currentName(parameterName)

                    currentIndex: api.internal.recalbox.parameterslist.currentIndex;
                    count: api.internal.recalbox.parameterslist.count;

                    onActivate: {
                        //for callback by parameterslistBox
                        parameterslistBox.parameterName = parameterName;
                        parameterslistBox.callerid = optTeknoparrotOption7;
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

                    checked: api.internal.recalbox.getBoolParameter(prefix + ".framelimiter", true)
                    onCheckedChanged: {
                        api.internal.recalbox.setBoolParameter(prefix + ".framelimiter",checked);
                    }
                    onFocusChanged: container.onFocus(this)
                    KeyNavigation.down: optTeknoparrotOption31
                }
                ToggleOption {
                    id: optTeknoparrotOption31
                    label: qsTr("Force Free Play") + api.tr
                    note: qsTr("Activate Free Play automatically if manageable by emulator") + api.tr

                    checked: api.internal.recalbox.getBoolParameter(prefix + ".force.freeplay", true)
                    onCheckedChanged: {
                        api.internal.recalbox.setBoolParameter(prefix + ".force.freeplay",checked);
                    }
                    onFocusChanged: container.onFocus(this)
                    KeyNavigation.down: optTeknoparrotOption32
                }
                MultivalueOption {
                    id: optTeknoparrotOption32

                    //property to manage parameter name
                    property string parameterName : prefix + ".versus.controller.mapping"

                    label: qsTr("'Versus' games controller mapping") + api.tr
                    note: qsTr("To adapt mappings to your habit/controller/panel") + api.tr

                    value: api.internal.recalbox.parameterslist.currentName(parameterName)

                    currentIndex: api.internal.recalbox.parameterslist.currentIndex;
                    count: api.internal.recalbox.parameterslist.count;

                    onActivate: {
                        //to force update of list of parameters
                        api.internal.recalbox.parameterslist.currentName(parameterName);
                        parameterslistBox.parameterName = parameterName;

                        //to customize Box display
                        parameterslistBox.has_picture = true;
                        parameterslistBox.firstlist_minimum_width_purcentage = 0.55;
                        parameterslistBox.firstlist_maximum_width_purcentage = 0.55;
                        parameterslistBox.box_maximum_width = 800;
                        parameterslistBox.box_minimum_width = 800;
                        parameterslistBox.has_picture = true;
                        parameterslistBox.max_listitem_displayed = 5;

                        //to force update of list of parameters
                        parameterslistBox.callerid = optTeknoparrotOption32;
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

                    KeyNavigation.down: optTeknoparrotOption6
                }
                ToggleOption {
                    id: optTeknoparrotOption6
                    label: qsTr("Rotate 'Tate' Game") + api.tr
                    note: qsTr("To rotate gamez from Open Parrot") + api.tr

                    checked: api.internal.recalbox.getBoolParameter(prefix + ".rotate.tate", false)
                    onCheckedChanged: {
                        api.internal.recalbox.setBoolParameter(prefix + ".rotate.tate",checked);
                    }
                    onFocusChanged: container.onFocus(this)
                    KeyNavigation.down: optTeknoparrotOption4
                }
                SectionTitle {
                    text: qsTr("'Advanced' configuration") + api.tr
                    first: true
                    symbol: "\uf26f" //TO DO: fusee ?!
                    symbolFontFamily: globalFonts.ion
                }
                ToggleOption {
                    id: optTeknoparrotOption4
                    label: qsTr("Launch UI first") + api.tr
                    note: qsTr("Start UI first to be able to change/verify conf if needed.\n(need mouse/keyboard to navigate)") + api.tr

                    checked: api.internal.recalbox.getBoolParameter(prefix + ".launch.ui", false)
                    onCheckedChanged: {
                        api.internal.recalbox.setBoolParameter(prefix + ".launch.ui",checked);
                    }
                    onFocusChanged: container.onFocus(this)
                    KeyNavigation.down: optTeknoparrotOption8
                }
                ToggleOption {
                    id: optTeknoparrotOption8
                    label: qsTr("Use UI Game Profile(s) if exists") + api.tr
                    note: qsTr("To let you use your own Game/Controller Settings.\n(for testing usually)") + api.tr

                    checked: api.internal.recalbox.getBoolParameter(prefix + ".keep.userprofile.from.ui", false)
                    onCheckedChanged: {
                        api.internal.recalbox.setBoolParameter(prefix + ".keep.userprofile.from.ui",checked);
                    }
                    onFocusChanged: container.onFocus(this)
                    KeyNavigation.down: optTeknoparrotOption81
                }
                ToggleOption {
                    id: optTeknoparrotOption81
                    visible: (optTeknoparrotOption8.checked === true) ? false : true
                    label: qsTr("Overwrite UI Game Profile(s) by pixL") + api.tr
                    note: qsTr("To have generated Game/Controller Settings from UI\n(as default)") + api.tr

                    checked: api.internal.recalbox.getBoolParameter(prefix + ".save.userprofile.for.ui", true)
                    onCheckedChanged: {
                        api.internal.recalbox.setBoolParameter(prefix + ".save.userprofile.for.ui",checked);
                    }
                    onFocusChanged: container.onFocus(this)
                    KeyNavigation.down: optTeknoparrotOption5
                }
                ToggleOption {
                    id: optTeknoparrotOption5
                    label: qsTr("Show launcher") + api.tr
                    note: qsTr("To show launcher console from Open Parrot") + api.tr

                    checked: api.internal.recalbox.getBoolParameter(prefix + ".show.launcher", false)
                    onCheckedChanged: {
                        api.internal.recalbox.setBoolParameter(prefix + ".show.launcher",checked);
                    }
                    onFocusChanged: container.onFocus(this)
                    KeyNavigation.down: optTeknoparrotRunnerType
                }
                SectionTitle {
                    text: qsTr("'Runner' configuration") + api.tr
                    first: true
                    symbol: "\uf26f" //TO DO: fusee ?!
                    symbolFontFamily: globalFonts.ion
                }

                MultivalueOption {
                    id: optTeknoparrotRunnerType

                    //property to manage parameter name
                    property string parameterName : prefix + ".runner.type"

                    label: qsTr("'Runner' type used to launch TeknoParrot") + api.tr
                    note: qsTr("To manage different cases (if needed)") + api.tr

                    value: api.internal.recalbox.parameterslist.currentName(parameterName)

                    currentIndex: api.internal.recalbox.parameterslist.currentIndex;
                    count: api.internal.recalbox.parameterslist.count;

                    onActivate: {
                        //for callback by parameterslistBox
                        parameterslistBox.parameterName = parameterName;
                        parameterslistBox.callerid = optTeknoparrotRunnerType;
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

                    KeyNavigation.down: optWineConfiguration
                }
                SimpleButton {
                    id: optWineConfiguration
                    visible: optTeknoparrotRunnerType.value === "Wine" ? true : false
                    label: qsTr("'Wine' configuration") + api.tr
                    onActivate: {
                        focus = true;
                        root.openWineConfiguration();
                    }
                    onFocusChanged: container.onFocus(this)
                    //pointer moved in SimpleButton desactived on default
                    pointerIcon: true
                    KeyNavigation.down: optProtonConfiguration
                }
                SimpleButton {
                    id: optProtonConfiguration
                    visible: optTeknoparrotRunnerType.value === "Proton" ? true : false
                    label: qsTr("'Proton' configuration") + api.tr
                    onActivate: {
                        focus = true;
                        root.openProtonConfiguration();
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
          //console.log("onSelect - callerid.parameterName : " + callerid.parameterName);
          //console.log("onSelect - index : " + index.toString());
            callerid.keypressed = true;
            //to use the good parameter
            api.internal.recalbox.parameterslist.currentName(callerid.parameterName);
            //to update index of parameterlist QAbstractList
            api.internal.recalbox.parameterslist.currentIndex = index;
            //to force update of display of selected value
            callerid.value = api.internal.recalbox.parameterslist.currentName(callerid.parameterName);
          //console.log("onSelect - callerid.value : " + callerid.value);
            callerid.currentIndex = api.internal.recalbox.parameterslist.currentIndex;
          //console.log("onSelect - callerid.currentIndex : " + callerid.currentIndex.toString());
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
