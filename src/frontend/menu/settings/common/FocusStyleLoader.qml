// Pegasus Frontend
// BozoTheGeek 24/11/2026

import QtQuick 2.12

Item {
    id: loaderRoot

    property string styleType: "glossy" // "glossy", "underline", etc.
    property bool active: false
    property color baseColor: themeColor.underline

    Loader {
        id: styleLoader
        anchors.fill: parent

        source: {
            switch (loaderRoot.styleType) {
                case "underline":
                    return "ClassicUnderline.qml"
                case "glossy":
                default:
                    return "GlossyFocusCard.qml"
            }
        }

        onLoaded: {
            if (item) {
                item.active = Qt.binding(function() { return loaderRoot.active })
                item.baseColor = Qt.binding(function() { return loaderRoot.baseColor })
            }
        }
    }
}
