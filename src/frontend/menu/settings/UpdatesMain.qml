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
    property var actionVersionToInstall: ""

    //loader to load confirm dialog
    Loader {
        id: confirmDialog
        anchors.fill: parent
        z:10
        sourceComponent: myDialog
        active: false
        asynchronous: true
        //to set value via loader
        property var componentLogo: ""
        property var componentText: ""
    }

    Component {
        id: myDialog
        Generic3ChoicesDialog {
            title: qsTr("Are you sure that you want to update ?") + api.tr
            message: qsTr("Update to") + " " + confirmDialog.componentText + api.tr
            symbol: ""
            firstchoice: qsTr("Update") + api.tr
            secondchoice: ""
            thirdchoice: qsTr("Cancel") + api.tr
            logo: confirmDialog.componentLogo
        }
    }

    Connections {
        target: confirmDialog.item
        function onAccept() { //first choice
            switch (actionState) {
                    case "Update": //-> TO UPDATE
                        //launch process of udpate (including download and installation)
                        api.internal.updates.launchComponentInstallation(componentsListModel.get(actionListIndex).componentName,componentsListModel.get(actionListIndex).versionToInstall);
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
                id: updatesListTitle
                    text: {
                        return (qsTr("Update(s) list : ")+ api.tr);
                    }
                    first: true
                    visible: true
                }

                Timer {
                    id: statusRefresh
                    interval: 100 // Run the timer every 100 seconds
                    repeat: true
                    running: true
                    triggeredOnStart: false
                    onTriggered: {
                        for(var i = 0; i < availableUpdates.count;i++){
                            var item = availableUpdates.itemAt(i).item;
                            availableUpdates.itemAt(i).progressStatus = api.internal.updates.getInstallationStatus(item.componentName);
                            //console.log("availableUpdates.itemAt(i).progressStatus : ",availableUpdates.itemAt(i).progressStatus);
                            availableUpdates.itemAt(i).progress = api.internal.updates.getInstallationProgress(item.componentName);
                            //console.log("availableUpdates.itemAt(i).progress : ",availableUpdates.itemAt(i).progress);
                        }
                    }
                }
                Repeater {
                    id: availableUpdates
                    model: componentsListModel
                    property var selectedButtonIndex : 0
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
                        // cross operability with ListModel and plain JS object list
                        property var item: model.modelData ? model.modelData : model
                        property var entry: {
                            console.log("item.componentName : ",item.componentName);
                            console.log("item.hasUpdate : ", item.hasUpdate);
                            if(typeof(item.hasUpdate) !== "undefined"){
                                if(item.hasUpdate === true){
                                    return api.internal.updates.updateDetails(item.componentName,true);
                                }
                            }
                            return null;
                        }
                        width: parent.width - vpx(100)
                        visible : entry !== null ? true : false
                        enabled: visible

                        //columns sizes
                        firstColumnRatio: 2/3
                        secondColumnRatio: 1/3
                        //progress bar and status
                        progress: 0.0
                        progressStatus: ""

                        //Status not used
                        status:{
                            return "";
                        }
                        status_color:{
                            return "";
                        }

                        // label used with default color
                        label: entry !== null ? (entry.componentName + " / " + entry.tagName) + (entry.isPreRelease ? " / " + qsTr("Pre-released") + api.tr : "") : ""
                        //label_color: "white"

                        note: entry !== null ? ( qsTr("Size") + " : " + entry.size +  " / " + qsTr("Published at") + " : " + entry.publishedAt) : "";
                        icon: ""
                        icon2: item.icon
                        //will be displayed when selected and not selected
                        icon2_forced_display: true
                        picture: item.picture
                        //first column - if empty that is not used
                        //detailed_line1: qsTr("Size") + " : " + api.tr;
                        //detailed_line2: entry.isPreRelease ? qsTr("Pre-released") + " : " + api.tr : "";
                        //detailed_line3: entry.isDraft ? qsTr("Draft") + " : " + api.tr : "";
                        detailed_line4: "" //qsTr("Description") + " : " + api.tr;
                        detailed_line5: ""
                        detailed_line6: ""
                        detailed_line7: ""
                        detailed_line8: ""
                        detailed_description: entry.releaseNote;
                        //second column - if empty that is not used
                        //detailed_line9: entry.size;
                        //detailed_line10: entry.isPreRelease ? qsTr("Yes") + api.tr : "";
                        //detailed_line11: entry.isDraft ? qsTr("Yes") + api.tr : "";
                        detailed_line12: ""
                        detailed_line13: ""

                        focus: index === 0 ? true : false
                        onActivate: {
                                //to display logo of this room
                                confirmDialog.componentText = label;
                                confirmDialog.componentLogo = item.icon;
                                confirmDialog.focus = false;
                                confirmDialog.active = true;
                                //Save action states for later
                                actionState = "Update";
                                actionListIndex = index;
                                componentsListModel.setProperty(index,"versionToInstall", entry.tagName);
                                //to force change of focus
                                confirmDialog.focus = true;
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
                            visible: parent.focus
                            anchors.left: parent.right
                            anchors.leftMargin: vpx(20)
                            anchors.verticalCenter: parent.verticalCenter

                            contentItem: Text {
                                text: updateButton.text
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
