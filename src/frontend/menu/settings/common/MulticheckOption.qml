// Pegasus Frontend
// Created by BozoTheGeek 14/08/2024

import QtQuick 2.12


FocusScope {
    id: root

    property alias label: labeltext.text
    property alias note: sublabel.text
    property alias value: valueText.text

    //property alias rightPointer : rightPointer
    //property alias leftPointer : leftPointer

    property var internalvalue

    property bool keypressed: false
    property bool firsttime: true

    property int currentIndex : -1
    property int count : 0

    property alias font: valueText.font.family
    property int fontSize: vpx(22)
    property int horizontalPadding: vpx(30)

    signal activate()
    signal check(int index, bool checked)

    width: parent.width
    height: labelContainer.height + fontSize * 1.25

    Component.onCompleted: {
        //if(firsttime) console.log(labeltext.text," onCurrentIndexChanged (first time)");
        //else console.log(labeltext.text," onCurrentIndexChanged (key pressed)");
        /*if(currentIndex < (count - 1)){
          rightPointer.visible = true;
        } else rightPointer.visible = false;
        if(currentIndex >=1){
          leftPointer.visible = true
        } else leftPointer.visible = false;*/
    }

    onCurrentIndexChanged: {
        if(keypressed || firsttime){
            /*if(firsttime) console.log(labeltext.text," onCurrentIndexChanged (first time)");
            else console.log(labeltext.text," onCurrentIndexChanged (key pressed)");
            console.log(labeltext.text," onCurrentIndexChanged count : ", count);
            console.log(labeltext.text," onCurrentIndexChanged currentindex : ", currentIndex);
            console.log(labeltext.text," onCurrentIndexChanged value : ", value);
            console.log(labeltext.text," onCurrentIndexChanged internalvalue : ", internalvalue);*/
            /*if(currentIndex < (count - 1)){
              rightPointer.visible = true;
            } else rightPointer.visible = false;
            if(currentIndex >=1){
              leftPointer.visible = true
            } else leftPointer.visible = false;*/
            keypressed = false;
            firsttime = false;
        }
    }

    Keys.onPressed: {
        //console.log("MultivalueOption onPressed of ", labeltext.text)
        if (api.keys.isAccept(event) && !event.isAutoRepeat) {
            event.accepted = true;
            root.activate();
        }
        /*else if (api.keys.isLeft(event) && !event.isAutoRepeat) {
            event.accepted = true;
            //console.log("MultivalueOption onPressed isLeft index (before) : ", currentIndex)
            //console.log("MultivalueOption onPressed isRight index (before) : ", count)
            //to update index of parameterlist QAbstractList
            if(currentIndex >=1){
                keypressed = true;
                //to update index of parameterlist QAbstractList
                currentIndex = currentIndex - 1;
                //to force update of display of selected value
                //root.select(currentIndex);
                //console.log("MultivalueOption onPressed isLeft index (after) : ", currentIndex)
            }
        }
        else if (api.keys.isRight(event) && !event.isAutoRepeat) {
            event.accepted = true;
            //console.log("MultivalueOption onPressed isRight index (before) : ", currentIndex)
            //console.log("MultivalueOption onPressed isRight count (before) : ", count)
            if(currentIndex < (count - 1)){
                keypressed = true;
                //to update index of parameterlist QAbstractList
                currentIndex = currentIndex + 1;
                //to force update of display of selected value
                //root.select(currentIndex);
                //console.log("MultivalueOption onPressed isRight index (after) : ", currentIndex)
            }
        }*/
    }

    Rectangle {
        id: underline

        width: parent.width
        height: vpx(3)
        anchors.bottom: parent.bottom

        color: themeColor.underline
        visible: parent.focus || mouseArea.containsMouse
    }

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
            id: labeltext

            color:themeColor.textLabel
            font.pixelSize: fontSize
            font.family: globalFonts.sans
        }

        Text {
            id: sublabel

            color: themeColor.textSublabel
            font.pixelSize: fontSize * 0.8
            font.family: globalFonts.sans
            font.italic: true
        }
    }

    /*Text {
        id: leftPointer
        visible: false
        anchors {
            rightMargin: vpx(10)
            right: valueText.left
            verticalCenter: valueText.verticalCenter
        }
        color: themeColor.underline
        font.pixelSize: vpx(25)
        font.family: globalFonts.ion
        text : "\uf3cf"
    }*/

    Text {
        id: valueText

        anchors.right: parent.right
        anchors.rightMargin: vpx(10)
        anchors.top: parent.top
        anchors.topMargin: vpx(14)
        color: themeColor.textValue
        font.pixelSize: fontSize
        font.family: globalFonts.sans
        property bool firsttime: true
    }

    /*Text {
        id: rightPointer
        visible: false
        anchors {
            rightMargin: horizontalPadding
            right: parent.right
            verticalCenter: valueText.verticalCenter
        }
        color: themeColor.underline
        font.pixelSize: vpx(25)
        font.family: globalFonts.ion
        text : "\uf3d1"
    }*/

    MouseArea {
        id: mouseArea
        anchors.fill: parent
        hoverEnabled: true
        onClicked: activate()
        cursorShape: Qt.PointingHandCursor
    }
}
