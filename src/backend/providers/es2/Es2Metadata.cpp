// Pegasus Frontend
// Copyright (C) 2017-2020  Mátyás Mustoha
//
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with this program. If not, see <http://www.gnu.org/licenses/>.
//
// Updated and integrated for recalbox by BozoTheGeek 03/05/2021
// Update by Sebio 19/04/2023
// Update by BozoTheGeek 30/07/2023 to fix media usages and media.xml generation method

#include "Es2Metadata.h"

#include "Log.h"
#include "Paths.h"
#include "model/gaming/Assets.h"
#include "model/gaming/Collection.h"
#include "model/gaming/Game.h"
#include "model/gaming/GameFile.h"
#include "providers/SearchContext.h"
#include "providers/es2/Es2Systems.h"
#include "utils/PathTools.h"

#include <QDir>
#include <QDirIterator>
#include <QFile>
#include <QFileInfo>
#include <QStringBuilder>
#include <QtXml>
#include <QTextStream>
#include <QXmlStreamReader>
#include <QDomDocument>

#include <algorithm>
#include <QElapsedTimer>

//For recalbox
#include "RecalboxConf.h"

namespace {

std::vector<QString> default_config_paths()
{
    QString shareInitPath = paths::homePath() % QStringLiteral("/.pegasus-frontend/");
    shareInitPath.replace("/share/","/share_init/");

    return {
        paths::homePath() % QStringLiteral("/.pegasus-frontend/"),
        shareInitPath,
        QStringLiteral("/etc/pegasus-frontend/"),
    };
}

QString lightgun_xml(const std::vector<QString>& possible_config_dirs)
{
    for (const QString& dir_path : possible_config_dirs) {
        QString xml_path = dir_path + QStringLiteral("lightgun.cfg");
        if (QFileInfo::exists(xml_path))
            return xml_path;
    }
    return {};
}

HashMap<QString, model::Game*> build_gamepath_db(const HashMap<QString, model::GameFile*>& filepath_to_entry_map)
{
    HashMap<QString, model::Game*> map;

    // TODO: C++17
    for (const auto& entry : filepath_to_entry_map) {
        const QFileInfo finfo(entry.first);
        QString path = ::clean_abs_dir(finfo) % '/' % finfo.completeBaseName();
        map.emplace(std::move(path), entry.second->parentGame());
    }

    return map;
}

QFileInfo shell_to_finfo(const QDir& base_dir, const QString& shell_filepath)
{
    if (shell_filepath.isEmpty())
        return {};

    const QString real_path = shell_filepath.startsWith(QLatin1String("~/"))
        ? paths::homePath() + shell_filepath.midRef(1)
        : shell_filepath;
    return QFileInfo(base_dir, real_path);
}

QString run(const QString& Command)
{
  const std::string& command = Command.toUtf8().constData();
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

} // namespace


namespace providers {
namespace es2 {

enum class MetaType : unsigned char {
    PATH,
    NAME,
    DESC,
    DEVELOPER,
    GENRE,
    PUBLISHER,
    PLAYERS,
    RATING,
    PLAYCOUNT,
    LASTPLAYED,
    RELEASE,
    IMAGE,
    THUMBNAIL,
    VIDEO,
    MARQUEE,
    FAVORITE,
    HASH,
    MD5,
    GENREID,
    HIDDEN,
};

const QHash<QString, QList<AssetType>> DIR_ASSETS {
    { QStringLiteral("bezel"), {AssetType::ARCADE_BEZEL}},
    { QStringLiteral("box2dback"), {AssetType::BOX_BACK}},
    { QStringLiteral("box2dfront"), {AssetType::BOX_FRONT, AssetType::BOX_2DFRONT}},
    { QStringLiteral("box2dside"), {AssetType::BOX_SPINE}},
    { QStringLiteral("box3d"), {AssetType::BOX_FRONT, AssetType::BOX_3DFRONT}},
    { QStringLiteral("boxtexture"), {AssetType::BOX_FULL}},
    { QStringLiteral("extra1"), {AssetType::EXTRA1}},
    { QStringLiteral("fanart"), {AssetType::BACKGROUND, AssetType::FANART}},
    { QStringLiteral("image"), {AssetType::IMAGES}},
    { QStringLiteral("images"), {AssetType::IMAGES}},
    { QStringLiteral("manual"), {AssetType::MANUAL}},
    { QStringLiteral("manuals"), {AssetType::MANUAL}},
    { QStringLiteral("map"), {AssetType::MAPS}},
    { QStringLiteral("maps"), {AssetType::MAPS}},
    { QStringLiteral("marquee"), {AssetType::ARCADE_MARQUEE, AssetType::MARQUEE}},
    { QStringLiteral("mix"), {AssetType::MIX}},
    { QStringLiteral("music"), {AssetType::MUSIC}},
    { QStringLiteral("screenmarquee"), {AssetType::ARCADE_MARQUEE, AssetType::SCREEN_MARQUEE}},
    { QStringLiteral("screenmarqueesmall"), {AssetType::ARCADE_MARQUEE, AssetType::SCREEN_MARQUEESMALL}},
    { QStringLiteral("screenshot"), {AssetType::SCREENSHOT, AssetType::BACKGROUND, AssetType::SCREENSHOT_BIS}},
    { QStringLiteral("screenshottitle"), {AssetType::TITLESCREEN, AssetType::SCREENSHOT}},
    { QStringLiteral("steamgrid"), {AssetType::UI_STEAMGRID, AssetType::ARCADE_MARQUEE}},
    { QStringLiteral("support"), {AssetType::BOX_FRONT, AssetType::CARTRIDGE}},
    { QStringLiteral("supporttexture"), {AssetType::CARTRIDGETEXTURE, AssetType::BOX_FRONT}},
    { QStringLiteral("thumbnail"), {AssetType::THUMBNAIL, AssetType::BOX_FRONT}},
    { QStringLiteral("video"), {AssetType::VIDEO}},
    { QStringLiteral("videos"), {AssetType::VIDEO}},
    { QStringLiteral("videomix"), {AssetType::VIDEOMIX}},
    { QStringLiteral("wheel"), {AssetType::LOGO, AssetType::WHEEL}},
    { QStringLiteral("wheelcarbon"), {AssetType::LOGO, AssetType::WHEEL_CARBON}},
    { QStringLiteral("wheelsteel"), {AssetType::LOGO, AssetType::WHEEL_STEEL}}
};

Metadata::Metadata(QString log_tag, std::vector<QString> possible_config_dirs)
    : m_log_tag(std::move(log_tag))
    , m_config_dirs(std::move(possible_config_dirs))
    , m_key_types {
        { QStringLiteral("path"), MetaType::PATH },
        { QStringLiteral("name"), MetaType::NAME },
        { QStringLiteral("desc"), MetaType::DESC },
        { QStringLiteral("developer"), MetaType::DEVELOPER },
        { QStringLiteral("genre"), MetaType::GENRE },
        { QStringLiteral("publisher"), MetaType::PUBLISHER },
        { QStringLiteral("players"), MetaType::PLAYERS },
        { QStringLiteral("rating"), MetaType::RATING },
        { QStringLiteral("playcount"), MetaType::PLAYCOUNT },
        { QStringLiteral("lastplayed"), MetaType::LASTPLAYED },
        { QStringLiteral("releasedate"), MetaType::RELEASE },
        { QStringLiteral("image"), MetaType::IMAGE },
        { QStringLiteral("thumbnail"), MetaType::THUMBNAIL },
        { QStringLiteral("video"), MetaType::VIDEO },
        { QStringLiteral("marquee"), MetaType::MARQUEE },
        { QStringLiteral("favorite"), MetaType::FAVORITE },
        { QStringLiteral("hash"), MetaType::HASH },
        { QStringLiteral("md5"), MetaType::MD5 },
		{ QStringLiteral("path"), MetaType::PATH },
		{ QStringLiteral("genreid"), MetaType::GENREID },
        { QStringLiteral("hidden"), MetaType::HIDDEN },
    }
    , m_date_format(QStringLiteral("yyyyMMdd'T'HHmmss"))
    , m_players_regex(QStringLiteral("(\\d+)(-(\\d+))?"))
    , m_asset_type_map {  // TODO: C++14 with constexpr pair ctor
        { MetaType::IMAGE, AssetType::BOX_FRONT },
        { MetaType::THUMBNAIL, AssetType::SCREENSHOT },
        { MetaType::MARQUEE, AssetType::ARCADE_MARQUEE },
        { MetaType::MARQUEE, AssetType::MARQUEE },
        { MetaType::VIDEO, AssetType::VIDEO },
    }
{}

HashMap<MetaType, QString, EnumHash> Metadata::parse_gamelist_game_node(QXmlStreamReader& xml) const
{
    Q_ASSERT(xml.isStartElement() && xml.name() == "game");

    HashMap<MetaType, QString, EnumHash> xml_props;
    while (xml.readNextStartElement()) {
        const auto it = std::find_if(
            m_key_types.cbegin(),
            m_key_types.cend(),
            [&xml](const decltype(m_key_types)::value_type& entry){ return entry.first == xml.name(); });
        if (it != m_key_types.cend()) {
            xml_props[it->second] = xml.readElementText();
            continue;
        }

        xml.skipCurrentElement();
    }
    return xml_props;
}

QString Metadata::find_gamelist_xml(const std::vector<QString>& possible_config_dirs, const QDir& system_dir, const SystemEntry& sysentry) const
{
    const QString GAMELISTFILE = QStringLiteral("/gamelist.xml");

    std::vector<QString> possible_files { system_dir.path() % GAMELISTFILE };

    if (!sysentry.name.isEmpty()) {
        for (const QString& dir_path : possible_config_dirs) {
            possible_files.emplace_back(dir_path
                % QStringLiteral("/gamelists/")
                % sysentry.name
                % GAMELISTFILE);
        }
    }

    for (const auto& path : possible_files) {
        if (QFileInfo::exists(path))
            return path;
    }

    return {};
}

QString Metadata::find_media_xml(const std::vector<QString>& possible_config_dirs, const QDir& system_dir, const SystemEntry& sysentry) const
{
    const QString MEDIAFILE = QStringLiteral("/media.xml");

    std::vector<QString> possible_files { system_dir.path() % MEDIAFILE };

    if (!sysentry.name.isEmpty()) {
        for (const QString& dir_path : possible_config_dirs) {
            possible_files.emplace_back(dir_path
                % QStringLiteral("/media/")
                % sysentry.name
                % MEDIAFILE);
        }
    }

    for (const auto& path : possible_files) {
        if (QFileInfo::exists(path))
            return path;
    }

    return {};
}

void Metadata::process_gamelist_xml(const QDir& xml_dir, QXmlStreamReader& xml, providers::SearchContext& sctx, const SystemEntry& sysentry) const
{
    QString log_tag = sysentry.shortname + " " + m_log_tag;
    // find the root <gameList> element
    if (!xml.readNextStartElement()) {
        xml.raiseError(LOGMSG("could not parse `%1`")
                       .arg(static_cast<QFile*>(xml.device())->fileName()));
        return;
    }
    if (xml.name() != QLatin1String("gameList")) {
        xml.raiseError(LOGMSG("`%1` does not have a `<gameList>` root node!")
                       .arg(static_cast<QFile*>(xml.device())->fileName()));
        return;
    }

    //need collection for gamelist only activated
    model::Collection& collection = *sctx.get_or_create_collection(sysentry.name);
	
    size_t found_games = 0;
    // read all <game> nodes
    while (xml.readNextStartElement()) {
        if (xml.name() != QLatin1String("game")) {
            xml.skipCurrentElement();
            continue;
        }

        const size_t linenum = xml.lineNumber();

        // process node
        HashMap<MetaType, QString, EnumHash> xml_props = parse_gamelist_game_node(xml);
        if (xml_props.empty() || (xml_props[MetaType::HIDDEN] == "true") )
            continue;

        const QString shell_filepath = xml_props[MetaType::PATH];
        if (shell_filepath.isEmpty()) {
            Log::warning(log_tag, LOGMSG("The `<game>` node in `%1` at line %2 has no valid `<path>` entry")
                .arg(static_cast<QFile*>(xml.device())->fileName(), QString::number(linenum)));
            continue;
        }

        const QFileInfo finfo = shell_to_finfo(xml_dir, shell_filepath);
        const QString path = ::clean_abs_path(finfo);
        
        if(RecalboxConf::Instance().AsBool("pegasus.gamelistonly") || RecalboxConf::Instance().AsBool("pegasus.gamelistfirst"))
        {
            // create game now in this case (don't care if exist or not on file system to go quicker)
            model::Game* game_ptr = sctx.game_by_filepath(path);
            if (!game_ptr) {
                game_ptr = sctx.create_game_for(collection);
                sctx.game_add_filepath(*game_ptr, std::move(path));
            }    
            sctx.game_add_to(*game_ptr, collection);
			found_games++;
        }
        else
        {    
            // get the Game, if exists, and apply the properties
            if (!finfo.exists())
                continue;
        }
        model::GameFile* const entry_ptr = sctx.gamefile_by_filepath(path);
        if (!entry_ptr)  // ie. the file was not picked up by the system's extension list
            continue;
        apply_metadata(*entry_ptr, xml_dir, xml_props, sysentry);
    }

    if(RecalboxConf::Instance().AsBool("pegasus.gamelistonly") || RecalboxConf::Instance().AsBool("pegasus.gamelistfirst"))
    {
        Log::info(log_tag, LOGMSG("System `%1` gamelist provided %2 games")
        .arg(sysentry.name, QString::number(found_games)));
    }
    
    if (xml.error()) {
        Log::warning(log_tag, xml.errorString());
        return;
    }
}

void Metadata::prepare_lightgun_games_metadata()
{
    QString log_tag = "lightgun.cfg " + m_log_tag;
    //part after is dedicated to set flag for lightgun games from our "lightgun.cfg" xml file
    if(RecalboxConf::Instance().AsBool("pegasus.flaglightgungames", true))
    {
        const QString xml_path = lightgun_xml(default_config_paths());
        if (xml_path.isEmpty()) {
            Log::warning(log_tag, LOGMSG("No lightgun.cfg found"));
        }
        else {
            //Log::debug(LOGMSG("File Found : `%1`").arg(xml_path));
            //get lightgun games from xml and for a system
            size_t lightgunGamesFound = import_lightgun_games_from_xml(xml_path);
            Log::info(log_tag, LOGMSG("%1 lightgun games known as compatible with pixL").arg(lightgunGamesFound));
        }
    }
}

bool Metadata::isLightgunGames(model::Game* game, const model::GameFile* gamefile, const SystemEntry& systementry) const
{
    QString log_tag = "lightgun.cfg ";
    QString simplified_game_name = game->title();
    //Log::debug(log_tag, LOGMSG("game name to simplified : %1").arg(simplified_game_name));

    //lowercase
    simplified_game_name = simplified_game_name.toLower();
    //keep only alphanumeric characters
    const QRegularExpression replace_regex(QStringLiteral("[^a-z0-9!]"));
    simplified_game_name.remove(replace_regex);
    //Log::debug(log_tag, LOGMSG("simplified game name : %1").arg(simplified_game_name));

    //parse m_lightgun_games to know if this game is a lightgun game one or not
    lightgunGameData lightgunGameToFind = {simplified_game_name, gamefile->fileinfo().baseName(), systementry.shortname};
    QList<lightgunGameData>::const_iterator it = std::find_if(m_lightgun_games.begin(),m_lightgun_games.end(),
                                                              [&](const lightgunGameData& input){
                                                                    //Log::debug(log_tag, LOGMSG("lightgunGameToFind.system : %1").arg(lightgunGameToFind.system));
                                                                    //Log::debug(log_tag, LOGMSG("input.system : %1").arg(input.system));
                                                                    if(input.roms == ""){
                                                                        return lightgunGameToFind.name.contains(input.name) && input.system.contains("'" + lightgunGameToFind.system + "'");
                                                                    }
                                                                    else{
                                                                        return input.roms.contains(lightgunGameToFind.roms) && input.system.contains("'" + lightgunGameToFind.system + "'");
                                                                    }
                                                              }
    );

    if ((it != m_lightgun_games.end())) {
        //Log::debug(log_tag, LOGMSG("%1 is lightgun game for %2").arg(game->title(), systementry.name));
        return true;
    }
    else {
        return false;
    }
}

void Metadata::find_metadata_for_system(const SystemEntry& sysentry, const QDir& system_dir, providers::SearchContext& sctx) const
{
    Q_ASSERT(!sysentry.name.isEmpty());
    Q_ASSERT(!sysentry.path.isEmpty());

    QString log_tag = sysentry.shortname + " " + m_log_tag;
    if (sysentry.shortname == QLatin1String("steam")) {
        Log::info(log_tag, LOGMSG("Ignoring the `steam` system in favor of the built-in Steam support"));
        return;
    }

    QElapsedTimer gamelist_timer;
    gamelist_timer.start();
    
    //Log::debug(log_tag, LOGMSG("sysentry.path:  %1").arg(sysentry.path));
      
    const QString gamelist_path = find_gamelist_xml(m_config_dirs, system_dir, sysentry);
    if (gamelist_path.isEmpty()) {
        Log::warning(log_tag, LOGMSG("No gamelist file found for system `%1`").arg(sysentry.shortname));
        return;
    }
    Log::info(log_tag, LOGMSG("Found `%1`").arg(gamelist_path));

    QFile xml_file(gamelist_path);
    if (!xml_file.open(QIODevice::ReadOnly)) {
        Log::error(log_tag, LOGMSG("Could not open `%1`").arg(gamelist_path));
        return;
    }

    QXmlStreamReader xml(&xml_file);
    process_gamelist_xml(system_dir, xml, sctx, sysentry);
    Log::info(log_tag, LOGMSG("Timing: Gamelist processing took %1ms").arg(gamelist_timer.elapsed()));

    //part after is dedicated to add additional media from skraper and not referenced in "gamelist.xml" files
    if(!RecalboxConf::Instance().AsBool("pegasus.deactivateskrapermedia", false))
    {
        //to add images stored by skraper and linked to gamelist/system of ES
        QElapsedTimer skraper_media_timer;
        skraper_media_timer.start();
        //Log::info(LOGMSG("media.xml path: %1").arg(xml_dir.path() + "/media.xml"));
        //use media.xml or not
        if(RecalboxConf::Instance().AsBool("pegasus.usemedialist", true)){
            //Log::info(LOGMSG("media.xml to use: %1").arg(xml_dir.path() + "/media.xml"));
            //add media from xml (to see if it's quicker or not ?!)
            size_t mediaFound = import_media_from_xml(system_dir, sctx, sysentry);
            if (mediaFound == 0){
                Log::info(log_tag,  LOGMSG("media.xml not found, empty or to regenerate due to change(s): %1").arg(system_dir.path() + "/media.xml"));
                //set last parameter to activate or not the media.xml generation during parsing of media
                //add_skraper_media_metadata(system_dir, sctx, sysentry, true);
                add_skraper_media_metadata_v2(system_dir, sctx, sysentry, true);
                Log::info(log_tag, LOGMSG("Timing: Skraper media searching (with media.xml generation) took %1ms").arg(skraper_media_timer.elapsed()));
            }
            else Log::info(log_tag, LOGMSG("Timing: Skraper media.xml import took %1ms").arg(skraper_media_timer.elapsed()));
        }
        else{
            //set last parameter to activate deactivate the media.xml generation during parsing of media
            //add_skraper_media_metadata(system_dir, sctx, sysentry, false);
            add_skraper_media_metadata_v2(system_dir, sctx, sysentry, false);
            Log::info(log_tag, LOGMSG("Timing: Skraper media searching took %1ms").arg(skraper_media_timer.elapsed()));
        }
        //*****************************************************     
    }

}

void Metadata::add_skraper_media_metadata(const QDir& xml_dir, providers::SearchContext& sctx, const SystemEntry& sysentry, bool generateMediaXML) const
{
    QString log_tag = sysentry.shortname + " " + m_log_tag;
    //Log::info(log_tag, LOGMSG("Start to add Skraper Assets in addition of ES Gamelist"));
    // NOTE: The entries are ordered by priority
    const HashMap<AssetType, QStringList, EnumHash> ASSET_DIRS {
        // multi posibility
        { AssetType::ARCADE_MARQUEE, {
            QStringLiteral("marquee"),
            QStringLiteral("screenmarquee"),
            QStringLiteral("screenmarqueesmall"),
            QStringLiteral("steamgrid"),
        }},
        { AssetType::BACKGROUND, {
            QStringLiteral("fanart"),
            QStringLiteral("screenshot"),
            // we can't use "image or images" because we can't anticipate what has been scrapped by user finally
            //QStringLiteral("image"),
            //QStringLiteral("images"),
        }},
        { AssetType::BOX_FRONT, {
            QStringLiteral("box3d"),
            QStringLiteral("support"),
            QStringLiteral("boxfront"),
            QStringLiteral("boxFront"),
            QStringLiteral("box2dfront"),
            QStringLiteral("supporttexture"),
            QStringLiteral("thumbnail"),
        }},
        { AssetType::LOGO, {
            QStringLiteral("wheel"),
            QStringLiteral("wheelcarbon"),
            QStringLiteral("wheelsteel"),
        }},
        { AssetType::SCREENSHOT, {
            QStringLiteral("screenshot"),
            QStringLiteral("screenshottitle"),
            // we can't use "image or images" because we can't anticipate what has been scrapped by user finally
            //QStringLiteral("image"),
            //QStringLiteral("images"),
        }},

        // solo posibility
        // for tag <bezels></bezels>
        { AssetType::ARCADE_BEZEL, {
            QStringLiteral("bezel"), // specific with arrm
            QStringLiteral("bezels"), // specific with arrm
        }},
        // for tag <box2dback></box2dback>
        { AssetType::BOX_BACK, {
            QStringLiteral("boxback"),
            QStringLiteral("boxBack"),
            QStringLiteral("box2dback"),
        }},
        // for tag <box2dfront></box2dfront>
        { AssetType::BOX_2DFRONT, {    
            QStringLiteral("boxfront"),
            QStringLiteral("boxFront"),
            QStringLiteral("box2dfront"),
        }},
        // for tag <box2dside></box2dside>
        { AssetType::BOX_SPINE, {
            QStringLiteral("boxside"),
            QStringLiteral("boxSide"),
            QStringLiteral("box2dside"),
        }},
        // for tag <box3d></box3d>
        { AssetType::BOX_3DFRONT, {
            QStringLiteral("box3d"),
        }},
        // for tag <boxtexture></boxtexture>
        { AssetType::BOX_FULL, {
            QStringLiteral("boxfull"),
            QStringLiteral("boxFull"),
            QStringLiteral("boxtexture"),
        }},
        // for tag <extra1></extra1>
        { AssetType::EXTRA1, {
            QStringLiteral("extra1"), // flyer specific with arrm
        }},
        // for tag <fanart></fanart>
        { AssetType::FANART, {
            QStringLiteral("fanart"),
        }},
        // for tag <images></images>
        { AssetType::IMAGES, {
            QStringLiteral("image"),
            QStringLiteral("images"),
        }},
        // for tag <manuals></manuals>
        { AssetType::MANUAL, {
            QStringLiteral("manual"),
            QStringLiteral("manuals"),
        }},
        // for tag <map></map>
        { AssetType::MAPS, {
            QStringLiteral("map"),
            QStringLiteral("maps"),            
        }},
        // for tag <marquee></marquee>
        { AssetType::MARQUEE, {
            QStringLiteral("marquee"),
        }},
        // for tag <mix></mix>
        { AssetType::MIX, {
            QStringLiteral("mix"), // specific with arrm
        }},
        // for tag <music></music>
        { AssetType::MUSIC, {
            QStringLiteral("music"), // specific with arrm
        }},
        // for tag <screenmarquee></screenmarquee>
        { AssetType::SCREEN_MARQUEE, {  
            QStringLiteral("screenmarquee"),
        }},
        // for tag <screenmarqueesmall></screenmarqueesmall>
        { AssetType::SCREEN_MARQUEESMALL, {      
            QStringLiteral("screenmarqueesmall"),
        }},
        // for tag <screenshot></screenshot>
        { AssetType::SCREENSHOT_BIS, {
            QStringLiteral("screenshot"),
        }},
        // for tag <screenshottitle></screenshottitle>
        { AssetType::TITLESCREEN, {
            QStringLiteral("screenshottitle"),
        }},
        // for tag <steamgrid></steamgrid>
        { AssetType::UI_STEAMGRID, {
            QStringLiteral("steamgrid"),
        }},
        // for tag <support></support>
        { AssetType::CARTRIDGE, {
            QStringLiteral("support"),
        }},
        // for tag <supporttexture></supporttexture>
        { AssetType::CARTRIDGETEXTURE, {
            QStringLiteral("supporttexture"),
        }},
        // for tag <thumbnail></thumbnail>
        { AssetType::THUMBNAIL, {
            QStringLiteral("thumbnail"),
        }},
        // for tag <videos></videos>
        { AssetType::VIDEO, {
            QStringLiteral("video"),
            QStringLiteral("videos"),
        }},
        // for tag <videomix></videomix>
        { AssetType::VIDEOMIX, {
            QStringLiteral("videomix"), // specific with arrm
        }},
        // for tag <wheel></wheel>
        { AssetType::WHEEL, {
            QStringLiteral("wheel"),
        }},
        // for tag <wheelcarbon></wheelcarbon>
        { AssetType::WHEEL_CARBON, {
            QStringLiteral("wheelcarbon"),
        }},
        // for tag <wheelsteel></wheelsteel>
        { AssetType::WHEEL_STEEL, {         
            QStringLiteral("wheelsteel"),
        }},
    };

    const std::array<QString, 1> MEDIA_DIRS {
        QStringLiteral("/media/"),
    };

    constexpr auto DIR_FILTERS = QDir::Files | QDir::Readable | QDir::NoDotAndDotDot;
    constexpr auto DIR_FLAGS = QDirIterator::Subdirectories | QDirIterator::FollowSymlinks;
    
    //Log::debug(log_tag, LOGMSG("Nb elements in extless_path_to_game : %1").arg(QString::number(extless_path_to_game.size())));
    
    //Log::debug(log_tag, LOGMSG("Nb elements in sctx.current_filepath_to_entry_map() : %1").arg(QString::number(sctx.current_filepath_to_entry_map().size())));
    //Log::debug(log_tag, LOGMSG("Nb elements in sctx.current_collection_to_entry_map() : %1").arg(QString::number(sctx.current_collection_to_entry_map().size())));

    size_t found_assets_cnt = 0;
    bool gamepath_db_generated = false;
    HashMap<QString, model::Game*> extless_path_to_game;

    //***FOR TEST PURPOSE ONLY - DELETE FOR EACH RUNNING***
    //if (QFileInfo::exists(system_dir.path() + "/media.xml")){
    //    QFile::remove(system_dir.path() + "/media.xml");
    //}
    //*****************************************************

    QDomDocument document;
    QDomElement root;
    QFile xmlFile;
    QTextStream xmlContent(&xmlFile);
    if(generateMediaXML){
        //Open media.xml file to write it (we consider that media.xml doesn't exist if we call this function
        xmlFile.setFileName(xml_dir.path() + "/media.xml");
        if (!xmlFile.open(QFile::WriteOnly | QFile::Text ))
        {
            Log::error(log_tag, LOGMSG("%1 already opened or there is another issue").arg(xml_dir.path() + "/media.xml"));
            xmlFile.close();
            //exit function due to issue finally
            return;
        }
        //Calculate media directory & gamelist size in bytes
        //Too slow to calcculate size of directories finaly
        //QString media_dir_size = run("du -s " + xml_dir.path() + "/media/" +
        //                         " | head -n 1 | awk '{print $1}' | tr -d '\\n' | tr -d '\\r'"); //To keep only one line without CR or LF or hidden char
        QString gamelist_size = run("ls -l " + xml_dir.path() + "/gamelist.xml"+
                                 " | head -n 1 | awk '{print $5}' | tr -d '\\n' | tr -d '\\r'"); //To keep only one line without CR or LF or hidden char
        QString gamelist_date = run("date '+%F-%H-%M-%S' -r " + xml_dir.path() + "/gamelist.xml"+
                                 " | head -n 1 | tr -d '\\n' | tr -d '\\r'"); //To keep only one line without CR or LF or hidden char

        //make the root element
        root = document.createElement("mediaList");
        //root.setAttribute("media_dir_size", media_dir_size);
        root.setAttribute("gamelist_size", gamelist_size);
        root.setAttribute("gamelist_date", gamelist_date);
        //add it to document
        document.appendChild(root);
    }

    //Log::debug(log_tag, LOGMSG("Nb elements in MEDIA_DIRS : %1").arg(QString::number(MEDIA_DIRS.size())));
    for (const QString& media_dir_subpath : MEDIA_DIRS) {
        const QString game_media_dir = xml_dir.path() % media_dir_subpath;
        if (!QFileInfo::exists(game_media_dir)) 
            {
                //Log::debug(log_tag, LOGMSG("%1 directory not found :-(").arg(game_media_dir));
                continue;
            }
        else if (!gamepath_db_generated) //first iteration only
            {
            //we build this db only one time and for one system now, to be able to search quickly
            extless_path_to_game = build_gamepath_db(sctx.current_filepath_to_entry_map());
            gamepath_db_generated = true;
            }            
        //check existing asset directories in media
        //Log::debug(log_tag, LOGMSG("Nb elements in ASSET_DIRS : %1").arg(QString::number(ASSET_DIRS.size())));
        for (const auto& asset_dir_entry : ASSET_DIRS) {
            const AssetType asset_type = asset_dir_entry.first;
            const QStringList& dir_names = asset_dir_entry.second;
            for (const QString& dir_name : dir_names) {
                const QString search_dir = game_media_dir % dir_name;
                //Log::debug(log_tag, LOGMSG("%1 is the directory to search !").arg(search_dir));
                const int subpath_len = media_dir_subpath.length() + dir_name.length();
                QDirIterator dir_it(search_dir, DIR_FILTERS, DIR_FLAGS);
                while (dir_it.hasNext()) {
                    dir_it.next();
                    const QFileInfo finfo = dir_it.fileInfo();
                    const QString game_path = ::clean_abs_dir(finfo).remove(xml_dir.path().length(), subpath_len)
                                            % '/' % finfo.completeBaseName();
                    //Log::debug(log_tag, LOGMSG("%1 is the game path !").arg(game_path));
                    const auto it = extless_path_to_game.find(game_path);
                    if (it == extless_path_to_game.cend())
                        continue;
                    //check if this game node already exist
                    model::Game& game = *(it->second);
                    game.assetsMut().add_file(asset_type, dir_it.filePath());
                    if(generateMediaXML){
                        //write asset by asset in media.xml
                        QDomElement gamenode = document.createElement(dir_name);
                        //add game as attribut
                        gamenode.setAttribute("game", game_path);//game.path());
                        //add path of the asset as value
                        QDomText text = document.createTextNode(dir_it.filePath());
                        gamenode.appendChild(text);
                        //appen new asset to root
                        root.appendChild(gamenode);
                    }
                    //Log::debug(log_tag, LOGMSG("%1 asset added !").arg(dir_it.filePath()));
                    found_assets_cnt++;
                }
            }
        }
    }
    if(generateMediaXML){
        //write xml Content
        xmlContent << document.toString();
        //close xml
        xmlFile.close();
    }
    Log::info(log_tag, LOGMSG("%1 assets found from media directory").arg(QString::number(found_assets_cnt)));
}

void Metadata::add_skraper_media_metadata_v2(const QDir& xml_dir, providers::SearchContext& sctx, const SystemEntry& sysentry, bool generateMediaXML) const
{
    QString log_tag = sysentry.shortname + " " + m_log_tag;
    //Log::info(log_tag, LOGMSG("Start to add Skraper Assets in addition of ES Gamelist"));
    // NOTE: The entries are ordered by priority
    const HashMap<AssetType, QStringList, EnumHash> ASSET_DIRS {
        // multi posibility
        { AssetType::ARCADE_MARQUEE, {
                                        QStringLiteral("marquee"),
                                        QStringLiteral("screenmarquee"),
                                        QStringLiteral("screenmarqueesmall"),
                                        QStringLiteral("steamgrid"),
                                    }},
        { AssetType::BACKGROUND, {
                                    QStringLiteral("fanart"),
                                    QStringLiteral("screenshot"),
                                    // we can't use "image or images" because we can't anticipate what has been scrapped by user finally
                                    //QStringLiteral("image"),
                                    //QStringLiteral("images"),
                                }},
        { AssetType::BOX_FRONT, {
                                   QStringLiteral("box3d"),
                                   QStringLiteral("support"),
                                   QStringLiteral("boxfront"),
                                   QStringLiteral("boxFront"),
                                   QStringLiteral("box2dfront"),
                                   QStringLiteral("supporttexture"),
                                   QStringLiteral("thumbnail"),
                               }},
        { AssetType::LOGO, {
                              QStringLiteral("wheel"),
                              QStringLiteral("wheelcarbon"),
                              QStringLiteral("wheelsteel"),
                          }},
        { AssetType::SCREENSHOT, {
                                    QStringLiteral("screenshot"),
                                    QStringLiteral("screenshottitle"),
                                    // we can't use "image or images" because we can't anticipate what has been scrapped by user finally
                                    //QStringLiteral("image"),
                                    //QStringLiteral("images"),
                                }},

        // solo posibility
        // for tag <bezels></bezels>
        { AssetType::ARCADE_BEZEL, {
                                      QStringLiteral("bezel"), // specific with arrm
                                      QStringLiteral("bezels"), // specific with arrm
                                  }},
        // for tag <box2dback></box2dback>
        { AssetType::BOX_BACK, {
                                  QStringLiteral("boxback"),
                                  QStringLiteral("boxBack"),
                                  QStringLiteral("box2dback"),
                              }},
        // for tag <box2dfront></box2dfront>
        { AssetType::BOX_2DFRONT, {
                                     QStringLiteral("boxfront"),
                                     QStringLiteral("boxFront"),
                                     QStringLiteral("box2dfront"),
                                 }},
        // for tag <box2dside></box2dside>
        { AssetType::BOX_SPINE, {
                                   QStringLiteral("boxside"),
                                   QStringLiteral("boxSide"),
                                   QStringLiteral("box2dside"),
                               }},
        // for tag <box3d></box3d>
        { AssetType::BOX_3DFRONT, {
                                     QStringLiteral("box3d"),
                                 }},
        // for tag <boxtexture></boxtexture>
        { AssetType::BOX_FULL, {
                                  QStringLiteral("boxfull"),
                                  QStringLiteral("boxFull"),
                                  QStringLiteral("boxtexture"),
                              }},
        // for tag <extra1></extra1>
        { AssetType::EXTRA1, {
                                QStringLiteral("extra1"), // flyer specific with arrm
                            }},
        // for tag <fanart></fanart>
        { AssetType::FANART, {
                                QStringLiteral("fanart"),
                            }},
        // for tag <images></images>
        { AssetType::IMAGES, {
                                QStringLiteral("image"),
                                QStringLiteral("images"),
                            }},
        // for tag <manuals></manuals>
        { AssetType::MANUAL, {
                                QStringLiteral("manual"),
                                QStringLiteral("manuals"),
                            }},
        // for tag <map></map>
        { AssetType::MAPS, {
                              QStringLiteral("map"),
                              QStringLiteral("maps"),
                          }},
        // for tag <marquee></marquee>
        { AssetType::MARQUEE, {
                                 QStringLiteral("marquee"),
                             }},
        // for tag <mix></mix>
        { AssetType::MIX, {
                             QStringLiteral("mix"), // specific with arrm
                         }},
        // for tag <music></music>
        { AssetType::MUSIC, {
                               QStringLiteral("music"), // specific with arrm
                           }},
        // for tag <screenmarquee></screenmarquee>
        { AssetType::SCREEN_MARQUEE, {
                                        QStringLiteral("screenmarquee"),
                                    }},
        // for tag <screenmarqueesmall></screenmarqueesmall>
        { AssetType::SCREEN_MARQUEESMALL, {
                                             QStringLiteral("screenmarqueesmall"),
                                         }},
        // for tag <screenshot></screenshot>
        { AssetType::SCREENSHOT_BIS, {
                                        QStringLiteral("screenshot"),
                                    }},
        // for tag <screenshottitle></screenshottitle>
        { AssetType::TITLESCREEN, {
                                     QStringLiteral("screenshottitle"),
                                 }},
        // for tag <steamgrid></steamgrid>
        { AssetType::UI_STEAMGRID, {
                                      QStringLiteral("steamgrid"),
                                  }},
        // for tag <support></support>
        { AssetType::CARTRIDGE, {
                                   QStringLiteral("support"),
                               }},
        // for tag <supporttexture></supporttexture>
        { AssetType::CARTRIDGETEXTURE, {
                                          QStringLiteral("supporttexture"),
                                      }},
        // for tag <thumbnail></thumbnail>
        { AssetType::THUMBNAIL, {
                                   QStringLiteral("thumbnail"),
                               }},
        // for tag <videos></videos>
        { AssetType::VIDEO, {
                               QStringLiteral("video"),
                               QStringLiteral("videos"),
                           }},
        // for tag <videomix></videomix>
        { AssetType::VIDEOMIX, {
                                  QStringLiteral("videomix"), // specific with arrm
                              }},
        // for tag <wheel></wheel>
        { AssetType::WHEEL, {
                               QStringLiteral("wheel"),
                           }},
        // for tag <wheelcarbon></wheelcarbon>
        { AssetType::WHEEL_CARBON, {
                                      QStringLiteral("wheelcarbon"),
                                  }},
        // for tag <wheelsteel></wheelsteel>
        { AssetType::WHEEL_STEEL, {
                                     QStringLiteral("wheelsteel"),
                                 }},
    };

    const std::array<QString, 1> MEDIA_DIRS {
        QStringLiteral("/media/"),
    };

    constexpr auto DIR_FILTERS = QDir::Files | QDir::Readable | QDir::NoDotAndDotDot;
    constexpr auto DIR_FLAGS = QDirIterator::Subdirectories | QDirIterator::FollowSymlinks;

    //Log::debug(log_tag, LOGMSG("Nb elements in extless_path_to_game : %1").arg(QString::number(extless_path_to_game.size())));

    //Log::debug(log_tag, LOGMSG("Nb elements in sctx.current_filepath_to_entry_map() : %1").arg(QString::number(sctx.current_filepath_to_entry_map().size())));
    //Log::debug(log_tag, LOGMSG("Nb elements in sctx.current_collection_to_entry_map() : %1").arg(QString::number(sctx.current_collection_to_entry_map().size())));

    size_t found_assets_cnt = 0;
    bool gamepath_db_generated = false;
    HashMap<QString, model::Game*> extless_path_to_game;

    //***FOR TEST PURPOSE ONLY - DELETE FOR EACH RUNNING***
    //if (QFileInfo::exists(system_dir.path() + "/media.xml")){
    //    QFile::remove(system_dir.path() + "/media.xml");
    //}
    //*****************************************************

    QDomDocument document;
    QDomElement root;
    QFile xmlFile;
    QTextStream xmlContent(&xmlFile);
    if(generateMediaXML){
        //Open media.xml file to write it (we consider that media.xml doesn't exist if we call this function
        xmlFile.setFileName(xml_dir.path() + "/media.xml");
        if (!xmlFile.open(QFile::WriteOnly | QFile::Text ))
        {
            Log::error(log_tag, LOGMSG("%1 already opened or there is another issue").arg(xml_dir.path() + "/media.xml"));
            xmlFile.close();
            //exit function due to issue finally
            return;
        }
        //Calculate media directory & gamelist size in bytes
        //Too slow to calcculate size of directories finaly
        //QString media_dir_size = run("du -s " + xml_dir.path() + "/media/" +
        //                         " | head -n 1 | awk '{print $1}' | tr -d '\\n' | tr -d '\\r'"); //To keep only one line without CR or LF or hidden char
        QString gamelist_size = run("ls -l " + xml_dir.path() + "/gamelist.xml"+
                                    " | head -n 1 | awk '{print $5}' | tr -d '\\n' | tr -d '\\r'"); //To keep only one line without CR or LF or hidden char
        QString gamelist_date = run("date '+%F-%H-%M-%S' -r " + xml_dir.path() + "/gamelist.xml"+
                                    " | head -n 1 | tr -d '\\n' | tr -d '\\r'"); //To keep only one line without CR or LF or hidden char

        //make the root element
        root = document.createElement("mediaList");
        //root.setAttribute("media_dir_size", media_dir_size);
        root.setAttribute("gamelist_size", gamelist_size);
        root.setAttribute("gamelist_date", gamelist_date);
        //add it to document
        document.appendChild(root);
    }

    //Log::debug(log_tag, LOGMSG("Nb elements in MEDIA_DIRS : %1").arg(QString::number(MEDIA_DIRS.size())));
    for (const QString& media_dir_subpath : MEDIA_DIRS) {
        const QString game_media_dir = xml_dir.path() % media_dir_subpath;
        if (!QFileInfo::exists(game_media_dir))
        {
            //Log::debug(log_tag, LOGMSG("%1 directory not found :-(").arg(game_media_dir));
            continue;
        }
        else if (!gamepath_db_generated) //first iteration only
        {
            //we build this db only one time and for one system now, to be able to search quickly
            extless_path_to_game = build_gamepath_db(sctx.current_filepath_to_entry_map());
            gamepath_db_generated = true;
        }
        //Log::debug(log_tag, LOGMSG("%1 is the media directory !").arg(game_media_dir));
        QDirIterator mediadir_it(game_media_dir,QDir::Dirs | QDir::NoDotAndDotDot);
        while (mediadir_it.hasNext()) {
            const QString search_dir = mediadir_it.next();
            const QFileInfo fileInfo(search_dir);
            const QString dir_name = fileInfo.fileName();
            //Log::debug(log_tag, LOGMSG("%1 is the directory to search !").arg(search_dir));
            const int subpath_len = media_dir_subpath.length() + dir_name.length();
            QDirIterator dir_it(search_dir, DIR_FILTERS, DIR_FLAGS);
            while (dir_it.hasNext()) {
                dir_it.next();
                const QFileInfo finfo = dir_it.fileInfo();
                const QString game_path = ::clean_abs_dir(finfo).remove(xml_dir.path().length(), subpath_len)
                                          % '/' % finfo.completeBaseName();
                //Log::debug(log_tag, LOGMSG("%1 is the game path !").arg(game_path));
                const auto it = extless_path_to_game.find(game_path);
                if (it == extless_path_to_game.cend())
                    continue;
                //check if this game node already exist
                model::Game& game = *(it->second);
                //search in all AssetType for this media directory
                //Log::debug(log_tag, LOGMSG("%1 is the directory name to find in media directories list !").arg(dir_name));
                const QList<AssetType>& asset_types = DIR_ASSETS[dir_name];
                for (const AssetType& asset_type : asset_types) {
                    game.assetsMut().add_file(asset_type, dir_it.filePath());
                    //Log::debug(log_tag, LOGMSG("%1 asset added !").arg(dir_it.filePath()));
                    found_assets_cnt++;
                }
                if(generateMediaXML){
                    //write asset by asset in media.xml
                    QDomElement gamenode = document.createElement(dir_name);
                    //add game as attribut
                    gamenode.setAttribute("game", game_path);//game.path());
                    //add path of the asset as value
                    QDomText text = document.createTextNode(dir_it.filePath());
                    gamenode.appendChild(text);
                    //appen new asset to root
                    root.appendChild(gamenode);
                }
            }
        }
    }
    if(generateMediaXML){
        //write xml Content
        xmlContent << document.toString();
        //close xml
        xmlFile.close();
    }
    Log::info(log_tag, LOGMSG("%1 assets found from media directory").arg(QString::number(found_assets_cnt)));
}

size_t Metadata::import_media_from_xml(const QDir& xml_dir, providers::SearchContext& sctx, const SystemEntry& sysentry) const
{
    QString log_tag  = sysentry.shortname + " " + m_log_tag;
    //Log::info(log_tag, LOGMSG("Start to add Assets from media.xml in addition of ES Gamelist"));

    size_t found_assets_cnt = 0;
    HashMap<QString, model::Game*> extless_path_to_game;

    //Open media.xml file to write it (we consider that media.xml deson't exist if we call this function
    QFile xmlFile(xml_dir.path() + "/media.xml");
    if (!xmlFile.open(QFile::ReadOnly | QFile::Text ))
    {
        Log::error(log_tag, LOGMSG("%1 already opened, not found or there is another issue").arg(xml_dir.path() + "/media.xml"));
        xmlFile.close();
        //exit function due to issue
        return 0;
    }

    QDomDocument document;
    //load content of XML
    document.setContent(&xmlFile);

    // Extract the root markup
    QDomElement root=document.documentElement();

    //tentative to detect changes in gamelist/medias
    //calculate media directory & gamelist size in bytes

    //Too slow to calcculate size of directories  finally
    //QString media_dir_size = run("du -s " + xml_dir.path() + "/media/" +
    //                         " | head -n 1 | awk '{print $1}' | tr -d '\\n' | tr -d '\\r'"); //To keep only one line without CR or LF or hidden char
    //QString media_dir_size_from_xml = root.attribute("media_dir_size");
    //exit function if difference of size for media directory to request to regenerate media.xml
    //if(media_dir_size  != media_dir_size_from_xml) return 0;

    QString gamelist_size = run("ls -l " + xml_dir.path() + "/gamelist.xml"+
                             " | head -n 1 | awk '{print $5}' | tr -d '\\n' | tr -d '\\r'"); //To keep only one line without CR or LF or hidden char
    QString gamelist_size_from_xml = root.attribute("gamelist_size");
    //exit function if difference of size for gamelist to request to regenerate media.xml
    if(gamelist_size  != gamelist_size_from_xml) return 0;

    QString gamelist_date = run("date '+%F-%H-%M-%S' -r " + xml_dir.path() + "/gamelist.xml"+
                             " | head -n 1 | tr -d '\\n' | tr -d '\\r'"); //To keep only one line without CR or LF or hidden char
    QString gamelist_date_from_xml = root.attribute("gamelist_date");
    //exit function if difference of size for gamelist to request to regenerate media.xml
    if(gamelist_date != gamelist_date_from_xml) return 0;


    // Get the first child of the root (Markup COMPONENT is expected)
    QDomElement asset=root.firstChild().toElement();

    //build gamepath db for search !!!
    extless_path_to_game = build_gamepath_db(sctx.current_filepath_to_entry_map());

    // Loop while there is a child
    while(!asset.isNull())
    {
        QString game_path = asset.attribute("game");
        //Log::info(log_tag, LOGMSG("game_path : %1").arg(game_path));
        const auto it = extless_path_to_game.find(game_path);
        if (it == extless_path_to_game.cend()){
            // Next asset
            asset = asset.nextSibling().toElement();
            continue;
        }
        //check if this game node already exist
        model::Game& game = *(it->second);
        //search in all AssetType for this media directory
        const QList<AssetType>& asset_types = DIR_ASSETS[asset.tagName()];
        for (const AssetType& asset_type : asset_types) {
            game.assetsMut().add_file(asset_type, asset.text());
            found_assets_cnt++;
        }
        // Next asset
        asset = asset.nextSibling().toElement();
    }

    //close xml
    xmlFile.close();
    Log::info(log_tag, LOGMSG("%1 assets imported from media.xml").arg(QString::number(found_assets_cnt)));
    return found_assets_cnt;
}

size_t Metadata::import_lightgun_games_from_xml(const QString& xml_path)
{
    QString log_tag  = "lightgun.cfg " + m_log_tag;
    //Log::debug(log_tag, LOGMSG("Start to parse lightgun.cfg"));

    size_t found_lightgun_games_cnt = 0;


    //Open media.xml file to write it (we consider that media.xml deson't exist if we call this function
    QFile xmlFile(xml_path);
    if (!xmlFile.open(QFile::ReadOnly | QFile::Text ))
    {
        Log::error(log_tag, LOGMSG("%1 already opened, not found or there is another issue").arg(xml_path));
        xmlFile.close();
        //exit function due to issue
        return 0;
    }

    QDomDocument document;
    //load content of XML
    document.setContent(&xmlFile);

    // Extract the root markup
    QDomElement root=document.documentElement();

    // Get the first child of the root (Markup COMPONENT is expected)
    QDomNode n=root.firstChild();
    while (!n.isNull()) {
        if (n.isElement()) {
            QDomElement e = n.toElement();
            //search corresponding system in xml file
            if (e.tagName() == "system")
            {
                QString systemNames = ""; //reset here system name(s) for each plaform
                //Log::debug(log_tag, LOGMSG("system tag found"));
                QDomNode systemNode=e.firstChild();
                while (!systemNode.isNull()) {
                    if (systemNode.isElement()) {
                        QDomElement systemElement = systemNode.toElement();
                        if (systemElement.tagName() == "platform")
                        {
                            //Log::debug(log_tag, LOGMSG("`%1` platform found").arg(systemElement.text()));
                            //manage case to have several platforms in the same system (i know, it's strange... but we did that to regroup conf of flycast for exemple
                            //format : 'nes' or 'atomiswave','naomi','naomigd' or 'snes'
                            //we add ' around system name to well distinguish nes or snes for example when we will seach name of system.
                            if (systemNames != "") systemNames = systemNames + "," + "'" + systemElement.text() + "'";
                            else systemNames = "'" + systemElement.text() + "'";
                        }
                        else if (systemElement.tagName() == "games")
                        {
                            //Log::debug(log_tag, LOGMSG("games tag found"));
                            QDomNode gamesNode=systemElement.firstChild();
                            while (!gamesNode.isNull()) {
                                if (systemNode.isElement()) {
                                    QDomElement gameElement = gamesNode.toElement();
                                    if (gameElement.tagName() == "game")
                                    {
                                        //Log::debug(log_tag, LOGMSG("game '%1' found").arg(gameElement.attribute("tested")));
                                        if(gameElement.attribute("tested").toLower() == "ok"){
                                            QDomNode gameNode=gamesNode.firstChild();
                                            QString name = "";
                                            QString roms = "";
                                            while (!gameNode.isNull()) {
                                                if (gameNode.isElement()) {
                                                    QDomElement nameElement = gameNode.toElement();
                                                    if (nameElement.tagName() == "name")
                                                    {
                                                        name =  nameElement.text();
                                                        //Log::debug(log_tag, LOGMSG("`%1` as valid game found for '%2'").arg(name, systemNames));
                                                    }
                                                    if (nameElement.tagName() == "roms")
                                                    {
                                                        roms =  nameElement.text();
                                                        //Log::debug(log_tag, LOGMSG("`%1` as valid roms found for '%2'").arg(roms, systemNames));
                                                    }
                                                }
                                            gameNode = gameNode.nextSibling();
                                            }
                                            if(name != ""){
                                                m_lightgun_games.append(lightgunGameData(name, roms, systemNames));
                                                found_lightgun_games_cnt++;
                                            }
                                        }
                                    }
                                }
                            gamesNode = gamesNode.nextSibling();
                            }
                        }
                    }
                systemNode = systemNode.nextSibling();
                }
            }
        }
        n = n.nextSibling();
    }

    //close xml
    xmlFile.close();
    //Log::debug(log_tag, LOGMSG("%1 games as 'ok' found from lightgun.cfg").arg(QString::number(found_lightgun_games_cnt)));
    return found_lightgun_games_cnt;
}

void Metadata::apply_metadata(model::GameFile& gamefile, const QDir& xml_dir, HashMap<MetaType, QString, EnumHash>& xml_props, const SystemEntry& sysentry) const
{
    model::Game& game = *gamefile.parentGame();

    // first, the simple strings
    game.setTitle(xml_props[MetaType::NAME])
        .setDescription(xml_props[MetaType::DESC])
        .setHash(xml_props[MetaType::HASH])
        .setMd5(xml_props[MetaType::MD5])
		.setPath(xml_props[MetaType::PATH])
		.setGenreId(xml_props[MetaType::GENREID]);
    game.developerList().append(xml_props[MetaType::DEVELOPER]);
    game.publisherList().append(xml_props[MetaType::PUBLISHER]);
    game.genreList().append(xml_props[MetaType::GENRE]);

    //add here if lightgun games
    //part after is dedicated to set flag for lightgun games from our "lightgun.cfg" xml file
    if(sysentry.lightgun != "no"){
        if(RecalboxConf::Instance().AsBool("pegasus.flaglightgungames", true))
        {
            //search game from lightgun db using lightgun.cfg
            game.setLightgunGame(isLightgunGames(&game, &gamefile, sysentry));
        }
    }

    // then the numbers
    const int play_count = xml_props[MetaType::PLAYCOUNT].toInt();
    game.setRating(xml_props[MetaType::RATING].toFloat());

    // the player count can be a range
    const QString players_field = xml_props[MetaType::PLAYERS];
    const auto players_match = m_players_regex.match(players_field);
    if (players_match.hasMatch()) {
        const short a = players_match.captured(1).toShort();
        const short b = players_match.captured(3).toShort();
        game.setPlayerCount(std::max(a, b));
    }

    // then the bools
    const QString& favorite_val = xml_props[MetaType::FAVORITE];
    if (favorite_val.compare(QLatin1String("yes"), Qt::CaseInsensitive) == 0
        || favorite_val.compare(QLatin1String("true"), Qt::CaseInsensitive) == 0
        || favorite_val.compare(QLatin1String("1")) == 0) {
        game.setFavorite(true);
    }

    // then dates
    // NOTE: QDateTime::fromString returns a null (invalid) date on error

    const QDateTime last_played = QDateTime::fromString(xml_props[MetaType::LASTPLAYED], m_date_format);
    const QDateTime release_time(QDateTime::fromString(xml_props[MetaType::RELEASE], m_date_format));
    game.setReleaseDate(release_time.date());
    gamefile.update_playstats(play_count, 0, last_played);

    // then assets
    // TODO: C++17
    for (const auto& pair : m_asset_type_map) {
        const QFileInfo finfo = shell_to_finfo(xml_dir, xml_props[pair.first]);
        QString path = ::clean_abs_path(finfo);
        game.assetsMut().add_file(pair.second, std::move(path));
    }
}

} // namespace es2
} // namespace providers
