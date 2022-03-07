// Pegasus Frontend
// Copyright (C) 2017-2019  Mátyás Mustoha
//
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with this program. If not, see <http://www.gnu.org/licenses/>.


import QtQuick 2.12
import QtGraphicalEffects 1.12

Item {
    property var gamepad

    Image {
        id:pressedImage
        z: 50
        //anchors.fill: parent
        width: parent.width //* 0.95
        height: parent.height //* 0.95
        anchors.verticalCenter: parent.verticalCenter
        anchors.horizontalCenter: parent.horizontalCenter

        //fillMode: Image.PreserveAspectFit
        source: "qrc:/frontend/assets/gamepad/dpad_snes.png"
        /*sourceSize {
            width: 128
            height: 128
        }*/
        visible: false //test.pressed
    }

    BrightnessContrast {
        z:100
        visible: test.pressed
        //enabled: pressed
        anchors.fill: pressedImage
        source: pressedImage
        brightness: 0.5
        contrast: 0.5
        transform: Rotation { origin.x: pressedImage.width/2; origin.y: pressedImage.height/2; axis { x: 0; y: 1; z: 0 } angle: 20 }
    }




    DpadHighlightSNES {
        id:test
        anchors.left: parent.left
        anchors.verticalCenter: parent.verticalCenter

        highlighted: padContainer.currentButton === "dpleft"
        pressed: gamepad && gamepad.buttonLeft
    }
    DpadHighlightSNES {
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter

        highlighted: padContainer.currentButton === "dpright"
        pressed: gamepad && gamepad.buttonRight
    }
    DpadHighlightSNES {
        anchors.top: parent.top
        anchors.horizontalCenter: parent.horizontalCenter

        highlighted: padContainer.currentButton === "dpup"
        pressed: gamepad && gamepad.buttonUp
    }
    DpadHighlightSNES {
        anchors.bottom: parent.bottom
        anchors.horizontalCenter: parent.horizontalCenter

        highlighted: padContainer.currentButton === "dpdown"
        pressed: gamepad && gamepad.buttonDown
    }
}
