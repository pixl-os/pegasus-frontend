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
//import "keyeditor"
import "qrc:/qmlutils" as PegasusUtils
import QtQuick 2.12
import QtQuick.Window 2.12
import QtQuick.XmlListModel 2.0

FocusScope {
    id: root

    readonly property string biosFilePath: "file://recalbox/share_init/system/.config/pegasus-frontend/es_bios.xml"
    signal close

    anchors.fill: parent
    enabled: focus
    visible: 0 < (x + width) && x < Window.window.width

    Keys.onPressed: {
        if (api.keys.isCancel(event) && !event.isAutoRepeat) {
            event.accepted = true;
            root.close();
        }
    }

    property string systems_Shortname: ""
    property string biosPath: ""
    property string biosMd5: ""
    property string biosNote: ""
    property string hashCalc: ""
    property bool hashMatch: hashCalc == "" ? true : false;
    property var system : xmlModelSystems.get(systemsList.currentIndex).systems_Shortname;


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
        text: qsTr("Games > Bios checking") + api.tr
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
                ListView {
                    id: systemsList
                    width: contentColumn.width ; height: vpx(50)
                    model: xmlModelSystems
                    delegate: xmlDelegate
                    spacing: vpx(30)
                    clip: true
                    orientation: ListView.Horizontal
                    highlightFollowsCurrentItem : true
                    highlightMoveDuration : 10
                    highlightResizeDuration : 1
                    highlightRangeMode: ListView.StrictlyEnforceRange

                    XmlListModel {
                        id: xmlModelSystems
                        // file:// need for read file system local
                        source: biosFilePath
                        query: "/biosList/system"

                        XmlRole { name: "systems_Shortname"; query: "@platform/string()" }
                        XmlRole { name: "systems_Fullname"; query: "@fullname/string()" }
                    }

                    Rectangle {
                        id: wrapper
                        Component {
                            id: xmlDelegate

                            Text {
                                id: fullname
                                text: systems_Fullname
                                color: themeColor.textSectionTitle
                                horizontalAlignment: Text.AlignHCenter
                                padding: vpx(7)
                                font {
                                    pixelSize: vpx(22)
                                    family: globalFonts.sans
                                }
                            }

                        }
                    }
                    highlight: Rectangle {
                        color: "transparent"
                        border.color: themeColor.secondary
                        border.width: vpx(3)
                        radius: 5
                    }
                }
                Item {
                    width: parent.width
                    height: implicitHeight + vpx(15)
                }
                Row {
                    id: biosColumn
                    spacing: vpx(15)
                    width: contentColumn.width / 2
                    height: implicitHeight
                    ListView {
                        id : biosList
                        width: biosColumn.width
                        height: vpx(460)
                        model: xmlModelBios
                        clip: true
                        focus: true
                        highlightRangeMode: ListView.StrictlyEnforceRange
                        highlightMoveDuration: 10
                        headerPositioning: ListView.PullBackHeader
                        spacing: vpx(20)

                        XmlListModel {
                            id: xmlModelBios
                            // file:// need for read file system local
                            // get current index in xmlModelSystems

                            source: biosFilePath
                            query:"/biosList/system[@platform='" + system + "']/bios"
                            XmlRole { name: "bios_Path"; query: "@path/string()"}
                            XmlRole { name: "bios_Md5"; query: "@md5/string()" }
                            XmlRole { name: "bios_Mandatory"; query: "@mandatory/string()" }
                            XmlRole { name: "bios_HashMatchMandatory"; query: "@hashMatchMandatory/string()" }
                            XmlRole { name: "bios_Core"; query: "@core/string()" }
                            XmlRole { name: "bios_Note"; query: "@note/string()" }
                        }

                        highlight: Rectangle {
                            color: "transparent"
                            border.color: themeColor.underline
                            border.width: vpx(3)
                            radius: 5
                            z: 2
                        }
                        // refresh info bios view
                        onCurrentItemChanged: {
                            biosPath = xmlModelBios.get(biosList.currentIndex).bios_Path;
                            biosMd5 = xmlModelBios.get(biosList.currentIndex).bios_Md5;
                            biosNote = xmlModelBios.get(biosList.currentIndex).bios_Note;
                            hashCalc = api.internal.bios.md5(biosPath);
                            hashMatch: hashCalc == "" ? true : false;
                        }
                        delegate: xmlInfoDelegate
                        Keys.onUpPressed: { decrementCurrentIndex() }
                        Keys.onDownPressed: { incrementCurrentIndex() }
                        Keys.onLeftPressed: { systemsList.decrementCurrentIndex() }
                        Keys.onRightPressed: { systemsList.incrementCurrentIndex() }
                        Keys.onPressed: {
                            if (api.keys.isAccept(event) && !event.isAutoRepeat) {
                                event.accepted = true;
                                hashCalc;
                                xmlModelBios.reload();
                                console.log("Check Md5 File ")
                            }
                            if (api.keys.isFilters(event) && !event.isAutoRepeat) {
                                event.accepted = true;
                                hashCalc;
                                console.log("filter mandatory ")
                            }
                        }
                        //                    }

                        Component {
                            id: xmlInfoDelegate
                            Rectangle {
                                id: biosButton
                                height: containerButton.height ; width: biosList.width
                                color: themeColor.main
                                property bool selected: ListView.isCurrentItem
                                property string md5String: api.internal.bios.md5( xmlModelBios.get(index).bios_Path )
                                Behavior on scale { NumberAnimation { duration: 350 } }
                                border.color: themeColor.secondary
                                border.width: vpx(3)
                                radius: 5
                                Grid {
                                    id: containerButton
                                    columns: 4
                                    horizontalItemAlignment: Grid.AlignHCenter
                                    verticalItemAlignment: Grid.AlignVCenter
                                    width: biosButton.width
                                    height: implicitHeight
                                    //spacing: vpx(10)
                                    padding: vpx(8)
                                    columnSpacing: vpx(20)
                                    //icon state md5 validate
                                    Text {
                                        text: md5String === "" ? "\uf2bf" /*Nok*/ :"\uf2bb"; /*ok*/
                                        color: md5String === "" ? "red" : "green";
                                        horizontalAlignment: Text.AlignHCenter
                                        width: Text.width
                                        font {
                                            family: global.fonts.ion
                                            pixelSize: vpx(35)
                                        }
                                    }
                                    // Core
                                    Text {
                                        // replace all ',' element with underline
                                        text: bios_Core.replace(/,/gi, "\n")
                                        horizontalAlignment: Text.AlignHCenter
                                        font.pixelSize: vpx(15)
                                        color: themeColor.textLabel
                                    }
                                    // mandatory or optional bios
                                    Text {
                                        text: bios_Mandatory === "false" ? qsTr("Optional") : qsTr("Mandatory");
                                        color: bios_Mandatory === "false" ? themeColor.textSublabel : "green";
                                        font.pixelSize: vpx(12)
                                    }
                                    // file name
                                    Text {
                                        // split to get only last element with pop()
                                        property var path: bios_Path
                                        property variant fileName: path.split('/').pop()
                                        text: fileName
                                        font.pixelSize: vpx(12)
                                        color: themeColor.textLabel
                                    }
                                }
                            }
                        }
                    }
                    Rectangle {
                        id: infobios
                        height: vpx(460) ; width: biosColumn.width
                        color: themeColor.main
                        radius: 5
                        border.color: themeColor.secondary
                        border.width: vpx(3)
                        clip: true

                        Grid {
                            id: infoview
                            topPadding: vpx(8)
                            spacing: vpx(8)
                            horizontalItemAlignment: Grid.AlignHCenter
                            verticalItemAlignment: Grid.AlignVCenter
                            columns: 1
                            rows: 12 // to come back to 8 after test lines removed
                            width: biosColumn.width
                            height: implicitHeight
                            //note if not empty
                            Text {
                                text: qsTr("Note: ")
                                font.pixelSize: vpx(15)
                                width: biosColumn.width - vpx(8)
                                horizontalAlignment: Text.AlignHCenter
                                color: themeColor.textSublabel
                                font.bold: true
                                visible: biosNote == "" ? false : true;
                            }
                            Text {
                                text: biosNote
                                font.pixelSize: vpx(12)
                                wrapMode: Text.WordWrap
                                width: biosColumn.width
                                color: themeColor.textLabel
                                horizontalAlignment: Text.AlignHCenter
                                visible: biosNote == "" ? false : true;
                            }
                            Rectangle {
                                color :themeColor.secondary
                                width: parent.width - vpx(20)
                                height: vpx(2)
                                visible: biosNote == "" ? false : true;
                            }
                            // path
                            Text {
                                text: qsTr("Path(s): ")
                                font.pixelSize: vpx(15)
                                horizontalAlignment: Text.AlignHCenter
                                color: themeColor.textSublabel
                                width: biosColumn.width
                            }
                            Text {
                                // replace all '|' element with underline
                                text: biosPath.replace(/\|/gi, "\n") //.replace(/\/recalbox\/share\/bios\//gi, "")
                                fontSizeMode: Text.VerticalFit;
                                horizontalAlignment: Text.AlignHCenter
                                color: themeColor.textLabel
                                width: biosColumn.width
                                font.pixelSize: vpx(12)
                            }
                            Rectangle {
                                color :themeColor.secondary
                                width: parent.width - vpx(20)
                                height: vpx(2)
                            }
                            // md5
                            Text {
                                text: qsTr("Calculed Md5 Checksum: ")
                                horizontalAlignment: Text.AlignHCenter
                                color: themeColor.textSublabel
                                font.pixelSize: vpx(15)
                                width: biosColumn.width
                            }
                            Text {
                                text: hashCalc == "" ? qsTr("bios not present or hash not matching") : hashCalc;
                                fontSizeMode: Text.VerticalFit;
                                horizontalAlignment: Text.AlignHCenter
                                color: hashCalc == "" ? "red" : "green";
                                //color: themeColor.textLabel
                                font {
                                    capitalization : Font.AllUppercase
                                    pixelSize: vpx(12)
                                }
                            }
                            Text {
                                text: qsTr("Possible Md5 Bios: ")
                                horizontalAlignment: Text.AlignHCenter
                                color: themeColor.textSublabel
                                font.pixelSize: vpx(15)
                                width: biosColumn.width
                                visible: hashMatch

                            }
                            Text {
                                //replace empty space
                                text: biosMd5.replace(/ /gi, "").replace(/,/gi, "\n")
                                fontSizeMode: Text.VerticalFit;
                                horizontalAlignment: Text.AlignHCenter
                                color: themeColor.textLabel
                                visible: hashMatch
                                font {
                                    capitalization : Font.AllUppercase
                                    pixelSize: vpx(12)
                                }
                            }
                        }
                    }
                }
            }
            Item {
                width: parent.width
                height: implicitHeight + vpx(30)
            }
        }
    }
    // help view
    Item {
        id: footer
        width: parent.width
        height: vpx(50)
        anchors.bottom: parent.bottom

        Rectangle {
            width: parent.width * 0.97
            height: vpx(1)
            color: "#777"
            anchors.top: parent.top
            anchors.horizontalCenter: parent.horizontalCenter
        }
        // button value
        Rectangle {
            id: backButtonIcon
            height: label.height
            width: height
            radius: width * 0.5
            border { color: "#777"; width: vpx(1) }
            color: "transparent"

            anchors {
                right: label.left
                verticalCenter: parent.verticalCenter
                verticalCenterOffset: vpx(1)
                margins: vpx(10)
            }
            Text {
                text: "B"
                color: themeColor.textValue
                font {
                    family: global.fonts.sans
                    pixelSize: parent.height * 0.7
                }
                anchors.centerIn: parent
            }
        }
        // info value
        Text {
            id: label
            text: qsTr("back") + api.tr
            verticalAlignment: Text.AlignTop

            color: themeColor.textValue
            font {
                family: global.fonts.sans
                pixelSize: vpx(22)
                capitalization: Font.SmallCaps
            }
            anchors {
                verticalCenter: parent.verticalCenter
                verticalCenterOffset: vpx(-1)
                right: parent.right; rightMargin: parent.width * 0.015
            }
        }
        Rectangle {
            id: checkButtonIcon
            height: labelA.height
            width: height
            radius: width * 0.5
            border { color: themeColor.textValue; width: vpx(1) }
            color: "transparent"
            anchors {
                right: labelA.left
                verticalCenter: parent.verticalCenter
                verticalCenterOffset: vpx(1)
                margins: vpx(10)
            }
            Text {
                text: "A"
                color: themeColor.textValue
                font {
                    family: global.fonts.sans
                    pixelSize: parent.height * 0.7
                }
                anchors.centerIn: parent
            }
        }
        Text {
            id: labelA
            text: qsTr("check") + api.tr
            verticalAlignment: Text.AlignTop
            color: themeColor.textValue

            font {
                family: global.fonts.sans
                pixelSize: vpx(22)
                capitalization: Font.SmallCaps
            }
            anchors {
                verticalCenter: parent.verticalCenter
                verticalCenterOffset: vpx(-1)
                right: backButtonIcon.left; rightMargin: parent.width * 0.015
            }
        }
        //add rectangle + text for 'directions' command
        Rectangle {
            id: stateOkButtonIcon
            height: labelCheckOk.height
            width: height
            radius: width * 0.5
            border { color: themeColor.textValue ; width: vpx(1) }
            color: "transparent"
            anchors {
                left: parent.left
                verticalCenter: parent.verticalCenter
                verticalCenterOffset: vpx(1)
                margins: vpx(10)
            }
            Text {
                text: "\uf2bb"
                // "\uf2bb" /*ok*/: "\uf2bf"; /*Nok*/
                color: "green"
                font {
                    family: global.fonts.ion
                    pixelSize: parent.height * 0.7
                }
                anchors.centerIn: parent
            }
        }
        Text {
            id: labelCheckOk
            text: qsTr("ok") + api.tr
            verticalAlignment: Text.AlignTop
            color: themeColor.textValue

            font {
                family: global.fonts.sans
                pixelSize: vpx(22)
                capitalization: Font.SmallCaps
            }
            anchors {
                verticalCenter: parent.verticalCenter
                verticalCenterOffset: vpx(-1)
                left: stateOkButtonIcon.right; leftMargin: parent.width * 0.005
            }
        }
        Rectangle {
            id: stateNokButtonIcon
            height: labelCheckNok.height
            width: height
            radius: width * 0.5
            border { color: themeColor.textValue ; width: vpx(1) }
            color: "transparent"
            anchors {
                left: labelCheckOk.right
                verticalCenter: parent.verticalCenter
                verticalCenterOffset: vpx(1)
                margins: vpx(10)
            }
            Text {
                text: "\uf2bb"
                // "\uf2bb" /*ok*/: "\uf2bf"; /*Nok*/
                color: "yellow"
                font {
                    family: global.fonts.ion
                    pixelSize: parent.height * 0.7
                }
                anchors.centerIn: parent
            }
        }
        Text {
            id: labelCheckNok
            text: qsTr("no matching") + api.tr
            verticalAlignment: Text.AlignTop
            color: themeColor.textValue

            font {
                family: global.fonts.sans
                pixelSize: vpx(22)
                capitalization: Font.SmallCaps
            }
            anchors {
                verticalCenter: parent.verticalCenter
                verticalCenterOffset: vpx(-1)
                left: stateNokButtonIcon.right; leftMargin: parent.width * 0.005
            }
        }
        Rectangle {
            id: stateNoFoundButtonIcon
            height: labelCheckNoFound.height
            width: height
            radius: width * 0.5
            border { color: themeColor.textValue ; width: vpx(1) }
            color: "transparent"
            anchors {
                left: labelCheckNok.right
                verticalCenter: parent.verticalCenter
                verticalCenterOffset: vpx(1)
                margins: vpx(10)
            }
            Text {
                text: "\uf2bf"
                // "\uf2bb" /*ok*/: "\uf2bf"; /*Nok*/
                color: "red"
                font {
                    family: global.fonts.ion
                    pixelSize: parent.height * 0.7
                }
                anchors.centerIn: parent
            }
        }
        Text {
            id: labelCheckNoFound
            text: qsTr("not found") + api.tr
            verticalAlignment: Text.AlignTop
            color: themeColor.textValue

            font {
                family: global.fonts.sans
                pixelSize: vpx(22)
                capitalization: Font.SmallCaps
            }
            anchors {
                verticalCenter: parent.verticalCenter
                verticalCenterOffset: vpx(-1)
                left: stateNoFoundButtonIcon.right;  leftMargin: parent.width * 0.005
            }
        }
    }
}


