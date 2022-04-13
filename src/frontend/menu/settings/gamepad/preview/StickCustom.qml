// Pegasus Frontend
//
//Created by Bozo The Geek 20/03/2022
//

import QtQuick 2.12
import QtGraphicalEffects 1.12

Item {
    property string side
    property bool pressed: false
    property real xPercent: 0.0
    property real yPercent: 0.0
    property string name: "" //used to find file named as "shortName_name.jpg" : b_nes.png or a_snes.png for example
    property alias brightness: animation.brightness
    property alias contrast: animation.contrast

    height: width

    Image {
        id: initialImage
        z:65
        width: parent.width
        anchors {
            centerIn: parent
            horizontalCenterOffset: parent.width * 0.15 * xPercent
            verticalCenterOffset: parent.width * 0.15 * yPercent
        }

        fillMode: Image.PreserveAspectFit
        source: name != "" ? "qrc:/frontend/assets/gamepad/" + side + "stick_" + name +".png" : ""
        sourceSize {
            width: 128
            height: 128
        }

        transform: [
            Rotation {
                origin.x: width * 0.5; origin.y: height * 0.5
                axis { x: 0; y: 1; z: 0 }
                angle: xPercent * 35
            },
            Rotation {
                origin.x: width * 0.5; origin.y: height * 0.5
                axis { x: 1; y: 0; z: 0 }
                angle: yPercent * 35
            }
        ]
    }

    //to have a border more than 1 pixel and behind initial image !!! ;-)
    ColorOverlay {
        z:60
        visible: padContainer.currentButton === (side + "3")
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
        width: initialImage.width * 0.95
        height: initialImage.height * 0.95
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

    Rectangle {
        id: highlightX
        z:75
        width: parent.width * 1.2
        height: vpx(2)
        anchors.centerIn: parent

        color: {
            if (root.recordingField !== null ) return "#c33";
            else return themeColor.underline;
        }
        visible: padContainer.currentButton === (side + "x")
    }

    Rectangle {
        id: highlightY
        z:75
        width: vpx(2)
        height: parent.width * 1.2
        anchors.centerIn: parent

        color: {
            if (root.recordingField !== null ) return "#c33";
            else return themeColor.underline;
        }
        visible: padContainer.currentButton === (side + "y")
    }
}
