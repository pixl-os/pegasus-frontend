// Pegasus Frontend
//
// Created by BozoTheGeek 23/03/2023
//

import QtQuick 2.12
import QtQuick.Controls 2.15

FocusScope {
    id: root

    //property alias label: label.text
    //property alias note: sublabel.text
    
    property alias value: value.text 
    
    property alias slidervalue : slider.value
    property alias max : slider.from
    property alias min : slider.to
    
    property int fontSize: vpx(16)
    property int horizontalPadding: vpx(10)

    //signal activate()

    //width: parent.width //fontSize * 1.25 //parent.width
    //height: parent.height /// 3 //labelContainer.height + fontSize * 1.25

    /*Keys.onPressed: {
        if (api.keys.isAccept(event) && !event.isAutoRepeat) {
            event.accepted = true;
            root.activate();
        }
    }*/
    //Keys.onLeftPressed: slider.value > min ? slider.value = slider.value - 1 : min
    //Keys.onRightPressed: slider.value < max ? slider.value = slider.value + 1 : max

    /*Rectangle {
        id: underline

        width: parent.width
        height: vpx(3)
        anchors.bottom: parent.bottom

        color: themeColor.underline
        visible: parent.focus || mouseArea.containsMouse
    }*/

    Slider {
        id: slider
        x: - 0.8 * parent.width/2
        y: 0
        width: parent.width
        height: parent.height // / 2 //parent.width
        visible: true
        //horizontal: false
        //orientation: Qt.Horizontal

        //anchors.left: parent.left
        //anchors.top: parent.top
        //anchors.leftMargin: horizontalPadding

        //anchors.verticalCenter: parent.verticalCenter
        //anchors.horizontalCenter: parent.horizontalCenter

        rotation: 90

        // left bar
        background: Rectangle {
                 x: slider.leftPadding
                 y: slider.topPadding + slider.availableHeight / 2 - height / 2
                 implicitWidth: vpx(50)
                 implicitHeight: vpx(5)
                 width: slider.availableWidth
                 height: implicitHeight
                 radius: vpx(7)
                 color: themeColor.underline
                 // right bar
                 Rectangle {
                     width: slider.visualPosition * parent.width
                     height: parent.height
                     color: themeColor.secondary
                     radius: vpx(7)
                 }
             }
        // slider handle
        handle: Rectangle {
             x: slider.leftPadding + slider.visualPosition * (slider.availableWidth - width)
             y: slider.topPadding + slider.availableHeight / 2 - height / 2
             implicitWidth: vpx(26)
             implicitHeight: vpx(26)
             radius: vpx(13)
             color: themeColor.textLabel // handle color
             border.color: themeColor.main
         }
    }

    Text {
        id: value

        //anchors.verticalCenter: parent.verticalCenter
        //anchors.rightMargin: horizontalPadding + slider.width
        //anchors.horizontalCenter: parent.horizontalCenter
        //x: - 0.8 * parent.width/2
        anchors.top: slider.bottom

        color: themeColor.textValue
        font.pixelSize: fontSize
        font.family: globalFonts.sans
    }    
    
}
