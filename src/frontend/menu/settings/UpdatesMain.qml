// Pegasus Frontend
//
// Created by BozoTheGeek 02/01/2022
//

import "common"
import "../../search"
import "../../dialogs"
import "qrc:/qmlutils" as PegasusUtils
import QtQuick 2.12
import QtQuick.Controls 2.12
import QtQuick.Window 2.12

FocusScope {
    id: root

    signal close

    width: parent.width
    height: parent.height

    anchors.fill: parent
	
    visible: 0 < (x + width) && x < Window.window.width

    //to be able to follow action done on Bluetooth Devices Lists
    property var actionState : ""
    property var actionListIndex : 0

    //loader to load confirm dialog
    Loader {
        id: confirmDialog
        anchors.fill: parent
        z:10
        sourceComponent: myDialog
        active: false
        asynchronous: true
        //to set value via loader
        property var component_logo: ""
    }

    Component {
        id: myDialog
        Generic3ChoicesDialog {
            title: qsTr("Are you that you want to update ?") + api.tr
            message: qsTr("Update of") + api.tr
            symbol: ""
            firstchoice: qsTr("Update") + api.tr
            secondchoice: ""
            thirdchoice: qsTr("Cancel") + api.tr

            //Specific to Netplay
            //to add in generic dialog one
            //logo: component_logo
        }
    }

    Connections {
        target: confirmDialog.item
        function onAccept() { //first choice
            switch (actionState) {
                    case "Update": //-> TO UPDATE
                    break;
            }
            confirmDialog.active = false;
            content.focus = true;
        }

        function onSecondChoice() {
            switch (actionState) {
                    case "":
                    break;
            }
            confirmDialog.active = false;
            content.focus = true;
        }
        function onCancel() {
            //do nothing
            confirmDialog.active = false;
            content.focus = true;
        }
    }

    Keys.onPressed: {
        if (api.keys.isCancel(event) && !event.isAutoRepeat) {
            event.accepted = true;
            root.close();
        }
        else if(api.keys.isFilters(event) && !event.isAutoRepeat) {
        }
        else if (api.keys.isDetails(event) && !event.isAutoRepeat) {
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
        text: qsTr("Updates") + api.tr
        z: 2
    }

    Rectangle {
        width: parent.width
        color: themeColor.main
        anchors {
            top: header.bottom
            bottom: footer.top
        }
    }

    Flickable {
        id: container

        width: content.width
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: header.bottom
        anchors.bottom: footer.top

        contentWidth: content.width
        contentHeight: content.height

        Behavior on contentY { PropertyAnimation { duration: 100 } }
        boundsBehavior: Flickable.StopAtBounds
        boundsMovement: Flickable.StopAtBounds

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

                SectionTitle {
                id: updates_list_title
                    text: {
                        return ("  " + qsTr("List of udpate(s) : ") + api.tr); //+ (friendsCount) + qsTr(" 'Friend' room(s)") + api.tr);
                    }
                    first: true
                    visible: true
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
                    id: availableUpdates
                    model: 0
                    //property var selectedButtonIndex : 0
                    property var hidden : 0
                    onItemRemoved:{
                        //RFU
                        //console.log("onItemRemoved: ", index)
                    }
                    onItemAdded:{
                        //RFU
                        //console.log("onItemAdded: ", index)
                    }
                    delegate: DetailedButton {
                        width: parent.width - vpx(100)
                        visible :{
                            return true;
                        }
                        enabled: visible
                        //for preview
                        status:{
                            return "";
                        }
                        status_color:{
                            return "";
                        }
                        label: {
                            return "";
                        }
                        label_color: {
                            return "";
                        }
                        note: {
                            return "";
                        }
                        //add image of country
                        icon: {
                            return "";
                        }
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
                        detailed_line7: {
                            return "Game file : ";
                        }
                        detailed_line10: {
                            return "";
                        }
                        detailed_line11: {
                            return "";
                        }
                        detailed_line11_color: {
                            return "";
                        }
                        detailed_line12: {
                            return "";
                        }
                        detailed_line12_color: {
                            return "";
                        }
                        detailed_line13: {
                            return "";
                        }
                        detailed_line14: {
                            return "";
                        }
                        detailed_line14_color: {
                            return "";
                        }
                        detailed_line15: {
                            return "";
                        }
                        detailed_line15_color: {
                            return "";
                        }
                        focus:{
                            if (index === 0){
                                    return true;
                            }
                            else return false;
                        }
                        onActivate: {
                                //to display logo of this room
                                //confirmDialog.game_logo = searchByCRCorFile.result.games.get(searchByCRCorFile.resultIndex).assets.logo;
                                confirmDialog.focus = false;
                                confirmDialog.active = true;
                                //Save action states for later
                                actionState = "Update";
                                actionListIndex = index;
                                //to force change of focus
                                confirmDialog.focus = true;
                            }
                        }

                        onFocusChanged:{
						}

                        Keys.onPressed: {
                            if ((event.key === Qt.Key_Up) && !event.isAutoRepeat) {
                                if (index !== 0) {
                                    availableUpdates.selectedButtonIndex = index-1;
                                    KeyNavigation.up = availableUpdates.itemAt(index-1);
								}
                                else {
                                    KeyNavigation.up = availableUpdates.itemAt(0);
                                    availableUpdates.selectedButtonIndex = 0;
								}
                            }
                            if ((event.key === Qt.Key_Down) && !event.isAutoRepeat) {
                                if (index < availableUpdates.count-1) {
                                    KeyNavigation.down = availableUpdates.itemAt(index+1);
                                    availableUpdates.selectedButtonIndex = index+1;
								}
                                else {
                                    KeyNavigation.down = availableUpdates.itemAt(availableUpdates.count-1);
                                    availableUpdates.selectedButtonIndex = availableUpdates.count-1;
								}
                            }
                            container.contentY = Math.min(Math.max(0, y - (height * 0.7)), container.contentHeight - height);
                        }

                        Button {
                            id: updateButton
                            property int fontSize: vpx(22)
                            height: fontSize * 1.5
                            text: qsTr("Update ?") + api.tr
                            visible: {
                                if(parent.focus){
                                    return true;
                                }
                                else{
                                    return false;
                                }
                            }
                            anchors.left: parent.right
                            anchors.leftMargin: vpx(20)
                            anchors.verticalCenter: parent.verticalCenter
                            
							contentItem: Text {
                                text: playButton.text
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
