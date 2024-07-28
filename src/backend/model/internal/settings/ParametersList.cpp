#include "ParametersList.h"
#include "Log.h"
#include "Recalbox.h"
#include "audio/AudioController.h"
#include "storage/StorageDevices.h"

#include <QDir>
#include <QDirIterator>

namespace {

/******************************* section to initial variables used by GetParametersList in same name *************************************/
QStringList ListOfInternalValue;

//! Storage devices
StorageDevices mStorageDevices;
/*
list of global and system values (example using snes system)
global or  snes.ratio=4/3 -> RATIO
global or  snes.shaders=/recalbox/share_init/shaders/scanline.glslp -> SHADERS -> TO DO

parameters for system to get from collection emulators and cores
snes.core=snes9x_next
neogeo.emulator=fba2x
*/

QString GetCommandOutput(const std::string& command)
{
    std::string output;
    char buffer[4096];
    FILE* pipe = popen(command.data(), "r");
    if (pipe != nullptr)
    {
        while (feof(pipe) == 0)
            if (fgets(buffer, sizeof(buffer), pipe) != nullptr)
                output.append(buffer);
        pclose(pipe);
    }
    return QString::fromStdString(output);
}

QStringList GetParametersList(QString Parameter)
{
    QStringList ListOfValue;

    //clean global internal values if needed
    ListOfInternalValue.clear();

    if (Parameter.endsWith(".ratio", Qt::CaseInsensitive) == true) // compatible for 'global.ratio' and '{system].ratio' (example: 'snes.ratio')
    {
        ListOfValue << QObject::tr("none") << QObject::tr("auto") << QObject::tr("square pixel") << QObject::tr("config")
                    << QObject::tr("custom") << QObject::tr("core provided")<< "4/3" << "16/9" << "16/10" << "16/15" << "21/9"
                    << "1/1" << "2/1" << "3/2" << "3/4" << "4/1" << "9/16" << "5/4" << "6/5" << "7/9" << "8/3" << "8/7" << "19/12"
                    << "19/14" << "30/17" << "32/9";
        /*## Set ratio for all emulators (auto,4/3,16/9,16/10,custom) - default value: auto / index 0
        global.ratio=auto */
        ListOfInternalValue << "none" << "auto" << "squarepixel" << "config"
                            << "custom" << "coreprovided" << "4/3" << "16/9" << "16/10" << "16/15" << "21/9"
                            << "1/1" << "2/1" << "3/2" << "3/4" << "4/1" << "9/16" << "5/4" << "6/5" << "7/9" << "8/3" << "8/7" << "19/12"
                            << "19/14" << "30/17" << "32/9";
    }
    else if (Parameter == "system.language")
    {
        /* pegasus language format :
        ar ,bs, de, en-GB, en, es, fr, hu, ko, nl, pt-BR, ru, zh, zh-TW */
        ListOfValue << "ar" << "bs" << "de" << "en-GB" << "en" << "es" << "fr"
                    << "hu" << "ko" << "nl" << "pt-BR" << "ru" << "zh" << "zh-TW";
        /*recalbox language format :
        ## Set the language of the system (fr_FR,en_US,en_GB,de_DE,pt_BR,es_ES,it_IT,eu_ES,tr_TR,zh_CN)
        system.language=en_US */
        ListOfInternalValue << "en_US" << "en_US" << "de_DE" << "en_GB" << "en_US" << "es_ES" << "fr_FR"
                            << "en_US" << "en_US" << "en_US" << "pt_BR" << "en_US" << "zh_CN" << "en_US";
    }
    else if (Parameter == "system.kblayout")
    {
        /* ## set the keyboard layout (fr,en,de,us,es)
        system.kblayout=us */
        ListOfValue << "us" << "fr" << "gb" << "de" << "es";
    }
    else if  (Parameter.endsWith(".screen.rotation", Qt::CaseInsensitive) == true)
    {
        /* for rotation xrandr output :
          --rotate normal,inverted,left,right */
        ListOfValue << QObject::tr("normal") << QObject::tr("inverted") << QObject::tr("left") << QObject::tr("right");
        ListOfInternalValue << "normal" << "inverted" << "left" << "right";
    }
    else if (Parameter == "system.video.screens.mode")
    {
        /* parameter List for mode :
        switch: when we plug a screen we switch to secondary one if connected
        clone: we replicate image between primary and secondary screen
        extended: when we ahve 2 screens, we extend to secondary one
        */
        ListOfValue << QObject::tr("switch") << QObject::tr("clone") << QObject::tr("extended");
        ListOfInternalValue << "switch" << "clone" << "extended";
    }
    else if (Parameter == "system.secondary.screen.position")
    {
        /* parameter List for xrandr option :
        for postion xrandr output :
          --left-of <output>
          --right-of <output>
          --above <output>
          --below <output>
    Only set for Marquee screen */
        ListOfValue << QObject::tr("above") << QObject::tr("below") << QObject::tr("left") << QObject::tr("right");
        ListOfInternalValue << "above" << "below" << "left" << "right";
    }
    else if (Parameter.endsWith(".shaderset", Qt::CaseInsensitive) == true)
    {
        /*
        ## Shader set
        ## Automatically select shaders for all systems
        ## (none, retro, scanlines)
        global.shaderset=none
        */
        ListOfValue << QObject::tr("none") << QObject::tr("retro") << QObject::tr("scanlines");
        ListOfInternalValue << "none" << "retro" << "scanlines";
    }
    else if (Parameter.endsWith(".shaders", Qt::CaseInsensitive) == true)
    {
        /*
        ## Set gpslp shader for all emulators (prefer shadersets above). Absolute path (string)
        global.shaders=/recalbox/share/shaders/myShaders.glslp
        select only compatible extension shaders in menu opengl(glslp) / vulkan(slangp)*/
        QString shadersext;
        QString filterext;
        // check vulkan option in recalbox.conf
        if (RecalboxConf::Instance().AsBool("system.video.driver.vulkan", false) == true)
        {
            shadersext = "*.slangp";
            filterext = ".slangp";
        }
        else
        {
            shadersext = "*.glslp";
            filterext = ".glslp";
        }

        // add none in list for disabled option if needed
        ListOfValue << QObject::tr("none");
        QString empty = "";
        ListOfInternalValue << empty;

        //read root directory
        // Define shaders path
        QDir shadersDir("/recalbox/share/shaders/");
        // Sorting by name
        shadersDir.setSorting(QDir::Name);
        QStringList files = shadersDir.entryList(QStringList(shadersext), QDir::Files);
        for ( int index = 0; index < files.count(); index++ )
        {
            QString file = files.at(index);
            //Log::debug(LOGMSG("File found in root : '%1'").arg(file));
            // set absolute path and extension for recalbox.conf
            ListOfInternalValue.append("/recalbox/share/shaders/" + file);
            // remove file extension on menu
            ListOfValue.append(file.replace(filterext, ""));
        }

        //read subdirectories
        QDirIterator it("/recalbox/share/shaders/",QDir::Dirs | QDir::NoDotAndDotDot, QDirIterator::Subdirectories);
        while (it.hasNext()) {
            QString dir = it.next();
            QString relativedir = dir;
            relativedir = relativedir.replace("/recalbox/share/shaders/","");
            //Log::debug(LOGMSG("Subdir : '%1'").arg(dir));
            QDir shadersSubDir(dir);
            // Sorting by name
            shadersSubDir.setSorting(QDir::Name);
            QStringList subfiles = shadersSubDir.entryList(QStringList(shadersext),QDir::Filter::Files,QDir::SortFlag::Name);
            for (int i = 0; i < subfiles.count(); i++ )
            {
                QString subfile = subfiles.at(i);
                //Log::debug(LOGMSG("File found in Subdir : '%1'").arg(subfile));
                // set absolute path and extension for recalbox.conf
                ListOfInternalValue.append(dir + '/' + subfile);
                // remove file extension on menu
                ListOfValue.append(subfile.replace(filterext, ""));
            }
        }
    }
    else if (Parameter.endsWith(".wine", Qt::CaseInsensitive) == true)
    {
        // add auto in list to let default value from configgen  if needed
        ListOfValue << QObject::tr("auto");
        QString empty = "";
        ListOfInternalValue << empty;
        //read subdirectories in /usr/wine
        QDirIterator it("/usr/wine/",QDir::Dirs | QDir::NoDotAndDotDot, QDirIterator::Subdirectories);
        while (it.hasNext()) {
            QString dir = it.next();
            QString relativedir = dir;
            Log::debug(LOGMSG("Directory found in Subdir : '%1'").arg(relativedir));
            //if contain /bin directory, we could consider that is a valid wine installed in pixL
            if(relativedir.endsWith("/bin")){
                QString fulldir;
                QString winename;
                //check if file wine or wine64 exists to detect a valid wine directory
                if (QFile::exists(relativedir + "/wine")) {
                    fulldir = relativedir + "/wine";
                    winename = relativedir;
                    winename = winename.replace("/usr/wine/","");
                    winename = winename.replace("/bin","");
                    // use name of directory from /usr/win for recalbox.conf
                    ListOfInternalValue.append(fulldir);
                    // remove file extension on menu
                    ListOfValue.append(winename + " (Wine)");
                }
                if (QFile::exists(relativedir + "/wine32")){
                    fulldir = relativedir + "/wine32";
                    winename = relativedir;
                    winename = winename.replace("/usr/wine/","");
                    winename = winename.replace("/bin","");
                    // use name of directory from /usr/win for recalbox.conf
                    ListOfInternalValue.append(fulldir);
                    // remove file extension on menu
                    ListOfValue.append(winename + " (Wine32)");
                }
                if (QFile::exists(relativedir + "/wine64")){
                    fulldir = relativedir + "/wine64";
                    winename = relativedir;
                    winename = winename.replace("/usr/wine/","");
                    winename = winename.replace("/bin","");
                    // use name of directory from /usr/win for recalbox.conf
                    ListOfInternalValue.append(fulldir);
                    // remove file extension on menu
                    ListOfValue.append(winename + " (Wine64)");
                }
            }
        }
    }
    else if (Parameter.endsWith(".wineappimage", Qt::CaseInsensitive) == true)
    {
        // add auto in list to let default value from configgen  if needed
        ListOfValue << QObject::tr("auto");
        QString empty = "";
        ListOfInternalValue << empty;
        //read "embedded" appimages file from /usr/wine :
        QDir wineDir("/usr/wine");
        // Sorting by name
        wineDir.setSorting(QDir::Name);
        QString ext = "*.AppImage";
        QString fileext = ".AppImage";
        QStringList files = wineDir.entryList(QStringList(ext), QDir::Files);
        for ( int index = 0; index < files.count(); index++ )
        {
            QString file = files.at(index);
            //Log::debug(LOGMSG("File found in root : '%1'").arg(file));
            ListOfInternalValue.append("/usr/wine/" + file);
            // remove file extension on menu
            ListOfValue.append(file.replace(fileext, ""));
        }
        //read "user" appimages file from /recalbox/share/save/usersettings/appimages
        QDir wineUserDir("/recalbox/share/save/usersettings/appimages");
        // Sorting by name
        wineUserDir.setSorting(QDir::Name);
        QStringList userfiles = wineUserDir.entryList(QStringList(ext), QDir::Files);
        for ( int index = 0; index < userfiles.count(); index++ )
        {
            QString file = userfiles.at(index);
            //Log::debug(LOGMSG("File found in root : '%1'").arg(file));
            ListOfInternalValue.append("/recalbox/share/save/usersettings/appimages/" + file);
            // remove file extension on menu
            ListOfValue.append(file.replace(fileext, ""));
        }
    }
    else if (Parameter.endsWith(".winearch", Qt::CaseInsensitive) == true)
    {
        // add auto in list to let default value from configgen  if needed
        ListOfValue << QObject::tr("auto");
        QString empty = "";
        ListOfInternalValue << empty;
        ListOfValue << "32 bits" << "64 bits";
        ListOfInternalValue << "win32" << "win64";
    }
    else if (Parameter.endsWith(".winver", Qt::CaseInsensitive) == true)
    {
        // add auto in list to let default value from configgen  if needed
        ListOfValue << QObject::tr("auto");
        QString empty = "";
        ListOfInternalValue << empty;
        ListOfValue << "Windows 10" << "Windows 8.1" << "Windows 8" << "Windows 7" << "Windows 2008" << "Windows Vista" << "Windows 2003" << "Windows XP" << "Windows 2000" << "Windows NT 4.0" << "Windows Millennium Edition" << "Windows 98" << "Windows 95" << "Windows 3.1";
        ListOfInternalValue << "win10" << "win81" << "win8" << "win7" << "win2008" << "vista" << "win2003" << "winxp" << "win2k" << "nt40" << "winme" << "win98" << "win95"  << "win31";
    }
    else if (Parameter.endsWith(".wineaudiodriver", Qt::CaseInsensitive) == true)
    {
        // add auto in list to let default value from configgen if needed
        ListOfValue << QObject::tr("auto");
        QString empty = "";
        ListOfInternalValue << empty;
        ListOfValue << "alsa" << "pulse";
        ListOfInternalValue << "alsa" << "pulse";
    }
    else if (Parameter == "system.selected.color")
    {
        /* "Original,Black,Gray,Blue,Green,Red" */
        ListOfValue << QObject::tr("Original") << QObject::tr("Dark Green") << QObject::tr("Light Green") << QObject::tr("Dark Gray")
                    << QObject::tr("Light Gray") << QObject::tr("Dark Red") << QObject::tr("Light Red") << QObject::tr("Dark Pink")
                    << QObject::tr("Light Pink") << QObject::tr("Dark Brown") << QObject::tr("Light Brown") << QObject::tr("Dark Blue")
                    << QObject::tr("Light Blue") << QObject::tr("Orange") << QObject::tr("Yellow") << QObject::tr("Turquoise")
                    << QObject::tr("Magenta") << QObject::tr("Purple") << QObject::tr("Steel") << QObject::tr("Stone");
        ListOfInternalValue << "Original" << "Dark Green" << "Light Green" << "Dark Gray"
                            << "Light Gray" << "Dark Red" << "Light Red" << "Dark Pink"
                            << "Light Pink" << "Dark Brown" << "Light Brown" << "Dark Blue"
                            << "Light Blue" << "Orange" << "Yellow" << "Turquoise"
                            << "Magenta" << "Purple" << "Steel" << "Stone";
    }
    else if (Parameter.endsWith(".color"))
    {
        /* "Original,Black,Gray,Blue,Green,Red" */
        ListOfValue << QObject::tr("Original") << QObject::tr("Black") << QObject::tr("White") << QObject::tr("Gray")
                    << QObject::tr("Blue") << QObject::tr("Green") << QObject::tr("Red") << QObject::tr("Purple");
        ListOfInternalValue << "Original" << "Black" << "White" << "Gray"
                            << "Blue" << "Green" << "Red" << "Purple";
    }
    else if (Parameter == "controllers.ps3.driver")
    {
        /*
         ## Choose a driver between bluez, official and shanwan
         ## bluez -> bluez 5 + kernel drivers, support official and shanwan sisaxis
         ## official -> sixad drivers, support official and gasia sisaxis
         ## shanwan -> shanwan drivers, support official and shanwan sisaxis
         controllers.ps3.driver=bluez
        */
        ListOfValue << "bluez" << "official" << "shanwan";
    }
    else if ((Parameter == "netplay.password.client") || (Parameter == "netplay.password.viewer"))
    {
        //global.netplay.nickname= ?
        ListOfValue << "|P/4/C-M/4/N|" << "[SpAcE.iNvAdErS]" << ">sUpEr.MaRi0.bRoSs<" << "{SoNiC.tHe.HeDgEhOg}" << "(Q/B/E/R/T-@;&?@#)"
                    << "~AnOtHeR.wOrLd!~" << "(/T\\E/T\\R/I\\S)" << "$m00n.p4tR0I$" << "*M.E.T.A.L.S.L.U.G*" << "OuTruN-hAn60uT"
                    << "[L*E*M*M*I*N*G*S]" << "@-G|a|U|n|L|e|T-@" << "%.BuBBLe.B00Ble.%" << "!.CaStLeVaNiA.!" << "=B@mBeR.J4cK=";
    }
    else if (Parameter == "audio.mode")
    {
        /*
        ## 2 values for the moment are really manage for pegasus
        audio.mode = musicandvideosound -> to activate sound for all using the Display value : "video and game"
        or
        audio.mode = none -> to deactivate sound

        ##RFU / activated only for menu / bug ignored to activate the sounds
        MusicsOnly,
        VideosSoundOnly,
        MusicsXorVideosSound,
        */

        //pegasus sound layer parameters is not as ES.
        ListOfValue << QObject::tr("All sounds on") + " \uf123" <<  QObject::tr("sounds off") +" \uf3a2"
                    << QObject::tr("Not supported: Videos Sound only") << QObject::tr("Not supported: Musics Only")
                    << QObject::tr("Not supported: Musics or Videos Sound");// using ionIcons Font
        //use internal values to match with ES modes
        ListOfInternalValue << "musicandvideosound" <<  "none"
                            << "videossoundonly" << "musicsonly"
                            << "musicsxorvideossound";
    }
    else if (Parameter == "audio.device")
    {
        /*
        example in conf:
        audio.device=alsa_card.pci-0000_00_1f.3:hdmi-output-0
        audio.volume=90
        audio.bgmusic=1
        audio.mode=musicandvideosound
        */

        IAudioController::DeviceList playbackList = AudioController::Instance().GetPlaybackList();

        for(const auto& playback : playbackList)
        {
            Log::debug(LOGMSG("Audio device DisplayableName : '%1'").arg(QString::fromStdString(playback.DisplayableName)));
            ListOfValue.append(QString::fromStdString(playback.DisplayableName)); // using Awesome Web Font

            Log::debug(LOGMSG("Audio device InternalName : '%1'").arg(QString::fromStdString(playback.InternalName)));
            ListOfInternalValue.append(QString::fromStdString(playback.InternalName));
        }
        if(ListOfValue.isEmpty())
        {
            ListOfValue.append(QObject::tr("no device detected"));
            ListOfInternalValue.append(""); //to empty parameter
        }
    }
    else if (Parameter.startsWith("dolphin", Qt::CaseInsensitive) == true)
    {
        if (Parameter.endsWith(".resolution", Qt::CaseInsensitive) == true)
        {
            /*
         * InternalResolution = 1, 2, 3, 4, 5, 6, 7, 8, 0 # AUTO
        */
            ListOfValue << QObject::tr("Auto Multiple of 640x528") << QObject::tr("Native 640x528") << QObject::tr("x2 Native 1280x1056 (720p)") << QObject::tr("x3 Native 1920x1584 (1080p)")
                        << QObject::tr("x4 Native 2560x2112 (1440p)") << QObject::tr("x5 Native 3200x2640") << QObject::tr("x6 Native 3840x3168 (4k)") << QObject::tr("x7 Native 4480x3696")
                        << QObject::tr("x8 Native 5120x4224 (5k)");

            ListOfInternalValue << "0" << "1" << "2" << "3"
                                << "4" << "5" << "6" << "7"
                                << "8" ;
        }
        else if (Parameter.endsWith(".antialiasing", Qt::CaseInsensitive) == true)
        {
            /*
         * MSAA = 0x00000001 # None, 0x00000002, 0x00000004, 0x00000008,
        */
            ListOfValue << QObject::tr("None") << QObject::tr("2x MSAA") << QObject::tr("4x MSAA") << QObject::tr("8x MSAA");

            ListOfInternalValue << "0x00000001" << "0x00000002" << "0x00000004" << "0x00000008" ;
        }
    }
    else if (Parameter == "duckstation.resolution")
    {
        /*
         * upscale_multiplier = 1, 2, 3, 4, 5, 6, 7, 8, 0
        */
        ListOfValue << QObject::tr("Native (ps1)") << QObject::tr("x2 Native (720p)") << QObject::tr("x3 Native (1080p)") << QObject::tr("x4 Native (1440p 2k)")
                    << QObject::tr("x5 Native (1620p)") << QObject::tr("x6 Native (4k)") << QObject::tr("x7 Native (2520p)") << QObject::tr("x8 Native (2880p)");

        ListOfInternalValue << "1" << "2" << "3" << "4"
                            << "5" << "6" << "7" << "8" ;
    }
    else if (Parameter == "pcsx2.resolution")
    {
        /*
         * upscale_multiplier = 1, 2, 3, 4, 5, 6, 7, 8, 0
        */
        ListOfValue << QObject::tr("Native (ps2)") << QObject::tr("x2 Native (720p)") << QObject::tr("x3 Native (1080p)") << QObject::tr("x4 Native (1440p 2k)")
                    << QObject::tr("x5 Native (1620p)") << QObject::tr("x6 Native (4k)") << QObject::tr("x7 Native (2520p)") << QObject::tr("x8 Native (2880p)");

        ListOfInternalValue << "1" << "2" << "3" << "4"
                            << "5" << "6" << "7" << "8" ;
    }
    else if (Parameter == "pcsx2.anisotropy")
    {
        /*
         * MaxAnisotropy = 0, 2, 4, 8, 16
        */
        ListOfValue << QObject::tr("Off") << QObject::tr("2x") << QObject::tr("4x") << QObject::tr("8x") << QObject::tr("16x");

        ListOfInternalValue << "0" << "2" << "4" << "8" << "16";
    }
    else if (Parameter == "pcsx2.tvshaders")
    {
        /*
         * TvShaders = 0, 1, 2, 3, 4, 5
        */
        ListOfValue << QObject::tr("None") << QObject::tr("Scanline filter") << QObject::tr("Diagonal filter")
                    << QObject::tr("Triangular filter") << QObject::tr("Wave filter") << QObject::tr("Lottes CRT filter");

        ListOfInternalValue << "0" << "1" << "2"
                            << "3" << "4" << "5";
    }
    else if (Parameter == "citra.resolution")
    {
        /*
         * resolution_factor = 1
        */
        ListOfValue << QObject::tr("Auto (Window Size)") << QObject::tr("Native 400x240") << QObject::tr("x2 Native 800x480") << QObject::tr("x3 Native 1200x720")
                    << QObject::tr("x4 Native 1600x960") << QObject::tr("x5 Native 2000x1200") << QObject::tr("x6 Native 2400x1440") << QObject::tr("x7 Native 2800x1680")
                    << QObject::tr("x8 Native 3200x1920") << QObject::tr("x9 Native 3600x2160") << QObject::tr("x10 Native 4000x2400");

        ListOfInternalValue << "0" << "1" << "2" << "3"
                            << "4" << "5" << "6" << "7"
                            << "8" << "9" << "10";
    }
    else if (Parameter == "citra.texture.filter")
    {
        /*
         * texture_filter = 1
        */
        ListOfValue << QObject::tr("None") << QObject::tr("Anime4k") << QObject::tr("Bicubic")
                    << QObject::tr("Nearest Neighbor") << QObject::tr("ScaleForce") << QObject::tr("xBRZ");

        ListOfInternalValue << "0" << "1" << "2"
                            << "3" << "4" << "5";
    }
    else if (Parameter.startsWith("cemu.", Qt::CaseInsensitive) == true)
    {
        if (Parameter.endsWith(".filter", Qt::CaseInsensitive) == true)
        {
            /*
            * <UpscaleFilter>1</UpscaleFilter>
            * <DownscaleFilter>0</DownscaleFilter>
            */
            ListOfValue << QObject::tr("Bilinear") << QObject::tr("Bicubic")
                        << QObject::tr("Hermite") << QObject::tr("Nearest Neighbor");

            ListOfInternalValue << "0" << "1"
                                << "2" << "3";
        }
        else if (Parameter.endsWith(".vsync", Qt::CaseInsensitive) == true)
        {

            /*
            * <VSync>0</VSync>
            */
            ListOfValue << QObject::tr("Off") << QObject::tr("Double buffering")<< QObject::tr("Triple buffering");

            ListOfInternalValue << "0" << "1" << "2";
        }
    }
    else if (Parameter == "supermodel.resolution")
    {
        /*
         * XResolution=640
         * YResolution=480
        */
        ListOfValue << QObject::tr("Auto (screen resolution)") << QObject::tr("Native") << QObject::tr("x2 Native (720p)")
                    << QObject::tr("x3 Native (1080p)") << QObject::tr("x4 Native (2k)") << QObject::tr("x5 Native (4k)");

        ListOfInternalValue << "auto" << "640,480" << "1280,720"
                            << "1920,1080" << "2560,1440" << "3840,2160";
    }
    else if (Parameter == "xemu.resolution")
    {
        /*
         * surface_scale = 1
        */
        ListOfValue << QObject::tr("Native") << QObject::tr("x2 Native") << QObject::tr("x3 Native") << QObject::tr("x4 Native")
                    << QObject::tr("x5 Native") << QObject::tr("x6 Native") << QObject::tr("x7 Native") << QObject::tr("x8 Native")
                    << QObject::tr("x9 Native") << QObject::tr("x10 Native");

        ListOfInternalValue << "1" << "2" << "3" << "4"
                            << "5" << "6" << "7" << "8"
                            << "9" << "10";
    }
    else if (Parameter == "ppsspp.resolution")
    {
        /*
         * InternalResolution = 1
        */
        ListOfValue << QObject::tr("Auto 1:1") << QObject::tr("Native") << QObject::tr("x2 Native") << QObject::tr("x3 Native")
                    << QObject::tr("x4 Native") << QObject::tr("x5 Native") << QObject::tr("x6 Native") << QObject::tr("x7 Native")
                    << QObject::tr("x8 Native") << QObject::tr("x9 Native") << QObject::tr("x10 Native");

        ListOfInternalValue << "0" << "1" << "2" << "3"
                            << "4" << "5" << "6" << "7"
                            << "8" << "9" << "10";
    }
    else if (Parameter == "ppsspp.msaa")
    {
        /*
         * multiSampleLevel = 0
        */
        ListOfValue << QObject::tr("Off") << QObject::tr("x2") << QObject::tr("x4") << QObject::tr("x8");

        ListOfInternalValue << "0" << "1" << "2" << "3";
    }
    else if (Parameter == "ppsspp.texture.scaling.level")
    {
        /*
         * texScalingLevel = 0
        */
        ListOfValue << QObject::tr("Off") << QObject::tr("x2") << QObject::tr("x3") << QObject::tr("x4") << QObject::tr("x5");

        ListOfInternalValue << "0" << "1" << "2" << "3" << "4";
    }
    else if (Parameter == "ppsspp.texture.scaling.type")
    {
        /*
         * texScalingType = 0
        */
        ListOfValue << QObject::tr("xBRZ") << QObject::tr("Hybrid") << QObject::tr("Bicubic") << QObject::tr("Hybrid + Bicubic");

        ListOfInternalValue << "0" << "1" << "2" << "3";
    }
    else if (Parameter == "ppsspp.anisotropy.level")
    {
        /*
         * AnisotropyLevel = 0
        */
        ListOfValue << QObject::tr("Off") << QObject::tr("x2") << QObject::tr("x4") << QObject::tr("x8") << QObject::tr("x16");

        ListOfInternalValue << "0" << "1" << "2" << "3" << "4";
    }
    else if (Parameter == "ppsspp.texture.filter")
    {
        /*
         * TextureFiltering = 0
        */
        ListOfValue << QObject::tr("Auto") << QObject::tr("Nearest") << QObject::tr("Linear") << QObject::tr("Auto Max Quality");

        ListOfInternalValue << "0" << "1" << "2" << "3";
    }
    else if (Parameter == "ppsspp.texture.shader")
    {
        /*
         * TextureFiltering = 0
        */
        ListOfValue << QObject::tr("Off") << QObject::tr("Tex2xBRZ") << QObject::tr("Tex4xBRZ") << QObject::tr("TexMMPX");

        ListOfInternalValue << "0" << "1" << "2" << "3";
    }
    else if (Parameter == "retroarch.color.theme.menu")
    {
        /*
         * ozone_menu_color_theme = 0
        */
        ListOfValue << QObject::tr("basic white") << QObject::tr("basic black") << QObject::tr("nord")
                    << QObject::tr("gruvbox dark") << QObject::tr("boysenberry") << QObject::tr("hacking the kernel")
                    << QObject::tr("twilight zone") << QObject::tr("dracula") << QObject::tr("solarized dark")
                    << QObject::tr("solarized light") << QObject::tr("gray dark") << QObject::tr("gray light")
                    << QObject::tr("purple rain");

        ListOfInternalValue << "0" << "1" << "2"
                            << "3" << "4" << "5"
                            << "6" << "7" << "8"
                            << "9" << "10" << "11"
                            << "12";
    }
    else if (Parameter == "boot.audio.device")
    {
        /*
        audio.volume=70
        */

        IAudioController::DeviceList playbackList = AudioController::Instance().GetPlaybackList();

        for(const auto& playback : playbackList)
        {
            Log::debug(LOGMSG("Audio device DisplayableName : '%1'").arg(QString::fromStdString(playback.DisplayableName)));
            ListOfValue.append(QString::fromStdString(playback.DisplayableName)); // using Awesome Web Font

            Log::debug(LOGMSG("Audio device InternalName : '%1'").arg(QString::fromStdString(playback.InternalName)));
            ListOfInternalValue.append(QString::fromStdString(playback.InternalName));
        }
        if(ListOfValue.isEmpty())
        {
            ListOfValue.append(QObject::tr("no device detected"));
            ListOfInternalValue.append(""); //to empty parameter
        }
    }
    else if (Parameter == "boot.sharedevice")
    {
        /*
        # The `sharedevice` variable indicates where to find the SHARE folder/partition.
        # It can have the following values:
        #   INTERNAL      => the partition immediately following the partition mounted as /boot, on the same disk (e.g. `/dev/mmcblk0p2`)
        #                    (this is the default)
        #   RAM           => a temporary in-memory file system (tmpfs)
        #                    (use at your own risks, specially on boards with low memory!)
        #   ANYEXTERNAL   => any storage device other than the one the system booted on
        #                    (use this when you have several USB keys/drives, but plug only one at a time)
        #   DEV [FSUUID]  => the storage device with the [FSUUID] unique identifier
        #                    (use this if you plug multiple storage devices together but want a specific one to hold SHARE)
        #   NETWORK       => a network-mounted filesystem
        #                    (see complementary `sharenetwork_*` directives below)
        ;sharedevice=INTERNAL
        */

        for(const StorageDevices::Device& device : mStorageDevices.GetStorageDevices())
        {
            Log::debug(LOGMSG("Storage Device Name: %1").arg(QString::fromStdString(device.DisplayName)));
            ListOfValue.append(QString::fromStdString(device.DisplayName));
            Log::debug(LOGMSG("Storage Device ID: %1").arg(QString::fromStdString(device.UUID)));
            ListOfInternalValue.append(QString::fromStdString(device.UUID));
        }
    }
    else if (Parameter.endsWith(".core", Qt::CaseInsensitive) == true) // compatible with all systems
    {
        QString system_short_name = Parameter.split('.').at(0);

        //model::Collection& collection = *sctx.get_or_create_collection(sysentry.name);

    }
    else if (Parameter.endsWith(".emulator", Qt::CaseInsensitive) == true) // compatible with all systems
    {
        QString system_short_name = Parameter.split('.').at(0);
    }
    //for bluetooth feature
    else if (Parameter == "controllers.bluetooth.scan.methods")
    {
        //QT QML Methods: 3 modes possible - MinimalServiceDiscovery (0) or FullServiceDiscovery (1)  or DeviceDiscovery (2)
        //1 legacy ES methods
        //new methods ?!
        ListOfValue << QObject::tr("Legacy (script)") << QObject::tr("Minimal Service Discovery (slow)") << QObject::tr("Full Service Discovery (slower)") << QObject::tr("Device Discovery (quicker)");
        ListOfInternalValue << "" << "0" << "1" << "2";
    }
    else if (Parameter == "controllers.bluetooth.pair.methods")
    {
        //legacy ES methods + command line
        ListOfValue << QObject::tr("Legacy (full script)") << QObject::tr("Simple one (partial script)");
        ListOfInternalValue << "" << "0";
    }
    else if (Parameter == "controllers.bluetooth.unpair.methods")
    {
        //legacy ES methods + command line
        ListOfValue << QObject::tr("Legacy (script)") << QObject::tr("Simple one (one commande line)");
        ListOfInternalValue << "" << "0";
    }
    else if (Parameter == "lightgun.sinden.bordercolor")
    {
        ListOfValue << QObject::tr("White") << QObject::tr("Red") << QObject::tr("Green") << QObject::tr("Blue");
        ListOfInternalValue << "white" << "red" << "green" << "blue";
    }
    else if (Parameter == "lightgun.sinden.bordersize")
    {
        ListOfValue << QObject::tr("Super Thin") << QObject::tr("Thin") << QObject::tr("Medium") << QObject::tr("Big");
        ListOfInternalValue << "superthin" << "thin" << "medium" << "big";
    }
    else if (Parameter == "lightgun.sinden.recoilmode")
    {
        ListOfValue << QObject::tr("None") << QObject::tr("Stronger") << QObject::tr("Softer") << QObject::tr("Strong Machine Gun") << QObject::tr("Soft Machine Gun");
        ListOfInternalValue << "none" << "stronger" << "softer" << "strongmachinegun" << "softmachinegun";
    }
    else
    {
        ListOfValue << QString("error: Parameters list for '%1' not found").arg(Parameter);
        //not a parameter using list !
        Log::warning(LOGMSG("'%1' parameter is not a parameters list").arg(Parameter));
    }
    //Log::debug(LOGMSG("The list of value for '%1' is '%2'.").arg(Parameter,ListOfValue.join(",")));
    //Log::debug(LOGMSG("The list of internal value for '%1' is '%2'.").arg(Parameter,ListOfInternalValue.join(",")));
    return ListOfValue;
}

QStringList GetParametersListFromSystem(QString Parameter, QString SysCommand, QStringList SysOptions)
{
    QStringList ListOfValue;

    //clean global internal values if needed
    ListOfInternalValue.clear();

    //replace from '%1' to '%i' parameters from SysCommand by SysOptions
    if (!SysOptions.empty())
    {
        for(int i = 0; i < SysOptions.count(); i++)
        {
            SysCommand.replace("%"+QString::number(i+1), SysOptions.at(i));
        }
    }

    //launch command using Qprocess to get output
    //Log::debug(LOGMSG("%2 SysCommand.toUtf8().constData(): '%1'").arg(SysCommand.toUtf8().constData(),Parameter));
    QString stdout = GetCommandOutput(SysCommand.toUtf8().constData());
    //Log::debug(LOGMSG("%2 GetCommandOutput(SysCommand.toUtf8().constData()): '%1'").arg(stdout,Parameter));

    //get list of value from stdout
    if (stdout.isEmpty())
    {
        ListOfValue.clear();
    }
    //search delimitor using semi-column
    else if (stdout.count(";") >= 1)
    {
        ListOfValue = stdout.split(";");
    }
    else // or search end of line
    {
        ListOfValue = stdout.split("\n");
    }
    //remove empty ones for cleaning
    ListOfValue.removeAll(QString(""));

    Log::debug(LOGMSG("The list of value for '%1' is '%2'.").arg(Parameter,ListOfValue.join(",")));

    //to avoid crash when there is no value return by command/script
    if(ListOfValue.isEmpty())
    {
        ListOfValue.append(QObject::tr("no value"));
        ListOfInternalValue.append(""); //to empty parameter
    }

    return ListOfValue;
}

std::vector<model::ParameterEntry> find_available_parameterslist(const QString& Parameter, const QString& SysCommand, const QStringList& SysOptions)
{
    //Log::debug(LOGMSG("Call of std::vector<model::ParameterEntry> find_available_parameterslist(const QString& Parameter)"));
    QStringList ListOfValue;

    if ((SysCommand != "") && (SysCommand != NULL))
    {
        ListOfValue = GetParametersListFromSystem(Parameter, SysCommand, SysOptions);
    }
    else
    {
        ListOfValue = GetParametersList(Parameter);
    }

    std::vector<model::ParameterEntry> parameterslist;

    //Log::debug(LOGMSG("ListOfValue.count():`%1`").arg(ListOfValue.count()));

    parameterslist.reserve(static_cast<size_t>(ListOfValue.count()));

    for (const QString& name : qAsConst(ListOfValue)) {
        //Log::debug(LOGMSG("name `%1`").arg(name));
        parameterslist.emplace_back(std::move(name));
        //Log::debug(LOGMSG("Found parameter `%1`").arg(parameterslist.back().name));
    }
    return parameterslist;
}

} // namespace

namespace model {

ParameterEntry::ParameterEntry(QString Name)
    : name(std::move(Name))
{}

ParametersList::ParametersList(QObject* parent)
    : QAbstractListModel(parent)
    , m_RecalboxBootConf(Path("/boot/recalbox-boot.conf"))
    , m_role_names({
                    { Roles::Name, QByteArrayLiteral("name") },
                    })
{
    //empty constructor to be generic
}


void ParametersList::select_preferred_parameter(const QString& Parameter)
{
    /*
    Log::debug(LOGMSG("void ParametersList::select_preferred_parameter(const QString& Parameter) Parameter:`%1`").arg(Parameter));
    to get first row as default value
    */
    QString DefaultValue;
    if (ListOfInternalValue.size() == 0) DefaultValue = m_parameterslist.at(0).name;
    else DefaultValue = ListOfInternalValue.at(0);

    //Log::debug(LOGMSG("DefaultValue:`%1`").arg(DefaultValue));

    if(Parameter.contains("boot.", Qt::CaseInsensitive))
    {
        //check in recalbox-boot.conf
        QString ParameterBoot = Parameter;
        ParameterBoot.replace(QString("boot."), QString(""));
        select_parameter(QString::fromStdString(m_RecalboxBootConf.AsString(ParameterBoot.toUtf8().constData(),DefaultValue.toUtf8().constData())));
    }
    else
    {
        //check in recalbox.conf
        //Log::debug(LOGMSG("select_parameter(QString::fromStdString(RecalboxConf::Instance().AsString(Parameter.toUtf8().constData(),DefaultValue.toUtf8().constData())));"));
        select_parameter(QString::fromStdString(RecalboxConf::Instance().AsString(Parameter.toUtf8().constData(),DefaultValue.toUtf8().constData())));
    }
}

bool ParametersList::select_parameter(const QString& name)
{
    //Log::debug(LOGMSG("ParametersList::select_parameter(const QString& name) name:`%1`").arg(name));

    for (size_t idx = 0; idx < m_parameterslist.size(); idx++) {
        /*
        Log::debug(LOGMSG("idx:`%1`").arg(idx));
        Log::debug(LOGMSG("at(idx).name:`%1`").arg(m_parameterslist.at(idx).name));
        */
        if (ListOfInternalValue.size() == 0)
        {
            if (m_parameterslist.at(idx).name == name) {
                m_current_idx = idx;
                //Log::debug(LOGMSG("m_current_idx:`%1`").arg(m_current_idx));
                return true;
            }
        }
        else // if internal value to check index from recalbox.conf/recalbox-boot.conf stored value
        {
            if (ListOfInternalValue.at(idx) == name) {
                m_current_idx = idx;
                //Log::debug(LOGMSG("m_current_idx:`%1`").arg(m_current_idx));
                return true;
            }
        }
    }
    //Log::debug(LOGMSG("ParametersList::select_parameter(const QString& name) / return false / index is set to 0"));
    //set index to 0 to have any value
    m_current_idx = 0;
    return false;
}

void ParametersList::save_selected_parameter()
{
    //Log::debug(LOGMSG("ParametersList::save_selected_parameter()"));
    const auto& value = m_parameterslist.at(m_current_idx);
    //Log::debug(LOGMSG("ParametersList::save_selected_parameter() - parameter value.name: `%1`").arg(value.name));
    //if (ListOfInternalValue.size() != 0) Log::debug(LOGMSG("ParametersList::save_selected_parameter() - parameter ListOfInternalValue.at(m_current_idx): `%1`").arg(ListOfInternalValue.at(m_current_idx)));

    //check in recalbox-boot.conf
    if(m_parameter.contains("boot.", Qt::CaseInsensitive))
    {
        QString ParameterBoot = m_parameter;
        ParameterBoot.replace(QString("boot."), QString(""));
        //write parameter in recalbox-boot.conf in all cases
        if (ListOfInternalValue.size() == 0) m_RecalboxBootConf.SetString(ParameterBoot.toUtf8().constData(), value.name.toUtf8().constData());
        //or internal value
        else m_RecalboxBootConf.SetString(ParameterBoot.toUtf8().constData(), ListOfInternalValue.at(m_current_idx).toUtf8().constData());
        //write recalbox-boot.conf immediately (but don't ask to reboot systematically ;-)
        m_RecalboxBootConf.Save();
    }
    else
    {
        //write parameter in recalbox.conf in all cases
        if (ListOfInternalValue.size() == 0) RecalboxConf::Instance().SetString(m_parameter.toUtf8().constData(), value.name.toUtf8().constData());
        //or internal value
        else RecalboxConf::Instance().SetString(m_parameter.toUtf8().constData(), ListOfInternalValue.at(m_current_idx).toUtf8().constData());
    }

    //Check m_parameter to manage specific case with specific management/action
    if(m_parameter == "audio.device")
    {
        //change audio device as selected
        std::string originalAudioDevice = RecalboxConf::Instance().GetAudioOuput();
        std::string fixedAudioDevice = AudioController::Instance().SetDefaultPlayback(originalAudioDevice);
    }
    else if(m_parameter == "audio.mode")
    {
        //change audio mode as selected
        if(ListOfInternalValue.at(m_current_idx) == "none")
        {
            AudioController::Instance().SetVolume(0);
        }
        else
        {
            AudioController::Instance().SetVolume(RecalboxConf::Instance().GetAudioVolume());
        }
    }
    else if (m_parameter == "system.kblayout")
    {
        /*Log::debug(LOGMSG("system.kblayout = %1").arg(value.name));
        ## set the keyboard layout (fr,en,de,us,es) */
        int exitcode = system(qPrintable(QStringLiteral("setxkbmap %1").arg(value.name)));
    }
}

int ParametersList::rowCount(const QModelIndex& parent) const
{
    if (parent.isValid())
        return 0;

    return static_cast<int>(m_parameterslist.size());
}

QVariant ParametersList::data(const QModelIndex& index, int role) const
{
    if (!index.isValid() || rowCount() <= index.row())
        return {};

    const auto& parameter = m_parameterslist.at(static_cast<size_t>(index.row()));
    switch (role) {
    case Roles::Name:
        return parameter.name;
    default:
        return {};
    }
}

void ParametersList::setCurrentIndex(int idx_int)
{
    //Log::warning(LOGMSG("ParametersList::setCurrentIndex(int idx_int) : m_current_idx = %1").arg(m_current_idx));
    const auto idx = static_cast<size_t>(idx_int);

    // verify
    if (idx == m_current_idx)
        return;

    if (m_parameterslist.size() <= idx) {
        Log::warning(LOGMSG("Invalid parameter index #%1").arg(idx));
        return;
    }
    // save
    m_current_idx = idx;
    save_selected_parameter();
    //Log::debug(LOGMSG("emit parameterChanged();"));
    emit parameterChanged();
}


QString ParametersList::currentName(const QString& Parameter, const QString& InternalName) {

    //Log::debug(LOGMSG("QString ParametersList::currentName(const QString& Parameter) - parameter: `%1`").arg(Parameter));

    if (m_parameter != Parameter)
    {
        //to signal refresh of model's data
        emit QAbstractItemModel::beginResetModel();
        m_parameter = Parameter;
        QStringList EmptyQStringList;
        m_parameterslist = find_available_parameterslist(Parameter,"",EmptyQStringList);
        select_preferred_parameter(Parameter);
        //to signal end of model's data
        emit QAbstractItemModel::endResetModel();
    }
    //if added to check if InternalName changed finally espcially for value change from recalbox.conf and using HTTP API
    if(InternalName != ""){
        //need to reset from InternalName as comming from recalox.conf
        for(int i = 0; i < ListOfInternalValue.count(); i++) {
            if(ListOfInternalValue.at(i) == InternalName){
                m_current_idx = i;
                break;
            }
        }
    }
    return m_parameterslist.at(m_current_idx).name;
}

QString ParametersList::currentInternalName(const QString& Parameter) {

    //Log::debug(LOGMSG("QString ParametersList::currentName(const QString& Parameter) - parameter: `%1`").arg(Parameter));

    if (m_parameter != Parameter)
    {
        //to signal refresh of model's data
        emit QAbstractItemModel::beginResetModel();
        m_parameter = Parameter;
        QStringList EmptyQStringList;
        m_parameterslist = find_available_parameterslist(Parameter,"",EmptyQStringList);
        select_preferred_parameter(Parameter);
        //to signal end of model's data
        emit QAbstractItemModel::endResetModel();
    }
    return ListOfInternalValue.at(m_current_idx);
}

QString ParametersList::currentNameFromSystem (const QString& Parameter, const QString& SysCommand, const QStringList& SysOptions) {

    //Log::debug(LOGMSG("QString ParametersList::currentNameFromSystem (const QString& Parameter, const QString& SysCommand, const QStringList& SysOptions) - parameter: `%1` - SysCommand: `%2` - SysOptions: TODO ").arg(Parameter,SysCommand));

    if (m_parameter != Parameter)
    {
        //to signal refresh of model's data
        emit QAbstractItemModel::beginResetModel();
        m_parameter = Parameter;
        m_parameterslist = find_available_parameterslist(Parameter, SysCommand, SysOptions);
        select_preferred_parameter(Parameter);
        //to signal end of model's data
        emit QAbstractItemModel::endResetModel();
    }
    return m_parameterslist.at(m_current_idx).name;
}



} // namespace model
