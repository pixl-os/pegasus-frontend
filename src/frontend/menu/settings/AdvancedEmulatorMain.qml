// Pegasus Frontend
//
// Updated by BozoTheGeek 10/05/2021
//

import "common"
import "qrc:/qmlutils" as PegasusUtils
import QtQuick 2.12
import QtQuick.Window 2.12


FocusScope {
    id: root

    signal close
    signal openEmulatorConfiguration(var system)

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
        text: qsTr("Games > Advanced emulators settings") + api.tr
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

                Repeater {
                    id: systemButtons
                    model: api.collections
                    SimpleButton {
                        label: qsTr(modelData.name) + api.tr

                        // set focus only on first item
                        focus: index == 0 ? true : false

                        onActivate: {
                            //console.log("root.openEmulatorConfiguration()");
                            focus = true;
                            root.openEmulatorConfiguration(modelData);

                        }
                        
                        onFocusChanged: container.onFocus(this)
                        KeyNavigation.up: (index != 0) ?  systemButtons.itemAt(index-1) : systemButtons.itemAt(systemButtons.count-1)
                        KeyNavigation.down: (index < systemButtons.count) ? systemButtons.itemAt(index+1) : systemButtons.itemAt(0)
                        Text {
                            id: pointer

                            anchors.right: parent.right
                            anchors.rightMargin: horizontalPadding
                            anchors.verticalCenter: parent.verticalCenter

                            color: themeColor.textValue
                            font.pixelSize: fontSize
                            font.family: globalFonts.ion

                            text : "\uf3d1"
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
}
