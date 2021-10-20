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

				width: root.width * 0.7
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

				SectionTitle {
					text: qsTr("Retroarch lobby") + api.tr
					first: true
					visible: true
				}
				
                //for test purpose only
                ListModel {
                    id: availableNetplayRoomsModel
                    ListElement { country: "br"; nickname: "Anonymous";
								  game: "Metal Slug X (U) [SLUS-01212]";
								  core: "PCSX-ReARMed r22 36f3ea6" ; private_flag: "No";
								  retroarch_version: "1.8.8"; created: "19 Oct 21 12:05 UTC"}
                    ListElement { country: "br"; nickname: "Anonymous";
                                  game: "Metal Slug X (U) [SLUS-01212]";
                                  core: "PCSX-ReARMed r22 36f3ea6" ; private_flag: "No";
                                  retroarch_version: "1.8.8"; created: "19 Oct 21 12:05 UTC"}
                    ListElement { country: "br"; nickname: "Anonymous";
                                  game: "Metal Slug X (U) [SLUS-01212]";
                                  core: "PCSX-ReARMed r22 36f3ea6" ; private_flag: "No";
                                  retroarch_version: "1.8.8"; created: "19 Oct 21 12:05 UTC"}
                    ListElement { country: "br"; nickname: "Anonymous";
                                  game: "Metal Slug X (U) [SLUS-01212]";
                                  core: "PCSX-ReARMed r22 36f3ea6" ; private_flag: "No";
                                  retroarch_version: "1.8.8"; created: "19 Oct 21 12:05 UTC"}
                    ListElement { country: "br"; nickname: "Anonymous";
                                  game: "Metal Slug X (U) [SLUS-01212]";
                                  core: "PCSX-ReARMed r22 36f3ea6" ; private_flag: "No";
                                  retroarch_version: "1.8.8"; created: "19 Oct 21 12:05 UTC"}
                }

                Repeater {
                    id: availableNetplayRooms
                    model: availableNetplayRoomsModel //for test purpose
                    DetailedButton {
                        width: parent.width - vpx(100)
                        height: focus ? vpx(100) : vpx(50)
						// to do add Image
						// using URL like this for image https://cdnjs.cloudflare.com/ajax/libs/flag-icon-css/3.4.3/flags/1x1/br.svg
						
                        // Text {
                            // id: Icon

                            // anchors.right: isPairingIssue ? deviceDiscoveredStatus.left : parent.left
                            // anchors.rightMargin: vpx(10)
                            // anchors.verticalCenter: parent.verticalCenter
                            // color: themeColor.textLabel
                            // font.pixelSize: (parent.fontSize)*getIconRatio(icon)
                            // font.family: globalFonts.awesome
                            // height: parent.height
                            // text : icon
                            // visible: true  //parent.focus
                        // }
						
                        // Text {
                            // id: deviceDiscoveredStatus

                            // anchors.right: parent.left
                            // anchors.rightMargin: vpx(5)
                            // anchors.top: parent.top
                            // anchors.topMargin: vpx(5)

                            // color: "red"
                            // font.pixelSize: (parent.fontSize)*2
                            // font.family: globalFonts.ion
                            // height: parent.height
                            // text : "\uf22a"
                            // visible: isPairingIssue
                        // }

                        label: {
                            return (nickname + " / " + game + " / " + retroarch_version + " / " + private_flag + "/" + created);
                        }
                        // set focus only on first item
                        focus: index == 0 ? true : false

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

                        onFocusChanged: container.onFocus(this)
                        Keys.onPressed: {
                            //verify if finally other lists are empty or not when we are just before to change list
                            //it's a tip to refresh the KeyNavigations value just before to change from one list to an other
                            if ((event.key === Qt.Key_Up) && !event.isAutoRepeat) {
                                if (index !== 0) KeyNavigation.up = availableNetplayRooms.itemAt(index-1);
                                /*else if (myDevices.count !== 0){
                                    KeyNavigation.up = myDevices.itemAt(myDevices.count-1);
                                }*/
                                else KeyNavigation.up = availableNetplayRooms.itemAt(0);
                            }
                            if ((event.key === Qt.Key_Down) && !event.isAutoRepeat) {
                                if (index < availableNetplayRooms.count-1) KeyNavigation.down = availableNetplayRooms.itemAt(index+1);
                                /*else if (myIgnoredDevices.count !== 0){
                                    KeyNavigation.down = myIgnoredDevices.itemAt(0);
                                }*/
                                else KeyNavigation.down = availableNetplayRooms.itemAt(availableNetplayRooms.count-1);
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
					visible: true
				}
			}
		}
	}
}
