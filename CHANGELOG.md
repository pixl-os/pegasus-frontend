# Change Log
All notable changes to this project will be documented in this file (focus on change done on recalbox-integration branch).

## [pixL] - yyyy-mm-dd - vx.x.x
- GameOS-pixL Theme:
	- optimize scan folder for load all media download by scraper
	- extraction of this theme from Pegasus (Default themes will be avilable from share_init/themes now)

- Fixes:
	- wifi-first-activation-not-list-proposed #[13]
	- fix up to option WifiNetwork not work in setting menu if wifi enabled

- Features:
	- add system videos from 'share/videos' directory in collections (to be used with Shinretro theme)
	- add volume only for video boot
	- translation about: parameter lists, vulkan driver, boot video volume
	- gamepad editor custom view for N64 Controllers (switch one, 8bitdo one, original ones using adapter)
	- support of +r/-r and -y/+y axis management for buttons of right stick as for N64 controllers

- News:
	- Add update online for supermodel, citra-emu, pcsx2, dolphin-emu, libretro-mame, xemu

## [recalbox-integration] - 2022-09-12 - v0.0.8

- New API features:
	- add System 'type', 'releasedate' & 'manufacturer' as new info from systemlist.xml and accessible from api.colletions
	- add new property on api.collections for themes to be able to call ressources from Screen Scraper using 'ScreenScraperId'

- Theme translation feature support:
	- add translator and .qm loading for theme from /lang theme directory
	- use en language by default if no file other language available (to force reload)

- Multi-windows support:
	- add capacity to keep theme loaded in pegasus or not
	- add any new way to launch game in multi-windows mode
	- add options for multi-windows and theme keep loaded 
	- add best workdir management and pid check in a simple way to launch in background
	- add time to well check the pid
	- add launchedgamefile property to manage state of launch from api now
	- add api.launchedgame to know which game is running
	- add guide key in pegasus to be take into account
	- add global variable for guide button pressed for frontend & theme

- GameOS-pixL Theme:
	- new design management : include a designer for main view + vertical List feature
	- emulator loading improvements : add api usage to be compatible with Pegasus multi-windows feature
	- Multi-languages-support : introduce translation capacity in theme using linquist tools
	- select random game in games list with R1+L1 (from Grid or VerticalList)

- rework video settings:
	- change cmd awk: remove all cat xrandr.tmp to read in awk cmd
	- remove multivaluebox not used from qml file
	- force write parameters before save in recalbox.conf and to launch script

- Other features:
	- add sound in volume settings
	- change favorites.txt path in the share to saves/usersettings/
	- system-information: use tmp file for reading and add vulkan information
	- add translation in Pegasus loading phase (in cpp code)
	- add translation in Pegasus parameterlists (in cpp code)
	- New "qmlutils" component to manage horizontal scrolling
	- add icons displayed for generix x-box pad for xbox 360/One/Series
	- add option to force vulkan video driver (only for nvidia-driver)
	- add translation for vulkan video driver menu
	- add online upgrade for libretro-mame 

- Fixes:
	- several fixes on QML source codes (var to other type, etc..)
	- fix log error in cmd to silent errors
	- fix typo on informationSystem for 'thread' and 'vulkan'
	- fix "Information System" to improve performance on display (and for vulkan info)
	- Fix shaders selection for vulkan and opengl
	- change url to download online versions from new repo

## [recalbox-integration] - 2022-07-08 - v0.0.7
- fix on management of shaders display/selection
- i915 Driver force-probe activation integration (to correct some issues with sound outputs)
- fix refresh functions for wifi, bluetooth and settings view (due to bad timeout parameter)
- add fr translation for i915 force-probe menu + fixes (wifi notes)
- GameOS-pixL:
	- adding logos for new 'naomi2' system and also new 5 logos for screenshots 'system' and also ports system

## [recalbox-integration] - 2022-06-03 - v0.0.6
- GameOS-pixL:
	- adding logos for new 'xbox' & 'chihiro' system
	- fix to update 5 logos for 'odyssey2' system
	- fix to use L1/R1 for letter nav & L2/R2 for system nav in platform page
	- fix on gridview width in platform page
	- Introduction of overlays & logos options in gameView of this theme
	- Usage of overlays also in demo mode of this theme
	- adding logos for new 'triforce' system
	- adding "beta" logo on system using an emulator 'low'
- fix for controllers to deactivate trim for names with spaces
- fix to add new system logos in qrc for embedded GameOS-pixL theme
- Wifi implementation:
	- regroup 'networks' parameters in the same section in settings menu (remove duplicate system section in the same time)
	- add view to read available wifi access points.
	- add icons in font to manage signal/frequency
	- add function/button to enable/disable wifi
	- add dialog box to enter key, select priority
	- add management of virtual keyboard
	- fix to display virtual keyboard only for 'visible' edition field
	- change to have 'connect' button only for 'priority one' wifi
	- Add check of IP/Wifi connection to well display it in Settings menu
- global meta data improvements:
	- add more inputs take from systemlist.xml (keep compatibility with es_systems.cfg)
	- fix to propose netplay only for 'libretro' core for the moment
	- confirm some info about some parameters from systemlist.xml and .corenames files
- Lang:
	- Add french translation for new wifi feature
	- Update all lang files to be ready for translation after wifi feature.
	- fix pixL issue 15

## [recalbox-integration] - 2022-05-06 - v0.0.5
- new feature including nvidia drivers installation as udpate proposed by Pegasus (need reboot)
- improvement and fix to well manage updates remotly but also local.
- fix to clarify the progress bar animation and using colors on results (green for ok, red for not ok)
- fix on lang: update for controller helps/views [Thanks Sebio]
- manage multiversions by updates repo to manage compatibility and several versions installable (as for nvidia drivers)
- fix to clean files in /tmp for updates
- fix on icon management of udpates
- index of selected version for udpates introduced to avoid mistmatch for display and during installation

## [recalbox-integration] - 2022-04-23 - v0.0.4
- lang: bump last translation fr (update on bios, restart and controller menu)
- introduction of online update for cores
- first updatable core: libretro fbneo

## [recalbox-integration] - 2022-04-21 - v0.0.3
- menu: refact menu advanced controller
- menu: remove focus on toogle option 
- icon: fix aligned icon on text 
- icon: fix file format for the 3 new icons
- menu: enable first true on ps3 controller drivers
- controllers improvements:
	- change way to find mapping (es_input -> sdl2)
	- fix asynchronous disconnection using bluetooth
	- set way to manage order  of player/device
	- fix bluetooth to remove not well paired device or not identified as paired.
	- fix bluetooth to add devices already paired in recalbox.conf
	- fix on icon used when name/service is not defined
	- add vendor search and save when restore of paired devices
	- bluetooth : improve verification/timing for devices already paired
	- add icon for Snakebyte idroid:con
	- Introduce parameter and menu to be able to reset bluetooth at each start of Pegasus
	- fix on battery reading/refresh from bluetooth menu
	- add icon for 8BitDo SN30pro+
	- best icon management to use globally and from main.qml
	- add management of SDL instance id to see change/move
	- icon: change positionning in bluetooth device and controllers list
	- icon: to add arcade sticks (8 buttons) black & white
	- game controller database: updated to accept SDL 2.0.16 format from SDL 2.0.14 
	- game controller database: add last version from https://github.com/gabomdq/SDL_GameControllerDB
	- add matching for drangonrise and xinmo using arcade panel icon
	- icon: add vertical double directions icon
	- simplebutton: hide/show underline and capacity to select
	- controllers: add selection, move icon and improve helps display
	- gamepad:  add more ids in gamepad object and to have more info
	- sdl2: rework introduced but still to move code in gamepadmanager
	- gamepadmanager: add more ids in gamepad creation
	- gamepad: first draft of rework on gamepad indexation (id, iid, index)
	- gamepad: add setting of device id for gamepad model
	- gamepad: clean recalbox.conf for gamepad(s) already disconnected
	- gampadeditor: fix to avoid bad effect when we remove device here
	- gamepad: to use index and not id now in some functions in qml/c++
	- sdl2: fix for build using SDL_JoystickDevicePathById
	- index: fix to update of index for all controllers during disconnect
	- udev: add code to integrate indexation from udev
	- gamepadlist: to edit directly the configuration from list
	- maxinputdevices: fix for best management of max input devices as global conf
	- icons: add detection of ultimarc j-pac as arcade panel device
	- controller: fix for better way to manage index for joystick 
	- custom pad tests:
		- snes: test gamepad images and way to have something customizable and generic
		- button: update to improve display of buttons on SNES
		- padbutton: definitive version managing recording/selection colors
		- layout: dpad snes highlight management as initial version
		- layout: dpad snes highlight management as improved version
		- gamepad_layout: dynamic loading of game controller layout
		- snes_layout: adding select, guide and start + parameters/cleaning
		- snes_layout: adding of L1/R1 & L2/R2 as shoulder/trigger
		- snes_layout: mapping management integration to avoid unused touch
		- nes_layout: adding switch online nes controller pictures 
		- nes_layout: first draft using ContainerCustom but still work ;-)
		- nes_layout: tested version using parameters and customizable layout
		- layouts: nes & snes layout using same QML codes by parameters
		- xbox360_layout: resources and first parameters added 
		- stick: completed management of sticks in "custom" layout set
		- xbox360: finalization of xbox360 use case
		- chore(cleaning): remove images not used finally
		- icons: use icon of sn30 pro+ for pro 2 from 8bitdo
		- pad: manage pad buttons as xbox vs snes/nes to switch a/b and x/y
		- icons: to well distinguish 8bitdo sn30 pro+/pro plus & pro 2
		- sticks: add red color during edition + some code cleanings
		- help: change details during edition of axis to precise up/left direction
		- hotkey: add info of "hotkey" near "guide" one
		- ps4_layout: add resources and parameters for ps4 ctrl layout
		- layout: change order of definition of L1/L2 or R1/R2 to avoid bad superposition
		- ps4_layout: support of dpad using independent buttons
		- layout: improve management of display and brightness/contrast
	- gamepadeditor: to be able to reset assignement of axis/button
	- hidname: test to get hidname more liable than name finally
	- sdl2: rework of maner to detect/manage mapping at controller connection
	- gamepadmanagersdl2: add way to get joystick path during debug on linux for dev
	- gamepadmanager: change process and way to well manage sdl2/esinput/custom mapping
	- sdl2manager: cleaning and optimization to well manage new naming
	- sdl2manager: optimization mapping affectation from name/guid 
	- icon-layout: to well manage icon/layout selection depending hidname
	- add xow daemon management for xbox one/series controllers
	- layout: force to default layout if doesn't exist for any controller
- sysinfo:
	- more info added as temp and gpu in 2 columns
	- merged methods to have all ways to get temps
	- fix to have best temperature display to ignore some cases and doubloon
	- last updates on gpus display and temperature parsing
	- lang : add last fr translation
- gamepad_manager_sdl2: some fixes of names management in mappings
- gamepadeditor: add custom way to elide long controller name due to adding of hid name now
- lang: add last fr translation
- confirm in title/comments that Sony part is only for PS3 sixasis
- bluetooth: some 'dev' logs deactivated and 'debug' ones improved
- bluetoohth: fix to restart bluetooth only during starting and not reloading after game session
- lang: new bump and all files are updated systematically on lupdate
- accountmain: add fix on SectionTitle to set font indendently
- gamepadeditor: add custom way to elide long controller name due to adding of hid name now
- controllersmenu: confirm in title/comments that Sony part is only for PS3 sixasis
- controllersmain: reduce controller icon of 10% and centralize verticaly

## [recalbox-integration] - 2022-02-12 - v0.0.2
- versionning: add version from git release and OS version in Pegasus
- localization: fix "american english" multiple menu display in buildroot
- add "-verbose" argument to configgen launching in case of debug activated
- introduce "information system" view:
	- add eth0/wlan0 in "information system"
- remove MenuBox.qml legacy code
- introduction of "virtual keyboard" component:
	- management of display or not of virtual keyboard
	- introduce InputPanel to manage VirtualKeyboard UI
	- TextFieldOption.qml done to replace progressively TextFiled.qml
	- add loader in inputPanel to access object from child view
	- new generic functions to manage virtual keyboard
	- active virtualkeyboard loader only if activated in settings
	- introduction of autoscroller for editbox using virtual keyboard
	- fix on appsettings to remove backspace keyboard touch as cancel command
	- fix in main to manage virtual keyboard in flickable
	- bump theme to sync virtual keyboard dev
- cleaning: comments some debug logs
- introduction of "updates" management feature:
	- first API functions and with structure to interact with QML
	- add parsing about assets
	- add scan structure for updates
	- adding visible condition and scroll text for description in detailedbutton
	- changes to integrate model and way to manage menu display in detailedbutton
	- optimize visibility of picture and word wrapping in detailedbutton
	- improve parrallel download of json information
	- improve assets management from github
	- verify version using vX.Y.Z format and manage beta version
	- add tag in note of updates
	- simplify way to use tag without annotate it
	- add download manager and progress bar
	- add selection of version index depending of beta flag
	- modify column width to adapt with preview display in detailedbutton
	- remove releaseTitle and keep only tag in title
	- fix updates class in case of pre-release take into account
	- add picture as png logo in generic dialog
	- optimized version using until 20 parallel downloaders
	- improve resize, margin depending data to display in detailedbutton
	- manage icon and picture online from repo
	- fix to remove "return" in description from repo
	- add unit for total assets size
	- change frequency of repo check and timer runnings
	- add background description using color from theme in detailedbutton
	- add management of installation steps and skeleton to run process
	- fix in mainmenu to manage when "updates" button is visible for key nav
	- introduction of progressbar with green and red ones.
	- errorCode management added
	- add restart and reboot using errorCode for updates
	- bump theme to sync virtual keyboard dev
- restart feature added in menu with popup of confirmation
- introduction of "Bios Checking menu":
	- fix bios info view
	- add button help view 
	- fix many property 
	- introduction of API with md5 calculation for bios
	- integration of bios api in QML interface
- rename NetplayInformation to NetplayRooms
- add display of version for all standalone emulator also as for libretro ones
- improvements on loading performance:
	- some metadata processing improvements
	- add skraper media option
	- tentative to use multithread and multicores (cancelled)
	- fix to well display the name of gamelist under parsing
	- change list of collections in game by a simple collection
	- cleaning some debug/info logs
	- remove legacy filtering about arcade games
	- optimization loading versions detail of standalone cores
	- fix support of "hidden" tag from gamelists
	- bump gameos theme for perf-loading-improvements

## [recalbox-integration] - 2021-12-31 - v0.0.1
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

