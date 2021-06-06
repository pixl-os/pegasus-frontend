# Change Log
All notable changes to this project will be documented in this file (focus on change done on recalbox-integration branch).

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

