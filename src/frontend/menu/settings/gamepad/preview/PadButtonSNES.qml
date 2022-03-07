// Pegasus Frontend
// Copyright (C) 2017  Mátyás Mustoha
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
    property string shortName
    property bool pressed: false

    //property alias sourceWidth: pieceImage.sourceSize.width
    //property alias sourceHeight: pieceImage.sourceSize.height

    /*Image {
        id: initialImage
        z: 50
        width: parent.width
        height: parent.height

        //fillMode: Image.PreserveAspectFit

        anchors.fill: parent.fill

        source: "qrc:/frontend/assets/gamepad/" + shortName + "_snes.png"
        visible: false
    }*/
    Image {
        id: pressedImage
        z: 50
        width: parent.width * 0.95
        height: parent.height * 0.95

        //fillMode: Image.PreserveAspectFit

        //anchors.fill: parent.fill

        anchors.verticalCenter: parent.verticalCenter
        anchors.horizontalCenter: parent.horizontalCenter



        source: "qrc:/frontend/assets/gamepad/" + shortName + "_snes.png"
        /*sourceSize {
            width: 71
            height: 71
        }*/
        visible: pressed
    }

    BrightnessContrast {
        z:100
        visible: pressed
        //enabled: pressed
        anchors.fill: pressedImage
        source: pressedImage
        brightness: 0.5
        contrast: 0.5
    }





    Rectangle {
        id: highlight
        color: {
				if (pressed) return "blue";
				else if (root.recordingField !== null ) return "#c33";
				else return themeColor.underline;
		}
        anchors.fill: parent
        radius: width * 0.5

        // FIXME: this is not really nice, but makes the code shorter
        visible: false//pressed || padContainer.currentButton === shortName
    }
}
