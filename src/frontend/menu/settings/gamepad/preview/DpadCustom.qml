// Pegasus Frontend
//
//Created by Bozo The Geek 12/03/2022
//

import QtQuick 2.12
import QtGraphicalEffects 1.12

Item {
    property var gamepad
    property var pressAngle: 15
    property string name: "" //used to find file named as "dpad_name.jpg" : dpad_nes.png or dpad_snes.png for example
    property alias brightness: animation.brightness
    property alias contrast: animation.contrast
    visible: name ? true : false
    Image {
        id:initialImage
        z: 50
        width: parent.width
        height: parent.height
        anchors.verticalCenter: parent.verticalCenter
        anchors.horizontalCenter: parent.horizontalCenter
        source: name ? "qrc:/frontend/assets/gamepad/dpad_" + name + ".png" : ""
        visible: gamepad ? (!gamepad.buttonLeft && !gamepad.buttonRight && !gamepad.buttonUp && !gamepad.buttonDown) : true
    }

    DpadHighlightCustom {
        id: dpleft
        z:70
        anchors.left: parent.left
        anchors.verticalCenter: parent.verticalCenter

        highlighted: padContainer.currentButton === "dpleft"
        pressed: gamepad ? gamepad.buttonLeft : false
    }

    BrightnessContrast {
        z:60
        visible: dpleft.pressed

        width: parent.width
        height: parent.height
        anchors.verticalCenter: parent.verticalCenter
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.horizontalCenterOffset: (parent.width/2) * -(pressAngle/1000)

        source: initialImage
        brightness: 0.5
        contrast: 0.5
        transform: Rotation { origin.x: initialImage.width/2; origin.y: initialImage.height/2; axis { x: 0; y: 1; z: 0 } angle: -pressAngle }
    }

    DpadHighlightCustom {
        z:70
        id: dpright

        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter

        highlighted: padContainer.currentButton === "dpright"
        pressed: gamepad ? gamepad.buttonRight : false
    }

    BrightnessContrast {
        id: animation
        z:60
        visible: gamepad ? gamepad.buttonRight : false

        width: parent.width
        height: parent.height
        anchors.verticalCenter: parent.verticalCenter
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.horizontalCenterOffset: (parent.width/2) * (pressAngle/1000)

        source: initialImage
        brightness: 0.5
        contrast: 0.5
        transform: Rotation { origin.x: initialImage.width/2; origin.y: initialImage.height/2; axis { x: 0; y: 1; z: 0 } angle: pressAngle }
    }


    DpadHighlightCustom {
        id: dpup
        z:70

        anchors.top: parent.top
        anchors.horizontalCenter: parent.horizontalCenter

        highlighted: padContainer.currentButton === "dpup"
        pressed: gamepad ? gamepad.buttonUp : false
    }

    BrightnessContrast {
        z:60
        visible: gamepad ? gamepad.buttonUp : false

        width: parent.width
        height: parent.height
        anchors.verticalCenter: parent.verticalCenter
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.verticalCenterOffset: (parent.height/2) * -(pressAngle/1000)

        source: initialImage
        brightness: 0.5
        contrast: 0.5
        transform: Rotation { origin.x: initialImage.width/2; origin.y: initialImage.height/2; axis { x: 1; y: 0; z: 0 } angle: pressAngle }
    }

    DpadHighlightCustom {
        id: dpdown
        z: 70

        anchors.bottom: parent.bottom
        anchors.horizontalCenter: parent.horizontalCenter

        highlighted: padContainer.currentButton === "dpdown"
        pressed: gamepad ? gamepad.buttonDown : false
    }

    BrightnessContrast {
        z:60
        visible: gamepad ? gamepad.buttonDown : false

        width: parent.width
        height: parent.height
        anchors.verticalCenter: parent.verticalCenter
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.verticalCenterOffset: (parent.height/2) * (pressAngle/1000)

        source: initialImage
        brightness: 0.5
        contrast: 0.5
        transform: Rotation { origin.x: initialImage.width/2; origin.y: initialImage.height/2; axis { x: 1; y: 0; z: 0 } angle: -pressAngle }
    }

}
