// Pegasus Frontend
//
// Created by BozoTheGeek 13/09/2021
//

import "common"
import "qrc:/qmlutils" as PegasusUtils
import QtQuick 2.12
import QtQuick.Controls 2.12
import QtQuick.Window 2.12
import QtBluetooth 5.12

FocusScope {
    id: root

        property BluetoothService currentService

        BluetoothDiscoveryModel {
            id: btModel
            running: true
            discoveryMode: BluetoothDiscoveryModel.DeviceDiscovery
            onDiscoveryModeChanged: console.log("Discovery mode: " + discoveryMode)
            onServiceDiscovered: console.log("Found new service " + service.deviceAddress + " " + service.deviceName + " " + service.serviceName);
            onDeviceDiscovered: console.log("New device: " + device)
            onErrorChanged: {
                    switch (btModel.error) {
                    case BluetoothDiscoveryModel.PoweredOffError:
                        console.log("Error: Bluetooth device not turned on"); break;
                    case BluetoothDiscoveryModel.InputOutputError:
                        console.log("Error: Bluetooth I/O Error"); break;
                    case BluetoothDiscoveryModel.InvalidBluetoothAdapterError:
                        console.log("Error: Invalid Bluetooth Adapter Error"); break;
                    case BluetoothDiscoveryModel.NoError:
                        break;
                    default:
                        console.log("Error: Unknown Error"); break;
                    }
            }
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
                //for test purpose only
                ListModel {
                    id: myDevicesModel
                    ListElement { icon: " \uf2f0 "; vendor: "Microsoft" ; name: "Xbox one series controler"; macaddress: "00:11:22:33:FF:EE" }
                    ListElement { icon: " \uf2ca "; vendor: "Sony" ; name: "PS4 controller"; macaddress: "00:33:11:33:FF:EE" }
                    ListElement { icon: " \uf1e2 "; vendor: "Boss" ; name: "Bluetooth headset"; macaddress: "00:12:22:55:FA:E1" }
                }
                //API to get vendor is very simple: https://api.macvendors.com/FC-A1-3E-2A-1C-33
                //API to get vendor is very simple: https://api.macvendors.com/B8-27-EB-A4-59-08
                //API to get vendor is very simple: https://api.macvendors.com/FC:FB:FB:01:FA:21
                //Basic reply could be get as a simple html text as: "Samsung Electronics Co.,Ltd"
                //example of pairing on rpi: https://pimylifeup.com/xbox-controllers-raspberry-pi/
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
                            //console.log("root.openEmulatorConfiguration()");
                            focus = true;

                            //root.pairBluetoothDevice(modelData);

                        }

                        onFocusChanged: container.onFocus(this)
                        KeyNavigation.up: (index != 0) ?  myDevices.itemAt(index-1) : myDevices.itemAt(myDevices.count-1)
                        KeyNavigation.down: (index < myDevices.count) ? myDevices.itemAt(index+1) : myDevices.itemAt(0)

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
                    ListElement { icon: ""; vendor: "Nintendo" ; name: "Switch Pro controller"; macaddress: "45:12:64:33:FF:EE" }
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
                            return (macaddress + " - " + vendor + " " + name)
                        }

                        // set focus only on first item
                        focus: index == 0 ? true : false

                        onActivate: {
                            //console.log("root.openEmulatorConfiguration()");
                            focus = true;

                            //root.pairBluetoothDevice(modelData);

                        }

                        onFocusChanged: container.onFocus(this)
                        KeyNavigation.up: (index != 0) ?  myDiscoveredDevices.itemAt(index-1) : myDiscoveredDevices.itemAt(myDiscoveredDevices.count-1)
                        KeyNavigation.down: (index < myDiscoveredDevices.count) ? myDiscoveredDevices.itemAt(index+1) : myDiscoveredDevices.itemAt(0)

                        Button {
                            id: pairButton
                            property int fontSize: vpx(22)
                            height: fontSize * 1.5
                            text: qsTr("Pair") + " ?"  + api.tr
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
                    text: qsTr("Devices blacklisted") + api.tr
                    first: false
                }
                //for test purpose only
                ListModel {
                    id: myDevicesBlacklistedModel
                    ListElement { icon: ""; vendor: "Xiaomi corporation" ; name: "smartphone X678"; macaddress: "25:12:36:33:FF:EE" }
                }

                Repeater {
                    id: myDevicesBlacklisted
                    model: myDevicesBlacklistedModel //for test purpose
                    SimpleButton {

                        Text {
                            id: deviceBlacklistedIcon

                            anchors.right: parent.left
                            //anchors.rightMargin: horizontalPadding
                            //anchors.rightMargin: horizontalPadding
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
                            focus = false;

                            //root.pairBluetoothDevice(modelData);

                        }

                        onFocusChanged: container.onFocus(this)
                        KeyNavigation.up: (index != 0) ?  myDevicesBlacklisted.itemAt(index-1) : myDevicesBlacklisted.itemAt(myDevicesBlacklisted.count-1)
                        KeyNavigation.down: (index < myDevicesBlacklisted.count) ? myDevicesBlacklisted.itemAt(index+1) : myDevicesBlacklisted.itemAt(0)

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

//                        Text {
//                            id: pointer

//                            anchors.right: parent.left
//                            //anchors.rightMargin: horizontalPadding
//                            anchors.verticalCenter: parent.verticalCenter

//                            color: themeColor.textValue
//                            font.pixelSize: fontSize
//                            font.family: globalFonts.ion

//                            text : "\uf3d1"
//                            visible: parent.focus
//                        }
                    }
                }
            }
        }
    }
}
