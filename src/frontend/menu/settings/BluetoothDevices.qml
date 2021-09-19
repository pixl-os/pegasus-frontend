// Pegasus Frontend
//
// Created by BozoTheGeek 13/09/2021
//

//Notes/Information!
//API to get vendor is very simple: https://api.macvendors.com/FC-A1-3E-2A-1C-33
//API to get vendor is very simple: https://api.macvendors.com/B8-27-EB-A4-59-08
//API to get vendor is very simple: https://api.macvendors.com/FC:FB:FB:01:FA:21
//Basic reply could be get as a simple html text as: "Samsung Electronics Co.,Ltd"
//example of pairing on rpi: https://pimylifeup.com/xbox-controllers-raspberry-pi/

import "common"
import "qrc:/qmlutils" as PegasusUtils
import QtQuick 2.12
import QtQuick.Controls 2.12
import QtQuick.Window 2.12
import QtBluetooth 5.12

FocusScope {
    id: root

    //loader to load confirm dialog
    Loader {
        id: confirmDialog
        anchors.fill: parent
    }
    Connections {
        target: confirmDialog.item
        function onAccept() { content.focus = true; }
        function onCancel() { content.focus = true; }
        function onClose() { content.focus = true; }
    }


    //function to get text content of html page
    function httpGet(theUrl)
    {
        var xmlHttp = new XMLHttpRequest();
        xmlHttp.open( "GET", theUrl, false ); // false for synchronous request
        xmlHttp.send( null );
        return xmlHttp.responseText;
    }

    //function to search device in a list
    function searchDeviceInList(list, name, macaddress, service){
        for(var i = 0;i < list.count; i++){
            if (list.get(i).name === name &&
                list.get(i).macaddress === macaddress &&
                list.get(i).service === service){
                return true;
            }
        }
        return false;
    }

    //function to add new discovered device using 'known' devices as My Devices or Ignored ones
    function updateDiscoveredDevicesLists(name, macaddress, service){
        var found = false;
        //check device already in "Devices ignored"
        found = searchDeviceInList(myIgnoredDevicesModel, name, macaddress, service);
        //check device already in "My Devices"
        if(!found) found = searchDeviceInList(myDevicesModel, name, macaddress, service);
        //check device already in "Discovered Devices"
        if(!found) found = searchDeviceInList(myDiscoveredDevicesModel, name, macaddress, service);
        if (!found){
            //set icon from service name
            let icon = getIcon(name,service);
            //set vendor from API & mac address
            //we can't set vendor immediately, it will be done by timer
            //add to discovered list
            myDiscoveredDevicesModel.append({icon: icon, vendor: "", name: name, macaddress: macaddress, service: service });
            console.log("At " + (bluetoothTimer.interval/1000)*counter + "s" + " - Found new service " + macaddress + " - Name: " + name + " - Service: " + service);
        }
    }

    //timer to relaunch bluetooth regularly
    property var counter: 0
    Timer {
        id: bluetoothTimer
        interval: 5000 // Run the timer every 5 seconds
        repeat: true
        running: true
        triggeredOnStart: true
        onTriggered: {
                if ((interval/1000)*counter >= 90){ // restart every 90 seconds
                    console.log("Restart bluetooth scan... after ", (interval/1000)*counter," seconds")
                    btModel.running = false;
                    btModel.running = true;
                    counter = 0;
                }
                else counter = counter + 1;
        }
    }
    //timer to udpate the vendor value in Discovered Devices
    Timer {
        id: vendorTimer
        interval: 2000 // every 2 seconds to avoid saturation of server
        repeat: true
        running: true
        triggeredOnStart: true
        onTriggered: {
            var list = myDiscoveredDevicesModel;
            var vendor = "";
            for(var i = 0;i < list.count; i++){
                if ((list.get(i).vendor === "") && (vendor === "")){
                    //search vendor from macadress
                    vendor = httpGet("https://api.macvendors.com/" + list.get(i).macaddress);
                    //console.log("return of https://api.macvendors.com for ",list.get(i).macaddress," : ", vendor);
                    if(vendor.includes("Not Found")) list.get(i).vendor = "Unknown vendor";
                    else if(vendor.includes("errors")) list.get(i).vendor = "";
                    else list.get(i).vendor = vendor;
                }
                else if(list.get(i).vendor === "")
                {
                    //search if previous search is for the same device
                    //console.log("Check vendor mac part: ",list.get(i).macaddress.substring(0,8));
                    if(list.get(i).macaddress.substring(0,8) === list.get(i-1).macaddress.substring(0,8)){
                        //console.log("Same vendor: ",list.get(i-1).vendor);
                        list.get(i).vendor = list.get(i-1).vendor;
                    }
                    else break;
                }
            }
        }
    }


    //to scan bluetooth devices
    property BluetoothService currentService
    BluetoothDiscoveryModel {
        id: btModel
        running: false
        discoveryMode: BluetoothDiscoveryModel.FullServiceDiscovery //3 modes possible: FullServiceDiscovery or MinimalServiceDiscovery or DeviceDiscovery
        onDiscoveryModeChanged: console.log("Discovery mode: " + discoveryMode)
        onServiceDiscovered: {
            updateDiscoveredDevicesLists(service.deviceName, service.deviceAddress, service.serviceName);
        }
        onDeviceDiscovered: {
            updateDiscoveredDevicesLists("", device, "");
        }
        onErrorChanged: {
                switch (btModel.error) {
                case BluetoothDiscoveryModel.PoweredOffError:
                    console.log("Error: Bluetooth device not turned on"); break;
                case BluetoothDiscoveryModel.InputOutputError:
                    console.log("Error: Bluetooth I/O Error"); break;
                case BluetoothDiscoveryModel.InvalidBluetoothAdapterError:
                    console.log("Error: Invalid Bluetooth Adapter Error"); break;
                case BluetoothDiscoveryModel.NoError:
                    console.log("Error: Bluetooth device No Error"); break;
                default:
                    console.log("Error: Unknown Error"); break;
                }
        }
    }
    //list model to manage type of devices
    ListModel {
        id: myDeviceTypes
        ListElement { type: "controller"; keywords: "controller,gamepad,stick"} //as XBOX for the moment, need icon for 360
        ListElement { type: "audio"; keywords: "audio,av,headset,speaker"} //as XBOX for the moment, need icon for 360
    }

    //list model to manage icons of devices
    ListModel {
        id: myDeviceIcons

        ListElement { icon: " \uf2f0 "; keywords: "x360,xbox360,xbox 360"; type:"controller"} //as XBOX for the moment, need icon for 360
        ListElement { icon: " \uf2f0 "; keywords: "xbox one"; type:"controller"}
        ListElement { icon: " \uf2f0 "; keywords: "xbox series"; type:"controller"} //as XBOX one for the moment, need icon for series
        ListElement { icon: " \uf2f0 "; keywords: "xbox,microsoft"; type:"controller"} //as XBOX for the moment, need icon for 360

        ListElement { icon: " \uf2ca "; keywords: "ps5,playstation 5,dualsense"; type:"controller"} //as PS4 for the moment, need icon for PS5
        ListElement { icon: " \uf2ca "; keywords: "ps4,playstation 4,dualshock 4"; type:"controller"}
        ListElement { icon: " \uf2c9 "; keywords: "ps3,playstation 3,dualshock 3"; type:"controller"}
        ListElement { icon: " \uf2c8 "; keywords: "ps2,playstation 2,dualshock 2"; type:"controller"}
        ListElement { icon: " \uf275 "; keywords: "ps1,psx,playstation,dualshock 1"; type:"controller"}

        ListElement { icon: " \uf25e "; keywords: "snes,super nintendo"; type:"controller"}
        ListElement { icon: " \uf25c "; keywords: "nes,nintendo entertainment system"; type:"controller"}
        ListElement { icon: " \uf262 "; keywords: "gc,gamecube"; type:"controller"}
        ListElement { icon: " \uf260 "; keywords: "n64,nintendo 64,nintendo64"; type:"controller"}
        ListElement { icon: " \uf263 "; keywords: "wii"; type:"controller"}

        ListElement { icon: " \uf26a "; keywords: "mastersystem,master system"; type:"controller"}
        ListElement { icon: " \uf26b "; keywords: "megadrive,mega drive,sega"; type:"controller"}

        ListElement { icon: " \uf1e2 "; keywords: "headset"; type:"audio"}
        ListElement { icon: " \uf1e1 "; keywords: "speaker"; type:"audio"}
        ListElement { icon: " \uf1b0 "; keywords: ""; types:"audio"} //as generic icon for audio

    }
    //little function to faciliate check of value in 2 name and service from a keyword
    function isKeywordFound(name,service,keyword)
    {
        if(name.toLowerCase().includes(keyword)||service.toLowerCase().includes(keyword)){
            return true;
        }
        else return false;
    }

    //function to dynamically set icon "character" from name and/or service
    function getIcon(name,service)
    {
        let icon = "";
        let type = "";
        let i = 0;
        //search the good type
         do{
             const typeKeywords = myDeviceTypes.get(i).keywords.split(",");
             for(var j = 0; j < typeKeywords.length;j++)
             {
                 if (isKeywordFound(name, service, typeKeywords[j])) type = myDeviceTypes.get(i).type;
             }
             i = i + 1;
         }while (type === "" && i < myDeviceTypes.count)
        //reset counter
         i = 0;
        //searchIcon using the good type
        do{
            const iconKeywords = myDeviceIcons.get(i).keywords.split(",");
            for(var k = 0; k < iconKeywords.length;k++)
            {
                if (isKeywordFound(name, service, iconKeywords[k]) && (myDeviceIcons.get(i).type === type || ((type === "") && (iconKeywords[k] !== "")))){
                    icon = myDeviceIcons.get(i).icon;
                }
            }
            i = i + 1;
        }while (icon === "" && i < myDeviceIcons.count)

        return icon;
    }

    //function to read saved data from recalbox.conf. Could be used for My Devices and Ignored Devices
    function readSavedDevicesList(list,parameter){
        let result = "";
        let i = 0;

        //to populate list from recalbox.conf
        do {
          result = api.internal.recalbox.getStringParameter(parameter + i);
          if (result !== ""){
                const parameters = result.split("|");
                let icon = getIcon(parameters[2],parameters[3])
                list.append({icon: icon, vendor: parameters[1], name: parameters[2], macaddress: parameters[0], service: parameters[3] });
          }
          i = i + 1;
        } while (result !== "");
    }

    Component.onCompleted:{
        readSavedDevicesList(myIgnoredDevicesModel,"pegasus.bt.ignored.device")
        readSavedDevicesList(myDevicesModel,"pegasus.bt.my.device")
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
        text: qsTr("Controllers > Bluetooth devices") + api.tr
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
                    text: qsTr("My Devices") + api.tr
                    first: true
                }

                ListModel {
                    id: myDevicesModel
                    //for test purpose only
                    //ListElement { icon: " \uf2f0 "; vendor: "Microsoft" ; name: "Xbox one series controler"; macaddress: "00:11:22:33:FF:EE" }
                    //ListElement { icon: " \uf2ca "; vendor: "Sony" ; name: "PS4 controller"; macaddress: "00:33:11:33:FF:EE" }
                    //ListElement { icon: " \uf1e2 "; vendor: "Boss" ; name: "Bluetooth headset"; macaddress: "00:12:22:55:FA:E1" }
                }

                Repeater {
                    id: myDevices
                    model: myDevicesModel //for test purpose
                    SimpleButton {

                        Text {
                            id: deviceIcon

                            anchors.right: parent.left
                            anchors.verticalCenter: parent.verticalCenter
                            color: themeColor.textLabel
                            font.pixelSize: (parent.fontSize)*3
                            font.family: globalFonts.awesome
                            height: parent.height
                            text : icon
                            visible: parent.focus
                        }

                        label: {
                            return (macaddress + " - " + vendor + " " + name)
                        }

                        // set focus only on first item
                        focus: index == 0 ? true : false

                        onActivate: {
//                            //focus = true;
//                            confirmDialog.setSource("../../dialogs/GenericOkCancelDialog.qml",
//                                { "title": qsTr("My Devices"),
//                                  "message": qsTr("Are you sure that you ant to forget this device ?") + "\n"
//                                  + "(" +  myDevicesModel.get(index).vendor + " " + myDevicesModel.get(index).name + " " + myDevicesModel.get(index).service + ")"
//								  //,"symbol": myDevicesModel.get(index).icon
//                                });
//                            confirmDialog.active = true;
//                            confirmDialog.focus = true;
                            //add dialogBox
                            confirmDialog.focus = false;
                            confirmDialog.setSource("../../dialogs/Generic3ChoicesDialog.qml",
                                { "title": qsTr("New type of controller detected") + api.tr,
                                  "message": qsTr("Press any button to continue") + "\n(" + qsTr("please read instructions at the bottom of next view to understand possible actions") + "\n" + qsTr("mouse and keyboard could be used to help configuration") + ")" + api.tr});
                            confirmDialog.focus = true;


                        }

                        onFocusChanged: container.onFocus(this)
                        KeyNavigation.up:{
                            if (index !== 0) return myDevices.itemAt(index-1);
                            else return myDevices.itemAt(0);
                        }
                        KeyNavigation.down:{
                                if (index < myDevices.count-1) return myDevices.itemAt(index+1);
                                else if (myDiscoveredDevices.count !== 0) return myDiscoveredDevices.itemAt(0);
                                else if (myIgnoredDevices.count !== 0) return myIgnoredDevices.itemAt(0);
                                else return myDevices.itemAt(myDevices.count-1);
                        }

                        Button {
                            id: forgetButton
                            property int fontSize: vpx(22)
                            height: fontSize * 1.5
                            text: qsTr("Forget") + " ?"  + api.tr
                            visible: parent.focus
                            anchors.left: parent.right
                            anchors.leftMargin: vpx(20)
                            anchors.verticalCenter: parent.verticalCenter
                            
							contentItem: Text {
                                text: forgetButton.text
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

                SectionTitle {
                    text: qsTr("Discovered devices") + api.tr
                    first: false
                    //Spinner Loader for all views loading... (principally for main menu for the moment)
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
                    id: myDiscoveredDevicesModel
                    //ListElement { icon: ""; vendor: "Nintendo" ; name: "Switch Pro controller"; macaddress: "45:12:64:33:FF:EE" }
                }

               Repeater {
                    id: myDiscoveredDevices
                    model: myDiscoveredDevicesModel //for test purpose
                    SimpleButton {

                        Text {
                            id: deviceDiscoveredIcon

                            anchors.right: parent.left
                            anchors.verticalCenter: parent.verticalCenter
                            color: themeColor.textLabel
                            font.pixelSize: (parent.fontSize)*3
                            font.family: globalFonts.awesome
                            height: parent.height
                            text : icon
                            visible: parent.focus
                        }

                        label: {
                            return (macaddress + " - " + vendor + " " + name + " " + service)
                        }

                        // set focus only on first item
                        focus: index == 0 ? true : false

                        onActivate: {
                            //console.log("root.openEmulatorConfiguration()");
                            //focus = true;
                        }

                        onFocusChanged: container.onFocus(this)
                        KeyNavigation.up:{
                            if (index !== 0) return myDiscoveredDevices.itemAt(index-1);
                            else if (myDevices.count !== 0) return myDevices.itemAt(myDevices.count-1);
                            else return myDiscoveredDevices.itemAt(0);
                        }
                        KeyNavigation.down:{
                            if (index < myDiscoveredDevices.count-1) return myDiscoveredDevices.itemAt(index+1);
                            else if (myIgnoredDevices.count !== 0) return myIgnoredDevices.itemAt(0);
                            else return myDiscoveredDevices.itemAt(myDiscoveredDevices.count-1);
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

                SectionTitle {
                    text: qsTr("Ignored Devices") + api.tr
                    first: false
                }

                ListModel {
                    id: myIgnoredDevicesModel
                    //for test purpose only ListElement { icon: ""; vendor: "Xiaomi corporation" ; name: "smartphone X678"; macaddress: "25:12:36:33:FF:EE" }
                }

                Repeater {
                    id: myIgnoredDevices
                    model: myIgnoredDevicesModel
                    SimpleButton {

                        Text {
                            id: deviceIgnoredIcon

                            anchors.right: parent.left
                            anchors.verticalCenter: parent.verticalCenter
                            color: themeColor.textLabel
                            font.pixelSize: (parent.fontSize)*3
                            font.family: globalFonts.awesome
                            height: parent.height
                            text : icon
                            visible: parent.focus
                        }

                        label: {
                            return (macaddress + " - " + vendor + " " + name)
                        }

                        // set focus only on first item
                        focus: index == 0 ? true : false

                        onActivate: {
                            //console.log("root.openEmulatorConfiguration()");
                            //focus = true;

                            //root.pairBluetoothDevice(modelData);

                        }

                        onFocusChanged: container.onFocus(this)
                        KeyNavigation.up:{
                            if (index !== 0) return myIgnoredDevices.itemAt(index-1);
                            else if(myDiscoveredDevices.count !== 0) return myDiscoveredDevices.itemAt(myDiscoveredDevices.count-1);
                            else if(myDevices.count !== 0) return myDevices.itemAt(myDevices.count-1);
                            else return myIgnoredDevices.itemAt(0);
                        }
                        KeyNavigation.down:{
                            if(index < myIgnoredDevices.count-1) return myIgnoredDevices.itemAt(index+1);
                            else return myIgnoredDevices.itemAt(myIgnoredDevices.count-1)
                        }

                        Button {
                            id: unblockButton
                            property int fontSize: vpx(22)
                            height: fontSize * 1.5
                            text: qsTr("Unblock") + " ?"  + api.tr
                            visible: parent.focus
                            anchors.left: parent.right
                            anchors.leftMargin: vpx(20)
                            anchors.verticalCenter: parent.verticalCenter
                            
							contentItem: Text {
                                text: unblockButton.text
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
