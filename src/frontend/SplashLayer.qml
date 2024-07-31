// Pegasus Frontend
// Copyright (C) 2017-2018  Mátyás Mustoha
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


import QtQuick 2.15

Rectangle {
    id: root

    color: "#000"
    anchors.fill: parent

    property real progress: api.internal.meta.loadingProgress
    property bool showDataProgressText: true

    Behavior on progress { NumberAnimation { duration: 500 } }

    function shuffle(array) {
        for (var i = array.length - 1; i > 0; i--) {
            var j = Math.floor(Math.random() * (i + 1));
            var temp = array[i];
            array[i] = array[j];
            array[j] = temp;
        }
        return array;
    }

    property var images: shuffle([
        "assets/logopegasus.png",
        "assets/recalbox-next.svg",
        "assets/libretro-retroarch-simple-logo.png",
        "assets/logonvidia.png"
    ])
    property int currentIndex: 0

    AnimatedImage {
        id: logo
        source: "assets/pixLAnime.gif"
        width: Math.min(parent.width, parent.height)
        speed: 1.6
        anchors.horizontalCenterOffset: 0
        anchors.topMargin: 100
        fillMode: Image.PreserveAspectFit
        verticalAlignment: Image.AlignBottom
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        anchors.bottom: parent.verticalCenter
    }

    Rectangle {
        id: slideshow
        width: parent.width
        height: 50
        anchors.bottom: parent.bottom
        anchors.bottomMargin: 20
        color: "black"

        Image {
            id: slideshowImage
            source: images[currentIndex]
            width: parent.width
            height: parent.height
            fillMode: Image.PreserveAspectFit
            anchors.centerIn: parent
            verticalAlignment: Image.AlignBottom
            anchors.horizontalCenter: parent.horizontalCenter

            SequentialAnimation on opacity {
                loops: Animation.Infinite
                NumberAnimation { from: 1.0; to: 0.0; duration: 2000 }
                ScriptAction { script: {
                    currentIndex = (currentIndex + 1) % images.length;
                    slideshowImage.source = images[currentIndex];
                }}
                NumberAnimation { from: 0.0; to: 1.0; duration: 2000 }
                PauseAnimation { duration: 2000 }
            }
        }
    }

    Rectangle {
        id: progressRoot
        property int padding: vpx(5)
        width: logo.width * 0.95
        height: vpx(30)
        radius: vpx(10)
        color: themeColor.main

        anchors.top: logo.bottom
        anchors.topMargin: height * 1.0
        anchors.horizontalCenter: parent.horizontalCenter

        border.width: vpx(2)

        Rectangle {
            id: progressBar
            width: parent.width * root.progress
            height: parent.height
            radius: vpx(10)
            color: themeColor.screenUnderline

            NumberAnimation on width {
                id: anim
                from: 0
                to: parent.width * (root.progress / 100)
                easing.type: Easing.InOutBounce
                running: true
            }
            SequentialAnimation on color {
                loops: Animation.Infinite
                ColorAnimation { from: Qt.darker(themeColor.screenUnderline); to: themeColor.screenUnderline; duration: 1000 }
                ColorAnimation { from: themeColor.screenUnderline; to: Qt.darker(themeColor.screenUnderline); duration: 1000 }
            }
        }

        Rectangle {
            id: lightningEffect
            width: parent.width
            height: parent.height
            radius: vpx(10)
            gradient: Gradient {
                GradientStop { position: 0.0; color: "transparent" }
                GradientStop { position: 0.5; color: "white" }
                GradientStop { position: 1.0; color: "transparent" }
            }

            PropertyAnimation on x {
                from: -parent.width
                to: parent.width
                duration: 1000
                loops: Animation.Infinite
                easing.type: Easing.Linear
            }

            PropertyAnimation on opacity {
                from: 0.8
                to: 0.0
                duration: 1000
                loops: Animation.Infinite
                easing.type: Easing.Linear
            }
        }
    }

    Text {
        id: gameCounter
        visible: showDataProgressText

        text: api.internal.meta.loadingStage
        color: "#999"
        font.pixelSize: vpx(16)
        font.family: global.fonts.sans
        font.italic: true

        anchors.top: progressRoot.bottom
        anchors.topMargin: vpx(8)
        anchors.right: progressRoot.right
        anchors.rightMargin: vpx(5)
    }
}
