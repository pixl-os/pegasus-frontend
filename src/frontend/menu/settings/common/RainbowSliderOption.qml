// Pegasus Frontend
//
// Created by BozoTheGeek 10/09/2025
//

import QtQuick 2.12
import QtQuick.Controls 2.15


FocusScope {
    id: root

    property alias label: label.text
    property alias note: sublabel.text
    
    property alias value: value.text 
    
    property alias slidervalue : slider.value
    property alias max : slider.from
    property alias min : slider.to
    
    property int fontSize: vpx(22)
    property int horizontalPadding: vpx(30)

    signal activate()

    property string sliderRBGstring

    width: parent.width
    height: labelContainer.height + fontSize * 1.25

    // A function to get the color at a specific position (0.0 to 1.0) on the rainbow
    function getColorAt(position) {
        if (position < 0) position = 0;
        if (position > 1) position = 1;

        var r, g, b;

        // Map the position to the R, G, B values of the rainbow
        if (position === 0){
            r = 255; g = 255; b = 255;
        }
        else if (position === 1){
            r = 0; g = 0; b = 0;
        }
        else if (position < 1/6) {
            r = 255; g = position * 6 * 255; b = 0;
        } else if (position < 2/6) {
            r = (2/6 - position) * 6 * 255; g = 255; b = 0;
        } else if (position < 3/6) {
            r = 0; g = 255; b = (position - 2/6) * 6 * 255;
        } else if (position < 4/6) {
            r = 0; g = (4/6 - position) * 6 * 255; b = 255;
        } else if (position < 5/6) {
            r = (position - 4/6) * 6 * 255; g = 0; b = 255;
        } else {
            r = 255; g = 0; b = (1 - position) * 6 * 255;
        }
        sliderRBGstring = String(parseInt(r)) + "," + String(parseInt(g)) + "," + String(parseInt(b));
        return Qt.rgba(r / 255, g / 255, b / 255, 1);
    }

    Keys.onPressed: {
        if (api.keys.isAccept(event) && !event.isAutoRepeat) {
            event.accepted = true;
            root.activate();
        }
    }
    Keys.onLeftPressed: slider.value > min ? slider.value = slider.value - 1 : min
    Keys.onRightPressed: slider.value < max ? slider.value = slider.value + 1 : max

    Rectangle {
        id: underline

        width: parent.width
        height: vpx(3)
        anchors.bottom: parent.bottom

        color: themeColor.underline
        visible: parent.focus || mouseArea.containsMouse
    }

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
            id: label

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
    
    Slider {
        id: slider
        width: vpx(350)
        rotation: -180
        orientation: Qt.Horizontal
        anchors.right: parent.right
        anchors.rightMargin: horizontalPadding
        anchors.verticalCenter: value.verticalCenter

        // Background with the rainbow gradient
        background: Rectangle {
            id: backgroundRect
            x: slider.leftPadding
            y: slider.topPadding + slider.availableHeight / 2 - height / 2
            implicitWidth: vpx(50)
            implicitHeight: vpx(5)
            width: slider.availableWidth
            height: implicitHeight
            radius: vpx(7)

            // Gradient for the rainbow effect
            gradient: Gradient {
                orientation: Gradient.Horizontal
                GradientStop { position: 0.0; color: "white" }
                GradientStop { position: 0.05; color: "red" }
                GradientStop { position: 1/8; color: "orange" }
                GradientStop { position: 2/8; color: "yellow" }
                GradientStop { position: 3/8; color: "green" }
                GradientStop { position: 4/8; color: "cyan" }
                GradientStop { position: 5/8; color: "blue" }
                GradientStop { position: 6/8; color: "indigo" }
                GradientStop { position: 7/8; color: "violet" }
                GradientStop { position: 0.95; color: "red" }
                GradientStop { position: 1.0; color: "black" }
            }
        }

        // slider handle
        handle: Rectangle {
             x: slider.leftPadding + slider.visualPosition * (slider.availableWidth - width)
             y: slider.topPadding + slider.availableHeight / 2 - height / 2
             implicitWidth: vpx(26)
             implicitHeight: vpx(26)
             radius: vpx(13)

             // Bind the color to the position on the rainbow bar
             color: root.getColorAt(slider.visualPosition)
             border.color: "white"
             border.width: 2
        }
    }

    Text {
        id: value

        anchors.right: parent.right
        anchors.rightMargin: horizontalPadding + slider.width
        anchors.top: parent.top
        anchors.topMargin: vpx(14)

        color: themeColor.textValue
        font.pixelSize: fontSize
        font.family: globalFonts.sans
    }    
    

    MouseArea {
        id: mouseArea
        anchors.fill: parent
        hoverEnabled: true
        onClicked: activate()
        cursorShape: Qt.PointingHandCursor
    }
}
