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
    property string game_system: "" //contain the shortname
    property string game_region: "" //contain region (no-intro format)
    property string game_type: "" //could contain the licence or type of cardridge
    property string game_picture: "" //contains the picture found for this cartridge
    property string game_state: "" //contains status/state
    property string game_name: "" //contain the name provided intially

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
            //console.log("onMaxChanged - enabled :",searchByName.enabled);
            //console.log("onMaxChanged - activated :",searchByName.activated);
            //console.log("onMaxChanged - max :",searchByName.max);
            //console.log("onMaxChanged - game_name :",game_name);
            //console.log("onMaxChanged - crc :",searchByName.crc);
            //console.log("onMaxChanged - crcToFind :",searchByName.crcToFind);
            //console.log("onMaxChanged - filename :",searchByName.filename);
            //console.log("onMaxChanged - filenameRegEx :",searchByName.filenameRegEx);
            //console.log("onMaxChanged - filenameToFilter :",searchByName.filenameToFilter);
            //console.log("onMaxChanged - system :",searchByName.system);
            //console.log("onMaxChanged - sytemToFind :",searchByName.systemToFilter);
            //console.log("onMaxChanged - filter :",searchByName.filter);
            //console.log("onMaxChanged - titleToFilter :",searchByName.titleToFilter);
            //console.log("onMaxChanged - region :",searchByName.region);
            //console.log("onMaxChanged - regionToFilter :",searchByName.regionToFilter);

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
                    var bestTitleFound = ""; // to track the best one found
                    for(var j = 0;(j < searchByName.result.games.count) && (j < iNB_RESULTS_MAX);j++)
                    {
                        //console.log("game title found:",result.games.get(j).title);
                        //console.log("game name to find:",game_name);
                        var titleToCheck = result.games.get(j).title;
                        //remove data between [] and ()
                        var regex = /\([^()]*\)|\[[^\]]*\]/;
                        titleToCheck = titleToCheck.replace(regex, "");
                        //console.log("titleToCheck - step 1: ",titleToCheck);
                        //keep only alpha numeric characters and in lowercases
                        regex = RegExp("[^a-zA-Z0-9&.;]"); // Matches non-alphanumeric characters + some special characters
                        titleToCheck = titleToCheck.replace(regex, "");
                        //console.log("titleToCheck - step 2: ",titleToCheck);
                        titleToCheck = titleToCheck.toLowerCase();
                        //console.log("titleToCheck - step 3: ",titleToCheck);
                        //also adapat game_name to improve the matching (keep alphanumeric also) and remove spaces
                        var gameToCheck = game_name.replace(regex, "");
                        //console.log("gameToCheck - step 1: ",gameToCheck);
                        gameToCheck = gameToCheck.toLowerCase();
                        //console.log("gameToCheck - step 2: ",gameToCheck);
                        //the idea is to compare game name/title lenghts and take the best one or matching exactly
                        if(gameToCheck.length === titleToCheck.length){ //best case ;-)
                            searchByName.resultIndex = j;
                            searchByName.titleMatched = true;
                            break;
                        }
                        else{ //else we will save the best one found
                            if(bestTitleFound === ""){ //first iteration (save first found)
                               bestTitleFound = titleToCheck;
                               searchByName.resultIndex = j;
                            }
                            else if((bestTitleFound.length - gameToCheck.length) > (titleToCheck.length - gameToCheck.length)){
                                bestTitleFound = titleToCheck;
                                searchByName.resultIndex = j;
                            }
                        }
                    }
                    //if we don't match any , we will take the first one
                    if(searchByName.resultIndex === -1) {
                        searchByName.resultIndex = 0;
                    }
                }
                //console.log("game found/selected !!!");
                //console.log("searchByName.resultIndex : ", searchByName.resultIndex);
                //console.log("result.games.get(searchByName.resultIndex).title : ", result.games.get(searchByName.resultIndex).title)
                if(searchByName.resultIndex !== -1) {
                    game_picture = cartArt(result.games.get(searchByName.resultIndex));
                    if(game_state !== "reloaded"){
                        animation.running = true;
                        //start animation
                        animation.restart();
                    }
                    root.visible = true;
                    root.focus = true;
                }
                else{
                    //keep empty in this case
                    game_picture = "";
                    animation.running = false;
                    //no animation
                    animation.stop();
                    root.visible = true;
                    root.focus = true;
                }
                //console.log("game picture to use: ", game_picture)
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
        //console.log("onActiveFocusChanged: ", activeFocus);
        state = activeFocus ? "open" : "";
        if (activeFocus){
            cancelButton.focus = true;
        }
    }

    function gameChanged(){
        //start search after focus
        //check if both are not empty as deleted one
        if(game_name !== "" && game_system !== "" && game_state !== "unknown"){
            //console.log("gameChanged() : game Changed");
            //deactivate during setup of search
            searchByName.activated = false;
            //we search by name and we clean it before if needed
            var regex = RegExp("[^a-zA-Z0-9&.;\\s]");
            // Matches non-alphanumeric characters, spaces and keep special characters: "&.;"
            var outputString = game_name.replace(regex, " "); //replace other characters by spaces
            //console.log("game name cleaned - step 1 : ",outputString);
            outputString = outputString.replace("&amp;", "&"); //&amp; to &
            //console.log("game name cleaned - step 2 : ",outputString);
            //change filename to any regex (to replace spaces)
            //replace space for regex expression
            var nameRegExTemp = ".*" + outputString.replace(/\ /g, '.*');//to replace space by .* to convert to regex filter
            //console.log("game name filter(regex) : ",nameRegExTemp);
            searchByName.filter  = nameRegExTemp;
            //hardcoded value for testing
            //searchByName.filter = ".*Super.*Mario.*.*Bros.*.*3.*"
            searchByName.system = game_system;
            searchByName.region = game_region;
            //activate search at the end
            searchByName.activated = true;
        }
        else if((game_name === "") && (game_state === "unknown")){
            //console.log("gameChanged() : game Unknown");
            //deactivate search
            searchByName.activated = false;
            //keep empty in this case
            game_picture = "";
            animation.running = false;
            //no animation
            animation.stop();
            //show if needed
            root.visible = true;
            root.focus = true;
        }
        else if((game_name === "") && ((game_state === "unplugged") || (game_state === "disconnected"))){
            //hide if needed
            root.visible = false;
            root.focus = false;
            //console.log("gameChanged() : game ", game_state);
            //deactivate search
            searchByName.activated = false;
            //keep empty in this case
            game_picture = "";
            animation.running = false;
            //no animation
            animation.stop();
        }
    }

    onGame_stateChanged : {
        //console.log("onGame_stateChanged : ", game_state);
        gameChanged();
    }

    onGame_nameChanged : {
        //console.log("onGame_nameChanged : ", game_name);
        gameChanged();
    }

    Keys.onPressed: {
        if (api.keys.isCancel(event) && !event.isAutoRepeat) {
            event.accepted = true;
            root.visible = false;
            root.focus = false;
            root.cancel();
        }
    }

    Shade {
        id: shade
        onCancel: root.cancel();
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
                source: game_picture
                antialiasing: true
                fillMode: Image.PreserveAspectFit
                width: vpx(400); height: vpx(400)
                asynchronous: true
                //sourceSize { width: vpx(400); height: vpx(400) }
                visible: game_picture !== "" ? true : false
                opacity: 1

                //for cart animation
                y: -root.height*2
                anchors {
                    horizontalCenter: parent.horizontalCenter
                }

                NumberAnimation on y {
                    id: animation
                    from: -root.height*2
                    to: messageText.y
                    running: false
                    duration: 1300
                    easing.type: Easing.InOutQuart
                }
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
                text: getIcon(game_system)
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
                        root.visible = false;
                        root.focus = false;
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
