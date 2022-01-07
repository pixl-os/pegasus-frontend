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

    XmlListModel {
        id: xmlModelSystems
        // file:// need for read file system local
        source: "file://recalbox/share/system/.emulationstation/es_bios.xml"
        query: "/biosList/system"

        XmlRole { name: "platform"; query: "@platform/string()" }
        XmlRole { name: "systems_Fullname"; query: "@fullname/string()" }
    }
    XmlListModel {
        id: xmlModelBios
        // file:// need for read file system local
        source: "file://recalbox/share/system/.emulationstation/es_bios.xml"
        //        query : "/biosList/system[@platform='dreamcast']/bios"
        query: {
            if (xmlModelSystems.count !== 0){
                var system = xmlModelSystems.get(systemsList.currentIndex).platform;
                return ( "/biosList/system[@platform='" + system + "']/bios");
                //            console.log("systemsList.currentIndex : ", systemsList.currentIndex );
                //            console.log("xmlModelSystems.count : ", xmlModelSystems.count );
                //            console.log("xmlModelSystems.get : '", system, "'" );
            }
            else return ("/biosList/system[@platform='']/bios");
        }
        XmlRole { name: "bios_Path"; query: "@path/string()"}
        XmlRole { name: "bios_Md5"; query: "@md5/string()" }
        XmlRole { name: "bios_Core"; query: "@core/string()" }
        XmlRole { name: "bios_Note"; query: "@note/string()" }
        XmlRole { name: "bios_Mandatory"; query: "boolean(@mandatory)"}
        XmlRole { name: "bios_HashMatchMandatory"; query: "boolean(@hashMatchMandatory)";}
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
                    focus: true
                    orientation: ListView.Horizontal
                    //                    opacity: systemsList.isCurrentIndex ? 1 :  0.4 ;
                    highlightFollowsCurrentItem : true
                    highlightMoveDuration : 5
                    highlightMoveVelocity : 2
                    highlightResizeDuration : 0
                    highlightRangeMode: ListView.StrictlyEnforceRange
                    Keys.onLeftPressed: { decrementCurrentIndex() }
                    Keys.onRightPressed: { incrementCurrentIndex() }
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
                        border.color: "red"
                        radius: 5
                    }
                }
                Item {
                    width: parent.width
                    height: implicitHeight + vpx(15)
                }
                Column {
                    id: biosColumn
                    spacing: vpx(5)

                    width: container.width / 2
                    height: implicitHeight + vpx(200)
                    ListView {
                        id : biosList
                        width: container.width ; height: vpx(500)
                        model: xmlModelBios
//                        focus: true
                        displayMarginBeginning : - vpx(10)
                        displayMarginEnd : - vpx(120)
                        highlightRangeMode: ListView.StrictlyEnforceRange
                        headerPositioning: ListView.PullBackHeader
                        delegate: xmlInfoDelegate
                        spacing: vpx(20)
                        Keys.onUpPressed: { decrementCurrentIndex() }
                        Keys.onDownPressed: { incrementCurrentIndex() }
                    }
                    Component {
                        id: xmlInfoDelegate
                        Rectangle {
                            height: biosColumn.height + vpx(5); width: biosColumn.width + vpx(5)
                            color: themeColor.secondary //bios_Mandatory == false ? "yellow" : "#00B000"; // green select
                            //                        color: "transparent"
                            border {
                                color: bios_Mandatory == false ? "yellow" : "#00B000"; // green select
                                width: vpx(5)
                            }
                            // opacity: biosList.isCurrentIndex ? 1 : 0.5;
                            radius: 5
                            Row {
                                id: biosColumn
                                spacing: vpx(8)
                                padding : vpx(20)
                                Column {
                                    Text {
                                        text: "\uf2a5"
                                        font {
                                            family: global.fonts.ion
                                            pixelSize: vpx(40)
                                        }
                                        color: "red"
                                        verticalAlignment: Text.AlignHCenter
                                    }
                                }
                                // core
                                Row {
                                    Text {
                                        text: qsTr("Core(s): ")
                                        font.pixelSize: vpx(12)
                                        verticalAlignment: Text.AlignHCenter
                                    }
                                    Text {
                                        text: bios_Core.replace(/,/gi, "\n")
                                        font.pixelSize: vpx(10)
                                        verticalAlignment: Text.AlignHCenter
                                    }
                                }
                                // path
                                Row {
                                    Text {
                                        text: qsTr("Path(s): ")
                                        font.pixelSize: vpx(12)
                                    }
                                    Text {
                                        text: bios_Path.replace(/\|/gi, "\n").replace(/\/recalbox\/share\/bios\//gi, "")
                                        font.pixelSize: vpx(10)
                                    }
                                }
                                //                            // mandatory
                                //                            Row {
                                //                                Text {
                                //                                    text: qsTr("Mandatory: ")
                                //                                    font.pixelSize: vpx(15)
                                //                                }
                                //                                Text {
                                //                                    text: bios_Mandatory
                                //                                    color: bios_Mandatory == false ? "red" : "green";
                                //                                    font.pixelSize: vpx(15)
                                //                                }
                                //                            }
                                //                        // md5
                                //                        Row {
                                //                            Text {
                                //                                text: qsTr("Md5 Checksum: ")
                                //                                font.pixelSize: vpx(15)
                                //                            }
                                //                            Text {
                                //                                //replace empty space
                                //                                text: bios_Md5.replace(/ /gi, "").replace(/,/gi, "\n")
                                //                                font {
                                //                                    capitalization : Font.AllUppercase
                                //                                    pixelSize: vpx(15)
                                //                                }
                                //                            }
                                //                        }
                                // note
                                //                            Row {
                                //                                // don't show empty note
                                //                                visible: bios_Note != "" ? true : false
                                //                                Text {
                                //                                    text: qsTr("Note: ")
                                //                                    font.pixelSize: vpx(15)
                                //                                }
                                //                                Text {
                                //                                    text: bios_Note
                                //                                    font.pixelSize: vpx(15)
                                //                                    wrapMode: Text.WrapAnywhere
                                //                                }
                                //                            }

                            }
                        }
                    }
                    Column {
                        // note
                        Row {
                            // don't show empty note
                            visible: xmlModelBios.bios_Note != "" ? true : false
                            Text {
                                text: qsTr("Note: ")
                                font.pixelSize: vpx(12)
                            }
                            Text {
                                text: xmlModelBios.bios_Note
                                font.pixelSize: vpx(10)
                                wrapMode: Text.WrapAnywhere
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
}

