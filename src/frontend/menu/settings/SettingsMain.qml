// Pegasus Frontend
// Copyright (C) 2017-2018  Mátyás Mustoha
//
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with this program. If not, see <http://www.gnu.org/licenses/>.


import "common"
import "qrc:/qmlutils" as PegasusUtils
import QtQuick 2.12
import QtQuick.Window 2.12

FocusScope {
    id: root

    signal close
    signal openVideoSettings
    signal openInformationSystem
    signal openWifiNetworks
    signal openAdvancedDirectoriesConfiguration

    width: parent.width
    height: parent.height
    visible: 0 < (x + width) && x < Window.window.width

    enabled: focus

    Keys.onPressed: {
        if (api.keys.isCancel(event) && !event.isAutoRepeat) {
            event.accepted = true;
            root.close();
            api.internal.recalbox.saveParameters();
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
        text: qsTr("Settings") + api.tr
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
                    text: qsTr("Sound configuration") + api.tr
                    first: true
                    symbol: "\uf11c"
                }
                MultivalueOption {
                    id: optAudioMode
                    
                    //property to manage parameter name
                    property string parameterName : "audio.mode"

                    // set focus only on first item
                    focus: true

                    label: qsTr("Mode") + api.tr
                    note: qsTr("Choose audio mode") + api.tr
                    value: api.internal.recalbox.parameterslist.currentName(parameterName)

                    currentIndex: api.internal.recalbox.parameterslist.currentIndex;
                    count: api.internal.recalbox.parameterslist.count;

                    font: globalFonts.ion

                    onActivate: {
                        //for callback by parameterslistBox
                        parameterslistBox.parameterName = parameterName;
                        parameterslistBox.callerid = optAudioMode;
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

                    KeyNavigation.down: optOutputAudio
                }
                MultivalueOption {
                    id: optOutputAudio
                    
                    //property to manage parameter name
                    property string parameterName : "audio.device"

                    label: qsTr("Output") + api.tr
                    note: qsTr("Choose audio output") + api.tr
                    value: api.internal.recalbox.parameterslist.currentName(parameterName)
                    internalvalue: api.internal.recalbox.audioDevice

                    currentIndex: api.internal.recalbox.parameterslist.currentIndex;
                    count: api.internal.recalbox.parameterslist.count;

                    font: globalFonts.awesome

                    onInternalvalueChanged: {
                        value = api.internal.recalbox.parameterslist.currentName(parameterName, internalvalue);
                        //console.log("value = ", value);
                        count = api.internal.recalbox.parameterslist.count;
                        //console.log("count = ", count);
                        currentIndex = api.internal.recalbox.parameterslist.currentIndex;
                        //console.log("currentIndex = ", currentIndex);unt);
                    }

                    onActivate: {
                        //for callback by parameterslistBox
                        parameterslistBox.parameterName = parameterName;
                        parameterslistBox.callerid = optOutputAudio;
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

                    KeyNavigation.down: optOutputBootVolume
                }
                SliderOption {
                    id: optOutputBootVolume

                    //property to manage parameter name
                    property string parameterName : "boot.audio.volume"

                    //property of SliderOption to set
                    label: qsTr("Boot video volume") + api.tr
                    note: qsTr("Set audio volume only for boot video") + api.tr
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
                    }

                    Keys.onRightPressed: {
                        api.internal.recalbox.setIntParameter(parameterName,slidervalue);
                        value = slidervalue + "%";
                    }

                    onFocusChanged: container.onFocus(this)

                    KeyNavigation.down: optOutputVolume
                }
                SliderOption {
                    id: optOutputVolume
                    
                    //property to manage parameter name
                    property string parameterName : "audio.volume"

                    //property of SliderOption to set
                    label: qsTr("Volume") + api.tr
                    note: qsTr("Set audio volume") + api.tr
                    // in slider object
                    max : 100
                    min : 0
                    slidervalue: api.internal.recalbox.audioVolume
                    value: api.internal.recalbox.audioVolume + "%"

                    onSlidervalueChanged: {
                        api.internal.recalbox.audioVolume = slidervalue;
                    }

                    onValueChanged: {
                        if(value !== slidervalue.toString() + "%"){
                            slidervalue = api.internal.recalbox.audioVolume;
                            sfxNav.play();
                        }
                    }

                    onActivate: {
                        focus = true;
                    }
                    
                    Keys.onLeftPressed: {
                        sfxNav.play();
                    }

                    Keys.onRightPressed: {
                        sfxNav.play();
                    }
                    
                    onFocusChanged: container.onFocus(this)
                    
                    KeyNavigation.down: optVideoSettings
                }

                //Tip for i915 chipset Depreacated now
                /*ToggleOption {
                    id: opti915patchactivation
                    //command to get/catch reference of card id if issue
                    //check if file exists or error found in dmesg (we will use finally 'cat /var/log/messages' for tests purposes ;-)
                    visible: api.internal.system.run("grep -e i915.force_probe /var/log/messages | awk '{ print $2 }' FS='='") !== "" ? true : (api.internal.system.run("if [ -f '/etc/modprobe.d/i915.conf' ]; then echo 'true' ; else echo 'false' ; fi ;").includes('true') ? true : false) ;
                    label: qsTr("i915 driver force-probe activation") + api.tr
                    note: qsTr("Any driver issue detected ! Use this option to discover inputs quickly (need reboot)") + api.tr
                    checked: api.internal.system.run("if [ -f '/etc/modprobe.d/i915.conf' ]; then echo 'true' ; else echo 'false' ; fi ;").includes('true') ? true : false ;
                    onCheckedChanged: {
                        if(checked && visible){
                            //create file but need to catch Device PCI PCI ID first.
                            api.internal.system.run("PCI_ID=$(grep -e i915.force_probe /var/log/messages | awk '{ print $2 }' FS='=') ; mount -o remount,rw / ; echo options i915 force_probe=$PCI_ID > /etc/modprobe.d/i915.conf");
                        }
                        else if(visible)
                        {
                            //delete file
                            api.internal.system.run("mount -o remount,rw / ; rm /etc/modprobe.d/i915.conf");
                        }
                    }
                    onFocusChanged: container.onFocus(this)
                    KeyNavigation.down: optVideoSettings
                }*/

                SectionTitle {
                    text: qsTr("Video Configuration") + api.tr
                    first: true
                    symbol: "\uf17f"
                }
                SimpleButton {
                    id: optVideoSettings

                    label: qsTr("Video configuration") + api.tr
                    note: qsTr("choose output") + api.tr
                    //pointer moved in SimpleButton desactived on default
                    pointerIcon: true

                    onActivate: {
                        api.internal.system.run("/usr/bin/xrandr > /tmp/xrandr.tmp");
                        focus = true;
                        root.openVideoSettings();
                    }
                    onFocusChanged: container.onFocus(this)
                    //                    KeyNavigation.up: optBiosChecking
                    KeyNavigation.down: optBrightness.visible ? optBrightness : optVideoFiltrer
                }
                SliderOption {
                    id: optBrightness

                    //property to manage parameter name
                    property string parameterName : "screen.brightness"

                    //property of SliderOption to set
                    label: qsTr("Brightness") + api.tr
                    note: qsTr("Set backlight brightness for internal/primary screen only") + api.tr
                    // in slider object
                    max : 100
                    min : 0
                    slidervalue: api.internal.recalbox.screenBrightness
                    value: api.internal.recalbox.screenBrightness + "%"
                    visible: {
                        var brightness = "";
                        if(isDebugEnv()){
                            brightness = "50";
                            api.internal.recalbox.screenBrightness=50;
                        }
                        else {
                            brightness = api.internal.system.run("timeout 1 sh /recalbox/system/hardware/device/pixl-backlight.sh brightness");
                        }
                        //console.log("brightness : ", brightness);
                        if(brightness == "no brightness found") return false;
                        else if (parseInt(brightness) >= 0) return true;
                        else return false;
                    }
                    onSlidervalueChanged: {
                        api.internal.recalbox.screenBrightness = slidervalue;
                    }

                    onValueChanged: {
                        if(value !== slidervalue.toString() + "%"){
                            slidervalue = api.internal.recalbox.screenBrightness;
                        }
                    }

                    onActivate: {
                        focus = true;
                    }

                    Keys.onLeftPressed: {
                        //no specific action here for the moment
                    }

                    Keys.onRightPressed: {
                        //no specific action here for the moment
                    }

                    onFocusChanged: container.onFocus(this)

                    KeyNavigation.down: optVideoFiltrer
                }
                ToggleOption {
                    id: optVideoFiltrer

                    label: qsTr("Enabled redshift") + api.tr
                    note: qsTr("Redshift adjusts the color temperature of your screen according to your surroundings.\nThis may help your eyes hurt less if you are working in front of the screen at night.") + api.tr
                    checked: api.internal.recalbox.getBoolParameter("system.video.redshift")
                    onCheckedChanged: {
                            if(checked !== api.internal.recalbox.getBoolParameter("system.video.redshift")){
                                api.internal.recalbox.setBoolParameter("system.video.redshift",checked);
                                api.internal.recalbox.saveParameters();
                                if(checked){
                                    api.internal.system.run("/usr/bin/start_redshift.sh > /tmp/redshift.tmp");
                                }
                                else api.internal.system.run("killall redshift");
                            }
                    }
                    onFocusChanged: container.onFocus(this)
                    KeyNavigation.down: optVideoDriver
                }
                ToggleOption {
                    id: optVideoDriver

                    label: qsTr("Vulkan video driver") + api.tr
                    note: qsTr("Force video driver to Vulkan.\nBeware some hardware is not compatible with this option used with care !") + api.tr
//                    visible: api.internal.recalbox.getStringParameter("boot.nvidia-driver") === "true" ? true : false // only visible if have Nvidia Gpu activated
                    checked: api.internal.recalbox.getBoolParameter("system.video.driver.vulkan")
                    onCheckedChanged: {
                        api.internal.recalbox.setBoolParameter("system.video.driver.vulkan",checked);
                    }
                    onFocusChanged: container.onFocus(this)
                    KeyNavigation.down: optStorageDevices
                    // Check if vulkan is compatible
                    visible: api.internal.system.run("grep 'Vulkan Instance Version:' /tmp/vulkaninfo.tmp | cut -d ':' -f2") === "" ? false : true
                }
                /*
                SectionTitle {
                    text: qsTr("Update System") + api.tr
                    first: true
                }
                MultivalueOption {
                    id: optUpdateSettings

                    label: qsTr("Update Settings") + api.tr
                    note: qsTr("Update configuration menu") + api.tr
                    value: api.internal.settings.locales.currentName

                    onActivate: {
                        focus = true;
                        localeBox.focus = true;
                    }
                    onFocusChanged: container.onFocus(this)
                    KeyNavigation.down: optStorageDevices
                }
                */
                SectionTitle {
                    text: qsTr("Storage configuration") + api.tr
                    first: true
                    symbol: "\uf2ec"
                }
                MultivalueOption {
                    id: optStorageDevices

                    //property to manage parameter name
                    property string parameterName : "boot.sharedevice"
                    property string previousValue : api.internal.recalbox.parameterslist.currentName(parameterName)
                    property int previousIndex
                    label: qsTr("Storage device") + api.tr
                    note: qsTr("move 'share' to an other storage") + api.tr

                    value: api.internal.recalbox.parameterslist.currentName(parameterName)

                    currentIndex: api.internal.recalbox.parameterslist.currentIndex;
                    count: api.internal.recalbox.parameterslist.count;

                    onValueChanged: {
                        //console.log("optStorageDevices - onValueChanged - value : ", value);
                        //console.log("optStorageDevices - onValueChanged - previousValue : ", previousValue);
                        //console.log("optStorageDevices - onValueChanged - index : ", currentIndex);
                        //console.log("optStorageDevices - onValueChanged - previousindex : ", previousIndex);
                        if(value.includes("(ext4)")){
                            //add dialogBox to alert about issue
                            genericMessage.setSource("../../dialogs/GenericContinueDialog.qml",
                                                     { "title": qsTr("Share compatibility"), "message": qsTr("Sorry you can't change to ") + "<br>" + value + "<br>" + qsTr("because ext4 file system format is not yet supported !")});
                            genericMessage.focus = true;
                            keypressed = true;
                            //impossible to manage share on ext4, need to restore previous one
                            //to update index of parameterlist QAbstractList
                            currentIndex = previousIndex;
                            api.internal.recalbox.parameterslist.currentIndex = currentIndex;
                            //to force update of display of selected value
                            value = api.internal.recalbox.parameterslist.currentName(parameterName);
                        }
                        else if(value !== previousValue){
                            //need to reboot to take change into account !
                            needReboot = true;
                        }
                    }

                    onActivate: {
                        //for callback by parameterslistBox
                        parameterslistBox.parameterName = parameterName;
                        parameterslistBox.callerid = optStorageDevices;
                        //to force update of list of parameters
                        api.internal.recalbox.parameterslist.currentName(parameterName);
                        parameterslistBox.model = api.internal.recalbox.parameterslist;
                        parameterslistBox.index = api.internal.recalbox.parameterslist.currentIndex;
                        //to save initial index
                        previousIndex = api.internal.recalbox.parameterslist.currentIndex;
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

                    KeyNavigation.down: optAdvancedDirectories
                }
                SimpleButton {
                    id: optAdvancedDirectories

                    label: qsTr("Advanced directories configuration") + api.tr
                    note: qsTr("Choose your directorires to take into account if needed") + api.tr
                    //pointer moved in SimpleButton desactived on default
                    pointerIcon: true

                    onActivate: {
                        focus = true;
                        root.openAdvancedDirectoriesConfiguration();
                    }
                    onFocusChanged: container.onFocus(this)
                    KeyNavigation.down: optEthernet
                }
                SectionTitle {
                    text: qsTr("Networks") + api.tr
                    first: true
                    symbol: "\uf26d"
                }
                //timer to update status of wifi/ethernet
                Timer {
                    id: connectedTimer
                    interval: 2000 // every 2 seconds
                    repeat: true
                    running: true
                    triggeredOnStart: false
                    onTriggered: {
                        //get ethernet ip if exists
                        var ethIP = ""
                        if(!isDebugEnv()) ethIP = api.internal.system.run("timeout 1 ifconfig 2> /dev/null | grep -A1 '^e'| grep 'inet addr:' | grep -v 127.0.0.1 | sed -e 's/Bcast//' | cut -d: -f2 | tr -d '\\n' | tr -d '\\r' | tr -s [:space:]");
                        else ethIP = "192.168.1.255"; //for test purpose
                        if(ethIP !== ""){
                            optEthernet.note = qsTr("Ethernet Local IP :") + api.tr + " " + ethIP;
                        }
                        else{
                            optEthernet.note = qsTr("Plug your cable to have network") + api.tr;
                        }

                        if(optWifiToggle.checked){
                            //get wifi ip if exists
                            var wifiIP = "";
                            if(!isDebugEnv()) wifiIP = api.internal.system.run("timeout 1 ifconfig 2> /dev/null | grep -A1 '^w'| grep 'inet addr:' | grep -v 127.0.0.1 | sed -e 's/Bcast//' | cut -d: -f2 | tr -d '\\n' | tr -d '\\r' | tr -d [:space:]");
                            else wifiIP = "192.168.1.254"; //for test purpose
                            //get wifi ssid if exists
                            var ssid = "";
                            if(!isDebugEnv()) ssid = api.internal.system.run("timeout 1 wpa_cli status | grep -E 'ssid' | grep -v 'bssid' | awk -v FS='(=)' '{print $2}' | tr -d '\\n' | tr -d '\\r' | tr -d [:space:]");
                            else ssid = "lesv2-5G-3"; //for test purpose

                            if(wifiIP !== ""){
                                optWifiNetwork.note = qsTr("Wifi Local IP :") + api.tr + " " + wifiIP + "\n" + qsTr("Wifi used :") + api.tr + " " + ssid;
                            }
                            else{
                                optWifiNetwork.note = qsTr("Connect your PC to any network") + api.tr;
                            }
                        }
                    }
                }
                SimpleButton {
                    id: optEthernet

                    label: qsTr("Ethernet network") + api.tr
                    note: ""
                    pointerIcon: false

                    onActivate: {
                        focus = true;
                    }
                    onFocusChanged: container.onFocus(this)
                    KeyNavigation.down: optWifiToggle
                }
                ToggleOption {
                    id: optWifiToggle
//                    # ------------ B - Network ------------ #
//                    ## Set system hostname
//                    system.hostname=RECALBOX
//                    ## Activate wifi (0,1)
//                    wifi.enabled=0
//                    ## Set wifi region
//                    ## More info here: https://github.com/recalbox/recalbox-os/wiki/Wifi-country-code-(EN)
//                    wifi.region=JP
//                    ## Wifi SSID (string)
//                    ;wifi.ssid=new ssid
//                    ## Wifi KEY (string)
//                    ## after rebooting the recalbox, the "new key" is replace by a hidden value "enc:xxxxx"
//                    ## you can edit the "enc:xxxxx" value to replace by a clear value, it will be updated again at the following reboot
//                    ## Escape your special chars (# ; $) with a backslash : $ => \$
//                    ;wifi.key=new key

//                    ## Wifi - static IP
//                    ## if you want a static IP address, you must set all 3 values (ip, gateway, and netmask)
//                    ## if any value is missing or all lines are commented out, it will fall back to the
//                    ## default of DHCP
//                    ;wifi.ip=manual ip address
//                    ;wifi.gateway=new gateway
//                    ;wifi.netmask=new netmask

//                    # secondary wifi (not configurable via the user interface)
//                    ;wifi2.ssid=new ssid
//                    ;wifi2.key=new key

//                    # third wifi (not configurable via the user interface)
//                    ;wifi3.ssid=new ssid
//                    ;wifi3.key=new key

// command lines
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

                    label: qsTr("Wifi activation") + api.tr
                    note: qsTr("Enable or disable Wifi") + api.tr

                    checked: api.internal.recalbox.getBoolParameter("wifi.enabled")
                    onCheckedChanged: {
                        api.internal.recalbox.setBoolParameter("wifi.enabled",checked);
                        api.internal.recalbox.saveParameters();
                        if(checked){
                            var wifiIP = "";
                            if(!isDebugEnv()) wifiIP = api.internal.system.run("timeout 1 ifconfig wlan0 | grep 'inet addr:' | cut -d: -f2 | awk '{print $1}'");
                            console.log("wifiIP : '", wifiIP,"'")
                            //activate wifi by restarting only if a wifi is not already connected
                            if(wifiIP === ""){
                                console.log("api.internal.system.runAsync('/etc/init.d/S09wifi restart');");
                                if(!isDebugEnv()) api.internal.system.runAsync("/etc/init.d/S09wifi restart");
                            }
                        }
                        else
                        {//deactivate wifi
                            console.log("api.internal.system.runAsync('/etc/init.d/S09wifi stop');");
                            if(!isDebugEnv()) api.internal.system.runAsync("/etc/init.d/S09wifi stop");
                        }
                    }
                    onFocusChanged: container.onFocus(this)
                    KeyNavigation.down: checked ? optWifiNetwork : optStorageNetworkShareSmbActivate
                }
                SimpleButton {
                    id: optWifiNetwork
                    visible: optWifiToggle.checked
                    label: qsTr("Wifi networks") + api.tr
                    note: ""
                    pointerIcon: true

                    onActivate: {
                        focus = true;
                        root.openWifiNetworks();
                    }
                    onFocusChanged: container.onFocus(this)
//                    KeyNavigation.down: optStorageNetworkShare
                    KeyNavigation.down: optStorageNetworkShareSmbActivate
                }
                SectionTitle {
                    text: qsTr("Network share") + api.tr
                    first: true
                    symbol: "\uf26d"
                }
                ToggleOption {
                    id: optStorageNetworkShareSmbActivate
                    // set focus only on first item
                    focus: true
                    label: qsTr("Samba settings showing") + api.tr

                    checked: false
                    onCheckedChanged: {
                    }
                    onFocusChanged: container.onFocus(this)
                    KeyNavigation.down: optStorageNetworkShareSmb1Path
                }
                SimpleButton {
                    id: optStorageNetworkShareSmb1Path
                    label: qsTr("Path Samba number 1") + api.tr
                    note: qsTr("Set your path") + api.tr
                    TextFieldOption {
                        id: networkShareSmb1
                        anchors.right: parent.right
                        anchors.verticalCenter: parent.bottom
                        horizontalAlignment: TextInput.AlignRight
                        placeholderText: qsTr("Path") + api.tr
                        text: api.internal.recalbox.getStringParameter("boot.sharenetwork_smb1")
                        echoMode: TextInput.Normal
                        inputMethodHints: Qt.ImhNoPredictiveText
                        onEditingFinished: api.internal.recalbox.setStringParameter("boot.sharenetwork_smb1", networkShareSmb1.text)
                    }
                    onFocusChanged: container.onFocus(this)
                    KeyNavigation.down: optStorageNetworkShareSmb2Path
                    visible: optStorageNetworkShareSmbActivate.checked
                }
                SimpleButton {
                    id: optStorageNetworkShareSmb2Path
                    label: qsTr("Path Samba number 2") + api.tr
                    note: qsTr("Set your path") + api.tr
                    TextFieldOption {
                        id: networkShareSmb2
                        anchors.right: parent.right
                        anchors.verticalCenter: parent.bottom
                        horizontalAlignment: TextInput.AlignRight
                        placeholderText: qsTr("Path") + api.tr
                        text: api.internal.recalbox.getStringParameter("boot.sharenetwork_smb2")
                        echoMode: TextInput.Normal
                        inputMethodHints: Qt.ImhNoPredictiveText
                        onEditingFinished: api.internal.recalbox.setStringParameter("boot.sharenetwork_smb2", networkShareSmb2.text)
                    }
                    onFocusChanged: container.onFocus(this)
                    KeyNavigation.down: optStorageNetworkShareSmb3Path
                    visible: optStorageNetworkShareSmbActivate.checked
                }
                SimpleButton {
                    id: optStorageNetworkShareSmb3Path
                    label: qsTr("Path Samba number 3") + api.tr
                    note: qsTr("Set your path") + api.tr
                    TextFieldOption {
                        id: networkShareSmb3
                        anchors.right: parent.right
                        anchors.verticalCenter: parent.bottom
                        horizontalAlignment: TextInput.AlignRight
                        placeholderText: qsTr("Path") + api.tr
                        text: api.internal.recalbox.getStringParameter("boot.sharenetwork_smb3")
                        echoMode: TextInput.Normal
                        inputMethodHints: Qt.ImhNoPredictiveText
                        onEditingFinished: api.internal.recalbox.setStringParameter("boot.sharenetwork_smb3", networkShareSmb3.text)
                    }
                    onFocusChanged: container.onFocus(this)
                    KeyNavigation.down: optStorageNetworkShareSmb4Path
                    visible: optStorageNetworkShareSmbActivate.checked
                }
                SimpleButton {
                    id: optStorageNetworkShareSmb4Path
                    label: qsTr("Path Samba number 4") + api.tr
                    note: qsTr("Set your path") + api.tr
                    TextFieldOption {
                        id: networkShareSmb4
                        anchors.right: parent.right
                        anchors.verticalCenter: parent.bottom
                        horizontalAlignment: TextInput.AlignRight
                        placeholderText: qsTr("Path") + api.tr
                        text: api.internal.recalbox.getStringParameter("boot.sharenetwork_smb4")
                        echoMode: TextInput.Normal
                        inputMethodHints: Qt.ImhNoPredictiveText
                        onEditingFinished: api.internal.recalbox.setStringParameter("boot.sharenetwork_smb4", networkShareSmb4.text)
                    }
                    onFocusChanged: container.onFocus(this)
                    KeyNavigation.down: optStorageNetworkShareNfsActivate
                    visible: optStorageNetworkShareSmbActivate.checked
                }
                ToggleOption {
                    id: optStorageNetworkShareNfsActivate
                    // set focus only on first item
                    focus: false
                    label: qsTr("NFS settings showing") + api.tr

                    checked: false
                    onCheckedChanged: {
                    }
                    onFocusChanged: container.onFocus(this)
                    KeyNavigation.down: optStorageNetworkShareNfs1Path
                }
                SimpleButton {
                    id: optStorageNetworkShareNfs1Path
                    label: qsTr("Path NFS number 1") + api.tr
                    note: qsTr("Set your path") + api.tr
                    TextFieldOption {
                        id: networkShareNfs1
                        anchors.right: parent.right
                        anchors.verticalCenter: parent.bottom
                        horizontalAlignment: TextInput.AlignRight
                        placeholderText: qsTr("Path") + api.tr
                        text: api.internal.recalbox.getStringParameter("boot.sharenetwork_nfs1")
                        echoMode: TextInput.Normal
                        inputMethodHints: Qt.ImhNoPredictiveText
                        onEditingFinished: api.internal.recalbox.setStringParameter("boot.sharenetwork_nfs1", networkShareNfs1.text)
                    }
                    onFocusChanged: container.onFocus(this)
                    KeyNavigation.down: optStorageNetworkShareNfs2Path
                    visible: optStorageNetworkShareNfsActivate.checked
                }
                SimpleButton {
                    id: optStorageNetworkShareNfs2Path
                    label: qsTr("Path NFS number 2") + api.tr
                    note: qsTr("Set your path") + api.tr
                    TextFieldOption {
                        id: networkShareNfs2
                        anchors.right: parent.right
                        anchors.verticalCenter: parent.bottom
                        horizontalAlignment: TextInput.AlignRight
                        placeholderText: qsTr("Path") + api.tr
                        text: api.internal.recalbox.getStringParameter("boot.sharenetwork_nfs2")
                        echoMode: TextInput.Normal
                        inputMethodHints: Qt.ImhNoPredictiveText
                        onEditingFinished: api.internal.recalbox.setStringParameter("boot.sharenetwork_nfs2", networkShareNfs2.text)
                    }
                    onFocusChanged: container.onFocus(this)
                    KeyNavigation.down: optStorageNetworkShareNfs3Path
                    visible: optStorageNetworkShareNfsActivate.checked
                }
                SimpleButton {
                    id: optStorageNetworkShareNfs3Path
                    label: qsTr("Path NFS number 3") + api.tr
                    note: qsTr("Set your path") + api.tr
                    TextFieldOption {
                        id: networkShareNfs3
                        anchors.right: parent.right
                        anchors.verticalCenter: parent.bottom
                        horizontalAlignment: TextInput.AlignRight
                        placeholderText: qsTr("Path") + api.tr
                        text: api.internal.recalbox.getStringParameter("boot.sharenetwork_nfs3")
                        echoMode: TextInput.Normal
                        inputMethodHints: Qt.ImhNoPredictiveText
                        onEditingFinished: api.internal.recalbox.setStringParameter("boot.sharenetwork_nfs3", networkShareNfs3.text)
                    }
                    onFocusChanged: container.onFocus(this)
                    KeyNavigation.down: optStorageNetworkShareNfs4Path
                    visible: optStorageNetworkShareNfsActivate.checked
                }
                SimpleButton {
                    id: optStorageNetworkShareNfs4Path
                    label: qsTr("Path NFS number 4") + api.tr
                    note: qsTr("Set your path") + api.tr
                    TextFieldOption {
                        id: networkShareNfs4
                        anchors.right: parent.right
                        anchors.verticalCenter: parent.bottom
                        horizontalAlignment: TextInput.AlignRight
                        placeholderText: qsTr("Path") + api.tr
                        text: api.internal.recalbox.getStringParameter("boot.sharenetwork_nfs4")
                        echoMode: TextInput.Normal
                        inputMethodHints: Qt.ImhNoPredictiveText
                        onEditingFinished: api.internal.recalbox.setStringParameter("boot.sharenetwork_nfs4", networkShareNfs4.text)
                    }
                    onFocusChanged: container.onFocus(this)
                    KeyNavigation.down: optLanguage
                    visible: optStorageNetworkShareNfsActivate.checked
                }
                /*
                SimpleButton {
                    id: optStorageCapacity

                    label: qsTr("Storage Capacity") + api.tr
                    note: qsTr("Show Storage capacity") + api.tr
                    onActivate: {
                        focus = true;
                        //                        localeBox.focus = true;
                    }
                    onFocusChanged: container.onFocus(this)
                    KeyNavigation.up: optStorageDevices
                    KeyNavigation.down: optLanguage
                }
                */
                SectionTitle {
                    text: qsTr("System language") + api.tr
                    first: true
                    symbol: "\uf18a"
                }
                MultivalueOption {
                    id: optLanguage

                    //property to manage parameter name
                    property string parameterName : "system.language"

                    label: qsTr("Language") + api.tr
                    note: qsTr("Set your language interface") + api.tr

                    value: api.internal.settings.locales.currentName
                    internalvalue: api.internal.recalbox.parameterslist.currentName(parameterName);

                    currentIndex: api.internal.settings.locales.currentIndex;
                    count: api.internal.recalbox.parameterslist.count;

                    /* pegasus language format :
                    ar ,bs, de, en-GB, en, es, fr, hu, ko, nl, pt-BR, ru, zh, zh-TW
                    recalbox language format
                    ## Set the language of the system (fr_FR,en_US,en_GB,de_DE,pt_BR,es_ES,it_IT,eu_ES,tr_TR,zh_CN)
                    system.language=en_US */
                    onActivate: {
                        //for callback by localeBox
                        localeBox.parameterName = parameterName;
                        localeBox.callerid = optLanguage;
                        //to force update of list of parameters
                        api.internal.recalbox.parameterslist.currentName(parameterName);
                        localeBox.model = api.internal.settings.locales;
                        localeBox.index = api.internal.settings.locales.currentIndex;
                        //to transfer focus to localeBox
                        localeBox.focus = true;
                    }

                    onSelect: {
                        //to force to be on the good parameter selected
                        api.internal.recalbox.parameterslist.currentName(parameterName);
                        //to update index of parameterlist QAbstractList
                        api.internal.recalbox.parameterslist.currentIndex = index;
                        api.internal.settings.locales.currentIndex = index;
                        //to force update of display of selected value
                        value = api.internal.settings.locales.currentName;
                        internalvalue = api.internal.recalbox.parameterslist.currentName(parameterName);
                    }

                    onFocusChanged:{
                        if(focus){
                            api.internal.recalbox.parameterslist.currentName(parameterName);
                            value = api.internal.settings.locales.currentName
                            currentIndex = api.internal.settings.locales.currentIndex;
                            count = api.internal.recalbox.parameterslist.count;
                        }
                        container.onFocus(this)
                    }

                    KeyNavigation.up: optWifiToggle.checked ? optWifiNetwork : optWifiToggle
                    KeyNavigation.down: optKbLayout
                }
                MultivalueOption {
                    id: optKbLayout

                    //property to manage parameter name
                    property string parameterName : "system.kblayout"

                    label: qsTr("Keyboard layout") + api.tr
                    note: qsTr("Change keyboard layout language") + api.tr

                    value: api.internal.recalbox.parameterslist.currentName(parameterName)

                    currentIndex: api.internal.recalbox.parameterslist.currentIndex;
                    count: api.internal.recalbox.parameterslist.count;

                    onActivate: {
                        //for callback by parameterslistBox
                        parameterslistBox.parameterName = parameterName;
                        parameterslistBox.callerid = optKbLayout;
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

                    KeyNavigation.down: optInformationSystem
                }
                SectionTitle {
                    text: qsTr("System") + api.tr
                    first: true
                    symbol: "\uf412"
                }
                SimpleButton {
                    id: optInformationSystem

                    label: qsTr("System information") + api.tr
                    note: qsTr("More information Ip, Cpu, OpenGL ...") + api.tr
                    pointerIcon: true

                    onActivate: {
                        focus = true;
                        root.openInformationSystem();
                    }
                    onFocusChanged: container.onFocus(this)
                    KeyNavigation.down: optDebugMode
                }
                ToggleOption {
                    id: optDebugMode

                    label: qsTr("Debug mode") + api.tr
                    note: qsTr("Give me your log baby !!! ;-)") + api.tr

                    checked: api.internal.recalbox.getBoolParameter("pegasus.debuglogs")
                    onCheckedChanged: {
                        api.internal.recalbox.setBoolParameter("pegasus.debuglogs",checked);
                    }
                    onFocusChanged: container.onFocus(this)
                    KeyNavigation.down: optHideMouse
                }
                ToggleOption {
                    id: optHideMouse

                    label: qsTr("Enable mouse support") + api.tr
                    note: qsTr("By default the cursor is visible if there are any pointer devices connected.") + api.tr
                    
                    checked: api.internal.settings.mouseSupport
                    onCheckedChanged: {
                        api.internal.settings.mouseSupport = checked;
                    }
                    onFocusChanged: container.onFocus(this)
                    KeyNavigation.up: optDebugMode
                    KeyNavigation.down: optHideKeyboard
                }
                ToggleOption {
                    id: optHideKeyboard

                    label: qsTr("Enable virtual keyboard support") + api.tr
                    note: qsTr("By default virtual keyboard is not activated.") + api.tr

                    checked: api.internal.settings.virtualKeyboardSupport
                    onCheckedChanged: {
                        api.internal.settings.virtualKeyboardSupport = checked;
                    }
                    onFocusChanged: container.onFocus(this)
                    KeyNavigation.up: optHideMouse
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

    MultivalueBox {
        id: localeBox
        z: 3

        //properties to manage parameter
        property string parameterName
        property MultivalueOption callerid

        //reuse same model
        model: api.internal.settings.locales
        //to use index from locales QAbstractList
        index:  api.internal.settings.locales.currentIndex

        onClose: content.focus = true
        onSelect: {
            callerid.keypressed = true;
            //to use the good parameter
            api.internal.recalbox.parameterslist.currentName(callerid.parameterName);
            //to update index of locales QAbstractList
            api.internal.settings.locales.currentIndex = index;
            /* Set recalbox settings on same time */
            api.internal.recalbox.parameterslist.currentIndex = index;
            //to force update of display of selected value
            callerid.value = api.internal.settings.locales.currentName;
            callerid.internalvalue = api.internal.recalbox.parameterslist.currentName(callerid.parameterName);
            callerid.currentIndex = api.internal.recalbox.parameterslist.currentIndex;
            callerid.count = api.internal.recalbox.parameterslist.count;
        }
    }
}
