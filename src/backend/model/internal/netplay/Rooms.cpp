// Pegasus Frontend
//
// Created by Bozo The Geek - 27/10/2021
//
#include "Rooms.h"
#include "Log.h"

#include <RecalboxConf.h>

//for network
#include <QNetworkAccessManager>
#include <QNetworkReply>
#include <QNetworkRequest>
#include <QSslSocket>

//for json parsing
#include <QJsonArray>
#include <QJsonDocument>
#include <QJsonObject>
#include <QEventLoop>
#include <QElapsedTimer>

namespace {
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
    //Log::debug(log_tag, LOGMSG("Raw data: %1").arg(QString(raw_data)));

    QJsonDocument json = QJsonDocument::fromJson(raw_data);
    if (json.isNull()) {
        Log::warning(log_tag, LOGMSG(
               "Failed to parse the response of the server, "
               "either it's no longer available from https://retroachievements.org/ or the API has changed"));
        return QJsonDocument();
    }
    return json;
}
} // namespace

namespace model {

RoomEntry::RoomEntry(int Id,
      QString Username,
      QString Country,
      QString Game_name,
      QString Game_crc,
      QString Core_name,
      QString Core_version,
      QString Subsystem_name,
      QString Retroarch_version,
      QString Frontend,
      QString Ip,
      int Port,
      QString Mitm_ip,
      int Mitm_port,
      int Host_method,
      bool Has_password,
      bool Has_spectate_password,
      QString Created,
      QString Updated)
    : id(std::move(Id))
	, username(std::move(Username))
	, country(std::move(Country))
    , game_name(std::move(Game_name))
    , game_crc(std::move(Game_crc))
    , core_name(std::move(Core_name))
    , core_version(std::move(Core_version))
    , subsystem_name(std::move(Subsystem_name))
    , retroarch_version(std::move(Retroarch_version))
    , frontend(std::move(Frontend))
    , ip(std::move(Ip))
    , port(std::move(Port))
    , mitm_ip(std::move(Mitm_ip))
    , mitm_port(std::move(Mitm_port))
    , host_method(std::move(Host_method))
    , has_password(std::move(Has_password))
    , has_spectate_password(std::move(Has_spectate_password))
    , created(std::move(Created))
    , updated(std::move(Updated))


{
}

Rooms::Rooms(QObject* parent)
    : QAbstractListModel(parent)
    , m_role_names({
        { Roles::Id, QByteArrayLiteral("id") },
        { Roles::Username, QByteArrayLiteral("username") },
        { Roles::Country, QByteArrayLiteral("country") },
        { Roles::Game_name, QByteArrayLiteral("game_name") },
        { Roles::Game_crc, QByteArrayLiteral("game_crc") },
        { Roles::Core_name, QByteArrayLiteral("core_name") },
        { Roles::Core_version, QByteArrayLiteral("core_version") },
        { Roles::Subsystem_name, QByteArrayLiteral("subsystem_name") },
        { Roles::Retroarch_version, QByteArrayLiteral("retroarch_version") },
        { Roles::Frontend, QByteArrayLiteral("frontend") },
        { Roles::Ip, QByteArrayLiteral("ip") },
        { Roles::Port, QByteArrayLiteral("port") },
        { Roles::Mitm_ip, QByteArrayLiteral("mitm_ip") },
        { Roles::Mitm_port, QByteArrayLiteral("mitm_port") },
        { Roles::Host_method, QByteArrayLiteral("host_method") },
        { Roles::Has_password, QByteArrayLiteral("has_password") },
        { Roles::Has_spectate_password, QByteArrayLiteral("has_spectate_password") },
        { Roles::Created, QByteArrayLiteral("created") },
        { Roles::Updated, QByteArrayLiteral("updated") },
})
{
}

int Rooms::rowCount(const QModelIndex& parent) const
{
    if (parent.isValid())
        return 0;

    return static_cast<int>(m_Rooms.size());
}

QVariant Rooms::data(const QModelIndex& index, int role) const
{
    if (!index.isValid() || rowCount() <= index.row())
        return {};

    const auto& room = m_Rooms.at(static_cast<size_t>(index.row()));
    switch (role) {
    case Roles::Id:
        return room.id;
	case Roles::Username:
		return room.username;
	case Roles::Country:
		return room.country;
	case Roles::Game_name:
		return room.game_name;
	case Roles::Game_crc:
		return room.game_crc;
	case Roles::Core_name:
		return room.core_name;
	case Roles::Core_version:
		return room.core_version;
    case Roles::Subsystem_name:
        return room.subsystem_name;
	case Roles::Retroarch_version:
		return room.retroarch_version;
	case Roles::Frontend:
    	return room.frontend;
    case Roles::Ip:
        return room.ip;
    case Roles::Port:
        return room.port;
    case Roles::Mitm_ip:
        return room.mitm_ip;
    case Roles::Mitm_port:
        return room.mitm_port;
    case Roles::Host_method:
        return room.host_method;
    case Roles::Has_password:
        return room.has_password;
    case Roles::Has_spectate_password:
        return room.has_spectate_password;
    case Roles::Created:
        return room.created;
    case Roles::Updated:
        return room.updated;
	default:
        return {};
    }
}

 void Rooms::setCurrentIndex(int idx_int)
{
    //Log::warning(LOGMSG("Rooms::setCurrentIndex(int idx_int) : m_current_idx = %1").arg(m_current_idx));
    const auto idx = static_cast<size_t>(idx_int);

    // verify
    if (idx == m_current_idx)
        return;

    if (m_Rooms.size() <= idx) {
        Log::warning(LOGMSG("Invalid room index #%1").arg(idx));
        return;
    }
    // save
    m_current_idx = idx;
    Log::debug(LOGMSG("emit roomsChanged();"));
    emit roomsChanged();
}

void Rooms::refresh()
{
     //Log::debug(LOGMSG("Rooms::refresh_slot() put in Qt::QueuedConnection"));
     QMetaObject::invokeMethod(this,"refresh_slot", Qt::QueuedConnection);
}

void Rooms::refresh_slot() {

    //Log::debug(LOGMSG("void Rooms::refresh_slot()"));
    QString log_tag = "Netplay";
    try{
        //check of netplay activated
        //check in recalbox.conf to know if activated
        if (!RecalboxConf::Instance().AsBool("global.netplay.active"))
        {
            Log::debug(log_tag, LOGMSG("not activated !"));
            return;
        }
        //Create Network Access
        QNetworkAccessManager *manager = new QNetworkAccessManager(this);
        //get lobby json from internet
        const QString url_str = QStringLiteral("http://lobby.libretro.com/list/");
        QJsonDocument json;
        json = get_json_from_url(url_str, log_tag, *manager);
        //parse lobby data
        bool result = false;
        result = find_available_rooms(log_tag, json, m_Rooms);

    }
    catch ( const std::exception & Exp )
    {
        Log::error(log_tag, LOGMSG("Error: %1.\n").arg(Exp.what()));
    }
}

bool Rooms::find_available_rooms(QString log_tag, const QJsonDocument& json, std::vector<model::RoomEntry>& roomsEntry)
{
    std::vector<model::RoomEntry> Roomslist;

    //Log::debug(LOGMSG("find_available_rooms() : %1").arg(QString(json.toJson(QJsonDocument::Compact))));

    using QL1 = QLatin1String;

    if (json.isNull())
    {
        Log::debug(log_tag, LOGMSG("json.isNull()"));
        return false;
    }
    const auto json_root = json.array();
    if (json_root.isEmpty())
    {
        Log::debug(log_tag, LOGMSG("json_root.isEmpty()"));
        return false;
    }
    else Log::debug(log_tag, LOGMSG("nb fields/rooms found: %1").arg(json_root.count()));

    //if(roomsEntry.size() != 0) emit Rooms::beginResetModel();

    //roomsEntry.clear();
    int i = 1;
    for (const auto& array_entry : json_root) {
            const auto fields = array_entry[QL1("fields")].toObject();
            const auto Id = fields[QL1("id")].toInt();
            const auto Username = fields[QL1("username")].toString();
            const auto Country = fields[QL1("country")].toString();
            const auto Game_name = fields[QL1("game_name")].toString();
            const auto Game_crc = fields[QL1("game_crc")].toString();
            const auto Core_name = fields[QL1("core_name")].toString();
            const auto Core_version = fields[QL1("core_version")].toString();
            const auto Subsystem_name = fields[QL1("subsystem_name")].toString();
            const auto Retroarch_version = fields[QL1("retroarch_version")].toString();
            const auto Frontend = fields[QL1("frontend")].toString();
            const auto Ip = fields[QL1("ip")].toString();
            const auto Port = fields[QL1("port")].toInt();
            const auto Mitm_ip = fields[QL1("mitm_ip")].toString();
            const auto Mitm_port = fields[QL1("mitm_port")].toInt();
            const auto Host_method = fields[QL1("host_method")].toInt();
            const auto Has_password = fields[QL1("has_password")].toBool();
            const auto Has_spectate_password = fields[QL1("has_spectate_password")].toBool();
            const auto Created = fields[QL1("created")].toString();
            const auto Updated = fields[QL1("updated")].toString();

            //Log::debug(log_tag, LOGMSG("Username=%1").arg(Username));

            if(i > int(roomsEntry.size())){
                Rooms::beginInsertRows(QModelIndex(), i-1, i-1);
                roomsEntry.emplace_back(Id,Username,Country,Game_name,Game_crc,Core_name,Core_version,Subsystem_name,Retroarch_version,
                  Frontend,Ip,Port,Mitm_ip,Mitm_port,Host_method,Has_password,Has_spectate_password,Created,Updated);
                Log::debug(log_tag, LOGMSG("Add game : %1").arg(Game_name));
                Rooms::endInsertRows();
            }
            else
            {
                roomsEntry.at(i-1).id = Id;
                roomsEntry.at(i-1).username = Username;
                roomsEntry.at(i-1).country = Country;
                roomsEntry.at(i-1).game_name = Game_name;
                roomsEntry.at(i-1).game_crc = Game_crc;
                roomsEntry.at(i-1).core_name = Core_name;
                roomsEntry.at(i-1).core_version = Core_version;
                roomsEntry.at(i-1).subsystem_name = Subsystem_name;
                roomsEntry.at(i-1).retroarch_version = Retroarch_version;
                roomsEntry.at(i-1).frontend = Frontend;
                roomsEntry.at(i-1).ip = Ip;
                roomsEntry.at(i-1).port = Port;
                roomsEntry.at(i-1).mitm_ip = Mitm_ip;
                roomsEntry.at(i-1).mitm_port = Mitm_port;
                roomsEntry.at(i-1).host_method = Host_method;
                roomsEntry.at(i-1).has_password = Has_password;
                roomsEntry.at(i-1).has_spectate_password = Has_spectate_password;
                roomsEntry.at(i-1).created = Created;
                roomsEntry.at(i-1).updated = Updated;
                Log::debug(log_tag, LOGMSG("Game changed : %1").arg(Game_name));
                emit Rooms::dataChanged(index(i-1), index(i-1));
            }
            i = i + 1;
    }
    //check if we have to remove line
    for(int j = 1; j <= (int(roomsEntry.size()) - (i-1)); j++){
        Rooms::beginRemoveRows(QModelIndex(), roomsEntry.size()-1, roomsEntry.size()-1);
        Log::debug(log_tag, LOGMSG("Remove game : %1").arg(roomsEntry.at(roomsEntry.size()-1).game_name));
        roomsEntry.pop_back();
        Rooms::endRemoveRows();
    }
    //emit QAbstractListModel::endResetModel();

    return true;
}



} // namespace model
