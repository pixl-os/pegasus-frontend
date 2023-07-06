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
        text: qsTr("Advanced emulators settings > Supermodel") + api.tr
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
                    id: optInternalResolution
                    // set focus only on first item
                    focus: true

                    //property to manage parameter name
                    property string parameterName : "supermodel.resolution"

                    label: qsTr("Internal Resolution") + api.tr
                    note: qsTr("Controls the rendering resolution. \nA high resolution greatly improves visual quality,\nbut cause issues in certain games") + api.tr

                    value: api.internal.recalbox.parameterslist.currentName(parameterName)
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
                    onFocusChanged: container.onFocus(this)
                    KeyNavigation.down: optCrosshairs
                }
                ToggleOption {
                    id: optCrosshairs

                    label: qsTr("Crosshairs") + api.tr
                    note: qsTr("Ative crosshairs on lightgun games") + api.tr

                    checked: api.internal.recalbox.getBoolParameter("supermodel.crosshairs")
                    onCheckedChanged: {
                        api.internal.recalbox.setBoolParameter("supermodel.crosshairs",checked);
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
                    note: qsTr("Switch between legacy and new 3d engine. \nEnable for new 3d engine by default") + api.tr

                    checked: api.internal.recalbox.getBoolParameter("supermodel.new3d.engine")
                    onCheckedChanged: {
                        api.internal.recalbox.setBoolParameter("supermodel.new3d.engine",checked);
                    }
                    onFocusChanged: container.onFocus(this)
                    KeyNavigation.down: optMultiTexture
                }
                ToggleOption {
                    id: optMultiTexture

                    label: qsTr("Multi texture") + api.tr
                    note: qsTr("Use 8 texture maps for decoding (legacy engine). \nDisabled on default") + api.tr

                    checked: api.internal.recalbox.getBoolParameter("supermodel.multi.texture")
                    onCheckedChanged: {
                        api.internal.recalbox.setBoolParameter("supermodel.multi.texture",checked);
                    }
                    onFocusChanged: container.onFocus(this)
                    KeyNavigation.down: optGpuThreaded
                    visible: optNew3dEngine.checked ? false : true
                }
                ToggleOption {
                    id: optGpuThreaded

                    label: qsTr("Gpu threaded") + api.tr
                    note: qsTr("Run graphics rendering in main thread. \nEnable by default") + api.tr

                    checked: api.internal.recalbox.getBoolParameter("supermodel.gpu.threaded")
                    onCheckedChanged: {
                        api.internal.recalbox.setBoolParameter("supermodel.gpu.threaded",checked);
                    }
                    onFocusChanged: container.onFocus(this)
                    KeyNavigation.down: optQuadRendering
                }
                ToggleOption {
                    id: optQuadRendering

                    label: qsTr("Quad Rendering") + api.tr
                    note: qsTr("Enable proper quad rendering. \nEnable by default") + api.tr

                    checked: api.internal.recalbox.getBoolParameter("supermodel.quad.rendering")
                    onCheckedChanged: {
                        api.internal.recalbox.setBoolParameter("supermodel.quad.rendering",checked);
                    }
                    onFocusChanged: container.onFocus(this)
                    KeyNavigation.down: optNetwork
                }
//                SliderOption {
//                    id: optPowerPcFrequency

//                    //property to manage parameter name
//                    property string parameterName : "supermodel.powerpc.frequency"

//                    //property of SliderOption to set
//                    label: qsTr("PowerPC frequency") + api.tr
//                    note: qsTr("Many games can be run at as low as 25 MHz,\nbut others require higher clock frequencies.\nOptimal values will differ from game to game.") + api.tr
//                    // in slider object
//                    max : 145
//                    min : 25
//                    slidervalue : api.internal.recalbox.getIntParameter(parameterName)
//                    // in text object
//                    value: api.internal.recalbox.getIntParameter(parameterName) + "MHz"
//                    onActivate: {
//                        focus = true;
//                    }
//                    Keys.onLeftPressed: {
//                        api.internal.recalbox.setIntParameter(parameterName,slidervalue);
//                        value = slidervalue + "MHz";
//                        sfxNav.play();
//                    }
//                    Keys.onRightPressed: {
//                        api.internal.recalbox.setIntParameter(parameterName,slidervalue);
//                        value = slidervalue + "MHz";
//                        sfxNav.play();
//                    }
//                    onFocusChanged: container.onFocus(this)
//                    KeyNavigation.down: optNetwork
//                }
                SectionTitle {
                    text: qsTr("Netplay") + api.tr
                    first: true
                    symbol: "\uf343"
                }
                ToggleOption {
                    id: optNetwork

                    label: qsTr("Network") + api.tr
                    note: qsTr("Enable Network betwen two cab") + api.tr

                    checked: api.internal.recalbox.getBoolParameter("supermodel.network")
                    onCheckedChanged: {
                        api.internal.recalbox.setBoolParameter("supermodel.network",checked);
                    }
                    onFocusChanged: container.onFocus(this)
                    KeyNavigation.down: optAddressOut
                }
                SimpleButton {
                    id: optAddressOut
                    label: qsTr("Address Out") + api.tr
                    note: qsTr("type your output address for next net cab's") + api.tr

                    TextFieldOption {
                        id: addressOut
                        anchors.right: parent.right
                        anchors.verticalCenter: parent.verticalCenter
                        horizontalAlignment: TextInput.AlignRight
                        placeholderText: qsTr("127.0.0.1") + api.tr
                        text: api.internal.recalbox.getStringParameter("supermodel.address.out")
                        echoMode: TextInput.Normal
                        inputMethodHints: Qt.ImhNoPredictiveText
                        onEditingFinished: api.internal.recalbox.setStringParameter("supermodel.address.out", addressOut.text)
                    }
                    onFocusChanged: container.onFocus(this)
                    KeyNavigation.down: optPortIn
                    visible: optNetwork.checked
                }
                SimpleButton {
                    id: optPortIn
                    label: qsTr("Port In") + api.tr
                    note: qsTr("type your Input port for next net cab's") + api.tr

                    TextFieldOption {
                        id: portIn
                        anchors.right: parent.right
                        anchors.verticalCenter: parent.verticalCenter
                        horizontalAlignment: TextInput.AlignRight
                        placeholderText: qsTr("1970") + api.tr
                        text: api.internal.recalbox.getStringParameter("supermodel.port.in")
                        echoMode: TextInput.Normal
                        inputMethodHints: Qt.ImhNoPredictiveText
                        onEditingFinished: api.internal.recalbox.setStringParameter("supermodel.port.in", portIn.text)
                    }
                    onFocusChanged: container.onFocus(this)
                    KeyNavigation.down: optPortOut
                    visible: optNetwork.checked
                }
                SimpleButton {
                    id: optPortOut
                    label: qsTr("Port Out") + api.tr
                    note: qsTr("type your Input port for next net cab's") + api.tr

                    TextFieldOption {
                        id: portOut
                        anchors.right: parent.right
                        anchors.verticalCenter: parent.verticalCenter
                        horizontalAlignment: TextInput.AlignRight
                        placeholderText: qsTr("1971") + api.tr
                        text: api.internal.recalbox.getStringParameter("supermodel.port.out")
                        echoMode: TextInput.Normal
                        inputMethodHints: Qt.ImhNoPredictiveText
                        onEditingFinished: api.internal.recalbox.setStringParameter("supermodel.port.out", portOut.text)
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
                    note: qsTr("Use Legacy SCSP engine. \nDisable on default") + api.tr

                    checked: api.internal.recalbox.getBoolParameter("supermodel.legacy.sound.engine")
                    onCheckedChanged: {
                        api.internal.recalbox.setBoolParameter("supermodel.legacy.sound.engine",checked);
                    }
                    onFocusChanged: container.onFocus(this)
                    KeyNavigation.down: optFlipStereo
                }
                ToggleOption {
                    id: optFlipStereo

                    label: qsTr("Flip stereo") + api.tr
                    note: qsTr("Swap left and right audio channels") + api.tr

                    checked: api.internal.recalbox.getBoolParameter("supermodel.flip.stereo")
                    onCheckedChanged: {
                        api.internal.recalbox.setBoolParameter("supermodel.flip.stereo",checked);
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
                    note: qsTr("Active service button for acces menu test arcade game. \nconfigured in L3: service R3 test ") + api.tr

                    checked: api.internal.recalbox.getBoolParameter("supermodel.service.button")
                    onCheckedChanged: {
                        api.internal.recalbox.setBoolParameter("supermodel.service.button",checked);
                    }
                    onFocusChanged: container.onFocus(this)
                    KeyNavigation.down: optSensitivity
                }
                SliderOption {
                    id: optSensitivity

                    //property to manage parameter name
                    property string parameterName : "supermodel.sensitivity"

                    //property of SliderOption to set
                    label: qsTr("Set sensitvity Controller") + api.tr
                    note: qsTr("The sensitvity is expressed as a percentage. \nthe default value is 25%.") + api.tr
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
                    property string parameterName : "supermodel.deadzone"

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
                    property string parameterName : "supermodel.saturation"

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
