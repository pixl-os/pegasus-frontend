
import "common"
import "qrc:/qmlutils" as PegasusUtils
import QtQuick 2.15
import QtQuick.Window 2.15
import QtQuick.Controls 2.15

FocusScope {
    id: root

    signal close

    width: parent.width
    height: parent.height
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
        text: qsTr("Settings > System Logs") + api.tr
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

                width: root.width * 0.9
                height: implicitHeight

                Item {
                    width: parent.width
                    height: implicitHeight + vpx(30)
                }
                //list model to manage type of devices
                ListModel {
                    id: systemLogsModel
                    ListElement { name: "Last game launched"; filepath: "/recalbox/share/system/logs/lastgamelaunch.log"}
                    ListElement { name: "Global pixL"; filepath: "/recalbox/share/system/recalbox.log"}
                    ListElement { name: "Pegasus-Frontend Last run"; filepath: "/recalbox/share/system/logs/lastrun.log"}
                    ListElement { name: "Virtual gamepads"; filepath: "/recalbox/share/system/logs/virtualgamepads.log"}
                    ListElement { name: "Sinden lightguns service"; filepath: "/recalbox/share/system/logs/sinden-lightguns.log"}
                    ListElement { name: "Initialization/Boot"; filepath: "/recalbox/share/system/logs/init.log"}
                    ListElement { name: "Xorg service"; filepath: "/var/log/Xorg.0.log"}
                    ListElement { name: "Bluetooth service"; filepath: "/var/log/recalbox-bluetooth.log"}
                    ListElement { name: "Messages"; filepath: "/var/log/messages"}
                    ListElement { name: "Samba smd daemon"; filepath: "/var/log/samba/log.smbd"}
                    ListElement { name: "Samba nmb daemon"; filepath: "/var/log/samba/log.nmbd"}
                }

                MultivalueOption {
                    id: optLogsList

                    //property to manage parameter name
                    property string parameterName : ""
                    property var model: systemLogsModel
                    focus: true

                    label: qsTr("Log file") + api.tr
                    note: qsTr("Select your log file to view below") + api.tr

                    currentIndex: 0

                    value: systemLogsModel.get(currentIndex).name

                    count: systemLogsModel.count;

                    onActivate : {
                        //for callback by listModelBox
                        listModelBox.callerid = optLogsList;
                        listModelBox.model = systemLogsModel;
                        listModelBox.index = currentIndex;
                        //to transfer focus to listModelBox
                        listModelBox.focus = true;
                    }

                    onSelect: {
                        currentIndex = index;
                        value = systemLogsModel.get(index).name;
                    }

                    onValueChanged: {
                        logsViewer.note = systemLogsModel.get(currentIndex).filepath;
                        parent.loadLogFile(systemLogsModel.get(currentIndex).filepath);
                    }

                    onFocusChanged:{
                        container.onFocus(this)
                    }

                    KeyNavigation.down: logsViewer
                }

                function loadLogFile(filePath) {
                    //console.log("loadLogFile - filePath : " + filePath);
                    logsViewer.fileContent = api.internal.system.run("cat '" + filePath + "'");
                }

                FileEditor {
                    id: logsViewer
                    visible: true
                    contentHeight: isDebugEnv() ? 400 : Window.height - 120

                    Keys.onPressed: (event) => {
                        if (api.keys.isAccept(event) && !event.isAutoRepeat) {
                            activeScroll = true;
                            event.accepted = true;
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

    MultivalueBox {
        id: listModelBox
        z: 3

        //properties to manage parameter
        property MultivalueOption callerid

        model: callerid ? callerid.model : {}
        index: callerid ? callerid.currentIndex : 0

        onClose: content.focus = true

        onSelect: {
            callerid.keypressed = true;
            callerid.currentIndex = index;
            callerid.value = systemLogsModel.get(index).name;
            callerid.count = callerid.model.count;
        }
    }

    Item {
        id: footer
        width: parent.width
        height: vpx(50)
        anchors.bottom: parent.bottom
        z:2
        visible: true

        //Rectangle for the transparent background
        Rectangle {
            anchors.fill: parent
            color: themeColor.screenHeader
            opacity: 0.75
        }

        //rectangle for the gray line
        Rectangle {
            width: parent.width * 0.97
            height: vpx(1)
            color: "#777"
            anchors.top: parent.top
            anchors.horizontalCenter: parent.horizontalCenter
        }

        //to select text for scrolling
        Rectangle {
            id: enterButtonIcon
            height: labelA.height
            width: height
            radius: width * 0.5
            border { color: "#777"; width: vpx(1) }
            color: "transparent"
            visible: !logsViewer.activeScroll && logsViewer.focus

            anchors {
                right: labelA.left
                verticalCenter: parent.verticalCenter
                verticalCenterOffset: vpx(1)
                margins: vpx(10)
            }
            Text {
                text: "A"
                color: "#777"
                font {
                    family: global.fonts.sans
                    pixelSize: parent.height * 0.7
                }
                anchors.centerIn: parent
            }
        }

        Text {
            id: labelA
            text: !logsViewer.activeScroll ? qsTr("To scroll text") + api.tr : ""
            verticalAlignment: Text.AlignTop
            visible: !logsViewer.activeScroll && logsViewer.focus

            color: "#777"
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

        //for the help to exit
        Rectangle {
            id: backButtonIcon
            height: labelB.height
            width: height
            radius: width * 0.5
            border { color: "#777"; width: vpx(1) }
            color: "transparent"
            visible: {
                return true;
            }

            anchors {
                right: labelB.left
                verticalCenter: parent.verticalCenter
                verticalCenterOffset: vpx(1)
                margins: vpx(10)
            }
            Text {
                text: "B"
                color: "#777"
                font {
                    family: global.fonts.sans
                    pixelSize: parent.height * 0.7
                }
                anchors.centerIn: parent
            }
        }

        Text {
            id: labelB
            text: logsViewer.activeScroll ? (qsTr("Exit Scroll") + api.tr) : (qsTr("Exit") + api.tr)
            verticalAlignment: Text.AlignTop
            visible: true

            color: "#777"
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
    }
}
