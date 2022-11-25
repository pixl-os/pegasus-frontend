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
    property string actionState : ""
    property int actionListIndex : 0
    property string actionVersionToInstall: ""

    //loader to load confirm dialog
    Loader {
        id: confirmDialog
        anchors.fill: parent
        z:10
        sourceComponent: myDialog
        active: false
        asynchronous: true
        //to set value via loader
        property string componentLogo: ""
        property string componentText: ""
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
                    interval: 1000 // Run the timer every seconds
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
                            availableUpdates.itemAt(i).errorCode = api.internal.updates.getInstallationError(item.componentName);
                            //console.log("availableUpdates.itemAt(i).errorCode : ",availableUpdates.itemAt(i).errorCode);
                        }
                    }
                }
                Repeater {
                    id: availableUpdates
                    model: componentsListModel
                    property int selectedButtonIndex : 0
                    property int hidden : 0
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
                                    return api.internal.updates.updateDetails(item.componentName,item.UpdateVersionIndex);
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
                        errorCode: 0

                        //Status not used
                        status:{
                            return "";
                        }
                        status_color:{
                            return "";
                        }

                        // label used with default color
                        label: entry !== null ? (item.componentName + " / " + entry.tagName) + (entry.isPreRelease ? " / " + qsTr("Pre-released") + api.tr : "") : ""

                        note: {
                            if(entry !== null){
                                // calculate unit of size
                                var size = entry.size;
                                let unit;
                                if (size < 1024) {
                                    unit = qsTr("bytes") + api.tr;
                                } else if (size < 1024*1024) {
                                    size /= 1024;
                                    unit = qsTr("KB") + api.tr;
                                } else {
                                    size /= 1024*1024;
                                    unit = qsTr("MB") + api.tr;
                                }
                                size = size.toFixed(2);
                                return qsTr("Size") + " : " + size + " " + unit + " - " + qsTr("Published at") + " : " + entry.publishedAt;
                            }
                            else{
                                return "";
                            }
                        }
                        icon: ""
                        icon2: item.hasUpdate ? (item.icon !== "" ? item.icon : entry.icon) : ""
                        //will be displayed when selected and not selected
                        picture: item.hasUpdate ? (item.picture !== "" ? item.picture : entry.picture) : ""
                        icon2_forced_display: item.hasUpdate ? (item.picture !== "" ? false : (entry.picture !== "" ? false : true)) : ""
                        //first column - if empty that is not used
                        detailed_description: item.hasUpdate ? entry.releaseNote : "";
                        focus: entry !== null ? true : false
                        onActivate: {
                            if(updateButton.visible && (errorCode >= 0)){
                                //to display logo of this room
                                confirmDialog.componentText = label;
                                confirmDialog.componentLogo = icon2;
                                confirmDialog.focus = false;
                                confirmDialog.active = true;
                                //Save action states for later
                                actionState = "Update";
                                actionListIndex = index;
                                componentsListModel.setProperty(index,"versionToInstall", entry.tagName);
                                //to force change of focus
                                confirmDialog.focus = true;
                            }
                            else if(updateButton.visible && (errorCode === -1)){ //restart
                                powerDialog.source = "../../dialogs/RestartDialog.qml"
                                powerDialog.focus = true;
                            }
                            else if(updateButton.visible && (errorCode === -2)){ //reboot
                                powerDialog.source = "../../dialogs/RebootDialog.qml"
                                powerDialog.focus = true;
                            }
                        }

                        onFocusChanged:{
                        }

                        Keys.onPressed: {
                            if ((event.key === Qt.Key_Up) && !event.isAutoRepeat) {
                                if (index !== 0) {
                                    for(var i = index;i > 0 ;i--){
                                        if(availableUpdates.itemAt(i-1).entry !== null){
                                            availableUpdates.selectedButtonIndex = i-1;
                                            KeyNavigation.up = availableUpdates.itemAt(i-1);
                                            break;
                                        }
                                    }
                                }
                                else {
                                    KeyNavigation.up = availableUpdates.itemAt(0);
                                    availableUpdates.selectedButtonIndex = 0;
                                }
                            }
                            if ((event.key === Qt.Key_Down) && !event.isAutoRepeat) {
                                if (index < availableUpdates.count-1) {
                                    for(var i = index;i < availableUpdates.count-1;i++){
                                        if(availableUpdates.itemAt(i+1).entry !== null){
                                            KeyNavigation.down = availableUpdates.itemAt(i+1);
                                            availableUpdates.selectedButtonIndex = i+1;
                                            break;
                                        }
                                    }
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
                            text: errorCode === 0 ? qsTr("Update ?") + api.tr : (errorCode > 0 ? qsTr("Retry ?") + api.tr : (errorCode === -1 ? qsTr("Restart ?") + api.tr : (errorCode === -2 ? qsTr("Reboot ?") + api.tr : "")))
                            visible: ((progress === 0.0) || (errorCode !== 0)) && parent.focus
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
