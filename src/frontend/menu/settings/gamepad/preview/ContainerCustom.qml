// Pegasus Frontend
//
//Created by Bozo The Geek 12/03/2022
//

import QtQuick 2.12
import QtGraphicalEffects 1.15

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
    property bool hasSelect : true
    property bool hasStart : true
    property bool hasDedicatedGuide: true; //if false, the select is usually reused
    property bool hasDpad : true
    property bool hasButtonsForDpad : false
    property bool hasNintendoPad : false
    property bool hasA : true
    property bool hasB : true
    property bool hasX : true
    property bool hasY : true
    property bool hasL1 : true
    property bool hasR1 : true
    property bool hasL2 : true
    property bool hasR2 : true
    property bool hasLeftStick : true
    property bool hasRightStick : true
    property bool hasButtonsForRightStick : false
    property bool hasL3 : true //included in left stick usually
    property bool hasR3 : true //included in left stick usually
    property bool hasScreenshotButton : false

    //parameters for base
    property real ratio: 80/100 //at 80% of the size
    property int padBaseSourceSizeWidth : 906
    property int padBaseSourceSizeHeight : 398

    //parameters for select
    property int padSelectWidth : 69
    property int padSelectHeight : 59
    property int padSelectTopY: 205
    property int padSelectLeftX: 334

    //parameters for start
    property int padStartWidth : 69
    property int padStartHeight : 59
    property int padStartTopY: 205
    property int padStartLeftX: 432

    //parameters for guide/hotkey
    property int padGuideWidth : 0
    property int padGuideHeight : 0
    property int padGuideTopY: 0
    property int padGuideLeftX: 0

    //parameters for A/B/X/Y
    property int padAWidth : 71
    property int padAHeight : 70
    property int padATopY: -1
    property int padALeftX: -1

    property int padBWidth : 71
    property int padBHeight : 71
    property int padBTopY: -1
    property int padBLeftX: -1

    property int padXWidth : 71
    property int padXHeight : 71
    property int padXTopY: -1
    property int padXLeftX: -1

    property int padYWidth : 73
    property int padYHeight : 72
    property int padYTopY: -1
    property int padYLeftX: -1

    //parameter for Dpad
    property int dpadAreaTopY: -1
    property int dpadAreaBottomY: -1
    property int dpadAreaLeftX: -1
    property int dpadAreaRightX: -1

    //parameter for Dpad with dedicated buttons and separated
    property int dpadUpWidth : 69
    property int dpadUpHeight : 89
    property int dpadUpTopY: -1
    property int dpadUpLeftX: -1

    property int dpadDownWidth : 67
    property int dpadDownHeight : 89
    property int dpadDownTopY: -1
    property int dpadDownLeftX: -1

    property int dpadLeftWidth : 89
    property int dpadLeftHeight : 70
    property int dpadLeftTopY: -1
    property int dpadLeftLeftX: -1

    property int dpadRightWidth : 88
    property int dpadRightHeight : 70
    property int dpadRightTopY: -1
    property int dpadRightLeftX: -1

    //parameter for L1
    property int padL1Width : 198
    property int padL1Height : 37
    property int padL1TopY: 0
    property int padL1LeftX: 97
    //parameter for R1
    property int padR1Width : 198
    property int padR1Height : 36
    property int padR1TopY: 1
    property int padR1LeftX: 612

    //parameter for L2
    property int padL2Width : 48
    property int padL2Height : 5
    property int padL2TopY: 4
    property int padL2LeftX: 350
    //parameter for R2
    property int padR2Width : 54
    property int padR2Height: 6
    property int padR2TopY: 4
    property int padR2LeftX: 509

    //parameter for lStrick
    property int lStickWidth : 0
    property int lStickHeight: 0
    property int lStickTopY: 0
    property int lStickLeftX: 0

    //parameter for rStrick
    property int rStickWidth : 0
    property int rStickHeight: 0
    property int rStickTopY: 0
    property int rStickLeftX: 0

    //parameter for rStick Buttons
    property int rStickUpWidth : 0
    property int rStickUpHeight : 0
    property int rStickUpTopY: 0
    property int  rStickUpLeftX: 0

    property int rStickDownWidth : 0
    property int rStickDownHeight : 0
    property int rStickDownTopY: 0
    property int  rStickDownLeftX: 0

    property int rStickLeftWidth : 0
    property int rStickLeftHeight : 0
    property int rStickLeftTopY: 0
    property int  rStickLeftLeftX: 0

    property int rStickRightWidth : 0
    property int rStickRightHeight : 0
    property int rStickRightTopY: 0
    property int  rStickRightLeftX: 0

    //to manage contrast/brightness for button effects
    property real contrast: 0.5
    property real brightness: 0.5

    //to manage change of led colors (default values)
    property string rgbLedColor: ""
    property real rgbLedLuminosity:  1.0

    Image {
        id: padBase
        width: vpx(padBaseSourceSizeWidth * ratio)
        height: vpx(padBaseSourceSizeHeight * ratio)
        anchors.centerIn: parent

        fillMode: Image.PreserveAspectFit
        source: name ? "qrc:/frontend/assets/gamepad/" + name + "/base_" + name + ".png" : ""
        sourceSize {
            width: padBaseSourceSizeWidth
            height: padBaseSourceSizeHeight
        }
    }

    Image {
        id: padLed
        width: vpx(padBaseSourceSizeWidth * ratio) //parent.width
        height: vpx(padBaseSourceSizeHeight * ratio)
        anchors.centerIn: parent

        fillMode: Image.PreserveAspectFit
        source: name ? "qrc:/frontend/assets/gamepad/" + name + "/led_" + name + ".png" : ""
        sourceSize {
            width: padBaseSourceSizeWidth
            height: padBaseSourceSizeHeight
        }
        visible: rgbLedColor === "" ? true : false
    }

    ShaderEffect {
        anchors.fill: padBase  // Fill the same area as the Image
        visible: rgbLedColor !== "" ? true : false
        // Bind the image as a texture source
        property variant source: padLed
        property string rgbString: rgbLedColor
        property real red
        property real green
        property real blue
        property real luminosity: rgbLedLuminosity
        onRgbStringChanged: {
            if(rgbString !== ""){
                red = Number(rgbString.split(",")[0]) / 255.0;
                green = Number(rgbString.split(",")[1]) / 255.0;
                blue = Number(rgbString.split(",")[2]) / 255.0;
            }
        }

        // GLSL fragment shader to "color" tinted
        fragmentShader: "
            uniform sampler2D source;
            varying highp vec2 qt_TexCoord0;
            // The QML properties are available as uniforms
            uniform float red;
            uniform float green;
            uniform float blue;
            uniform highp float luminosity; // Parameter to control brightness
            // Create a vec3 from the uniform values
            vec3 targetColor = vec3(red, green, blue);

            void main() {
                // 1. Get the original pixel color
                lowp vec4 originalColor = texture2D(source, qt_TexCoord0);

                //for testing: to do it only with color with more blue
                if((originalColor.b > (originalColor.r * 2.0)) && (originalColor.b > (originalColor.g*2.0))){
                    // 2. Calculate the luminance (brightness) of the original pixel
                    // This gives us a single float from 0.0 (black) to 1.0 (white)
                    highp float luminance = dot(originalColor.rgb, vec3(0.2126, 0.7152, 0.0722));

                    // 3. Create the new color by multiplying the base color by the luminance
                    // Multiplying the base color's R, G, and B values by the luminance
                    // effectively scales them down, making them darker for lower luminance values.
                    vec3 tintedColor = targetColor * luminance;

                    // 4. Apply the luminosity parameter
                    // Multiply the tinted color by the luminosity value.
                    // A value > 1.0 makes the image brighter, and < 1.0 makes it darker.
                    vec3 finalColor = tintedColor * luminosity;

                    // 5. To prevent the color values from exceeding 1.0, you can clamp them.
                    // This avoids 'blowing out' the highlights and keeps the color within the valid range.
                    finalColor = clamp(finalColor, 0.0, 1.0);

                    // 6. Output the final, adjusted color
                    gl_FragColor = vec4(finalColor, originalColor.a);

                } else {
                    gl_FragColor = originalColor;
                }
            }
        "
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

        contrast: padContainer.contrast
        brightness: padContainer.brightness
        shortName: "l2"
        name: hasL2 ? padContainer.name : ""
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

        contrast: padContainer.contrast
        brightness: padContainer.brightness
        shortName: "l1"
        name: hasL1 ? padContainer.name : ""
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

        contrast: padContainer.contrast
        brightness: padContainer.brightness
        shortName: "r2"
        name: hasR2 ? padContainer.name : ""
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

        contrast: padContainer.contrast
        brightness: padContainer.brightness
        shortName: "r1"
        name: hasR1 ? padContainer.name : ""
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

        contrast: padContainer.contrast
        brightness: padContainer.brightness
        shortName: "select"
        name: hasSelect ? padContainer.name : ""
        pressed: gamepad ? gamepad.buttonSelect : false
        visible: gamepad ? (!padGuide.pressed || hasDedicatedGuide) : true

    }

    PadButtonCustom {
        id: padGuide //as select one in case of SNES/NES layout

        width: hasDedicatedGuide ? vpx(padGuideWidth * ratio) : vpx(padSelectWidth * ratio)
        height: hasDedicatedGuide ? vpx(padGuideHeight * ratio) : vpx(padSelectHeight * ratio)

        anchors {
            verticalCenter: padBase.verticalCenter
            horizontalCenter: padBase.horizontalCenter
            verticalCenterOffset: hasDedicatedGuide ? vpx(-((padBaseSourceSizeHeight/2) - (padGuideTopY + (padGuideHeight/2))) * ratio) : vpx(-((padBaseSourceSizeHeight/2) - (padSelectTopY + (padSelectHeight/2))) * ratio);
            horizontalCenterOffset: hasDedicatedGuide ? vpx(-((padBaseSourceSizeWidth/2) - (padGuideLeftX + (padGuideWidth/2))) * ratio) : vpx(-((padBaseSourceSizeWidth/2) - (padSelectLeftX + (padSelectWidth/2))) * ratio);
        }

        contrast: padContainer.contrast
        brightness: padContainer.brightness
        shortName: "guide"
        name: (hasSelect || hasDedicatedGuide) ? padContainer.name : ""
        pressed: gamepad ? gamepad.buttonGuide : false
        visible: gamepad ? (!padSelect.pressed || hasDedicatedGuide) : true
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

        contrast: padContainer.contrast
        brightness: padContainer.brightness
        shortName: "start"
        name: hasStart ? padContainer.name : ""
        pressed: gamepad ? gamepad.buttonStart : false
    }

    PadButtonCustom {
        id: padB
        width: vpx(padBWidth * ratio)
        height: vpx(padBHeight * ratio)

        anchors {
            horizontalCenter: padBase.horizontalCenter;
            verticalCenter: padBase.verticalCenter;
            verticalCenterOffset: vpx(-((padBaseSourceSizeHeight/2) - (padBTopY + (padBHeight/2))) * ratio);
            horizontalCenterOffset: vpx(-((padBaseSourceSizeWidth/2) - (padBLeftX + (padBWidth/2))) * ratio);
        }

        shortName: "b"
        name: hasB ? padContainer.name : ""
        pressed: gamepad ? (hasNintendoPad ? gamepad.buttonSouth : gamepad.buttonEast) : false
    }
    PadButtonCustom {
        id: padA
        width: vpx(padAWidth * ratio)
        height: vpx(padAHeight * ratio)

        anchors {
            horizontalCenter: padBase.horizontalCenter
            verticalCenter: padBase.verticalCenter
            verticalCenterOffset: vpx(-((padBaseSourceSizeHeight/2) - (padATopY + (padAHeight/2))) * ratio);
            horizontalCenterOffset: vpx(-((padBaseSourceSizeWidth/2) - (padALeftX + (padAWidth/2))) * ratio);
        }

        shortName: "a"
        name: hasA ? padContainer.name : ""
        pressed: gamepad ? (hasNintendoPad ? gamepad.buttonEast : gamepad.buttonSouth) : false
    }
    PadButtonCustom {
        id: padY
        width: vpx(padYWidth * ratio)
        height: vpx(padYHeight * ratio)

        anchors {
            horizontalCenter: padBase.horizontalCenter
            verticalCenter: padBase.verticalCenter
            verticalCenterOffset: vpx(-((padBaseSourceSizeHeight/2) - (padYTopY + (padYHeight/2))) * ratio);
            horizontalCenterOffset: vpx(-((padBaseSourceSizeWidth/2) - (padYLeftX + (padYWidth/2))) * ratio);
        }

        shortName: "y"
        name: hasY ? padContainer.name : ""
        pressed: gamepad ? (hasNintendoPad ? gamepad.buttonWest : gamepad.buttonNorth) : false
    }
    PadButtonCustom {
        id: padX
        width: vpx(padXWidth * ratio)
        height: vpx(padXHeight * ratio)

        anchors {
            horizontalCenter: padBase.horizontalCenter
            verticalCenter: padBase.verticalCenter
            verticalCenterOffset: vpx(-((padBaseSourceSizeHeight/2) - (padXTopY + (padXHeight/2))) * ratio);
            horizontalCenterOffset: vpx(-((padBaseSourceSizeWidth/2) - (padXLeftX + (padXWidth/2))) * ratio);
        }

        shortName: "x"
        name: hasX ? padContainer.name : ""
        pressed: gamepad ? (hasNintendoPad ? gamepad.buttonNorth : gamepad.buttonWest) : false
    }

    DpadCustom {
        id: padDpadArea
        //to manage better when sticks are on the same place as for 8bitdo arcade Stick using a circle switch to manage different mode (LS,DP,RS)
        z:  gamepad && (gamepad.buttonLeft || gamepad.buttonRight || gamepad.buttonUp || gamepad.buttonDown) ? 200 : 100

        width: vpx((dpadAreaRightX-dpadAreaLeftX) * ratio)
        height: vpx((dpadAreaBottomY-dpadAreaTopY) * ratio)
        anchors {
            verticalCenter: padBase.verticalCenter
            horizontalCenter: padBase.horizontalCenter
            verticalCenterOffset: vpx(-((padBaseSourceSizeHeight/2) - (dpadAreaTopY + ((dpadAreaBottomY-dpadAreaTopY)/2))) * ratio);
            horizontalCenterOffset: vpx(-((padBaseSourceSizeWidth/2) - (dpadAreaLeftX + ((dpadAreaRightX-dpadAreaLeftX)/2))) * ratio);
        }
        name: (hasDpad && !hasButtonsForDpad) ? padContainer.name : ""
        gamepad: parent.gamepad
    }

    PadButtonCustom {
        id: dpadUp
        width: vpx(dpadUpWidth * ratio)
        height: vpx(dpadUpHeight * ratio)

        anchors {
            horizontalCenter: padBase.horizontalCenter;
            verticalCenter: padBase.verticalCenter;
            verticalCenterOffset: vpx(-((padBaseSourceSizeHeight/2) - (dpadUpTopY + (dpadUpHeight/2))) * ratio);
            horizontalCenterOffset: vpx(-((padBaseSourceSizeWidth/2) - (dpadUpLeftX + (dpadUpWidth/2))) * ratio);
        }

        contrast: padContainer.contrast
        brightness:  padContainer.brightness
        shortName: "dpup"
        name: (hasDpad && hasButtonsForDpad) ? padContainer.name : ""
        pressed: gamepad ? gamepad.buttonUp : false
    }

    PadButtonCustom {
        id: dpadDown
        width: vpx(dpadDownWidth * ratio)
        height: vpx(dpadDownHeight * ratio)

        anchors {
            horizontalCenter: padBase.horizontalCenter;
            verticalCenter: padBase.verticalCenter;
            verticalCenterOffset: vpx(-((padBaseSourceSizeHeight/2) - (dpadDownTopY + (dpadDownHeight/2))) * ratio);
            horizontalCenterOffset: vpx(-((padBaseSourceSizeWidth/2) - (dpadDownLeftX + (dpadDownWidth/2))) * ratio);
        }

        contrast: padContainer.contrast
        brightness:  padContainer.brightness
        shortName: "dpdown"
        name: (hasDpad && hasButtonsForDpad) ? padContainer.name : ""
        pressed: gamepad ? gamepad.buttonDown : false
    }

    PadButtonCustom {
        id: dpadLeft
        width: vpx(dpadLeftWidth * ratio)
        height: vpx(dpadLeftHeight * ratio)

        anchors {
            horizontalCenter: padBase.horizontalCenter;
            verticalCenter: padBase.verticalCenter;
            verticalCenterOffset: vpx(-((padBaseSourceSizeHeight/2) - (dpadLeftTopY + (dpadLeftHeight/2))) * ratio);
            horizontalCenterOffset: vpx(-((padBaseSourceSizeWidth/2) - (dpadLeftLeftX + (dpadLeftWidth/2))) * ratio);
        }

        contrast: padContainer.contrast
        brightness:  padContainer.brightness
        shortName: "dpleft"
        name: (hasDpad && hasButtonsForDpad) ? padContainer.name : ""
        pressed: gamepad ? gamepad.buttonLeft : false
    }

    PadButtonCustom {
        id: dpadRight
        width: vpx(dpadRightWidth * ratio)
        height: vpx(dpadRightHeight * ratio)

        anchors {
            horizontalCenter: padBase.horizontalCenter;
            verticalCenter: padBase.verticalCenter;
            verticalCenterOffset: vpx(-((padBaseSourceSizeHeight/2) - (dpadRightTopY + (dpadRightHeight/2))) * ratio);
            horizontalCenterOffset: vpx(-((padBaseSourceSizeWidth/2) - (dpadRightLeftX + (dpadRightWidth/2))) * ratio);
        }

        contrast: padContainer.contrast
        brightness:  padContainer.brightness
        shortName: "dpright"
        name: (hasDpad && hasButtonsForDpad) ? padContainer.name : ""
        pressed: gamepad ? gamepad.buttonRight : false
    }

    StickCustom {
        id: padLeftStick

        //to better manage when sticks are on the same place as for 8bitdo arcade Stick using a circle switch to manage different mode (LS,DP,RS)
        z: (padContainer.currentButton === (side + "x")) || (padContainer.currentButton === (side + "y")) ? 200 : 100

        width: vpx(lStickWidth * ratio)
        anchors {
            verticalCenter: padBase.verticalCenter
            horizontalCenter: padBase.horizontalCenter
            verticalCenterOffset: vpx(-((padBaseSourceSizeHeight/2) - (lStickTopY + (lStickHeight/2))) * ratio);
            horizontalCenterOffset: vpx(-((padBaseSourceSizeWidth/2) - (lStickLeftX + (lStickWidth/2))) * ratio);
        }

        contrast: padContainer.contrast
        brightness:  padContainer.brightness
        side: "l"
        name: hasLeftStick ? padContainer.name : ""
        pressed: hasL3 && gamepad ? gamepad.buttonL3 : false
        xPercent: (gamepad && gamepad.axisLeftX) || 0.0
        yPercent: (gamepad && gamepad.axisLeftY) || 0.0
    }


    PadButtonCustom {
        id: padRightStickUp

        width: vpx(rStickUpWidth * ratio)
        height: vpx(rStickUpHeight * ratio)

        anchors {
            horizontalCenter: padBase.horizontalCenter;
            verticalCenter: padBase.verticalCenter;
            verticalCenterOffset: vpx(-((padBaseSourceSizeHeight/2) - (rStickUpTopY + (rStickUpHeight/2))) * ratio);
            horizontalCenterOffset: vpx(-((padBaseSourceSizeWidth/2) - (rStickUpLeftX + (rStickUpWidth/2))) * ratio);
        }

        contrast: padContainer.contrast
        brightness:  padContainer.brightness
        shortName: "rstickup"
        name: (hasRightStick && hasButtonsForRightStick) ? padContainer.name : ""
        pressed: (gamepad && gamepad.axisRightY < -0.5) ? true : false
    }

    PadButtonCustom {
        id: padRightStickDown

        width: vpx(rStickDownWidth * ratio)
        height: vpx(rStickDownHeight * ratio)

        anchors {
            horizontalCenter: padBase.horizontalCenter;
            verticalCenter: padBase.verticalCenter;
            verticalCenterOffset: vpx(-((padBaseSourceSizeHeight/2) - (rStickDownTopY + (rStickDownHeight/2))) * ratio);
            horizontalCenterOffset: vpx(-((padBaseSourceSizeWidth/2) - (rStickDownLeftX + (rStickDownWidth/2))) * ratio);
        }

        contrast: padContainer.contrast
        brightness:  padContainer.brightness
        shortName: "rstickdown"
        name: (hasRightStick && hasButtonsForRightStick) ? padContainer.name : ""
        pressed: (gamepad && gamepad.axisRightY > 0.5) ? true : false
    }

    PadButtonCustom {
        id: padRightStickLeft

        width: vpx(rStickLeftWidth * ratio)
        height: vpx(rStickLeftHeight * ratio)

        anchors {
            horizontalCenter: padBase.horizontalCenter;
            verticalCenter: padBase.verticalCenter;
            verticalCenterOffset: vpx(-((padBaseSourceSizeHeight/2) - (rStickLeftTopY + (rStickLeftHeight/2))) * ratio);
            horizontalCenterOffset: vpx(-((padBaseSourceSizeWidth/2) - (rStickLeftLeftX + (rStickLeftWidth/2))) * ratio);
        }

        contrast: padContainer.contrast
        brightness:  padContainer.brightness
        shortName: "rstickleft"
        name: (hasRightStick && hasButtonsForRightStick) ? padContainer.name : ""
        pressed: (gamepad && gamepad.axisRightX < -0.5) ? true : false
    }


    PadButtonCustom {
        id: padRightStickRight

        width: vpx(rStickRightWidth * ratio)
        height: vpx(rStickRightHeight * ratio)

        anchors {
            horizontalCenter: padBase.horizontalCenter;
            verticalCenter: padBase.verticalCenter;
            verticalCenterOffset: vpx(-((padBaseSourceSizeHeight/2) - (rStickRightTopY + (rStickRightHeight/2))) * ratio);
            horizontalCenterOffset: vpx(-((padBaseSourceSizeWidth/2) - (rStickRightLeftX + (rStickRightWidth/2))) * ratio);
        }

        contrast: padContainer.contrast
        brightness:  padContainer.brightness
        shortName: "rstickright"
        name: (hasRightStick && hasButtonsForRightStick) ? padContainer.name : ""
        pressed: (gamepad && gamepad.axisRightX > 0.5) ? true : false
    }

    StickCustom {
        id: padRightStick

        //to manage better when sticks are on the same place as for 8bitdo arcade Stick using a circle switch to manage different mode (LS,DP,RS)
        z: (padContainer.currentButton === (side + "x")) || (padContainer.currentButton === (side + "y")) ? 200 : 100

        width: vpx(rStickWidth * ratio)
        anchors {
            verticalCenter: padBase.verticalCenter
            horizontalCenter: padBase.horizontalCenter
            verticalCenterOffset: vpx(-((padBaseSourceSizeHeight/2) - (rStickTopY + (rStickHeight/2))) * ratio);
            horizontalCenterOffset: vpx(-((padBaseSourceSizeWidth/2) - (rStickLeftX + (rStickWidth/2))) * ratio);
        }

        contrast: padContainer.contrast
        brightness:  padContainer.brightness
        side: "r"
        name: (hasRightStick && !hasButtonsForRightStick) ? padContainer.name : ""
        pressed: hasR3 && gamepad ? gamepad.buttonR3 : false
        xPercent: (gamepad && gamepad.axisRightX) || 0.0
        yPercent: (gamepad && gamepad.axisRightY) || 0.0
    }

}
