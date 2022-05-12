// Pegasus Frontend
//
// Created by BozoTheGeek 07/05/2022
//
// command lines:
// To launch scan:
//                        #  wpa_cli -i wlan0 scan
//                        OK
// To have scan results:
//                        # wpa_cli -i wlan0 scan_results
//                        bssid / frequency / signal level / flags / ssid
//                        9c:c9:eb:15:cd:80       5220    -55     [WPA2-PSK-CCMP][WPS][ESS]       lesv2-5G-3
//                        9c:c9:eb:15:cd:7e       2472    -51     [WPA2-PSK-CCMP][WPS][ESS]       lesv2_2G
//                        ec:6c:9a:0b:1c:79       5540    -79     [WPA2-PSK-CCMP][WPS][ESS]       lesv2_livebox
//                        2c:30:33:da:84:93       5640    -79     [WPA2-PSK-CCMP+TKIP][ESS]       lesv2-5G-1
//                        2c:30:33:da:84:a4       2462    -71     [WPA-PSK-CCMP+TKIP][WPA2-PSK-CCMP+TKIP][ESS]    lesv2
//                        ec:6c:9a:0b:1c:74       2412    -74     [WPA2-PSK-CCMP][WPS][ESS]       lesv2_livebox

import "common"
import "qrc:/qmlutils" as PegasusUtils
import QtQuick 2.12
import QtQuick.Controls 2.12
import QtQuick.Window 2.12

FocusScope {
    id: root

    //to be able to follow action done on Bluetooth Devices Lists
    property string actionState : ""
    property int actionListIndex : 0

    //loader to load confirm dialog
    Loader {
        id: confirmDialog
        anchors.fill: parent
        z:10
    }

    Connections {
        target: confirmDialog.item
        function onAccept() {
            switch (actionState) {
                    case "Connect":
                        wifiTimer.running = false;
						var result = "";
						console.log("result:",result);
                        //relaunch scanning
                        wifiTimer.running = true; // no need to restart btModel because timer will manage
                    break;
                    case "Disconnect":
                        //stop scanning/checking during pairing
                        wifiTimer.running = true;
						var result = "";
                        console.log("result:",result);
                        //relaunch scanning
                        wifiTimer.running = true; // no need to restart btModel because timer will manage
                    break;
            }
            content.focus = true;
        }
        function onSecondChoice() {
            switch (actionState) {
                    case "Forget": // as "Disconnect" in fact for second choice
                        //just a simple tentative to disconnect the device "sofwarely" ;-)
                        //stop scanning during disconnect
                        wifiTimer.running = false;
                        console.log("result:",result);
                        //relaunch scanning
                        wifiTimer.running = true; // no need to restart btModel because timer will manage
                    break;
            }
            content.focus = true;
        }
        function onCancel() {
            //do nothing
            content.focus = true;
        }
    }

    //function to add new discovered device using 'known' devices as My Devices or Ignored ones
    function updateDiscoveredDevicesLists(name, macaddress, service){
        var found = false;
        //check device already in "Devices ignored"
        found = searchDeviceInList(myIgnoredDevicesModel, name, macaddress, service);
        //check device already in "My Devices"
        if(!found) found = searchDeviceInList(myDevicesModel, name, macaddress, service);
        //check device already in "Discovered Devices"
        if(!found) found = searchDeviceInList(wifiNetworksModel, name, macaddress, service);
        if (!found){
            //set icon from service name
            let icon = getIcon(name,service);
            if(macaddress !== name.replace(/-/g, ':') || !api.internal.recalbox.getBoolParameter("controllers.bluetooth.hide.no.name")){
                //add to discovered list
                //set vendor later from API & mac address
                //we can't set vendor immediately, it will be done by timer
                wifiNetworksModel.append({icon: icon, iconfont: getIconFont,  vendor: "", name: name, macaddress: macaddress, service: service });
                //console.log("At " + (bluetoothTimer.interval/1000)*counter + "s" + " - Found new service " + macaddress + " - Name: " + name + " - Service: " + service);
            }
        }
    }


    //As readSavedDevicesList but check also pairing at the same time
    function readWifiNetworksList(list){
        let result = "";
        //let i = 0;
        let icon;
        let allmacaddresses = "";
        if(!isDebugEnv()){
            //command to read scan, need to lauch scan before with command: 'wpa_cli -i wlan0 scan'
            result = api.internal.system.run("timeout 0.50 wpa_cli -i wlan0 scan_results | sed \"1 d\" | awk '{printf $1\"|\"$2\"|\"$3\"|\"$4\"|\"$5\"\\n}'");
        }
        else{
            // bssid / frequency / signal level / flags / ssid
            result = "9c:c9:eb:15:cd:80|5220|-54|[WPA2-PSK-CCMP][WPS][ESS]|lesv2-5G-3
9c:c9:eb:15:cd:7e|2472|-50|[WPA2-PSK-CCMP][WPS][ESS]|lesv2_2G
2c:30:33:da:84:93|5640|-79|[WPA2-PSK-CCMP+TKIP][ESS]|lesv2-5G-1
2c:30:33:da:84:a4|2462|-75|[WPA-PSK-CCMP+TKIP][WPA2-PSK-CCMP+TKIP][ESS]|lesv2
"
        }

        console.log("***********");
        console.log(result);
        console.log("***********");
        const devices = result.split('\n');//Split by LF ;-)
        console.log("Wifi networks found:",devices.length - 1);
        for(var j = 0;j < devices.length;j++){
            if (devices[j] !== "") {
                console.log("device:",devices[j]);
                const details = devices[j].split("|");
                /*if(!allmacaddresses.includes(details[0])){//if paired device is missing
                    //Add to list
                    icon = getIcon(details[1],"");
                    list.append({icon: icon, iconfont: getIconFont, vendor:"", name: details[1], macaddress: details[0], service: "" });
                    i = i + 1;
                }*/
            }
        }
    }



    //timer to relaunch bluetooth regularly for QT methods for the moment
    property int counter: 0
    Timer {
        id: wifiTimer
        interval: 1000 // Run the timer every second
        repeat: true
        running: true
        triggeredOnStart: true
        onTriggered: {
            if ((interval/1000)*counter === 2){ // wait 2 seconds before to scan wifi for the first time
                api.internal.system.runAsync("wpa_cli -i wlan0 scan");
            }
            // restart every 20 seconds
            if ((interval/1000)*counter >= 20){
                counter = 0;
            }
            else counter = counter + 1;
        }
    }

    Component.onCompleted:{
    }

    signal close

    width: parent.width
    height: parent.height
    
    anchors.fill: parent
    visible: 0 < (x + width) && x < Window.window.width

    enabled: focus

    Keys.onPressed: {
        if (api.keys.isCancel(event) && !event.isAutoRepeat) {
            event.accepted = true;
            //stop scanning/checking during pairing
            wifiTimer.running = false;
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
        onClicked: {
            //stop scanning/checking during connecting
            wifiTimer.running = false;
            root.close();
        }
    }

    ScreenHeader {
        id: header
        text: qsTr("Settings > Wifi networks") + api.tr
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
                    text: qsTr("Wifi networks") + api.tr
                    first: false
                    //Spinner Loader for wifi networks section
                    Loader {
                        id: spinnerloader
                        anchors.left: parent.right
                        anchors.leftMargin: vpx(30)
                        anchors.bottom: parent.bottom
                        anchors.bottomMargin: vpx(30)


                        //anchors.topMargin: vpx(80)
                        //anchors.verticalCenter: parent.verticalCenter
                        active: true
                        sourceComponent: spinner
                    }

                    Component {
                        id: spinner
                        Rectangle{
                            Image {
                                id: imageSpinner
                                source: "../../assets/loading.png"
                                width: vpx(30)
                                height: vpx(30)
                                asynchronous: true
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

                //for test purpose only
                ListModel {
                    id: wifiNetworksModel
                    ListElement { icon: ""; vendor: "Nintendo" ; name: "Switch Pro controller"; macaddress: "45:12:64:33:FF:EE" }
                }

                Repeater {
                    id: myDiscoveredDevices
                    model: wifiNetworksModel //for test purpose
                    SimpleButton {
                        property var isPairingIssue: false
                        width: parent.width - vpx(100)
                        Text {
                            id: wifiNetworkIcon

                            anchors.right: isPairingIssue ? wifiNetworkStatus.left : parent.left
                            anchors.rightMargin: vpx(10)
                            //anchors.verticalCenter: parent.verticalCenter
                            anchors.bottom: parent.bottom
                            anchors.bottomMargin: vpx(10)
                            color: themeColor.textLabel
                            font.pixelSize: (parent.fontSize)*getIconRatio(icon)
                            font.family: iconfont //globalFonts.awesome
                            height: parent.height
                            text : icon
                            visible: true  //parent.focus
                        }
                        Text {
                            id: wifiNetworkStatus

                            anchors.right: parent.left
                            anchors.rightMargin: vpx(5)
                            anchors.top: parent.top
                            anchors.topMargin: vpx(5)

                            color: "red"
                            font.pixelSize: (parent.fontSize)*2
                            font.family: globalFonts.ion
                            height: parent.height
                            text : "\uf22a"
                            visible: isPairingIssue
                        }

                        label: {
                            return (macaddress + " / " + vendor + " / " + name + " " + service)
                        }
                        // set focus only on first item
                        focus: index == 0 ? true : false

                        onActivate: {
                            //to force change of focus
                            confirmDialog.focus = false;
                            confirmDialog.setSource("../../dialogs/Generic3ChoicesDialog.qml",
                                                    { "title": wifiNetworksModel.get(index).vendor + " " + wifiNetworksModel.get(index).name + " " + wifiNetworksModel.get(index).service,
                                                      "message": qsTr("Do you want to pair or ignored this device ?") + api.tr,
                                                      "symbol": wifiNetworksModel.get(index).icon,
                                                      "symbolfont" : wifiNetworksModel.get(index).iconfont,
                                                      "firstchoice": qsTr("Pair") + api.tr,
                                                      "secondchoice": qsTr("Ignored") + api.tr,
                                                      "thirdchoice": qsTr("Cancel") + api.tr});
                            //Save action states for later
                            actionState = "Pair";
                            actionListIndex = index;
                            //to force change of focus
                            confirmDialog.focus = true;
                            //focus = true;

                        }

                        onFocusChanged: container.onFocus(this)
                        Keys.onPressed: {
                            //verify if finally other lists are empty or not when we are just before to change list
                            //it's a tip to refresh the KeyNavigations value just before to change from one list to an other
                            if ((event.key === Qt.Key_Up) && !event.isAutoRepeat) {
                                if (index !== 0) KeyNavigation.up = myDiscoveredDevices.itemAt(index-1);
                                else if (myDevices.count !== 0){
                                    KeyNavigation.up = myDevices.itemAt(myDevices.count-1);
                                }
                                else KeyNavigation.up = myDiscoveredDevices.itemAt(0);
                            }
                            if ((event.key === Qt.Key_Down) && !event.isAutoRepeat) {
                                if (index < myDiscoveredDevices.count-1) KeyNavigation.down = myDiscoveredDevices.itemAt(index+1);
                                else if (myIgnoredDevices.count !== 0){
                                    KeyNavigation.down = myIgnoredDevices.itemAt(0);
                                }
                                else KeyNavigation.down = myDiscoveredDevices.itemAt(myDiscoveredDevices.count-1);                            }
                        }

                        Button {
                            id: pairButton
                            property int fontSize: vpx(22)
                            height: fontSize * 1.5
                            text: qsTr("Pair/Ignore ?") + api.tr
                            visible: parent.focus
                            anchors.left: parent.right
                            anchors.leftMargin: vpx(20)
                            anchors.verticalCenter: parent.verticalCenter
                            
							contentItem: Text {
                                text: pairButton.text
                                font.pixelSize: fontSize
                                font.family: globalFonts.sans
                                opacity: 1.0
                                color: themeColor.textSectionTitle
                                horizontalAlignment: Text.AlignHCenter
                                verticalAlignment: Text.AlignVCenter
                                elide: Text.ElideRight
                            }
							
							background: Rectangle {
                                implicitWidth: 100
                                implicitHeight: parent.height
                                opacity: 1.0
                                border.color: themeColor.textSectionTitle
                                color: themeColor.textLabel
                                border.width: 3
                                radius: 25
                            }
                        }
                    }
                }
            }
        }
    }
}
