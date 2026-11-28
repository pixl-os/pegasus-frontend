import QtQuick 2.12


FocusScope {
    id: root

    property alias label: label.text
    property alias labelFormat: label.textFormat
    property alias note: sublabel.text
    property alias noteFormat: sublabel.textFormat

    property alias textfield: textfield
    property int wrapMode: Text.WordWrap

    property bool launchedAsDialogBox: false

    readonly property int fontSize: vpx(22)
    readonly property int horizontalPadding: launchedAsDialogBox ? vpx(0) : vpx(30)

    signal activate()


    width: parent.width
    //    height: fontSize * 2.5
    height: labelContainer.height + fontSize * 1.25

    Keys.onPressed: {
        if (api.keys.isAccept(event) && !event.isAutoRepeat) {
            event.accepted = true;
            root.activate();
        }
    }

    //******************************** section to manage design in menu selection*******************************************
    readonly property bool isHighlighted: root.activeFocus || mouseArea.containsMouse // [CHANGED - keyboard focus]
    FocusStyleLoader {
        id: focusBackground
        anchors.fill: parent
        styleType: focusThemeStyle
        active: root.isHighlighted
        baseColor: themeColor.underline
    }
    //*********************************************************************************************************************

    Column {
        id: labelContainer

        anchors {
            left: parent.left; leftMargin: horizontalPadding
            right: parent.horizontalCenter
            verticalCenter: parent.verticalCenter
        }

        spacing: fontSize * 0.25
        height: label.height + (sublabel.text ? spacing + sublabel.height : 0)


        Text {
            id: label
            maximumLineCount: (root.wrapMode === Text.NoWrap) ? 1 : 2
            color: themeColor.textLabel
            font.pixelSize: fontSize
            font.family: globalFonts.sans
            width: focusBackground.width
            wrapMode: root.wrapMode
        }

        Text {
            id: sublabel

            color: themeColor.textSublabel
            font.pixelSize: fontSize * 0.8
            font.family: globalFonts.sans
            font.italic: true
            width: focusBackground.width
            wrapMode: Text.WordWrap
        }
    }

    MouseArea {
        id: mouseArea
        anchors.fill: parent
        hoverEnabled: true
        onClicked: activate()
        cursorShape: Qt.PointingHandCursor
    }

    TextField {
        id: textfield
        focus: true
        color: themeColor.textLabel
        selectionColor: Qt.rgba(0.0, 0.0, 0.0, 0.15)
        selectedTextColor: color
        selectByMouse: false
        font.pixelSize: vpx(22)
        font.family: globalFonts.sans
        readOnly: true
        anchors.verticalCenter: parent.verticalCenter
        anchors.right: parent.right
        anchors.rightMargin: horizontalPadding

        visible: true

        //custom parameter to inverse color
        property color activeFocusColor : themeColor.secondary
        property color inactiveColor: themeColor.main
        property color activeBorderColor: themeColor.screenHeader

        background: Rectangle {
            radius: vpx(5)
            color: textfield.activeFocus ? textfield.activeFocusColor : textfield.inactiveColor
            border.color: textfield.activeFocus ? textfield.activeBorderColor : textfield.inactiveColor
        }

        Keys.onReleased:{
            if(visible) event.accepted = virtualKeyboardOnReleased(event);
        }
        property bool active : false //set to false by default
        Keys.onPressed: {
            // console.log("-----Before update-----");
            // console.log("event.accepted : ", event.accepted);
            // console.log("event.key : ", event.key);
            // console.log("textfield.focus : ", textfield.focus);
            // console.log("textfield.readOnly : ", textfield.readOnly);
            // console.log("active : ",active);
            if(visible) event.accepted, textfield.focus, textfield.active = virtualKeyboardOnPressed(event,textfield,textfield.active);
            // console.log("-----After update-----");
            // console.log("event.accepted : ", event.accepted);
            // console.log("event.key : ", event.key);
            // console.log("textfield.focus : ", textfield.focus);
            // console.log("textfield.readOnly : ", textfield.readOnly);
            // console.log("textfield.active : ",textfield.active);
        }
    }
}
