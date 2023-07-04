// Pegasus Frontend
//
// Created by BozoTheGeek 10/05/2021
//

import "../common"
import "qrc:/qmlutils" as PegasusUtils
import QtQuick 2.12
import QtQuick.Controls 2.12
import QtQuick.Window 2.12

FocusScope {
    id: root

    signal close

    width: parent.width
    height: parent.height
    
    anchors.fill: parent
    visible: 0 < (x + width) && x < Window.window.width

    enabled: focus

    Keys.onPressed: {
        if (api.keys.isCancel(event) && !event.isAutoRepeat) {
            event.accepted = true;
            root.close();
        }
    }
    PegasusUtils.HorizontalSwipeArea {
        anchors.fill: parent
        onSwipeRight: root.close()
    }
    MouseArea {
        anchors.fill: parent
        acceptedButtons: Qt.RightButton
        onClicked: root.close()
    }
    ScreenHeader {
        id: header
        text: qsTr("Advanced emulators settings > ppsspp") + api.tr
        z: 2
    }
    Flickable {
        id: container

        width: content.width
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: header.bottom
        anchors.bottom: parent.bottom

        contentWidth: content.width
        contentHeight: content.height

        Behavior on contentY { PropertyAnimation { duration: 100 } }
        boundsBehavior: Flickable.StopAtBounds
        boundsMovement: Flickable.StopAtBounds

        readonly property int yBreakpoint: height * 0.7
        readonly property int maxContentY: contentHeight - height

        function onFocus(item) {
            if (item.focus)
                contentY = Math.min(Math.max(0, item.y - yBreakpoint), maxContentY);
        }
        FocusScope {
            id: content

            focus: true
            enabled: focus

            width: contentColumn.width
            height: contentColumn.height

            Column {
                id: contentColumn
                spacing: vpx(5)

                width: root.width * 0.7
                height: implicitHeight

                Item {
                    width: parent.width
                    height: implicitHeight + vpx(30)
                }

                SectionTitle {
                    text: qsTr("Game screen") + api.tr
                    first: true
                    symbol: "\uf17f"
                }
//                multiSampleLevel = conf.getInt("ppsspp.msaa", 0)
//                shaderChainRequires60FPS = conf.getInt("ppsspp.force.60fps", 0)
//                texScalingLevel = conf.getInt("ppsspp.texture.scaling.level", 0)
//                texScalingType = conf.getInt("ppsspp.texture.scaling.type", 0)
//                anisotropyLevel = conf.getInt("ppsspp.anisotropy.level", 0)
//                textureFiltering = conf.getInt("ppsspp.texture.filter", 0)
                MultivalueOption {
                    id: optInternalResolution
                    // set focus only on first item
                    focus: true

                    //property to manage parameter name
                    property string parameterName : "ppsspp.resolution"

                    label: qsTr("Internal Resolution") + api.tr
                    note: qsTr("Controls the rendering resolution. \nA high resolution greatly improves visual quality,But cause issues in certain games") + api.tr

                    value: api.internal.recalbox.parameterslist.currentName(parameterName)
                    onActivate: {
                        //for callback by parameterslistBox
                        parameterslistBox.parameterName = parameterName;
                        parameterslistBox.callerid = optInternalResolution;
                        //to force update of list of parameters
                        api.internal.recalbox.parameterslist.currentName(parameterName);
                        parameterslistBox.model = api.internal.recalbox.parameterslist;
                        parameterslistBox.index = api.internal.recalbox.parameterslist.currentIndex;
                        //to transfer focus to parameterslistBox
                        parameterslistBox.focus = true;
                    }
                    onFocusChanged: container.onFocus(this)
                    KeyNavigation.down: optForce60fps
                }
                ToggleOption {
                    id: optForce60fps

                    label: qsTr("Force 60Hz") + api.tr
                    note: qsTr("Render duplicate frames to 60Hz.") + api.tr

                    checked: api.internal.recalbox.getBoolParameter("ppsspp.force.60fps")
                    onCheckedChanged: {
                        api.internal.recalbox.setBoolParameter("ppsspp.force.60fps",checked);
                    }
                    onFocusChanged: container.onFocus(this)
                    KeyNavigation.down: optMsaa
                }
                MultivalueOption {
                    id: optMsaa
                    //property to manage parameter name
                    property string parameterName : "ppsspp.msaa"

                    label: qsTr("Antialiasing") + api.tr
                    note: qsTr("Antialiasing msaa level") + api.tr

                    value: api.internal.recalbox.parameterslist.currentName(parameterName)
                    onActivate: {
                        //for callback by parameterslistBox
                        parameterslistBox.parameterName = parameterName;
                        parameterslistBox.callerid = optMsaa;
                        //to force update of list of parameters
                        api.internal.recalbox.parameterslist.currentName(parameterName);
                        parameterslistBox.model = api.internal.recalbox.parameterslist;
                        parameterslistBox.index = api.internal.recalbox.parameterslist.currentIndex;
                        //to transfer focus to parameterslistBox
                        parameterslistBox.focus = true;
                    }
                    onFocusChanged: container.onFocus(this)
                    KeyNavigation.down: optTextureScalingLevel
                }
                MultivalueOption {
                    id: optTextureScalingLevel

                    //property to manage parameter name
                    property string parameterName : "ppsspp.texture.scaling.level"

                    label: qsTr("texture scaling level") + api.tr
                    note: qsTr("Set level of texture shaders.") + api.tr

                    value: api.internal.recalbox.parameterslist.currentName(parameterName)
                    onActivate: {
                        //for callback by parameterslistBox
                        parameterslistBox.parameterName = parameterName;
                        parameterslistBox.callerid = optTextureScalingLevel;
                        //to force update of list of parameters
                        api.internal.recalbox.parameterslist.currentName(parameterName);
                        parameterslistBox.model = api.internal.recalbox.parameterslist;
                        parameterslistBox.index = api.internal.recalbox.parameterslist.currentIndex;
                        //to transfer focus to parameterslistBox
                        parameterslistBox.focus = true;
                    }
                    onFocusChanged: container.onFocus(this)
                    KeyNavigation.down: optTextureScalingType
                }
                MultivalueOption {
                    id: optTextureScalingType

                    //property to manage parameter name
                    property string parameterName : "ppsspp.texture.scaling.type"

                    label: qsTr("texture scaling type") + api.tr
                    note: qsTr("Set type of texture shaders.") + api.tr

                    value: api.internal.recalbox.parameterslist.currentName(parameterName)
                    onActivate: {
                        //for callback by parameterslistBox
                        parameterslistBox.parameterName = parameterName;
                        parameterslistBox.callerid = optTextureScalingType;
                        //to force update of list of parameters
                        api.internal.recalbox.parameterslist.currentName(parameterName);
                        parameterslistBox.model = api.internal.recalbox.parameterslist;
                        parameterslistBox.index = api.internal.recalbox.parameterslist.currentIndex;
                        //to transfer focus to parameterslistBox
                        parameterslistBox.focus = true;
                    }
                    onFocusChanged: container.onFocus(this)
                    KeyNavigation.down: optTextureShader
//                    visible: optTextureScalingLevel.value[0] ? false : true
                }
                MultivalueOption {
                    id: optTextureShader

                    //property to manage parameter name
                    property string parameterName : "ppsspp.texture.shader"

                    label: qsTr("texture shaders type") + api.tr
                    note: qsTr("Set type of texture shaders.") + api.tr

                    value: api.internal.recalbox.parameterslist.currentName(parameterName)
                    onActivate: {
                        //for callback by parameterslistBox
                        parameterslistBox.parameterName = parameterName;
                        parameterslistBox.callerid = optTextureShader;
                        //to force update of list of parameters
                        api.internal.recalbox.parameterslist.currentName(parameterName);
                        parameterslistBox.model = api.internal.recalbox.parameterslist;
                        parameterslistBox.index = api.internal.recalbox.parameterslist.currentIndex;
                        //to transfer focus to parameterslistBox
                        parameterslistBox.focus = true;
                    }
                    onFocusChanged: container.onFocus(this)
                    KeyNavigation.down: optAnisotropyLevel
//                    visible: optTextureScalingLevel.value[0] ? false : true
                }
                MultivalueOption {
                    id: optAnisotropyLevel

                    //property to manage parameter name
                    property string parameterName : "ppsspp.anisotropy.level"

                    label: qsTr("Anisotropy level") + api.tr
                    note: qsTr("Set anisotropy level.") + api.tr

                    value: api.internal.recalbox.parameterslist.currentName(parameterName)
                    onActivate: {
                        //for callback by parameterslistBox
                        parameterslistBox.parameterName = parameterName;
                        parameterslistBox.callerid = optAnisotropyLevel;
                        //to force update of list of parameters
                        api.internal.recalbox.parameterslist.currentName(parameterName);
                        parameterslistBox.model = api.internal.recalbox.parameterslist;
                        parameterslistBox.index = api.internal.recalbox.parameterslist.currentIndex;
                        //to transfer focus to parameterslistBox
                        parameterslistBox.focus = true;
                    }
                    onFocusChanged: container.onFocus(this)
                    KeyNavigation.down: optTextureFilter
                }
                MultivalueOption {
                    id: optTextureFilter

                    //property to manage parameter name
                    property string parameterName : "ppsspp.texture.filter"

                    label: qsTr("Texture filter") + api.tr
                    note: qsTr("Set type of texture filter.") + api.tr

                    value: api.internal.recalbox.parameterslist.currentName(parameterName)
                    onActivate: {
                        //for callback by parameterslistBox
                        parameterslistBox.parameterName = parameterName;
                        parameterslistBox.callerid = optTextureFilter;
                        //to force update of list of parameters
                        api.internal.recalbox.parameterslist.currentName(parameterName);
                        parameterslistBox.model = api.internal.recalbox.parameterslist;
                        parameterslistBox.index = api.internal.recalbox.parameterslist.currentIndex;
                        //to transfer focus to parameterslistBox
                        parameterslistBox.focus = true;
                    }
                    onFocusChanged: container.onFocus(this)
//                    KeyNavigation.down: optAnisotropyLevel
                }
                Item {
                    width: parent.width
                    height: implicitHeight + vpx(30)
                }
            }
        }
    }
    MultivalueBox {
        id: parameterslistBox
        z: 3

        //properties to manage parameter
        property string parameterName
        property MultivalueOption callerid

        //reuse same model
        model: api.internal.recalbox.parameterslist.model
        //to use index from parameterlist QAbstractList
        index: api.internal.recalbox.parameterslist.currentIndex

        onClose: content.focus = true
        onSelect: {
            //to update index of parameterlist QAbstractList
            api.internal.recalbox.parameterslist.currentIndex = index;
            //to force update of display of selected value
            callerid.value = api.internal.recalbox.parameterslist.currentName(parameterName);
        }
    }
}
