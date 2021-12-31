# Change Log
All notable changes to this project will be documented in this file (focus on change done on recalbox-integration branch).

## [recalbox-integration] - 2021-12-31
- fix controllers: change delimiter in recalbox.conf for controller parts (to avoid issue for controller name with ":")
- fix controllers: after test and check of name '|' delimiter seems the best
- fix bluetooth: add a connect command after recalpair
- fix bluetooth: to increase timeout from 30s to 60s for some cases
- fix in es_state.inf lists for game without gamelist data
- overlay: add on/off option from menu
- translation: update french ones
- video: settings display
- video: add component xandr
- video: add toogle option and add button to apply
- menu: color and size of slider and switch
- video: add two parameter list for position and rotation xrandr
- video: change menu input name and rework rollable menu
- video: fix key name for primary and secondary screen
- bluetooth: add legacy "buggy" scripts if needed
- system api: add parameters to manage escaped characters or not in run command
- bluetooth: remove escaped characters to improve legacy pair script
- system api: new async command way
- bluetooth: using runAsync function from API
- bluetooth: add logs in searchDeviceInLists
- bluetooth: correct matching in case of legacy scanning
- keys:  add management of new key event for Netplay menu access
- netplay: introduction of netplay information view
- netplay: introduction of friend's rooms
- netplay: management of retroarch lobby/reading list from json downloaded.
- netplay: adding logo/icons to display and using colors
- netplay: optimization on list refresh and memory management
- netplay: usage of searchGame component to search by CRC and file name
- netplay: display of media as logo and screenshot for the moment in the netplay information buttons
- netplay: management of case using "00000000" crc value
- netplay: management of cores version/long name display/comparaisons using system/configs/retroarch.corenames file
- netplay: new dialog box to select frineds and passwords before to join or create room.
- netplay: add lob to ping and know latency
- netplay: add telnet using ip/port checking before to launch retroarch and avoid long black screen display when room is finally not available
- netplay: introduction of launchNetplay() from game and gameFile object.
- netplay: add function in main.qml (for all themes) to check netplay capacity for a game
- gameOS: add icons for netplay room using 'select'
- gameOS: add button in GameView to play game using netplay (only for system using a core compatible)
- netplay: add spinner during loading/refresh of lobby
- netplay: need to activate to have access to lobby and button display.
- netplay: set to "Anonymous" nickname if netplay activated but nickname empty
- gameOS: introduction of L1/R1 in gameview to change game quickly in a same system
- gameOS: demo mode introduced with parameters in Gamedetails settings
- gameOS: fix on L2/R2 usage in system view
- project-cd: add png timer and main popup cd
- project-cd: add personalised popup
- project-cd: remove tmp file on launch eject or back
- project-cd:  change cat to grep with -s option for silent log
- project-cd: running popup on splaslayer complete
- single play: introduction of new way to run an independnat game/rom (outside a list or/and share)
- single play: add api to find system from shortname, to set file path and title(optional)
- single play: add api to "connect" game to launcher
- single play: manage specifically case for path using "crdom://"
- project-cd: update cdRomDialog to manage directly icon/cd picture
- project-cd: add launch api for cdrom
- project-cd: add default png for many console 
- video: fix parameter list video
- menu: add icons for entry menu and sections
- bump last version of gameOS.

## [recalbox-integration] - 2021-10-13
- Fix loading bar progress (upper than 100% were possible)
- bump last gameOs-pixL theme for :
	- fix settings for 'play stats' conf
	- add new feature to change automatically favorite displayed in header of showcaseview
	- add play time, play count and last played in game info and also in settings
	
## [bluetooth-controllers-feature] - 2021-10-12
- new menu to integrate Bluetooth devices (My Devices, Discovered Devices, Ignored Devices)
- new parameters for bluetooth features
- usage of QTbluetooth
- restart regularly bluetooth to improve checking
- manage several type of search device: legacy (still to test), device discovery, full service discovery, short service discovery
- usage API to get vendor name from mac address
- compare known devices and discovered devices to avoid doublons
- manage selections of items between lists of devices
- reading existing bluetooth device from recalbox.conf
- management of icon dynamically from keywords/types
- new dialog box to have '3 choices' dialog box
- introduction of 2 new api.internal.system to run shell commands and scripts
- manage/resize icons in dialogbox
- added options for pairing methods.
- add parameters to hide: no name and unknown vendor
- add checking of pairing success
- add icon for pairing, connected
- add logo of controllers depending of name for several devices as controllers, audio speaker and headset
- add info/logo for battery capacity (only for Nintendo Switch and Sony PS4 devices for the moment)
- create a command to know if we are in debug or not for bluetooth testing based on hostname ;-)
- add disconnect feature (cool for speakers ;-)
- add function in qml to clean shell command using new api.internal.system.run
- fix when no network to unblock UI
- add icon in font for joycon (r/l) + switch pro controller
- map new icons in listmodel for devices icons
- fix gamepadeditor on new controller view displayed
- display now list of all controllers connected in menu (for future use and change order)

## [recalbox-integration] - 2021-09-27
- bump updated sortfilterproxymodel

## [loading-bar-improvements] - 2021-09-27
- improved provider progress reporting
- add more informatin and steps

## [app-close-menu-renewal-for-qt-creator-debug] - 2021-09-15
- change to "PEGASUS (pixL version)"
- renewal close app feature for debug usage / condition of display inversed (not available by default)

## [controller-not-known-bug] - 2021-09-08
- fix to correct issue with "unknown" controllers by SDL
- update logs info used for dev (log lines in comment)

## [recalbox-integration] - 2021-09-08
- GameOS bump with collections/arcade button/gameinfo improvements

## [recalbox-integration] - 2021-08-18
- fix on axis issue in ConfigField using inputType now.
- fix issue: 13-after-new-installation-keyboard-in-menu-fr-in-real-en
- fix issue: 11-bug-system-logo-style-at-first-start-up
- fix missing merge on gameos
- fix warning for binding loop on Recommended gamelist in gameos
- fix second warning on popup anchor ignored and unused
- bump last version of gameos with showcaseview loading improvement
- remove wizard/stepbystep help for the moment for gamepadeditor
- fix font to use the good icon for directions

## [controllers-improvements] - 2021-08-06
- manage other xbox controller for icon display
- new controller gamepad api event
- fix warning for controller unplugged from GamepadEditor
- cleaning loading subscreen & improve theme visibility
- fix warning on popup anchor ignored and unused
- improve theme visibility during animations
- draft of dialogbox for new controller detected
- to add information in Gamepad Editor qml file
- dialog box to manage "continue" using any input
- add '<' and '>' characters to indicate horizontal list
- properties for new controller in gamepad editor
- use blue for pressed inputs (background and field)
- change Font to have '<' and '>' as one used in menu
- hold down A to edit any input now
- activate hold down to activate all inputs edition
- correct a warning due to bad assignment
- display red color immediately when hold down reach
- manage red color of recording for all inputs
- add help for directions and change some text
- add index for new controller in gamepad editor
- "dynamic help" displayed depending context

## [systemlist-romfsv2-integration] - 2021-08-04
- create base for new systems list (to keep ES with ROMFSV2)
- first version compatible with systemlist.xml
- systemlist to be search in share_init/.emulationstation also

## [system-parameterlist] - 2021-07-17
- first version using system command
- fix for management empty command output to avoid crash
- add public function to reload any ini file
- add runCommand and reloadParameters from API
- update log details for ParametersList

## [add-shaders-option-in-menu] - 2021-07-06
- add option to select prefered shaders
- fix mistake in advanced settings
- fix to manage better empty string as default/"none" value in parameters list
- fix header/title in menu using elide from right if title too long
- bump lang:
	- fix traduction for shaders
	- fix on mistake in advanced settings
	- fix on emulatorconf: base and fr lang
	- fix netplay trad
	- fix mistake in fr translation
	
## [controllers-improvements] - 2021-07-06
- first popup implementation:
	- to have title, message and delay as popup's parameter
	- tentative to manage dynamic height/number of line (cancelled for the moment)
	- first version of popup using resize of text (cancelled for the moment)
	- add icon support in ShowPopup
- add popup for disconnect controller in gamepad manager
- add icon for driving wheel in police
- add icon support in qml and gamepad manager

## [recalbox-integration] - 2021-06-30
- bump GameOS : last version without pdfjs
- bump GameOS: less warning and wait update from launchgame

## [retroachievements-management] - 2021-06-29
- robustness/controls index to avoid out of range
- add signals/slots to communicate/free with QML
- add try/catch during init/udpate to avoid crash
- using last GameOS-Pixl Theme (game-retroachievements-fix)

## [retroachievements-management] - 2021-06-28
- add api entry in Game
- add Meta data provider for retroachievements
- manage meta data simpler for retroachievements
- rcheevos v10.1.0 code integration
- implementation/optimization/cache for RA Metadata
- linking done for libzip
- process to manage arcade zip vs file zipped
- add init/update functions using network or cache
- remove backslash if in login/password
- add 3 additional get commands + fixes on logs
- clean cache on update + fix for ID selection
- add cdfs dependencies to calculate cd hash
- add raHash in Game data as temporary storage
- clean to remove logs of debug
- clean debug logs + fix for cd + hashes saving
- add new files in themes.qrc

## [logopng-optimisation] - 2021-06-27
- change splash logo to gif
- bump submodule

## [rework-menu] - 2021-06-27
- rework parameter menu
- fix double 'en' on language list

## [10-text-correction-in-netplay-spectator-(pegasus)] - 2021-06-23
- fix: replace viewer to netplay spectator
- fix bad traduction
- comment english language traduction and bump lang
- remove uneeded english trad

## [9-keyboard-qwerty-retroachievement-menu-and-netplay] - 2021-06-22
- fix language and keybord layout
- directly set layout keyboard
- use setxkbmap for set keyboard layout > ParameterList.cpp 
- fix layout en to gb for setxkbmap > ParametersList.cpp
- fix indent et remove test > Recalbox.cpp

## [recalbox-integration] - 2021-06-18
- auto save text field entry
- fix bad version for qtquick, qtquick layout and qt multimedia
- fix width an height for multivaluebox
- multi fix 

## [splash-layer-pegasus] - 2021-06-14
- integration splash screen startup pixL
- fix missing add pegasus logo in qrc (add new file in frontend.qrc / resize pixL logo)
- fix color bar
- fix default white bar
- re-enable loading information
- more big pegasus logo ;)

## [change-logo-style-in-system-view] - 2021-06-14
- disable color mask on logo systems

## [recalbox-integration] - 2021-06-10
- GameOs:
	- bump all qt5 module on lastest version
	- add logo sets systems on : white, black, color, steel, carbon
	- Disable color mask on systems logo 
	
- add missing logo in theme.qrc

## [recalbox-integration] - 2021-06-04
- add missing description
- add menu selection for ps3 driver
- rework sound slider
- cleaning Menu
- add fps option in menu
- bump submodule lang
- menu to add text entry
- fix missing qstr
- fix remove uneeded option and cleaning account main
- controller : add function to find by guid only from es_input.cfg
- controller : finally just recopy sdl2 conf to es_input if needed
- controller : recopy es_input conf in user conf if empty
- theme : change pegasus grid to game os as default submodule included
- fix gamesos theme build remove pdfjs folder


## [recalbox-integration] - 2021-05-24
- change lang module to use forked version
- use repo forked in pegasus.pro
- new en/fr language file for recalbox-integration menus
- lang module merge remote to use branch recalbox-integration
- fix mouse issue/display in menu (using also new parameter in settings menu)
- best management of up/down navigation in menu

## [recalbox-integration] - 2021-05-23
- creation of this changelog file

## [emulator-core-parameter-selection] - 2021-05-22
- change parameterlist to work for global and {system}.ratio
- to have list of system in the menu
- to have parameters by system for emulator/core
- take into account core/emulator from recalbox.conf

## [sound-menu-issue] - 2021-05-14
- fix to add additional ES mode not supported

## [performance-improvements] - 2021-05-06
- add hash and genreid accessible from theme
- add support of gamelist only to have quicker loading
- add timings info + 'Stats' keyword for filtering

## [recalbox-integration] - 2021-04-22
- fix on audiomode : correct issue of default value empty when parameter doesn't exist in recalbox.conf

## [sound-management-integration] - 2021-04-20
- add way to select fonts in multivalueoption qml file
- to add volume using slider in menu 
- management of volume and mute from parameterslist/recalbox

## [add-storage-device] - 2021-04-20
- add recalbox system and storage device
- add list and menu storage

## [sound-management-integration] - 2021-04-19
- fix to improve instance creation for board/audiocontroller
- add internal value management
- with parameterlists using displayable and internal lists
- add font including private icons
- fix to keep Roboto-Regular font by default
- change logs places for .ini files to ahve its as info
- add support of recalbox-boot.cfg from recalbox api

## [sound-management-integration] - 2021-04-15
- cleaning to improve log/comments/adapt existing codes
- update utils files from last ES version
- sound by pulseaudio using hardware board/audiocontroller


## [metadata-improvements] - 2021-04-11
- add metatype to match with asset type
- add BuildDate, Buildversion, BuildName as Meta
- improve ES assets usage
- add path to use themes from share
- add and intiate QTWebEngine in pegasus
- add manual/pdf support as asset
- embbed disabling of sandbox for this module
- to add QML Keys simulation for game controller

## [recalbox-integration] - 2021-03-30
- fix: PathCheck.cpp replace by PathTools.cpp in utils.pri
- fix: add PathTools

## [ui-integration] - 2021-03-29
- rebase from master
- disable many menu and settings
- fix crash on menu 
- rework settings menu
- change menu acces
- connect menu option to recalbox
- rework many menu box
- add list of shaders
- sade mighty things
- improve  virtual  keyboard
- fix missing themecolor variable
- change keyeditor  to interfacemain

## [controllers-integration] - 2021-03-29
- to get and save guid, name and path in recalbox.conf
- update from Recabox ES 7.2 utils
- add Es2Input in Providers::Es2 to load conf from es_input.cfg
- update to add keys and Set/Get for Pegasus Pad
- activate/deactivate log using 'emulationstation.debuglogs'
- add management of es_input.cfg (find and add input)
- fix problem of second game launched
- to add management of exception (using try/catch) + debug
- add save/update features for es_input.cfg
- fix to move recalboxConf instance creation in backend
- manage SDL2 controllers configuration using es_input.cfg
- option NO_LEGACY_SDL=1 could be used for QT Creator usage
- cleaning recalbox conf parts
- to manage hotkey on commun button (as select) + sign for axis
- userscripts for start/shutdown/reboot
- fix: issue corrected with a button during setting of pad
- draft of popup feature, not yet activated
- fix: no sign to set for right and left sticks on gamepad
- fix: cleaning and best method to detect sticks to avoid to sign

## [api-for-recalbox] - 2021-02-24
- add recalbox api (first version)
- add SetIntParameter and GetIntParameter for recalbox.conf
- add parameters list feature (for ratio and kb)

## [Buildroot-integration] - 2021-02-16
- Branch creation from pegasus master (for regular rebase)
- fix to reboot and shutdown compatible for buildroot 
- add compatibility with es_systems.cfg of recalbox
- add tags to manage and command options to overload
- add logs function/type/display for debug
- add color for debug log
- remove code unused
- serialization for configgen python command
- change replace_variables function parameters
- add system, core and emulator as launch command parameters
- add common emulators in collections
- add shortname, emulator and core to game
- get system, emulator and core from game/collection
- manage escaped path to load roms
- add management of priority to select the default emulator and  core
- add classes to manage recalbox.conf and other dependencies
- fix to manage python command and tearing down from front-end

