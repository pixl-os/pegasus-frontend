// Pegasus Frontend
// created by BozoTheGeek 20/08/2024

import QtQuick 2.15
import "../search"

FocusScope {
    id: root

    property alias message: messageText.text
    property alias symbol: symbolText.text
    property alias firstchoice: okButtonText.text
    property alias secondchoice: secondButtonText.text
    property alias thirdchoice: cancelButtonText.text

    //game info
    property string game_crc32: "" //contain the crc32 hash as in gamelist (working for SNES for the moment)
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
        id: searchGame;
        property bool titleMatched : false // by default
        property bool crc32Matched : false // by default
        property int resultIndex: -1
        activated: false

        onMaxChanged:{
            //console.log("onMaxChanged - enabled :",searchGame.enabled);
            //console.log("onMaxChanged - activated :",searchGame.activated);
            //console.log("onMaxChanged - max :",searchGame.max);
            //console.log("onMaxChanged - game_name :",game_name);
            //console.log("onMaxChanged - crc :",searchGame.crc);
            //console.log("onMaxChanged - crcToFind :",searchGame.crcToFind);
            //console.log("onMaxChanged - filename :",searchGame.filename);
            //console.log("onMaxChanged - filenameRegEx :",searchGame.filenameRegEx);
            //console.log("onMaxChanged - filenameToFilter :",searchGame.filenameToFilter);
            //console.log("onMaxChanged - system :",searchGame.system);
            //console.log("onMaxChanged - sytemToFind :",searchGame.systemToFilter);
            //console.log("onMaxChanged - filter :",searchGame.filter);
            //console.log("onMaxChanged - titleToFilter :",searchGame.titleToFilter);
            //console.log("onMaxChanged - region :",searchGame.region);
            //console.log("onMaxChanged - regionToFilter :",searchGame.regionToFilter);

            if((game_system === "") || ((game_name === "") && (game_crc32 === ""))  || (activated === false)) {
                //do nothing to go quickly when it's not significant to proceed
                //just reset for later
                titleMatched = false;
                crc32Matched = false;
            }
            //parse only nb_results_max to avoid saturation of system if not found
            else if (searchGame.max >= 1 && searchGame.max <= iNB_RESULTS_MAX && (activated === true)) { //Title search and match
                //init index
                searchGame.resultIndex = -1;
                //check if not already found by title
                if(searchGame.titleMatched !== true && searchGame.crc === ""){
                    var bestTitleFound = ""; // to track the best one found
                    for(var j = 0;(j < searchGame.result.games.count) && (j < iNB_RESULTS_MAX);j++)
                    {
                        //console.log("game title found:",result.games.get(j).title);
                        //console.log("game name to find:",game_name);
                        var titleToCheck = result.games.get(j).title;
                        //remove data between [] and ()
                        var regex = /\([^()]*\)|\[[^\]]*\]/;
                        titleToCheck = titleToCheck.replace(regex, "");
                        //console.log("titleToCheck - step 1: ",titleToCheck);
                        titleToCheck = titleToCheck.replace("&amp;", "&");
                        //console.log("titleToCheck - step 2: ",titleToCheck);
                        //keep only alpha numeric characters and in lowercases
                        regex = /[^a-zA-Z0-9&]/g; // Matches non-alphanumeric characters + '&' special character
                        titleToCheck = titleToCheck.replace(regex, "");
                        //console.log("titleToCheck - step 3: ",titleToCheck);
                        titleToCheck = titleToCheck.toLowerCase();
                        //console.log("titleToCheck - step 4: ",titleToCheck);
                        //also adapat game_name to improve the matching (keep alphanumeric also) and remove spaces
                        var gameToCheck = game_name.replace(regex, "");
                        //console.log("gameToCheck - step 1: ",gameToCheck);
                        gameToCheck = gameToCheck.toLowerCase();
                        //console.log("gameToCheck - step 2: ",gameToCheck);
                        //the idea is to compare game name/title lenghts and take the best one or matching exactly
                        if(gameToCheck.length === titleToCheck.length){ //best case ;-)
                            searchGame.resultIndex = j;
                            searchGame.titleMatched = true;
                            break;
                        }
                        else{ //else we will save the best one found
                            if(bestTitleFound === ""){ //first iteration (save first found)
                               bestTitleFound = titleToCheck;
                               searchGame.resultIndex = j;
                            }
                            else if((bestTitleFound.length - gameToCheck.length) > (titleToCheck.length - gameToCheck.length)){
                                bestTitleFound = titleToCheck;
                                searchGame.resultIndex = j;
                            }
                        }
                    }
                    //if we don't match any , we will take the first one
                    if(searchGame.resultIndex === -1) {
                        searchGame.resultIndex = 0;
                    }
                }
                if(searchGame.crcMatched !== true && searchGame.crc !== ""){
                    for(var j = 0;(j < searchGame.result.games.count) && (j < iNB_RESULTS_MAX);j++)
                    {
                        //console.log("game title found:",result.games.get(j).title);
                        var crcToCheck = result.games.get(j).hash;
                        //console.log("game crc to check:",crcToCheck);
                        //console.log("searGame crc:",searchGame.crc);
                        if(crcToCheck.toUpperCase() === searchGame.crc.toUpperCase()){ //best case ;-)
                            searchGame.resultIndex = j;
                            searchGame.crc32Matched = true;
                            break;
                        }
                    }
                    //if we don't match any , we will take the first one
                    if(searchGame.resultIndex === -1) {
                        searchGame.resultIndex = 0;
                    }
                }
                //console.log("game found/selected !!!");
                //console.log("searchGame.resultIndex : ", searchGame.resultIndex);
                //console.log("result.games.get(searchGame.resultIndex).title : ", result.games.get(searchGame.resultIndex).title)
                if(searchGame.resultIndex !== -1) {
                    game_picture = cartArt(result.games.get(searchGame.resultIndex));
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
            //to remove image/stop animation if no game found
            else if (searchGame.max === 0){
                //keep empty in this case
                game_picture = "";
                animation.running = false;
                //no animation
                animation.stop();
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

    onFocusChanged: {
        //console.log("onFocusChanged: ", focus);
    }

    onActiveFocusChanged: {
        //console.log("onActiveFocusChanged: ", activeFocus);
        state = activeFocus ? "open" : "close";
        if (activeFocus){
            cancelButton.focus = true;
        }
    }
    //list model to manage specific cases where we should replace value by an other one to filter search by name
    //this type of model help to complete limitation of some regex
    ListModel {
        id: specificValue //order is important to avoid issue especially with "roman" numbers
        /*ListElement { toFind: " 100|C"; toReplaceBy: "*.100|C" }
        ListElement { toFind: " 90|XC"; toReplaceBy: "*.90|XC" }
        ListElement { toFind: " 80|LXXX"; toReplaceBy: "*.80|LXXX" }
        ListElement { toFind: " 70|LXX"; toReplaceBy: "*.70|LXX" }
        ListElement { toFind: " 60|LX"; toReplaceBy: "*.60|LX" }
        ListElement { toFind: " 50|L"; toReplaceBy: "*.50|L" }
        ListElement { toFind: " 49|XLIX"; toReplaceBy: "*.49|XLIX" }
        ListElement { toFind: " 48|XLVIII"; toReplaceBy: "*.48|XLVIII" }
        ListElement { toFind: " 47|XLVII"; toReplaceBy: "*.47|XLVII" }
        ListElement { toFind: " 46|XLVI"; toReplaceBy: "*.46|XLVI" }
        ListElement { toFind: " 45|XLV"; toReplaceBy: "*.45|XLV" }
        ListElement { toFind: " 44|XLIV"; toReplaceBy: "*.44|XLIV" }
        ListElement { toFind: " 43|XLIII"; toReplaceBy: "*.43|XLIII" }
        ListElement { toFind: " 42|XLII"; toReplaceBy: "*.42|XLII" }
        ListElement { toFind: " 41|XLI"; toReplaceBy: "*.41|XLI" }
        ListElement { toFind: " 40|XL"; toReplaceBy: "*.40|XL" }
        ListElement { toFind: " 39|XXXIX"; toReplaceBy: "*.39|XXXIX" }
        ListElement { toFind: " 38|XXXVIII"; toReplaceBy: "*.38|XXXVIII" }
        ListElement { toFind: " 37|XXXVII"; toReplaceBy: "*.37|XXXVII" }
        ListElement { toFind: " 36|XXXVI"; toReplaceBy: "*.36|XXXVI" }
        ListElement { toFind: " 35|XXXV"; toReplaceBy: "*.35|XXXV" }
        ListElement { toFind: " 34|XXXIV"; toReplaceBy: "*.34|XXXIV" }
        ListElement { toFind: " 33|XXXIII"; toReplaceBy: "*.33|XXXIII" }
        ListElement { toFind: " 32|XXXII"; toReplaceBy: "*.32|XXXII" }
        ListElement { toFind: " 31|XXXI"; toReplaceBy: "*.31|XXXI" }
        ListElement { toFind: " 30|XXX"; toReplaceBy: "*.30|XXX" }
        ListElement { toFind: " 29|XXIX"; toReplaceBy: "*.29|XXIX" }
        ListElement { toFind: " 28|XXVIII"; toReplaceBy: "*.28|XXVIII" }
        ListElement { toFind: " 27|XXVII"; toReplaceBy: "*.27|XXVII" }
        ListElement { toFind: " 26|XXVI"; toReplaceBy: "*.26|XXVI" }
        ListElement { toFind: " 25|XXV"; toReplaceBy: "*.25|XXV" }
        ListElement { toFind: " 24|XXIV"; toReplaceBy: "*.24|XXIV" }
        ListElement { toFind: " 23|XXIII"; toReplaceBy: "*.23|XXIII" }
        ListElement { toFind: " 22|XXII"; toReplaceBy: "*.22|XXII" }
        ListElement { toFind: " 21|XXI"; toReplaceBy: "*.21|XXI" }*/
        ListElement { toFind: " XX";    toReplaceBy: " 20" }
        ListElement { toFind: " XIX";   toReplaceBy: " 19" }
        ListElement { toFind: " XVIII"; toReplaceBy: " 18" }
        ListElement { toFind: " XVII";  toReplaceBy: " 17" }
        ListElement { toFind: " XVI";   toReplaceBy: " 16" }
        ListElement { toFind: " XV";    toReplaceBy: " 15" }
        ListElement { toFind: " XIV";   toReplaceBy: " 14" }
        ListElement { toFind: " XIII";  toReplaceBy: " 13" }
        ListElement { toFind: " XII";   toReplaceBy: " 12" }
        ListElement { toFind: " XI";    toReplaceBy: " 11" }
        ListElement { toFind: " X";     toReplaceBy: " 10" }
        ListElement { toFind: " IX";    toReplaceBy: " 9" }
        ListElement { toFind: " VIII";  toReplaceBy: " 8" }
        ListElement { toFind: " VII";   toReplaceBy: " 7" }
        ListElement { toFind: " VI";    toReplaceBy: " 6" }
        ListElement { toFind: " V";     toReplaceBy: " 5" }
        ListElement { toFind: " IV";    toReplaceBy: " 4" }
        ListElement { toFind: " III";   toReplaceBy: " 3" }
        ListElement { toFind: " II";    toReplaceBy: " 2" }
        ListElement { toFind: " I";     toReplaceBy: " 1" }
        ListElement { toFind: " 20";    toReplaceBy: " XX" }
        ListElement { toFind: " 19";    toReplaceBy: " XIX" }
        ListElement { toFind: " 18";    toReplaceBy: " XVIII" }
        ListElement { toFind: " 17";    toReplaceBy: " XVII" }
        ListElement { toFind: " 16";    toReplaceBy: " XVI" }
        ListElement { toFind: " 15";    toReplaceBy: " XV" }
        ListElement { toFind: " 14";    toReplaceBy: " XIV" }
        ListElement { toFind: " 13";    toReplaceBy: " XIII" }
        ListElement { toFind: " 12";    toReplaceBy: " XII" }
        ListElement { toFind: " 11";    toReplaceBy: " XI" }
        ListElement { toFind: " 10";    toReplaceBy: " X" }
        ListElement { toFind: " 9";     toReplaceBy: " IX" }
        ListElement { toFind: " 8";     toReplaceBy: " VIII" }
        ListElement { toFind: " 7";     toReplaceBy: " VII" }
        ListElement { toFind: " 6";     toReplaceBy: " VI" }
        ListElement { toFind: " 5";     toReplaceBy: " V" }
        ListElement { toFind: " 4";     toReplaceBy: " IV" }
        ListElement { toFind: " 3";     toReplaceBy: " III" }
        ListElement { toFind: " 2";     toReplaceBy: " II" }
        ListElement { toFind: " 1";     toReplaceBy: " I" }
    }

    function gameChanged(){
        var game_criteria = "";
        if(game_name !== "") game_criteria = game_name;
        else if(game_crc32 !== "") game_criteria = game_crc32;

        //start search after focus (by crc32 or name)
        if(game_criteria !==""  && game_system !== "" && game_state !== "unknown" && game_state !== "unplugged" && game_state !== "disconnected"){
            //console.log("gameChanged() : game Changed");
            //deactivate during setup of search
            searchGame.activated = false;
            if(game_crc32 === ""){ // search by name/region/system
                //we search by name and we clean it before if needed
                //finally we start by replace '&amp;' to '&'
                var outputString = game_name.replace("&amp;", "&");
                //console.log("game name cleaned - step 1 : ",outputString);
                var regex =  /[^a-zA-Z0-9&\s]/g;
                // Matches non-alphanumeric characters, spaces and keep the special character: "&"
                outputString = outputString.replace(regex, " "); //replace other characters by spaces
                //console.log("game name cleaned - step 2 : ",outputString);
                //try to replace numbers to be able to seach by arab or roman ones (could be extend to other expression if needed in the future using the listmodel)
                var newOutputString = "";
                for(var i = 0; i < specificValue.count; i++){
                    var alternativeOutputString = outputString.replace(specificValue.get(i).toFind, specificValue.get(i).toReplaceBy);
                    if(alternativeOutputString !== outputString){
                        if(newOutputString === ""){
                            newOutputString = outputString + "|.*" + alternativeOutputString;
                        }
                        else{
                            newOutputString = newOutputString + "|.*" + alternativeOutputString;
                        }
                    }
                }
                if(newOutputString !== "") outputString = newOutputString;
                //console.log("game name cleaned - step 3 : ",outputString);
                //change filename to any regex (to replace spaces)
                //replace space for regex expression
                var nameRegExTemp = ".*" + outputString.replace(/\ /g, '.*');//to replace space by .* to convert to regex filter
                //console.log("game name filter(regex) : ",nameRegExTemp);
                searchGame.crc = "";
                searchGame.filter  = nameRegExTemp + ".*"; //add also .* at the end
                //hardcoded value for testing
                //searchGame.filter = ".*Super.*Mario.*.*Bros.*.*3.*"
                searchGame.system = game_system;
                searchGame.region = game_region;
            }
            else{ //search by crc32/system
                //we search by crc32 and we clean it before if needed
                searchGame.filter  = "";
                searchGame.system = game_system;
                searchGame.region = "";
                searchGame.crc = game_crc32;
            }
            //reset picture in all cases
            game_picture = "";
            //force showing is needed
            root.visible = true;
            root.focus = true;
            //activate search at the end
            searchGame.activated = true;
        }
        else if((game_criteria === "") && (game_state === "unknown")){
            //console.log("gameChanged() : game Unknown");
            //deactivate search
            searchGame.activated = false;
            //keep empty in this case
            game_picture = "";
            animation.running = false;
            //no animation
            animation.stop();
            //force showing is needed
            root.visible = true;
            root.focus = true;
        }
        else if((game_state === "unplugged") || (game_state === "disconnected")){
            //console.log("gameChanged() : game ", game_state);
            //deactivate search
            searchGame.activated = false;
            //keep empty in this case
            game_picture = "";
            animation.running = false;
            //no animation
            animation.stop();
            //force hidding if needed
            if(root.focus === true || root.visible === true)
            {
                root.cancel();
            }
            root.focus = false;
            root.visible = false;
        }
    }

    onGame_crc32Changed : {
        //console.log("onGame_crc32Changed : ", game_crc32);
        gameChanged();
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
        scale: 1 //0.5

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
        },
        State {
            name: "close"
            PropertyChanges { target: shade; opacity: 0 }
            PropertyChanges { target: dialogBox; scale: 0.5 }
        }

    ]
}
