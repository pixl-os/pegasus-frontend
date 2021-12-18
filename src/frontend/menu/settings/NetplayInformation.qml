// Pegasus Frontend
//
// Created by BozoTheGeek 16/11/2021
//

import "common"
import "../../search"
import "../../dialogs"
import "qrc:/qmlutils" as PegasusUtils
import QtQuick 2.12
import QtQuick.Controls 2.12
import QtQuick.Window 2.12

FocusScope {
    id: root
	
	property bool isCallDirectly : false

    //use as status and icon at the same time
    readonly property string isOK :  "\uf1c0"
    readonly property string isMAYBE :"\uf1c1"
    readonly property string isNOK :"\uf1c2"

    signal close

    width: parent.width
    height: parent.height

    anchors.fill: parent
	
    //enabled: focus
    
    visible: 0 < (x + width) && x < Window.window.width

    //timer to refresh Netplay list
    property var counter: 0
    Timer {
        id: netplayTimer
        interval: 200 // Run the timer 200 ms
        repeat: true
        running: true
        triggeredOnStart: true
        onTriggered: {
                if (counter === 1){ // to start after 200ms (to let page loading)
                    //console.log("netplayTimer - before refresh: availableNetplayRooms.selectedButtonIndex", availableNetplayRooms.selectedButtonIndex);
                    api.internal.netplay.rooms.refresh();
				}
                else if ((interval*counter/1000) === 3){ //wait 3 seconds before to refresh latency
                    api.internal.netplay.rooms.refresh_latency();
                }
                else if((interval*counter/1000) >= 5){ //wait 5 seconds before to refresh list
                    counter = 0;
                }
                counter = counter + 1;
        }
    }

    //timer to check number of friends
    Timer {
        id: friendsTimer
        interval: 1000 // Run the timer 200 ms
        repeat: true
        running: true
        triggeredOnStart: false
        onTriggered: {
            if(friendsOnly){
                friendsCount = 0;
                for(var i = 0;i < availableNetplayRooms.count;i++)
                {
                    if(availableNetplayRooms.itemAt(i).visible) friendsCount = friendsCount + 1
                }
            }
        }
    }
    //to be able to follow action done on Bluetooth Devices Lists
    property var actionState : ""
    property var actionListIndex : 0
    property bool friendsOnly: false
    property bool launchableOnly: false
    property var friendsCount: 0
    property var gameSelected
    property var roomSelected
    property var searchSelected

    onFriendsOnlyChanged:{
        //reset count when changed
        availableNetplayRooms.friendsCount = 0;
    }


    //loader to load confirm dialog
    Loader {
        id: confirmDialog
        anchors.fill: parent
        z:10
        sourceComponent: myDialog
        active: false
        asynchronous: true
        //to set value via loader
        property var game_logo: ""
        property var game_name: ""
        property var player_name: ""
        property var system_logo: ""
        property bool has_password: false
        property bool has_spectate_password: false
    }

    Component {
        id: myDialog
        NetplayDialog {
            title: qsTr("Play or View this game ?") + api.tr
            message: confirmDialog.game_name
            symbol: confirmDialog.system_logo
            firstchoice: qsTr("Play") + api.tr
            secondchoice: qsTr("View") + api.tr
            thirdchoice: qsTr("Cancel") + api.tr

            //Specific to Netplay
            game_logo: confirmDialog.game_logo
            player_name: confirmDialog.player_name
            has_password: confirmDialog.has_password
            has_spectate_password: confirmDialog.has_spectate_password
        }
    }

    Connections {
        target: confirmDialog.item
        function onAccept() { //first choice
            switch (actionState) {
                    case "PlayOrView": //-> TO PLAY
                        //stop scanning during playing ;-)
                        netplayTimer.running = false;
                        friendsTimer.running = false;
                        if(isRoomAvailable(roomSelected.ip,roomSelected.port)){
                            //launch game in netplay mode
                            //set parameter for netplay (mode = 1 -> client)
                            gameSelected.modelData.launchNetplay(
                                        1, roomSelected.port, roomSelected.ip,
                                        roomSelected.has_password ? api.internal.recalbox.parameterslist.currentName("netplay.password.client"):"",
                                        "", //let viewer password empty in this case
                                        false,
                                        roomSelected.hash,
                                        "libretro",
                                        searchSelected.coreFound);
                            //clean rooms model
                            api.internal.netplay.rooms.reset();
                        }
                        else{
                            //restart scanning
                            netplayTimer.running = true;
                            friendsTimer.running = true;
                        }
                    break;
            }
            confirmDialog.active = false;
            content.focus = true;
        }

        function onSecondChoice() {
            switch (actionState) {
                    case "PlayOrView": // -> TO VIEW
                        //stop scanning during playing ;-)
                        netplayTimer.running = false;
                        friendsTimer.running = false;
                        if(isRoomAvailable(roomSelected.ip,roomSelected.port)){
                            //launch game in netplay mode
                            //set parameter for netplay (mode = 1 -> client)
                            gameSelected.modelData.launchNetplay(
                                        1, roomSelected.port, roomSelected.ip,
                                        "", //let player password empty in this case
                                        roomSelected.has_spectate_password ? api.internal.recalbox.parameterslist.currentName("netplay.password.viewer"):"",
                                        true,
                                        roomSelected.hash,
                                        "libretro",
                                        searchSelected.coreFound);
                            //clean rooms model
                            api.internal.netplay.rooms.reset();
                        }
                        else{
                            //restart scanning
                            netplayTimer.running = true;
                            friendsTimer.running = true;
                        }
                    break;
            }
            confirmDialog.active = false;
            content.focus = true;
        }
        function onCancel() {
            //reset game/room/search Selected
            gameSelected = null;
            roomSelected = null;
            searchSelected = null;
            //do nothing
            confirmDialog.active = false;
            content.focus = true;
            netplayTimer.running = true;
        }
    }

    //function to check room availability before to launch retroarch
    function isRoomAvailable(ip,port){
        //do telnet to verify connectivity quickly and avoid to wait too long time if not accessible finally
        console.log("command:","timeout 5 telnet " + ip + " " + port);
        //check during 5 seconds
        var result = api.internal.system.run("timeout 5 telnet " + ip + " " + port);
        console.log("result:",result)
        if(result.toLowerCase().includes("connected")) return true;
        else{
            //display dialog box to alert that room is not accessible finally
            genericMessage.setSource("../../dialogs/GenericOkDialog.qml",
               { "title": qsTr("Connection error"), "message": qsTr("Room seems not available finally, may be reference is obsolete from lobby or not compatible ?!") });
            genericMessage.focus = true;
            return false;
        }
    }


    //function to update index where focus should be
    function updateFocusIndex()
    {
        //if existing selected index is visible
        if(availableNetplayRooms.itemAt(availableNetplayRooms.selectedButtonIndex).visible !== true){
            //need to select an other index
            //first after if exist...
            for(var i = availableNetplayRooms.selectedButtonIndex; i < availableNetplayRooms.count; i++)
            {
                if(availableNetplayRooms.itemAt(i).visible === true) {
                    availableNetplayRooms.selectedButtonIndex = i;
                    break;
                }
            }
            //if no visible found after...
            if(availableNetplayRooms.itemAt(availableNetplayRooms.selectedButtonIndex).visible !== true){
                //need check before if exist...
                for(var j = availableNetplayRooms.selectedButtonIndex; j >= 0; j--)
                {
                    if(availableNetplayRooms.itemAt(j).visible === true) {
                        availableNetplayRooms.selectedButtonIndex = j;
                        break;
                    }
                }
            }
        }
        //console.log("availableNetplayRooms.selectedButtonIndex: ", availableNetplayRooms.selectedButtonIndex);
    }

    Keys.onPressed: {
        if (api.keys.isCancel(event) && !event.isAutoRepeat) {
            event.accepted = true;
            //clean rooms model
            api.internal.netplay.rooms.reset();
            root.close();
        }
        else if(api.keys.isFilters(event) && !event.isAutoRepeat) {
            friendsOnly = !friendsOnly;
        }
        else if (api.keys.isDetails(event) && !event.isAutoRepeat) {
            launchableOnly = !launchableOnly;
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
        text: isCallDirectly ? qsTr("Netplay information") + api.tr : qsTr("Accounts > Netplay information") + api.tr
        z: 2
    }

    Rectangle {
        width: parent.width
        color: themeColor.main
        anchors {
            top: header.bottom
            bottom: footer.top
        }
    }

    Flickable {
        id: container

        width: content.width
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: header.bottom
        anchors.bottom: footer.top

        contentWidth: content.width
        contentHeight: content.height

        Behavior on contentY { PropertyAnimation { duration: 100 } }
        boundsBehavior: Flickable.StopAtBounds
        boundsMovement: Flickable.StopAtBounds

		FocusScope {
			id: content

			focus: true
			enabled: focus

			width: contentColumn.width
			height: contentColumn.height

			Column {
				id: contentColumn
				spacing: vpx(5)

                width: root.width * 0.9
				height: implicitHeight

                Item {
					width: parent.width
					height: implicitHeight + vpx(30)
                }

                Row{
                    Image {
                        id: logoRetroarch
                        height: vpx(50)
                        source: "../../assets/libretro-retroarch-simple-logo.png"
                        anchors.verticalCenter: retroarch_title.verticalCenter
                        fillMode: Image.PreserveAspectFit
                    }
                    SectionTitle {
                    id: retroarch_title
                    text: {
                        if(friendsOnly)
                            return ("  " + qsTr("Retroarch lobby : ") + (friendsCount) + qsTr(" 'Friend' room(s)") + api.tr);
                        else
                            return ("  " + qsTr("Retroarch lobby : ") + (availableNetplayRooms.count - availableNetplayRooms.hidden) + qsTr(" room(s)") + api.tr);
                    }
                    first: true
					visible: true
                    }
                }
                //for test purpose only
                /*ListModel {
                    id: availableNetplayRoomsModel
                    ListElement { country: "br"; username: "Anonymous";
                                  game_name: "Metal Slug X (U) [SLUS-01212]";
                                  game_crc: "D634567DF";
                                  core_name: "PCSX-ReARMed";
                                  core_version: "r22 36f3ea6";
                                  retroarch_version: "1.8.8";
                                  frontend: "win32 x64";
                                  ip: "192.168.0.1";
                                  port: 8080;
                                  mitm_ip: "";
                                  mitm_port: 0;
                                  host_method : 0;
                                  has_password: false;
                                  has_spectate_password: true;
                                  created: "19 Oct 21 12:05 UTC";
                                  updated: "19 Oct 21 12:10 UTC";
                                }
                }*/
                Repeater {
                    id: availableNetplayRooms
                    model: api.internal.netplay.rooms  // availableNetplayRoomsModel //for test purpose
                    property var selectedButtonIndex : 0
                    property var hidden : 0
                    onItemRemoved:{
                        //RFU
                        //console.log("onItemRemoved: ", index)
                    }
                    onItemAdded:{
                        //RFU
                        //console.log("onItemAdded: ", index)
                    }
                    delegate: DetailedButton {
                        SearchGame {
                            id: searchByCRCorFile;
                            property var crcMatched : false
                            property var fileMatched : false
                            property var coreFound: ""
                            property var coreLongNameFound: ""
                            property var coreVersionFound: ""
                            property var resultIndex: -1
                            onMaxChanged:{
                                //console.log("onMaxChanged - enabled :",searchByCRCorFile.enabled);
                                //console.log("onMaxChanged - max :",searchByCRCorFile.max);
                                //console.log("onMaxChanged - game_crc :",game_crc);
                                //console.log("onMaxChanged - game_name :",game_name);
                                //console.log("onMaxChanged - crc :",searchByCRCorFile.crc);
                                //console.log("onMaxChanged - crcToFind :",searchByCRCorFile.crcToFind);
                                //console.log("onMaxChanged - filename :",searchByCRCorFile.filename);
                                //console.log("onMaxChanged - filenameRegEx :",searchByCRCorFile.filenameRegEx);
                                //console.log("onMaxChanged - filenameToFilter :",searchByCRCorFile.filenameToFilter);
                                //console.log("onMaxChanged - system :",searchByCRCorFile.system);
                                //console.log("onMaxChanged - sytemToFind :",searchByCRCorFile.systemToFilter);

                                if((game_crc === "") && (game_name === "")) {
                                    picture = "";
                                    icon2 = "";
                                    searchByCRCorFile.crcMatched = false;
                                    searchByCRCorFile.fileMatched = false;
                                }
                                else if (searchByCRCorFile.max === 1 && searchByCRCorFile.crc === result.games.get(0).hash) { //CRC search and match
                                    searchByCRCorFile.resultIndex = 0;
                                    picture = result.games.get(0).assets.screenshot;
                                    icon2 = result.games.get(0).assets.logo;
                                    searchByCRCorFile.crcMatched = true;
                                }
                                //parse only 20 results to avoid saturation of system if not found
                                else if (searchByCRCorFile.max>=1 && searchByCRCorFile.max <20 && searchByCRCorFile.filename !== "") { //file name match
                                    //console.log("file name at index 0:",result.games.get(0).files.get(0).name);
                                    searchByCRCorFile.resultIndex = -1;
                                    for(var i = 0;(i < searchByCRCorFile.result.games.count) && (i < 20);i++)
                                    {
                                        //console.log("file name found:",result.games.get(i).files.get(0).name);
                                        if(searchByCRCorFile.result.games.get(i).files.get(0).name === searchByCRCorFile.filename){
                                            searchByCRCorFile.resultIndex = i;
                                            break;
                                        }
                                    }
                                    if(searchByCRCorFile.resultIndex != -1){
                                        picture = searchByCRCorFile.result.games.get(searchByCRCorFile.resultIndex).assets.screenshot;
                                        icon2 = searchByCRCorFile.result.games.get(searchByCRCorFile.resultIndex).assets.logo;
                                        searchByCRCorFile.fileMatched = true;
                                    }
                                    else
                                    {
                                        picture = "";
                                        picture = "";
                                        icon2 = "";
                                        searchByCRCorFile.fileMatched = false;
                                    }
                                }
                                else if (searchByCRCorFile.max !== 1 && searchByCRCorFile.crc !== ""){
                                    picture = "";
                                    icon2 = "";
                                    searchByCRCorFile.crcMatched = false;
                                    searchByCRCorFile.fileMatched = false;
                                }
                                else{
                                    picture = "";
                                    icon2 = "";
                                    searchByCRCorFile.crcMatched = false;
                                    searchByCRCorFile.fileMatched = false;
                                }
                            }
                        }

                        property var status_icon : {
                            //concatenate value to search quickly
                            //About core
                            var core_status = detailed_line11 + detailed_line12
                            //About game
                            var game_status = detailed_line14 + detailed_line15
                            //search if green one exist
                            if(game_status.includes(isOK)){
                                if(!core_status.includes(isOK) && !core_status.includes(isNOK)){
                                    return "\uf1c0 "; // as OK because Core and Game are present at minimum
                                }
                                else
                                {
                                    return "\uf1c1 "; // May be, game ok but core not green ?!
                                }
                            }
                            else
                            {
                                return "\uf1c2 "; // As NOK because no game in all cases
                            }
                            //"\uf1c0" // or "\uf1c1"/"?" or "\uf1c2"/"X"
                        }
                        property var latency_icon :{
                            if (latency >= 1000) return "\uf1c9 ";
                            else if(latency < 50) return "\uf1c8 ";
                            else if(latency < 100) return "\uf1c7 ";
                            else if(latency < 150) return "\uf1c6 ";
                            else return "\uf1c5 ";
                        }
                        //"\uf1c8 " or "\uf1c7" or "\uf1c6" or "\uf1c5" or "\uf1c9"/"?"
                        //good     -    medium   -    bad    - very bad   -  unknown
                        // <50           <100        <150       >150             > 1000

                        property var private_icon : has_password ? "\uf071 " : ""
                        property var visibility_icon : has_spectate_password ? "\uf070 " : " "
                        width: parent.width - vpx(100)
                        enabled: visible
                        visible :{
                            availableNetplayRooms.hidden = api.internal.netplay.rooms.nbEmptyRooms()
                            if ((game_crc === "") && (game_name === "")) return false;
                            else if (friendsOnly){
                               if(api.internal.recalbox.getBoolParameter("netplay.friend." + username)){
                                   if(launchableOnly){
                                       if(!status_icon.includes(isNOK)){
                                           return true;
                                       }
                                       else{
                                          return false;
                                       }
                                   }
                                   else return true;
                               }
                               else return false;
                            }
                            else
                            {
                                if(launchableOnly){
                                    if(!status_icon.includes(isNOK)){
                                        return true;
                                    }
                                    else{
                                       return false;
                                    }
                                }
                                else return true;
                            }
                        }
                        //for preview
                        label: {
                            return (status_icon + latency_icon + private_icon + visibility_icon + username + " / " + ((searchByCRCorFile.crcMatched === true) ? searchByCRCorFile.result.games.get(searchByCRCorFile.resultIndex).title : ((searchByCRCorFile.fileMatched === true) ? searchByCRCorFile.result.games.get(searchByCRCorFile.resultIndex).title : game_name)));
                        }
                        note: {
                            return (" " + qsTr("Creation date") + ": " + created);
                        }
                        //check note only because created date will change only if room is change
                        onNoteChanged:
                        {
                            //check if both are not empty as deleted one
                            if(game_crc !== "" && game_name !== ""){
                                //deactivate during setup of search
                                searchByCRCorFile.activated = false;
                                if (game_crc !== "00000000")
                                    searchByCRCorFile.crc = game_crc;
                                else
                                    searchByCRCorFile.crc = "";
                                //but also by filename at the same time (in //)
                                searchByCRCorFile.filename = game_name;
                                searchByCRCorFile.system = "";
                                //search the system associated also and if the core exist at the same time
                                for(var i = 0;i < api.collections.count  ;i++)
                                {
                                    //check shortname
                                    //console.log("Short name:",api.collections.get(i).shortName);
                                    //console.log("Emulator count:",api.collections.get(i).emulatorsCount);
                                    //for the full list of emulator
                                    for(var j = 0;j < api.collections.get(i).emulatorsCount;j++)
                                    {
                                        //console.log("onNoteChanged - Short name selected:",api.collections.get(i).shortName);
                                        //console.log("onNoteChanged - Core to find:",core_name.toLowerCase());
                                        //console.log("onNoteChanged - Core Long Name to compare:",api.collections.get(i).getCoreLongNameAt(j).toLowerCase());
                                        if(api.collections.get(i).getCoreLongNameAt(j).toLowerCase() === core_name.toLowerCase()){
                                            //console.log("onNoteChanged - Core found :",api.collections.get(i).getCoreAt(j));
                                            if(searchByCRCorFile.system === ""){
                                                searchByCRCorFile.system = api.collections.get(i).shortName;
                                                searchByCRCorFile.coreFound = api.collections.get(i).getCoreAt(j);
                                                searchByCRCorFile.coreLongNameFound = api.collections.get(i).getCoreLongNameAt(j);
                                                searchByCRCorFile.coreVersionFound = api.collections.get(i).getCoreVersionAt(j);
                                            }
                                            else searchByCRCorFile.system = searchByCRCorFile.system + "|" + api.collections.get(i).shortName;
                                        }
                                    }
                                }
                                //activate search at the end
                                searchByCRCorFile.activated = true;
                            }
                        }
                        //add image of country
                        icon: {
                            return ("https://flagcdn.com/h60/" + country + ".png");
                        }
                        detailed_line2: {
                            return "Retroarch version : ";
                        }
                        detailed_line3: {
                            return "Core: ";
                        }
                        detailed_line4: {
                            return "Core version : ";
                        }
                        detailed_line5: {
                            return "Architecture : ";
                        }
                        detailed_line6: {
                            return "Game CRC : ";
                        }
                        detailed_line7: {
                            return "Game file : ";
                        }
                        detailed_line10: {
                            return retroarch_version;
                        }
                        detailed_line11: {
                            return (core_name === searchByCRCorFile.coreLongNameFound) ? (isOK + " " + core_name) : (isNOK + " " + core_name);
                        }
                        detailed_line11_color: {
                            return (core_name === searchByCRCorFile.coreLongNameFound) ? "green" : "red"
                        }
                        detailed_line12: {
                            return (core_version === searchByCRCorFile.coreVersionFound) ? (isOK + " " + core_version) : (isMAYBE + " " + core_version) + (searchByCRCorFile.coreVersionFound !== "" ? (" vs " + searchByCRCorFile.coreVersionFound) : "")
                        }
                        detailed_line12_color: {
                            var coreMatched = false;
                            //search common value
                            const core_details = core_version.split(' ');
                            const core_details_found = searchByCRCorFile.coreVersionFound.split(' ');
                            if(core_details_found[0] === core_details[0]) coreMatched = true;
                            const core_details2 = core_version.split('-');
                            const core_details_found2 = searchByCRCorFile.coreVersionFound.split('-');
                            if(core_details_found2[0] === core_details2[0]) coreMatched = true;
                            return (coreMatched) ? "green" : "orange"
                        }
                        detailed_line13: {
                            return  frontend;
                        }
                        detailed_line14: {
                            return ((searchByCRCorFile.crcMatched === true) ? isOK : isNOK ) + " " + game_crc;
                        }
                        detailed_line14_color: {
                            return ((searchByCRCorFile.crcMatched === true) ? "green" : "red" )
                        }
                        detailed_line15: {
                            return ((searchByCRCorFile.fileMatched === true) ? isOK : isNOK ) + " " + game_name;
                        }
                        detailed_line15_color: {
                            return ((searchByCRCorFile.fileMatched === true) ? "green" : "red" )
                        }
                        // set focus only on first item
                        focus:{
                            //console.log("------Begin of Focus-------");
                            //console.log("api.internal.netplay.rooms.count : ", api.internal.netplay.rooms.rowCount() );
                            //console.log("availableNetplayRooms.selectedButtonIndex : ",availableNetplayRooms.selectedButtonIndex)
                            //console.log("Index : ",index)

                            if (index === availableNetplayRooms.selectedButtonIndex){
                                if(visible){
                                    return true;
                                }
                                else updateFocusIndex();
                            }
                            return false;
                        }
                        onActivate: {
                            if(!status_icon.includes(isNOK)){

                                //set data linked to this room that we want to display
                                //to display logo of this room
                                confirmDialog.game_logo = searchByCRCorFile.result.games.get(searchByCRCorFile.resultIndex).assets.logo;
                                //to display game name of this room
                                confirmDialog.game_name = searchByCRCorFile.result.games.get(searchByCRCorFile.resultIndex).title;
                                //to display player name of this room
                                confirmDialog.player_name = username
                                confirmDialog.has_password = has_password;
                                confirmDialog.has_spectate_password = has_spectate_password;

                                //set room
                                root.roomSelected = model;
                                //set search data
                                root.searchSelected = searchByCRCorFile;
                                //set game
                                root.gameSelected = searchByCRCorFile.result.games.get(searchByCRCorFile.resultIndex);

                                //to force change of focus
                                netplayTimer.running = false;
                                confirmDialog.focus = false;
                                confirmDialog.active = true;
                                //Save action states for later
                                actionState = "PlayOrView";
                                actionListIndex = index;
                                //to force change of focus
                                confirmDialog.focus = true;
                            }
                        }

                        onFocusChanged:{
						}

                        Keys.onPressed: {
                            //verify if finally other lists are empty or not when we are just before to change list
                            //it's a tip to refresh the KeyNavigations value just before to change from one list to an other
                            if ((event.key === Qt.Key_Up) && !event.isAutoRepeat) {
                                if (index !== 0) {
                                    availableNetplayRooms.selectedButtonIndex = index-1;
									KeyNavigation.up = availableNetplayRooms.itemAt(index-1);
								}
                                else {
									KeyNavigation.up = availableNetplayRooms.itemAt(0);
                                    availableNetplayRooms.selectedButtonIndex = 0;
								}
                            }
                            if ((event.key === Qt.Key_Down) && !event.isAutoRepeat) {
                                if (index < availableNetplayRooms.count-1) {
									KeyNavigation.down = availableNetplayRooms.itemAt(index+1);
                                    availableNetplayRooms.selectedButtonIndex = index+1;
								}
                                else {
									KeyNavigation.down = availableNetplayRooms.itemAt(availableNetplayRooms.count-1);
                                    availableNetplayRooms.selectedButtonIndex = availableNetplayRooms.count-1;
								}
                            }
                            container.contentY = Math.min(Math.max(0, y - (height * 0.7)), container.contentHeight - height);
                        }

                        Button {
                            id: playButton
                            property int fontSize: vpx(22)
                            height: fontSize * 1.5
                            text: qsTr("Play/View ?") + api.tr
                            visible: {
                                if(parent.focus && !status_icon.includes("\uf1c2")){
                                    return true;
                                }
                                else{
                                    return false;
                                }
                            }
                            anchors.left: parent.right
                            anchors.leftMargin: vpx(20)
                            anchors.verticalCenter: parent.verticalCenter
                            
							contentItem: Text {
                                text: playButton.text
                                font.pixelSize: fontSize
                                font.family: globalFonts.sans
                                opacity: 1.0
                                color: themeColor.textSectionTitle
                                horizontalAlignment: Text.AlignHCenter
                                verticalAlignment: Text.AlignVCenter
                                elide: Text.ElideRight
                            }
							
							background: Rectangle {
                                implicitWidth: 100
                                implicitHeight: parent.height
                                opacity: 1.0
                                border.color: themeColor.textSectionTitle
                                color: themeColor.textLabel
                                border.width: 3
                                radius: 25
                            }
                        }
                    }
                }				
				
				SectionTitle {
					text: qsTr("Dolphin") + api.tr
                    first: false
                    visible: false // hide for the moment
				}
			}
		}
	}

    Item {
        id: footer
        width: parent.width
        height: vpx(50)
        anchors.bottom: parent.bottom
        z:2

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
            text: qsTr("Exit") + api.tr
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

        //for the help to select to view friend only or not
        Rectangle {
            id: filterButtonIcon
            height: labelY.height
            width: height
            radius: width * 0.5
            border { color: "#777"; width: vpx(1) }
            color: "transparent"
            visible: {
                return true;
            }

            anchors {
                right: labelY.left
                verticalCenter: parent.verticalCenter
                verticalCenterOffset: vpx(1)
                margins: vpx(10)
            }
            Text {
                text: "Y"
                color: "#777"
                font {
                    family: global.fonts.sans
                    pixelSize: parent.height * 0.7
                }
                anchors.centerIn: parent
            }
        }

        Text {
            id: labelY
            text: friendsOnly ? (qsTr("All rooms") + api.tr) : (qsTr("Friends only") + api.tr)
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
                right: backButtonIcon.left; rightMargin: parent.width * 0.015
            }
        }

        //for the help to show game launchable ony or not
        Rectangle {
            id: detailButtonIcon
            height: labelX.height
            width: height
            radius: width * 0.5
            border { color: "#777"; width: vpx(1) }
            color: "transparent"
            visible: {
                return true;
            }
            anchors {
                right: labelX.left
                verticalCenter: parent.verticalCenter
                verticalCenterOffset: vpx(1)
                margins: vpx(10)
            }
            Text {
                text: "X"
                color: "#777"
                font {
                    family: global.fonts.sans
                    pixelSize: parent.height * 0.7
                }
                anchors.centerIn: parent
            }
        }

        Text {
            id: labelX
            text: launchableOnly ? (qsTr("All games") + api.tr) : (qsTr("Launchable games only") + api.tr)
            verticalAlignment: Text.AlignTop
            color: "#777"
            visible: {
                return true;
            }

            font {
                family: global.fonts.sans
                pixelSize: vpx(22)
                capitalization: Font.SmallCaps
            }
            anchors {
                verticalCenter: parent.verticalCenter
                verticalCenterOffset: vpx(-1)
                right: filterButtonIcon.left; rightMargin: parent.width * 0.015
            }
        }

        //for the help to launch game (only visible if launchable)
        Rectangle {
            id: validButtonIcon
            height: labelA.height
            width: height
            radius: width * 0.5
            border { color: "#777"; width: vpx(1) }
            color: "transparent"
            visible: true
            anchors {
                right: labelA.left
                verticalCenter: parent.verticalCenter
                verticalCenterOffset: vpx(1)
                margins: vpx(10)
            }
            Text {
                text: "A"
                color: "#777"
                font {
                    family: global.fonts.sans
                    pixelSize: parent.height * 0.7
                }
                anchors.centerIn: parent
            }
        }

        Text {
            id: labelA
            text: qsTr("play/view game") + api.tr
            verticalAlignment: Text.AlignTop
            color: "#777"
            visible: true
            font {
                family: global.fonts.sans
                pixelSize: vpx(22)
                capitalization: Font.SmallCaps
            }
            anchors {
                verticalCenter: parent.verticalCenter
                verticalCenterOffset: vpx(-1)
                right: detailButtonIcon.left; rightMargin: parent.width * 0.015
            }
        }
    }
}
