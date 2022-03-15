// Pegasus Frontend
//
//Created by Bozo The Geek 12/03/2022
//

import QtQuick 2.12

Item {
    id: padContainer
    width: parent.width
    height: padBase.height
    anchors.verticalCenter: parent.verticalCenter
    anchors.verticalCenterOffset: vpx(45)

    property var gamepad
    property string currentButton: ""
    property string name: "" //used to find file named as "x_name.jpg" : x_nes.png or x_snes.png for example

    //layout availability features list
    property var hasSelect : true
    property var hasStart : true
    property var hasDedicatedGuide : false
    property var hasDpad : true
    property var hasA : true
    property var hasB : true
    property var hasX : false
    property var hasY : false
    property var hasL1 : true
    property var hasR1 : true
    property var hasL2 : true
    property var hasR2 : true
    property var hasLeftStick : false
    property var hasRightStick : false
    property var hasScreenshotButton : false

    //parameters for base
    property var ratio: 80/100 //at 80% of the size
    property var padBaseSourceSizeWidth : 906
    property var padBaseSourceSizeHeight : 398

    //parameters for select
    property var padSelectWidth : 69
    property var padSelectHeight : 59
    property var padSelectTopY: 205
    property var padSelectLeftX: 334

    //parameters for start
    property var padStartWidth : 69
    property var padStartHeight : 59
    property var padStartTopY: 205
    property var padStartLeftX: 432

    //parameters for A/B/X/Y
    property var padABXYAreaTopY: 103
    property var padABXYAreaBottomY: 308
    property var padABXYAreaLeftX: 590
    property var padABXYAreaRightX: 836

    property var padAWidth : 71
    property var padAHeight : 70
    property var padATopY: -1
    property var padALeftX: -1

    property var padBWidth : 71
    property var padBHeight : 71
    property var padBTopY: -1
    property var padBLeftX: -1

    property var padXWidth : 71
    property var padXHeight : 71
    property var padXTopY: -1
    property var padXLeftX: -1

    property var padYWidth : 73
    property var padYHeight : 72
    property var padYTopY: -1
    property var padYLeftX: -1

    //parameter for Dpad
    property var dpadAreaTopY: 126
    property var dpadAreaBottomY: 285
    property var dpadAreaLeftX: 112
    property var dpadAreaRightX: 270

    //parameter for L1
    property var padL1Width : 198
    property var padL1Height : 37
    property var padL1TopY: 0
    property var padL1LeftX: 97
    //parameter for R1
    property var padR1Width : 198
    property var padR1Height : 36
    property var padR1TopY: 1
    property var padR1LeftX: 612

    //parameter for L2
    property var padL2Width : 48
    property var padL2Height : 5
    property var padL2TopY: 4
    property var padL2LeftX: 350
    //parameter for R2
    property var padR2Width : 54
    property var padR2Height: 6
    property var padR2TopY: 4
    property var padR2LeftX: 509


    Image {
        id: padBase
        width: parent.width
        height: vpx(padBaseSourceSizeHeight * ratio)
        anchors.centerIn: parent

        fillMode: Image.PreserveAspectFit
        source: "qrc:/frontend/assets/gamepad/base_" + name + ".png"
        sourceSize {
            width: padBaseSourceSizeWidth
            height: padBaseSourceSizeHeight
        }
    }

    PadTriggerCustom {
        id: padL2
        width: vpx(padL2Width * ratio)
        height: vpx(padL2Height * ratio)

        anchors {
            verticalCenter: padBase.verticalCenter
            horizontalCenter: padBase.horizontalCenter
            verticalCenterOffset: vpx(-((padBaseSourceSizeHeight/2) - (padL2TopY + (padL2Height/2))) * ratio);
            horizontalCenterOffset: vpx(-((padBaseSourceSizeWidth/2) - (padL2LeftX + (padL2Width/2))) * ratio);
        }

        shortName: "l2"
        name: padContainer.name
        pressed: gamepad ? gamepad.buttonL2 : false
    }

    PadShoulderCustom {
        id: padL1
        width: vpx(padL1Width * ratio)
        height: vpx(padL1Height * ratio)

        anchors {
            verticalCenter: padBase.verticalCenter
            horizontalCenter: padBase.horizontalCenter
            verticalCenterOffset: vpx(-((padBaseSourceSizeHeight/2) - (padL1TopY + (padL1Height/2))) * ratio);
            horizontalCenterOffset: vpx(-((padBaseSourceSizeWidth/2) - (padL1LeftX + (padL1Width/2))) * ratio);
        }

        shortName: "l1"
        name: padContainer.name
        pressed: gamepad ? gamepad.buttonL1 : false
    }
    PadTriggerCustom {
        id: padR2
        width: vpx(padR2Width * ratio)
        height: vpx(padR2Height * ratio)

        anchors {
            verticalCenter: padBase.verticalCenter
            horizontalCenter: padBase.horizontalCenter
            verticalCenterOffset: vpx(-((padBaseSourceSizeHeight/2) - (padR2TopY + (padR2Height/2))) * ratio);
            horizontalCenterOffset: vpx(-((padBaseSourceSizeWidth/2) - (padR2LeftX + (padR2Width/2))) * ratio);
        }

        shortName: "r2"
        name: padContainer.name
        pressed: gamepad ? gamepad.buttonR2 : false
    }

    PadShoulderCustom {
        id: padR1
        width: vpx(padR1Width * ratio)
        height: vpx(padR1Height * ratio)

        anchors {
            verticalCenter: padBase.verticalCenter
            horizontalCenter: padBase.horizontalCenter
            verticalCenterOffset: vpx(-((padBaseSourceSizeHeight/2) - (padR1TopY + (padR1Height/2))) * ratio);
            horizontalCenterOffset: vpx(-((padBaseSourceSizeWidth/2) - (padR1LeftX + (padR1Width/2))) * ratio);
        }

        shortName: "r1"
        name: padContainer.name
        pressed: gamepad ? gamepad.buttonR1 : false
    }


    PadButtonCustom {
        id: padSelect
        width: vpx(padSelectWidth * ratio)
        height: vpx(padSelectHeight * ratio)

        anchors {
            verticalCenter: padBase.verticalCenter
            horizontalCenter: padBase.horizontalCenter
            verticalCenterOffset: vpx(-((padBaseSourceSizeHeight/2) - (padSelectTopY + (padSelectHeight/2))) * ratio);
            horizontalCenterOffset: vpx(-((padBaseSourceSizeWidth/2) - (padSelectLeftX + (padSelectWidth/2))) * ratio);
        }

        shortName: "select"
        name: padContainer.name
        pressed: gamepad ? (gamepad.buttonSelect || gamepad.buttonGuide)  : false
        visible: gamepad ? !padGuide.pressed : true

    }

    PadButtonCustom {
        id: padGuide //as select one in case of SNES layout

        width: vpx(padSelectWidth * ratio)
        height: vpx(padSelectHeight * ratio)

        anchors {
            verticalCenter: padBase.verticalCenter
            horizontalCenter: padBase.horizontalCenter
            verticalCenterOffset: vpx(-((padBaseSourceSizeHeight/2) - (padSelectTopY + (padSelectHeight/2))) * ratio);
            horizontalCenterOffset: vpx(-((padBaseSourceSizeWidth/2) - (padSelectLeftX + (padSelectWidth/2))) * ratio);
        }

        shortName: "guide"
        name: padContainer.name
        pressed: gamepad ? gamepad.buttonGuide : false
        visible: gamepad ? !padSelect.pressed : true
    }

    PadButtonCustom {
        id: padStart

        width: vpx(padStartWidth * ratio)
        height: vpx(padStartHeight * ratio)

        anchors {
            verticalCenter: padBase.verticalCenter
            horizontalCenter: padBase.horizontalCenter
            verticalCenterOffset: vpx(-((padBaseSourceSizeHeight/2) - (padStartTopY + (padStartHeight/2))) * ratio);
            horizontalCenterOffset: vpx(-((padBaseSourceSizeWidth/2) - (padStartLeftX + (padStartWidth/2))) * ratio);
        }

        shortName: "start"
        name: padContainer.name
        pressed: gamepad ? gamepad.buttonStart : false
    }

    Item {
        id: padABXYArea

        width: vpx((padABXYAreaRightX-padABXYAreaLeftX) * ratio)
        height: vpx((padABXYAreaBottomY-padABXYAreaTopY) * ratio)
        anchors {
            verticalCenter: padBase.verticalCenter
            horizontalCenter: padBase.horizontalCenter
            verticalCenterOffset: vpx(-((padBaseSourceSizeHeight/2) - (padABXYAreaTopY + ((padABXYAreaBottomY-padABXYAreaTopY)/2))) * ratio);
            horizontalCenterOffset: vpx(-((padBaseSourceSizeWidth/2) - (padABXYAreaLeftX + ((padABXYAreaRightX-padABXYAreaLeftX)/2))) * ratio);
        }

        PadButtonCustom {
            id: padB
            width: vpx(padBWidth * ratio)
            height: vpx(padBHeight * ratio)

            anchors {
                bottom: padBTopY === -1 ? parent.bottom : undefined
                horizontalCenter: padBLeftX === -1 ? parent.horizontalCenter : padBase.horizontalCenter
                verticalCenter: padBTopY === -1 ? undefined : padBase.verticalCenter
                verticalCenterOffset: padBTopY === -1 ? 0 : vpx(-((padBaseSourceSizeHeight/2) - (padBTopY + (padBWidth/2))) * ratio);
                horizontalCenterOffset: padBLeftX === -1 ? 0 : vpx(-((padBaseSourceSizeWidth/2) - (padBLeftX + (padBHeight/2))) * ratio);
            }

            shortName: "b"
            name: padContainer.name
            pressed: gamepad ? gamepad.buttonSouth : false
        }
        PadButtonCustom {
            id: padA
            width: vpx(padAWidth * ratio)
            height: vpx(padAHeight * ratio)

            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter

            shortName: "a"
            name: padContainer.name
            pressed: gamepad ? gamepad.buttonEast : false
        }
        PadButtonCustom {
            id: padY
            width: vpx(padYWidth * ratio)
            height: vpx(padYHeight * ratio)
            anchors.left: parent.left
            anchors.verticalCenter: parent.verticalCenter
            shortName: "y"
            name: padContainer.name
            pressed: gamepad ? gamepad.buttonWest : false
        }
        PadButtonCustom {
            id: padX
            width: vpx(padXWidth * ratio)
            height: vpx(padXHeight * ratio)
            anchors.top: parent.top
            anchors.horizontalCenter: parent.horizontalCenter
            shortName: "x"
            name: padContainer.name
            pressed: gamepad ? gamepad.buttonNorth : false
        }
    }

    DpadCustom {
        id: padDpadArea

        width: vpx((dpadAreaRightX-dpadAreaLeftX) * ratio)
        height: vpx((dpadAreaBottomY-dpadAreaTopY) * ratio)
        anchors {
            verticalCenter: padBase.verticalCenter
            horizontalCenter: padBase.horizontalCenter
            verticalCenterOffset: vpx(-((padBaseSourceSizeHeight/2) - (dpadAreaTopY + ((dpadAreaBottomY-dpadAreaTopY)/2))) * ratio);
            horizontalCenterOffset: vpx(-((padBaseSourceSizeWidth/2) - (dpadAreaLeftX + ((dpadAreaRightX-dpadAreaLeftX)/2))) * ratio);
        }
        name: padContainer.name
        gamepad: parent.gamepad
    }
}
