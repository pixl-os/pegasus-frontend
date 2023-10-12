// Pegasus Frontend
//
// Created by BozoTheGeek 07/06/2021
//

#include "RetroAchievementsMetadata.h"

#include "Log.h"
#include "model/gaming/Assets.h"
#include "model/gaming/Collection.h"
#include "model/gaming/Game.h"
#include "model/gaming/GameFile.h"
#include "providers/JsonCacheUtils.h"
#include "providers/SearchContext.h"
#include "utils/CommandTokenizer.h"
#include "utils/Zip.h"

//for retroachievements management coming from libretro and rcheevos
#include "libretro.h"
#include "rc_hash.h"
#include "formats/cdfs.h"
#include "file/file_path.h"
#include "string/stdstring.h"
#include "streams/chd_stream.h"

#include <QJsonArray>
#include <QJsonDocument>
#include <QJsonObject>
#include <QNetworkReply>
#include <QStringBuilder>
#include <QDir>

#include <QEventLoop>
#include <QElapsedTimer>

#include <RecalboxConf.h>

namespace {
//***********************UTILS FUNCTIONS***********************************//
QString PathMakeEscaped(QString param)
{
  std::string escaped = param.toUtf8().constData();

  static std::string invalidChars = " '\"\\!$^&*(){}[]?;<>";
  const char* invalids = invalidChars.c_str();
  for(int i = escaped.size(); --i >= 0; )
  {
    char c = escaped.c_str()[i];
    for(int j = invalidChars.size(); --j >= 0; )
      if (c == invalids[j])
      {
        escaped.insert(i, "\\");
        break;
      }
  }

  return QString::fromStdString(escaped);
}

QString serialize_command(const QString& cmd, const QStringList& args)
{
    return (QStringList(QDir::toNativeSeparators(cmd)) + args).join(QLatin1String(" "));
}

QJsonDocument get_json_from_url(QString url_str, QString log_tag, QNetworkAccessManager &manager)
{
	QNetworkAccessManager* const manager_ptr = &manager;
	const QUrl url(url_str, QUrl::StrictMode);
	Q_ASSERT(url.isValid());
	if (Q_UNLIKELY(!url.isValid()))
	{
        Log::debug(log_tag, LOGMSG("Q_UNLIKELY(!url.isValid())"));
		return QJsonDocument();
	}
	
	//Set request
	QNetworkRequest request(url);
    request.setAttribute(QNetworkRequest::FollowRedirectsAttribute, true);
	#if (QT_VERSION >= QT_VERSION_CHECK(5, 15, 0))
		request.setTransferTimeout(10000);
	#endif

	//Get request
    QNetworkReply* const reply = manager_ptr->get(request);
	
	//do loop on connect to wait donwload in this case
	QEventLoop loop;
	QObject::connect(reply, &QNetworkReply::finished, &loop, &QEventLoop::quit);
	loop.exec();
	
	if (reply->error()) {
		Log::warning(log_tag, LOGMSG("Downloading metadata failed: %1").arg(reply->errorString()));
		return QJsonDocument();
	}
	const QByteArray raw_data = reply->readAll();
	QJsonDocument json = QJsonDocument::fromJson(raw_data);
	if (json.isNull()) {
		Log::warning(log_tag, LOGMSG(
                         "Failed to parse the response of the server, "
                         "either it's no longer available from %1 or the API has changed").arg(url_str));
		return QJsonDocument();
	}	
	return json;
}
//***********************END OF UTILS FUNCTIONS***********************************//

//***********************JSON PARSING FUNCTIONS***********************************//
QString apply_login_json(QString log_tag, const QJsonDocument& json)
//Example of JSON content
// {"Success":true,"User":"username","Token":"lePOt1iA5jr56cZj","Score":25,"Messages":0}
//from : http://retroachievements.org/dorequest.php?r=login&u=username&p=password
{
    using QL1 = QLatin1String;

    if (json.isNull())
	{
		Log::debug(log_tag, LOGMSG("json.isNull()"));
        return "";
	}
    const auto json_root = json.object();
    if (json_root.isEmpty())
	{
		Log::debug(log_tag, LOGMSG("json_root.isEmpty()")); 
		return "";
	}

    const bool login_success = json_root[QL1("Success")].toBool();
    if (!login_success)
	{
		Log::debug(log_tag, LOGMSG("login wrong")); 
		return "";
	}
	const QString user_data = json_root[QL1("User")].toString();
    if (user_data.isEmpty())
	{
		Log::debug(log_tag, LOGMSG("user_data.isEmpty()")); 
		return "";
	}
	else Log::debug(log_tag, LOGMSG("User: %1").arg(user_data));
	
	QString token_data = json_root[QL1("Token")].toString();
    if (token_data.isEmpty())
        return "";
	else 
	{
		Log::debug(log_tag, LOGMSG("Token: %1").arg(token_data));
	}
	
    return token_data;
}	

int apply_gameid_json(QString log_tag, const QJsonDocument& json)
//Example of JSON content
//  {"Success":true,"GameID":1669}
//or{"Success":true,"GameID":0} if wrong/game doesn't exist/recognized
//from : http://retroachievements.org/dorequest.php?r=gameid&m=44dca16afbee7fd947e86c30c1183846

{
    using QL1 = QLatin1String;

    if (json.isNull())
	{
		Log::debug(log_tag, LOGMSG("json.isNull()"));
        return 0;
	}
    const auto json_root = json.object();
    if (json_root.isEmpty())
	{
		Log::debug(log_tag, LOGMSG("json_root.isEmpty()")); 
		return 0;
	}

    const bool login_success = json_root[QL1("Success")].toBool();
    if (!login_success)
	{
		Log::debug(log_tag, LOGMSG("gameid request wrong")); 
		return 0;
	}
	const int gameid_data = json_root[QL1("GameID")].toInt();
	Log::debug(log_tag, LOGMSG("GameID: %1").arg(gameid_data));
	return gameid_data;
}

bool apply_game_json(model::Game& game, QString log_tag, const QJsonDocument& json)
//from : "http://retroachievements.org/dorequest.php?r=patch&u=%1&t=%2&g=%3"
{
    using QL1 = QLatin1String;

    if (json.isNull())
	{
		Log::debug(log_tag, LOGMSG("json.isNull()"));
        return false;
	}
    const auto json_root = json.object();
    if (json_root.isEmpty())
	{
		Log::debug(log_tag, LOGMSG("json_root.isEmpty()")); 
		return false;
	}
    const bool patch_success = json_root[QL1("Success")].toBool();
    if (!patch_success)
	{
		Log::debug(log_tag, LOGMSG("Error: %1").arg(json_root[QL1("Error")].toString())); 
		return false;
	}
	const auto PatchData = json_root[QL1("PatchData")].toObject();
	if (PatchData.isEmpty()) 
	{
		Log::debug(log_tag, LOGMSG("No Patch Data found"));
		return false;
	}
	const auto Achievements = PatchData[QL1("Achievements")].toArray();
	if (Achievements.isEmpty()) 
	{
		Log::debug(log_tag, LOGMSG("No Achievements found"));
		return false;
	}

    QList<model::RetroAchievement> AllRetroAchievements;
	
    for (const auto& array_entry : Achievements) {
        const auto Achievement = array_entry.toObject();
		const auto ID = Achievement[QL1("ID")].toInt();
		const auto Title = Achievement[QL1("Title")].toString();
		Log::debug(log_tag, LOGMSG("Title=%1").arg(Title)); 
		const auto Description = Achievement[QL1("Description")].toString();
		const auto Points = Achievement[QL1("Points")].toInt();
		const auto Author = Achievement[QL1("Author")].toString();
		const auto BadgeName = Achievement[QL1("BadgeName")].toString();
		Log::debug(log_tag, LOGMSG("BadgeName=%1").arg(BadgeName)); 
		const auto Flags = Achievement[QL1("Flags")].toInt();
		
		if ((Title != "") || (BadgeName != ""))
		{
			//Add game retro achievement one by one
			AllRetroAchievements.append({ID
										   ,Title
										   ,Description
										   ,Points
										   ,Author
										   ,BadgeName
										   ,Flags
										   ,false
										   ,false});
		}
    }
	//Set all game retro achievements in game.
	game.setRetroAchievements(AllRetroAchievements);
    return true;	
}

bool apply_achievements_status_json(model::Game& game,int Hardcore, QString log_tag, const QJsonDocument& json)
//from: http://retroachievements.org/dorequest.php?r=unlocks&u=bozothegeek&t=sdfgsdf564564&g=1669&h=0
//{"Success":true,"UserUnlocks":[22989,22991,22992,22994,22995],"GameID":1669,"HardcoreMode":false}
{
    using QL1 = QLatin1String;

    if (json.isNull())
	{
		Log::debug(log_tag, LOGMSG("json.isNull()"));
        return false;
	}
    const auto json_root = json.object();
    if (json_root.isEmpty())
	{
		Log::debug(log_tag, LOGMSG("json_root.isEmpty()")); 
		return false;
	}
    const bool patch_success = json_root[QL1("Success")].toBool();
    if (!patch_success)
	{
		Log::debug(log_tag, LOGMSG("Error: %1").arg(json_root[QL1("Error")].toString())); 
		return false;
	}
	const auto UserUnlocks = json_root[QL1("UserUnlocks")].toArray();
	if (UserUnlocks.isEmpty()) 
	{
		Log::debug(log_tag, LOGMSG("No UserUnlocks found"));
		return false;
	}
	
	QMap<QString, bool> map;
    for (const auto& array_entry : UserUnlocks) {
        const auto UserUnlock = array_entry.toInt();
		Log::debug(log_tag, LOGMSG("ID '%1' is unlocked").arg(QString::number(UserUnlock)));
		map.insert(QString::number(UserUnlock),true);

    }
	//Set retro achievements unlocked in game.
	for (int i=0;i<game.getRetroAchievementsCount();i++) {
		Log::debug(log_tag, LOGMSG("The ID verified is '%1'").arg(game.retroAchievements()[i].ID));
		if (map.contains(QString::number(game.retroAchievements()[i].ID)))
		{
			game.unlockRetroAchievement(i);
			if (Hardcore == 1)
			{
				game.activateHardcoreRetroAchievement(i);
			}
		}
		Log::debug(log_tag, LOGMSG("Badge %1 - unlocked : %2 - hardcore mode: %3").arg(game.retroAchievements()[i].BadgeName,game.retroAchievements()[i].Unlocked ? "true" : "false",game.retroAchievements()[i].HardcoreMode ? "true" : "false"));
	}
	
    return true;	
}	

HashMap <QString, qint64> apply_hash_library_json(QString log_tag, const QJsonDocument& json)
//from: http://retroachievements.org/dorequest.php?r=hashlibrary
//{"Success":true,"MD5List":{"1b1d9ac862c387367e904036114c4825":1,"1bc674be034e43c96b86487ac69d9293":1,........
{
    using QL1 = QLatin1String;

    if (json.isNull())
    {
        Log::debug(log_tag, LOGMSG("json.isNull()"));
        return {};
    }
    const auto json_root = json.object();
    if (json_root.isEmpty())
    {
        Log::debug(log_tag, LOGMSG("json_root.isEmpty()"));
        return {};
    }
    const bool success = json_root[QL1("Success")].toBool();
    if (!success)
    {
        Log::debug(log_tag, LOGMSG("Error: %1").arg(json_root[QL1("Error")].toString()));
        return {};
    }

    QJsonObject MD5List = json_root[QL1("MD5List")].toObject();
    QJsonDocument doc(MD5List);
    //convert to string to be able to be able to split (need to remove {} and "")
    QString jsonString(doc.toJson(QJsonDocument::Compact).trimmed());
    jsonString.remove('{');
    jsonString.remove('}');
    jsonString.remove('"');
    jsonString.remove('"');
    Log::debug(log_tag, LOGMSG("Json MD5LIST content (first 100 characters) : '%1'").arg(jsonString.toStdString().substr(0,100).c_str()));
    //convert to array split by ","
    QStringList list = jsonString.split(",");
    //parse list to create hashmap
    HashMap <QString, qint64> map;
    foreach(const QString &HashAndGameId, list){
        QStringList content = HashAndGameId.split(":");
        if(content.length() == 2){
            map.emplace(std::move(content.at(0)), std::move(content.at(1).toLongLong()));
        }
    }
    return map;
}
//***********************END OF JSON PARSING FUNCTIONS***********************************//

//***********************GET FUNCTIONS***********************************//
QString get_token(QString log_tag, QString json_cache_dir, QNetworkAccessManager &manager)
//from : http://retroachievements.org/dorequest.php?r=login&u=username&p=password
{
	QElapsedTimer get_token_timer;
    get_token_timer.start();
	
/* 	## Enable retroarchievements (0,1)
	## Set your www.retroachievements.org username/password
	## Escape your special chars (# ; $) with a backslash : $ => \$
	global.retroachievements=1
	global.retroachievements.hardcore=0
	global.retroachievements.username=login
	global.retroachievements.password=motdepasse */
	
	
	
	//GET information from recalbox.conf
	QString Username = QString::fromStdString(RecalboxConf::Instance().AsString("global.retroachievements.username"));
	QString Password = QString::fromStdString(RecalboxConf::Instance().AsString("global.retroachievements.password"));
		
	//Try to get token from json in cache
	QJsonDocument json = providers::read_json_from_cache(log_tag + " - cache", json_cache_dir, Username + Password);
	
	//replace backslash as proposed in recalbox.conf, this backslash is only necessary for retroarch (but seems not to work in retroarch ?!)
	Username.remove("\\", Qt::CaseInsensitive); 
	Password.remove("\\", Qt::CaseInsensitive);
	
	QString token = apply_login_json(log_tag + " - cache", json);
	if (token == "")
	{
		//Delete JSON inb cache by security - use Username and Password to have a unique key and if password is changed finally.
		providers::delete_cached_json(log_tag, json_cache_dir, Username + Password);

		//To get token
		const QString url_str = QStringLiteral("http://retroachievements.org/dorequest.php?r=login&u=%1&p=%2").arg(Username,Password);
		json = get_json_from_url(url_str, log_tag, manager);
		token = apply_login_json(log_tag, json);
		if (token != "")
		{
			//saved in cache
			providers::cache_json(log_tag, json_cache_dir, Username + Password, json.toJson(QJsonDocument::Compact));
		}
	}
	
	//Log::info(log_tag, LOGMSG("Stats - Timing: Get token processing: %1ms").arg(get_token_timer.elapsed()));    
	return token;
}	

int get_gameid_from_hash(QString Hash, QString log_tag, QNetworkAccessManager &manager)
//from : http://retroachievements.org/dorequest.php?r=gameid&m=44dca16afbee7fd947e86c30c1183846
{
	QElapsedTimer get_gameid_timer;
    get_gameid_timer.start();
	int gameid = 0;
	
	if (Hash != "")
	{
		Log::debug(log_tag, LOGMSG("hash value to find GameID: '%1'").arg(Hash));
		//no cache usage in this cache, the cache will be manage by the game object itself by data stored inside.
		//To get GameID
		const QString url_str = QStringLiteral("http://retroachievements.org/dorequest.php?r=gameid&m=%1").arg(Hash);
		QJsonDocument json = get_json_from_url(url_str, log_tag, manager);
		gameid = apply_gameid_json(log_tag, json);
	}
	
    Log::debug(log_tag, LOGMSG("Stats - Timing: Get GameID processing from RA web site: %1ms").arg(get_gameid_timer.elapsed()));
	return gameid;
}	

int get_gameid_from_hashlibrary(QString Hash, QString log_tag, HashMap <QString, qint64> map)
//from hashlibrary stored in hashmap
{
    QElapsedTimer get_gameid_timer;
    get_gameid_timer.start();
    int gameid = 0;

    if (Hash != "")
    {
        Log::debug(log_tag, LOGMSG("hash value to find GameID: '%1'").arg(Hash));
        //no cache usage in this cache, the cache will be manage by the game object itself by data stored inside.
        //To get GameID
        if (map.size() >= 1)
        {
            const auto it = map.find(Hash);
            if (it != map.cend())
                gameid = it->second;
        }
    }
    Log::debug(log_tag, LOGMSG("Stats - Timing: Get GameID processing from hash library: %1ms").arg(get_gameid_timer.elapsed()));
    return gameid;
}

bool get_game_details_from_gameid(int gameid, QString token, model::Game& game, QString log_tag, QString json_cache_dir, QNetworkAccessManager &manager)
//from : http://retroachievements.org/dorequest.php?r=patch&u=bozothegeek&t=sd4f6s4dgf6sdf4gdf4g&g=1669
{
	QElapsedTimer get_game_details_timer;
    get_game_details_timer.start();
	bool result = false;
	
	if (gameid != 0)
	{
		//Try to get game details from json in cache
		QJsonDocument json = providers::read_json_from_cache(log_tag + " - cache", json_cache_dir, "RaGameID=" + QString::number(gameid));
		result = apply_game_json(game, log_tag + " - cache", json);
		if (result == false)
		{
			//Delete JSON inb cache by security - use Username and Password to have a unique key and if password is changed finally.
			providers::delete_cached_json(log_tag + " - cache", json_cache_dir, "RaGameID=" + QString::number(gameid));
			//to get Username
			QString Username = QString::fromStdString(RecalboxConf::Instance().AsString("global.retroachievements.username"));
			//Url to get Game details
			const QString url_str = QStringLiteral("http://retroachievements.org/dorequest.php?r=patch&u=%1&t=%2&g=%3").arg(Username,token,QString::number(gameid));
			QJsonDocument json = get_json_from_url(url_str, log_tag, manager);
			result = apply_game_json(game, log_tag, json);
			if (result == true)
			{
				//saved in cache
				providers::cache_json(log_tag, json_cache_dir, "RaGameID=" + QString::number(gameid), json.toJson(QJsonDocument::Compact));
			}
		}
	}
    Log::debug(log_tag, LOGMSG("Stats - Timing: Get Game Details processing: %1ms").arg(get_game_details_timer.elapsed()));
	return result;
}

bool get_achievements_status_from_gameid(int gameid, QString token, model::Game& game, QString log_tag, QNetworkAccessManager &manager)
//from : http://retroachievements.org/dorequest.php?r=unlocks&u=bozothegeek&t=sqdsqf5465fsd4sd65f4s6&g=1669&h=0
{
	QElapsedTimer get_achievements_status_timer;
    get_achievements_status_timer.start();
	bool result = false;
	
	if (gameid != 0)
	{
		//no cache usage in this cache, we want to have last status from RA site
		//to get Username
		QString Username = QString::fromStdString(RecalboxConf::Instance().AsString("global.retroachievements.username"));
		//to get Hardcore value
		int Hardcore = RecalboxConf::Instance().AsInt("global.retroachievements.hardcore");
		//To get status
		const QString url_str = QStringLiteral("http://retroachievements.org/dorequest.php?r=unlocks&u=%1&t=%2&g=%3&h=%4").arg(Username,token,QString::number(gameid),QString::number(Hardcore));
		QJsonDocument json = get_json_from_url(url_str, log_tag, manager);
		result = apply_achievements_status_json(game,Hardcore, log_tag, json);
	}
	
    Log::debug(log_tag, LOGMSG("Stats - Timing: Get achievements status processing: %1ms").arg(get_achievements_status_timer.elapsed()));
	return gameid;
}

	
//***********************END OF GET FUNCTIONS***********************************//

//***********************START OF HASH FUNCTIONS***********************************//
/* hooks for rc_hash library */

static void* rc_hash_handle_file_open(const char* path)
{
   return intfstream_open_file(path,
         RETRO_VFS_FILE_ACCESS_READ, RETRO_VFS_FILE_ACCESS_HINT_NONE);
}

static void rc_hash_handle_file_seek(
      void* file_handle, int64_t offset, int origin)
{
   intfstream_seek((intfstream_t*)file_handle, offset, origin);
}

static int64_t rc_hash_handle_file_tell(void* file_handle)
{
   return intfstream_tell((intfstream_t*)file_handle);
}

static size_t rc_hash_handle_file_read(
      void* file_handle, void* buffer, size_t requested_bytes)
{
   return intfstream_read((intfstream_t*)file_handle,
         buffer, requested_bytes);
}

static void rc_hash_handle_file_close(void* file_handle)
{
   intfstream_close((intfstream_t*)file_handle);
   CHEEVOS_FREE(file_handle);
}

#ifdef HAVE_CHD
static void* rc_hash_handle_chd_open_track(
      const char* path, uint32_t track)
{
   cdfs_track_t* cdfs_track;

   switch (track)
   {
      case RC_HASH_CDTRACK_FIRST_DATA:
         cdfs_track = cdfs_open_data_track(path);
         break;

      case RC_HASH_CDTRACK_LAST:
         cdfs_track = cdfs_open_track(path, CHDSTREAM_TRACK_LAST);
         break;

      case RC_HASH_CDTRACK_LARGEST:
         cdfs_track = cdfs_open_track(path, CHDSTREAM_TRACK_PRIMARY);
         break;

      default:
         cdfs_track = cdfs_open_track(path, track);
         break;
   }

   if (cdfs_track)
   {
      cdfs_file_t* file = (cdfs_file_t*)malloc(sizeof(cdfs_file_t));
      if (cdfs_open_file(file, cdfs_track, NULL))
         return file; /* ASSERT: file owns cdfs_track now */

      CHEEVOS_FREE(file);
      cdfs_close_track(cdfs_track); /* ASSERT: this free()s cdfs_track */
   }

   return NULL;
}

static size_t rc_hash_handle_chd_read_sector(
      void* track_handle, uint32_t sector,
      void* buffer, size_t requested_bytes)
{
   cdfs_file_t* file = (cdfs_file_t*)track_handle;
   uint32_t track_sectors = cdfs_get_num_sectors(file);

   sector -= cdfs_get_first_sector(file);
   if (sector >= track_sectors)
      return 0;

   cdfs_seek_sector(file, sector);
   return cdfs_read_file(file, buffer, requested_bytes);
}

static uint32_t rc_hash_handle_chd_first_track_sector(
   void* track_handle)
{
   cdfs_file_t* file = (cdfs_file_t*)track_handle;
   return cdfs_get_first_sector(file);
}

static void rc_hash_handle_chd_close_track(void* track_handle)
{
   cdfs_file_t* file = (cdfs_file_t*)track_handle;
   if (file)
   {
      cdfs_close_track(file->track);
      cdfs_close_file(file); /* ASSERT: this does not free() file */
      CHEEVOS_FREE(file);
   }
}

#endif

static void rc_hash_handle_error_log_message(const char* message)
{
   Log::error("Cheevos", LOGMSG("%1").arg(QString::fromStdString(message))); 
}

static void rc_hash_handle_debug_log_message(const char* message)
{
   Log::debug("Cheevos", LOGMSG("%1").arg(QString::fromStdString(message))); 
}

static void rc_hash_reset_cdreader_hooks(void);

static void* rc_hash_handle_cd_open_track(
      const char* path, uint32_t track)
{
   struct rc_hash_cdreader cdreader;

   if (string_is_equal_noncase(path_get_extension(path), "chd"))
   {
#ifdef HAVE_CHD
      /* special handlers for CHD file */
      memset(&cdreader, 0, sizeof(cdreader));
      cdreader.open_track = rc_hash_handle_cd_open_track;
      cdreader.read_sector = rc_hash_handle_chd_read_sector;
      cdreader.close_track = rc_hash_handle_chd_close_track;
      cdreader.first_track_sector = rc_hash_handle_chd_first_track_sector;
      rc_hash_init_custom_cdreader(&cdreader);

      return rc_hash_handle_chd_open_track(path, track);
#else
      Log::debug("Cheevos", LOGMSG("Cannot generate hash from CHD without HAVE_CHD compile flag"));
      return NULL;
#endif
   }
   else
   {
      /* not a CHD file, use the default handlers */
      rc_hash_get_default_cdreader(&cdreader);
      rc_hash_reset_cdreader_hooks();
      return cdreader.open_track(path, track);
   }
}

static void rc_hash_reset_cdreader_hooks(void)
{
   struct rc_hash_cdreader cdreader;
   rc_hash_get_default_cdreader(&cdreader);
   cdreader.open_track = rc_hash_handle_cd_open_track;
   rc_hash_init_custom_cdreader(&cdreader);
}

/* end hooks */

QString calculate_hash_from_file(QString rom_file, QString log_tag)
// can calculate hash using maner of RetroAchievements to manage the following system and format of rom supported by RetroAchievements.
{
	QElapsedTimer calculate_hash_timer;
    calculate_hash_timer.start();
	char hash_iterator[33] = "";
	int result_iterator;
	struct rc_hash_iterator iterator;
	struct rc_hash_filereader filereader;

    /* provide hooks for reading files */
    memset(&filereader, 0, sizeof(filereader));
    filereader.open = rc_hash_handle_file_open;
    filereader.seek = rc_hash_handle_file_seek;
    filereader.tell = rc_hash_handle_file_tell;
    filereader.read = rc_hash_handle_file_read;
    filereader.close = rc_hash_handle_file_close;
	rc_hash_init_custom_filereader(&filereader);

    //to uncomment to activate logs
    rc_hash_init_error_message_callback(rc_hash_handle_error_log_message);

    //Take care: verbose mode could be bugguy as for arcade .zip file hash calculation due to snprintf no-secured function used in logs :-(
    //rc_hash_init_verbose_message_callback(rc_hash_handle_debug_log_message);

    rc_hash_reset_cdreader_hooks();
    const char* path = rom_file.toUtf8().data(); //for testing //toLocal8Bit().data(); //.toUtf8().data();
	rc_hash_initialize_iterator(&iterator, path, NULL, 0);
	result_iterator = rc_hash_iterate(hash_iterator, &iterator);
    if (!result_iterator)
    {
       Log::debug(log_tag, LOGMSG("no hashes generated"));
    }
	rc_hash_destroy_iterator(&iterator);
    Log::debug(log_tag, LOGMSG("Stats - Timing: Hash processing: %1ms").arg(calculate_hash_timer.elapsed()));
    Log::debug(log_tag, LOGMSG("Hash on file: '%1' - '%2'").arg(rom_file, QString::fromLocal8Bit(hash_iterator)));
	return QString::fromLocal8Bit(hash_iterator);
}	
//***********************END OF HASH FUNCTIONS***********************************//
} // namespace


namespace providers {
namespace retroAchievements {

HashMap <QString, qint64> Metadata::mRetroAchievementsGames;

Metadata::Metadata(QString log_tag)
    : m_log_tag(std::move(log_tag))
    , m_json_cache_dir(QStringLiteral("retroachievements"))
{
}

void Metadata::build_md5_db(QString hashlibrary_url) const
{
    QElapsedTimer build_md5_db_timer;
    build_md5_db_timer.start();
    int size = 0;

    //Try to get RA hash library from cache
    QJsonDocument json = providers::read_json_from_cache(m_log_tag + " - cache", m_json_cache_dir, "ra_hash_library");

    Metadata::mRetroAchievementsGames = apply_hash_library_json(m_log_tag + " - cache", json);
    if (Metadata::mRetroAchievementsGames.size() < 1)
    {
        //Delete JSON in cache by security
        providers::delete_cached_json(m_log_tag, m_json_cache_dir, "ra_hash_library");

        //Create Network Access
        QNetworkAccessManager *manager = new QNetworkAccessManager();
        //To get JSON from internet
        json = get_json_from_url(hashlibrary_url, m_log_tag, *manager);
        //kill manager to avoid memory leaks
        delete manager;

        Metadata::mRetroAchievementsGames = apply_hash_library_json(m_log_tag + " - cache", json);
        if (Metadata::mRetroAchievementsGames.size() >= 1)
        {
            //saved in cache
            providers::cache_json(m_log_tag, m_json_cache_dir, "ra_hash_library", json.toJson(QJsonDocument::Compact));
        }
    }
    size = Metadata::mRetroAchievementsGames.size();
    Log::debug(m_log_tag, LOGMSG("Stats - Timing: JSON to HashMap processing: %1 ms - games quantity: %2 ").arg(QString::number(build_md5_db_timer.elapsed()), QString::number(size)));
    //for test purposes
    //Metadata::mRetroAchievementsGames.emplace(std::move("12345678"), 1);
    //Metadata::mRetroAchievementsGames.emplace(std::move("12345679"), 2);
}

void Metadata::set_RaHash_And_GameID_from_hashlibrary(model::Game& game, bool ForceUpdate) const
{
    QString token;
    bool result = false;
    //Set Game info
    model::Game* const game_ptr = &game;
    QString title = game_ptr->title();

    //check if recalbox.conf to know if activated
    if (!RecalboxConf::Instance().AsBool("global.retroachievements"))
    {
        Log::debug(m_log_tag, LOGMSG("not activated !"));
        return;
    }
    else if (game_ptr->collections().retroachievements() != true){
        Log::debug(m_log_tag, LOGMSG("not applicable for this system !"));
        //force result for this game to avoid to use it
        game_ptr->setRaHash("FFFFFFFFFF");
        game_ptr->setRaGameID(-1);
        return;
    }

    //check if gameid exists and hash already calculated
    if(((game_ptr->RaGameID() == 0) && (game_ptr->RaHash() == "")) || ForceUpdate)
    {
        Log::debug(m_log_tag, LOGMSG("RetroAchievement RaGameId to find from Hash library!"));
        const model::GameFile* gamefile = game_ptr->filesConst().first(); /// take into account only the first file for the moment.
        const QFileInfo& finfo = gamefile->fileinfo();
        QString romfile = QDir::toNativeSeparators(finfo.absoluteFilePath());
        QString targetfile;
        //check if zip
        if(romfile.toLower().endsWith(".zip"))
        {
            Zip zip(Path(romfile.toLocal8Bit().data()));
            Log::debug(m_log_tag, LOGMSG("This zip has %1 file(s).").arg(zip.Count()));
            if(zip.Count() == 1)
            {
                //it seems a console game because only one file is present
                //unzip file_unzipped
                //example : unzip -o -d /tmp "/recalbox/share/roms/nes/Duck Hunt (World).zip"
                QString UnzipCommand = "unzip";
                QStringList args = QStringList {
                                        QStringLiteral("-o"),
                                        QStringLiteral("-d /tmp"),
                                        "\""+romfile+"\""
                                    };
                int exitcode = system(qPrintable(serialize_command(UnzipCommand, args)));

                //set target file from /tmp
                targetfile = "/tmp/" + QString::fromStdString(zip.FileName(0).ToString());
            }
            else
            {
                //could be a arcade game in this case
                //set target file from as the initial zip due to the fact that hash for arcade use the name of the file
                targetfile = romfile;
            }
        }
        else
        {	//not zipped
            //set target file as the intial romfile
            targetfile = romfile;
        }
        Log::debug(m_log_tag, LOGMSG("The target file to hash is '%1'").arg(targetfile));
        QString hash = calculate_hash_from_file(targetfile, m_log_tag);
        //save hash to avoid to recalculate during the same session/lauching of Pegasus (as a cache ;-)
        game_ptr->setRaHash(hash);
        game_ptr->setRaGameID(get_gameid_from_hashlibrary(hash, m_log_tag, Metadata::mRetroAchievementsGames));
        if(game_ptr->RaGameID() > 0){
            //but finally we need to connect to retroachievements.org to be sure this game is valid and has any retroachievements :-(
            //Create Network Access
            QNetworkAccessManager *manager = new QNetworkAccessManager(game_ptr->parent());
            //GetToken first from cache or network
            token = get_token(m_log_tag, m_json_cache_dir, *manager);
            if (token != "")
            {
                //check details of game :-(
                result = get_game_details_from_gameid(game_ptr->RaGameID(), token, game, m_log_tag, m_json_cache_dir, *manager);
                if(!result){
                    game_ptr->setRaGameID(-1);
                }
            }
            //kill manager to avoid memory leaks
            delete manager;
        }

        //check if tmp file used
        if(targetfile.toLower().startsWith("/tmp/"))
        {
            Log::debug(m_log_tag, LOGMSG("Deletion of target file : %1").arg(targetfile));
            //delete file
            QString DeleteFileCommand = "rm";
            QStringList args = QStringList {"\""+targetfile+"\""};
            int exitcode = system(qPrintable(serialize_command(DeleteFileCommand, args)));
        }
        Log::debug(m_log_tag, LOGMSG("RetroAchievement GameId set is : %1").arg(game_ptr->RaGameID()));
     }
}

void Metadata::fill_Ra_from_network_or_cache(model::Game& game, bool ForceUpdate) const
{
    QString token;
    bool result = false;
    //Set Game info
    model::Game* const game_ptr = &game;
    QString title = game_ptr->title();

    //check if recalbox.conf to know if activated
    if (!RecalboxConf::Instance().AsBool("global.retroachievements"))
    {
        Log::debug(m_log_tag, LOGMSG("not activated !"));
        return;
    }
    else if (game_ptr->collections().retroachievements() != true){
        Log::debug(m_log_tag, LOGMSG("not applicable for this system !"));
        //force result for this game to avoid to use it
        game_ptr->setRaHash("FFFFFFFFFF");
        game_ptr->setRaGameID(-1);
        return;
    }
    //for test to check static hash map of RA Hash/GameId
    /*for (const auto& entry : mRetroAchievementsGames) {
        const QString& hash = entry.first;
        const qint64 gameid = entry.second;
        Log::debug(m_log_tag, LOGMSG("Hash: %1 GameId: %2").arg(hash,QString::number(gameid)));
    }*/

    //Create Network Access
    QNetworkAccessManager *manager = new QNetworkAccessManager(game_ptr->parent());

    //GetToken first from cache or network
    token = get_token(m_log_tag, m_json_cache_dir, *manager);
    if (token != "")
    {
        //check if gameid exists and hash already calculated
        if((game_ptr->RaGameID() == 0) && (game_ptr->RaHash() == ""))
        {
            Log::debug(m_log_tag, LOGMSG("RetroAchievement RaGameId to find from RA site or cache !"));
            const model::GameFile* gamefile = game_ptr->filesConst().first(); /// take into account only the first file for the moment.
            const QFileInfo& finfo = gamefile->fileinfo();
            QString romfile = QDir::toNativeSeparators(finfo.absoluteFilePath());
            QString targetfile;
            //check if zip
            if(romfile.toLower().endsWith(".zip"))
            {
                Zip zip(Path(romfile.toLocal8Bit().data()));
                Log::debug(m_log_tag, LOGMSG("This zip has %1 file(s).").arg(zip.Count()));
                if(zip.Count() == 1)
                {
                    //it seems a console game because only one file is present
                    //unzip file_unzipped
                    //example : unzip -o -d /tmp "/recalbox/share/roms/nes/Duck Hunt (World).zip"
                    QString UnzipCommand = "unzip";
                    QStringList args = QStringList {
                                            QStringLiteral("-o"),
                                            QStringLiteral("-d /tmp"),
                                            "\""+romfile+"\""
                                        };
                    int exitcode = system(qPrintable(serialize_command(UnzipCommand, args)));

                    //set target file from /tmp
                    targetfile = "/tmp/" + QString::fromStdString(zip.FileName(0).ToString());
                }
                else
                {
                    //could be a arcade game in this case
                    //set target file from as the initial zip due to the fact that hash for arcade use the name of the file
                    targetfile = romfile;
                }
            }
            else
            {	//not zipped
                //set target file as the intial romfile
                targetfile = romfile;
            }
            Log::debug(m_log_tag, LOGMSG("The target file to hash is '%1'").arg(targetfile));
            QString hash = calculate_hash_from_file(targetfile, m_log_tag);
            //save hash to avoid to recalculate during the same session/lauching of Pegasus (as a cache ;-)
            game_ptr->setRaHash(hash);
            //check if tmp file used
            if(targetfile.toLower().startsWith("/tmp/"))
            {
                Log::debug(m_log_tag, LOGMSG("Deletion of target file : '%1'").arg(targetfile));
                //delete file
                QString DeleteFileCommand = "rm";
                QStringList args = QStringList {"\""+targetfile+"\""};
                int exitcode = system(qPrintable(serialize_command(DeleteFileCommand, args)));
            }

            game_ptr->setRaGameID(get_gameid_from_hash(hash, m_log_tag, *manager));
            Log::debug(m_log_tag, LOGMSG("RetroAchievement GameId found is : %1").arg(game_ptr->RaGameID()));

            //get details about Game from GameID
            result = get_game_details_from_gameid(game_ptr->RaGameID(), token, game, m_log_tag, m_json_cache_dir, *manager);
            //set status of retroachievements (lock or no locked) -> no cache used in this case, to have always the last one
            result = get_achievements_status_from_gameid(game_ptr->RaGameID(), token, game, m_log_tag, *manager);
        }
        else
        {
            Log::debug(m_log_tag, LOGMSG("RetroAchievement GameId already known : %1").arg(game_ptr->RaGameID()));
            if(game_ptr->retroAchievements().isEmpty() || ForceUpdate)
            {
                //set status of retroachievements (lock or no locked) -> no cache used in this case, to have always the last one
                if (ForceUpdate) {
                    //Delete JSON in cache for cleaning and force update vs init when we reuse cache.
                    providers::delete_cached_json(m_log_tag, m_json_cache_dir, "RaGameID=" + QString::number(game_ptr->RaGameID()));
                }
                //get details about Game from GameID
                result = get_game_details_from_gameid(game_ptr->RaGameID(), token, game, m_log_tag, m_json_cache_dir, *manager);
                if(result){
                    //set status of retroachievements (lock or no locked) -> no cache used in this case, to have always the last one
                    result = get_achievements_status_from_gameid(game_ptr->RaGameID(), token, game, m_log_tag, *manager);
                }
                else{
                    //force result for this game to avoid to use it in the future
                    game_ptr->setRaHash("FFFFFFFFFF");
                    game_ptr->setRaGameID(-1);
                }
            }
        }
    }
    //kill manager to avoid memory leaks
    delete manager;

}

} // namespace retroAchievements
} // namespace providers
