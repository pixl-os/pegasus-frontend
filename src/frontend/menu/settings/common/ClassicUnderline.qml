// Pegasus Frontend
//BozoTheGeek 24/11/2026

import QtQuick 2.12


Item {
    id: underlineRoot

    property bool active: false
    property color baseColor: themeColor.underline
    property int lineHeight: vpx(3)
    property int animDuration: 140

    opacity: active ? 1.0 : 0.0
    visible: opacity > 0

    Behavior on opacity {
        NumberAnimation { duration: underlineRoot.animDuration }
    }

    Rectangle {
        id: underlineBar
        width: parent.width
        height: underlineRoot.lineHeight
        anchors.bottom: parent.bottom
        color: underlineRoot.baseColor
    }
}
