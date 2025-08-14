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


import QtQuick 2.15
import "qrc:/qmlutils" as PegasusUtils
//import "common"

FocusScope {
    id: root

    property var model
    property int index //index in model

    readonly property int textSize: vpx(22)
    readonly property int itemHeight: 2.25 * textSize

    //new property usefull to customize Box to display to select options/parameters ;-)
    property string selected_picture: ""
    property bool has_picture: false
    property int max_listitem_displayed: 10
    property bool splitted_list: false
    property real firstlist_minimum_width_purcentage: 0.33
    property real firstlist_maximum_width_purcentage: 0.50
    property real secondlist_minimum_width_purcentage: 0.33
    property real secondlist_maximum_width_purcentage: 0.50
    property string firstlist_title: ""
    property string secondlist_title: ""
    property int box_maximum_width: 1100
    property int box_minimum_width: 700

    signal close
    signal select(int index)

    onFocusChanged:{
        if (focus){
            root.state = "open";
            root.visible = true;
            if(has_picture) box.width = vpx(box_maximum_width);
            else box.width = vpx(box_minimum_width);
        }
    }

    function triggerClose() {
        root.state = "";
        //hide MultiValue box before reseting
        root.visible = false;
        //come back to firstlist in term of focus
        prefixListView.focus = true;
        index = 0;
        prefixListView.currentIndex = 0;
        suffixListView.focus = false;
        suffixListView.currentIndex = 0;
        //reseting parameters
        has_picture = false;
        max_listitem_displayed = 10;
        splitted_list = false;
        firstlist_minimum_width_purcentage = 0.33;
        firstlist_maximum_width_purcentage = 0.50;
        firstlist_title = "";
        secondlist_minimum_width_purcentage = 0.33;
        secondlist_maximum_width_purcentage = 0.50;
        secondlist_title = "";
        box_maximum_width = 1100;
        box_minimum_width = 700;
        //reset size of box
        box.width = vpx(box_minimum_width);
        //close box
        root.close();
    }

    anchors.fill: parent
    enabled: focus
    visible: focus || animClosing.running

    Keys.onPressed: {
        if (event.isAutoRepeat)
            return;

        if (api.keys.isCancel(event)) {
            event.accepted = true;
            if(prefixListView.focus){
                //close without new selection/change
                triggerClose();
            }
            else {
                //come back to prefixList
                suffixListView.focus = false;
                prefixListView.focus = true;
            }
        }
        else if (api.keys.isAccept(event)) {
            event.accepted = true;
            if(!splitted_list){
                index = prefixListView.currentIndex;
                //select index for new selection and close
                select(index);
                triggerClose();
            }
            else{
                if(suffixListView.focus ||  (suffixListView.visible === false)){
                    //find index of root model from select value in prefix/suffix ListViews
                    index = findRootModelIndex(prefixListView.model.get(prefixListView.currentIndex).name,
                                              suffixListView.model.get(suffixListView.currentIndex).name);
                    //select index for new selection and close
                    select(index);
                    triggerClose();
                }
                else if(prefixListView.focus){
                    //go to suffixList
                    prefixListView.focus = false;
                    suffixListView.focus = true;
                }
            }
        }
        else if (api.keys.isLeft(event)) {
            if(suffixListView.focus && splitted_list){
                //come back to prefixList
                suffixListView.focus = false;
                prefixListView.focus = true;
            }
        }
        else if (api.keys.isRight(event)) {
            if(prefixListView.focus && splitted_list && suffixListView.visible){
                //go to suffixList
                prefixListView.focus = false;
                suffixListView.focus = true;
            }
        }
    }

    ListModel {
        id: prefixModel
    }

    // Function to populate the prefixModel with unique values
    function populatePrefixModel() {
        //to populate splitted list or not
        //console.log("populatePrefixModel()");
        //console.log("splitted_list : " + splitted_list)
        if (splitted_list){
            prefixModel.clear();
            var uniquePrefixes = {};
            var fullName = "";
            //console.log("root.model.count : " + root.model.count)
            for (var i = 0; i < root.model.count; i++) {
                fullName = root.model.get(i, "name")
                var prefix = fullName.split("/")[0];
                if(prefix === fullName){
                    prefix = "/"
                }
                //console.log("prefix: " + prefix)
                if (!uniquePrefixes[prefix]) {
                    uniquePrefixes[prefix] = true;
                    //console.log("prefixModel.append({ 'name': " + prefix + "});")
                    prefixModel.append({ "name": prefix });
                }
            }
            if (root.index >= 0 && root.index < root.model.count) {
                fullName = root.model.get(root.index, "name");
                //console.log("fullName : " + fullName)
                var savedPrefix = fullName.split("/")[0];
                //console.log("savedPrefix : " + savedPrefix)
                // Now find the index of this prefix in the prefixModel
                var prefixIndexToSelect = -1;
                for (var j = 0; j < prefixModel.count; j++) {
                    if ((prefixModel.get(j).name === savedPrefix) || ((savedPrefix === fullName) && (prefixModel.get(j).name === "/"))) {
                        prefixIndexToSelect = j;
                        console.log("prefixIndexToSelect : " + prefixIndexToSelect)
                        break;
                    }
                }
                // Set the current index of the prefix list view
                if (prefixIndexToSelect !== -1) {
                    prefixListView.currentIndex = prefixIndexToSelect;
                }
            }
        }
        else {
            prefixListView.currentIndex = index;
        }

        if (prefixListView.currentIndex > 0){
            prefixListView.positionViewAtIndex(prefixListView.currentIndex, ListView.Center);
        }
    }

    ListModel {
        id: suffixModel
    }

    // Function to populate the suffixModel with unique values
    function populateSuffixModel() {
        //console.log("suffixListView.model");
        suffixModel.clear();
        if(splitted_list){
            if (prefixListView.currentIndex !== -1) {
                var selectedPrefix = prefixListView.model.get(prefixListView.currentIndex).name;
                //console.log("suffixListView.model - selectedPrefix : " + selectedPrefix);
                var j = 0;
                for (var i = 0; i < root.model.count; ++i) {
                    var fullName = root.model.get(i,"name");
                    if (fullName.startsWith(selectedPrefix + "/")) {
                        var suffix = fullName.split("/")[1];
                        suffixModel.append({ "name": suffix, "picture": root.model.get(i,"picture")});
                        if(root.index === i){
                            suffixListView.currentIndex = j;
                        }
                        j++;
                        //suffixListView.visible = true;
                    }
                    else if ((selectedPrefix === "/") && (fullName === fullName.split("/")[0])) {
                        //case of prefix only (as at root)
                        suffixModel.append({ "name": fullName, "picture": root.model.get(i,"picture")});
                        //suffixListView.currentIndex = 0;
                        if(root.index === i){
                            suffixListView.currentIndex = j;
                        }
                        j++;
                        //hide suffix list in this case
                        //suffixListView.visible = false;
                        //break;
                    }
                }
            }
        }
        if (suffixListView.currentIndex > 0){
            suffixListView.positionViewAtIndex(suffixListView.currentIndex, ListView.Center);
        }
    }

    /*function findPrefixIndex(prefixName) {
        for (var i = 0; i < prefixModel.count; ++i) {
            if (prefixModel.get(i).name === prefixName) {
                return i;
            }
        }
        return -1; // Return -1 if not found
    }*/

    function findRootModelIndex(prefixName, suffixName) {
        for (var i = 0; i < root.model.count; ++i) {
            if (root.model.get(i, "name") === (prefixName + "/" + suffixName)) {
                return i;
            }
            else if((root.model.get(i, "name") === suffixName) && (prefixName === "/")) { //for parameter at root
                return i;
            }
        }
        return -1; // Return -1 if not found
    }


    /*Component.onCompleted: {
        //console.log("Component.onCompleted - root.index : " + root.index);
        //populatePrefixModel();
    }*/

    onModelChanged: {
        //console.log("onModelChanged - root.index : " + root.index);
        populatePrefixModel();
    }

    Rectangle {
        id: shade

        anchors.fill: parent
        color: "#000"

        opacity: parent.focus ? 0.3 : 0.0
        Behavior on opacity { PropertyAnimation { duration: 150 } }

        MouseArea {
            anchors.fill: parent
            acceptedButtons: Qt.LeftButton | Qt.RightButton
            onClicked: root.triggerClose()
        }
    }
    Item {
        id: box
        //fix to 10 items size if picture to display for each selection
        height: (prefixListView.count >= max_listitem_displayed) ? (max_listitem_displayed * itemHeight) : has_picture ? (max_listitem_displayed * itemHeight) : (prefixListView.count * itemHeight)
        width: {
            //console.log("box width binding - has_picture " + has_picture);
            if(has_picture) return vpx(box_maximum_width)
            else return vpx(box_minimum_width)
        }
        anchors.centerIn: parent
        Rectangle {
            id: borderBox
            height: box.height + vpx(15)
            width: box.width + vpx(15)
            color: themeColor.secondary
            radius: vpx(8)
            anchors.centerIn: parent
        }

        Rectangle {
            color: themeColor.main
            radius: vpx(8)
            anchors.fill: box

            MouseArea {
                id: mouseArea
                anchors.fill: parent
                hoverEnabled: true
                clip: true

                SectionTitle {
                    text: firstlist_title
                    visible: firstlist_title === "" ? false : true
                    first: true
                    symbol: "" //"\uf39b"
                    anchors.left: parent.left
                    anchors.top: parent.top
                    width: has_picture && splitted_list ? parseInt(parent.width * firstlist_minimum_width_purcentage) : (has_picture || splitted_list ? parseInt(parent.width * firstlist_maximum_width_purcentage) : parent.width)
                    height: itemHeight
                }

                ListView {
                    id: prefixListView
                    model: splitted_list ? prefixModel : root.model
                    focus: splitted_list ? false : true
                    width: has_picture && splitted_list ? parseInt(parent.width * firstlist_minimum_width_purcentage) : (has_picture || splitted_list ? parseInt(parent.width * firstlist_maximum_width_purcentage) : parent.width)
                    height: Math.min(count * itemHeight, parent.height)
                    anchors.left: parent.left
                    anchors.top: firstlist_title !== "" ? firstlist_title.bottom : parent.top
                    delegate: prefixListViewItem
                    snapMode: ListView.SnapOneItem
                    highlightMoveDuration: 150
                    onCurrentIndexChanged: {
                        populateSuffixModel();
                    }

                    MouseArea {
                        anchors.fill: parent
                        onClicked: {
                            var new_idx = prefixListView.indexAt(mouse.x, prefixListView.contentY + mouse.y);
                            if (new_idx < 0)
                                return;

                            prefixListView.currentIndex = new_idx;
                            root.select(new_idx);
                        }
                        cursorShape: Qt.PointingHandCursor
                    }
                }

                SectionTitle {
                    text: secondlist_title
                    visible: secondlist_title !== ""
                    first: false
                    symbol: "\uf39b"
                    anchors.left: prefixListView.right
                    anchors.top: parent.top
                    width: has_picture && splitted_list ? parseInt(parent.width * secondlist_minimum_width_purcentage) : (splitted_list && !has_picture ? parseInt(parent.width * secondlist_maximum_width_purcentage) : 0)
                    height: itemHeight
                }

                ListView {
                    id: suffixListView

                    focus: splitted_list ? true : false
                    visible: splitted_list
                    width: has_picture && splitted_list ? parseInt(parent.width * secondlist_minimum_width_purcentage) : (splitted_list && !has_picture ? parseInt(parent.width * secondlist_maximum_width_purcentage) : 0)
                    height: Math.min(count * itemHeight, parent.height)
                    anchors.left: prefixListView.right
                    anchors.top: secondlist_title !== "" ? secondlist_title.top : parent.top
                    model: suffixModel
                    delegate: suffixListViewItem
                    snapMode: ListView.SnapOneItem
                    highlightMoveDuration: 150

                    MouseArea {
                        anchors.fill: parent
                        onClicked: {
                            var new_idx = suffixListView.indexAt(mouse.x, suffixListView.co/ntentY + mouse.y);
                            if (new_idx < 0)
                                return;

                            suffixListView.currentIndex = new_idx;
                            root.select(new_idx);
                        }
                        cursorShape: Qt.PointingHandCursor
                    }
                }

                Image {
                    id: picture
                    source: selected_picture !== "" ? selected_picture : ""
                    visible: selected_picture !== "" ? true : false
                    //width: selected_picture !== "" ? (parent.width/2) : 0
                    //height: parent.height

                    anchors.right: parent.right
                    anchors.left: suffixListView.right
                    anchors.leftMargin: vpx(10) // Left margin
                    anchors.rightMargin: vpx(10) // Right margin
                    anchors.top: parent.top
                    anchors.bottom: parent.bottom
                    anchors.topMargin: vpx(10) // Top margin
                    anchors.bottomMargin: vpx(10) // Bottom margin

                    asynchronous: true
                    antialiasing: true
                    fillMode: Image.PreserveAspectFit
                    opacity: 1
                }

                Text {
                    id: noImageText
                    text: qsTr("No Preview Available") + api.tr
                    visible: has_picture & ((selected_picture === "") || (picture.status === Image.Error)) ? true : false
                    width: selected_picture !== "" ? (parent.width/2) : 0
                    height: parent.height
                    anchors.right: parent.right
                    anchors.left: suffixListView.right
                    anchors.leftMargin: vpx(10) // Left margin
                    anchors.rightMargin: vpx(10) // Right margin
                    anchors.topMargin: vpx(10) // Top margin
                    anchors.bottomMargin: vpx(10) // Bottom margin
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                    color: "red"
                    font.pixelSize: root.textSize
                    font.family: globalFonts.sans
                }
            }
        }
    }
    Component {
        id: prefixListViewItem
        Rectangle {
            //readonly property bool highlighted: ListView.isCurrentItem || mouseArea.containsMouse
            readonly property bool highlighted: ListView.isCurrentItem || (mouseArea.containsMouse && api.internal.settings.mouseSupport)
            clip: true
            onHighlightedChanged:{
                //console.log("onTextChanged - model.picture : " + model.picture)
                if(has_picture && !splitted_list) selected_picture = model.picture;
            }

            width: ListView.view.width
            height: root.itemHeight
            radius: vpx(8)
            color: highlighted ? themeColor.secondary : themeColor.main
            border.color: highlighted && prefixListView.focus ? themeColor.underline : themeColor.main

            PegasusUtils.HorizontalAutoScroll{
                id: longtext

                scrollWaitDuration: 1000 // in ms
                pixelsPerSecond: 20
                visible: (has_picture && !splitted_list) ? true : false
                activated: visible
                anchors {
                    top:    parent.top;
                    left:   parent.left;
                    right:  parent.right;
                    leftMargin: vpx(5);
                    rightMargin: vpx(5);
                    //horizontalCenter: parent.horizontalCenter;
                    //verticalCenter: parent.verticalCenter;
                }

                height: parent.height

                Text {
                    id: labellongtext
                    visible: (has_picture && !splitted_list) ? true : false
                    //anchors.verticalCenter: parent.verticalCenter
                    //anchors.horizontalCenter: parent.horizontalCenter

                    text: (typeof(model.version) !== "undefined") && (model.version.trim().length !== 0) ? model.name + " - " + model.version : model.name
                    //text: "labellongtext"
                    color: themeColor.textValue
                    font.pixelSize: root.textSize
                    font.family: globalFonts.sans

                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                }
            }

            Text {
                 id: label
                 visible: !labellongtext.visible
                 anchors.verticalCenter: parent.verticalCenter
                 anchors.horizontalCenter: parent.horizontalCenter

                 text: (typeof(model.version) !== "undefined") && (model.version.trim().length !== 0) ? model.name + " - " + model.version : model.name
                 //text: "label"
                 color: themeColor.textValue
                 font.pixelSize: root.textSize
                 font.family: globalFonts.sans
            }

            MouseArea {
                id: mouseArea
                anchors.fill: parent
                hoverEnabled: true
            }
        }
    }

    Component {
        id: suffixListViewItem
        Rectangle {
            //readonly property bool highlighted: ListView.isCurrentItem || mouseArea.containsMouse
            readonly property bool highlighted: ListView.isCurrentItem || (mouseArea.containsMouse && api.internal.settings.mouseSupport)
            clip: true
            onHighlightedChanged:{
                if(typeof(model) !== 'undefined'){
                    //console.log("onTextChanged - model.picture : " + model.picture)
                    if(has_picture && splitted_list && (typeof(model.picture) !== 'undefined')){
                        selected_picture = model.picture;
                    }
                }
             }
            width: ListView.view.width
            height: root.itemHeight
            radius: vpx(8)
            color: highlighted ? themeColor.secondary : themeColor.main
            border.color: highlighted && suffixListView.focus ? themeColor.underline : themeColor.main

            PegasusUtils.HorizontalAutoScroll{
                id: longtext

                scrollWaitDuration: 1000 // in ms
                pixelsPerSecond: 20
                visible: (has_picture && !splitted_list) ? true : false
                activated: visible
                anchors {
                    top:    parent.top;
                    left:   parent.left;
                    right:  parent.right;
                    leftMargin: vpx(5);
                    rightMargin: vpx(5);
                    //horizontalCenter: parent.horizontalCenter;
                    //verticalCenter: parent.verticalCenter;
                }

                height: parent.height

                Text {
                    id: labellongtext
                    visible: (has_picture && !splitted_list) ? true : false
                    //anchors.verticalCenter: parent.verticalCenter
                    //anchors.horizontalCenter: parent.horizontalCenter

                    text: (typeof(model.version) !== "undefined") && (model.version.trim().length !== 0) ? model.name + " - " + model.version : model.name
                    color: themeColor.textValue
                    font.pixelSize: root.textSize
                    font.family: globalFonts.sans

                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                }
            }

            Text {
                 id: label
                 visible: !labellongtext.visible
                 anchors.verticalCenter: parent.verticalCenter
                 anchors.horizontalCenter: parent.horizontalCenter

                 text: (typeof(model.version) !== "undefined") && (model.version.trim().length !== 0) ? model.name + " - " + model.version : model.name
                 color: themeColor.textValue
                 font.pixelSize: root.textSize
                 font.family: globalFonts.sans
            }

            MouseArea {
                id: mouseArea
                anchors.fill: parent
                hoverEnabled: true
            }
        }
    }

    states: State {
        name: "open"
        AnchorChanges {
            target: box
            anchors.left: undefined
            anchors.right: root.right
        }
    }
    readonly property var bezierDecelerate: [ 0,0, 0.2,1, 1,1 ]
    readonly property var bezierSharp: [ 0.4,0, 0.6,1, 1,1 ]

    transitions: [
        Transition {
            from: ""; to: "open"
            AnchorAnimation {
                duration: 175
                easing { type: Easing.Bezier; bezierCurve: bezierDecelerate }
            }
        },
        Transition {
            id: animClosing
            from: "open"; to: ""
            AnchorAnimation {
                duration: 150
                easing { type: Easing.Bezier; bezierCurve: bezierSharp }
            }
        }
    ]
}
