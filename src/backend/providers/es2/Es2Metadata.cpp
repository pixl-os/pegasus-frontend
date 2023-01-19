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
//

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
#include <QElapsedTimer>

//For recalbox
#include "RecalboxConf.h"

namespace {

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
    GENREID,
    HIDDEN,
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

QString Metadata::find_gamelist_xml(const std::vector<QString>& possible_config_dirs, const QDir& system_dir, const QString& system_name) const
{
    const QString GAMELISTFILE = QStringLiteral("/gamelist.xml");

    std::vector<QString> possible_files { system_dir.path() % GAMELISTFILE };

    if (!system_name.isEmpty()) {
        for (const QString& dir_path : possible_config_dirs) {
            possible_files.emplace_back(dir_path
                % QStringLiteral("/gamelists/")
                % system_name
                % GAMELISTFILE);
        }
    }

    for (const auto& path : possible_files) {
        if (QFileInfo::exists(path))
            return path;
    }

    return {};
}

QString Metadata::find_media_xml(const std::vector<QString>& possible_config_dirs, const QDir& system_dir, const QString& system_name) const
{
    const QString MEDIAFILE = QStringLiteral("/media.xml");

    std::vector<QString> possible_files { system_dir.path() % MEDIAFILE };

    if (!system_name.isEmpty()) {
        for (const QString& dir_path : possible_config_dirs) {
            possible_files.emplace_back(dir_path
                % QStringLiteral("/media/")
                % system_name
                % MEDIAFILE);
        }
    }

    for (const auto& path : possible_files) {
        if (QFileInfo::exists(path))
            return path;
    }

    return {};
}

void Metadata::process_gamelist_xml(const QDir& xml_dir, QXmlStreamReader& xml, providers::SearchContext& sctx, const QString& system_name) const
{
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
    model::Collection& collection = *sctx.get_or_create_collection(system_name);
	
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
            Log::warning(m_log_tag, LOGMSG("The `<game>` node in `%1` at line %2 has no valid `<path>` entry")
                .arg(static_cast<QFile*>(xml.device())->fileName(), QString::number(linenum)));
            continue;
        }

        const QFileInfo finfo = shell_to_finfo(xml_dir, shell_filepath);
        const QString path = ::clean_abs_path(finfo);
        
        if(RecalboxConf::Instance().AsBool("emulationstation.gamelistonly") || RecalboxConf::Instance().AsBool("emulationstation.gamelistfirst"))
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
        apply_metadata(*entry_ptr, xml_dir, xml_props);
    }

    if(RecalboxConf::Instance().AsBool("emulationstation.gamelistonly") || RecalboxConf::Instance().AsBool("emulationstation.gamelistfirst"))
    {
        Log::info(m_log_tag, LOGMSG("System `%1` gamelist provided %2 games")
        .arg(system_name, QString::number(found_games)));     
    }
    
    if (xml.error()) {
        Log::warning(m_log_tag, xml.errorString());
        return;
    }
}


void Metadata::find_metadata_for_system(const SystemEntry& sysentry, providers::SearchContext& sctx) const
{
    Q_ASSERT(!sysentry.name.isEmpty());
    Q_ASSERT(!sysentry.path.isEmpty());


    if (sysentry.shortname == QLatin1String("steam")) {
        Log::info(m_log_tag, LOGMSG("Ignoring the `steam` system in favor of the built-in Steam support"));
        return;
    }

    QElapsedTimer gamelist_timer;
    gamelist_timer.start();

    const QDir xml_dir(sysentry.path);
    
    //Log::debug(m_log_tag, LOGMSG("sysentry.path:  %1").arg(sysentry.path));
      
    const QString gamelist_path = find_gamelist_xml(m_config_dirs, xml_dir, sysentry.shortname);
    if (gamelist_path.isEmpty()) {
        Log::warning(m_log_tag, LOGMSG("No gamelist file found for system `%1`").arg(sysentry.shortname));
        return;
    }
    Log::info(m_log_tag, LOGMSG("Found `%1`").arg(gamelist_path));

    QFile xml_file(gamelist_path);
    if (!xml_file.open(QIODevice::ReadOnly)) {
        Log::error(m_log_tag, LOGMSG("Could not open `%1`").arg(gamelist_path));
        return;
    }

    QXmlStreamReader xml(&xml_file);
    process_gamelist_xml(xml_dir, xml, sctx, sysentry.name);
    Log::info(LOGMSG("Timing: Gamelist processing took %1ms").arg(gamelist_timer.elapsed()));    
    
    if(!RecalboxConf::Instance().AsBool("pegasus.deactivateskrapermedia", false))
    {
        //to add images stored by skraper and linked to gamelist/system of ES
        QElapsedTimer skraper_media_timer;
        skraper_media_timer.start();
        //Log::info(LOGMSG("media.xml path: %1").arg(xml_dir.path() + "/media.xml"));
        //use media.xml or not
        if(RecalboxConf::Instance().AsBool("pegasus.usemedialist", true)){
            if (!QFileInfo::exists(xml_dir.path() + "/media.xml")){
                Log::info(LOGMSG("media.xml not found (to generate for  this  time): %1").arg(xml_dir.path() + "/media.xml"));
                //set last parameter to activate or not the media.xml generation during parsing of media
                add_skraper_media_metadata(xml_dir, sctx, true);
            }
            else{
                Log::info(LOGMSG("media.xml used: %1").arg(xml_dir.path() + "/media.xml"));
                //add media from xml (to see if it's quicker or not  ?!)
                import_media_from_xml(xml_dir, sctx);
            }
        }
        else{
            //set last parameter to activate deactivate the media.xml generation during parsing of media
            add_skraper_media_metadata(xml_dir, sctx, false);
        }
        //*****************************************************
        Log::info(LOGMSG("Timing: Skraper media searching took %1ms").arg(skraper_media_timer.elapsed()));
    }
}

void Metadata::add_skraper_media_metadata(const QDir& system_dir, providers::SearchContext& sctx, bool generateMediaXML) const
{
    Log::info(m_log_tag, LOGMSG("Start to add Skraper Assets in addition of ES Gamelist"));
    // NOTE: The entries are ordered by priority
    const HashMap<AssetType, QStringList, EnumHash> ASSET_DIRS {
        { AssetType::ARCADE_MARQUEE, {
            QStringLiteral("marquee"),
            QStringLiteral("screenmarquee"),
            QStringLiteral("screenmarqueesmall"),
            QStringLiteral("steamgrid"),
        }},
        { AssetType::ARCADE_BEZEL, {
            QStringLiteral("bezel"),
        }},
        { AssetType::BACKGROUND, {
            QStringLiteral("fanart"),
            QStringLiteral("screenshot"),
        }},
        { AssetType::BOX_BACK, {
            QStringLiteral("box2dback"),
        }},
        { AssetType::BOX_FRONT, {
            QStringLiteral("box3d"),
            QStringLiteral("support"),
            QStringLiteral("box2dfront"),
            QStringLiteral("supporttexture"),
        }},
        { AssetType::BOX_FULL, {
            QStringLiteral("boxtexture"),
        }},
        { AssetType::BOX_SPINE, {
            QStringLiteral("box2dside"),
        }},
        { AssetType::CARTRIDGE, {
            QStringLiteral("support"),
        }},
        { AssetType::CARTRIDGETEXTURE, {
            QStringLiteral("supporttexture"),
        }},
        { AssetType::LOGO, {
            QStringLiteral("wheel"),
            QStringLiteral("wheelcarbon"),
            QStringLiteral("wheelsteel"),
        }},
        { AssetType::SCREENSHOT, {
            QStringLiteral("screenshot"),
            QStringLiteral("screenshottitle"),
        }},
        { AssetType::TITLESCREEN, {
            QStringLiteral("screenshottitle"),
        }},
        { AssetType::UI_STEAMGRID, {
            QStringLiteral("steamgrid"),
        }},
        { AssetType::VIDEO, {
            QStringLiteral("videos"),
        }},
        { AssetType::MANUAL, {
            QStringLiteral("manuals"),
        }},
        { AssetType::MAPS, {
            QStringLiteral("maps"),
        }},
        { AssetType::MUSIC, {
            QStringLiteral("music"),
        }},
    };

    const std::array<QString, 1> MEDIA_DIRS {
        QStringLiteral("/media/"),
    };

    constexpr auto DIR_FILTERS = QDir::Files | QDir::Readable | QDir::NoDotAndDotDot;
    constexpr auto DIR_FLAGS = QDirIterator::Subdirectories | QDirIterator::FollowSymlinks;
    
    //Log::debug(m_log_tag, LOGMSG("Nb elements in extless_path_to_game : %1").arg(QString::number(extless_path_to_game.size())));
    
    //Log::debug(m_log_tag, LOGMSG("Nb elements in sctx.current_filepath_to_entry_map() : %1").arg(QString::number(sctx.current_filepath_to_entry_map().size())));
    //Log::debug(m_log_tag, LOGMSG("Nb elements in sctx.current_collection_to_entry_map() : %1").arg(QString::number(sctx.current_collection_to_entry_map().size())));

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
        //Open media.xml file to write it (we consider that media.xml deson't exist if we call this function
        xmlFile.setFileName(system_dir.path() + "/media.xml");
        if (!xmlFile.open(QFile::WriteOnly | QFile::Text ))
        {
            Log::error(m_log_tag, LOGMSG("%1 already opened or there is another issue").arg(system_dir.path() + "/media.xml"));
            xmlFile.close();
        }
        //make the root element
        root = document.createElement("mediaList");
        //add it to document
        document.appendChild(root);
    }

    //Log::debug(m_log_tag, LOGMSG("Nb elements in MEDIA_DIRS : %1").arg(QString::number(MEDIA_DIRS.size())));
    for (const QString& media_dir_subpath : MEDIA_DIRS) {
        const QString game_media_dir = system_dir.path() % media_dir_subpath;
        if (!QFileInfo::exists(game_media_dir)) 
            {
                //Log::debug(m_log_tag, LOGMSG("%1 directory not found :-(").arg(game_media_dir));
                continue;
            }
        else if (!gamepath_db_generated) //first iteration only
            {
            //all path name seems here but without extension !!!
            extless_path_to_game = build_gamepath_db(sctx.current_filepath_to_entry_map()); 
            gamepath_db_generated = true;
            }            
        //check existing asset directories in media
        //Log::debug(m_log_tag, LOGMSG("Nb elements in ASSET_DIRS : %1").arg(QString::number(ASSET_DIRS.size())));
        for (const auto& asset_dir_entry : ASSET_DIRS) {
            const AssetType asset_type = asset_dir_entry.first;
            const QStringList& dir_names = asset_dir_entry.second;
            for (const QString& dir_name : dir_names) {
                const QString search_dir = game_media_dir % dir_name;
                //Log::debug(m_log_tag, LOGMSG("%1 is the directory to search !").arg(search_dir));
                const int subpath_len = media_dir_subpath.length() + dir_name.length();
                QDirIterator dir_it(search_dir, DIR_FILTERS, DIR_FLAGS);
                while (dir_it.hasNext()) {
                    dir_it.next();
                    const QFileInfo finfo = dir_it.fileInfo();
                    const QString game_path = ::clean_abs_dir(finfo).remove(system_dir.path().length(), subpath_len)
                                            % '/' % finfo.completeBaseName();
                    //Log::debug(m_log_tag, LOGMSG("%1 is the game path !").arg(game_path));
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
                    //Log::debug(m_log_tag, LOGMSG("%1 asset added !").arg(dir_it.filePath()));
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
    Log::info(m_log_tag, LOGMSG("%1 assets found").arg(QString::number(found_assets_cnt)));
}

void Metadata::import_media_from_xml(const QDir& system_dir, providers::SearchContext& sctx) const
{
    Log::info(m_log_tag, LOGMSG("Start to add Assets from media.xml in addition of ES Gamelist"));

    QHash<QString, QList<AssetType>> ASSET_REFS {
        { QStringLiteral("marquee"), {AssetType::ARCADE_MARQUEE}},
        { QStringLiteral("screenmarquee"), {AssetType::ARCADE_MARQUEE}},
        { QStringLiteral("screenmarqueesmall"), {AssetType::ARCADE_MARQUEE}},
        { QStringLiteral("bezel"), {AssetType::ARCADE_BEZEL}},
        { QStringLiteral("fanart"), {AssetType::BACKGROUND}},
        { QStringLiteral("box2dback"), {AssetType::BOX_BACK}},
        { QStringLiteral("box3d"), {AssetType::BOX_FRONT}},
        { QStringLiteral("support"), {AssetType::BOX_FRONT, AssetType::CARTRIDGE}},
        { QStringLiteral("box2dfront"), {AssetType::BOX_FRONT}},
        { QStringLiteral("supporttexture"), {AssetType::BOX_FRONT}},
        { QStringLiteral("boxtexture"), {AssetType::BOX_FULL}},
        { QStringLiteral("box2dside"), {AssetType::BOX_SPINE}},
        { QStringLiteral("supporttexture"), {AssetType::CARTRIDGETEXTURE,AssetType::BOX_FRONT}},
        { QStringLiteral("wheel"), {AssetType::LOGO}},
        { QStringLiteral("wheelcarbon"), {AssetType::LOGO}},
        { QStringLiteral("wheelsteel"), {AssetType::LOGO}},
        { QStringLiteral("screenshot"), {AssetType::SCREENSHOT, AssetType::BACKGROUND}},
        { QStringLiteral("screenshottitle"), {AssetType::TITLESCREEN, AssetType::SCREENSHOT}},
        { QStringLiteral("steamgrid"), {AssetType::UI_STEAMGRID, AssetType::ARCADE_MARQUEE}},
        { QStringLiteral("videos"), {AssetType::VIDEO}},
        { QStringLiteral("manuals"), {AssetType::MANUAL}},
        { QStringLiteral("maps"), {AssetType::MAPS}},
        { QStringLiteral("music"), {AssetType::MUSIC}}
    };

    size_t found_assets_cnt = 0;
    HashMap<QString, model::Game*> extless_path_to_game;

    //Open media.xml file to write it (we consider that media.xml deson't exist if we call this function
    QFile xmlFile(system_dir.path() + "/media.xml");
    if (!xmlFile.open(QFile::ReadOnly | QFile::Text ))
    {
        Log::error(m_log_tag, LOGMSG("%1 already opened or there is another issue").arg(system_dir.path() + "/media.xml"));
        xmlFile.close();
        //exit function
        return;
    }
    QDomDocument document;
    //load content of XML
    document.setContent(&xmlFile);

    // Extract the root markup
    QDomElement root=document.documentElement();
    // Get the first child of the root (Markup COMPONENT is expected)
    QDomElement asset=root.firstChild().toElement();

    //build gamepath db for search !!!
    extless_path_to_game = build_gamepath_db(sctx.current_filepath_to_entry_map());

    // Loop while there is a child
    while(!asset.isNull())
    {
        QString game_path = asset.attribute("game");
        //Log::info(m_log_tag, LOGMSG("game_path : %1").arg(game_path));
        const auto it = extless_path_to_game.find(game_path);
        if (it == extless_path_to_game.cend()){
            // Next asset
            asset = asset.nextSibling().toElement();
            continue;
        }
        //check if this game node already exist
        model::Game& game = *(it->second);
        //search in all AssetType for this media directory
        const QList<AssetType>& asset_types = ASSET_REFS[asset.tagName()];
        for (const AssetType& asset_type : asset_types) {
            game.assetsMut().add_file(asset_type, asset.text());
            found_assets_cnt++;
        }
        // Next asset
        asset = asset.nextSibling().toElement();
    }

    //close xml
    xmlFile.close();
    Log::info(m_log_tag, LOGMSG("%1 assets found").arg(QString::number(found_assets_cnt)));
}

void Metadata::apply_metadata(model::GameFile& gamefile, const QDir& xml_dir, HashMap<MetaType, QString, EnumHash>& xml_props) const
{
    model::Game& game = *gamefile.parentGame();

    // first, the simple strings
    game.setTitle(xml_props[MetaType::NAME])
        .setDescription(xml_props[MetaType::DESC])
        .setHash(xml_props[MetaType::HASH])
		.setPath(xml_props[MetaType::PATH])
		.setGenreId(xml_props[MetaType::GENREID]);
    game.developerList().append(xml_props[MetaType::DEVELOPER]);
    game.publisherList().append(xml_props[MetaType::PUBLISHER]);
    game.genreList().append(xml_props[MetaType::GENRE]);

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
