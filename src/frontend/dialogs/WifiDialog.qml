// Pegasus Frontend
//
// Created by BozoTheGeek - 24/05/2022
//

import QtQuick 2.12

import "../menu/settings/common"

FocusScope {
    id: root

    property alias title: titleText.text
    property alias symbol: symbolText.text
    property alias symbolfont : symbolText.font.family
    property alias firstchoice: okButtonText.text
    property alias secondchoice: secondButtonText.text
    property alias thirdchoice: cancelButtonText.text

    property bool has_password: false
    property string ssid :  ""
    property string actionState

    property int textSize: vpx(18)
    property int titleTextSize: vpx(20)
    property string lastchoice: ""

    property int horizontalPadding: vpx(30)
    property int verticalPadding: vpx(30)

    signal accept()
    signal secondChoice()
    signal cancel()

    anchors.fill: parent
    visible: shade.opacity > 0

    focus: true
    onActiveFocusChanged: {
        //console.log("onActiveFocusChanged : ", activeFocus);
        state = activeFocus ? "open" : "";
        if (activeFocus)
            cancelButton.focus = true;
    }

    Keys.onPressed: {
        //console.log("Global Keys.onPressed");
        if (api.keys.isCancel(event) && !event.isAutoRepeat) {
            event.accepted = true;
            root.cancel();
        }
    }

    Shade {
        id: shade
        onCancel: root.cancel()
    }

    //save wifi conf function
    function saveWifiConf(){
        //calculate index from wifiPriority
        var index;
        if(optWifiPriority.value === "1"){
            index = ""; //first one is "wifi."
        }
        else
        {
            index = optWifiPriority.value;
        }

        if(ssid === "") api.internal.recalbox.setStringParameter("wifi" + index + ".ssid", ssidtextfield.text);
        else api.internal.recalbox.setStringParameter("wifi" + index + ".ssid", ssid);

        api.internal.recalbox.setStringParameter("wifi" + index + ".key", keyfield.text);
        api.internal.recalbox.saveParameters();
    }

    // actual dialog
    MouseArea {
        anchors.centerIn: parent
        width: dialogBox.width
        height: dialogBox.height
    }
    Column {
        id: dialogBox

        width: parent.height * (1.4) //0.8

        anchors.horizontalCenter:  parent.horizontalCenter
        anchors.top:  parent.top
        anchors.topMargin: (Qt.inputMethod.visible && api.internal.settings.virtualKeyboardSupport) ? verticalPadding : ((parent.height/2) - (height/2))

        scale: 0.5

        Behavior on scale { NumberAnimation { duration: 125 } }

        // title bar
        Rectangle {
            id: titleBar
            width: parent.width
            height: root.titleTextSize * 2.25
            color: themeColor.main

            Text {
                id: titleText
                elide: Text.ElideRight
                anchors {
                    verticalCenter: parent.verticalCenter
                    left: parent.left
                    leftMargin: root.titleTextSize * 0.75
                    right: parent.right
                    rightMargin: root.titleTextSize * 0.75
                }

                color: themeColor.textTitle
                font {
                    bold: true
                    pixelSize: root.titleTextSize
                    family: globalFonts.sans
                }
            }
        }

        // text area
        /*# ------------ B - Network ------------ #
        ## Set system hostname
        system.hostname=RECALBOX
        ## Activate wifi (0,1)
        wifi.enabled=1
        ## Set wifi region
        ## More info here: https://github.com/recalbox/recalbox-os/wiki/Wifi-country-code-(EN)
        wifi.region=JP
        ## Wifi SSID (string)
        ;wifi.ssid=new ssid
        ## Wifi KEY (string)
        ## after rebooting the recalbox, the "new key" is replace by a hidden value "enc:xxxxx"
        ## you can edit the "enc:xxxxx" value to replace by a clear value, it will be updated again at the following reboot
        ## Escape your special chars (# ; $) with a backslash : $ => \$
        ;wifi.key=new key

        ## Wifi - static IP
        ## if you want a static IP address, you must set all 3 values (ip, gateway, and netmask)
        ## if any value is missing or all lines are commented out, it will fall back to the
        ## default of DHCP
        ;wifi.ip=manual ip address
        ;wifi.gateway=new gateway
        ;wifi.netmask=new netmask

        # secondary wifi (not configurable via the user interface)
        ;wifi2.ssid=new ssid
        ;wifi2.key=new key

        # third wifi (not configurable via the user interface)
        ;wifi3.ssid=new ssid
        ;wifi3.key=new key*/

        SimpleButton {
            id: optWifiSSID
            Rectangle {
                width: parent.width
                height: parent.height
                color: themeColor.secondary
                z:-1
            }
            label: qsTr("Wifi SSID") + api.tr
            note: ssid === "" ? qsTr("Thanks to enter your hidden SSID here") + api.tr : ""

            TextFieldOption {
                id: ssidtextfieldoption
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                horizontalAlignment: TextInput.AlignRight
                placeholderText: qsTr("your hidden ssid") + api.tr
                text: ""
                visible: ssid === "" ? true : false
                active: ssid === "" ? true : false
                echoMode: TextInput.Normal
                inputMethodHints: Qt.ImhNoPredictiveText

                activeFocusColor : themeColor.main
                inactiveColor: themeColor.secondary
                activeBorderColor: themeColor.screenHeader

                onEditingFinished: {
                    //do nothing save by "save" or "connect" button
                }
            }

            Text {
                id: symbolText

                anchors {
                    verticalCenter: parent.verticalCenter
                    right: ssidtextfield.left
                    rightMargin: root.titleTextSize * 0.75
                }

                color: themeColor.textTitle
                font {
                    bold: true
                    pixelSize: root.titleTextSize * 2
                    family: globalFonts.awesome
                }
                visible: ssid !== "" ? true : false
            }

            TextField {
                id: ssidtextfield
                anchors.right: parent.right
                anchors.rightMargin: horizontalPadding
                anchors.verticalCenter: parent.verticalCenter
                horizontalAlignment: TextInput.AlignRight
                text: ssid
                visible: ssid !== "" ? true : false
            }

            onFocusChanged: container.onFocus(this)
            KeyNavigation.down: optWifiKey
            visible: true
        }

        SimpleButton {
            id: optWifiKey
            Rectangle {
                width: parent.width
                height: parent.height
                color: themeColor.secondary
                z:-1
            }
            label: qsTr("Wifi Network security key") + api.tr
            note: qsTr("Thanks to enter your security key here") + api.tr

            TextFieldOption {
                id: keyfield
                anchors.right: parent.right
                anchors.rightMargin: horizontalPadding
                anchors.verticalCenter: parent.verticalCenter
                horizontalAlignment: TextInput.AlignRight
                placeholderText: qsTr("your key") + api.tr
                text: {
                    //find if a parameter has already this SSID to take and know if a key exists
                    var index = "";
                    for(var i = 1; i <= 3; i++){
                        if(i === 1){
                            index = ""; //first one is "wifi."
                        }
                        else
                        {
                            index = (i).toString(); //other one is from "wifi2."
                        }
                        if(api.internal.recalbox.getStringParameter("wifi"+ index + ".ssid") === ssid)
                        {
                            return api.internal.recalbox.getStringParameter("wifi" + index + ".key");
                        }
                    }
                    //if no existing SSID found in parameters
                    return "";
                }
                echoMode: TextInput.PasswordEchoOnEdit
                inputMethodHints: Qt.ImhNoAutoUppercase | Qt.ImhPreferLowercase | Qt.ImhSensitiveData | Qt.ImhNoPredictiveText

                activeFocusColor : themeColor.main
                inactiveColor: themeColor.secondary
                activeBorderColor: themeColor.screenHeader

                onEditingFinished: {
                    //do nothing save by "save" or "connect" button
                }
            }
            onFocusChanged: container.onFocus(this)
            KeyNavigation.down: optWifiPriority
            visible: has_password
        }

        //ListModel to manage priority list and parameters associated
        ListModel{
            id: wifiPriorityList
            ListElement{ name: "1"}
            ListElement{ name: "2"}
            ListElement{ name: "3"}
        }

        MultivalueOption {
            id: optWifiPriority
            Rectangle {
                width: parent.width
                height: parent.height
                color: themeColor.secondary
                z:-1
            }
            label: qsTr("Priority") + api.tr
            note: qsTr("From 1 to 3 to match with the 3 conf that we could save") + api.tr
            value: {
                //find if a parameter has already this SSID to take teh good priority
                var index = "";
                for(var i = 1; i <= 3; i++){
                    if(i === 1){
                        index = ""; //first one is "wifi."
                    }
                    else
                    {
                        index = (i).toString(); //other one is from "wifi2."
                    }
                    if(api.internal.recalbox.getStringParameter("wifi"+ index + ".ssid") === ssid)
                    {
                        if(index === "") index = "1";
                        return index;
                    }
                }
                //if no existing SSID found in parameters
                return "1";
            }
            //priority 1 will be save in wifi.ssid/key paremeters
            //priority 2 will be save in wifi2.ssid/key paremeters
            //priority 3 will be save in wifi3.ssid/key paremeters
            onActivate: {
                //for callback
                wifiPriorityBox.callerid = optWifiPriority;
                //to force update of list of parameters
                wifiPriorityBox.model = wifiPriorityList;
                wifiPriorityBox.index = parseInt(value) - 1;
                //to transfer focus to wifiPriorityBox
                wifiPriorityBox.focus = true;
            }
            onFocusChanged: container.onFocus(this)
            KeyNavigation.down: optWifiPriority.value === "1" ? okButton : secondButton
        }


        //For future use but need to change existing wifi script as /etc/init.d/S09wifi
        // today we ahve only key/ssid paremeters proposed and for a maximum of 3 wifis register.
        /*
        ToggleOption {
            id: optWifiAutoConnect //recalbox scripts to support this feature (today all wifi will try to be connected)
            Rectangle {
                        width: parent.width
                        height: parent.height
                        color: themeColor.secondary
                        z:-1
                      }
            label: qsTr(" Connect automatically for next time ?") + api.tr
            note: qsTr("Activate it to automatically connect to this wifi when it is detected") + api.tr

            checked: {
                //find next parameter available - until 50 wifi configrurables (but 3 useable for the moment from recalbox scripts ;-)
                for(var i = 0; i<= 50; i++){
                    var index;
                    if(i === 0)
                    {
                        index = ""; //first one is "wifi."
                    }
                    else
                    {
                        index = i+1; //other one is from "wifi2."
                    }
                    if(api.internal.recalbox.getStringParameter("wifi"+ index + ".ssid") === ssid)
                    {
                        return api.internal.recalbox.getBoolParameter("wifi" + index + ".autoconnect");
                    }
                }
                //if not found
                return false;
            }
            onCheckedChanged: {
                //find next parameter available - until 50 wifi configrurables (but 3 useable for the moment from recalbox scripts ;-)
                for(var i = 0; i<= 50; i++){
                    var index;
                    if(i === 0)
                    {
                        index = ""; //first one is "wifi."
                    }
                    else
                    {
                        index = i+1; //other one is from "wifi2."
                    }
                    if(api.internal.recalbox.getStringParameter("wifi"+ index + ".ssid") === ssid)
                    {
                        api.internal.recalbox.setBoolParameter("wifi" + index + ".autoconnect",checked);
                        return;
                    }
                    else if(api.internal.recalbox.getStringParameter("wifi"+ index + ".ssid") === "")
                    {
                        api.internal.recalbox.setStringParameter("wifi" + index + ".ssid",ssid);
                        api.internal.recalbox.setBoolParameter("wifi" + index + ".autoconnect",checked);
                        return;
                    }
                }
            }
            KeyNavigation.down: okButton
            visible: true
        }*/

        // button row
        Row {
            width: parent.width
            height: root.textSize * 2

            //to let DialogBox to update message after accept ;-)
            Timer{
                id: acceptTimer
                interval: 50 // launch after 50 ms
                repeat: false
                running: false
                triggeredOnStart: false
                onTriggered: {
                    if(lastchoice === "firstchoice") root.accept();
                    else if(lastchoice === "secondchoice") root.secondChoice();
                    else root.cancel();
                }
            }


            Rectangle {
                id: okButton

                width: (secondchoice !== "") ? parent.width * 0.33 : ((thirdchoice !== "") ? parent.width * 0.5 : parent.width)
                height: root.textSize * 2.25
                color: (optWifiPriority.value === "1") ? ((focus || okMouseArea.containsMouse) ? "darkGreen" : themeColor.main) : "grey"
                KeyNavigation.up: optWifiPriority
                KeyNavigation.right: (secondchoice !== "") ? secondButton : cancelButton
                Keys.onPressed: {
                    //console.log("okButton Keys.onPressed");
                    if (api.keys.isAccept(event) && !event.isAutoRepeat) {
                        event.accepted = true;
                        if (optWifiPriority.value === "1"){
                            //change text to ask to wait if needed
                            okButtonText.text = qsTr("Please wait...") + api.tr
                            messageText.text = qsTr("Under progress...") + api.tr
                            //add spinner display
                            spinnerloader.active = true;
                            //hide other buttons
                            secondButtonText.text = "";
                            cancelButtonText.text = "";
                            //save conf depending actionState
                            if(actionState === "Connect"){
                                saveWifiConf();
                            }
                            //let 50 ms to update interface
                            lastchoice = "firstchoice";
                            acceptTimer.running = true;
                        }
                    }
                }

                Text {
                    id: okButtonText
                    anchors.centerIn: parent

                    text: qsTr("Ok") + api.tr
                    color: themeColor.textTitle
                    font {
                        pixelSize: root.textSize
                        family: globalFonts.sans
                        strikeout: (optWifiPriority.value === "1") ? false : true
                    }
                }

                MouseArea {
                    id: okMouseArea
                    anchors.fill: parent
                    hoverEnabled: true
                    onClicked: {
                        if (optWifiPriority.value === "1"){
                            //change text to ask to wait if needed
                            okButtonText.text = qsTr("Please wait...") + api.tr;
                            messageText.text = qsTr("Under progress...") + api.tr;
                            //add spinner display
                            spinnerloader.active = true;
                            //hide other buttons
                            secondButtonText.text = "";
                            cancelButtonText.text = "";
                            //save conf depending actionState
                            if(actionState === "Connect"){
                                saveWifiConf();
                            }
                            //let 50 ms to update interface
                            lastchoice = "firstchoice";
                            acceptTimer.running = true;
                        }
                   }
                }
                //Spinner Loader to wait after accept (if needed and if UI blocked)
                Loader {
                    id: spinnerloader
                    anchors {
                        right:  parent.right;
                        rightMargin: parent.width * 0.02 + vpx(30/2)
                        verticalCenter: parent.verticalCenter
                    }
                    active: false
                    sourceComponent: spinner
                }

                Component {
                    id: spinner
                    Rectangle{
                        Image {
                            id: imageSpinner
                            source: "../assets/loading.png"
                            width: vpx(30)
                            height: vpx(30)
                            asynchronous: true
                            anchors.verticalCenter: parent.verticalCenter
                            anchors.horizontalCenter: parent.horizontalCenter
                            sourceSize { width: vpx(50); height: vpx(50) }
                            RotationAnimator on rotation {
                                loops: Animator.Infinite;
                                from: 0;
                                to: 360;
                                duration: 3000
                            }
                        }
                    }
                }
            }

            Rectangle {
                id: secondButton

                width: (secondchoice !== "") ? parent.width * 0.33 : parent.width * 0.5
                height: root.textSize * 2.25
                color: (focus || okMouseArea.containsMouse) ? "darkOrange" : themeColor.main //"#222"
                visible: (secondchoice !== "") ? true : false
                KeyNavigation.up: optWifiPriority
                KeyNavigation.right: cancelButton
                KeyNavigation.left:{
                    if(optWifiPriority.value === "1"){
                        return okButton;
                    }
                    else return cancelButton;
                }
                Keys.onPressed: {
                    //console.log("secondButton Keys.onPressed");
                    if (api.keys.isAccept(event) && !event.isAutoRepeat) {
                        event.accepted = true;
                        //change text to ask to wait if needed
                        okButtonText.text = qsTr("Please wait...") + api.tr;
                        messageText.text = qsTr("Under progress...") + api.tr;
                        //add spinner display
                        spinnerloader.active = true;
                        //hide other buttons
                        secondButtonText.text = "";
                        cancelButtonText.text = "";
                        //save conf depending actionState
                        if(actionState === "Connect"){
                            saveWifiConf();
                        }
                        //let 50 ms to update interface
                        lastchoice = "secondchoice";
                        acceptTimer.running = true;
                    }
                }
                Text {
                    id: secondButtonText
                    anchors.centerIn: parent

                    text: qsTr("2nd choice") + api.tr
                    color: themeColor.textTitle
                    font {
                        pixelSize: root.textSize
                        family: globalFonts.sans
                    }
                }

                MouseArea {
                    id: secondMouseArea
                    anchors.fill: parent
                    hoverEnabled: true
                    onClicked: {
                        //change text to ask to wait if needed
                        okButtonText.text = qsTr("Please wait...") + api.tr;
                        messageText.text = qsTr("Under progress...") + api.tr;
                        //add spinner display
                        spinnerloader.active = true;
                        //hide other buttons
                        secondButtonText.text = "";
                        cancelButtonText.text = "";
                        //save conf depending actionState
                        if(actionState === "Connect"){
                            saveWifiConf();
                        }
                        //let 50 ms to update interface
                        lastchoice = "secondchoice";
                        acceptTimer.running = true;
                   }
                }
            }

            Rectangle {
                id: cancelButton

                focus: true

                width: (secondchoice !== "") ? parent.width * 0.34 : ((thirdchoice !== "") ? parent.width * 0.5 : 0)
                height: root.textSize * 2.25
                color: (focus || cancelMouseArea.containsMouse) ? "darkRed" : themeColor.main //"#222"
                KeyNavigation.up: optWifiPriority
                KeyNavigation.left: (secondchoice !== "") ? secondButton : okButton
                Keys.onPressed: {
                    //console.log("cancelButton Keys.onPressed");
                    if (api.keys.isAccept(event) && !event.isAutoRepeat) {
                        event.accepted = true;
                        //change text to ask to wait if needed
                        okButtonText.text = qsTr("Please wait...") + api.tr;
                        messageText.text = qsTr("Under progress...") + api.tr;
                        //add spinner display
                        spinnerloader.active = true;
                        //hide other buttons
                        secondButtonText.text = "";
                        cancelButtonText.text = "";
                        //let 50 ms to update interface
                        lastchoice = "thirdchoice";
                        acceptTimer.running = true;
                    }
                }

                Text {
                    id: cancelButtonText
                    anchors.centerIn: parent

                    text: qsTr("Cancel") + api.tr
                    color: themeColor.textTitle
                    font {
                        pixelSize: root.textSize
                        family: globalFonts.sans
                    }
                }

                MouseArea {
                    id: cancelMouseArea
                    anchors.fill: parent
                    hoverEnabled: true
                    onClicked: {
                        //change text to ask to wait if needed
                        okButtonText.text = qsTr("Please wait...") + api.tr;
                        messageText.text = qsTr("Under progress...") + api.tr;
                        //add spinner display
                        spinnerloader.active = true;
                        //hide other buttons
                        secondButtonText.text = "";
                        cancelButtonText.text = "";
                        //let 50 ms to update interface
                        lastchoice = "thirdchoice";
                        acceptTimer.running = true;
                   }
                }
            }
        }
    }
    states: [
        State {
            name: "open"
            PropertyChanges { target: shade; opacity: 0.8 }
            PropertyChanges { target: dialogBox; scale: 1 }
        }
    ]



    MultivalueBox {
        id: wifiPriorityBox
        z: 3

        //properties to manage parameter
        //property string parameterName
        property MultivalueOption callerid
        //property alias parameterslistModel : model
        //reuse same model
        //model: api.internal.recalbox.parameterslist.model
        //to use index from parameterlist QAbstractList
        //index: api.internal.recalbox.parameterslist.currentIndex

        onClose: callerid.focus = true

        onSelect: {
            //to force update of display of selected value
            callerid.value = (index + 1).toString();
        }
    }
}
