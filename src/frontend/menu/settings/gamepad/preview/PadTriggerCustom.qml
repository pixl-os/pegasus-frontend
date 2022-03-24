// Pegasus Frontend
//
//Created by Bozo The Geek 12/03/2022
//
// it's a copy of PadButtonSNES adapted for trigger

import QtQuick 2.12
import QtGraphicalEffects 1.12
Item {
    property string shortName
    property bool pressed: false
    property string name: "" //used to find file named as "shortName_name.jpg" : l1_nes.png or r2_snes.png for example
    property alias brightness: animation.brightness
    property alias contrast: animation.contrast

    //initial image loaded
    Image {
        id: initialImage
        z: 65
        width: parent.width
        height: parent.height
        anchors.fill: parent.fill
        source: name ? "qrc:/frontend/assets/gamepad/" + shortName + "_" + name +".png" : ""
        visible: !pressed
    }

    //to have a border more than 1 pixel and behind initial image !!! ;-)
    ColorOverlay {
        z:60
        visible: padContainer.currentButton === shortName
        width: initialImage.width + vpx(10)
        height: initialImage.height + vpx(10)
        anchors.verticalCenter: initialImage.verticalCenter
        anchors.horizontalCenter: initialImage.horizontalCenter

        source: initialImage
        color: {
            if (root.recordingField !== null ) return "#c33";
            else if (padContainer.currentButton) return themeColor.underline;
            else return "transparent";
        }
    }

    //to have an image prepared but not displayed when we press on button
    Image {
        id: pressedImage
        width: initialImage.width //* 0.95
        height: initialImage.height //* 0.95
        anchors.verticalCenter: initialImage.verticalCenter
        anchors.horizontalCenter: initialImage.horizontalCenter
        source: initialImage.source
        visible: false
    }

    //for animation when we press button
    BrightnessContrast {
        id: animation
        z:70
        visible: pressed
        anchors.fill: pressedImage
        source: pressedImage
        brightness: 0.5
        contrast: 0.5
    }
}
