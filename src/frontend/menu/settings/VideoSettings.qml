
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
                    text: qsTr("Video Game Settings") + api.tr
                    first: true
                }
                MultivalueOption {
                    id: optDisplayOutput

                    //property to manage parameter name
                    property string parameterName : "system.externalscreen.prefered"
                    property variant optionsList : []
                    // set focus only on first item
                    focus: true

                    label: qsTr("Display Output") + api.tr
                    note: qsTr("Choose Display output") + api.tr
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
                    property string parameterName : "system.externalscreen.forceresolution"
                    property variant optionsList : [optDisplayOutput.value]

                    label: qsTr("Display Resolution") + api.tr
                    note: qsTr("Choose resolution for this output") + api.tr
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
                    property string parameterName : "system.externalscreen.forcefrequency"
                    property variant optionsList : [optDisplayOutput.value, optDisplayResolution.value]

                    label: qsTr("Display Frequency") + api.tr
                    note: qsTr("Choose frequency for this output") + api.tr
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
                    KeyNavigation.down: optDisplayMarqueeOutput
                    //                    KeyNavigation.down: optValidateChange
                }
                SectionTitle {
                    text: qsTr("Video Marquee Settings") + api.tr
                    first: true
                }
                MultivalueOption {
                    id: optDisplayMarqueeOutput

                    //property to manage parameter name
                    property string parameterName : "system.marqueescreen.prefered"
                    property variant optionsList : []

                    label: qsTr("Display Output") + api.tr
                    note: qsTr("Choose Display output") + api.tr
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
                    KeyNavigation.up: optDisplayFrequency
                    KeyNavigation.down: optDisplayMarqueeResolution
                }
                MultivalueOption {
                    id: optDisplayMarqueeResolution

                    //property to manage parameter name
                    property string parameterName : "system.marqueescreen.forceresolution"
                    property variant optionsList : [optDisplayMarqueeOutput.value]

                    label: qsTr("Display Resolution") + api.tr
                    note: qsTr("Choose resolution for this output") + api.tr
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
                }
                MultivalueOption {
                    id: optDisplayMarqueeFrequency

                    //property to manage parameter name
                    property string parameterName : "system.marqueescreen.forcefrequency"
                    property variant optionsList : [optDisplayMarqueeOutput.value, optDisplayMarqueeResolution.value]

                    label: qsTr("Display Frequency") + api.tr
                    note: qsTr("Choose frequency for this output") + api.tr
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
                    KeyNavigation.down: optValidateChange
                }
                SimpleButton {
                    id: optValidateChange
                    label: qsTr("Validate settings") + api.tr
                    note: qsTr("Change screen layout settings") + api.tr

                    Text {
                        id: pointeroptAdvancedEmulator
                        anchors.right: parent.right
                        anchors.verticalCenter: parent.verticalCenter

                        color: themeColor.textValue
                        font.pixelSize: vpx(30)
                        font.family: globalFonts.ion
                        text : "\uf2bc"
                    }
                    onActivate: {
                        api.internal.recalbox.saveParameters();
                        api.internal.system.runBoolResult("time /usr/bin/externalscreen.sh");
                    }
                    onFocusChanged: container.onFocus(this)
                    KeyNavigation.up: optDisplayMarqueeFrequency
                    //                    KeyNavigation.up: optDisplayFrequency
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

