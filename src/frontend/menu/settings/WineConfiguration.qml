// Pegasus Frontend
//
// Created by BozoTheGeek 26/05/2025
//

import "common"
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

    property string emulator;

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
        text: emulator + " > " + qsTr("Wine configuration") + api.tr
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

        //to manage update from visibility
        clip: true

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

                // Inside your delegate or item that needs to check visibility
                function checkVisibility(item) {
                    // Map the item's local coordinates to the Flickable's content coordinates
                    // This gives you the item's rectangle relative to the Flickable's content.
                    var itemXInContent = mapToItem(container.contentItem, 0, 0).x;
                    var itemYInContent = mapToItem(container.contentItem, 0, 0).y;

                    // Define the item's rectangle in the Flickable's content coordinate system
                    var itemRectInContent = Qt.rect(itemXInContent, itemYInContent, item.width, item.height);

                    // Define the Flickable's visible rectangle (its viewport)
                    // This is relative to contentX and contentY, so it's (0,0, width, height) of the visible area
                    // Adjust flickableRect to be in the content's coordinate system, shifted by contentX/contentY
                    var flickableVisibleRect = Qt.rect(container.contentX, container.contentY, container.width, container.height);

                    // Now, perform the intersection check manually or using helper functions if available.
                    // The `intersects` property/method on QRectF is for C++ API.
                    // For pure QML `Qt.rect`, you usually define an intersection logic like this:

                    var intersects =
                        itemRectInContent.x < flickableVisibleRect.x + flickableVisibleRect.width &&
                        itemRectInContent.x + itemRectInContent.width > flickableVisibleRect.x &&
                        itemRectInContent.y < flickableVisibleRect.y + flickableVisibleRect.height &&
                        itemRectInContent.y + itemRectInContent.height > flickableVisibleRect.y;

                    var visibleInFlickable = intersects;
                    if((item.visibleInFlickable !== visibleInFlickable) &&  (visibleInFlickable === true)){
                        item.value = api.internal.recalbox.parameterslist.currentName(item.parameterName);
                        item.internalvalue = api.internal.recalbox.parameterslist.currentInternalName(item.parameterName);
                        item.currentIndex = api.internal.recalbox.parameterslist.currentIndex;
                        item.count = api.internal.recalbox.parameterslist.count;
                    }
                    item.visibleInFlickable = visibleInFlickable;
                }
                //put from here options
                //****************************** section to manage wine version of this emulator*****************************************
                SectionTitle {
                    text: qsTr("Wine 'Bottle' configuration") + api.tr
                    first: true
                    symbol: "\uf26f"
                    symbolFontFamily: globalFonts.ion
                }
                MultivalueOption {
                    id: optWineEngine

                    //property to manage parameter name
                    property string parameterName : emulator + ".wine"

                    // set focus only on first item
                    focus: true

                    label: qsTr("Wine 'engine'") + api.tr
                    note: qsTr("Select the one to use, keep 'AUTO' if you don't know") + api.tr

                    value: api.internal.recalbox.parameterslist.currentName(parameterName)
                    internalvalue: api.internal.recalbox.parameterslist.currentInternalName(parameterName)
                    currentIndex: api.internal.recalbox.parameterslist.currentIndex
                    count: api.internal.recalbox.parameterslist.count
                    onActivate: {
                        //for callback by parameterslistBox
                        parameterslistBox.parameterName = parameterName;
                        parameterslistBox.callerid = optWineEngine;
                        //to force update of list of parameters
                        api.internal.recalbox.parameterslist.currentName(parameterName);
                        parameterslistBox.model = api.internal.recalbox.parameterslist;
                        parameterslistBox.index = api.internal.recalbox.parameterslist.currentIndex;
                        //to transfer focus to parameterslistBox
                        parameterslistBox.focus = true;
                    }

                    onSelect: {
                        //to force to be on the good parameter selected
                        api.internal.recalbox.parameterslist.currentName(parameterName);
                        //to update index of parameterlist QAbstractList
                        api.internal.recalbox.parameterslist.currentIndex = index;
                        //to force update of display of selected value
                        value = api.internal.recalbox.parameterslist.currentName(parameterName);
                        internalvalue = api.internal.recalbox.parameterslist.currentInternalName(parameterName);
                    }

                    onFocusChanged:{
                        if(focus){
                            api.internal.recalbox.parameterslist.currentName(parameterName);
                            currentIndex = api.internal.recalbox.parameterslist.currentIndex;
                            count = api.internal.recalbox.parameterslist.count;
                        }
                        container.onFocus(this)
                    }

                    KeyNavigation.down: optWineAppImage
                }
                MultivalueOption {
                    id: optWineAppImage

                    //property to manage parameter name
                    property string parameterName : emulator + ".wineappimage"

                    label: qsTr("Wine AppImage") + api.tr
                    note: qsTr("Select the one to use, keep 'AUTO' if you don't know") + api.tr

                    value: api.internal.recalbox.parameterslist.currentName(parameterName)
                    internalvalue: api.internal.recalbox.parameterslist.currentInternalName(parameterName)
                    currentIndex: api.internal.recalbox.parameterslist.currentIndex
                    count: api.internal.recalbox.parameterslist.count

                    onActivate: {
                        //for callback by parameterslistBox
                        parameterslistBox.parameterName = parameterName;
                        parameterslistBox.callerid = optWineAppImage;
                        //to force update of list of parameters
                        api.internal.recalbox.parameterslist.currentName(parameterName);
                        parameterslistBox.model = api.internal.recalbox.parameterslist;
                        parameterslistBox.index = api.internal.recalbox.parameterslist.currentIndex;
                        //to transfer focus to parameterslistBox
                        parameterslistBox.focus = true;
                    }

                    onSelect: {
                        //to force to be on the good parameter selected
                        api.internal.recalbox.parameterslist.currentName(parameterName);
                        //to update index of parameterlist QAbstractList
                        api.internal.recalbox.parameterslist.currentIndex = index;
                        //to force update of display of selected value
                        value = api.internal.recalbox.parameterslist.currentName(parameterName);
                        internalvalue = api.internal.recalbox.parameterslist.currentInternalName(parameterName);
                    }

                    onFocusChanged:{
                        if(focus){
                            api.internal.recalbox.parameterslist.currentName(parameterName);
                            currentIndex = api.internal.recalbox.parameterslist.currentIndex;
                            count = api.internal.recalbox.parameterslist.count;
                        }
                        container.onFocus(this)
                    }

                    KeyNavigation.down: optWineArch
                }
                MultivalueOption {
                    id: optWineArch

                    //property to manage parameter name
                    property string parameterName : emulator + ".winearch"

                    label: qsTr("Wine architecture") + api.tr
                    note: qsTr("Select the one to use, keep 'AUTO' if you don't know") + api.tr

                    value: api.internal.recalbox.parameterslist.currentName(parameterName)
                    internalvalue: api.internal.recalbox.parameterslist.currentInternalName(parameterName)
                    currentIndex: api.internal.recalbox.parameterslist.currentIndex
                    count: api.internal.recalbox.parameterslist.count

                    onActivate: {
                        //for callback by parameterslistBox
                        parameterslistBox.parameterName = parameterName;
                        parameterslistBox.callerid = optWineArch;
                        //to force update of list of parameters
                        api.internal.recalbox.parameterslist.currentName(parameterName);
                        parameterslistBox.model = api.internal.recalbox.parameterslist;
                        parameterslistBox.index = api.internal.recalbox.parameterslist.currentIndex;
                        //to transfer focus to parameterslistBox
                        parameterslistBox.focus = true;
                    }

                    onSelect: {
                        //to force to be on the good parameter selected
                        api.internal.recalbox.parameterslist.currentName(parameterName);
                        //to update index of parameterlist QAbstractList
                        api.internal.recalbox.parameterslist.currentIndex = index;
                        //to force update of display of selected value
                        value = api.internal.recalbox.parameterslist.currentName(parameterName);
                        internalvalue = api.internal.recalbox.parameterslist.currentInternalName(parameterName);
                    }

                    onFocusChanged:{
                        if(focus){
                            api.internal.recalbox.parameterslist.currentName(parameterName);
                            currentIndex = api.internal.recalbox.parameterslist.currentIndex;
                            count = api.internal.recalbox.parameterslist.count;
                        }
                        container.onFocus(this)
                    }

                    KeyNavigation.down: optWindowsVersion
                }
                MultivalueOption {
                    id: optWindowsVersion

                    //property to manage parameter name
                    property string parameterName : emulator + ".winver"

                    label: qsTr("Windows version") + api.tr
                    note: qsTr("Select the one to use, keep 'AUTO' if you don't know") + api.tr

                    value: api.internal.recalbox.parameterslist.currentName(parameterName)
                    currentIndex: api.internal.recalbox.parameterslist.currentIndex
                    count: api.internal.recalbox.parameterslist.count

                    onActivate: {
                        //for callback by parameterslistBox
                        parameterslistBox.parameterName = parameterName;
                        parameterslistBox.callerid = optWindowsVersion;
                        //to force update of list of parameters
                        api.internal.recalbox.parameterslist.currentName(parameterName);
                        parameterslistBox.model = api.internal.recalbox.parameterslist;
                        parameterslistBox.index = api.internal.recalbox.parameterslist.currentIndex;
                        //to transfer focus to parameterslistBox
                        parameterslistBox.focus = true;
                    }

                    onSelect: {
                        //to force to be on the good parameter selected
                        api.internal.recalbox.parameterslist.currentName(parameterName);
                        //to update index of parameterlist QAbstractList
                        api.internal.recalbox.parameterslist.currentIndex = index;
                        //to force update of display of selected value
                        value = api.internal.recalbox.parameterslist.currentName(parameterName);
                    }

                    onFocusChanged:{
                        if(focus){
                            api.internal.recalbox.parameterslist.currentName(parameterName);
                            currentIndex = api.internal.recalbox.parameterslist.currentIndex;
                            count = api.internal.recalbox.parameterslist.count;
                        }
                        container.onFocus(this)
                    }

                    KeyNavigation.down: optWineDllOverrides
                }
                MulticheckOption {
                    id: optWineDllOverrides

                    //property to manage parameter name
                    property string parameterName : emulator + ".winedlloverrides"

                    label: qsTr("DLL overrides") + api.tr
                    note: qsTr("Select DLL overrides to apply (all selected by default)") + api.tr

                    value: api.internal.recalbox.parameterslist.currentNameChecked(parameterName)

                    currentIndex: api.internal.recalbox.parameterslist.currentIndex;
                    count: api.internal.recalbox.parameterslist.count;

                    onActivate: {
                        //for callback by parameterslistBox
                        parameterscheckBox.parameterName = parameterName;
                        parameterscheckBox.callerid = optWineDllOverrides;
                        parameterscheckBox.isChecked = api.internal.recalbox.parameterslist.isChecked();
                        //to force update of list of parameters
                        api.internal.recalbox.parameterslist.currentNameChecked(parameterName);
                        parameterscheckBox.model = api.internal.recalbox.parameterslist;
                        parameterscheckBox.index = api.internal.recalbox.parameterslist.currentIndex;
                        //to transfer focus to parameterscheckBox
                        parameterscheckBox.focus = true;
                        //to save previous value and know if we need restart or not finally
                        parameterscheckBox.previousValue = api.internal.recalbox.getStringParameter(parameterName)
                    }

                    onFocusChanged:{
                        if(focus){
                            api.internal.recalbox.parameterslist.currentNameChecked(parameterName);
                            currentIndex = api.internal.recalbox.parameterslist.currentIndex;
                            count = api.internal.recalbox.parameterslist.count;
                            parameterscheckBox.isChecked = api.internal.recalbox.parameterslist.isChecked();
                        }
                        container.onFocus(this)
                    }

                    KeyNavigation.down: btnCleanEmulatorBottles
                }
                // to clean/delete "bottle" before re-installation
                SimpleButton {
                    id: btnCleanEmulatorBottles
                    Rectangle {
                        id: containerValidateCleanEmulatorBottles
                        width: parent.width
                        height: parent.height
                        anchors.verticalCenter: parent.verticalCenter
                        anchors.horizontalCenter: parent.horizontalCenter
                        color: parent.focus ? themeColor.underline : themeColor.secondary
                        opacity : parent.focus ? 1 : 0.3
                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            anchors.horizontalCenter: parent.horizontalCenter
                            color: themeColor.textValue
                            font.pixelSize: vpx(30)
                            font.family: globalFonts.ion
                            text : "\uf2ba  " + qsTr("Clean") + " " + emulator + " " + qsTr("Wine bottle(s) (to re-install)") + api.tr
                        }
                    }
                    onActivate: {
                        //to force change of focus
                        confirmDialog.callerid = "btnCleanEmulatorBottles"
                        confirmDialog.focus = false;
                        confirmDialog.setSource("../../dialogs/Generic3ChoicesDialog.qml",
                                                { "title": emulator + " " + qsTr("Wine Bottles") + api.tr,
                                                  "message": qsTr("Are you sure to delete existing bottles ?") + api.tr,
                                                  "symbol": "\uf431",
                                                  "symbolfont" : global.fonts.ion,
                                                  "firstchoice": qsTr("Yes") + api.tr,
                                                  "secondchoice": "",
                                                  "thirdchoice": qsTr("No") + api.tr});
                        //to force change of focus
                        confirmDialog.focus = true;
                    }
                    onFocusChanged: container.onFocus(this)
                    KeyNavigation.down: optWineSoftRenderer
                }

                //****************************** section to manage wine version of this emulator*****************************************
                SectionTitle {
                    text: qsTr("Wine 'Renderer' configuration") + api.tr
                    first: true
                    symbol: "\uf26f"
                    symbolFontFamily: globalFonts.ion
                }
                ToggleOption {
                    id: optWineSoftRenderer
                    label: qsTr("Wine Software renderer") + api.tr
                    note: qsTr("Enable software renderer for wine") + api.tr

                    checked: api.internal.recalbox.getBoolParameter(emulator + ".winesoftrenderer")
                    onCheckedChanged: {
                        api.internal.recalbox.setBoolParameter(emulator + ".winesoftrenderer",checked);
                    }
                    onFocusChanged: container.onFocus(this)
                    KeyNavigation.down: optWineRenderer
                }
                MultivalueOption {
                    id: optWineRenderer

                    //property to manage parameter name
                    property string parameterName : emulator + ".winerenderer"

                    label: qsTr("Wine renderer") + api.tr
                    note: qsTr("Select the one to use, keep 'auto' if you don't know") + "\n" +
                          qsTr("('auto' let emulator to select the best renderer itself)") + api.tr

                    // Logic to update visibleInFlickable based on scroll position
                    // This is less efficient as it's checked for ALL items
                    property bool visibleInFlickable: false // Custom property to track visibility
                    onXChanged: parent.checkVisibility(this)
                    // Initial check
                    Component.onCompleted: parent.checkVisibility(this)

                    onActivate: {
                        //for callback by parameterslistBox
                        parameterslistBox.parameterName = parameterName;
                        parameterslistBox.callerid = optWineRenderer;
                        //to force update of list of parameters
                        api.internal.recalbox.parameterslist.currentName(parameterName);
                        parameterslistBox.model = api.internal.recalbox.parameterslist;
                        parameterslistBox.index = api.internal.recalbox.parameterslist.currentIndex;
                        //to transfer focus to parameterslistBox
                        parameterslistBox.focus = true;
                    }

                    onSelect: {
                        //to force to be on the good parameter selected
                        api.internal.recalbox.parameterslist.currentName(parameterName);
                        //to update index of parameterlist QAbstractList
                        api.internal.recalbox.parameterslist.currentIndex = index;
                        //to force update of display of selected value
                        value = api.internal.recalbox.parameterslist.currentName(parameterName);
                        internalvalue = api.internal.recalbox.parameterslist.currentInternalName(parameterName);
                    }

                    onFocusChanged:{
                        if(focus){
                            api.internal.recalbox.parameterslist.currentName(parameterName);
                            count = api.internal.recalbox.parameterslist.count;
                            currentIndex = api.internal.recalbox.parameterslist.currentIndex;
                        }
                        container.onFocus(this)
                    }

                    KeyNavigation.down: optWineDxvkFramerate
                }
                MultivalueOption {
                    id: optWineDxvkFramerate
                    visible: optWineRenderer.internalvalue !== "gl" ? true : false
                    //property to manage parameter name
                    property string parameterName : emulator + ".winedxvkframerate"

                    label: qsTr("Wine DXVK framerate") + api.tr
                    note: qsTr("DXVK Framerate (FPS Limit especially for vulkan/DXVK (DirectX 9 to 11))") + api.tr

                    // Logic to update visibleInFlickable based on scroll position
                    // This is less efficient as it's checked for ALL items
                    property bool visibleInFlickable: false // Custom property to track visibility
                    onXChanged: parent.checkVisibility(this)
                    // Initial check
                    Component.onCompleted: parent.checkVisibility(this)

                    onActivate: {
                        //for callback by parameterslistBox
                        parameterslistBox.parameterName = parameterName;
                        parameterslistBox.callerid = optWineDxvkFramerate;
                        //to force update of list of parameters
                        api.internal.recalbox.parameterslist.currentName(parameterName);
                        parameterslistBox.model = api.internal.recalbox.parameterslist;
                        parameterslistBox.index = api.internal.recalbox.parameterslist.currentIndex;
                        //to transfer focus to parameterslistBox
                        parameterslistBox.focus = true;
                    }

                    onSelect: {
                        //to force to be on the good parameter selected
                        api.internal.recalbox.parameterslist.currentName(parameterName);
                        //to update index of parameterlist QAbstractList
                        api.internal.recalbox.parameterslist.currentIndex = index;
                        //to force update of display of selected value
                        value = api.internal.recalbox.parameterslist.currentName(parameterName);
                    }

                    onFocusChanged:{
                        if(focus){
                            api.internal.recalbox.parameterslist.currentName(parameterName);
                            currentIndex = api.internal.recalbox.parameterslist.currentIndex;
                            count = api.internal.recalbox.parameterslist.count;
                        }
                        container.onFocus(this)
                    }
                    KeyNavigation.down: optWineDxvkMethod
                }
                MultivalueOption {
                    id: optWineDxvkMethod
                    visible: optWineRenderer.internalvalue !== "gl" ? true : false
                    //property to manage parameter name
                    property string parameterName : emulator + ".winedxvkmethod"

                    label: qsTr("Wine DXVK/VKD8D method") + api.tr
                    note: qsTr("this 'DLLs' installation methodoloy can impact game behaviors") + api.tr

                    // Logic to update visibleInFlickable based on scroll position
                    // This is less efficient as it's checked for ALL items
                    property bool visibleInFlickable: false // Custom property to track visibility
                    onXChanged: parent.checkVisibility(this)
                    // Initial check
                    Component.onCompleted: parent.checkVisibility(this)

                    onActivate: {
                        //for callback by parameterslistBox
                        parameterslistBox.parameterName = parameterName;
                        parameterslistBox.callerid = optWineDxvkMethod;
                        //to force update of list of parameters
                        api.internal.recalbox.parameterslist.currentName(parameterName);
                        parameterslistBox.model = api.internal.recalbox.parameterslist;
                        parameterslistBox.index = api.internal.recalbox.parameterslist.currentIndex;
                        //to transfer focus to parameterslistBox
                        parameterslistBox.focus = true;
                    }

                    onSelect: {
                        //to force to be on the good parameter selected
                        api.internal.recalbox.parameterslist.currentName(parameterName);
                        //to update index of parameterlist QAbstractList
                        api.internal.recalbox.parameterslist.currentIndex = index;
                        //to force update of display of selected value
                        value = api.internal.recalbox.parameterslist.currentName(parameterName);
                    }

                    onFocusChanged:{
                        if(focus){
                            api.internal.recalbox.parameterslist.currentName(parameterName);
                            currentIndex = api.internal.recalbox.parameterslist.currentIndex;
                            count = api.internal.recalbox.parameterslist.count;
                        }
                        container.onFocus(this)
                    }
                    KeyNavigation.down: optWineAudioDriver
                }
                SectionTitle {
                    text: qsTr("Wine 'Software' configuration") + api.tr
                    first: true
                    symbol: "\uf26f"
                    symbolFontFamily: globalFonts.ion
                }
                MultivalueOption {
                    id: optWineAudioDriver

                    //property to manage parameter name
                    property string parameterName : emulator + ".wineaudiodriver"

                    label: qsTr("Wine audio driver") + api.tr
                    note: qsTr("Select the one to use, keep 'AUTO' if you don't know") + api.tr

                    // Logic to update visibleInFlickable based on scroll position
                    // This is less efficient as it's checked for ALL items
                    property bool visibleInFlickable: false // Custom property to track visibility
                    onXChanged: parent.checkVisibility(this)
                    // Initial check
                    Component.onCompleted: parent.checkVisibility(this)

                    onActivate: {
                        //for callback by parameterslistBox
                        parameterslistBox.parameterName = parameterName;
                        parameterslistBox.callerid = optWineAudioDriver;
                        //to force update of list of parameters
                        api.internal.recalbox.parameterslist.currentName(parameterName);
                        parameterslistBox.model = api.internal.recalbox.parameterslist;
                        parameterslistBox.index = api.internal.recalbox.parameterslist.currentIndex;
                        //to transfer focus to parameterslistBox
                        parameterslistBox.focus = true;
                    }

                    onSelect: {
                        //to force to be on the good parameter selected
                        api.internal.recalbox.parameterslist.currentName(parameterName);
                        //to update index of parameterlist QAbstractList
                        api.internal.recalbox.parameterslist.currentIndex = index;
                        //to force update of display of selected value
                        value = api.internal.recalbox.parameterslist.currentName(parameterName);
                    }

                    onFocusChanged:{
                        if(focus){
                            api.internal.recalbox.parameterslist.currentName(parameterName);
                            currentIndex = api.internal.recalbox.parameterslist.currentIndex;
                            count = api.internal.recalbox.parameterslist.count;
                        }
                        container.onFocus(this)
                    }
                    KeyNavigation.down: optWineVirtualDesktop
                }                
                ToggleOption {
                    id: optWineVirtualDesktop
                    label: qsTr("Wine Virtual Desktop") + api.tr
                    note: qsTr("Enable software launching in desktop for wine") + api.tr

                    checked: api.internal.recalbox.getBoolParameter(emulator + ".winevirtualdesktop", false)
                    onCheckedChanged: {
                        api.internal.recalbox.setBoolParameter(emulator + ".winevirtualdesktop",checked);
                    }
                    onFocusChanged: container.onFocus(this)
                    KeyNavigation.down: optWineNVapi
                }
                SectionTitle {
                    text: qsTr("Wine 'Performance' configuration") + api.tr
                    first: true
                    symbol: "\uf26f"
                    symbolFontFamily: globalFonts.ion
                }
                ToggleOption {
                    id: optWineNVapi
                    label: qsTr("Wine NVAPI") + api.tr
                    note: qsTr("Enable NVIDIA api for wine") + api.tr

                    checked: api.internal.recalbox.getBoolParameter(emulator + ".winenvapi", false)
                    onCheckedChanged: {
                        api.internal.recalbox.setBoolParameter(emulator + ".winenvapi",checked);
                    }
                    onFocusChanged: container.onFocus(this)
                    KeyNavigation.down: optWineFullScreenFSR
                }
                ToggleOption {
                    id: optWineFullScreenFSR
                    label: qsTr("Wine Fullscreen FSR") + api.tr
                    note: qsTr("Enables AMD FidelityFX Super Resolution (FSR).\n(globally for fullscreen games)") + api.tr

                    checked: api.internal.recalbox.getBoolParameter(emulator + ".winefullscreenfsr", false)
                    onCheckedChanged: {
                        api.internal.recalbox.setBoolParameter(emulator + ".winefullscreenfsr",checked);
                    }
                    onFocusChanged: container.onFocus(this)
                    KeyNavigation.down: optWineFullScreenIntegerScaling
                }
                ToggleOption {
                    id: optWineFullScreenIntegerScaling
                    label: qsTr("Wine Fullscreen Integer Scaling") + api.tr
                    note: qsTr("Enables integer scaling for fullscreen games.\n(Useful for pixel-perfect scaling on high-DPI displays)") + api.tr

                    checked: api.internal.recalbox.getBoolParameter(emulator + ".winefullscreenintegerscaling", false)
                    onCheckedChanged: {
                        api.internal.recalbox.setBoolParameter(emulator + ".winefullscreenintegerscaling",checked);
                    }
                    onFocusChanged: container.onFocus(this)
                    KeyNavigation.down: optWineDisableFullScreenHack
                }
                ToggleOption {
                    id: optWineDisableFullScreenHack
                    label: qsTr("Wine Disable Fullscreen Hack") + api.tr
                    note: qsTr("Disables Wine's fullscreen hack.\n(which sometimes causes issues with certain games)") + api.tr

                    checked: api.internal.recalbox.getBoolParameter(emulator + ".winedisablefullscreenhack", true)
                    onCheckedChanged: {
                        api.internal.recalbox.setBoolParameter(emulator + ".winedisablefullscreenhack",checked);
                    }
                    onFocusChanged: container.onFocus(this)
                    KeyNavigation.down: optWineESync
                }
                ToggleOption {
                    id: optWineESync
                    label: qsTr("Wine Esync") + api.tr
                    note: qsTr("Enables Esync (Eventfd Synchronization).\n(Can improve performance in multi-threaded games)") + api.tr

                    checked: api.internal.recalbox.getBoolParameter(emulator + ".wineesync", true)
                    onCheckedChanged: {
                        api.internal.recalbox.setBoolParameter(emulator + ".wineesync",checked);
                    }
                    onFocusChanged: container.onFocus(this)
                    KeyNavigation.down: optWineFSync
                }
                ToggleOption {
                    id: optWineFSync
                    label: qsTr("Wine Fsync") + api.tr
                    note: qsTr("Enables Fsync (Futex Synchronization).\n(A newer, more performant alternative to Esync)") + api.tr

                    checked: api.internal.recalbox.getBoolParameter(emulator + ".winefsync", true)
                    onCheckedChanged: {
                        api.internal.recalbox.setBoolParameter(emulator + ".winefsync",checked);
                    }
                    onFocusChanged: container.onFocus(this)
                    KeyNavigation.down: optWineDebug
                }
                SectionTitle {
                    text: qsTr("Wine 'Developer' configuration") + api.tr
                    first: true
                    symbol: "\uf26f"
                    symbolFontFamily: globalFonts.ion
                }
                MulticheckOption {
                    id: optWineDebug

                    //property to manage parameter name
                    property string parameterName : emulator + ".winedebug"

                    label: qsTr("Wine Debug") + api.tr
                    note: qsTr("Especially for developer/beta testers to help analysis from debug logs") + api.tr

                    value: api.internal.recalbox.parameterslist.currentNameChecked(parameterName)

                    currentIndex: api.internal.recalbox.parameterslist.currentIndex;
                    count: api.internal.recalbox.parameterslist.count;

                    onActivate: {
                        //for callback by parameterslistBox
                        parameterscheckBox.parameterName = parameterName;
                        parameterscheckBox.callerid = optWineDebug;
                        parameterscheckBox.isChecked = api.internal.recalbox.parameterslist.isChecked();
                        //to force update of list of parameters
                        api.internal.recalbox.parameterslist.currentNameChecked(parameterName);
                        parameterscheckBox.model = api.internal.recalbox.parameterslist;
                        parameterscheckBox.index = api.internal.recalbox.parameterslist.currentIndex;
                        //to transfer focus to parameterscheckBox
                        parameterscheckBox.focus = true;
                        //to save previous value and know if we need restart or not finally
                        parameterscheckBox.previousValue = api.internal.recalbox.getStringParameter(parameterName)
                    }

                    onFocusChanged:{
                        if(focus){
                            api.internal.recalbox.parameterslist.currentNameChecked(parameterName);
                            currentIndex = api.internal.recalbox.parameterslist.currentIndex;
                            count = api.internal.recalbox.parameterslist.count;
                            parameterscheckBox.isChecked = api.internal.recalbox.parameterslist.isChecked();
                        }
                        container.onFocus(this)
                    }

                    KeyNavigation.down: optWineHUD
                }

                MultivalueOption {
                    id: optWineHUD
                    visible: optWineRenderer.internalvalue !== "gl" ? true : false
                    //property to manage parameter name
                    property string parameterName : emulator + ".winehud"

                    label: qsTr("Wine DXVK/VKD3D HUD") + api.tr
                    note: qsTr("Especially for vulkan/DXVK (DirectX 9 to 11) or VKD3D (Direct 12) features") + api.tr

                    // Logic to update visibleInFlickable based on scroll position
                    // This is less efficient as it's checked for ALL items
                    property bool visibleInFlickable: false // Custom property to track visibility
                    onXChanged: parent.checkVisibility(this)
                    // Initial check
                    Component.onCompleted: parent.checkVisibility(this)

                    onActivate: {
                        //for callback by parameterslistBox
                        parameterslistBox.parameterName = parameterName;
                        parameterslistBox.callerid = optWineHUD;
                        //to force update of list of parameters
                        api.internal.recalbox.parameterslist.currentName(parameterName);
                        parameterslistBox.model = api.internal.recalbox.parameterslist;
                        parameterslistBox.index = api.internal.recalbox.parameterslist.currentIndex;
                        //to transfer focus to parameterslistBox
                        parameterslistBox.focus = true;
                    }

                    onSelect: {
                        //to force to be on the good parameter selected
                        api.internal.recalbox.parameterslist.currentName(parameterName);
                        //to update index of parameterlist QAbstractList
                        api.internal.recalbox.parameterslist.currentIndex = index;
                        //to force update of display of selected value
                        value = api.internal.recalbox.parameterslist.currentName(parameterName);
                    }

                    onFocusChanged:{
                        if(focus){
                            api.internal.recalbox.parameterslist.currentName(parameterName);
                            currentIndex = api.internal.recalbox.parameterslist.currentIndex;
                            count = api.internal.recalbox.parameterslist.count;
                        }
                        container.onFocus(this)
                    }
                    KeyNavigation.down: btnLaunchWineCfg
                }
                //to launch wine cfg from bottle clearly defined (could create wineprefix if missing)
                SimpleButton {
                    id: btnLaunchWineCfg
                    visible: (optWineEngine.internalvalue !== "") || (optWineAppImage.internalvalue !== "") ? true : false
                    Rectangle {
                        id: containerValidateLaunchWineCfg
                        width: parent.width
                        height: parent.height
                        anchors.verticalCenter: parent.verticalCenter
                        anchors.horizontalCenter: parent.horizontalCenter
                        color: parent.focus ? themeColor.underline : themeColor.secondary
                        opacity : parent.focus ? 1 : 0.3
                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            anchors.horizontalCenter: parent.horizontalCenter
                            color: themeColor.textValue
                            font.pixelSize: vpx(30)
                            font.family: globalFonts.ion
                            text : "\uf2ba  " + qsTr("Launch Winecfg from wine bottle") + api.tr
                        }
                    }
                    onActivate: {
                        //to force change of focus
                        confirmDialog.callerid = "btnLaunchWineCfg"
                        confirmDialog.focus = false;
                        confirmDialog.setSource("../../dialogs/Generic3ChoicesDialog.qml",
                                                { "title": emulator + " " + qsTr("Winecfg") + api.tr,
                                                  "message": qsTr("Are you sure to launch Winecfg ?") + api.tr,
                                                  "symbol": "\uf431",
                                                  "symbolfont" : global.fonts.ion,
                                                  "firstchoice": qsTr("Yes") + api.tr,
                                                  "secondchoice": "",
                                                  "thirdchoice": qsTr("No") + api.tr});
                        //to force change of focus
                        confirmDialog.focus = true;
                    }
                    onFocusChanged: container.onFocus(this)
                    //KeyNavigation.down: optWineRenderer
                }


                Item {
                    width: parent.width
                    height: implicitHeight + vpx(30)
                }
            }
        }
    }

    //loader to load confirm dialog
    Loader {
        id: confirmDialog
        anchors.fill: parent
        z:10
        property string callerid: ""
    }

    Connections {
        target: confirmDialog.item
        function onAccept() {
            //remove emulator bottles
            if (!isDebugEnv()){
                if (confirmDialog.callerid === "btnCleanEmulatorBottles"){
                    api.internal.system.run("sleep 1 ; mount -o remount,rw /; rm -r /recalbox/." + emulator + "_* ; mount -o remount,ro /");
                    api.internal.system.run("sleep 1 ; mount -o remount,rw /; rm -r /recalbox/share/saves/usersettings/." + emulator + "_* ; mount -o remount,ro /");
                }
                else if (confirmDialog.callerid === "btnLaunchWineCfg"){
                    //LIMIT: if everything is set in "auto" we can't determine the prefix to select
                    var env = ""
                    var wine = ""
                    var prefixroot = api.internal.recalbox.getStringParameter(emulator + ".wineprefixroot","/recalbox")
                    if(optWineEngine.internalvalue !== ""){
                        env = "WINEPREFIX=" + prefixroot + "/." + emulator + "_" + optWineEngine.value.replace(" (32 bit)","").replace(" (64 bit)","").trim().replace(" ","_")
                        wine = optWineEngine.internalvalue
                    }
                    else if(optWineAppImage.internalvalue !== ""){
                        env = "WINEPREFIX=" + prefixroot + "/." + emulator + "_" + optWineAppImage.value.replace(" (embedded)","")
                        wine = "/usr/wine/wine"
                    }
                    if(env !== ""){
                        if(optWineArch.internalvalue !== "" ){
                            env = env + "_" + optWineArch.internalvalue;
                        }
                        //deactivated because not used in prefix for the moment
                        /*if(optWindowsVersion.internalvalue !== "" ){
                            env = env + "_" + optWindowsVersion.internalvalue;
                        }*/
                        var command = env + " " + wine + " winecfg";
                        console.log("winecfg command: " + command);
                        api.internal.system.run(command);
                    }
                    else {//we can't determine the prefix to use from pegasus-fe
                        console.log("wine prefix can't be determine to execute winecfg");
                    }
                }

            }
            else{//for simulate and see more the spinner
                api.internal.system.run("sleep 5");
            }
            content.focus = true;
        }
        function onCancel() {
            //do nothing
            content.focus = true;
        }
    }

    MulticheckBox {
        id: parameterscheckBox
        z: 3

        //properties to manage parameter
        property string parameterName
        property string previousValue
        property MulticheckOption callerid

        //reuse same model
        model: api.internal.recalbox.parameterslist.model
        //to use index from parameterlist QAbstractList
        index: api.internal.recalbox.parameterslist.currentIndex
        //to load "checked" status for each indexes
        isChecked: api.internal.recalbox.parameterslist.isChecked()

        onClose: {
            content.focus = true
        }

        onCheck: {
            //console.log("parameterscheckBox::onCheck index : ", index, " checked : ", checked, " callerid.parameterName : ", callerid.parameterName);
            callerid.keypressed = true;
            //to use the good parameter
            api.internal.recalbox.parameterslist.currentNameChecked(callerid.parameterName);
            //to update index of parameterlist QAbstractList
            api.internal.recalbox.parameterslist.currentIndex = index;
            api.internal.recalbox.parameterslist.currentIndexChecked = checked;
            //to force update of display of selected value
            callerid.value = api.internal.recalbox.parameterslist.currentNameChecked(callerid.parameterName);
            callerid.currentIndex = api.internal.recalbox.parameterslist.currentIndex;
            callerid.count = api.internal.recalbox.parameterslist.count;
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
            /*console.log(callerid.label," onSelect count : ", callerid.count);
            console.log(callerid.label," onSelect currentindex : ", callerid.currentIndex);
            console.log(callerid.label," onSelect newindex : ", index);
            console.log(callerid.label," onSelect value : ", callerid.value);
            console.log(callerid.label," onSelect internalvalue : ", callerid.internalvalue);*/
            //to use the good parameter

            if(typeof(callerid.command) === "undefined") api.internal.recalbox.parameterslist.currentName(callerid.parameterName);
            else api.internal.recalbox.parameterslist.currentNameFromSystem(callerid.parameterName,callerid.command,callerid.optionsList);

            callerid.keypressed = true;
            //to update index of parameterlist QAbstractList
            api.internal.recalbox.parameterslist.currentIndex = index;
            callerid.count = api.internal.recalbox.parameterslist.count;
            callerid.currentIndex = index;

            //to force update of display of selected value
            if(typeof(callerid.command) === "undefined"){
                callerid.value = api.internal.recalbox.parameterslist.currentName(callerid.parameterName);
                callerid.internalvalue = api.internal.recalbox.parameterslist.currentInternalName(parameterName);
            }
            else {
                callerid.value = api.internal.recalbox.parameterslist.currentNameFromSystem(callerid.parameterName,callerid.command,callerid.optionsList);
            }
        }
    }
}
