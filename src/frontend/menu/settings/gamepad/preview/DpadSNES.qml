// Pegasus Frontend
//
//Created by Bozo The Geek 12/03/2022
//

import QtQuick 2.12
import QtGraphicalEffects 1.12

Item {
    property var gamepad
    property var pressAngle: 15

    Image {
        id:initialImage
        z: 50
        width: parent.width
        height: parent.height
        anchors.verticalCenter: parent.verticalCenter
        anchors.horizontalCenter: parent.horizontalCenter
        source: "qrc:/frontend/assets/gamepad/dpad_snes.png"
        visible: gamepad && !gamepad.buttonLeft && !gamepad.buttonRight && !gamepad.buttonUp && !gamepad.buttonDown
    }

    DpadHighlightSNES {
        id: dpleft
        z:70
        anchors.left: parent.left
        anchors.verticalCenter: parent.verticalCenter

        highlighted: padContainer.currentButton === "dpleft"
        pressed: gamepad && gamepad.buttonLeft
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

    DpadHighlightSNES {
        z:70
        id: dpright

        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter

        highlighted: padContainer.currentButton === "dpright"
        pressed: gamepad && gamepad.buttonRight
    }

    BrightnessContrast {
        z:60
        visible: gamepad && gamepad.buttonRight

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


    DpadHighlightSNES {
        id: dpup
        z:70

        anchors.top: parent.top
        anchors.horizontalCenter: parent.horizontalCenter

        highlighted: padContainer.currentButton === "dpup"
        pressed: gamepad && gamepad.buttonUp
    }

    BrightnessContrast {
        z:60
        visible: gamepad && gamepad.buttonUp

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

    DpadHighlightSNES {
        id: dpdown
        z: 70

        anchors.bottom: parent.bottom
        anchors.horizontalCenter: parent.horizontalCenter

        highlighted: padContainer.currentButton === "dpdown"
        pressed: gamepad && gamepad.buttonDown
    }

    BrightnessContrast {
        z:60
        visible: gamepad && gamepad.buttonDown

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
