// Pegasus Frontend
//
// Created by Bozo 26/08/2026
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

//    anchors.fill: parent
    visible: 0 < (x + width) && x < Window.window.width

    enabled: focus

    property bool launchedAsDialogBox: false

    property var game
    property var system
    //to manage overloading
    property string prefix : game ? "override" :
                             (system ? system.shortName : "global")
    //to manage better title in screen ScreenHeader (if we want to change it during loading)
    property string titleHeader : game ? game.title +  " > Scraper settings" :
                                  (system ? system.name + "> Scraper settings" :
                                   qsTr("Games > Scraper settings") + api.tr)


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
        text: titleHeader
        z: 2
    }

    clip: launchedAsDialogBox

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

                width: launchedAsDialogBox ? root.width * 0.9 : root.width * 0.7
                height: implicitHeight

                Item {
                    width: parent.width
                    height: implicitHeight + vpx(30)
                }
                SectionTitle {
                    text: qsTr("Scraping source") + api.tr
                    first: true
                    symbol: "\uf17f"
                }
                MultivalueOption {
                    id: optScraperSource

                    // set focus only on first item
                    focus: true

                    internalvalue: "screenscraper"
                    value: "ScreenScraper"
                    property string parameterName: prefix + ".scraper.source"
                    label: qsTr("from") + api.tr
                    note: qsTr("select your prefered scrapping source") + api.tr
                    onFocusChanged: container.onFocus(this)
                    KeyNavigation.down: optScraperImage
                }
                SectionTitle {
                    text: qsTr("Primary Scraping Media") + api.tr
                    first: true
                    symbol: "\uf17f"
                }

                //TO DO:
                // add more info as preview: ""; size: ""; type: "" (as arcade, cd, cartridge, etc...)
                ListModel {
                    id: imageModel
                    ListElement { name: qsTr("Game Screenshot"); internal: "screenshot"}
                    ListElement { name: qsTr("Title Screenshot"); internal: "screenshottitle"}
                    ListElement { name: qsTr("2D Box"); internal: "box2d"}
                    ListElement { name: qsTr("3D Box"); internal: "bod3d"}
                    ListElement { name: qsTr("Support"); internal: "support"}
                    ListElement { name: qsTr("Images Mix (V1)"); internal: "mixv1"}
                    ListElement { name: qsTr("Images Mix (V2)"); internal: "mixv2"}
                    ListElement { name: qsTr("2 Images Mix"); internal: "2mix"}
                    ListElement { name: qsTr("3 Images Mix"); internal: "3mix"}
                    ListElement { name: qsTr("4 Images Mix"); internal: "4mix"}
                    ListElement { name: qsTr("5 Images Mix"); internal: "5mix"}
                }

                ListModel {
                    id: wheelModel
                    ListElement { name: qsTr("No Wheel"); internal: "nowheel"}
                    ListElement { name: qsTr("Wheel"); internal: "wheel"}
                    ListElement { name: qsTr("Carbon Wheel"); internal: "carbonwheel"}
                    ListElement { name: qsTr("Steel Wheel"); internal: "steelwheel"}
                }

                ListModel {
                    id: marqueeModel
                    ListElement { name: qsTr("No Marquee"); internal: "nomarquee"}
                    ListElement { name: qsTr("Arcade Marquee"); internal: "arcademarquee"}
                    ListElement { name: qsTr("Screen Marquee"); internal: "screenmarquee"}
                    ListElement { name: qsTr("Small Screen Marquee"); internal: "smallmarquee"}
                    ListElement { name: qsTr("Steam Grid"); internal: "steamgrid"}
                }

                ListModel {
                    id: videoModel
                    ListElement { name: qsTr("No Video"); internal: "novideo"}
                    ListElement { name: qsTr("Video"); internal: "video"}
                    ListElement { name: qsTr("Normalized Video"); internal: "normalizedvideo"}
                }

                MultivalueOption {
                    id: optScraperImage

                    //property to manage parameter name
                    property string parameterName: prefix + ".scraper.image";

                    label: qsTr("'Image' scraped") + api.tr
                    note: qsTr("Media scraped for <image> tag") + api.tr

                    internalvalue: api.internal.recalbox.getStringParameter(parameterName, "box3d")

                    count: imageModel.count

                    font: globalFonts.awesome

                    onActivate: {
                        if(visible){
                            //for callback by parameterslistBox
                            parameterslistBox.parameterName = parameterName;
                            parameterslistBox.callerid = optScraperImage;
                            //to force update of list of parameters
                            parameterslistBox.model = imageModel;
                            parameterslistBox.index = currentIndex;
                            //to transfer focus to parameterslistBox
                            parameterslistBox.focus = true;
                        }
                    }

                    onSelect: {
                        if(visible){
                            value = imageModel.get(index).name;
                            internalvalue = imageModel.get(index).internal;
                        }
                    }

                    onInternalvalueChanged: {
                        if(visible){
                            if(api.internal.recalbox.getStringParameter(parameterName) !==  internalvalue || !value){
                                //only write override .conf file if any value change
                                api.internal.recalbox.setStringParameter(parameterName, internalvalue)
                                for(var i=0; i < imageModel.count; i++){
                                    //console.log("MultivalueOption currentIndex : ",i);
                                    //console.log("modelData.options.get(i).name : ",options.get(i).name);
                                    //console.log("modelData.options.get(i).internal : ",options.get(i).internal);
                                    //console.log("value : ",value);
                                    //console.log("internalvalue : ",internalvalue);
                                    if(imageModel.get(i).internal === internalvalue){
                                        value = imageModel.get(i).name;
                                        currentIndex = i;
                                    }
                                }
                            }
                        }
                    }

                    onFocusChanged: container.onFocus(this)
                    KeyNavigation.down: optScraperThumbnail
                }

                MultivalueOption {
                    id: optScraperThumbnail

                    //property to manage parameter name
                    property string parameterName: prefix + ".scraper.thumbnail";

                    label: qsTr("'Thumbnail' scraped") + api.tr
                    note: qsTr("Media scraped for <thumbnail> tag") + api.tr

                    internalvalue: api.internal.recalbox.getStringParameter(parameterName, "screenshot")

                    count: imageModel.count

                    font: globalFonts.awesome

                    onActivate: {
                        if(visible){
                            //for callback by parameterslistBox
                            parameterslistBox.parameterName = parameterName;
                            parameterslistBox.callerid = optScraperThumbnail;
                            //to force update of list of parameters
                            parameterslistBox.model = imageModel;
                            parameterslistBox.index = currentIndex;
                            //to transfer focus to parameterslistBox
                            parameterslistBox.focus = true;
                        }
                    }

                    onSelect: {
                        if(visible){
                            value = imageModel.get(index).name;
                            internalvalue = imageModel.get(index).internal;
                        }
                    }

                    onInternalvalueChanged: {
                        if(visible){
                            if(api.internal.recalbox.getStringParameter(parameterName) !==  internalvalue || !value){
                                //only write override .conf file if any value change
                                api.internal.recalbox.setStringParameter(parameterName, internalvalue)
                                for(var i=0; i < imageModel.count; i++){
                                    //console.log("MultivalueOption currentIndex : ",i);
                                    //console.log("modelData.options.get(i).name : ",options.get(i).name);
                                    //console.log("modelData.options.get(i).internal : ",options.get(i).internal);
                                    //console.log("value : ",value);
                                    //console.log("internalvalue : ",internalvalue);
                                    if(imageModel.get(i).internal === internalvalue){
                                        value = imageModel.get(i).name;
                                        currentIndex = i;
                                    }
                                }
                            }
                        }
                    }

                    onFocusChanged: container.onFocus(this)
                    KeyNavigation.down: optScraperWheel
                }

                MultivalueOption {
                    id: optScraperWheel

                    //property to manage parameter name
                    property string parameterName: prefix + ".scraper.wheel";

                    label: qsTr("Wheel scraped") + api.tr
                    note: qsTr("Media scraped for <wheel> tag") + api.tr

                    internalvalue: api.internal.recalbox.getStringParameter(parameterName, "wheel")

                    count: wheelModel.count

                    font: globalFonts.awesome

                    onActivate: {
                        if(visible){
                            //for callback by parameterslistBox
                            parameterslistBox.parameterName = parameterName;
                            parameterslistBox.callerid = optScraperWheel;
                            //to force update of list of parameters
                            parameterslistBox.model = wheelModel;
                            parameterslistBox.index = currentIndex;
                            //to transfer focus to parameterslistBox
                            parameterslistBox.focus = true;
                        }
                    }

                    onSelect: {
                        if(visible){
                            value = wheelModel.get(index).name;
                            internalvalue = wheelModel.get(index).internal;
                        }
                    }

                    onInternalvalueChanged: {
                        if(visible){
                            if(api.internal.recalbox.getStringParameter(parameterName) !==  internalvalue || !value){
                                //only write override .conf file if any value change
                                api.internal.recalbox.setStringParameter(parameterName, internalvalue)
                                for(var i=0; i < wheelModel.count; i++){
                                    //console.log("MultivalueOption currentIndex : ",i);
                                    //console.log("modelData.options.get(i).name : ",options.get(i).name);
                                    //console.log("modelData.options.get(i).internal : ",options.get(i).internal);
                                    //console.log("value : ",value);
                                    //console.log("internalvalue : ",internalvalue);
                                    if(wheelModel.get(i).internal === internalvalue){
                                        value = wheelModel.get(i).name;
                                        currentIndex = i;
                                    }
                                }
                            }
                        }
                    }

                    onFocusChanged: container.onFocus(this)
                    KeyNavigation.down: optScraperVideo
                }

                MultivalueOption {
                    id: optScraperVideo

                    //property to manage parameter name
                    property string parameterName: prefix + ".scraper.video";

                    label: qsTr("Video scraped") + api.tr
                    note: qsTr("Media scraped for <video> tag") + api.tr

                    internalvalue: api.internal.recalbox.getStringParameter(parameterName, "novideo")

                    count: videoModel.count

                    font: globalFonts.awesome

                    onActivate: {
                        if(visible){
                            //for callback by parameterslistBox
                            parameterslistBox.parameterName = parameterName;
                            parameterslistBox.callerid = optScraperVideo;
                            //to force update of list of parameters
                            parameterslistBox.model = videoModel;
                            parameterslistBox.index = currentIndex;
                            //to transfer focus to parameterslistBox
                            parameterslistBox.focus = true;
                        }
                    }

                    onSelect: {
                        if(visible){
                            value = videoModel.get(index).name;
                            internalvalue = videoModel.get(index).internal;
                        }
                    }

                    onInternalvalueChanged: {
                        if(visible){
                            if(api.internal.recalbox.getStringParameter(parameterName) !==  internalvalue || !value){
                                //only write override .conf file if any value change
                                api.internal.recalbox.setStringParameter(parameterName, internalvalue)
                                for(var i=0; i < videoModel.count; i++){
                                    //console.log("MultivalueOption currentIndex : ",i);
                                    //console.log("modelData.options.get(i).name : ",options.get(i).name);
                                    //console.log("modelData.options.get(i).internal : ",options.get(i).internal);
                                    //console.log("value : ",value);
                                    //console.log("internalvalue : ",internalvalue);
                                    if(videoModel.get(i).internal === internalvalue){
                                        value = videoModel.get(i).name;
                                        currentIndex = i;
                                    }
                                }
                            }
                        }
                    }

                    onFocusChanged: container.onFocus(this)
                    KeyNavigation.down: optScraperMarquee
                }

                MultivalueOption {
                    id: optScraperMarquee

                    //property to manage parameter name
                    property string parameterName: prefix + ".scraper.wheel";

                    label: qsTr("Marquee scraped") + api.tr
                    note: qsTr("Media scraped for <marquee> tag") + api.tr

                    internalvalue: api.internal.recalbox.getStringParameter(parameterName, "nomarqee")

                    count: wheelModel.count

                    font: globalFonts.awesome

                    onActivate: {
                        if(visible){
                            //for callback by parameterslistBox
                            parameterslistBox.parameterName = parameterName;
                            parameterslistBox.callerid = optScraperMarquee;
                            //to force update of list of parameters
                            parameterslistBox.model = marqueeModel;
                            parameterslistBox.index = currentIndex;
                            //to transfer focus to parameterslistBox
                            parameterslistBox.focus = true;
                        }
                    }

                    onSelect: {
                        if(visible){
                            value = marqueeModel.get(index).name;
                            internalvalue = marqueeModel.get(index).internal;
                        }
                    }

                    onInternalvalueChanged: {
                        if(visible){
                            if(api.internal.recalbox.getStringParameter(parameterName) !==  internalvalue || !value){
                                //only write override .conf file if any value change
                                api.internal.recalbox.setStringParameter(parameterName, internalvalue)
                                for(var i=0; i < marqueeModel.count; i++){
                                    //console.log("MultivalueOption currentIndex : ",i);
                                    //console.log("modelData.options.get(i).name : ",options.get(i).name);
                                    //console.log("modelData.options.get(i).internal : ",options.get(i).internal);
                                    //console.log("value : ",value);
                                    //console.log("internalvalue : ",internalvalue);
                                    if(marqueeModel.get(i).internal === internalvalue){
                                        value = marqueeModel.get(i).name;
                                        currentIndex = i;
                                    }
                                }
                            }
                        }
                    }

                    onFocusChanged: container.onFocus(this)
                    KeyNavigation.down: optScraperManual
                }

                SectionTitle {
                    text: qsTr("Additional Scraping Media") + api.tr
                    first: true
                    symbol: "\uf17f"
                }
                ToggleOption {
                    id: optScraperManual

                    label: qsTr("Manual") + api.tr
                    note: qsTr("Once enabled, pixL will scrap manual also") + api.tr

                    checked: api.internal.recalbox.getBoolParameter(prefix + ".scraper.manual", false)
                    onCheckedChanged: {
                        api.internal.recalbox.setBoolParameter(prefix + ".scraper.video",checked);
                    }
                    onFocusChanged: container.onFocus(this)
                    KeyNavigation.down: optScraperMap
                }
                ToggleOption {
                    id: optScraperMap

                    label: qsTr("Map") + api.tr
                    note: qsTr("Once enabled, pixL will scrap map also") + api.tr

                    checked: api.internal.recalbox.getBoolParameter(prefix + ".scraper.map", false)
                    onCheckedChanged: {
                        api.internal.recalbox.setBoolParameter(prefix + ".scraper.map",checked);
                    }
                    onFocusChanged: container.onFocus(this)
                    KeyNavigation.down: optScraperTips
                }
                ToggleOption {
                    id: optScraperTips

                    label: qsTr("Tips") + api.tr
                    note: qsTr("Once enabled, pixL will scrap tips also") + api.tr

                    checked: api.internal.recalbox.getBoolParameter(prefix + ".scraper.tips", false)
                    onCheckedChanged: {
                        api.internal.recalbox.setBoolParameter(prefix + ".scraper.tips",checked);
                    }
                    onFocusChanged: container.onFocus(this)
                    KeyNavigation.down: optScraperP2K
                }
                ToggleOption {
                    id: optScraperP2K

                    label: qsTr("Pad to Keys") + api.tr
                    note: qsTr("Once enabled, pixL will scrap pad to keys parameters also") + api.tr

                    checked: api.internal.recalbox.getBoolParameter(prefix + ".scraper.p2k", false)
                    onCheckedChanged: {
                        api.internal.recalbox.setBoolParameter(prefix + ".scraper.p2k",checked);
                    }
                    onFocusChanged: container.onFocus(this)
                    KeyNavigation.down: optScraperOverlay
                }
                ToggleOption {
                    id: optScraperOverlay

                    label: qsTr("16/9 Overlay") + api.tr
                    note: qsTr("Once enabled, pixL will scrap 16/9 overlay also") + api.tr

                    checked: api.internal.recalbox.getBoolParameter(prefix + ".scraper.overlay", false)
                    onCheckedChanged: {
                        api.internal.recalbox.setBoolParameter(prefix + ".scraper.overlay",checked);
                    }
                    onFocusChanged: container.onFocus(this)
                    //KeyNavigation.down: optScraperTips
                }
                Item {
                    width: parent.width
                    height: launchedAsDialogBox ? implicitHeight + vpx(50) : implicitHeight + vpx(30)
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

        //to use index from parameterlist QAbstractList
        //index: callerid.currentIndex
        //reuse same model
        //model: callerid.modelData.options
        onClose: content.focus = true
        onSelect: {
            callerid.keypressed = true;
            callerid.currentIndex = index;
            callerid.value = model.get(index).name;
            callerid.internalvalue = model.get(index).internal;
        }
    }

    Item {
        id: footer
        width: parent.width
        height: vpx(50)
        anchors.bottom: parent.bottom
        z:2
        visible: launchedAsDialogBox

        //Rectangle for the transparent background
        Rectangle {
            anchors.fill: parent
            color: themeColor.screenHeader
            opacity: 0.75
        }

        //rectangle for the gray line
        Rectangle {
            width: parent.width * 0.97
            height: vpx(1)
            color: "#777"
            anchors.top: parent.top
            anchors.horizontalCenter: parent.horizontalCenter
        }

        //for the help to exit
        Rectangle {
            id: backButtonIcon
            height: labelB.height
            width: height
            radius: width * 0.5
            border { color: "#777"; width: vpx(1) }
            color: "transparent"
            visible: {
                return true;
            }

            anchors {
                right: labelB.left
                verticalCenter: parent.verticalCenter
                verticalCenterOffset: vpx(1)
                margins: vpx(10)
            }
            Text {
                text: "B"
                color: "#777"
                font {
                    family: global.fonts.sans
                    pixelSize: parent.height * 0.7
                }
                anchors.centerIn: parent
            }
        }

        Text {
            id: labelB
            text: qsTr("Back") + api.tr
            verticalAlignment: Text.AlignTop
            visible: {
                return true;
            }

            color: "#777"
            font {
                family: global.fonts.sans
                pixelSize: vpx(22)
                capitalization: Font.SmallCaps
            }
            anchors {
                verticalCenter: parent.verticalCenter
                verticalCenterOffset: vpx(-1)
                right: parent.right; rightMargin: parent.width * 0.015
            }
        }
    }
}
