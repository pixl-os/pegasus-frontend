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

//#battery info 
//# ls '/sys/class/power_supply/' | grep -i 'AC:FD:93:C9:9D:44'
//sony_controller_battery_ac:fd:93:c9:9d:44
//for PS4
//cat '/sys/class/power_supply/sony_controller_battery_ac:fd:93:c9:9d:44/capacity'
//60
//for nintendo HID
//cat '/sys/class/power_supply/nintendo_switch_controller_battery_0005:057E:2009.000D/capacity_level'
//full
//cat '/sys/class/power_supply/nintendo_switch_controller_battery_0005:057E:2007.000C/capacity_level'
//
//or to know the good file to check
//ls '/sys/class/power_supply/sony_controller_battery_ac:fd:93:c9:9d:44/' | grep -i 'capacity'
//capacity
//ls '/sys/class/power_supply/nintendo_switch_controller_battery_0005:057E:2009.000D/' | grep -i 'capacity'
//capacity_level
//ls '/sys/class/power_supply/nintendo_switch_controller_battery_0005:057E:2007.000C/' | grep -i 'capacity'
//capacity_level
//to get modalias reference to find battery for nintendo HID
// # bluetoothctl info 98:B6:EB:FD:33:AB |grep -i 'modalias'  | awk -v FS="(v|p)" '{print $2}'
// 057E
// # bluetoothctl info 98:B6:EB:FD:33:AB |grep -i 'modalias'  | awk -v FS="(p|d)" '{print $3}'
// 2009
//5 level known from linux hid-nintendo:
//	[POWER_SUPPLY_CAPACITY_LEVEL_UNKNOWN]	= "Unknown",
//	[POWER_SUPPLY_CAPACITY_LEVEL_CRITICAL]	= "Critical",
//	[POWER_SUPPLY_CAPACITY_LEVEL_LOW]	= "Low",
//	[POWER_SUPPLY_CAPACITY_LEVEL_NORMAL]	= "Normal",
//	[POWER_SUPPLY_CAPACITY_LEVEL_HIGH]	= "High",
//	[POWER_SUPPLY_CAPACITY_LEVEL_FULL]	= "Full",

import "common"
import "qrc:/qmlutils" as PegasusUtils
import QtQuick 2.12
import QtQuick.Controls 2.12
import QtQuick.Window 2.12
import QtBluetooth 5.2

FocusScope {
    id: root

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
                            //add timeout of 5s if needed
                            result = api.internal.system.run("timeout 5 /recalbox/scripts/bluetooth/test-device remove " + macaddress);
						}
						else{
							//simpler one
							console.log("command:", "bluetoothctl remove "+ macaddress);
                            //add timeout of 5s if needed
                            if(!isDebugEnv()) result = api.internal.system.run("timeout 5 bluetoothctl remove "+ macaddress);
                            else result = api.internal.system.run("timeout 5 echo -e 'remove " + macaddress + "' | bluetoothctl");
						}
						console.log("result:",result);
						//relaunch scanning
                        bluetoothTimer.running = true; // no need to restart btModel because timer will manage
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
                        //stop scanning/checking during pairing
						bluetoothTimer.running = false;
                        connectedTimer.running = false;
                        btModel.running = false;
                        var name = myDiscoveredDevicesModel.get(actionListIndex).name;
						var macaddress = myDiscoveredDevicesModel.get(actionListIndex).macaddress;
						var result = "";
						//launch pairing
						if(api.internal.recalbox.getStringParameter("controllers.bluetooth.pair.methods") === ""){
							//legacy method
                            console.log("command:", "/recalbox/scripts/recalbox-config.sh hiddpair '" + name + "' " + macaddress);
                            //timeout of 30s if needed
                            result = api.internal.system.runBoolResult("timeout 30 /recalbox/scripts/recalbox-config.sh hiddpair '" + name + "' " + macaddress, false);
						}
						else{
                            //do remove to avoid bad suprise
                            console.log("command:", "bluetoothctl remove "+ macaddress);
                            //timeout of 5s if needed
                            if(!isDebugEnv()) result = api.internal.system.run("timeout 5 bluetoothctl remove "+ macaddress);
                            else result = api.internal.system.run("timeout 5 echo -e 'remove " + macaddress + "' | bluetoothctl");
                            console.log("result:",result);
                            //simpler one
							console.log("command:", "/recalbox/scripts/bluetooth/recalpair "+ macaddress + " '" + name + "'");
                            //timeout of 60s if needed
                            result = api.internal.system.runBoolResult("timeout 60 /recalbox/scripts/bluetooth/recalpair "+ macaddress + " '" + name + "'", false);
                            //add connect command to correct some issues with some devices too long to connected
                            console.log("command:", "bluetoothctl connect " + macaddress);
                            //timeout 15s if needed
                            if(!isDebugEnv()) result = api.internal.system.run("timeout 15 bluetoothctl connect " + macaddress);
                            else result = api.internal.system.run("timeout 15 echo -e 'connect " + macaddress + "' | bluetoothctl");

						}
						console.log("result:",result);
                        //Check	if really paired
                        console.log("command:", "bluetoothctl info " + macaddress + " | grep -i 'paired' | awk '{print $2}'");
                        //timeout of 2s or 5s if needed
                        if(!isDebugEnv()) result = api.internal.system.run("timeout 2 bluetoothctl info " + macaddress + " | grep -i 'paired' | awk '{print $2}'");
                        else result = api.internal.system.run("timeout 5 echo -e 'info " + macaddress + "' | bluetoothctl | grep -i 'paired' | awk '{print $2}'");

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
                        else myDiscoveredDevices.itemAt(actionListIndex).isPairingIssue = true;
                        //calculate focus depending available devices in each lists / to keep always a line with focus at minimum
                        if(myDiscoveredDevices.count !== 0){
                            if(myDiscoveredDevices.itemAt(actionListIndex)) myDiscoveredDevices.itemAt(actionListIndex).focus = true;
                            else if(myDiscoveredDevices.itemAt(actionListIndex-1)) myDiscoveredDevices.itemAt(actionListIndex-1).focus = true;
                        }
                        else{
                            if(myDevices.count !== 0) myDevices.itemAt(myDevices.count-1).focus = true;
                            else if(myIgnoredDevices.count !== 0) myIgnoredDevices.itemAt(0).focus = true;
                        }
                        //relaunch scanning
                        bluetoothTimer.running = true; // no need to restart btModel because timer will manage
                        connectedTimer.running = true
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
                    case "Pair": // as "Ignored" in fact for second choice
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
                    case "Forget": // as "Disconnect" in fact for second choice
                        //just a simple tentative to disconnect the device "sofwarely" ;-)
                        //stop scanning during disconnect
                        bluetoothTimer.running = false;
                        btModel.running = false;
                        var macaddress = myDevicesModel.get(actionListIndex).macaddress;
                        var result = "";
                        console.log("command:", "bluetoothctl disconnect "+ macaddress);
                        //add timeout of 10s if needed
                        if(!isDebugEnv()) result = api.internal.system.run("timeout 10 bluetoothctl disconnect "+ macaddress);
                        else result = api.internal.system.run("timeout 10 echo -e 'disconnect " + macaddress + "' | bluetoothctl");
                        console.log("result:",result);
                        //relaunch scanning
                        bluetoothTimer.running = true; // no need to restart btModel because timer will manage
                    break;
            }
            content.focus = true;
        }
        function onCancel() {
            //do nothing
            content.focus = true;
        }
    }

    //To keep only one line without CR or LF or hidden char
    function uniqueCleanLineCommand()
    {
        return " | head -n 1 | awk '{print $1}' | tr -d '\\n' | tr -d '\\r'";
    }

    //function to update vendor in any list using index
    function searchVendorAndUpdate(list, index){

        var xmlHttp = new XMLHttpRequest();
        var vendor = "";
        xmlHttp.open( "GET", "https://api.macvendors.com/" + list.get(index).macaddress, true ); // true for asynchronous request

        xmlHttp.timeout = 1900; // time in milliseconds

        xmlHttp.onload = function () {
            // Request finished.
            vendor = xmlHttp.responseText;
            console.log("return of https://api.macvendors.com for ",list.get(index).macaddress," : ", vendor);
            if(vendor.includes("Not Found")) {
                if(!api.internal.recalbox.getBoolParameter("controllers.bluetooth.hide.unknown.vendor")){
                    list.get(index).vendor = "Unknown vendor";
                }
                else{
                    //Remove from Discovered devices list
                    myDiscoveredDevicesModel.remove(index);
                    //calculate focus depending available devices in each lists / to keep always a line with focus at minimum
                    if(myDiscoveredDevices.count !== 0){
                        if(myDiscoveredDevices.itemAt(index)) myDiscoveredDevices.itemAt(index).focus = true;
                        else if(myDiscoveredDevices.itemAt(index-1)) myDiscoveredDevices.itemAt(index-1).focus = true;
                    }
                    else{
                        if(myDevices.count !== 0) myDevices.itemAt(myDevices.count-1).focus = true;
                        else if(myIgnoredDevices.count !== 0) myIgnoredDevices.itemAt(0).focus = true;
                    }
                }
            }
            else if(vendor.includes("errors")) list.get(index).vendor = "";
            else list.get(index).vendor = vendor;
        };
        xmlHttp.ontimeout = function (e) {
          // XMLHttpRequest timed out
          console.log("Timeout of https://api.macvendors.com for ",list.get(index).macaddress);
        };
        xmlHttp.send( null );
    }

    //function to search device in a list
    function searchDeviceInList(list, name, macaddress, service){
        //console.log("searchDeviceInList | to find Mac Address: '" + macaddress + "' - Name: '" + name + "' - Service: '" + service + "'");
		for(var i = 0;i < list.count; i++){
            //console.log("searchDeviceInList | found Mac Address: '" + list.get(i).macaddress + "' - Name: '" + list.get(i).name + "' - Service: '" + list.get(i).service + "'");
		    if (list.get(i).name === name &&
                list.get(i).macaddress === macaddress &&
                list.get(i).service === service){
                //console.log("searchDeviceInList | Match Mac Address: '" + list.get(i).macaddress + "' - Name: '" + list.get(i).name + "' - Service: '" + list.get(i).service + "'");
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
                        //to test with release version of recalbox - need to check if UI is blocked or not
                        console.log("legacy method: api.internal.system.run('sh /recalbox/scripts/recalbox-config.sh hcitoolscan')");
                        api.internal.system.runAsync("timeout 30 sh /recalbox/scripts/recalbox-config.sh hcitoolscan");
                        //var result = api.internal.system.runAsync("sleep 10");
                        //need to read later "cat /tmp/btlist" using timer in this case
                    }
                }
                // restart every 30 seconds if BluetoothDiscoveryModel.DeviceDiscovery is used
                if (((interval/1000)*counter >= 30) && (api.internal.recalbox.getStringParameter("controllers.bluetooth.scan.methods") === BluetoothDiscoveryModel.DeviceDiscovery)){
                    counter = 0;
                }
                // restart every 90 seconds for other methods
                else if ((interval/1000)*counter >= 90){
                    counter = 0;
                }
                else counter = counter + 1;
        }
    }

    Timer {
        id: readBtList
        interval: 5000 // Run the timer every 5 seconds
        repeat: true
        running: (api.internal.recalbox.getStringParameter("controllers.bluetooth.scan.methods") === "") ? true : false
        triggeredOnStart: false
        onTriggered: {
            //read file every 5 seconds
            var result = api.internal.system.run("cat /tmp/btlist");
            console.log("raw result:",result);
            const results = result.split('\n');
            for(var i=0;i<results.length-1;i++)
            {
                console.log("results[",i,"]:",results[i]);
                var remoteAddress = results[i].split(" ")[0]; //to take address
                var deviceName = results[i].replace(remoteAddress + " ",""); //to get everything execpt address + " "
                updateDiscoveredDevicesLists(deviceName, remoteAddress, "");
            }
        }
    }

    //timer to update status of battery in "My Devices"
    Timer {
        id: updateBatteryStatusTimer
        interval: 5000 // every 5 seconds to be able to detect that a controller is plug on usb / charging also
        repeat: true
        running: true
        triggeredOnStart: false
        onTriggered: {
            var list = myDevicesModel;
            var macaddress = "";
            var result = "";
            //Get a list for later else stop here.
            for(var i = 0;i < list.count; i++){
                    macaddress = list.get(i).macaddress;
                    myDevices.itemAt(i).batteryStatusText = getBatteryStatus(macaddress);
            }
        }
    }

    //timer to update status in  "My Devices"
    Timer {
        id: connectedTimer
        interval: 1000 // every 2 seconds
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
                if (!isDebugEnv()){
                    //timeout of 1s if needed (can't go under 1s else issue with timeout command on buildroot
                    result = api.internal.system.run("timeout 1 bluetoothctl info " + macaddress + " | grep -i 'connected' | awk '{print $2}'");
                }
                else{
                    result = api.internal.system.run("timeout 2 echo -e 'info " + macaddress + "' | bluetoothctl | grep -i 'connected' | awk '{print $2}'");
                }
                //console.log("result:",result);
                //check if device is connected
                if(result.toLowerCase().includes("yes")){
                    //update "connected" status & check status to avoid to call binding for no change
                    if (myDevices.itemAt(i).connected === false) {
                        myDevices.itemAt(i).connected = true;
                    }
                }
                else
                {
                    //update "connected" status & check status to avoid to call binding for no change
                    if (myDevices.itemAt(i).connected === true) {
                        myDevices.itemAt(i).connected = false;
                    }
                }
            }
        }
    }

    //timer to udpate the vendor value in Discovered Devices
    Timer {
        id: vendorTimer
        interval: 3000 // every 3 seconds to avoid saturation of server
        repeat: true
        running: true
        triggeredOnStart: true
        property int indexParameterToSaveLater : -1
        onTriggered: {

            //for My Devices just discovered
            var list = myDiscoveredDevicesModel;
            var oneAPICallDone = false; // to limit to one call every 2 seconds
            var i;

            for(i = 0;i < list.count; i++){
                if ((list.get(i).vendor === "") && !oneAPICallDone){
                    //search and update vendor from macadress
                    searchVendorAndUpdate(list, i)
                    oneAPICallDone = true;
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


            //for My Devices
            list = myDevicesModel;
            if(indexParameterToSaveLater !== -1){
                //Update to recalbox.conf in this case also
                /*console.log("Write of pegasus.bt.my.device",indexParameterToSaveLater,":",
                            list.get(indexParameterToSaveLater).macaddress + "|"
                            + list.get(indexParameterToSaveLater).vendor + "|"
                            + list.get(indexParameterToSaveLater).name + "|"
                            + list.get(indexParameterToSaveLater).service);*/
                api.internal.recalbox.setStringParameter("pegasus.bt.my.device" + indexParameterToSaveLater,
                                                         list.get(indexParameterToSaveLater).macaddress + "|"
                                                         + list.get(indexParameterToSaveLater).vendor + "|"
                                                         + list.get(indexParameterToSaveLater).name + "|"
                                                         + list.get(indexParameterToSaveLater).service);
                indexParameterToSaveLater = -1;
            }
            for(i = 0;i < list.count; i++){
                if ((list.get(i).vendor === "") && !oneAPICallDone){
                    //search and update vendor from macadress
                    searchVendorAndUpdate(list, i)
                    oneAPICallDone = true;
                    indexParameterToSaveLater = i;
                }
                else if(list.get(i).vendor === "" && indexParameterToSaveLater === -1)
                {
                    //search if previous search is for the same device
                    //console.log("Check vendor mac part: ",list.get(i).macaddress.substring(0,8));
                    if(list.get(i).macaddress.substring(0,8) === list.get(i-1).macaddress.substring(0,8)){
                        //console.log("Same vendor: ",list.get(i-1).vendor);
                        list.get(i).vendor = list.get(i-1).vendor;
                        indexParameterToSaveLater = i;
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

        ListElement { icon: "\uf2f0"; keywords: "x360,xbox360,xbox 360"; type:"controller"} //as XBOX for the moment, need icon for 360
        ListElement { icon: "\uf2f0"; keywords: "xbox one"; type:"controller"}
        ListElement { icon: "\uf2f0"; keywords: "xbox series"; type:"controller"} //as XBOX one for the moment, need icon for series
        ListElement { icon: "\uf2f0"; keywords: "xbox,microsoft"; type:"controller"} //as XBOX for the moment, need icon for 360

        ListElement { icon: "\uf2ca"; keywords: "ps5,playstation 5,dualsense"; type:"controller"} //as PS4 for the moment, need icon for PS5
        ListElement { icon: "\uf2ca"; keywords: "ps4,playstation 4,dualshock 4,wireless controller"; type:"controller"} // add wireless controller as usual PS name used by Sony
        ListElement { icon: "\uf2c9"; keywords: "ps3,playstation 3,dualshock 3"; type:"controller"}
        ListElement { icon: "\uf2c8"; keywords: "ps2,playstation 2,dualshock 2"; type:"controller"}
        ListElement { icon: "\uf275"; keywords: "ps1,psx,playstation,dualshock 1"; type:"controller"}

        ListElement { icon: "\uf25e"; keywords: "snes,super nintendo"; type:"controller"}
        ListElement { icon: "\uf25c"; keywords: "nes,nintendo entertainment system"; type:"controller"}
        ListElement { icon: "\uf262"; keywords: "gc,gamecube"; type:"controller"}
        ListElement { icon: "\uf260"; keywords: "n64,nintendo 64,nintendo64"; type:"controller"}
        ListElement { icon: "\uf263"; keywords: "wii"; type:"controller"}
        ListElement { icon: "\uf0ca"; keywords: "pro controller"; type:"controller"}
        ListElement { icon: "\uf0c8"; keywords: "joy-con (l)"; type:"controller"}
        ListElement { icon: "\uf0c9"; keywords: "joy-con (r)"; type:"controller"}

        ListElement { icon: "\uf26a"; keywords: "mastersystem,master system"; type:"controller"}
        ListElement { icon: "\uf26b"; keywords: "megadrive,mega drive,sega"; type:"controller"}

        ListElement { icon: "\uf0cb"; keywords: "idroid"; type:"controller"}

        //add here specific headset tested, keep it in lowercase and as displayed in bluetooth detection
        //04/10/21: add 'plt focus'
        //06/10/21: add 'qcy50' and 'jbl go'
        ListElement { icon: "\uf1e2"; keywords: "headset,plt focus,qcy50,jbl go"; type:"audio"}
        ListElement { icon: "\uf1e1"; keywords: "speaker"; type:"audio"}
        ListElement { icon: "\uf1b0"; keywords: ""; types:"audio"} //as generic icon for audio

    }

    //little function to faciliate check of value in 2 name and service from a keyword
    function isKeywordFound(name,service,keyword){
        if(typeof(name) !== "undefined" && typeof(service) !== "undefined"){
            if(name.toLowerCase().includes(keyword)||service.toLowerCase().includes(keyword)){
                return true;
            }
            else return false;
        }
        else return false
    }

    //function to dynamically set icon "character" from name and/or service
    function getBatteryStatus(macaddress){
        var result = "";
        var batteryName = "";
		//check if any battery exists for the existing macaddress
		//first method
        //console.log("command : ","ls '/sys/class/power_supply/' | grep -i " + macaddress + uniqueCleanLineCommand());
        batteryName = api.internal.system.run("ls '/sys/class/power_supply/' | grep -i " + macaddress + uniqueCleanLineCommand());

        //Only for test purpose in QT creator
        //if (isDebugEnv()) batteryName = "BAT0";

        //console.log("batteryName : ",batteryName,"For",macaddress)

        if((batteryName === "") && !isDebugEnv()){
            //second method: for nintendo ones for exemple using hdev
            //console.log("command : ","bluetoothctl info " + macaddress + " |grep -i 'modalias'  | awk -v FS='(v|p)' '{print $2}' | tr -d '\\n' | tr -d '\\r'");
            var firstPart = api.internal.system.run("bluetoothctl info " + macaddress + " |grep -i 'modalias'  | awk -v FS='(v|p)' '{print $2}' | tr -d '\\n' | tr -d '\\r'");
            //console.log("command : ","bluetoothctl info " + macaddress + " |grep -i 'modalias'  | awk -v FS='(p|d)' '{print $3}' | tr -d '\\n' | tr -d '\\r'");
            var secondPart = api.internal.system.run("bluetoothctl info " + macaddress + " |grep -i 'modalias'  | awk -v FS='(p|d)' '{print $3}' | tr -d '\\n' | tr -d '\\r'");
            if(firstPart !== "" && secondPart !== ""){
                //console.log("command : ","ls '/sys/class/power_supply/' | grep -i '" + firstPart + ":" + secondPart + "'" + uniqueCleanLineCommand());
                batteryName = api.internal.system.run("ls '/sys/class/power_supply/' | grep -i '" + firstPart + ":" + secondPart + "'" + uniqueCleanLineCommand());
            }
        }
        else if((batteryName === "") && isDebugEnv()){
            //method for Ubuntu: for nintendo ones for exemple using hdev
            var firstPart = api.internal.system.run("timeout 2 echo -e 'info " + macaddress + "' | bluetoothctl |grep -i 'modalias'  | awk -v FS='(v|p)' '{print $2}' | tr -d '\\n' | tr -d '\\r'");
            var secondPart = api.internal.system.run("timeout 2 echo -e 'info " + macaddress + "' | bluetoothctl |grep -i 'modalias'  | awk -v FS='(p|d)' '{print $3}' | tr -d '\\n' | tr -d '\\r'");
            if(firstPart !== "" && secondPart !== ""){
                //console.log("command : ","ls '/sys/class/power_supply/' | grep -i '" + firstPart + ":" + secondPart + "'" + uniqueCleanLineCommand());
                batteryName = api.internal.system.run("ls '/sys/class/power_supply/' | grep -i '" + firstPart + ":" + secondPart + "'" + uniqueCleanLineCommand());
            }

        }

		if(batteryName !== ""){
			//search method to know battery capacity
            //console.log("command : ","ls /sys/class/power_supply/" + batteryName + "/" + " | grep -i 'capacity'" + uniqueCleanLineCommand());
            var capacityName = api.internal.system.run("ls /sys/class/power_supply/" + batteryName + "/" + " | grep -i 'capacity'" + uniqueCleanLineCommand());
			if(capacityName !== ""){
                //check if it's "Status" finally before to check "Capacity/Capacity_Level"
                //console.log("command : ","cat /sys/class/power_supply/" + batteryName + "/status" + uniqueCleanLineCommand());
                result = api.internal.system.run("cat /sys/class/power_supply/" + batteryName + "/status" + uniqueCleanLineCommand());
                if(result.toLowerCase() === "charging"){
                    return "\uf1b3";
                }
                //console.log("command : ","cat /sys/class/power_supply/" + batteryName + "/" + capacityName + uniqueCleanLineCommand());
                result = api.internal.system.run("cat /sys/class/power_supply/" + batteryName + "/" + capacityName + uniqueCleanLineCommand());
                //console.log("Battery result:",result);
                if(isNaN(result)){
                    //console.log("is Not a number");
					switch(result.toLowerCase()){
						case "critical":
							return "\uf1b5"; //font awesome
						break;
						case "low":
							return "\uf1b1"; //font awesome
						break;
						case "normal":
							return "\uf1b8"; //font awesome
						break;
						case "high":
							return "\uf1ba"; //font awesome
						break;
						case "full":
							return "\uf1bc"; //font awesome
						break;
						case "unknown":
						default:
							return "\uf1be"; //font awesome
						break;
					}
				}
				else{
                    //console.log("is a number");
					var resultNumber = Number(result);
                    if (resultNumber <= 5) return "\uf1b5"; //font awesome as "critical"
					if (resultNumber <= 33) return "\uf1b1"; //font awesome as "low"
					if (resultNumber <= 63) return "\uf1b8"; //font awesome as "normal"
					if (resultNumber <= 95) return "\uf1ba"; //font awesome as "high"
					if (resultNumber >= 99) return "\uf1bc"; //font awesome as "full"
					else return "\uf1be"; //font awesome as "unknown"
				}
			}
			else return ""; //no battery well detected
		}
        else return ""; //no battery well detected
    }

    //to change icon size for audio ones especially and keep standard one for others.
    function getIconRatio(icon){
        var ratio;
        switch(icon){
        case "\uf1e2":
            ratio = 2;
            break;
        case "\uf1e1":
            ratio = 2;
            break;
        case "\uf1b0":
            ratio = 2;
            break;
        case "\uf0c8":
            ratio = 2.5
            break;
        case "\uf0c9":
            ratio = 2.5
            break;
        default:
            ratio = 3;
            break;
        }
        return ratio;
    }

    //function to dynamically set icon "character" from name and/or service
    function getIcon(name,service){
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

    //As readSavedDevicesList but check also pairing at the same time
    function readSavedDevicesListAndPairing(list,parameter){
        let result = "";
        let i = 0;
        let icon;
        let allmacaddresses = "";
        //First to populate list from recalbox.conf and check if exists as paired
        do {
          result = api.internal.recalbox.getStringParameter(parameter + i);
          if(result !== ""){
            const parameters = result.split("|");
            if(!isDebugEnv()) result = api.internal.system.run("timeout 0.50 bluetoothctl info " + parameters[0] + " | grep -i 'paired' | awk '{print $2}'");
            //with timeout of 50 ms
            else result = api.internal.system.run("timeout 0.50 echo -e 'info " + parameters[0] + "' | bluetoothctl | grep -i 'paired' | awk '{print $2}'");
            console.log("result:",result);
            if(result.toLowerCase().includes("yes")){
              icon = getIcon(parameters[2],parameters[3]);
              list.append({icon: icon, vendor: parameters[1], name: parameters[2], macaddress: parameters[0], service: parameters[3] });
              allmacaddresses = allmacaddresses + parameters[0];
              i = i + 1;
            }
            else{
              //replace by next one
              let nextOne = api.internal.recalbox.getStringParameter(parameter + (i+1));
              api.internal.recalbox.setStringParameter(parameter + i,nextOne);
            }
          }
        } while (result !== "");

        //Check if anyone paired is missing from list
        //with timeout of 50 ms
        if(!isDebugEnv()) result = api.internal.system.run("timeout 0.05 bluetoothctl paired-devices | grep -i 'Device' | awk '{printf $2\"|\";$1=\"\";$2=\"\";gsub(/^[ \t]+/,\"\");print $0}'");
        else result = api.internal.system.run("timeout 0.05 echo -e 'paired-devices' | bluetoothctl | grep -I 'Device' | awk '{printf $2\"|\";$1=\"\";$2=\"\";gsub(/^[ \t]+/,\"\");print $0}' | grep -v 'NEW'");

        console.log("***********");
        console.log(result);
        console.log("***********");

        const devices = result.split('\n');//Split by LF ;-)
        console.log("devices.length:",devices.length);
        for(var j = 0;j < devices.length;j++){
            console.log("device:",devices[j]);
            const details = devices[j].split("|");
            if(!allmacaddresses.includes(details[0])){//if paired device is missing
                //Add to list
                icon = getIcon(details[1],"");
                list.append({icon: icon, vendor:"", name: details[1], macaddress: details[0], service: "" });
                //Add to recalbox.conf
                api.internal.recalbox.setStringParameter(parameter + i,details[0] + "||" + details[1] + "|");
                i = i + 1;
            }
        }
    }

    Component.onCompleted:{
        //delete tmp file
        var result = api.internal.system.run("rm /tmp/btlist");

        //read devices already known and if paired
        readSavedDevicesListAndPairing(myDevicesModel,"pegasus.bt.my.device");

        //read devices already known and to ignore
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
            //stop scanning/checking during pairing
            bluetoothTimer.running = false;
            connectedTimer.running = false;
            btModel.running = false;
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
            //stop scanning/checking during pairing
            bluetoothTimer.running = false;
            connectedTimer.running = false;
            btModel.running = false;
            root.close();
        }
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
                        property var batteryStatusText: getBatteryStatus(macaddress);
                        width: parent.width - vpx(100)
                        Text {
                            id: batteryStatus

                            anchors.right: deviceIcon.left
                            anchors.rightMargin: vpx(5)
                            anchors.top: parent.top
                            anchors.topMargin: vpx(10)

                            color: themeColor.textLabel
                            font.pixelSize: (parent.fontSize)*1.5
                            font.family: globalFonts.awesome
                            height: parent.height
                            text : batteryStatusText
                            visible: true
                        }

                        Text {
                            id: deviceIcon

                            anchors.right: deviceStatus.left
                            anchors.rightMargin: vpx(5)
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
                            text : connected ? "\uf1f9" : "\uf22a"
                            visible: true
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
                                                    { "title": myDevicesModel.get(index).vendor + " " + myDevicesModel.get(index).name + " " + myDevicesModel.get(index).service,
                                                      "message": connected ? (qsTr("Do you want to forget or disconnect this device ?") + api.tr) : (qsTr("Are you sure to forget this device ?") + api.tr),
                                                      "symbol": myDevicesModel.get(index).icon,
                                                      "firstchoice": connected ? qsTr("Forget") + api.tr : qsTr("Yes") + api.tr,
                                                      "secondchoice": connected ? qsTr("Disconnect") + api.tr : "",
                                                      "thirdchoice": connected ? qsTr("Cancel") + api.tr : qsTr("No") + api.tr});
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
                            text: connected ? (qsTr("Forget/Disconnect") + " ?"  + api.tr) : (qsTr("Forget") + " ?"  + api.tr)
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
                        property var isPairingIssue: false
                        width: parent.width - vpx(100)
                        Text {
                            id: deviceDiscoveredIcon

                            anchors.right: isPairingIssue ? deviceDiscoveredStatus.left : parent.left
                            anchors.rightMargin: vpx(10)
                            anchors.verticalCenter: parent.verticalCenter
                            color: themeColor.textLabel
                            font.pixelSize: (parent.fontSize)*getIconRatio(icon)
                            font.family: globalFonts.awesome
                            height: parent.height
                            text : icon
                            visible: true  //parent.focus
                        }
                        Text {
                            id: deviceDiscoveredStatus

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
                        width: parent.width - vpx(100)
                        Text {
                            id: deviceIgnoredIcon

                            anchors.right: parent.left
                            anchors.rightMargin: vpx(10)
                            anchors.verticalCenter: parent.verticalCenter
                            color: themeColor.textLabel
                            font.pixelSize: (parent.fontSize)*getIconRatio(icon)
                            font.family: globalFonts.awesome
                            height: parent.height
                            text : icon
                            visible: true  //parent.focus
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
