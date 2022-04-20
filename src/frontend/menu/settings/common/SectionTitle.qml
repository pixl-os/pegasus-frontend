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


import QtQuick 2.12



Text {
    property bool first: false
    property alias symbol: symbolTitle.text
    property alias symbolFontFamily: symbolTitle.font.family
    property int fontSize: vpx(22)

    color: themeColor.textSectionTitle
    font {
        pixelSize: fontSize
        family: globalFonts.sans
//        capitalization: Font.AllUppercase
        italic: true
    }
    topPadding: font.pixelSize * (first ? 0.25 : 2.25)

    Text {
        id: symbolTitle
        anchors {
            verticalCenter: parent.verticalCenter
            left: parent.left
            leftMargin: - fontSize * 2
        }
        color: themeColor.textTitle
        font {
            bold: false
            pixelSize: fontSize * 1.25
            family: global.fonts.ion
        }
    }
}
