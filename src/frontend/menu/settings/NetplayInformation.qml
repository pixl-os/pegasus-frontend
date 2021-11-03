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
import "../../search"
import "qrc:/qmlutils" as PegasusUtils
import QtQuick 2.12
import QtQuick.Controls 2.12
import QtQuick.Window 2.12

FocusScope {
    id: root
	
	property bool isCallDirectly : false
	
    signal close

    width: parent.width
    height: parent.height

    anchors.fill: parent
	
    enabled: focus
    
    visible: 0 < (x + width) && x < Window.window.width

    //timer to refresh Netplay list
    property var counter: 4
    Timer {
        id: netplayTimer
        interval: 1000 // Run the timer every second
        repeat: true
        running: true //(api.internal.recalbox.getStringParameter("controllers.bluetooth.scan.methods") !== "") ? true : false
        triggeredOnStart: true
        onTriggered: {

                if ((interval/1000)*counter === 5){ // wait 5 seconds before to refresh
                    console.log("netplayTimer - before refresh: availableNetplayRooms.selectedButtonIndex", availableNetplayRooms.selectedButtonIndex);
                    api.internal.netplay.rooms.refresh();
                    counter = 0;
				}
                else counter = counter + 1;
        }
    }



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
        text: isCallDirectly ? qsTr("Netplay information") + api.tr : qsTr("Accounts > Netplay information") + api.tr
        z: 2
    }
    Rectangle {
        width: parent.width
        color: themeColor.main
        anchors {
            top: header.bottom
            bottom: parent.bottom
        }
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

                width: root.width * 0.9
				height: implicitHeight

                Item {
					width: parent.width
					height: implicitHeight + vpx(30)
                }


                //for test purpose only
                ListModel {
                    id: myFriends
                    //ListElement { nickname: "Anonymous"; }
                }

                SectionTitle {
                    text: qsTr("My Friend's rooms") + api.tr
                    first: true
                    visible: myFriends.count > 0 ? true : false
                }


                Row{
                    Image {
                        id: logoRetroarch
                        height: vpx(50)
                        source: "../../assets/libretro-retroarch-simple-logo.png"
                        anchors.verticalCenter: retroarch_title.verticalCenter
                        fillMode: Image.PreserveAspectFit
                    }
                    SectionTitle {
                    id: retroarch_title
                    text: "  " + qsTr("Retroarch lobby : ") + availableNetplayRooms.count + qsTr(" room(s)")  + api.tr
					first: true
					visible: true
                    }
                }
                //for test purpose only
                /*ListModel {
                    id: availableNetplayRoomsModel
                    ListElement { country: "br"; username: "Anonymous";
                                  game_name: "Metal Slug X (U) [SLUS-01212]";
                                  game_crc: "D634567DF";
                                  core_name: "PCSX-ReARMed";
                                  core_version: "r22 36f3ea6";
                                  retroarch_version: "1.8.8";
                                  frontend: "win32 x64";
                                  ip: "192.168.0.1";
                                  port: 8080;
                                  mitm_ip: "";
                                  mitm_port: 0;
                                  host_method : 0;
                                  has_password: false;
                                  has_spectate_password: true;
                                  created: "19 Oct 21 12:05 UTC";
                                  updated: "19 Oct 21 12:10 UTC";
                                }
                }*/

                Repeater {
                    id: availableNetplayRooms
                    model: api.internal.netplay.rooms     // availableNetplayRoomsModel //for test purpose
					property var selectedButtonIndex : 0

                    DetailedButton {
                        SearchGame {id: mygames; filter:"mario"} //     crc:game_crc.toLowerCase()}
                        property var nbgame :{
                            console.log("game_crc : ", game_crc.toLowerCase());
                            console.log("mygames.games.count : ", mygames.games.count);
                            console.log("mygames.gamesFound : ", mygames.gamesFound(0).Title);
                            return mygames.games.count;
                        }
                        property var status_icon : "\uf1c0 " // or "\uf1c1"/"?" or "\uf1c2"/"X"
                        property var latency_icon : "\uf1c8 " // or "\uf1c7" or "\uf1c6" or "\uf1c5" or "\uf1c9"/"?"
                        property var private_icon : has_password ? "\uf071 " : ""
                        property var visibility_icon : has_spectate_password ? "\uf070 " : " "
                        width: parent.width - vpx(100)
                        //for preview
                        label: {
                            return (status_icon + latency_icon + private_icon + visibility_icon + username + " / " + game_name);
                        }
                        note: {
                            return (" " + qsTr("Creation date") + ": " + created);
                        }
                        //add image of country
                        icon: {
                            return ("https://flagcdn.com/h60/" + country + ".png");
                        }
                        //system image
                        /*icon2: {
                            //return "file:/recalbox/share/roms/neogeo/media/wheel/mslugx.png"
                            return "qrc:/themes/gameOS/assets/images/logospng/" + "psx" + "_color.png"
                        }*/
                        //screenshot
                        picture: {
                            return "file:/recalbox/share/roms/neogeo/media/screenshot/mslugx.png"
                        }
                        //line titles
                        /*detailed_line1: {
                            return "Country code : ";
                        }*/
                        detailed_line2: {
                            return "Retroarch version : ";
                        }
                        detailed_line3: {
                            return "Core: ";
                        }
                        detailed_line4: {
                            return "Core version : ";
                        }
                        detailed_line5: {
                            return "Architecture : ";
                        }
                        detailed_line6: {
                            return "Game CRC : ";
                        }
                        /*detailed_line7: {
                            return "Password to play : ";
                        }
                        detailed_line8: {
                            return "Password for viewer : ";
                        }*/
                        //line status with details and colors
                        /*detailed_line9: {
                            return country;
                        }*/
                        detailed_line10: {
                            return "\uf1c0" + " " + retroarch_version;
                        }
                        detailed_line11: {
                            return "\uf1c0" + " " + core_name
                        }
                        detailed_line11_color: {
                            return "green"
                        }
                        detailed_line12: {
                            return "\uf1c0" + " " + core_version
                        }
                        detailed_line12_color: {
                            return "green"
                        }
                        detailed_line13: {
                            return  frontend;
                        }
                        detailed_line14: {
                            return "\uf1c0" + " " + game_crc;
                        }
                        detailed_line14_color: {
                            return "green"
                        }
                        /*detailed_line15: {
                            return (has_password ? "Yes":"No");
                        }
                        detailed_line16: {
                            return (has_spectate_password ? "Yes":"No");
                        }*/
                        picture2: {
                            return "file:/recalbox/share/roms/neogeo/media/wheel/mslugx.png"
                            //return "qrc:/themes/gameOS/assets/images/logospng/" + "psx" + "_color.png"
                        }
                        // set focus only on first item
                        focus:{
                            console.log("------Begin of Focus-------");
                            console.log("api.internal.netplay.rooms.count : ", api.internal.netplay.rooms.rowCount() );
                            console.log("availableNetplayRooms.selectedButtonIndex : ",availableNetplayRooms.selectedButtonIndex)
                            console.log("Index : ",index)

                            if( availableNetplayRooms.selectedButtonIndex < api.internal.netplay.rooms.rowCount()){
                                console.log("(index === availableNetplayRooms.selectedButtonIndex) ? true : false : ",(index === availableNetplayRooms.selectedButtonIndex) ? true : false);
                                return (index === availableNetplayRooms.selectedButtonIndex) ? true : false ;
							}
							else{
                                availableNetplayRooms.selectedButtonIndex = api.internal.netplay.rooms.rowCount()-1;
                                console.log("(index === api.internal.netplay.rooms.rowCount()-1) ? true : false : ",(index === api.internal.netplay.rooms.rowCount()-1) ? true : false);
                                return (index === api.internal.netplay.rooms.rowCount()-1) ? true : false ;
                            }
                            console.log("------End of Focus-------");

                        }
                        onActivate: {
                            ////to force change of focus
                            // confirmDialog.focus = false;
                            // confirmDialog.setSource("../../dialogs/Generic3ChoicesDialog.qml",
                                                    // { "title": myDiscoveredDevicesModel.get(index).vendor + " " + myDiscoveredDevicesModel.get(index).name + " " + myDiscoveredDevicesModel.get(index).service,
                                                      // "message": qsTr("Do you want to pair or ignored this device ?") + api.tr,
                                                      // "symbol": myDiscoveredDevicesModel.get(index).icon,
                                                      // "firstchoice": qsTr("Pair") + api.tr,
                                                      // "secondchoice": qsTr("Ignored") + api.tr,
                                                      // "thirdchoice": qsTr("Cancel") + api.tr});
                            ////Save action states for later
                            // actionState = "Pair";
                            // actionListIndex = index;
                            ////to force change of focus
                            // confirmDialog.focus = true;
                            ////focus = true;

                        }

                        onFocusChanged:{
							container.onFocus(this)                            
						}
                        Keys.onPressed: {
                            //verify if finally other lists are empty or not when we are just before to change list
                            //it's a tip to refresh the KeyNavigations value just before to change from one list to an other
                            if ((event.key === Qt.Key_Up) && !event.isAutoRepeat) {
                                if (index !== 0) {
                                    availableNetplayRooms.selectedButtonIndex = index-1;
									KeyNavigation.up = availableNetplayRooms.itemAt(index-1);
								}
                                else {
									KeyNavigation.up = availableNetplayRooms.itemAt(0);
                                    availableNetplayRooms.selectedButtonIndex = 0;
								}
                            }
                            if ((event.key === Qt.Key_Down) && !event.isAutoRepeat) {
                                if (index < availableNetplayRooms.count-1) {
									KeyNavigation.down = availableNetplayRooms.itemAt(index+1);
                                    availableNetplayRooms.selectedButtonIndex = index+1;
								}
                                else {
									KeyNavigation.down = availableNetplayRooms.itemAt(availableNetplayRooms.count-1);
                                    availableNetplayRooms.selectedButtonIndex = availableNetplayRooms.count-1;
								}
                            }
                        }

                        Button {
                            id: pairButton
                            property int fontSize: vpx(22)
                            height: fontSize * 1.5
                            text: qsTr("Play/View ?") + api.tr
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
					text: qsTr("Dolphin") + api.tr
                    first: false
                    visible: false // hide for the moment
				}
			}
		}
	}
}
