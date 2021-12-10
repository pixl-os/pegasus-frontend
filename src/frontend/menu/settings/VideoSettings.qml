
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

                SectionTitle {
                    text: qsTr("Primary screen settings") + api.tr
                    first: true
                }
                MultivalueOption {
                    id: optDisplayOutput
                    //property to manage parameter name
                    property string parameterName : "system.primary.screen"
                    property variant optionsList : []
                    // set focus only on first item
                    focus: true

                    label: qsTr("Output") + api.tr
                    note: qsTr("Choose your output for primary screen.") + api.tr
                    value: api.internal.recalbox.parameterslist.currentNameFromSystem(parameterName,"cat /tmp/xrandr.tmp | awk '$2 ~ \"connected\"{print $1}'",optionsList)
                    font: globalFonts.ion

                    onActivate: {
                        //for callback by parameterslistBox
                        parameterslistBox.parameterName = parameterName;
                        parameterslistBox.callerid = optDisplayOutput;
                        //to force update of list of parameters
                        api.internal.recalbox.parameterslist.currentNameFromSystem(parameterName,"cat /tmp/xrandr.tmp | awk '$2 == \"connected\"{print $1}'",optionsList);
                        parameterslistBox.model = api.internal.recalbox.parameterslist;
                        parameterslistBox.index = api.internal.recalbox.parameterslist.currentIndex;
                        //to transfer focus to parameterslistBox
                        parameterslistBox.focus = true;
                    }
                    onFocusChanged: container.onFocus(this)
                    KeyNavigation.down: optDisplayResolution
                }
                MultivalueOption {
                    id: optDisplayResolution
                    //property to manage parameter name
                    property string parameterName : "system.primary.screen.resolution"
                    property variant optionsList : [optDisplayOutput.value]

                    label: qsTr("Resolution") + api.tr
                    note: qsTr("Choose resolution for your primary screen.") + api.tr
                    value: api.internal.recalbox.parameterslist.currentNameFromSystem(parameterName,"cat /tmp/xrandr.tmp | awk -v monitor=\"^%1 connected\" '/connected/ {p = 0} $0 ~ monitor {p = 1} p' | awk '{if(NR>1)print $1}'",optionsList)
                    font: globalFonts.ion

                    onActivate: {
                        //for callback by parameterslistBox
                        parameterslistBox.parameterName = parameterName;
                        parameterslistBox.callerid = optDisplayResolution;
                        //to force update of list of parameters
                        api.internal.recalbox.parameterslist.currentNameFromSystem(parameterName,"cat /tmp/xrandr.tmp | awk -v monitor=\"^%1 connected\" '/connected/ {p = 0} $0 ~ monitor {p = 1} p' | awk '{if(NR>1)print $1}'",optionsList);
                        parameterslistBox.model = api.internal.recalbox.parameterslist;
                        parameterslistBox.index = api.internal.recalbox.parameterslist.currentIndex;
                        //to transfer focus to parameterslistBox
                        parameterslistBox.focus = true;
                    }
                    onFocusChanged: container.onFocus(this)
                    KeyNavigation.up: optDisplayOutput
                    KeyNavigation.down: optDisplayFrequency
                }
                MultivalueOption {
                    id: optDisplayFrequency
                    //property to manage parameter name
                    property string parameterName : "system.primary.screen.frequency"
                    property variant optionsList : [optDisplayOutput.value, optDisplayResolution.value]

                    label: qsTr("Frequency") + api.tr
                    note: qsTr("Choose frequency for your primary screen.") + api.tr
                    value: api.internal.recalbox.parameterslist.currentNameFromSystem(parameterName,"cat /tmp/xrandr.tmp | awk -v monitor=\"^%1 connected\" '/connected/ {p = 0} $0 ~ monitor {p = 1} p' | awk '{if(NR>1) print}' | awk '$1 == \"%2\" {print}' | awk '{for (i=2; i<=NF; i++) print $i}' | tr -d '+*'",optionsList)
                    font: globalFonts.ion

                    onActivate: {
                        //for callback by parameterslistBox
                        parameterslistBox.parameterName = parameterName;
                        parameterslistBox.callerid = optDisplayFrequency;
                        //to force update of list of parameters
                        api.internal.recalbox.parameterslist.currentNameFromSystem(parameterName,"cat /tmp/xrandr.tmp | awk -v monitor=\"^%1 connected\" '/connected/ {p = 0} $0 ~ monitor {p = 1} p' | awk '{if(NR>1) print}' | awk '$1 == \"%2\" {print}' | awk '{for (i=2; i<=NF; i++) print $i}' | tr -d '+*'",optionsList)
                        parameterslistBox.model = api.internal.recalbox.parameterslist;
                        parameterslistBox.index = api.internal.recalbox.parameterslist.currentIndex;
                        //to transfer focus to parameterslistBox
                        parameterslistBox.focus = true;
                    }
                    onFocusChanged: container.onFocus(this)
                    KeyNavigation.up: optDisplayResolution
                    KeyNavigation.down: optDisplayRotation
                }
                MultivalueOption {
                    id: optDisplayRotation
                    //property to manage parameter name
                    property string parameterName : "system.primary.screen.rotation"

                    label: qsTr("Rotate") + api.tr
                    note: qsTr("Choose orientation for your primary screen.") + api.tr
                    value: api.internal.recalbox.parameterslist.currentName(parameterName)
                    font: globalFonts.ion

                    onActivate: {
                        //for callback by parameterslistBox
                        parameterslistBox.parameterName = parameterName;
                        parameterslistBox.callerid = optDisplayRotation;
                        //to force update of list of parameters
                        api.internal.recalbox.parameterslist.currentName(parameterName);
                        parameterslistBox.model = api.internal.recalbox.parameterslist;
                        parameterslistBox.index = api.internal.recalbox.parameterslist.currentIndex;
                        //to transfer focus to parameterslistBox
                        parameterslistBox.focus = true;
                    }
                    onFocusChanged: container.onFocus(this)
                    KeyNavigation.up: optDisplayFrequency
                    KeyNavigation.down: optMarqueeScreenActivate
                }
                // second screen marque or else
                ToggleOption {
                    id: optMarqueeScreenActivate
                    SectionTitle {
                        text: qsTr("Secondary screen settings") + api.tr
                        first: true
                    }
                    // label: qsTr("Activate secondary screen") + api.tr
                    // note: qsTr("Secondary screen for marquee or else.") + api.tr
                    checked: api.internal.recalbox.getBoolParameter("system.secondary.screen.enabled")
                    onCheckedChanged: {
                        api.internal.recalbox.setBoolParameter("system.secondary.screen.enabled",checked);
                    }
                    onFocusChanged: container.onFocus(this)
                    KeyNavigation.up: optDisplayRotation
                    KeyNavigation.down: optDisplayMarqueeOutput
                }
                MultivalueOption {
                    id: optDisplayMarqueeOutput
                    //property to manage parameter name
                    property string parameterName : "system.secondary.screen"
                    property variant optionsList : []

                    label: qsTr("Output") + api.tr
                    note: qsTr("Choose your output for secondary screen.") + api.tr
                    value: api.internal.recalbox.parameterslist.currentNameFromSystem(parameterName,"cat /tmp/xrandr.tmp | awk '$2 ~ \"connected\"{print $1}'",optionsList)
                    font: globalFonts.ion

                    onActivate: {
                        //for callback by parameterslistBox
                        parameterslistBox.parameterName = parameterName;
                        parameterslistBox.callerid = optDisplayMarqueeOutput;
                        //to force update of list of parameters
                        api.internal.recalbox.parameterslist.currentNameFromSystem(parameterName,"cat /tmp/xrandr.tmp | awk '$2 == \"connected\"{print $1}'",optionsList);
                        parameterslistBox.model = api.internal.recalbox.parameterslist;
                        parameterslistBox.index = api.internal.recalbox.parameterslist.currentIndex;
                        //to transfer focus to parameterslistBox
                        parameterslistBox.focus = true;
                    }
                    onFocusChanged: container.onFocus(this)
                    KeyNavigation.up: optMarqueeScreenActivate
                    KeyNavigation.down: optDisplayMarqueeResolution
                    // only show if video marquee option as enabled
                    visible: optMarqueeScreenActivate.checked
                }
                MultivalueOption {
                    id: optDisplayMarqueeResolution
                    //property to manage parameter name
                    property string parameterName : "system.secondary.screen.resolution"
                    property variant optionsList : [optDisplayMarqueeOutput.value]

                    label: qsTr("Resolution") + api.tr
                    note: qsTr("Choose resolution for secondary screen.") + api.tr
                    value: api.internal.recalbox.parameterslist.currentNameFromSystem(parameterName,"cat /tmp/xrandr.tmp | awk -v monitor=\"^%1 connected\" '/connected/ {p = 0} $0 ~ monitor {p = 1} p' | awk '{if(NR>1)print $1}'",optionsList)
                    font: globalFonts.ion

                    onActivate: {
                        //for callback by parameterslistBox
                        parameterslistBox.parameterName = parameterName;
                        parameterslistBox.callerid = optDisplayMarqueeResolution;
                        //to force update of list of parameters
                        api.internal.recalbox.parameterslist.currentNameFromSystem(parameterName,"cat /tmp/xrandr.tmp | awk -v monitor=\"^%1 connected\" '/connected/ {p = 0} $0 ~ monitor {p = 1} p' | awk '{if(NR>1)print $1}'",optionsList);
                        parameterslistBox.model = api.internal.recalbox.parameterslist;
                        parameterslistBox.index = api.internal.recalbox.parameterslist.currentIndex;
                        //to transfer focus to parameterslistBox
                        parameterslistBox.focus = true;
                    }
                    onFocusChanged: container.onFocus(this)
                    KeyNavigation.up: optDisplayMarqueeOutput
                    KeyNavigation.down: optDisplayMarqueeFrequency
                    // only show if video marquee option as enabled
                    visible: optMarqueeScreenActivate.checked
                }
                MultivalueOption {
                    id: optDisplayMarqueeFrequency
                    //property to manage parameter name
                    property string parameterName : "system.secondary.screen.frequency"
                    property variant optionsList : [optDisplayMarqueeOutput.value, optDisplayMarqueeResolution.value]

                    label: qsTr("Frequency") + api.tr
                    note: qsTr("Choose frequency for secondary screen.") + api.tr
                    value: api.internal.recalbox.parameterslist.currentNameFromSystem(parameterName,"cat /tmp/xrandr.tmp | awk -v monitor=\"^%1 connected\" '/connected/ {p = 0} $0 ~ monitor {p = 1} p' | awk '{if(NR>1) print}' | awk '$1 == \"%2\" {print}' | awk '{for (i=2; i<=NF; i++) print $i}' | tr -d '+*'",optionsList)
                    font: globalFonts.ion

                    onActivate: {
                        //for callback by parameterslistBox
                        parameterslistBox.parameterName = parameterName;
                        parameterslistBox.callerid = optDisplayMarqueeFrequency;
                        //to force update of list of parameters
                        api.internal.recalbox.parameterslist.currentNameFromSystem(parameterName,"cat /tmp/xrandr.tmp | awk -v monitor=\"^%1 connected\" '/connected/ {p = 0} $0 ~ monitor {p = 1} p' | awk '{if(NR>1) print}' | awk '$1 == \"%2\" {print}' | awk '{for (i=2; i<=NF; i++) print $i}' | tr -d '+*'",optionsList)
                        parameterslistBox.model = api.internal.recalbox.parameterslist;
                        parameterslistBox.index = api.internal.recalbox.parameterslist.currentIndex;
                        //to transfer focus to parameterslistBox
                        parameterslistBox.focus = true;
                    }
                    onFocusChanged: container.onFocus(this)
                    KeyNavigation.up: optDisplayMarqueeResolution
                    KeyNavigation.down: optDisplayMarqueeRotation
                    // only show if video marquee option as enabled
                    visible: optMarqueeScreenActivate.checked
                }
                MultivalueOption {
                    id: optDisplayMarqueeRotation
                    //property to manage parameter name
                    property string parameterName : "system.secondary.screen.rotation"

                    label: qsTr("Rotation") + api.tr
                    note: qsTr("Choose orientation for your secondary screen.") + api.tr
                    value: api.internal.recalbox.parameterslist.currentName(parameterName)
                    font: globalFonts.ion

                    onActivate: {
                        //for callback by parameterslistBox
                        parameterslistBox.parameterName = parameterName;
                        parameterslistBox.callerid = optDisplayMarqueeRotation;
                        //to force update of list of parameters
                        api.internal.recalbox.parameterslist.currentName(parameterName);
                        parameterslistBox.model = api.internal.recalbox.parameterslist;
                        parameterslistBox.index = api.internal.recalbox.parameterslist.currentIndex;
                        //to transfer focus to parameterslistBox
                        parameterslistBox.focus = true;
                    }
                    onFocusChanged: container.onFocus(this)
                    KeyNavigation.up: optDisplayMarqueeFrequency
                    KeyNavigation.down: optDisplayMarqueePosition
                    // only show if video marquee option as enabled
                    visible: optMarqueeScreenActivate.checked
                }
                MultivalueOption {
                    id: optDisplayMarqueePosition
                    //property to manage parameter name
                    property string parameterName : "system.secondary.screen.position"

                    label: qsTr("Position") + api.tr
                    note: qsTr("Choose position for your Secondary screen.") + api.tr
                    value: api.internal.recalbox.parameterslist.currentName(parameterName)
                    font: globalFonts.ion

                    onActivate: {
                        //for callback by parameterslistBox
                        parameterslistBox.parameterName = parameterName;
                        parameterslistBox.callerid = optDisplayMarqueePosition;
                        //to force update of list of parameters
                        api.internal.recalbox.parameterslist.currentName(parameterName)
                        parameterslistBox.model = api.internal.recalbox.parameterslist;
                        parameterslistBox.index = api.internal.recalbox.parameterslist.currentIndex;
                        //to transfer focus to parameterslistBox
                        parameterslistBox.focus = true;
                    }
                    onFocusChanged: container.onFocus(this)
                    KeyNavigation.up: optDisplayMarqueeRotation
                    KeyNavigation.down: optValidateChange
                    // only show if video marquee option as enabled
                    visible: optMarqueeScreenActivate.checked
                }
                // second screen marque or else
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
                        api.internal.recalbox.saveParameters();
                        api.internal.system.runBoolResult("/usr/bin/externalscreen.sh");
                    }
                    onFocusChanged: container.onFocus(this)
                    KeyNavigation.up: optDisplayMarqueePosition
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
    MultivalueBox {
        id: localeBox
        z: 3

        model: api.internal.settings.locales
        index: api.internal.settings.locales.currentIndex

        onClose: content.focus = true
        onSelect: {
            api.internal.settings.locales.currentIndex = index;
            /* Set recalbox settings on same time */
            api.internal.recalbox.parameterslist.currentIndex = index;
        }
    }
    MultivalueBox {
        id: themeBox
        z: 3

        model: api.internal.settings.themes
        index: api.internal.settings.themes.currentIndex

        onClose: content.focus = true
        onSelect: api.internal.settings.themes.currentIndex = index
    }
}

