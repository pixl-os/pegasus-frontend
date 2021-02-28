//
// Created by matthieu on 12/09/15.
//
#pragma once

#include <utils/IniFile.h>
#include <utils/cplusplus/StaticLifeCycleControler.h>

class RecalboxConf : public IniFile, public StaticLifeCycleControler<RecalboxConf>
{
  public:
    /*!
     * @brief Confstructor
     * @param initialConfigOnly true if only the original file has to be loaded
     */
    explicit RecalboxConf();

    /*!
     * @brief Called when file has been saved
     */
    void OnSave() override;
    /*
     * Direct Implementations
     */

    bool GetCollection(const std::string& name) const { return AsBool(std::string(sCollectionHeader).append(1, '.').append(name), false); }
    RecalboxConf& SetCollection(const std::string& name, bool on) { SetBool(std::string(sCollectionHeader).append(1, '.').append(name), on); return *this; }

    std::string GetPad(int index) const { return AsString(std::string(sPadHeader).append(Strings::ToString(index)), ""); }
    RecalboxConf& SetPad(int index, const std::string& padid) { SetString(std::string(sPadHeader).append(Strings::ToString(index)), padid); return *this; }

    std::string GetPadPegasus(int index) const { return AsString(std::string(sPadHeaderPegasus).append(Strings::ToString(index)), ""); }
    RecalboxConf& SetPadPegasus(int index, const std::string& padid) { SetString(std::string(sPadHeaderPegasus).append(Strings::ToString(index)), padid); return *this; }

    /*
     * System keys
     */

    static constexpr const char* sSystemEmulator             = "emulator";
    static constexpr const char* sSystemCore                 = "core";
    static constexpr const char* sSystemRatio                = "ratio";
    static constexpr const char* sSystemSmooth               = "smooth";
    static constexpr const char* sSystemRewind               = "rewind";
    static constexpr const char* sSystemAutoSave             = "autosave";
    static constexpr const char* sSystemShaders              = "shaders";
    static constexpr const char* sSystemShaderSet            = "shaderset";
    static constexpr const char* sSystemFilterAdult          = "filteradultgames";
    static constexpr const char* sSystemRegionFilter         = "regionfilter";
    static constexpr const char* sSystemFlatFolders          = "flatfolders";
    static constexpr const char* sSystemSort                 = "sort";

    /*
     * Key headers
     */

    static constexpr const char* sCollectionHeader           = "emulationstation.collection";

    /*
     * Keys
     */

    static constexpr const char* sGlobalRatio                = "global.ratio";
    static constexpr const char* sGlobalSmooth               = "global.smooth";
    static constexpr const char* sGlobalRewind               = "global.rewind";
    static constexpr const char* sGlobalAutoSave             = "global.autosave";
    static constexpr const char* sGlobalShaders              = "global.shaders";
    static constexpr const char* sGlobalShaderSet            = "global.shaderset";
    static constexpr const char* sGlobalQuitTwice            = "global.quitpresstwice";
    static constexpr const char* sGlobalHidePreinstalled     = "global.hidepreinstalledgames";
    static constexpr const char* sGlobalIntegerScale         = "global.integerscale";
    static constexpr const char* sGlobalShowFPS              = "global.showfps";
    static constexpr const char* sGlobalInputDriver          = "global.inputdriver";

    static constexpr const char* sHostname                   = "system.hostname";

    static constexpr const char* sWifiEnabled                = "wifi.enabled";
    static constexpr const char* sWifiSSID                   = "wifi.ssid";
    static constexpr const char* sWifiKey                    = "wifi.key";

    static constexpr const char* sAudioVolume                = "audio.volume";
    static constexpr const char* sAudioMusic                 = "audio.bgmusic";
    static constexpr const char* sAudioGameClip              = "audio.gameclip";
    static constexpr const char* sAudioOuput                 = "audio.device";

    static constexpr const char* sScreenSaverTime            = "emulationstation.screensaver.time";
    static constexpr const char* sScreenSaverType            = "emulationstation.screensaver.type";
    static constexpr const char* sScreenSaverSystemList      = "global.demo.systemlist";

    static constexpr const char* sPopupHelp                  = "emulationstation.popoup.help";
    static constexpr const char* sPopupMusic                 = "emulationstation.popoup.music";
    static constexpr const char* sPopupNetplay               = "emulationstation.popoup.netplay";

    static constexpr const char* sThemeGeneric               = "emulationstation.theme.";
    static constexpr const char* sThemeCarousel              = "emulationstation.theme.carousel";
    static constexpr const char* sThemeTransition            = "emulationstation.theme.transition";
    static constexpr const char* sThemeFolder                = "emulationstation.theme.folder";

    static constexpr const char* sBrightness                 = "emulationstation.brightness";
    static constexpr const char* sClock                      = "emulationstation.clock";
    static constexpr const char* sShowHelp                   = "emulationstation.showhelp";
    static constexpr const char* sShowGameClipHelpItems      = "emulationstation.showgamecliphelpitems";
    static constexpr const char* sQuickSystemSelect          = "emulationstation.quicksystemselect";
    static constexpr const char* sFilterAdultGames           = "emulationstation.filteradultgames";
    static constexpr const char* sFavoritesOnly              = "emulationstation.favoritesonly";
    static constexpr const char* sShowHidden                 = "emulationstation.showhidden";

    static constexpr const char* sFirstTimeUse               = "system.firsttimeuse";
    static constexpr const char* sSystemLanguage             = "system.language";
    static constexpr const char* sSystemKbLayout             = "system.kblayout";
    static constexpr const char* sSystemManagerEnabled       = "system.manager.enabled";

    static constexpr const char* sSecurityEnabled            = "system.security.enabled";
    static constexpr const char* sOverclocking               = "system.overclocking";
    static constexpr const char* sOverscan                   = "system.overscan";

    static constexpr const char* sKodiEnabled                = "kodi.enabled";
    static constexpr const char* sKodiAtStartup              = "kodi.atstartup";
    static constexpr const char* sKodiXButton                = "kodi.xbutton";

    static constexpr const char* sScrapperSource             = "scraper.source";
    static constexpr const char* sScrapperGetNameFrom        = "scraper.getnamefrom";
    static constexpr const char* sScrapperRegionFromFilename = "scraper.extractregionfromfilename";

    static constexpr const char* sScreenScraperLogin         = "scraper.screenscraper.user";
    static constexpr const char* sScreenScraperPassword      = "scraper.screenscraper.password";
    static constexpr const char* sScreenScraperRegion        = "scraper.screenscraper.region";
    static constexpr const char* sScreenScraperLanguage      = "scraper.screenscraper.language";
    static constexpr const char* sScreenScraperMainMedia     = "scraper.screenscraper.media";
    static constexpr const char* sScreenScraperThumbnail     = "scraper.screenscraper.thumbnail";
    static constexpr const char* sScreenScraperVideo         = "scraper.screenscraper.video";
    static constexpr const char* sScreenScraperWantMarquee   = "scraper.screenscraper.marquee";
    static constexpr const char* sScreenScraperWantWheel     = "scraper.screenscraper.wheel";
    static constexpr const char* sScreenScraperWantManual    = "scraper.screenscraper.manual";
    static constexpr const char* sScreenScraperWantMaps      = "scraper.screenscraper.maps";
    static constexpr const char* sScreenScraperWantP2K       = "scraper.screenscraper.p2k";

    static constexpr const char* sNetplayEnabled             = "global.netplay.active";
    static constexpr const char* sNetplayLogin               = "global.netplay.nickname";
    static constexpr const char* sNetplayLobby               = "global.netplay.lobby";
    static constexpr const char* sNetplayPort                = "global.netplay.port";
    static constexpr const char* sNetplayRelay               = "global.netplay.relay";

    static constexpr const char* sRetroAchievementOnOff      = "global.retroachievements";
    static constexpr const char* sRetroAchievementHardcore   = "global.retroachievements.hardcore";
    static constexpr const char* sRetroAchievementLogin      = "global.retroachievements.username";
    static constexpr const char* sRetroAchievementPassword   = "global.retroachievements.password";

    static constexpr const char* sStartupGamelistOnly        = "emulationstation.gamelistonly";
    static constexpr const char* sStartupSelectedSystem      = "emulationstation.selectedsystem";
    static constexpr const char* sStartupStartOnGamelist     = "emulationstation.bootongamelist";
    static constexpr const char* sStartupHideSystemView      = "emulationstation.hidesystemview";

    static constexpr const char* sMenuType                   = "emulationstation.menu";
    static constexpr const char* sHideSystemView             = "emulationstation.hidesystemview";
    static constexpr const char* sBootOnGamelist             = "emulationstation.bootongamelist";
    static constexpr const char* sForceBasicGamelistView     = "emulationstation.forcebasicgamelistview";

    static constexpr const char* sCollectionLastPlayed       = "emulationstation.collection.lastplayed";
    static constexpr const char* sCollectionMultiplayer      = "emulationstation.collection.multiplayer";
    static constexpr const char* sCollectionAllGames         = "emulationstation.collection.allgames";

    static constexpr const char* sCollectionArcade           = "emulationstation.arcade";
    static constexpr const char* sCollectionArcadeNeogeo     = "emulationstation.arcade.includeneogeo";
    static constexpr const char* sCollectionArcadeHide       = "emulationstation.arcade.hideoriginals";
    static constexpr const char* sCollectionPosition         = "emulationstation.arcade.position";

    static constexpr const char* sUpdatesEnabled             = "updates.enabled";
    static constexpr const char* sUpdatesType                = "updates.type";

    static constexpr const char* sPadHeader                = "emulationstation.pad";
	static constexpr const char* sPadHeaderPegasus         = "pegasus.pad";

    static constexpr const int sNetplayDefaultPort           = 55435;
};
