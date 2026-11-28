// Pegasus Frontend
// BozoTheGeek 24/11/2026

import QtQuick 2.12


Item {
    id: glossyRoot

    property bool active: false
    property color baseColor: themeColor.underline
    property int cornerRadius: vpx(8)
    property int glowSpread: vpx(4)
    property int animDuration: 140

    readonly property color lightColor: Qt.lighter(baseColor, 1.35)
    readonly property color brightColor: Qt.lighter(baseColor, 1.65)
    readonly property color darkColor: Qt.darker(baseColor, 2.2)

    opacity: active ? 1.0 : 0.0
    visible: opacity > 0

    Behavior on opacity {
        NumberAnimation { duration: glossyRoot.animDuration }
    }

    // Outer soft glow seamlessly touching the card
    Rectangle {
        id: outerGlow
        anchors.fill: card
        anchors.margins: -glossyRoot.glowSpread
        radius: card.radius + glossyRoot.glowSpread
        color: Qt.rgba(glossyRoot.baseColor.r, glossyRoot.baseColor.g, glossyRoot.baseColor.b, 0.22)
    }

    // Main glossy focus card
    Rectangle {
        id: card
        anchors.fill: parent
        radius: glossyRoot.cornerRadius

        color: Qt.rgba(glossyRoot.baseColor.r, glossyRoot.baseColor.g, glossyRoot.baseColor.b, 0.25)
        border.width: vpx(1)
        border.color: Qt.rgba(glossyRoot.lightColor.r, glossyRoot.lightColor.g, glossyRoot.lightColor.b, 0.90)

        // Top-to-bottom glossy sheen gradient
        Rectangle {
            anchors.fill: parent
            anchors.margins: vpx(1)
            radius: Math.max(0, card.radius - vpx(1))
            gradient: Gradient {
                GradientStop { position: 0.0; color: Qt.rgba(glossyRoot.lightColor.r, glossyRoot.lightColor.g, glossyRoot.lightColor.b, 0.38) }
                GradientStop { position: 0.35; color: Qt.rgba(1.0, 1.0, 1.0, 0.14) }
                GradientStop { position: 0.55; color: Qt.rgba(glossyRoot.darkColor.r, glossyRoot.darkColor.g, glossyRoot.darkColor.b, 0.18) }
                GradientStop { position: 1.0; color: Qt.rgba(0.05, 0.10, 0.08, 0.45) }
            }
        }

        // Uniform inner highlight frame following the rounded corners
        Rectangle {
            anchors.fill: parent
            anchors.margins: vpx(1)
            radius: Math.max(0, card.radius - vpx(1))
            color: "transparent"
            border.width: vpx(1)
            border.color: Qt.rgba(glossyRoot.brightColor.r, glossyRoot.brightColor.g, glossyRoot.brightColor.b, 0.35)
        }
    }
}
