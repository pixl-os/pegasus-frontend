// Pegasus Frontend
//
// Created by BozoTheGeek 23/03/2023
//

import QtQuick 2.12
import QtQuick.Controls 2.15

FocusScope {
    id: root

    property alias value: value.text
    property alias symbol: symbol.text
    property alias symbolFontFamily: symbol.font.family
    property alias slidervalue : slider.value
    property alias max : slider.from
    property alias min : slider.to
    
    property int fontSize: vpx(16)
    property int horizontalPadding: vpx(10)

    Slider {
        id: slider

        x: parent.x - 0.8 * parent.height/2
        y: 0

        //use height only and for "slider" because need to calculate/rotate in a square finally :-(
        width: parent.height
        height: parent.height
        visible: true

        rotation: 90

        // left bar
        background: Rectangle {
                 x: slider.leftPadding
                 y: slider.topPadding + slider.availableHeight / 2 - height / 2
                 implicitWidth: vpx(50)
                 implicitHeight: vpx(3)
                 width: slider.availableWidth
                 height: implicitHeight
                 radius: vpx(1)
                 color: themeColor.underline
                 // right bar
                 Rectangle {
                     width: slider.visualPosition * parent.width
                     height: parent.height
                     color: themeColor.secondary
                     radius: vpx(1)
                 }
             }
        // slider handle
        handle: Rectangle {
             x: slider.leftPadding + slider.visualPosition * (slider.availableWidth - width)
             y: slider.topPadding + slider.availableHeight / 2 - height / 2
             implicitWidth: vpx(16)
             implicitHeight: vpx(16)
             radius: vpx(8)
             color: themeColor.textLabel // handle color
             border.color: themeColor.main
         }
    }

    Text {
        id: value
        anchors.left: parent.left
        anchors.leftMargin: horizontalPadding
        anchors.top: slider.bottom
        color: themeColor.textValue
        font.pixelSize: fontSize
        font.family: globalFonts.sans
    }    

    Text {
        id: symbol
        anchors.top: value.text !== "" ? value.bottom : slider.bottom
        anchors.horizontalCenter: slider.horizontalCenter
        color: themeColor.textValue
        font {
            bold: false
            pixelSize: fontSize * 1.25
            family: global.fonts.ion
        }
    }
}
