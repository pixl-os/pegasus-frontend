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

    color: "#101010"
    anchors.fill: parent

    property real progress: api.internal.meta.loadingProgress
    property bool showDataProgressText: true

    Behavior on progress { NumberAnimation { duration: 500; easing.type: Easing.OutQuad } }

    // Logo animé principal
    AnimatedImage {
        id: logo
        source: "assets/pixLAnime.gif"
        width: parent.width * 0.4
        height: parent.width * 0.4
        fillMode: Image.PreserveAspectFit
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        anchors.topMargin: vpx(40)
        opacity: 1.0

        SequentialAnimation on opacity {
            loops: Animation.Infinite
            NumberAnimation { from: 0.8; to: 1.0; duration: 1500; easing.type: Easing.InOutQuad }
        }
    }

    // Barre de progression
    Rectangle {
        id: progressRoot
        width: logo.width * 0.95
        height: vpx(30)
        radius: vpx(15)
        color: "#333"
        border.color: "#555"
        border.width: vpx(2)

        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: logo.bottom
        anchors.topMargin: vpx(20)

        // Barre intérieure animée
        Rectangle {
            id: progressBar
            width: parent.width * root.progress
            height: parent.height
            radius: vpx(15)
            color: themeColor.screenUnderline

            NumberAnimation on width {
                duration: 800
                easing.type: Easing.InOutQuad
            }

            SequentialAnimation on color {
                loops: Animation.Infinite
                ColorAnimation {
                    from: Qt.lighter(themeColor.screenUnderline, 1.5)
                    to: Qt.darker(themeColor.screenUnderline, 1.5)
                    duration: 1000
                }
                ColorAnimation {
                    from: Qt.darker(themeColor.screenUnderline, 1.5)
                    to: Qt.lighter(themeColor.screenUnderline, 1.5)
                    duration: 1000
                }
            }
        }
    }

    // Texte de progression
    Text {
        id: gameCounter
        visible: showDataProgressText

        text: api.internal.meta.loadingStage
        color: "#CCCCCC"
        font.pixelSize: vpx(16)
        font.family: global.fonts.sans
        anchors.top: progressRoot.bottom
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.topMargin: vpx(8)
    }

    // Diaporama
    Rectangle {
        id: slideshow
        width: parent.width
        height: vpx(50)
        color: "black"
        opacity: 0.7
        anchors.bottom: parent.bottom
        anchors.bottomMargin: vpx(10)

        Image {
            id: slideshowImage
            source: images[currentIndex]
            width: parent.width * 0.8
            height: parent.height
            fillMode: Image.PreserveAspectFit
            anchors.centerIn: parent

            SequentialAnimation on opacity {
                loops: Animation.Infinite
                NumberAnimation { from: 1.0; to: 0.0; duration: 1500 }
                ScriptAction { script: {
                        currentIndex = (currentIndex + 1) % images.length;
                        slideshowImage.source = images[currentIndex];
                    }}
                NumberAnimation { from: 0.0; to: 1.0; duration: 1500 }
            }
        }
    }

    // Helper pour le diaporama
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
}
