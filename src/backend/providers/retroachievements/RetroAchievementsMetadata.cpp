// Pegasus Frontend
//
// Created by BozoTheGeek 07/06/2021
//

#include "RetroAchievementsMetadata.h"

#include "Log.h"
#include "model/gaming/Assets.h"
#include "model/gaming/Collection.h"
#include "model/gaming/Game.h"
#include "providers/JsonCacheUtils.h"
#include "providers/SearchContext.h"
#include "utils/CommandTokenizer.h"
//#include "utils/MoveOnly.h"

#include <QJsonArray>
#include <QJsonDocument>
#include <QJsonObject>
#include <QNetworkReply>
#include <QStringBuilder>
//#include <array>


namespace {
QString apply_login_json(model::Game& game, const QJsonDocument& json)
//Example of JSON content
// {"Success":true,"User":"username","Token":"lePOt1iA5jr56cZj","Score":25,"Messages":0}
//from : http://retroachievements.org/dorequest.php?r=login&u=username&p=password
{
    using QL1 = QLatin1String;

    if (json.isNull())
	{
		Log::debug("json.isNull()");
        return "";
	}
    const auto json_root = json.object();
    if (json_root.isEmpty())
	{
		Log::debug("json_root.isEmpty()"); 
		return "";
	}
    // const auto app_entry = json_root.begin().value().toObject();
    // if (app_entry.isEmpty())
        // return false;

    const bool login_success = json_root[QL1("Success")].toBool();
    if (!login_success)
	{
		Log::debug("!login_success"); 
		return "";
	}
	const QString user_data = json_root[QL1("User")].toString();
    if (user_data.isEmpty())
	{
		Log::debug("user_data.isEmpty()"); 
		return "";
	}
	else Log::debug("Login retroachievements", LOGMSG("User: %1").arg(user_data));
	
	QString token_data = json_root[QL1("Token")].toString();
    if (token_data.isEmpty())
        return "";
	else 
	{
		Log::debug("Login retroachievements", LOGMSG("Token: %1").arg(token_data));
	}
	
    return token_data;
}	
	
	
/* bool apply_json(model::Game& game, const QJsonDocument& json)
{
    using QL1 = QLatin1String;


    if (json.isNull())
        return false;

    const auto json_root = json.object();
    if (json_root.isEmpty())
        return false;

    const auto app_entry = json_root.begin().value().toObject();
    if (app_entry.isEmpty())
        return false;

    const bool app_success = app_entry[QL1("success")].toBool();
    if (!app_success)
        return false;

    const auto app_data = app_entry[QL1("data")].toObject();
    if (app_data.isEmpty())
        return false;

    // now the actual field reading

    model::Assets& assets = game.assetsMut(); // FIXME: update signals

    game.setTitle(app_data[QL1("name")].toString())
        .setSummary(app_data[QL1("short_description")].toString())
        .setDescription(app_data[QL1("about_the_game")].toString());

    const auto reldate_obj = app_data[QL1("release_date")].toObject();
    if (!reldate_obj.isEmpty()) {
        const QString date_str = reldate_obj[QL1("date")].toString();

        // FIXME: the date format will likely fail for non-English locales (see Qt docs)
        const QDateTime datetime(QDateTime::fromString(date_str, QL1("d MMM, yyyy")));
        if (datetime.isValid())
            game.setReleaseDate(datetime.date());
    }

    const QString header_image = app_data[QL1("header_image")].toString();
    assets
        .add_uri(AssetType::LOGO, header_image)
        .add_uri(AssetType::UI_STEAMGRID, header_image)
        .add_uri(AssetType::BOX_FRONT, header_image);

    const QJsonArray developer_arr = app_data[QL1("developers")].toArray();
    for (const auto& arr_entry : developer_arr)
        game.developerList().append(arr_entry.toString());

    const QJsonArray publisher_arr = app_data[QL1("publishers")].toArray();
    for (const auto& arr_entry : publisher_arr)
        game.publisherList().append(arr_entry.toString());

    const auto metacritic_obj = app_data[QL1("metacritic")].toObject();
    if (!metacritic_obj.isEmpty()) {
        const double score = metacritic_obj[QL1("score")].toDouble(-1);
        if (0.0 <= score && score <= 100.0)
            game.setRating(static_cast<float>(score / 100.0));
    }

    const auto genre_arr = app_data[QL1("genres")].toArray();
    for (const auto& arr_entry : genre_arr) {
        const auto genre_obj = arr_entry.toObject();
        if (genre_obj.isEmpty())
            break; // assume the rest will fail too

        const QString genre = genre_obj[QL1("description")].toString();
        if (!genre.isEmpty())
            game.genreList().append(genre);
    }

    const auto category_arr = app_data[QL1("categories")].toArray();
    for (const auto& arr_entry : category_arr) {
        const auto cat_obj = arr_entry.toObject();
        if (cat_obj.isEmpty())
            break; // assume the rest will fail too

        const QString category = cat_obj[QL1("description")].toString();
        if (!category.isEmpty())
            game.tagList().append(category);
    }

    const QString background_image = app_data[QL1("background")].toString();
    if (!background_image.isEmpty())
        assets.add_uri(AssetType::BACKGROUND, background_image);

    const auto screenshots_arr = app_data[QL1("screenshots")].toArray();
    for (const auto& arr_entry : screenshots_arr) {
        const auto screenshot_obj = arr_entry.toObject();
        if (screenshot_obj.isEmpty())
            break; // assume the rest will fail too

        const QString thumb_path = screenshot_obj[QL1("path_thumbnail")].toString();
        if (!thumb_path.isEmpty())
            assets.add_uri(AssetType::SCREENSHOT, thumb_path);
    }

    const auto movies_arr = app_data[QL1("movies")].toArray();
    for (const auto& arr_entry : movies_arr) {
        const auto movie_obj = arr_entry.toObject();
        if (movie_obj.isEmpty())
            break;

        const auto webm_obj = movie_obj[QL1("webm")].toObject();
        if (webm_obj.isEmpty())
            break;

        const QString p480_path = webm_obj[QL1("480")].toString();
        if (!p480_path.isEmpty())
            assets.add_uri(AssetType::VIDEO, p480_path);
    }

    return true;
} */
} // namespace


namespace providers {
namespace retroAchievements {

Metadata::Metadata(QString log_tag)
    : m_log_tag(std::move(log_tag))
    , m_json_cache_dir(QStringLiteral("retroachievements"))
{
	Log::debug(log_tag, LOGMSG("Creation of RetroAchievementsMetaData"));
}

bool Metadata::fill_from_cache(model::Game& game) const
{
	model::Game* const game_ptr = &game;
    const auto json = providers::read_json_from_cache(m_log_tag, m_json_cache_dir, game_ptr->title());
    QString m_token = apply_login_json(*game_ptr, json);
	bool json_success;
	if (m_token == "")
	{
		//const bool json_success = apply_login_json(game, json);
		//if (!json_success)
		json_success = false;
        providers::delete_cached_json(m_log_tag, m_json_cache_dir, game_ptr->title());
	}
	else 
	{
		json_success = true;
	}
	
    return json_success;
}

void Metadata::fill_from_network(model::Game& game, SearchContext& sctx) const
{
	QString log_tag = m_log_tag;
    Log::debug(log_tag, LOGMSG("Metadata::fill_from_network(model::Game& game, SearchContext& sctx)"));

	
	//GET information from recalbox.conf
	//TO DO
	
	//create url to get token
	const QString url_str = QStringLiteral("http://retroachievements.org/dorequest.php?r=login&u=%1&p=%2").arg("bozothegeek","schwarzy");
    
	//
	
	//const QString embed_url_str = QStringLiteral("https://embed.ra.com/games/ajax/filtered?mediaType=game&search=%1").arg(raid);
    
	
	const QUrl url(url_str, QUrl::StrictMode);
	
    //const QUrl embed_url(embed_url_str, QUrl::StrictMode);
    
	
	Q_ASSERT(url.isValid());
    
	//Q_ASSERT(embed_url.isValid());
    
	if (Q_UNLIKELY(!url.isValid())) // || !embed_url.isValid()))
	{
		Log::debug(log_tag, LOGMSG("Q_UNLIKELY(!url.isValid())"));
		return;
	}

    model::Game* const game_ptr = &game;
    QString json_cache_dir = m_json_cache_dir;
	QString title = game_ptr->title();
	Log::debug(log_tag, LOGMSG("0 - sctx.schedule_download(url, [log_tag, json_cache_dir, game_ptr, title](QNetworkReply* const reply)"));
    
	//TEST
	QNetworkAccessManager *manager = new QNetworkAccessManager(game_ptr->parent());
	// connect(manager, &QNetworkAccessManager::finished,
        // this, &MyClass::replyFinished);

	// manager->get(QNetworkRequest(QUrl(url)));

	QNetworkRequest request(url);
    request.setAttribute(QNetworkRequest::FollowRedirectsAttribute, true);
	#if (QT_VERSION >= QT_VERSION_CHECK(5, 15, 0))
		request.setTransferTimeout(10000);
	#endif

    QNetworkReply* const reply = manager->get(request);
	Log::debug(LOGMSG("emit downloadScheduled();"));
    //emit downloadScheduled();

	QObject::connect(reply, &QNetworkReply::finished, [=]() {
		if(reply->error() == QNetworkReply::NoError)
		{
			QByteArray response = reply->readAll();
			// do something with the data...
			Log::debug(LOGMSG("response = %1").arg(QString::fromStdString(response.toStdString())));
		}
		else // handle error
		{
	      Log::debug(LOGMSG("ERROR"));
		}
	});	
		
	// sctx.schedule_download(url, [title, game_ptr, log_tag, json_cache_dir](QNetworkReply* const reply){
        // if (reply->error()) {
            // Log::warning(log_tag, LOGMSG("Downloading metadata for `%1` failed: %2")
                // .arg(title, reply->errorString()));
            // return;
        // }
		// Log::debug(log_tag, LOGMSG("1 - sctx.schedule_download(url, [log_tag, json_cache_dir, game_ptr, title](QNetworkReply* const reply)"));
        // const QByteArray raw_data = reply->readAll();
        // const QJsonDocument json = QJsonDocument::fromJson(raw_data);
        // if (json.isNull()) {
            // Log::warning(log_tag, LOGMSG(
                   // "Failed to parse the response of the server for game '%1', "
                   // "either it's no longer available from the Steam Store or the Steam API has changed"
               // ).arg(title));
            // return;
        // }

		// QString m_token = apply_login_json(*game_ptr, json);
        // if (m_token != "")
		// {
            // providers::cache_json(log_tag, json_cache_dir, title, json.toJson(QJsonDocument::Compact));
		// }
    // });
}

} // namespace retroAchievements
} // namespace providers
