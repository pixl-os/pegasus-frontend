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
    property string prefix : game ? "override.rpcs3" : "rpcs3"
    //to manage better title in screen ScreenHeader (if we want to change it during loading)
    property string titleHeader: game ? game.title +  " > Rpcs3" :
        (system ? system.name + " > Rpcs3" :
         qsTr("Advanced emulators settings > Rpcs3") + api.tr)

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
                SectionTitle {
                    text: qsTr("Game screen") + api.tr
                    first: true
                    symbol: "\uf17f"
                }
                MultivalueOption {
                    id: optResolutionScale
                    // set focus only on first item
                    focus: true

                    //property to manage parameter name
                    property string parameterName : prefix + ".resolution"

                    label: qsTr("Resolution Scale") + api.tr
                    note: qsTr("Scale the game's resolution by the given percentage. \nThe base resolution is always 1280x720. \nValue below 100% wiil usually not improve performance.") + api.tr

                    value: api.internal.recalbox.parameterslist.currentName(parameterName)

                    currentIndex: api.internal.recalbox.parameterslist.currentIndex;
                    count: api.internal.recalbox.parameterslist.count;

                    onActivate: {
                        //for callback by parameterslistBox
                        parameterslistBox.parameterName = parameterName;
                        parameterslistBox.callerid = optResolutionScale;
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

                    KeyNavigation.down: optVsync
                }
                ToggleOption {
                    id: optVsync

                    label: qsTr("VSync") + api.tr
                    note: qsTr("By having this off you might obtain a higher framerate at \nthe cost of tearing artifacts in the game.") + api.tr

                    checked: api.internal.recalbox.getBoolParameter(prefix + ".vsync")
                    onCheckedChanged: {
                        api.internal.recalbox.setBoolParameter(prefix + ".vsync",checked);
                    }
                    onFocusChanged: container.onFocus(this)
                    KeyNavigation.down: optScanline
                }
                MultivalueOption {
                    id: optScanline

                    //property to manage parameter name
                    property string parameterName : prefix + ".scanline"

                    label: qsTr("Output Scanling") + api.tr
                    note: qsTr("Nearest applies no filtering, bilinear smooths the image, \nand fidelity super resolution enhances upscaled images.") + api.tr

                    value: api.internal.recalbox.parameterslist.currentName(parameterName)

                    currentIndex: api.internal.recalbox.parameterslist.currentIndex;
                    count: api.internal.recalbox.parameterslist.count;

                    onActivate: {
                        //for callback by parameterslistBox
                        parameterslistBox.parameterName = parameterName;
                        parameterslistBox.callerid = optScanline;
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
                    KeyNavigation.down: optFidelityFx
                }
                SliderOption {
                    id: optFidelityFx

                    //property to manage parameter name
                    property string parameterName : prefix + ".fidelityfx"

                    //property of SliderOption to set
                    label: qsTr("Set Fidelity FX level") + api.tr
                    note: qsTr("Fidelity super resolution enhances upscaled images\nThe default value is 50%.") + api.tr
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
                    visible: optScanline.value === "FidelityFX Super Resolution"
                    KeyNavigation.down: optNetworkStatut
                }
                SectionTitle {
                    text: qsTr("Network") + api.tr
                    first: true
                    symbol: "\uf17f"
                }
                ToggleOption {
                    id: optNetworkStatut

                    label: qsTr("Network Status") + api.tr
                    note: qsTr("If set to Connected, RPCS3 will alow programs to use internet connection.") + api.tr

                    checked: api.internal.recalbox.getBoolParameter(prefix + ".network")
                    onCheckedChanged: {
                        api.internal.recalbox.setBoolParameter(prefix + ".network",checked);
                    }
                    onFocusChanged: container.onFocus(this)
                    KeyNavigation.down: optUpnp
                }
                ToggleOption {
                    id: optUpnp

                    label: qsTr("Enable UPNP protocol") + api.tr
                    note: qsTr("This will automactically forward ports bound on 0.0.0.0 if your router has UPNP enabled.") + api.tr

                    checked: api.internal.recalbox.getBoolParameter(prefix + ".upnp")
                    onCheckedChanged: {
                        api.internal.recalbox.setBoolParameter(prefix + ".upnp",checked);
                    }
                    onFocusChanged: container.onFocus(this)
                    visible: optNetworkStatut.checked
                    KeyNavigation.down: optRpcnStatut
                }
                ToggleOption {
                    id: optRpcnStatut

                    label: qsTr("PSN Status") + api.tr
                    note: qsTr("If set enable RPCS3 will use the RPCN server as PSN connection if the game is supported.") + api.tr

                    checked: api.internal.recalbox.getBoolParameter(prefix + ".rpcn")
                    onCheckedChanged: {
                        api.internal.recalbox.setBoolParameter(prefix + ".rpcn",checked);
                    }
                    onFocusChanged: container.onFocus(this)
                    visible: optNetworkStatut.checked
                    KeyNavigation.down: optRpcs3RpcnUsername
                }
                SimpleButton {
                    id: optRpcs3RpcnUsername

                    label: qsTr("Username") + api.tr
                    note: qsTr("If you don't have an account go to setting emulator and create on menu") + api.tr

                    TextFieldOption {
                        id: rpcnUsername
                        anchors.right: parent.right
                        anchors.verticalCenter: parent.verticalCenter
                        horizontalAlignment: TextInput.AlignRight
                        placeholderText: qsTr("Username") + api.tr
                        text: api.internal.recalbox.getStringParameter(prefix + ".rpcn.username")
                        echoMode: TextInput.Normal
                        inputMethodHints: Qt.ImhNoPredictiveText
                        onEditingFinished: api.internal.recalbox.setStringParameter(prefix + ".rpcn.username", rpcnUsername.text)
                    }
                    onFocusChanged: container.onFocus(this)
                    KeyNavigation.down: optRpcs3RpcnPassword
                    visible: optRpcnStatut.checked && optNetworkStatut.checked
                }
                SimpleButton {
                    id: optRpcs3RpcnPassword

                    label: qsTr("Password") + api.tr
                    note: qsTr("then login with your username and password") + api.tr

                    TextFieldOption {
                        id: rpcnPassword
                        anchors.right: parent.right
                        anchors.verticalCenter: parent.verticalCenter
                        placeholderText: qsTr("Password") + api.tr
                        text: api.internal.recalbox.getStringParameter(prefix + ".rpcn.password")
                        horizontalAlignment: TextInput.AlignRight
                        echoMode: TextInput.PasswordEchoOnEdit
                        inputMethodHints: Qt.ImhNoAutoUppercase | Qt.ImhPreferLowercase | Qt.ImhSensitiveData | Qt.ImhNoPredictiveText
                        onEditingFinished: api.internal.recalbox.setStringParameter(prefix + ".rpcn.password", rpcnPassword.text)
                    }
                    onFocusChanged: container.onFocus(this)
                    KeyNavigation.down: optRpcs3RpcnToken
                    visible: optRpcnStatut.checked && optNetworkStatut.checked
                }
                SimpleButton {
                    id: optRpcs3RpcnToken

                    label: qsTr("Token") + api.tr
                    note: qsTr("If you don't have an token check your mail after create an account") + api.tr

                    TextFieldOption {
                        id: rpcnToken
                        anchors.right: parent.right
                        anchors.verticalCenter: parent.verticalCenter
                        horizontalAlignment: TextInput.AlignRight
                        placeholderText: qsTr("Token") + api.tr
                        text: api.internal.recalbox.getStringParameter(prefix + ".rpcn.token")
                        echoMode: TextInput.PasswordEchoOnEdit
                        inputMethodHints: Qt.ImhNoPredictiveText
                        onEditingFinished: api.internal.recalbox.setStringParameter(prefix + ".rpcn.token", rpcnToken.text)
                    }
                    onFocusChanged: container.onFocus(this)
                    KeyNavigation.down: optRpcs3Theme
                    visible: optRpcnStatut.checked && optNetworkStatut.checked
                }
                SectionTitle {
                    text: qsTr("Menu options") + api.tr
                    first: true
                    symbol: "\uf412"
                }
                MultivalueOption {
                    id: optRpcs3Theme
                    //property to manage parameter name
                    property string parameterName : prefix + ".theme"

                    label: qsTr("GUI Theme") + api.tr
                    note: qsTr("Changes the overall look of RPCS3") + api.tr

                    value: api.internal.recalbox.parameterslist.currentName(parameterName)

                    currentIndex: api.internal.recalbox.parameterslist.currentIndex;
                    count: api.internal.recalbox.parameterslist.count;

                    onActivate: {
                        //for callback by parameterslistBox
                        parameterslistBox.parameterName = parameterName;
                        parameterslistBox.callerid = optRpcs3Theme;
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
