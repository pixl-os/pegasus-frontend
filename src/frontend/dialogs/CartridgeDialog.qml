// Pegasus Frontend
// created by BozoTheGeek 20/08/2024

import QtQuick 2.12
import "../search"

FocusScope {
    id: root

    property alias message: messageText.text
    property alias symbol: symbolText.text
    property alias firstchoice: okButtonText.text
    property alias secondchoice: secondButtonText.text
    property alias thirdchoice: cancelButtonText.text

    //game info
    property string game_system: ""
    property string game_name: ""
    property string game_region: ""
    property string game_licence: ""
    property string game_picture: ""
    //to manage max for search (could be tune from experience)
    readonly property int iNB_RESULTS_MAX : 50

    property int textSize: vpx(18)
    property int titleTextSize: vpx(20)

    signal accept()
    signal secondChoice()
    signal cancel()

    //list model to manage icons of devices
    ListModel {
        id: mySystemIcons

        //ListElement { icon: "\uf275"; system: "psx"; picture:"qrc:/frontend/assets/project-cd/retroarch-cd-psx.png"}
        //ListElement { icon: "\uf26e"; system: "dreamcast"; picture:"qrc:/frontend/assets/project-cd/retroarch-cd-dreamcast.png"}
        //ListElement { icon: "\uf26b"; system: "segacd"; picture:"qrc:/frontend/assets/project-cd/retroarch-cd-segacd.png"}
        //ListElement { icon: "\uf271"; system: "pcenginecd"; picture:"qrc:/frontend/assets/project-cd/retroarch-cd-pcenginecd.png"}
        //ListElement { icon: "\uf28d"; system: "3do"; picture:"qrc:/frontend/assets/project-cd/retroarch-cd-3do.png"}
        //ListElement { icon: "\uf26c"; system: "saturn"; picture:"qrc:/frontend/assets/project-cd/retroarch-cd-saturn.png"}
        ListElement { icon: "\uf25c"; system: "nes"; picture:"qrc:/frontend/assets/cartridge/nes_cartridge.png"}
    }

    SearchGame {
        id: searchByName;
        property bool titleMatched : false
        property int resultIndex: -1
        activated: false

        onMaxChanged:{
            console.log("onMaxChanged - enabled :",searchByName.enabled);
            console.log("onMaxChanged - activated :",searchByName.activated);
            console.log("onMaxChanged - max :",searchByName.max);
            //console.log("onMaxChanged - game_crc :",game_crc);
            console.log("onMaxChanged - game_name :",game_name);
            console.log("onMaxChanged - crc :",searchByName.crc);
            console.log("onMaxChanged - crcToFind :",searchByName.crcToFind);
            console.log("onMaxChanged - filename :",searchByName.filename);
            console.log("onMaxChanged - filenameRegEx :",searchByName.filenameRegEx);
            console.log("onMaxChanged - filenameToFilter :",searchByName.filenameToFilter);
            console.log("onMaxChanged - system :",searchByName.system);
            console.log("onMaxChanged - sytemToFind :",searchByName.systemToFilter);
            console.log("onMaxChanged - filter :",searchByName.filter);
            console.log("onMaxChanged - titleToFilter :",searchByName.titleToFilter);
            console.log("onMaxChanged - region :",searchByName.region);
            console.log("onMaxChanged - regionToFilter :",searchByName.regionToFilter);

            //init before
            //picture = "";
            //icon2 = "";
            searchByName.titleMatched = false;

            if((game_system === "") || (game_name === "") || (activated === false)) {
                //do nothing to go quickly when it's not significant to proceed
            }
            //parse only nb_results_max to avoid saturation of system if not found
            else if (searchByName.max >= 1 && searchByName.max <= iNB_RESULTS_MAX) { //Title search and match
                //init index
                searchByName.resultIndex = -1;
                //check if found by title
                if(searchByName.titleMatched !== true){
                    for(var j = 0;(j < searchByName.result.games.count) && (j < iNB_RESULTS_MAX);j++)
                    {
                        console.log("game title found:",result.games.get(j).title);
                        console.log("game name to find:",game_name);

                        if(result.games.get(j).title.includes(game_name)){
                            searchByName.resultIndex = j;
                            searchByName.titleMatched = true;
                            break;
                        }
                    }
                    //if we don't match exactly, we will take the first one
                    if(searchByName.resultIndex === -1) {
                        searchByName.resultIndex = 0;
                    }
                }
                console.log("game found/selected !!!");
                //console.log("searchByName.resultIndex : ", searchByName.resultIndex);
                //console.log("result.games.get(searchByName.resultIndex).title : ", result.games.get(searchByName.resultIndex).title)
                game_picture = cartArt(result.games.get(searchByName.resultIndex));
                console.log("game picture found: ", game_picture)
                //start animation
                animation.running = true;
                //play sound if available
                //TO DO
            }
        }
    }

    //provide cartArt
    function cartArt(data) {
        if (data !== null) {
            if (data.assets.cartridge !== "")
            return data.assets.cartridge;
            if (data.assets.boxFront !== "")
            return data.assets.boxFront;
            //else if (data.assets.image !== "")
            //return data.assets.image;
        }
        return "";
    }

    //function to get icon from system
    function getIcon(mySystem){
        let icon = "";
        let i = 0;
        //search Icon using the good system
        do{
            if (mySystem.includes(mySystemIcons.get(i).system)){
                    icon = mySystemIcons.get(i).icon;
            }
            i = i + 1;
        }while (icon === "" && i < mySystemIcons.count)
        return icon;
    }

    //function to get CD picture from system
    function getPicture(mySystem){
        let picture = "";
        let i = 0;
        //search Picture using the good system
        do{
            if (mySystem.includes(mySystemIcons.get(i).system)){
                    picture = mySystemIcons.get(i).picture;
            }
            i = i + 1;
        }while (picture === "" && i < mySystemIcons.count)
        return picture;
    }

    anchors.fill: parent
    visible: shade.opacity > 0

    focus: true
    onActiveFocusChanged: {
        state = activeFocus ? "open" : "";
        if (activeFocus){
            cancelButton.focus = true;
            //start search after focus
            //check if both are not empty as deleted one
            if(game_name !== "" && game_system !== ""){
                //deactivate during setup of search
                searchByName.activated = false;
                //we search by name and we clean it before if needed
                var regex = RegExp("[^a-zA-Z0-9\\s]"); // Matches non-alphanumeric characters and spaces
                var outputString = game_name.replace(regex, " "); //replace other parameters by spaces
                console.log("game name cleaned : ",outputString);
                //change filename to any regex (to replace spaces)
                //replace space for regex expression
                var nameRegExTemp = ".*" + outputString.replace(/\ /g, '.*');//to replace space by .* to convert to regex filter
                console.log("game name filter(regex) : ",nameRegExTemp);
                searchByName.filter  = nameRegExTemp;
                //hardcoded value for testing
                //searchByName.filter = ".*Super.*Mario.*.*Bros.*.*3.*"
                searchByName.system = game_system;
                searchByName.region = game_region;
                //activate search at the end
                searchByName.activated = true;
            }
        }
    }

    Keys.onPressed: {
        if (api.keys.isCancel(event) && !event.isAutoRepeat) {
            event.accepted = true;
            focus = false;
            visible = false;
            root.cancel();
        }
    }

    Shade {
        id: shade
        onCancel: root.cancel()
    }

    // actual dialog
    MouseArea {
        anchors.centerIn: parent
        width: dialogBox.width
        height: dialogBox.height
    }
    Column {
        id: dialogBox

        width: parent.height * 0.8
        anchors.centerIn: parent
        scale: 0.5

        Behavior on scale { NumberAnimation { duration: 125 } }

        // image area
        Item {
            width: parent.width
            height: picture.height + vpx("5") * root.textSize
            Image {
                id: picture
                source: game_picture //getPicture(root.system)
                antialiasing: true
                fillMode: Image.PreserveAspectFit
                width: vpx(400); height: vpx(400)
                asynchronous: true
                //sourceSize { width: vpx(400); height: vpx(400) }
                visible: true
                opacity: 1

                //for cart animation
                y: -picture.height*1.25
                anchors {
                    horizontalCenter: parent.horizontalCenter
                }

                NumberAnimation on y {
                    id: animation
                    from: -picture.height*1.25
                    to: messageText.y
                    running: false
                    duration: 2000
                    easing.type: Easing.InOutQuart
                }

                //cdrom animation example
                /*anchors {
                    verticalCenter: parent.verticalCenter
                    horizontalCenter: parent.horizontalCenter
                }

                NumberAnimation on rotation {
                    id: animation
                    from: 0; to: 1080 * 6
                    running: false
                    loops: Animation.Infinite
                    duration: 12000
                    easing.type: Easing.InOutQuart
                }*/
            }
        }

        // text area
        Rectangle {
            width: parent.width
            height: messageText.height + vpx("50")
            color: themeColor.secondary
            Text {
                id: messageText

                anchors.centerIn: parent
                width: parent.width - vpx("2") * root.textSize

                wrapMode: Text.WordWrap
                horizontalAlignment: Text.AlignHCenter

                color: themeColor.textTitle
                font {
                    pixelSize: root.textSize
                    family: globalFonts.sans
                }
            }

            Text {
                id: symbolText

                anchors {
                    verticalCenter: parent.verticalCenter
                    left: parent.left
                    leftMargin: root.titleTextSize * 0.75
                    right: messageText.left
                    rightMargin: root.titleTextSize * 0.75
                }
                color: themeColor.textTitle
                text: getIcon(root.system)
                font {
                    bold: false
                    pixelSize: root.titleTextSize * 2.5
                    family: global.fonts.awesome
                }
            }
        }
        // button row
        Row {
            width: parent.width
            height: root.textSize * 2

            Rectangle {
                id: okButton

                width: (secondchoice !== "") ? parent.width * 0.33 : ((thirdchoice !== "") ? parent.width * 0.5 : parent.width)
                height: root.textSize * 2.25
                color: (focus || okMouseArea.containsMouse) ? "darkGreen" : themeColor.main
                KeyNavigation.right: (secondchoice !== "") ? secondButton : cancelButton
                Keys.onPressed: {
                    if (api.keys.isAccept(event) && !event.isAutoRepeat) {
                        event.accepted = true;
                        root.accept();
                    }
                }

                Text {
                    id: okButtonText
                    anchors.centerIn: parent

                    text: qsTr("Ok") + api.tr
                    color: themeColor.textTitle
                    font {
                        pixelSize: root.textSize
                        family: globalFonts.sans
                    }
                }

                MouseArea {
                    id: okMouseArea
                    anchors.fill: parent
                    hoverEnabled: true
                    onClicked: {
                        root.accept();
                   }
                }
            }

            Rectangle {
                id: secondButton

                width: (secondchoice !== "") ? parent.width * 0.33 : parent.width * 0.5
                height: root.textSize * 2.25
                color: (focus || okMouseArea.containsMouse) ? "darkOrange" : themeColor.main
                visible: (secondchoice !== "") ? true : false

                KeyNavigation.right: cancelButton
                KeyNavigation.left: okButton
                Keys.onPressed: {
                    if (api.keys.isAccept(event) && !event.isAutoRepeat) {
                        event.accepted = true;
                        root.secondChoice();
                    }
                }
                Text {
                    id: secondButtonText
                    anchors.centerIn: parent

                    text: qsTr("2nd choice") + api.tr
                    color: themeColor.textTitle
                    font {
                        pixelSize: root.textSize
                        family: globalFonts.sans
                    }
                }

                MouseArea {
                    id: secondMouseArea
                    anchors.fill: parent
                    hoverEnabled: true
                    onClicked: {
                        root.secondChoice();
                   }
                }
            }

            Rectangle {
                id: cancelButton

                focus: true

                width: (secondchoice !== "") ? parent.width * 0.34 : ((thirdchoice !== "") ? parent.width * 0.5 : 0)
                height: root.textSize * 2.25
                color: (focus || cancelMouseArea.containsMouse) ? "darkRed" : themeColor.main

                KeyNavigation.left: (secondchoice !== "") ? secondButton : okButton
                Keys.onPressed: {
                    if (api.keys.isAccept(event) && !event.isAutoRepeat) {
                        event.accepted = true;
                        root.cancel();
                    }
                }

                Text {
                    id: cancelButtonText
                    anchors.centerIn: parent

                    text: qsTr("Cancel") + api.tr
                    color: themeColor.textTitle
                    font {
                        pixelSize: root.textSize
                        family: globalFonts.sans
                    }
                }

                MouseArea {
                    id: cancelMouseArea
                    anchors.fill: parent
                    hoverEnabled: true
                    onClicked: {
                        root.cancel();
                   }
                }
            }
        }
    }

    states: [
        State {
            name: "open"
            PropertyChanges { target: shade; opacity: 0.8 }
            PropertyChanges { target: dialogBox; scale: 1 }
        }
    ]
}
