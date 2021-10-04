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

//command line for bluetooth: 
// # hcitool scan | grep -v '^S'
// Scanning ...
        // 3C:BD:3E:C1:13:F7       Bureau
        // 00:9E:C8:D9:7C:6B       xiaomi wifi speaker
        // 48:A5:E7:5D:41:87       SNES Controller
// /recalbox/scripts/bluetooth/recalpair 48:A5:E7:5D:41:87 snes
// /recalbox/scripts/bluetooth/test-discovery & ( PID=$! ; sleep 15 ; kill -15 $PID)

// #scan bluetooth
// sh /recalbox/scripts/recalbox-config.sh hcitoolscan | awk '/▶/||/▷/' | awk '{for(i=2;i<=NF;i++) printf("%s%s",$i,(i==2) ? ";" : (i==NF) ? "\n" : " ");}'
// 4C:16:A9:94:21:EB;4C-16-A9-94-21-EB
// 3C:BD:3E:C1:13:F7;Bureau
// 00:9E:C8:D9:7C:6B;xiaomi wifi speaker
// 48:A5:E7:5D:AF:EB;SNES Controller
// 48:A5:E7:5D:41:87;SNES Controller

// #pair
// sh recalbox-config.sh hiddpair 'SNES controller' 48:A5:E7:5D:AF:EB
// bluetoothctl info AC:FD:93:C9:9D:44 | grep -i 'paired' | awk '{print $2}'
// yes
// #icon (type of device)
// bluetoothctl info AC:FD:93:C9:9D:44 | grep -i 'icon' | awk '{print $2}'
// input-gaming

// #paired-devices
// # bluetoothctl paired-devices | awk '{print $2}'
// 48:A5:E7:5D:AF:EB
// 48:A5:E7:5D:41:87
// # bluetoothctl paired-devices
// Device 48:A5:E7:5D:AF:EB SNES Controller
// Device 48:A5:E7:5D:41:87 SNES Controller

// #unpair
// python /recalbox/scripts/bluetooth/test-device remove 48:A5:E7:5D:41:87
// python /recalbox/scripts/bluetooth/test-device remove 48:A5:E7:5D:AF:EB
// or bluetoothctl remove 48:A5:E7:5D:41:87

//#connected ?
// Switch Online SNES Controller //bluetoothctl info 48:A5:E7:5D:41:87 | grep -i 'connected' | awk '{print $2}'
// PS4 Controller //bluetoothctl info AC:FD:93:C9:9D:44 | grep -i 'connected' | awk '{print $2}'
//yes


import "common"
import "qrc:/qmlutils" as PegasusUtils
import QtQuick 2.12
import QtQuick.Controls 2.12
import QtQuick.Window 2.12
import QtBluetooth 5.2

FocusScope {
    id: root

//    //to load waitDialog
//    Timer{
//        id: waitDialogTimer
//        interval: 200 // launch after 200 ms
//        repeat: false
//        running: false
//        triggeredOnStart: false
//        onTriggered: {
//            //add wait dialogBox
//            waitDialog.focus = false;
//            waitDialog.setSource("../../dialogs/GenericWaitDialog.qml",
//                    { "title": qsTr("Pairing..."), "message": qsTr("Please wait...") });
//            waitDialog.focus = true;
//        }
//    }

//    //loader Wait Dialog including spinner
//    Loader {
//        id: waitDialog
//        anchors.fill: parent
//        z:20
//    }

//    Connections {
//        target: waitDialog.item
//        function onClose() {
//            content.focus = true;
//        }
//    }

    //to be able to follow action done on Bluetooth Devices Lists
    property var actionState : ""
    property var actionListIndex : 0

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
                    case "Forget":
                        //Bluetooth unPair device
						//stop scanning during Forgeting ;-)
						bluetoothTimer.running = false;
						btModel.running = false;
						var name = myDevicesModel.get(actionListIndex).name;
						var macaddress = myDevicesModel.get(actionListIndex).macaddress;
						var result = "";
						//launch unpairing
						if(api.internal.recalbox.getStringParameter("controllers.bluetooth.unpair.methods") === ""){
							//legacy method
							console.log("command:", "/recalbox/scripts/bluetooth/test-device remove " + macaddress);
							result = api.internal.system.run("/recalbox/scripts/bluetooth/test-device remove " + macaddress);
						}
						else{
							//simpler one
							console.log("command:", "bluetoothctl remove "+ macaddress);
							result = api.internal.system.run("bluetoothctl remove "+ macaddress);
						}
						console.log("result:",result);
						//relaunch scanning
						bluetoothTimer.running = true; // no need to restart btModel ecause timer will manage
						//ADD Check	of result
						//TO DO
						//for test purpose for the moment
                        //remove from list
                        myDevicesModel.remove(actionListIndex);
                        //save in recalbox.conf
                        saveDevicesList(myDevicesModel,"pegasus.bt.my.device");
                        //calculate focus depending available devices in each lists / to keep always a line with focus at minimum
                        if(myDevices.count !== 0){
                            if(myDevices.itemAt(actionListIndex)) myDevices.itemAt(actionListIndex).focus = true;
                            else if(myDevices.itemAt(actionListIndex-1)) myDevices.itemAt(actionListIndex-1).focus = true;
                        }
                        else{
                            if(myDiscoveredDevices.count !== 0) myDiscoveredDevices.itemAt(0).focus = true;
                            else if(myIgnoredDevices.count !== 0) myIgnoredDevices.itemAt(0).focus = true;
                        }
                    break;
                    case "Pair":
						//stop scanning during pairing
						bluetoothTimer.running = false;
						btModel.running = false;
						var name = myDiscoveredDevicesModel.get(actionListIndex).name;
						var macaddress = myDiscoveredDevicesModel.get(actionListIndex).macaddress;
						var result = "";
						//launch pairing
						if(api.internal.recalbox.getStringParameter("controllers.bluetooth.pair.methods") === ""){
							//legacy method
							console.log("command:", "sh /recalbox/scripts/recalbox-config.sh hiddpair '" + name + "' " + macaddress);
                            result = api.internal.system.runBoolResult("/recalbox/scripts/recalbox-config.sh hiddpair '" + name + "' " + macaddress);
						}
						else{
                            //do remove to avoid bad suprise
                            console.log("command:", "bluetoothctl remove "+ macaddress);
                            result = api.internal.system.run("bluetoothctl remove "+ macaddress);
                            console.log("result:",result);
                            //simpler one
							console.log("command:", "/recalbox/scripts/bluetooth/recalpair "+ macaddress + " '" + name + "'");
                            result = api.internal.system.runBoolResult("/recalbox/scripts/bluetooth/recalpair "+ macaddress + " '" + name + "'");
						}
						console.log("result:",result);
						//relaunch scanning
						bluetoothTimer.running = true; // no need to restart btModel ecause timer will manage
                        //Check	if really paired
                        console.log("command:", "bluetoothctl info " + macaddress + " | grep -i 'paired' | awk '{print $2}'");
                        result = api.internal.system.run("bluetoothctl info " + macaddress + " | grep -i 'paired' | awk '{print $2}'");
                        console.log("result:",result);
                        if(result.toLowerCase().includes("yes")){
                            //Add to My Devices list
                            myDevicesModel.append({icon: myDiscoveredDevicesModel.get(actionListIndex).icon,
                                         vendor: myDiscoveredDevicesModel.get(actionListIndex).vendor,
                                         name: myDiscoveredDevicesModel.get(actionListIndex).name,
                                         macaddress: myDiscoveredDevicesModel.get(actionListIndex).macaddress,
                                         service: myDiscoveredDevicesModel.get(actionListIndex).service});
                            //Remove from Discovered devices list
                            myDiscoveredDevicesModel.remove(actionListIndex);
                            //save in recalbox.conf
                            saveDevicesList(myDevicesModel,"pegasus.bt.my.device");
                        }
                        //calculate focus depending available devices in each lists / to keep always a line with focus at minimum
                        if(myDiscoveredDevices.count !== 0){
                            if(myDiscoveredDevices.itemAt(actionListIndex)) myDiscoveredDevices.itemAt(actionListIndex).focus = true;
                            else if(myDiscoveredDevices.itemAt(actionListIndex-1)) myDiscoveredDevices.itemAt(actionListIndex-1).focus = true;
                        }
                        else{
                            if(myDevices.count !== 0) myDevices.itemAt(myDevices.count-1).focus = true;
                            else if(myIgnoredDevices.count !== 0) myIgnoredDevices.itemAt(0).focus = true;
                        }
                    break;
                    case "Unblock":
                        //remove from list
                        myIgnoredDevicesModel.remove(actionListIndex);
                        //save in recalbox.conf
                        saveDevicesList(myIgnoredDevicesModel,"pegasus.bt.ignored.device");
                        //calculate focus depending available devices in each lists / to keep always a line with focus at minimum
                        if(myIgnoredDevices.count !== 0){
                            if(myIgnoredDevices.itemAt(actionListIndex)) myIgnoredDevices.itemAt(actionListIndex).focus = true;
                            else if(myIgnoredDevices.itemAt(actionListIndex-1)) myIgnoredDevices.itemAt(actionListIndex-1).focus = true;
                        }
                        else{
                            if(myDiscoveredDevices.count !== 0) myDiscoveredDevices.itemAt(myDiscoveredDevices.count-1).focus = true;
                            else if(myDevices.count !== 0) myDevices.itemAt(myDevices.count-1).focus = true;
                        }
                    break;

            }
            content.focus = true;
        }
        function onSecondChoice() {
            switch (actionState) {
                    case "Pair": // as ignored in fact for second choice
                        //Add to Ignored devices list
                        myIgnoredDevicesModel.append({icon: myDiscoveredDevicesModel.get(actionListIndex).icon,
                                     vendor: myDiscoveredDevicesModel.get(actionListIndex).vendor,
                                     name: myDiscoveredDevicesModel.get(actionListIndex).name,
                                     macaddress: myDiscoveredDevicesModel.get(actionListIndex).macaddress,
                                     service: myDiscoveredDevicesModel.get(actionListIndex).service});
                        //Remove from Discovered devices list
                        myDiscoveredDevicesModel.remove(actionListIndex);
                        //save in recalbox.conf
                        saveDevicesList(myIgnoredDevicesModel,"pegasus.bt.ignored.device");
                        //calculate focus depending available devices in each lists / to keep always a line with focus at minimum
                        if(myDiscoveredDevices.count !== 0){
                            if(myDiscoveredDevices.itemAt(actionListIndex)) myDiscoveredDevices.itemAt(actionListIndex).focus = true;
                            else if(myDiscoveredDevices.itemAt(actionListIndex-1)) myDiscoveredDevices.itemAt(actionListIndex-1).focus = true;
                        }
                        else{
                            if(myIgnoredDevices.count !== 0) myIgnoredDevices.itemAt(0).focus = true;
                            else if(myDevices.count !== 0) myDevices.itemAt(myDevices.count-1).focus = true;
                        }
                    break;
            }
            content.focus = true;
        }
        function onCancel() {
            //do nothing
            content.focus = true;
        }
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
                //console.log("At " + (bluetoothTimer.interval/1000)*counter + "s" + " - Found existing service " + macaddress + " - Name: " + name + " - Service: " + service);
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
            if(macaddress !== name.replace(/-/g, ':') || !api.internal.recalbox.getBoolParameter("controllers.bluetooth.hide.no.name")){
                //add to discovered list
                //set vendor later from API & mac address
                //we can't set vendor immediately, it will be done by timer
                myDiscoveredDevicesModel.append({icon: icon, vendor: "", name: name, macaddress: macaddress, service: service });
                //console.log("At " + (bluetoothTimer.interval/1000)*counter + "s" + " - Found new service " + macaddress + " - Name: " + name + " - Service: " + service);
            }
        }
    }

    //timer to relaunch bluetooth regularly for QT methods for the moment
    property var counter: 0
    Timer {
        id: bluetoothTimer
        interval: 1000 // Run the timer every second
        repeat: true
        running: true //(api.internal.recalbox.getStringParameter("controllers.bluetooth.scan.methods") !== "") ? true : false
        triggeredOnStart: true
        onTriggered: {

                if ((interval/1000)*counter === 2){ // wait 2 seconds before to scan bluetooth for the first time
                    //console.log("Start bluetooth scan... at ", (interval/1000)*counter," seconds")
                    btModel.running = false;
                    if(api.internal.recalbox.getStringParameter("controllers.bluetooth.scan.methods") !== ""){
                        btModel.running = true;
                    }
                    else{
                        console.log("legacy method:",api.internal.system.run("sh /recalbox/scripts/recalbox-config.sh hcitoolscan"));
                        //console.log("legacy method:",api.internal.system.run("ls -l /home"));

                    }
                }

                if ((interval/1000)*counter >= 90){ // restart every 90 seconds
                    //console.log("Restart bluetooth scan... after ", (interval/1000)*counter," seconds")
                    btModel.running = false;
                    btModel.running = (api.internal.recalbox.getStringParameter("controllers.bluetooth.scan.methods") !== "") ? true : false
                    counter = 0;
                }
                else counter = counter + 1;
        }
    }
    //timer to udpate status of MyDevices
    Timer {
        id: connectedTimer
        interval: 1000 // every seconds
        repeat: true
        running: true
        triggeredOnStart: false
        onTriggered: {
            var list = myDevicesModel;
            var macaddress = "";
            var result = "";
            for(var i = 0;i < list.count; i++){
                macaddress = list.get(i).macaddress;
                //console.log("command:", "bluetoothctl info " + macaddress + " | grep -i 'connected' | awk '{print $2}'");
                //result = "yes"; //for test purpose
                result = api.internal.system.run("bluetoothctl info " + macaddress + " | grep -i 'connected' | awk '{print $2}'");
                //console.log("result:",result);
                //check if device is connected
                if(result.toLowerCase().includes("yes")){
                    //update "connected" status
                    myDevices.itemAt(i).connected = true;
                }
                else
                {
                    //update "connected" status
                    myDevices.itemAt(i).connected = false;
                }
            }
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
                    if(vendor.includes("Not Found")) {
                        if(!api.internal.recalbox.getBoolParameter("controllers.bluetooth.hide.unknown.vendor")){
                            list.get(i).vendor = "Unknown vendor";
                        }
                        else{
                            //Remove from Discovered devices list
                            myDiscoveredDevicesModel.remove(i);
                            //calculate focus depending available devices in each lists / to keep always a line with focus at minimum
                            if(myDiscoveredDevices.count !== 0){
                                if(myDiscoveredDevices.itemAt(i)) myDiscoveredDevices.itemAt(i).focus = true;
                                else if(myDiscoveredDevices.itemAt(i-1)) myDiscoveredDevices.itemAt(i-1).focus = true;
                            }
                            else{
                                if(myDevices.count !== 0) myDevices.itemAt(myDevices.count-1).focus = true;
                                else if(myIgnoredDevices.count !== 0) myIgnoredDevices.itemAt(0).focus = true;
                            }
                        }
                    }
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
        discoveryMode: (api.internal.recalbox.getStringParameter("controllers.bluetooth.scan.methods") !== "") ? parseInt(api.internal.recalbox.getStringParameter("controllers.bluetooth.scan.methods")) : BluetoothDiscoveryModel.DeviceDiscovery //3 modes possible:  MinimalServiceDiscovery (0) or FullServiceDiscovery (1) or DeviceDiscovery (2)
        onDiscoveryModeChanged: {
            //console.log("Bluetooth Discovery mode: " + discoveryMode)
        }
        onServiceDiscovered: {
            updateDiscoveredDevicesLists(service.deviceName, service.deviceAddress, service.serviceName);
        }
        onDeviceDiscovered: {
            //don't udpate now because is not with all information
            //updateDiscoveredDevicesLists("", device, "");
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

    //Listview to catch 'deviceName' for DeviceDiscovery method only: sorry, it's a tips ;-) to hold the discovered device index/name/address
    ListView{
        id:hideview
        model: btModel
        visible: false
        delegate:Item {
            id:btdeviceName
            Component.onCompleted:
            {
                //console.log("deviceName: ", deviceName);
                if((Number(api.internal.recalbox.getStringParameter("controllers.bluetooth.scan.methods")) === BluetoothDiscoveryModel.DeviceDiscovery)
                        && (deviceName !== "")) updateDiscoveredDevicesLists(deviceName, remoteAddress, "");
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

        ListElement { icon: " \uf1e2 "; keywords: "headset,plt focus"; type:"audio"}
        ListElement { icon: " \uf1e1 "; keywords: "speaker"; type:"audio"}
        ListElement { icon: " \uf1b0 "; keywords: ""; types:"audio"} //as generic icon for audio

    }

    //to change icon size for audio ones especially and keep standard one for others.
    function getIconRatio(icon)
    {
        var ratio;
        switch(icon){
        case " \uf1e2 ":
            ratio = 2;
            break;
        case " \uf1e1 ":
            ratio = 2;
            break;
        case " \uf1b0 ":
            ratio = 2;
            break;
        default:
            ratio = 3;
            break;
        }
        return ratio;
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
    function saveDevicesList(list,parameter){
        //to populate list from recalbox.conf
        for(var i = 0; i < list.count; i++){
          var savedData = "";
          savedData = list.get(i).macaddress;
          savedData = savedData + "|" + list.get(i).vendor;
          savedData = savedData + "|" + list.get(i).name;
          savedData = savedData + "|" + list.get(i).service;
          api.internal.recalbox.setStringParameter(parameter + i, savedData);
        }
        //save an empty line at the end to confirm end of the list in reclbox.conf
        api.internal.recalbox.setStringParameter(parameter + i,"");
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
        readSavedDevicesList(myDevicesModel,"pegasus.bt.my.device");
        readSavedDevicesList(myIgnoredDevicesModel,"pegasus.bt.ignored.device");
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
                    visible: (myDevices.count !== 0) ? true : false
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
                        property var connected: false;
                        Text {
                            id: deviceIcon

                            anchors.right: connected ? deviceStatus.left : parent.left
                            anchors.verticalCenter: parent.verticalCenter
                            color: themeColor.textLabel
                            font.pixelSize: (parent.fontSize)*getIconRatio(icon)
                            font.family: globalFonts.awesome
                            height: parent.height
                            text : icon
                            visible: true  //parent.focus
                        }
                        Text {
                            id: deviceStatus

                            anchors.right: parent.left
                            anchors.rightMargin: vpx(10)
                            anchors.top: parent.top
                            anchors.topMargin: vpx(5)

                            color: connected ? "green" : "gray" //themeColor.textLabel
                            font.pixelSize: (parent.fontSize)*2
                            font.family: globalFonts.ion
                            height: parent.height
                            text : "\uf1f9"
                            visible: connected
                        }

                        label: {
                            return (macaddress + " - " + vendor + " " + name + " " + service)
                        }

                        // set focus only on first item
                        focus: index == 0 ? true : false

                        onActivate: {
                            //to force change of focus
                            confirmDialog.focus = false;
                            confirmDialog.setSource("../../dialogs/Generic3ChoicesDialog.qml",
                                                    { "title": myDevicesModel.get(index).vendor + " " + myDevicesModel.get(index).name + " " + myDevicesModel.get(index).service,
                                                      "message": qsTr("Are you sure to forget this device ?") + api.tr,
                                                      "symbol": myDevicesModel.get(index).icon,
                                                      "firstchoice": qsTr("Yes") + api.tr,
                                                      "secondchoice": "",
                                                      "thirdchoice": qsTr("No") + api.tr});
                            //Save action states for later
                            actionState = "Forget";
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
                                if (index !== 0) KeyNavigation.up = myDevices.itemAt(index-1);
                                else KeyNavigation.up = myDevices.itemAt(0);
                            }
                            if ((event.key === Qt.Key_Down) && !event.isAutoRepeat) {
                                if (index < myDevices.count-1) KeyNavigation.down = myDevices.itemAt(index+1);
                                else if (myDiscoveredDevices.count !== 0){
                                    KeyNavigation.down = myDiscoveredDevices.itemAt(0);
                                }
                                else if (myIgnoredDevices.count !== 0){
                                    KeyNavigation.down = myIgnoredDevices.itemAt(0);
                                }
                                else KeyNavigation.down = myDevices.itemAt(myDevices.count-1);
                            }
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
                    //Spinner Loader for discovered devices section
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
                            font.pixelSize: (parent.fontSize)*getIconRatio(icon)
                            font.family: globalFonts.awesome
                            height: parent.height
                            text : icon
                            visible: true  //parent.focus
                        }

                        label: {
                            return (macaddress + " - " + vendor + " " + name + " " + service)
                        }
                        // set focus only on first item
                        focus: index == 0 ? true : false

                        onActivate: {
                            //to force change of focus
                            confirmDialog.focus = false;
                            confirmDialog.setSource("../../dialogs/Generic3ChoicesDialog.qml",
                                                    { "title": myDiscoveredDevicesModel.get(index).vendor + " " + myDiscoveredDevicesModel.get(index).name + " " + myDiscoveredDevicesModel.get(index).service,
                                                      "message": qsTr("Do you want to pair or ignored this device ?") + api.tr,
                                                      "symbol": myDiscoveredDevicesModel.get(index).icon,
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

                SectionTitle {
                    text: qsTr("Ignored Devices") + api.tr
                    first: false
                    visible: (myIgnoredDevices.count !== 0) ? true : false
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
                            font.pixelSize: (parent.fontSize)*getIconRatio(icon)
                            font.family: globalFonts.awesome
                            height: parent.height
                            text : icon
                            visible: true  //parent.focus
                        }

                        label: {
                            return (macaddress + " - " + vendor + " " + name + " " + service)
                        }

                        // set focus only on first item
                        focus: index == 0 ? true : false

                        onActivate: {
                            //to force change of focus
                            confirmDialog.focus = false;
                            confirmDialog.setSource("../../dialogs/Generic3ChoicesDialog.qml",
                                                    { "title": myIgnoredDevicesModel.get(index).vendor + " " + myIgnoredDevicesModel.get(index).name + " " + myIgnoredDevicesModel.get(index).service,
                                                      "message": qsTr("Are you sure to unblock this device ?") + api.tr,
                                                      "symbol": myIgnoredDevicesModel.get(index).icon,
                                                      "firstchoice": qsTr("Yes") + api.tr,
                                                      "secondchoice": "",
                                                      "thirdchoice": qsTr("No") + api.tr});
                            //Save action states for later
                            actionState = "Unblock";
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
                                if (index !== 0) KeyNavigation.up = myIgnoredDevices.itemAt(index-1);
                                else if(myDiscoveredDevices.count !== 0) {
                                    KeyNavigation.up = myDiscoveredDevices.itemAt(myDiscoveredDevices.count-1);
                                }
                                else if(myDevices.count !== 0){
                                    KeyNavigation.up = myDevices.itemAt(myDevices.count-1);
                                }
                                else KeyNavigation.up = myIgnoredDevices.itemAt(0);
                            }
                            if ((event.key === Qt.Key_Down) && !event.isAutoRepeat) {
                                if(index < myIgnoredDevices.count-1) KeyNavigation.down = myIgnoredDevices.itemAt(index+1);
                                else KeyNavigation.down = myIgnoredDevices.itemAt(myIgnoredDevices.count-1)                          }
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
