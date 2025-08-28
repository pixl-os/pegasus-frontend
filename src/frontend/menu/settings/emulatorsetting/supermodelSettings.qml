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
    property string prefix : game ? "override.supermodel" : "supermodel"
    //to manage better title in screen ScreenHeader (if we want to change it during loading)
    property string titleHeader: game ? game.title +  " > Supermodel" :
        (system ? system.name + " > Supermodel" :
         qsTr("Advanced emulators settings > Supermodel") + api.tr)

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
                MultivalueOption {
                    id: optInternalResolution
                    // set focus only on first item
                    focus: true

                    //property to manage parameter name
                    property string parameterName : prefix + ".resolution"

                    label: qsTr("Internal Resolution") + api.tr
                    note: qsTr("Controls the rendering resolution. \nA high resolution greatly improves visual quality, \nBut cause issues in certain games.") + api.tr

                    value: api.internal.recalbox.parameterslist.currentName(parameterName)

                    currentIndex: api.internal.recalbox.parameterslist.currentIndex;
                    count: api.internal.recalbox.parameterslist.count;

                    onActivate: {
                        //for callback by parameterslistBox
                        parameterslistBox.parameterName = parameterName;
                        parameterslistBox.callerid = optInternalResolution;
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

                    KeyNavigation.down: optSupersampling
                }
                SliderOption {
                    id: optSupersampling
                    property string parameterName : prefix + ".supersampling"

                    label: qsTr("Supersampling anti-aliasing") + api.tr
                    note: qsTr("Supersampling is very much a brute force solution, \nrender the scene at a higher resolution and mipmap it. \n3 gives a very good balance between speed and quality, 8 will make your GPU bleed.") + api.tr
                    max : 8
                    min : 1
                    slidervalue : api.internal.recalbox.getIntParameter(parameterName)
                    value: api.internal.recalbox.getIntParameter(parameterName) + "x"
                    onActivate: {
                        focus = true;
                    }
                    Keys.onLeftPressed: {
                        api.internal.recalbox.setIntParameter(parameterName,slidervalue);
                        value = slidervalue + "x";
                        sfxNav.play();
                    }
                    Keys.onRightPressed: {
                        api.internal.recalbox.setIntParameter(parameterName,slidervalue);
                        value = slidervalue + "x";
                        sfxNav.play();
                    }
                    onFocusChanged: container.onFocus(this)
                    KeyNavigation.down: optUpscaleMode
                }
                MultivalueOption {
                    id: optUpscaleMode

                    property string parameterName : prefix + ".upscalemode"
                    label: qsTr("Upscale filters Mode") + api.tr
                    note: qsTr("Upscale filter used for the 2D layers.") + api.tr

                    value: api.internal.recalbox.parameterslist.currentName(parameterName)

                    currentIndex: api.internal.recalbox.parameterslist.currentIndex;
                    count: api.internal.recalbox.parameterslist.count;

                    onActivate: {
                        parameterslistBox.parameterName = parameterName;
                        parameterslistBox.callerid = optInternalResolution;
                        api.internal.recalbox.parameterslist.currentName(parameterName);
                        parameterslistBox.model = api.internal.recalbox.parameterslist;
                        parameterslistBox.index = api.internal.recalbox.parameterslist.currentIndex;
                        parameterslistBox.focus = true;
                    }

                    onSelect: {
                        api.internal.recalbox.parameterslist.currentName(parameterName);
                        api.internal.recalbox.parameterslist.currentIndex = index;
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

                    KeyNavigation.down: optCRTColors
                }
                MultivalueOption {
                    id: optCRTColors

                    property string parameterName : prefix + ".crtcolors"
                    label: qsTr("CRT-like color adaption") + api.tr
                    note: qsTr("so not scanlines or the other CRT aspects, \njust the differences in the region-specific TV color standards.") + api.tr

                    value: api.internal.recalbox.parameterslist.currentName(parameterName)

                    currentIndex: api.internal.recalbox.parameterslist.currentIndex;
                    count: api.internal.recalbox.parameterslist.count;

                    onActivate: {
                        parameterslistBox.parameterName = parameterName;
                        parameterslistBox.callerid = optInternalResolution;
                        api.internal.recalbox.parameterslist.currentName(parameterName);
                        parameterslistBox.model = api.internal.recalbox.parameterslist;
                        parameterslistBox.index = api.internal.recalbox.parameterslist.currentIndex;
                        parameterslistBox.focus = true;
                    }

                    onSelect: {
                        api.internal.recalbox.parameterslist.currentName(parameterName);
                        api.internal.recalbox.parameterslist.currentIndex = index;
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

                    KeyNavigation.down: optCrosshairs
                }
                ToggleOption {
                    id: optCrosshairs

                    label: qsTr("Crosshairs") + api.tr
                    note: qsTr("Active crosshairs on lightgun games.") + api.tr

                    checked: api.internal.recalbox.getBoolParameter(prefix + ".crosshairs")
                    onCheckedChanged: {
                        api.internal.recalbox.setBoolParameter(prefix + ".crosshairs",checked);
                    }
                    onFocusChanged: container.onFocus(this)
                    KeyNavigation.down: optNew3dEngine
                }
                SectionTitle {
                    text: qsTr("Core options") + api.tr
                    first: true
                    symbol: "\uf179"
                }
                ToggleOption {
                    id: optNew3dEngine

                    label: qsTr("New 3d engine") + api.tr
                    note: qsTr("Switch between legacy and new 3d engine. \nEnable for new 3d engine by default.") + api.tr

                    checked: api.internal.recalbox.getBoolParameter(prefix + ".new3d.engine")
                    onCheckedChanged: {
                        api.internal.recalbox.setBoolParameter(prefix + ".new3d.engine",checked);
                    }
                    onFocusChanged: container.onFocus(this)
                    KeyNavigation.down: optMultiTexture
                }
                ToggleOption {
                    id: optMultiTexture

                    label: qsTr("Multi textures") + api.tr
                    note: qsTr("Use 8 texture maps for decoding (legacy engine). \nDisabled on default.") + api.tr

                    checked: api.internal.recalbox.getBoolParameter(prefix + ".multi.texture")
                    onCheckedChanged: {
                        api.internal.recalbox.setBoolParameter(prefix + ".multi.texture",checked);
                    }
                    onFocusChanged: container.onFocus(this)
                    KeyNavigation.down: optGpuThreaded
                    visible: optNew3dEngine.checked ? false : true
                }
                ToggleOption {
                    id: optGpuThreaded

                    label: qsTr("Gpu threaded") + api.tr
                    note: qsTr("Run graphics rendering in main thread. \nEnable by default.") + api.tr

                    checked: api.internal.recalbox.getBoolParameter(prefix + ".gpu.threaded")
                    onCheckedChanged: {
                        api.internal.recalbox.setBoolParameter(prefix + ".gpu.threaded",checked);
                    }
                    onFocusChanged: container.onFocus(this)
                    KeyNavigation.down: optQuadRendering
                }
                ToggleOption {
                    id: optQuadRendering

                    label: qsTr("Quad Rendering") + api.tr
                    note: qsTr("Enable proper quad rendering.") + api.tr

                    checked: api.internal.recalbox.getBoolParameter(prefix + ".quad.rendering")
                    onCheckedChanged: {
                        api.internal.recalbox.setBoolParameter(prefix + ".quad.rendering",checked);
                    }
                    onFocusChanged: container.onFocus(this)
                    KeyNavigation.down: optNetwork
                }
               // SliderOption {
               //     id: optPowerPcFrequency

               //     //property to manage parameter name
               //     property string parameterName : prefix + ".powerpc.frequency"

               //     //property of SliderOption to set
               //     label: qsTr("PowerPC frequency") + api.tr
               //     note: qsTr("Many games can be run at as low as 66 MHz,\nbut others require higher clock frequencies.\nOptimal values will differ from game to game.") + api.tr
               //     // in slider object
               //     max : 166
               //     min : 66
               //     slidervalue : api.internal.recalbox.getIntParameter(parameterName)
               //     // in text object
               //     value: api.internal.recalbox.getIntParameter(parameterName) + "MHz"
               //     onActivate: {
               //         focus = true;
               //     }
               //     Keys.onLeftPressed: {
               //         api.internal.recalbox.setIntParameter(parameterName,slidervalue);
               //         value = slidervalue + "MHz";
               //         sfxNav.play();
               //     }
               //     Keys.onRightPressed: {
               //         api.internal.recalbox.setIntParameter(parameterName,slidervalue);
               //         value = slidervalue + "MHz";
               //         sfxNav.play();
               //     }
               //     onFocusChanged: container.onFocus(this)
               //     KeyNavigation.down: optNetwork
               // }
                SectionTitle {
                    text: qsTr("Netplay") + api.tr
                    first: true
                    symbol: "\uf343"
                }
                ToggleOption {
                    id: optNetwork

                    label: qsTr("Network") + api.tr
                    note: qsTr("Enable Network betwen two cab.") + api.tr

                    checked: api.internal.recalbox.getBoolParameter(prefix + ".network")
                    onCheckedChanged: {
                        api.internal.recalbox.setBoolParameter(prefix + ".network",checked);
                    }
                    onFocusChanged: container.onFocus(this)
                    KeyNavigation.down: optAddressOut
                }
                SimpleButton {
                    id: optAddressOut
                    label: qsTr("Address Out") + api.tr
                    note: qsTr("type your output address for next net cab's.") + api.tr

                    TextFieldOption {
                        id: addressOut
                        anchors.right: parent.right
                        anchors.verticalCenter: parent.verticalCenter
                        horizontalAlignment: TextInput.AlignRight
                        placeholderText: qsTr("127.0.0.1") + api.tr
                        text: api.internal.recalbox.getStringParameter(prefix + ".address.out")
                        echoMode: TextInput.Normal
                        inputMethodHints: Qt.ImhNoPredictiveText
                        onEditingFinished: api.internal.recalbox.setStringParameter(prefix + ".address.out", addressOut.text)
                    }
                    onFocusChanged: container.onFocus(this)
                    KeyNavigation.down: optPortIn
                    visible: optNetwork.checked
                }
                SimpleButton {
                    id: optPortIn
                    label: qsTr("Port In") + api.tr
                    note: qsTr("type your Input port for next net cab's.") + api.tr

                    TextFieldOption {
                        id: portIn
                        anchors.right: parent.right
                        anchors.verticalCenter: parent.verticalCenter
                        horizontalAlignment: TextInput.AlignRight
                        placeholderText: qsTr("1970") + api.tr
                        text: api.internal.recalbox.getStringParameter(prefix + ".port.in")
                        echoMode: TextInput.Normal
                        inputMethodHints: Qt.ImhNoPredictiveText
                        onEditingFinished: api.internal.recalbox.setStringParameter(prefix + ".port.in", portIn.text)
                    }
                    onFocusChanged: container.onFocus(this)
                    KeyNavigation.down: optPortOut
                    visible: optNetwork.checked
                }
                SimpleButton {
                    id: optPortOut
                    label: qsTr("Port Out") + api.tr
                    note: qsTr("type your Input port for next net cab's.") + api.tr

                    TextFieldOption {
                        id: portOut
                        anchors.right: parent.right
                        anchors.verticalCenter: parent.verticalCenter
                        horizontalAlignment: TextInput.AlignRight
                        placeholderText: qsTr("1971") + api.tr
                        text: api.internal.recalbox.getStringParameter(prefix + ".port.out")
                        echoMode: TextInput.Normal
                        inputMethodHints: Qt.ImhNoPredictiveText
                        onEditingFinished: api.internal.recalbox.setStringParameter(prefix + ".port.out", portOut.text)
                    }
                    onFocusChanged: container.onFocus(this)
                    KeyNavigation.down: optLegacySoundEngine
                    visible: optNetwork.checked
                }
                SectionTitle {
                    text: qsTr("Sound configuration") + api.tr
                    first: true
                    symbol: "\uf11c"
                }
                ToggleOption {
                    id: optLegacySoundEngine

                    label: qsTr("Legacy Sound engine") + api.tr
                    note: qsTr("Use Legacy SCSP engine. \nDisable on default.") + api.tr

                    checked: api.internal.recalbox.getBoolParameter(prefix + ".legacy.sound.engine")
                    onCheckedChanged: {
                        api.internal.recalbox.setBoolParameter(prefix + ".legacy.sound.engine",checked);
                    }
                    onFocusChanged: container.onFocus(this)
                    KeyNavigation.down: optFlipStereo
                }
                ToggleOption {
                    id: optFlipStereo

                    label: qsTr("Flip stereo") + api.tr
                    note: qsTr("Swap left and right audio channels.") + api.tr

                    checked: api.internal.recalbox.getBoolParameter(prefix + ".flip.stereo")
                    onCheckedChanged: {
                        api.internal.recalbox.setBoolParameter(prefix + ".flip.stereo",checked);
                    }
                    onFocusChanged: container.onFocus(this)
                    KeyNavigation.down: optServiceButton
                }
                SectionTitle {
                    text: qsTr("Controllers") + api.tr
                    first: true
                    symbol: "\uf181"
                }
                ToggleOption {
                    id: optServiceButton

                    label: qsTr("Active service button") + api.tr
                    note: qsTr("Active service button for acces menu test arcade game. \nConfigured in L3: service R3 test.") + api.tr

                    checked: api.internal.recalbox.getBoolParameter(prefix + ".service.button")
                    onCheckedChanged: {
                        api.internal.recalbox.setBoolParameter(prefix + ".service.button",checked);
                    }
                    onFocusChanged: container.onFocus(this)
                    KeyNavigation.down: optSensitivity
                }
                SliderOption {
                    id: optSensitivity

                    //property to manage parameter name
                    property string parameterName : prefix + ".sensitivity"

                    //property of SliderOption to set
                    label: qsTr("Set sensitvity Controller") + api.tr
                    note: qsTr("The sensitvity is expressed as a percentage. \nThe default value is 25%.") + api.tr
                    // in slider object
                    max : 100
                    min : 0
                    slidervalue : api.internal.recalbox.getIntParameter(parameterName)
                    // in text object
                    value: api.internal.recalbox.getIntParameter(parameterName) + "%"
                    onActivate: {
                        focus = true;
                    }
                    Keys.onLeftPressed: {
                        api.internal.recalbox.setIntParameter(parameterName,slidervalue);
                        value = slidervalue + "%";
                        sfxNav.play();
                    }
                    Keys.onRightPressed: {
                        api.internal.recalbox.setIntParameter(parameterName,slidervalue);
                        value = slidervalue + "%";
                        sfxNav.play();
                    }
                    onFocusChanged: container.onFocus(this)
                    KeyNavigation.down: optDeadzone
                }
                SliderOption {
                    id: optDeadzone

                    //property to manage parameter name
                    property string parameterName : prefix + ".deadzone"

                    //property of SliderOption to set
                    label: qsTr("Set dead zone Controller") + api.tr
                    note: qsTr("The dead zone is expressed as a percentage. \nthe axis and the default value is 2%.") + api.tr
                    // in slider object
                    max : 99
                    min : 0
                    slidervalue : api.internal.recalbox.getIntParameter(parameterName)
                    // in text object
                    value: api.internal.recalbox.getIntParameter(parameterName) + "%"
                    onActivate: {
                        focus = true;
                    }
                    Keys.onLeftPressed: {
                        api.internal.recalbox.setIntParameter(parameterName,slidervalue);
                        value = slidervalue + "%";
                        sfxNav.play();
                    }
                    Keys.onRightPressed: {
                        api.internal.recalbox.setIntParameter(parameterName,slidervalue);
                        value = slidervalue + "%";
                        sfxNav.play();
                    }
                    onFocusChanged: container.onFocus(this)
                    KeyNavigation.down: optsaturation
                }
                SliderOption {
                    id: optsaturation

                    //property to manage parameter name
                    property string parameterName : prefix + ".saturation"

                    //property of SliderOption to set
                    label: qsTr("Set saturation controller") + api.tr
                    note: qsTr("The saturation is expressed as a percentage 0-200. \nthe default value is 100%.") + api.tr
                    // in slider object
                    max : 200
                    min : 0
                    slidervalue : api.internal.recalbox.getIntParameter(parameterName)
                    // in text object
                    value: api.internal.recalbox.getIntParameter(parameterName) + "%"
                    onActivate: {
                        focus = true;
                    }
                    Keys.onLeftPressed: {
                        api.internal.recalbox.setIntParameter(parameterName,slidervalue);
                        value = slidervalue + "%";
                        sfxNav.play();
                    }
                    Keys.onRightPressed: {
                        api.internal.recalbox.setIntParameter(parameterName,slidervalue);
                        value = slidervalue + "%";
                        sfxNav.play();
                    }
                    onFocusChanged: container.onFocus(this)
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
