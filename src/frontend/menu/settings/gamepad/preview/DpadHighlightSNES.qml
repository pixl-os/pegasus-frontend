// Pegasus Frontend
//
//Created by Bozo The Geek 12/03/2022
//

import QtQuick 2.12
import QtGraphicalEffects 1.12

Rectangle {
    property bool highlighted: false
    property bool pressed: false

    width: parent.width * 0.3
    height: width
    anchors.margins: 4

    color: {
        if (pressed) return "white";
		else if (root.recordingField !== null) return "#c33";
		else return themeColor.underline;
    }
    opacity:0.3

    radius: width * 0.2
    visible: highlighted || pressed
}
