// Pegasus Frontend
// Created by BozoTheGeek 14/08/2024

import "common"
import "qrc:/qmlutils" as PegasusUtils
import QtQuick 2.12
import QtQuick.Window 2.12

FocusScope {

    id: root
    //loader to load confirm dialog
    Loader {
        id: confirmDialog
        anchors.fill: parent
        z:10
    }

    Connections {
        target: confirmDialog.item
        function onAccept() {
            var result = "";
            //umount first in all cases
            console.log("umount command : ","umount " + parameterslistBox.target);
            result = api.internal.system.run("umount " + parameterslistBox.target);
            console.log("umount result : ",result);
            api.internal.system.run("sleep 1");
            //mount/remount
            //check that is not the default value
            if(parameterslistBox.target !== parameterslistBox.callerid.value){
                console.log("mount command : ", "mount --bind " + parameterslistBox.callerid.value + " " + parameterslistBox.target + " 2>&1");
                result = api.internal.system.run("mount --bind " + parameterslistBox.callerid.value + " " + parameterslistBox.target + " 2>&1");
                console.log("mount result : ",result);
                if(result !== ""){
                    //add dialogBox to alert about issue
                    genericMessage.setSource("../../dialogs/GenericContinueDialog.qml",
                                             { "title": qsTr("Mount error"), "message": qsTr(result)});
                    genericMessage.focus = true;
                }
            }
            content.focus = true;
        }
        function onCancel() {
            //do nothing
            content.focus = true;
        }
    }

    signal close

    anchors.fill: parent
    enabled: focus
    visible: 0 < (x + width) && x < Window.window.width

    Keys.onPressed: {
        if (api.keys.isCancel(event) && !event.isAutoRepeat) {
            event.accepted = true;
            root.close();
            api.internal.recalbox.saveParameters();
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
        text: qsTr("Settings > Advanced Directories Configuration") + api.tr
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

                MulticheckOption {
                    id: optRomsDirectories
                    focus:  true
                    //property to manage parameter name
                    property string parameterName : "directories.roms"

                    label: qsTr("ROMS directories") + api.tr
                    note: qsTr("select directories to take into account (all selected by default)") + api.tr

                    value: api.internal.recalbox.parameterslist.currentNameChecked(parameterName)

                    currentIndex: api.internal.recalbox.parameterslist.currentIndex;
                    count: api.internal.recalbox.parameterslist.count;

                    onActivate: {
                        //for callback by parameterslistBox
                        parameterscheckBox.parameterName = parameterName;
                        parameterscheckBox.callerid = optRomsDirectories;
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

                    KeyNavigation.down: optThemesDirectories
                }

                MulticheckOption {
                    id: optThemesDirectories

                    //property to manage parameter name
                    property string parameterName : "directories.themes"

                    label: qsTr("THEMES directories") + api.tr
                    note: qsTr("select directories to take into account (all selected by default)") + api.tr

                    value: api.internal.recalbox.parameterslist.currentNameChecked(parameterName)

                    currentIndex: api.internal.recalbox.parameterslist.currentIndex;
                    count: api.internal.recalbox.parameterslist.count;

                    onActivate: {
                        //for callback by parameterslistBox
                        parameterscheckBox.parameterName = parameterName;
                        parameterscheckBox.callerid = optThemesDirectories;
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

                    KeyNavigation.down: optBiosDirectory
                }

                MultivalueOption {
                    id: optBiosDirectory

                    //property to manage parameter name
                    property string parameterName : "directory.bios"

                    label: qsTr("BIOS directory") + api.tr
                    note: qsTr("select directory to take into account (share one by default)") + api.tr

                    value: api.internal.recalbox.parameterslist.currentName(parameterName)

                    currentIndex: api.internal.recalbox.parameterslist.currentIndex;
                    count: api.internal.recalbox.parameterslist.count;

                    onActivate: {
                        //for callback by parameterslistBox
                        parameterslistBox.parameterName = parameterName;
                        parameterslistBox.callerid = optBiosDirectory;
                        //to have previous one
                        parameterslistBox.previous = value;
                        //to precise target if changed to be able to mount immediately
                        parameterslistBox.target = "/recalbox/share/bios"
                        //to force update of list of parameters
                        api.internal.recalbox.parameterslist.currentName(parameterName);
                        parameterslistBox.model = api.internal.recalbox.parameterslist;
                        parameterslistBox.index = api.internal.recalbox.parameterslist.currentIndex;
                        //to transfer focus to parameterslistBox
                        parameterslistBox.focus = true;
                    }

                    onFocusChanged:{
                        if(focus){
                            api.internal.recalbox.parameterslist.currentName(parameterName);
                            currentIndex = api.internal.recalbox.parameterslist.currentIndex;
                            count = api.internal.recalbox.parameterslist.count;
                        }
                        container.onFocus(this)
                    }

                    KeyNavigation.down: optSavesDirectory
                }

                MultivalueOption {
                    id: optSavesDirectory

                    //property to manage parameter name
                    property string parameterName : "directory.saves"

                    label: qsTr("SAVES directory") + api.tr
                    note: qsTr("select directory to take into account (share one by default)") + api.tr

                    value: api.internal.recalbox.parameterslist.currentName(parameterName)

                    currentIndex: api.internal.recalbox.parameterslist.currentIndex;
                    count: api.internal.recalbox.parameterslist.count;

                    onActivate: {
                        //for callback by parameterslistBox
                        parameterslistBox.parameterName = parameterName;
                        parameterslistBox.callerid = optSavesDirectory;
                        //to have previous one
                        parameterslistBox.previous = value;
                        //to precise target if changed to be able to mount immediately
                        parameterslistBox.target = "/recalbox/share/saves"
                        //to force update of list of parameters
                        api.internal.recalbox.parameterslist.currentName(parameterName);
                        parameterslistBox.model = api.internal.recalbox.parameterslist;
                        parameterslistBox.index = api.internal.recalbox.parameterslist.currentIndex;
                        //to transfer focus to parameterslistBox
                        parameterslistBox.focus = true;
                    }

                    onFocusChanged:{
                        if(focus){
                            api.internal.recalbox.parameterslist.currentName(parameterName);
                            currentIndex = api.internal.recalbox.parameterslist.currentIndex;
                            count = api.internal.recalbox.parameterslist.count;
                        }
                        container.onFocus(this)
                    }

                    KeyNavigation.down: optOverlaysDirectory
                }

                MultivalueOption {
                    id: optOverlaysDirectory

                    //property to manage parameter name
                    property string parameterName : "directory.overlays"

                    label: qsTr("OVERLAYS directory") + api.tr
                    note: qsTr("select directory to take into account (share one by default)") + api.tr

                    value: api.internal.recalbox.parameterslist.currentName(parameterName)

                    currentIndex: api.internal.recalbox.parameterslist.currentIndex;
                    count: api.internal.recalbox.parameterslist.count;

                    onActivate: {
                        //for callback by parameterslistBox
                        parameterslistBox.parameterName = parameterName;
                        parameterslistBox.callerid = optOverlaysDirectory;
                        //to have previous one
                        parameterslistBox.previous = value;
                        //to precise target if changed to be able to mount immediately
                        parameterslistBox.target = "/recalbox/share/overlays"
                        //to force update of list of parameters
                        api.internal.recalbox.parameterslist.currentName(parameterName);
                        parameterslistBox.model = api.internal.recalbox.parameterslist;
                        parameterslistBox.index = api.internal.recalbox.parameterslist.currentIndex;
                        //to transfer focus to parameterslistBox
                        parameterslistBox.focus = true;
                    }

                    onFocusChanged:{
                        if(focus){
                            api.internal.recalbox.parameterslist.currentName(parameterName);
                            currentIndex = api.internal.recalbox.parameterslist.currentIndex;
                            count = api.internal.recalbox.parameterslist.count;
                        }
                        container.onFocus(this)
                    }

                    KeyNavigation.down: optShadersDirectory
                }

                MultivalueOption {
                    id: optShadersDirectory

                    //property to manage parameter name
                    property string parameterName : "directory.shaders"

                    label: qsTr("SHADERS directory") + api.tr
                    note: qsTr("select directory to take into account (share one by default)") + api.tr

                    value: api.internal.recalbox.parameterslist.currentName(parameterName)

                    currentIndex: api.internal.recalbox.parameterslist.currentIndex;
                    count: api.internal.recalbox.parameterslist.count;

                    onActivate: {
                        //for callback by parameterslistBox
                        parameterslistBox.parameterName = parameterName;
                        parameterslistBox.callerid = optShadersDirectory;
                        //to have previous one
                        parameterslistBox.previous = value;
                        //to precise target if changed to be able to mount immediately
                        parameterslistBox.target = "/recalbox/share/shaders"
                        //to force update of list of parameters
                        api.internal.recalbox.parameterslist.currentName(parameterName);
                        parameterslistBox.model = api.internal.recalbox.parameterslist;
                        parameterslistBox.index = api.internal.recalbox.parameterslist.currentIndex;
                        //to transfer focus to parameterslistBox
                        parameterslistBox.focus = true;
                    }

                    onFocusChanged:{
                        if(focus){
                            api.internal.recalbox.parameterslist.currentName(parameterName);
                            currentIndex = api.internal.recalbox.parameterslist.currentIndex;
                            count = api.internal.recalbox.parameterslist.count;
                        }
                        container.onFocus(this)
                    }

                    KeyNavigation.down: optUserscriptsDirectory
                }

                MultivalueOption {
                    id: optUserscriptsDirectory

                    //property to manage parameter name
                    property string parameterName : "directory.userscripts"

                    label: qsTr("USERSCRIPTS directory") + api.tr
                    note: qsTr("select directory to take into account (share one by default)") + api.tr

                    value: api.internal.recalbox.parameterslist.currentName(parameterName)

                    currentIndex: api.internal.recalbox.parameterslist.currentIndex;
                    count: api.internal.recalbox.parameterslist.count;

                    onActivate: {
                        //for callback by parameterslistBox
                        parameterslistBox.parameterName = parameterName;
                        parameterslistBox.callerid = optUserscriptsDirectory;
                        //to have previous one
                        parameterslistBox.previous = value;
                        //to precise target if changed to be able to mount immediately
                        parameterslistBox.target = "/recalbox/share/userscripts"
                        //to force update of list of parameters
                        api.internal.recalbox.parameterslist.currentName(parameterName);
                        parameterslistBox.model = api.internal.recalbox.parameterslist;
                        parameterslistBox.index = api.internal.recalbox.parameterslist.currentIndex;
                        //to transfer focus to parameterslistBox
                        parameterslistBox.focus = true;
                    }

                    onFocusChanged:{
                        if(focus){
                            api.internal.recalbox.parameterslist.currentName(parameterName);
                            currentIndex = api.internal.recalbox.parameterslist.currentIndex;
                            count = api.internal.recalbox.parameterslist.count;
                        }
                        container.onFocus(this)
                    }

                    KeyNavigation.down: optScreenshotsDirectory
                }

                MultivalueOption {
                    id: optScreenshotsDirectory

                    //property to manage parameter name
                    property string parameterName : "directory.screenshots"

                    label: qsTr("SCREENHOTS directory") + api.tr
                    note: qsTr("select directory to take into account (share one by default)") + api.tr

                    value: api.internal.recalbox.parameterslist.currentName(parameterName)

                    currentIndex: api.internal.recalbox.parameterslist.currentIndex;
                    count: api.internal.recalbox.parameterslist.count;

                    onActivate: {
                        //for callback by parameterslistBox
                        parameterslistBox.parameterName = parameterName;
                        parameterslistBox.callerid = optScreenshotsDirectory;
                        //to have previous one
                        parameterslistBox.previous = value;
                        //to precise target if changed to be able to mount immediately
                        parameterslistBox.target = "/recalbox/share/screenshots"
                        //to force update of list of parameters
                        api.internal.recalbox.parameterslist.currentName(parameterName);
                        parameterslistBox.model = api.internal.recalbox.parameterslist;
                        parameterslistBox.index = api.internal.recalbox.parameterslist.currentIndex;
                        //to transfer focus to parameterslistBox
                        parameterslistBox.focus = true;
                    }

                    onFocusChanged:{
                        if(focus){
                            api.internal.recalbox.parameterslist.currentName(parameterName);
                            currentIndex = api.internal.recalbox.parameterslist.currentIndex;
                            count = api.internal.recalbox.parameterslist.count;
                        }
                        container.onFocus(this)
                    }

                    KeyNavigation.down: optVideosDirectory
                }


                MultivalueOption {
                    id: optVideosDirectory

                    //property to manage parameter name
                    property string parameterName : "directory.videos"

                    label: qsTr("VIDEOS directory") + api.tr
                    note: qsTr("select directory to take into account (share one by default)") + api.tr

                    value: api.internal.recalbox.parameterslist.currentName(parameterName)

                    currentIndex: api.internal.recalbox.parameterslist.currentIndex;
                    count: api.internal.recalbox.parameterslist.count;

                    onActivate: {
                        //for callback by parameterslistBox
                        parameterslistBox.parameterName = parameterName;
                        parameterslistBox.callerid = optVideosDirectory;
                        //to have previous one
                        parameterslistBox.previous = value;
                        //to precise target if changed to be able to mount immediately
                        parameterslistBox.target = "/recalbox/share/videos"
                        //to force update of list of parameters
                        api.internal.recalbox.parameterslist.currentName(parameterName);
                        parameterslistBox.model = api.internal.recalbox.parameterslist;
                        parameterslistBox.index = api.internal.recalbox.parameterslist.currentIndex;
                        //to transfer focus to parameterslistBox
                        parameterslistBox.focus = true;
                    }

                    onFocusChanged:{
                        if(focus){
                            api.internal.recalbox.parameterslist.currentName(parameterName);
                            currentIndex = api.internal.recalbox.parameterslist.currentIndex;
                            count = api.internal.recalbox.parameterslist.count;
                        }
                        container.onFocus(this)
                    }

                    KeyNavigation.down: optMusicDirectory
                }
                MultivalueOption {
                    id: optMusicDirectory

                    //property to manage parameter name
                    property string parameterName : "directory.music"

                    label: qsTr("MUSIC directory") + api.tr
                    note: qsTr("select directory to take into account (share one by default)") + api.tr

                    value: api.internal.recalbox.parameterslist.currentName(parameterName)

                    currentIndex: api.internal.recalbox.parameterslist.currentIndex;
                    count: api.internal.recalbox.parameterslist.count;

                    onActivate: {
                        //for callback by parameterslistBox
                        parameterslistBox.parameterName = parameterName;
                        parameterslistBox.callerid = optMusicDirectory;
                        //to have previous one
                        parameterslistBox.previous = value;
                        //to precise target if changed to be able to mount immediately
                        parameterslistBox.target = "/recalbox/share/music"
                        //to force update of list of parameters
                        api.internal.recalbox.parameterslist.currentName(parameterName);
                        parameterslistBox.model = api.internal.recalbox.parameterslist;
                        parameterslistBox.index = api.internal.recalbox.parameterslist.currentIndex;
                        //to transfer focus to parameterslistBox
                        parameterslistBox.focus = true;
                    }

                    onFocusChanged:{
                        if(focus){
                            api.internal.recalbox.parameterslist.currentName(parameterName);
                            currentIndex = api.internal.recalbox.parameterslist.currentIndex;
                            count = api.internal.recalbox.parameterslist.count;
                        }
                        container.onFocus(this)
                    }

                    //KeyNavigation.down: rfu
                }

                Item {
                    width: parent.width
                    height: implicitHeight + vpx(30)
                }
            }
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
            //check if need to restart to take change into account !
            if(previousValue !== api.internal.recalbox.getStringParameter(parameterName)){
                console.log("needRestart");
                needRestart = true;
            }
        }

        onCheck: {
            //console.log("parameterscheckBox::onCheck index : ", index, " checked : ", checked);
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
        property string target
        property string previous: ""

        //reuse same model
        model: api.internal.recalbox.parameterslist.model
        //to use index from parameterlist QAbstractList
        index: api.internal.recalbox.parameterslist.currentIndex

        onClose: {
            content.focus = true
            console.log("previous value : ", previous);
            console.log("new value : ", callerid.value);
            if (previous !== callerid.value ) {
                //if different we could propose to remount this directory
                //force save in recalbox.conf file before to execute anything in this case
                api.internal.recalbox.saveParameters();
                //to force change of focus
                confirmDialog.focus = false;
                confirmDialog.setSource("../../dialogs/Generic3ChoicesDialog.qml",
                                        { "title": qsTr("Mount directory") + api.tr,
                                          "message": qsTr("Do you want to mount immediately") + "<br>'" + callerid.value + "'<br>" + qsTr("as") + "<br>" + callerid.label + " ?" + api.tr,
                                          "symbol": "",
                                          "symbolfont" : global.fonts.awesome,
                                          "firstchoice": qsTr("Yes") + api.tr,
                                          "secondchoice": "",
                                          "thirdchoice": qsTr("No") + api.tr});
                //to force change of focus
                confirmDialog.focus = true;
            }
        }

        onSelect: {
            previous = callerid.value;
            callerid.keypressed = true;
            //to use the good parameter
            api.internal.recalbox.parameterslist.currentName(callerid.parameterName);
            //to update index of parameterlist QAbstractList
            api.internal.recalbox.parameterslist.currentIndex = index;
            //to force update of display of selected value
            callerid.value = api.internal.recalbox.parameterslist.currentName(callerid.parameterName);
            callerid.currentIndex = api.internal.recalbox.parameterslist.currentIndex;
            callerid.count = api.internal.recalbox.parameterslist.count;
        }
    }
}
