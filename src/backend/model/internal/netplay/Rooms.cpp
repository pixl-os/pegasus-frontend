// Pegasus Frontend
//
// Created by Bozo The Geek - 27/10/2021
//
#include "Rooms.h"
#include "Log.h"

namespace {

std::vector<model::RoomEntry> find_available_rooms()
{
    std::vector<model::RoomEntry> Roomslist;

    Log::debug(LOGMSG("find_available_rooms()"));
    //For test purpose
	Roomslist.emplace_back(474269,"Anonymous","us","Aero Fighters ","9F8D3323","Snes9x","1.60 7235219","N/A","1.9.11",
      "unix ARMv8","24.156.110.18",55436,"",0,0,true,false,"2021-10-27T15:44:24.253326Z","2021-10-27T15:44:34.344168Z");
	Roomslist.emplace_back(474270,"Anonymous2","us","Aero Fighters ","9F8D3323","Snes9x","1.60 7235219","N/A","1.9.11",
      "unix ARMv8","24.156.110.18",55436,"",0,0,true,false,"2021-10-27T15:44:24.253326Z","2021-10-27T15:44:34.344168Z");
	Roomslist.emplace_back(474271,"Anonymous3","us","Aero Fighters ","9F8D3323","Snes9x","1.60 7235219","N/A","1.9.11",
      "unix ARMv8","24.156.110.18",55436,"",0,0,true,false,"2021-10-27T15:44:24.253326Z","2021-10-27T15:44:34.344168Z");
  
    return Roomslist;
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
    , has_password(std::move(Has_password))
    , has_spectate_password(std::move(Has_spectate_password))
    , created(std::move(Created))
    , updated(std::move(Updated))


{

    Log::warning(LOGMSG("RoomEntry::RoomEntry"));


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
   Log::warning(LOGMSG("Rooms::Rooms(QObject* parent)"));
   //updateRooms();//empty constructor to be generic
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
    Log::debug(LOGMSG("emit roomChanged();"));
    emit roomChanged();
}


void Rooms::updateRooms() { 

    Log::debug(LOGMSG("void Rooms::updateRooms()"));

	//check if network
	
	//get lobby json filebuf
	
	//check content is valid
	
	//update list from existing list if not empty
	
   //to signal refresh of model's data
   emit QAbstractItemModel::beginResetModel();

        m_Rooms = find_available_rooms();
        
   //to signal end of model's data
   emit QAbstractItemModel::endResetModel();

}

} // namespace model
