
import "common"
import "qrc:/qmlutils" as PegasusUtils
import QtQuick 2.12
import QtQuick.Window 2.12


FocusScope {
    id: root

    signal close
    signal openVideoSettings

    width: parent.width
    height: parent.height
    visible: 0 < (x + width) && x < Window.window.width

    enabled: focus

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
        text: qsTr("Settings > Video Configuration") + api.tr
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

                //mode: switch, clone or extended
                MultivalueOption {
                    id: optDisplayMode

                    //property to manage parameter name
                    property string parameterName : "system.video.screens.mode"
                    //to keep initial value and before to apply new one
                    property string previousinternalvalue: api.internal.recalbox.getStringParameter(parameterName)
                    property string previousvalue : api.internal.recalbox.parameterslist.currentName(parameterName)

                    label: qsTr("Display mode") + api.tr
                    note: qsTr("Choose any mode to manage behavior when you plug/unplug any screen") + api.tr

                    value: api.internal.recalbox.parameterslist.currentName(parameterName)
                    internalvalue: api.internal.recalbox.parameterslist.currentInternalName(parameterName)

                    currentIndex: api.internal.recalbox.parameterslist.currentIndex;
                    count: api.internal.recalbox.parameterslist.count;

                    font: globalFonts.ion
                    focus: true
                    onActivate: {
                        //for callback by parameterslistBox
                        parameterslistBox.parameterName = parameterName;
                        parameterslistBox.callerid = optDisplayMode;
                        //to force update of list of parameters
                        api.internal.recalbox.parameterslist.currentName(parameterName)
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
                    KeyNavigation.down: optVirtualDisplay
                }

                MulticheckOption {
                    id: optVirtualDisplay
                    //property to manage parameter name
                    property string parameterName : "system.video.screens.virtual"

                    label: qsTr("Virtual Screens (for remote display)") + api.tr
                    note: qsTr("Select output(s) available to connect any virtual screen (need reboot)") + api.tr

                    //to keep initial value and before to apply new one (to know if need reboot more than restart)
                    property string previousvalue: api.internal.recalbox.getStringParameter(parameterName)

                    value: api.internal.recalbox.parameterslist.currentNameChecked(parameterName)

                    currentIndex: api.internal.recalbox.parameterslist.currentIndex;
                    count: api.internal.recalbox.parameterslist.count;

                    onActivate: {
                        //for callback by parameterslistBox
                        parameterscheckBox.parameterName = parameterName;
                        parameterscheckBox.callerid = optVirtualDisplay;
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

                    onValueChanged: {
                        //console.log("previousvalue: ", previousvalue);
                        //console.log("api.internal.recalbox.getStringParameter(parameterName): ", api.internal.recalbox.getStringParameter(parameterName));
                        if(previousvalue !== api.internal.recalbox.getStringParameter(parameterName)){
                            //need to reboot (or restart Xorg if possible in the future)
                            console.log("Need reboot");
                            needReboot = true;
                        }
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

                    KeyNavigation.down: optPrimaryScreenActivate
                }
                // primary screen
                ToggleOption {
                    id: optPrimaryScreenActivate

                    //property to manage parameter name
                    property string parameterName : "system.primary.screen.enabled"
                    //to keep initial value and before to apply new one
                    property bool previousvalue: api.internal.recalbox.getBoolParameter(parameterName)

                    SectionTitle {
                        text: qsTr("Primary screen settings") + api.tr
                        first: true
                    }
                    checked: api.internal.recalbox.systemPrimaryScreenEnabled
                    onCheckedChanged: {
                        api.internal.recalbox.systemPrimaryScreenEnabled = checked;
                    }
                    symbol: "\uf17f"
                    onFocusChanged: container.onFocus(this)
                    KeyNavigation.down: optDisplayOutput
                }
                MultivalueOption {
                    id: optDisplayOutput

                    //property to manage parameter name
                    property string parameterName : "system.primary.screen"
                    //to keep initial value and before to apply new one
                    property string previousvalue: api.internal.recalbox.getStringParameter(parameterName)

                    property variant optionsList : []
                    property string command: "awk '$2 ~ \"connected\" {print $1}' /tmp/xrandr.tmp"
                    // set focus only on first item

                    label: qsTr("Output") + api.tr
                    note: qsTr("Choose your output for primary screen.") + api.tr

                    value: api.internal.recalbox.parameterslist.currentNameFromSystem(parameterName,command,optionsList)

                    currentIndex: api.internal.recalbox.parameterslist.currentIndex;
                    count: api.internal.recalbox.parameterslist.count;

                    font: globalFonts.ion

                    Component.onCompleted: {
                        //console.log(label," onCompleted count : ", count);
                        //console.log(label," onCompleted currentindex : ", currentIndex);
                        //console.log(label," onCompleted value : ", value);
                        //console.log(label," onCompleted internalvalue : ", internalvalue);

                        //to force update of value and pointers at the beginning
                        keypressed = true;
                        value = api.internal.recalbox.parameterslist.currentNameFromSystem(parameterName,command,optionsList);
                        count = api.internal.recalbox.parameterslist.count;
                        currentIndex = api.internal.recalbox.parameterslist.currentIndex;
                        //To force update of pointers
                        if(currentIndex < (count - 1)){
                          rightPointer.visible = true;
                        } else rightPointer.visible = false;
                        if(currentIndex >=1){
                          leftPointer.visible = true
                        } else leftPointer.visible = false;
                    }

                    onActivate: {
                        //for callback by parameterslistBox
                        parameterslistBox.parameterName = parameterName;
                        parameterslistBox.callerid = optDisplayOutput;
                        //to force update of list of parameters
                        api.internal.recalbox.parameterslist.currentNameFromSystem(parameterName,command,optionsList);
                        parameterslistBox.model = api.internal.recalbox.parameterslist;
                        parameterslistBox.index = api.internal.recalbox.parameterslist.currentIndex;
                        //to transfer focus to parameterslistBox
                        parameterslistBox.focus = true;
                    }

                    onSelect: {
                        //to force to be on the good parameter selected
                        api.internal.recalbox.parameterslist.currentNameFromSystem(parameterName,command,optionsList);
                        //to update index of parameterlist QAbstractList
                        api.internal.recalbox.parameterslist.currentIndex = index;
                        //to force update of display of selected value
                        value = api.internal.recalbox.parameterslist.currentNameFromSystem(parameterName,command,optionsList);
                    }

                    onFocusChanged:{
                        if(focus){
                            api.internal.recalbox.parameterslist.currentNameFromSystem(parameterName,command,optionsList);
                            currentIndex = api.internal.recalbox.parameterslist.currentIndex;
                            count = api.internal.recalbox.parameterslist.count;
                        }
                        container.onFocus(this)
                    }

                    KeyNavigation.down: optDisplayResolution
                    visible: optPrimaryScreenActivate.checked
                }
                MultivalueOption {
                    id: optDisplayResolution

                    //property to manage parameter name
                    property string parameterName : "system.primary.screen.resolution"
                    //to keep initial value and before to apply new one
                    property string previousvalue: api.internal.recalbox.getStringParameter(parameterName)

                    property variant optionsList : [optDisplayOutput.value]
                    property string command : "awk -v monitor=\"^%1 connected\" '/connected/ {p = 0} $0 ~ monitor {p = 1} p' /tmp/xrandr.tmp | awk '{if(NR>1)print $1}'"

                    label: qsTr("Resolution") + api.tr
                    note: qsTr("Choose resolution for your primary screen.") + api.tr

                    value: api.internal.recalbox.parameterslist.currentNameFromSystem(parameterName,command,optionsList)

                    currentIndex: api.internal.recalbox.parameterslist.currentIndex;
                    count: api.internal.recalbox.parameterslist.count;

                    font: globalFonts.ion

                    Component.onCompleted: {
                        //console.log(label," onCompleted count : ", count);
                        //console.log(label," onCompleted currentindex : ", currentIndex);
                        //console.log(label," onCompleted value : ", value);
                        //console.log(label," onCompleted internalvalue : ", internalvalue);

                        //to force update of value and pointers at the beginning
                        keypressed = true;
                        value = api.internal.recalbox.parameterslist.currentNameFromSystem(parameterName,command,optionsList);
                        count = api.internal.recalbox.parameterslist.count;
                        currentIndex = api.internal.recalbox.parameterslist.currentIndex;
                        //To force update of pointers
                        if(currentIndex < (count - 1)){
                          rightPointer.visible = true;
                        } else rightPointer.visible = false;
                        if(currentIndex >=1){
                          leftPointer.visible = true
                        } else leftPointer.visible = false;
                    }

                    onActivate: {
                        //for callback by parameterslistBox
                        parameterslistBox.parameterName = parameterName;
                        parameterslistBox.callerid = optDisplayResolution;
                        //to force update of list of parameters
                        api.internal.recalbox.parameterslist.currentNameFromSystem(parameterName,command,optionsList);
                        parameterslistBox.model = api.internal.recalbox.parameterslist;
                        parameterslistBox.index = api.internal.recalbox.parameterslist.currentIndex;
                        //to transfer focus to parameterslistBox
                        parameterslistBox.focus = true;
                    }

                    onSelect: {
                        //to force to be on the good parameter selected
                        api.internal.recalbox.parameterslist.currentNameFromSystem(parameterName,command,optionsList);
                        //to update index of parameterlist QAbstractList
                        api.internal.recalbox.parameterslist.currentIndex = index;
                        //to force update of display of selected value
                        value = api.internal.recalbox.parameterslist.currentNameFromSystem(parameterName,command,optionsList);
                    }

                    onFocusChanged:{
                        if(focus){
                            /*console.log(label," onFocusChanged count : ", count);
                            console.log(label," onFocusChanged currentindex : ", currentIndex);
                            console.log(label," onFocusChanged value : ", value);
                            console.log(label," onFocusChanged internalvalue : ", internalvalue);*/
                            value = api.internal.recalbox.parameterslist.currentNameFromSystem(parameterName,command,optionsList);
                            count = api.internal.recalbox.parameterslist.count;
                            currentIndex = api.internal.recalbox.parameterslist.currentIndex;
                        }
                        container.onFocus(this)
                    }

                    KeyNavigation.down: optDisplayFrequency
                    visible: optPrimaryScreenActivate.checked
                }
                MultivalueOption {
                    id: optDisplayFrequency

                    //property to manage parameter name
                    property string parameterName : "system.primary.screen.frequency"
                    //to keep initial value and before to apply new one
                    property string previousvalue: api.internal.recalbox.getStringParameter(parameterName)

                    property variant optionsList : [optDisplayOutput.value, optDisplayResolution.value]
                    property string command : "awk -v monitor=\"^%1 connected\" '/connected/ {p = 0} $0 ~ monitor {p = 1} p' /tmp/xrandr.tmp | awk '{if(NR>1) print}' | awk '$1 == \"%2\" {print}' | awk '{for (i=2; i<=NF; i++) print $i}' | tr -d '+*'"
                    label: qsTr("Frequency") + api.tr
                    note: qsTr("Choose frequency for your primary screen.") + api.tr

                    value: api.internal.recalbox.parameterslist.currentNameFromSystem(parameterName,command,optionsList)

                    currentIndex: api.internal.recalbox.parameterslist.currentIndex;
                    count: api.internal.recalbox.parameterslist.count;

                    font: globalFonts.ion

                    Component.onCompleted: {
                        //console.log(label," onCompleted count : ", count);
                        //console.log(label," onCompleted currentindex : ", currentIndex);
                        //console.log(label," onCompleted value : ", value);
                        //console.log(label," onCompleted internalvalue : ", internalvalue);

                        //to force update of value and pointers at the beginning
                        keypressed = true;
                        value = api.internal.recalbox.parameterslist.currentNameFromSystem(parameterName,command,optionsList);
                        count = api.internal.recalbox.parameterslist.count;
                        currentIndex = api.internal.recalbox.parameterslist.currentIndex;
                        //To force update of pointers
                        if(currentIndex < (count - 1)){
                          rightPointer.visible = true;
                        } else rightPointer.visible = false;
                        if(currentIndex >=1){
                          leftPointer.visible = true
                        } else leftPointer.visible = false;
                    }

                    onActivate: {
                        //for callback by parameterslistBox
                        parameterslistBox.parameterName = parameterName;
                        parameterslistBox.callerid = optDisplayFrequency;
                        //to force update of list of parameters
                        api.internal.recalbox.parameterslist.currentNameFromSystem(parameterName,command,optionsList)
                        parameterslistBox.model = api.internal.recalbox.parameterslist;
                        parameterslistBox.index = api.internal.recalbox.parameterslist.currentIndex;
                        //to transfer focus to parameterslistBox
                        parameterslistBox.focus = true;
                    }

                    onSelect: {
                        //to force to be on the good parameter selected
                        api.internal.recalbox.parameterslist.currentNameFromSystem(parameterName,command,optionsList);
                        //to update index of parameterlist QAbstractList
                        api.internal.recalbox.parameterslist.currentIndex = index;
                        //to force update of display of selected value
                        value = api.internal.recalbox.parameterslist.currentNameFromSystem(parameterName,command,optionsList);
                    }

                    onFocusChanged:{
                        if(focus){
                            api.internal.recalbox.parameterslist.currentNameFromSystem(parameterName,command,optionsList);
                            currentIndex = api.internal.recalbox.parameterslist.currentIndex;
                            count = api.internal.recalbox.parameterslist.count;
                        }
                        container.onFocus(this)
                    }

                    KeyNavigation.down: optDisplayRotation
                    visible: optPrimaryScreenActivate.checked
                }
                MultivalueOption {
                    id: optDisplayRotation

                    //property to manage parameter name
                    property string parameterName : "system.primary.screen.rotation"
                    //to keep initial internal value and before to apply new one
                    property string previousinternalvalue: api.internal.recalbox.getStringParameter(parameterName)
                    property string previousvalue : api.internal.recalbox.parameterslist.currentName(parameterName)

                    label: qsTr("Rotate") + api.tr
                    note: qsTr("Choose orientation for your primary screen.") + api.tr

                    value: api.internal.recalbox.parameterslist.currentName(parameterName)
                    internalvalue: api.internal.recalbox.parameterslist.currentInternalName(parameterName)

                    currentIndex: api.internal.recalbox.parameterslist.currentIndex;
                    count: api.internal.recalbox.parameterslist.count;

                    font: globalFonts.ion
                    onActivate: {
                        //for callback by parameterslistBox
                        parameterslistBox.parameterName = parameterName;
                        parameterslistBox.callerid = optDisplayRotation;
                        //to force update of list of parameters
                        api.internal.recalbox.parameterslist.currentName(parameterName);
                        api.internal.recalbox.parameterslist.currentInternalName(parameterName);
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
                            value = api.internal.recalbox.parameterslist.currentName(parameterName);
                            internalvalue = api.internal.recalbox.parameterslist.currentInternalName(parameterName);
                            count = api.internal.recalbox.parameterslist.count;
                            currentIndex = api.internal.recalbox.parameterslist.currentIndex;
                        }
                        container.onFocus(this)
                    }

                    KeyNavigation.down: optSecondaryScreenActivate
                    visible: optPrimaryScreenActivate.checked
                }

                // second screen or else
                ToggleOption {
                    id: optSecondaryScreenActivate

                    //property to manage parameter name
                    property string parameterName : "system.secondary.screen.enabled"
                    //to keep initial value and before to apply new one
                    property bool previousvalue: api.internal.recalbox.getBoolParameter(parameterName)

                    SectionTitle {
                        text: qsTr("Secondary screen settings") + api.tr
                        first: true
                    }
                    checked: api.internal.recalbox.systemSecondaryScreenEnabled
                    onCheckedChanged: {
                        api.internal.recalbox.systemSecondaryScreenEnabled = checked;
                    }
                    symbol: "\uf115"
                    onFocusChanged: container.onFocus(this)
                    //                    KeyNavigation.up: optDisplayRotation
                    KeyNavigation.down: optDisplaySecondaryOutput
                }

                MultivalueOption {
                    id: optDisplaySecondaryOutput

                    //property to manage parameter name
                    property string parameterName : "system.secondary.screen"
                    //to keep initial value and before to apply new one
                    property string previousvalue: api.internal.recalbox.getStringParameter(parameterName)

                    property variant optionsList : []
                    property string command : "awk '$2 ~ \"connected\" {print $1}' /tmp/xrandr.tmp"

                    label: qsTr("Output") + api.tr
                    note: qsTr("Choose your output for secondary screen.") + api.tr

                    value: api.internal.recalbox.parameterslist.currentNameFromSystem(parameterName,command,optionsList)

                    currentIndex: api.internal.recalbox.parameterslist.currentIndex;
                    count: api.internal.recalbox.parameterslist.count;

                    font: globalFonts.ion

                    Component.onCompleted: {
                        //console.log(label," onCompleted count : ", count);
                        //console.log(label," onCompleted currentindex : ", currentIndex);
                        //console.log(label," onCompleted value : ", value);
                        //console.log(label," onCompleted internalvalue : ", internalvalue);

                        //to force update of value and pointers at the beginning
                        keypressed = true;
                        value = api.internal.recalbox.parameterslist.currentNameFromSystem(parameterName,command,optionsList);
                        count = api.internal.recalbox.parameterslist.count;
                        currentIndex = api.internal.recalbox.parameterslist.currentIndex;
                        //To force update of pointers
                        if(currentIndex < (count - 1)){
                          rightPointer.visible = true;
                        } else rightPointer.visible = false;
                        if(currentIndex >=1){
                          leftPointer.visible = true
                        } else leftPointer.visible = false;
                    }

                    onActivate: {
                        //for callback by parameterslistBox
                        parameterslistBox.parameterName = parameterName;
                        parameterslistBox.callerid = optDisplaySecondaryOutput;
                        //to force update of list of parameters
                        api.internal.recalbox.parameterslist.currentNameFromSystem(parameterName,command,optionsList);
                        parameterslistBox.model = api.internal.recalbox.parameterslist;
                        parameterslistBox.index = api.internal.recalbox.parameterslist.currentIndex;
                        //to transfer focus to parameterslistBox
                        parameterslistBox.focus = true;
                    }

                    onSelect: {
                        //to force to be on the good parameter selected
                        api.internal.recalbox.parameterslist.currentNameFromSystem(parameterName,command,optionsList);
                        //to update index of parameterlist QAbstractList
                        api.internal.recalbox.parameterslist.currentIndex = index;
                        //to force update of display of selected value
                        value = api.internal.recalbox.parameterslist.currentNameFromSystem(parameterName,command,optionsList);
                    }

                    onFocusChanged:{
                        if(focus){
                            api.internal.recalbox.parameterslist.currentNameFromSystem(parameterName,command,optionsList);
                            currentIndex = api.internal.recalbox.parameterslist.currentIndex;
                            count = api.internal.recalbox.parameterslist.count;
                        }
                        container.onFocus(this)
                    }

                    KeyNavigation.down: optDisplaySecondaryResolution
                    // only show if video Secondary option as enabled
                    visible: optSecondaryScreenActivate.checked
                }
                MultivalueOption {
                    id: optDisplaySecondaryResolution

                    //property to manage parameter name
                    property string parameterName : "system.secondary.screen.resolution"
                    //to keep initial value and before to apply new one
                    property string previousvalue: api.internal.recalbox.getStringParameter(parameterName)

                    property variant optionsList : [optDisplaySecondaryOutput.value]
                    property string command : "awk -v monitor=\"^%1 connected\" '/connected/ {p = 0} $0 ~ monitor {p = 1} p' /tmp/xrandr.tmp | awk '{if(NR>1)print $1}'"

                    label: qsTr("Resolution") + api.tr
                    note: qsTr("Choose resolution for secondary screen.") + api.tr

                    value: api.internal.recalbox.parameterslist.currentNameFromSystem(parameterName,command,optionsList)

                    currentIndex: api.internal.recalbox.parameterslist.currentIndex;
                    count: api.internal.recalbox.parameterslist.count;

                    font: globalFonts.ion

                    Component.onCompleted: {
                        //console.log(label," onCompleted count : ", count);
                        //console.log(label," onCompleted currentindex : ", currentIndex);
                        //console.log(label," onCompleted value : ", value);
                        //console.log(label," onCompleted internalvalue : ", internalvalue);

                        //to force update of value and pointers at the beginning
                        keypressed = true;
                        value = api.internal.recalbox.parameterslist.currentNameFromSystem(parameterName,command,optionsList);
                        count = api.internal.recalbox.parameterslist.count;
                        currentIndex = api.internal.recalbox.parameterslist.currentIndex;
                        //To force update of pointers
                        if(currentIndex < (count - 1)){
                          rightPointer.visible = true;
                        } else rightPointer.visible = false;
                        if(currentIndex >=1){
                          leftPointer.visible = true
                        } else leftPointer.visible = false;
                    }

                    onActivate: {
                        //for callback by parameterslistBox
                        parameterslistBox.parameterName = parameterName;
                        parameterslistBox.callerid = optDisplaySecondaryResolution;
                        //to force update of list of parameters
                        api.internal.recalbox.parameterslist.currentNameFromSystem(parameterName,command,optionsList);
                        parameterslistBox.model = api.internal.recalbox.parameterslist;
                        parameterslistBox.index = api.internal.recalbox.parameterslist.currentIndex;
                        //to transfer focus to parameterslistBox
                        parameterslistBox.focus = true;
                    }

                    onSelect: {
                        //to force to be on the good parameter selected
                        api.internal.recalbox.parameterslist.currentNameFromSystem(parameterName,command,optionsList);
                        //to update index of parameterlist QAbstractList
                        api.internal.recalbox.parameterslist.currentIndex = index;
                        //to force update of display of selected value
                        value = api.internal.recalbox.parameterslist.currentNameFromSystem(parameterName,command,optionsList);
                    }

                    onFocusChanged:{
                        if(focus){
                            api.internal.recalbox.parameterslist.currentNameFromSystem(parameterName,command,optionsList);
                            currentIndex = api.internal.recalbox.parameterslist.currentIndex;
                            count = api.internal.recalbox.parameterslist.count;
                        }
                        container.onFocus(this)
                    }

                    KeyNavigation.down: optDisplaySecondaryFrequency
                    // only show if video Secondary option as enabled
                    visible: optSecondaryScreenActivate.checked
                }
                MultivalueOption {
                    id: optDisplaySecondaryFrequency

                    //property to manage parameter name
                    property string parameterName : "system.secondary.screen.frequency"
                    //to keep initial value and before to apply new one
                    property string previousvalue: api.internal.recalbox.getStringParameter(parameterName)

                    property variant optionsList : [optDisplaySecondaryOutput.value, optDisplaySecondaryResolution.value]
                    property string command : "awk -v monitor=\"^%1 connected\" '/connected/ {p = 0} $0 ~ monitor {p = 1} p' /tmp/xrandr.tmp | awk '{if(NR>1) print}' | awk '$1 == \"%2\" {print}' | awk '{for (i=2; i<=NF; i++) print $i}' | tr -d '+*'"

                    label: qsTr("Frequency") + api.tr
                    note: qsTr("Choose frequency for secondary screen.") + api.tr

                    value: api.internal.recalbox.parameterslist.currentNameFromSystem(parameterName,command,optionsList)

                    currentIndex: api.internal.recalbox.parameterslist.currentIndex;
                    count: api.internal.recalbox.parameterslist.count;

                    font: globalFonts.ion

                    Component.onCompleted: {
                        //console.log(label," onCompleted count : ", count);
                        //console.log(label," onCompleted currentindex : ", currentIndex);
                        //console.log(label," onCompleted value : ", value);
                        //console.log(label," onCompleted internalvalue : ", internalvalue);

                        //to force update of value and pointers at the beginning
                        keypressed = true;
                        value = api.internal.recalbox.parameterslist.currentNameFromSystem(parameterName,command,optionsList);
                        count = api.internal.recalbox.parameterslist.count;
                        currentIndex = api.internal.recalbox.parameterslist.currentIndex;
                        //To force update of pointers
                        if(currentIndex < (count - 1)){
                          rightPointer.visible = true;
                        } else rightPointer.visible = false;
                        if(currentIndex >=1){
                          leftPointer.visible = true
                        } else leftPointer.visible = false;
                    }

                    onActivate: {
                        //for callback by parameterslistBox
                        parameterslistBox.parameterName = parameterName;
                        parameterslistBox.callerid = optDisplaySecondaryFrequency;
                        //to force update of list of parameters
                        api.internal.recalbox.parameterslist.currentNameFromSystem(parameterName,command,optionsList)
                        parameterslistBox.model = api.internal.recalbox.parameterslist;
                        parameterslistBox.index = api.internal.recalbox.parameterslist.currentIndex;
                        //to transfer focus to parameterslistBox
                        parameterslistBox.focus = true;
                    }

                    onSelect: {
                        //to force to be on the good parameter selected
                        api.internal.recalbox.parameterslist.currentNameFromSystem(parameterName,command,optionsList);
                        //to update index of parameterlist QAbstractList
                        api.internal.recalbox.parameterslist.currentIndex = index;
                        //to force update of display of selected value
                        value = api.internal.recalbox.parameterslist.currentNameFromSystem(parameterName,command,optionsList);
                    }

                    onFocusChanged:{
                        if(focus){
                            api.internal.recalbox.parameterslist.currentNameFromSystem(parameterName,command,optionsList);
                            currentIndex = api.internal.recalbox.parameterslist.currentIndex;
                            count = api.internal.recalbox.parameterslist.count;
                        }
                        container.onFocus(this)
                    }

                    KeyNavigation.down: optDisplaySecondaryRotation
                    // only show if video Secondary option as enabled
                    visible: optSecondaryScreenActivate.checked
                }
                MultivalueOption {
                    id: optDisplaySecondaryRotation

                    //property to manage parameter name
                    property string parameterName : "system.secondary.screen.rotation"
                    //to keep initial internal value and before to apply new one
                    property string previousinternalvalue: api.internal.recalbox.getStringParameter(parameterName)
                    property string previousvalue : api.internal.recalbox.parameterslist.currentName(parameterName)

                    label: qsTr("Rotation") + api.tr
                    note: qsTr("Choose orientation for your secondary screen.") + api.tr

                    value: api.internal.recalbox.parameterslist.currentName(parameterName)
                    internalvalue: api.internal.recalbox.parameterslist.currentInternalName(parameterName)

                    currentIndex: api.internal.recalbox.parameterslist.currentIndex;
                    count: api.internal.recalbox.parameterslist.count;

                    font: globalFonts.ion

                    onActivate: {
                        //for callback by parameterslistBox
                        parameterslistBox.parameterName = parameterName;
                        parameterslistBox.callerid = optDisplaySecondaryRotation;
                        //to force update of list of parameters
                        api.internal.recalbox.parameterslist.currentName(parameterName);
                        api.internal.recalbox.parameterslist.currentInternalName(parameterName);
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

                    KeyNavigation.down: optDisplaySecondaryPosition
                    // only show if video Secondary option as enabled
                    visible: optSecondaryScreenActivate.checked
                }
                MultivalueOption {
                    id: optDisplaySecondaryPosition

                    //property to manage parameter name
                    property string parameterName : "system.secondary.screen.position"
                    //to keep initial internal value and before to apply new one
                    property string previousinternalvalue : api.internal.recalbox.getStringParameter(parameterName)
                    property string previousvalue : api.internal.recalbox.parameterslist.currentName(parameterName)

                    label: qsTr("Position") + api.tr
                    note: qsTr("Choose position for your Secondary screen.") + api.tr

                    value: api.internal.recalbox.parameterslist.currentName(parameterName)
                    internalvalue: api.internal.recalbox.parameterslist.currentInternalName(parameterName)

                    currentIndex: api.internal.recalbox.parameterslist.currentIndex;
                    count: api.internal.recalbox.parameterslist.count;

                    font: globalFonts.ion

                    onActivate: {
                        //for callback by parameterslistBox
                        parameterslistBox.parameterName = parameterName;
                        parameterslistBox.callerid = optDisplaySecondaryPosition;
                        //to force update of list of parameters
                        api.internal.recalbox.parameterslist.currentName(parameterName);
                        api.internal.recalbox.parameterslist.currentInternalName(parameterName);
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
                            value = api.internal.recalbox.parameterslist.currentName(parameterName);
                            internalvalue = api.internal.recalbox.parameterslist.currentInternalName(parameterName);
                            count = api.internal.recalbox.parameterslist.count;
                            currentIndex = api.internal.recalbox.parameterslist.currentIndex;
                        }
                        container.onFocus(this)
                    }

                    KeyNavigation.down: optValidateChange
                    // only show if video Secondary option as enabled
                    visible: optSecondaryScreenActivate.checked
                }

                // to validate first and second screen
                SimpleButton {
                    id: optValidateChange
                    Rectangle {
                        id: containerValidate
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
                            text : "\uf2ba  " + qsTr("Apply") + api.tr
                        }
                    }
                    onActivate: {
                        //for display mode
                        //console.log("optDisplayMode.parameterName: ", optDisplayMode.parameterName, "optDisplayMode.internalvalue: ", optDisplayMode.internalvalue)
                        api.internal.recalbox.setStringParameter(optDisplayMode.parameterName, optDisplayMode.internalvalue);
                        //for first screen (if activated)
                        api.internal.recalbox.setBoolParameter(optPrimaryScreenActivate.parameterName, optPrimaryScreenActivate.checked);
                        if(optPrimaryScreenActivate.checked){
                            api.internal.recalbox.setStringParameter(optDisplayOutput.parameterName, optDisplayOutput.value)
                            api.internal.recalbox.setStringParameter(optDisplayResolution.parameterName, optDisplayResolution.value)
                            api.internal.recalbox.setStringParameter(optDisplayFrequency.parameterName, optDisplayFrequency.value)
                            api.internal.recalbox.setStringParameter(optDisplayRotation.parameterName, optDisplayRotation.internalvalue)
                        }
                        //for second screen (if activated)
                        api.internal.recalbox.setBoolParameter(optSecondaryScreenActivate.parameterName,optSecondaryScreenActivate.checked);
                        if(optSecondaryScreenActivate.checked){
                            api.internal.recalbox.setStringParameter(optDisplaySecondaryOutput.parameterName, optDisplaySecondaryOutput.value)
                            api.internal.recalbox.setStringParameter(optDisplaySecondaryResolution.parameterName, optDisplaySecondaryResolution.value)
                            api.internal.recalbox.setStringParameter(optDisplaySecondaryFrequency.parameterName, optDisplaySecondaryFrequency.value)
                            api.internal.recalbox.setStringParameter(optDisplaySecondaryRotation.parameterName, optDisplaySecondaryRotation.internalvalue)
                            api.internal.recalbox.setStringParameter(optDisplaySecondaryPosition.parameterName, optDisplaySecondaryPosition.internalvalue)
                        }
                        //force save in recalbox.conf file before to execute script
                        api.internal.recalbox.saveParameters();
                        //Execute script to udpate screen settings in real-time
                        api.internal.system.runBoolResult("/usr/bin/externalscreen.sh");
                        //and move pegasus-frontend in connected and primary screen
                        api.internal.system.runBoolResult("WINDOWPID=$(xdotool search --class 'pegasus-frontend'); xdotool windowmove $WINDOWPID $(xrandr | grep -e ' connected' | grep -e 'primary' | awk '{print $4}' | awk -F'+' '{print $2, $3}');", false);

                        //to confirm change or not
                        confirmDialog.focus = false;
                        confirmDialog.setSource("../../dialogs/Generic3ChoicesDialog.qml",
                                                { "title": qsTr("Confirmation"),
                                                  "message": qsTr("Do you want to keep this change ?") + api.tr,
                                                  "symbol": "\uf17f",
                                                  "symbolfont" : global.fonts.ion,
                                                  "firstchoice": qsTr("Yes") + api.tr,
                                                  "secondchoice": "",
                                                  "thirdchoice": qsTr("No") + api.tr,
                                                  "canceldelay": 15});
                        //to force change of focus
                        confirmDialog.focus = true;
                    }
                    onFocusChanged: container.onFocus(this)
                    //KeyNavigation.down: optRemoteScreenActivate
                }

                // "remote" screen activation (for test purpose only)
                /*ToggleOption {
                    id: optRemoteScreenActivate

                    //property to manage parameter name
                    property string parameterName : "system.screens.remote"

                    label: qsTr("Remote screens access") + api.tr
                    note: qsTr("to access screens display from any web browser") + api.tr
                    checked: api.internal.recalbox.getBoolParameter(parameterName)
                    onCheckedChanged: {
                        if(checked !== api.internal.recalbox.getBoolParameter(parameterName)){
                            api.internal.recalbox.setBoolParameter(parameterName,checked);
                        }
                    }
                    onFocusChanged: container.onFocus(this)
                }*/

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
    }

    Connections {
        target: confirmDialog.item
        function onAccept() {
            //confirm to keep same conf
            //update previousvalue with value
            //for display mode
            optDisplayMode.previousvalue = optDisplayMode.value
            optDisplayMode.previousinternalvalue = api.internal.recalbox.getStringParameter(optDisplayMode.parameterName)
            //console.log("optDisplayMode.previousvalue: ", optDisplayMode.previousvalue, "optDisplayMode.previousinternalvalue: ", optDisplayMode.previousinternalvalue)
            //for first screen (if activated)
            optPrimaryScreenActivate.previousvalue = optPrimaryScreenActivate.checked
            if(optPrimaryScreenActivate.checked){
                optDisplayOutput.previousvalue = optDisplayOutput.value
                optDisplayResolution.previousvalue = optDisplayResolution.value
                optDisplayFrequency.previousvalue = optDisplayFrequency.value
                optDisplayRotation.previousvalue = optDisplayRotation.value
                optDisplayRotation.previousinternalvalue = api.internal.recalbox.getStringParameter(optDisplayRotation.parameterName)
            }
            //for second screen (if activated)
            optSecondaryScreenActivate.previousvalue = optSecondaryScreenActivate.checked
            if(optSecondaryScreenActivate.checked){
                optDisplaySecondaryOutput.previousvalue = optDisplaySecondaryOutput.value
                optDisplaySecondaryResolution.previousvalue = optDisplaySecondaryResolution.value
                optDisplaySecondaryFrequency.previousvalue = optDisplaySecondaryFrequency.value
                optDisplaySecondaryRotation.previousvalue = optDisplaySecondaryRotation.value
                optDisplaySecondaryRotation.previousinternalvalue = api.internal.recalbox.getStringParameter(optDisplaySecondaryRotation.parameterName)
                optDisplaySecondaryPosition.previousvalue  = optDisplaySecondaryPosition.value
                optDisplaySecondaryPosition.previousinternalvalue = api.internal.recalbox.getStringParameter(optDisplaySecondaryPosition.parameterName)
            }
            content.focus = true;
        }
        function onCancel() {
            //restore previous value
            //for display mode
            api.internal.recalbox.setStringParameter(optDisplayMode.parameterName,optDisplayMode.previousinternalvalue);
            optDisplayMode.value = optDisplayMode.previousvalue;
            //for first screen (if activated)
            api.internal.recalbox.setBoolParameter(optPrimaryScreenActivate.parameterName,optPrimaryScreenActivate.previousvalue);
            optPrimaryScreenActivate.checked = optPrimaryScreenActivate.previousvalue;
            api.internal.recalbox.setStringParameter(optDisplayOutput.parameterName, optDisplayOutput.previousvalue);
            optDisplayOutput.value = optDisplayOutput.previousvalue;
            api.internal.recalbox.setStringParameter(optDisplayResolution.parameterName, optDisplayResolution.previousvalue);
            optDisplayResolution.value = optDisplayResolution.previousvalue;
            api.internal.recalbox.setStringParameter(optDisplayFrequency.parameterName, optDisplayFrequency.previousvalue);
            optDisplayFrequency.value = optDisplayFrequency.previousvalue;
            api.internal.recalbox.setStringParameter(optDisplayRotation.parameterName, optDisplayRotation.previousinternalvalue);
            optDisplayRotation.value = optDisplayRotation.previousvalue;

            //for second screen (if activated)
            api.internal.recalbox.setBoolParameter(optSecondaryScreenActivate.parameterName,optSecondaryScreenActivate.previousvalue);
            optSecondaryScreenActivate.checked = optSecondaryScreenActivate.previousvalue;
            api.internal.recalbox.setStringParameter(optDisplaySecondaryOutput.parameterName, optDisplaySecondaryOutput.previousvalue);
            optDisplaySecondaryOutput.value = optDisplaySecondaryOutput.previousvalue;
            api.internal.recalbox.setStringParameter(optDisplaySecondaryResolution.parameterName, optDisplaySecondaryResolution.previousvalue);
            optDisplaySecondaryResolution.value = optDisplaySecondaryResolution.previousvalue;
            api.internal.recalbox.setStringParameter(optDisplaySecondaryFrequency.parameterName, optDisplaySecondaryFrequency.previousvalue);
            optDisplaySecondaryFrequency.value = optDisplaySecondaryFrequency.previousvalue;
            api.internal.recalbox.setStringParameter(optDisplaySecondaryRotation.parameterName, optDisplaySecondaryRotation.previousinternalvalue);
            optDisplaySecondaryRotation.value = optDisplaySecondaryRotation.previousvalue;
            api.internal.recalbox.setStringParameter(optDisplaySecondaryPosition.parameterName, optDisplaySecondaryPosition.previousinternalvalue);
            optDisplaySecondaryPosition.value = optDisplaySecondaryPosition.previousvalue;

            //re-save conf
            api.internal.recalbox.saveParameters();
            //Execute script to restore screen openVideoSettings
            api.internal.system.runBoolResult("/usr/bin/externalscreen.sh");
            //and move pegasus-frontend in connected and primary screen
            api.internal.system.runBoolResult("WINDOWPID=$(xdotool search --class 'pegasus-frontend'); xdotool windowmove $WINDOWPID $(xrandr | grep -e ' connected' | grep -e 'primary' | awk '{print $4}' | awk -F'+' '{print $2, $3}');", false);
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
            //check if need to restart to take change into account !
            if(previousValue !== api.internal.recalbox.getStringParameter(parameterName)){
                console.log("needRestart");
                needRestart = true;
            }
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

