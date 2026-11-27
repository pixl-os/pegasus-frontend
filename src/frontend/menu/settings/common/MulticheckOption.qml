// Pegasus Frontend
// Created by BozoTheGeek 14/08/2024

import QtQuick 2.12


FocusScope {
    id: root

    // Add this line at the top
    readonly property bool isMulticheckOption: true

    property alias label: labeltext.text
    property alias note: sublabel.text
    property alias value: valueText.text

    property var internalvalue

    property bool keypressed: false
    property bool firsttime: true

    property int currentIndex : -1
    property int count : 0

    property alias font: valueText.font.family
    property int fontSize: vpx(22)
    property int horizontalPadding: vpx(30)

    signal activate()
    signal check(int index, bool checked)

    width: parent.width
    height: labelContainer.height + fontSize * 1.25

    Component.onCompleted: {
    }

    onCurrentIndexChanged: {
        if(keypressed || firsttime){
            keypressed = false;
            firsttime = false;
        }
    }

    Keys.onPressed: {
        //console.log("MulticheckOption onPressed of ", labeltext.text)
        if (api.keys.isAccept(event) && !event.isAutoRepeat) {
            event.accepted = true;
            root.activate();
        }
    }

    //******************************** section to manage design in menu selection*******************************************
    readonly property bool isHighlighted: root.activeFocus || mouseArea.containsMouse // [CHANGED - keyboard focus]
    FocusStyleLoader {
        id: focusBackground
        anchors.fill: parent
        styleType: focusThemeStyle
        active: root.isHighlighted
        baseColor: themeColor.underline
    }
    //*********************************************************************************************************************

    Column {
        id: labelContainer
        anchors {
            left: parent.left; leftMargin: horizontalPadding
            right: parent.horizontalCenter
            verticalCenter: parent.verticalCenter
        }

        spacing: fontSize * 0.25
        height: label.height + (sublabel.text ? spacing + sublabel.height : 0)


        Text {
            id: labeltext

            color:themeColor.textLabel
            font.pixelSize: fontSize
            font.family: globalFonts.sans
        }

        Text {
            id: sublabel

            color: themeColor.textSublabel
            font.pixelSize: fontSize * 0.8
            font.family: globalFonts.sans
            font.italic: true
        }
    }

    Text {
        id: valueText

        anchors.right: parent.right
        anchors.rightMargin: vpx(10)
        anchors.top: parent.top
        anchors.topMargin: vpx(14)
        color: themeColor.textValue
        font.pixelSize: fontSize
        font.family: globalFonts.sans
        property bool firsttime: true
    }

    MouseArea {
        id: mouseArea
        anchors.fill: parent
        hoverEnabled: true
        onClicked: activate()
        cursorShape: Qt.PointingHandCursor
    }
}
