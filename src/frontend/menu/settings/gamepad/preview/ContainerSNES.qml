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

Item {
    id: padContainer
    width: parent.width
    height: padBase.height
    anchors.verticalCenter: parent.verticalCenter
    anchors.verticalCenterOffset: vpx(45)

    property var gamepad
    property string currentButton: ""


    Image {
        id: padBase
        width: parent.width
        height: vpx(398 * 80/100) //at 80% of the size
        anchors.centerIn: parent

        fillMode: Image.PreserveAspectFit
        //source: "qrc:/frontend/assets/gamepad/base.svg"
        //source: "qrc:/frontend/assets/gamepad/snes_layout.png"
        source: "qrc:/frontend/assets/gamepad/base_snes.png"
        sourceSize {
            width: 906
            height: 398
        }
    }
/*
    PadTrigger {
        id: padL2
        width: vpx(50)
        anchors {
            bottom: padBase.verticalCenter
            bottomMargin: vpx(113)
            right: padBase.horizontalCenter
            rightMargin: vpx(131)
        }

        shortName: "l2"
        pressed: gamepad && gamepad.buttonL2
    }
    PadShoulder {
        id: padL1
        width: vpx(110)
        anchors {
            bottom: padBase.verticalCenter
            bottomMargin: vpx(84)
            right: padBase.horizontalCenter
            rightMargin: vpx(110)
        }

        shortName: "l1"
        pressed: gamepad && gamepad.buttonL1
    }
    PadTrigger {
        id: padR2
        width: padL2.width
        anchors {
            bottom: padBase.verticalCenter
            bottomMargin: padL2.anchors.bottomMargin
            left: padBase.horizontalCenter
            leftMargin: padL2.anchors.rightMargin
        }

        shortName: "r2"
        pressed: gamepad && gamepad.buttonR2
    }
    PadShoulder {
        id: padR1
        width: padL1.width
        anchors {
            bottom: padBase.verticalCenter
            bottomMargin: padL1.anchors.bottomMargin
            left: padBase.horizontalCenter
            leftMargin: padL1.anchors.rightMargin
        }

        shortName: "r1"
        pressed: gamepad && gamepad.buttonR1
    }
    */
    /*Item {
        width: padSelect.width + padGuide.width + padStart.width + 10
        height: padGuide.height
        anchors {
            verticalCenter: padBase.verticalCenter
            verticalCenterOffset: vpx(-20)
            horizontalCenter: padBase.horizontalCenter
        }
        PadButton {
            id: padSelect
            width: vpx(38)
            anchors.left: parent.left
            anchors.verticalCenter: parent.verticalCenter

            shortName: "select"
            pressed: gamepad && gamepad.buttonSelect
        }
        PadButton {
            id: padStart
            width: vpx(38)
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter

            shortName: "start"
            pressed: gamepad && gamepad.buttonStart
        }
        PadButton {
            id: padGuide
            width: vpx(50)
            anchors.centerIn: parent

            shortName: "guide"
            pressed: gamepad && gamepad.buttonGuide
        }
    }*/

    Item {
        id: padABXYArea
        //Global Ratio to be in the container: 80/100
        //PADButtons AREA
        //left X: 590
        //Right X: 834
        //Top Y: 103
        //Bottom Y: 308
        //Image Height: 398
        //Image Width: 906
        //Vertical Center position : 206

        width: vpx((834-590) * 80/100)
        height: vpx((308-103) * 80/100)
        anchors {
            verticalCenter: padBase.verticalCenter
            verticalCenterOffset: vpx(-((398/2)-206) * 80/100)
            left: padBase.horizontalCenter
            leftMargin: vpx((590-(906/2)) * 80/100)
        }

        //for test purpose only
        /*Rectangle {
            id: areaplace
            color: "red"
            anchors.fill: parent
            opacity: 0.5
            visible: true
        }*/

        PadButtonSNES {
            id: padB
            //width of button in pixel : 71
            //height of button in pixel : 71
            width: vpx(71 * 80/100)
            height: vpx(71 * 80/100)

            anchors.bottom: parent.bottom

            anchors.horizontalCenter: parent.horizontalCenter

            shortName: "b"
            pressed: gamepad && gamepad.buttonSouth

        }
        PadButtonSNES {
            id: padA
            width: vpx(71 * 80/100)
            height: vpx(70 * 80/100)
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter

            shortName: "a"
            pressed: gamepad && gamepad.buttonEast
        }
        PadButtonSNES {
            id: padY
            width: vpx(73 * 80/100)
            height: vpx(72 * 80/100)
            anchors.left: parent.left
            anchors.verticalCenter: parent.verticalCenter

            shortName: "y"
            pressed: gamepad && gamepad.buttonWest
        }
        PadButtonSNES {
            id: padX
            width: vpx(71 * 80/100)
            height: vpx(71 * 80/100)
            anchors.top: parent.top
            anchors.horizontalCenter: parent.horizontalCenter
            shortName: "x"
            pressed: gamepad && gamepad.buttonNorth
        }
    }

    DpadSNES {
        id: padDpadArea
        //Global Ratio to be in the container: 80/100
        //DPAD AREA
        //left X: 112
        //Right X: 270
        //Top Y: 126
        //Bottom Y: 285
        //Image Height: 398
        //Image Width: 906
        //Vertical Center position : 206
        width: vpx((270-112) * 80/100)
        height: vpx((285-126) * 80/100)
        anchors {
            verticalCenter: padBase.verticalCenter
            verticalCenterOffset: vpx(-((398/2)-206) * 80/100)
            //left: padBase.horizontalCenter
            //leftMargin: vpx((112-(906/2)) * 80/100)
            right: padBase.horizontalCenter
            rightMargin: vpx(((906/2) - 270) *80/100)
        }

        /*width: padABXYArea.width * 0.95
        height: width
        anchors {
            verticalCenter: padBase.verticalCenter
            verticalCenterOffset: padABXYArea.anchors.verticalCenterOffset
            right: padBase.horizontalCenter
            rightMargin: padABXYArea.anchors.leftMargin
        }*/



        gamepad: parent.gamepad
    }

/*    Stick {
        id: padLeftStick
        width: vpx(110)
        anchors {
            top: padBase.verticalCenter
            topMargin: vpx(22)
            right: padBase.horizontalCenter
            rightMargin: vpx(18)
        }

        side: "l"
        pressed: gamepad && gamepad.buttonL3
        xPercent: (gamepad && gamepad.axisLeftX) || 0.0
        yPercent: (gamepad && gamepad.axisLeftY) || 0.0
    }
    Stick {
        id: padRightStick
        width: padLeftStick.width
        anchors {
            top: padBase.verticalCenter
            topMargin: padLeftStick.anchors.topMargin
            left: padBase.horizontalCenter
            leftMargin: padLeftStick.anchors.rightMargin
        }
        side: "r"
        pressed: gamepad && gamepad.buttonR3
        xPercent: (gamepad && gamepad.axisRightX) || 0.0
        yPercent: (gamepad && gamepad.axisRightY) || 0.0
    }
*/
}
