#include "ParametersList.h"
#include "Log.h"
#include "Recalbox.h"
#include "audio/AudioController.h"
#include "storage/StorageDevices.h"

namespace {

/******************************* section to initial variables used by GetParametersList in same name *************************************/
QStringList ListOfInternalValue;

//! Storage devices
StorageDevices mStorageDevices;

QStringList GetParametersList(QString Parameter)
{
    QStringList ListOfValue;
    
    //clean global internal values if needed
    ListOfInternalValue.clear();
    
    if (Parameter == "global.ratio")
    {   
        //## Set ratio for all emulators (auto,4/3,16/9,16/10,custom) - default value: auto / index 0
        //global.ratio=auto
        ListOfValue << "none" << "auto" << "4/3" << "16/9" << "16/10" << "16/15" << "21/9" << "1/1" << "2/1" << "3/2" << "3/4" << "4/1" << "9/16" << "5/4" << "6/5" << "7/9" << "8/3" << "8/7" << "19/12" << "19/14" << "30/17" << "32/9" << "squarepixel" << "config" << "custom" << "coreprovided";
    }
    else if (Parameter == "system.kblayout")
    {   
        //## set the keyboard layout (fr,en,de,us,es)
        //system.kblayout=us
        ListOfValue << "fr" << "en" << "de" << "us" << "es";
    }
    else if (Parameter == "global.shaderset")
    {
        //## Shader set
        //## Automatically select shaders for all systems
        //## (none, retro, scanlines)
        //global.shaderset=none
        ListOfValue << "none" << "retro" << "scanline";
    }
    else if ((Parameter == "netplay.password.client") || (Parameter == "netplay.password.viewer"))
    {
        //global.netplay.nickname= ?
        ListOfValue << "|P/4/C-M/4/N|" << "[SpAcE.iNvAdErS]" << ">sUpEr.MaRi0.bRoSs<" << "{SoNiC.tHe.HeDgEhOg}" << "(Q/B/E/R/T-@;&?@#)" << "~AnOtHeR.wOrLd!~" << "(/T\\E/T\\R/I\\S)" << "$m00n.p4tR0I$" << "*M.E.T.A.L.S.L.U.G*" << "OuTruN-hAn60uT" << "[L*E*M*M*I*N*G*S]" << "@-G|a|U|n|L|e|T-@" << "%.BuBBLe.B00Ble.%" << "!.CaStLeVaNiA.!" << "=B@mBeR.J4cK=";
    }
    else if (Parameter == "audio.mode")
    {
        //## 2 values for the moment are really manage for pegasus
        //audio.mode = musicandvideosound -> to activate sound for all using the Display value : "video and game"
        //or
        //audio.mode = none -> to deactivate sound
        
        //##RFU / activated only for 
        //MusicsOnly,
        //VideosSoundOnly,
        //MusicsXorVideosSound,
        
        //pegasus sound layer parameters is not as ES.
        ListOfValue << "sound on \uf123" <<  "sound off \uf3a2"; // using ionIcons Font
        //use internal values to match with ES modes
        ListOfInternalValue << "musicandvideosound" <<  "none";
    }
    else if (Parameter == "audio.device")
    {
        //example in conf: 
        //audio.device=alsa_card.pci-0000_00_1f.3:hdmi-output-0
        //audio.volume=90
        //audio.bgmusic=1
        //audio.mode=musicandvideosound

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
               ListOfValue.append("no device detected");
               ListOfInternalValue.append(""); //to empty parameter
           }            
    }
    else if (Parameter == "boot.sharedevice")
    {
        //# The `sharedevice` variable indicates where to find the SHARE folder/partition.
        //# It can have the following values:
        //#   INTERNAL      => the partition immediately following the partition mounted as /boot, on the same disk (e.g. `/dev/mmcblk0p2`)
        //#                    (this is the default)
        //#   RAM           => a temporary in-memory file system (tmpfs)
        //#                    (use at your own risks, specially on boards with low memory!)
        //#   ANYEXTERNAL   => any storage device other than the one the system booted on
        //#                    (use this when you have several USB keys/drives, but plug only one at a time)
        //#   DEV [FSUUID]  => the storage device with the [FSUUID] unique identifier
        //#                    (use this if you plug multiple storage devices together but want a specific one to hold SHARE)
        //#   NETWORK       => a network-mounted filesystem
        //#                    (see complementary `sharenetwork_*` directives below)
        //;sharedevice=INTERNAL

        for(const StorageDevices::Device& device : mStorageDevices.GetStorageDevices())
        {
            Log::info(LOGMSG("Storage Device Name: %1").arg(QString::fromStdString(device.DisplayName)));
            ListOfValue.append(QString::fromStdString(device.DisplayName));
            Log::info(LOGMSG("Storage Device ID: %1").arg(QString::fromStdString(device.UUID)));
            ListOfInternalValue.append(QString::fromStdString(device.UUID));
        }
    }
    else
    {
        ListOfValue << QString("error: Parameters list for '%1' not found").arg(Parameter);
        //not a parameter using list !
        Log::warning(LOGMSG("'%1' parameter is not a parameters list").arg(Parameter));
    }
    Log::debug(LOGMSG("The list of value for '%1' is '%2'.").arg(Parameter,ListOfValue.join(",")));
    return ListOfValue;
}

std::vector<model::ParameterEntry> find_available_parameterslist(const QString& Parameter)
{
    //Log::debug(LOGMSG("Call of std::vector<model::ParameterEntry> find_available_parameterslist(const QString& Parameter)"));
    
    const QStringList ListOfValue = GetParametersList(Parameter);

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
    //Log::debug(LOGMSG("void ParametersList::select_preferred_parameter(const QString& Parameter) Parameter:`%1`").arg(Parameter));
    //to get first row as default value
    QString DefaultValue;
    if (ListOfInternalValue.size() == 0) DefaultValue = m_parameterslist.at(0).name;
    else DefaultValue = ListOfInternalValue.at(0);
    
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
        select_parameter(QString::fromStdString(RecalboxConf::Instance().AsString(Parameter.toUtf8().constData(),DefaultValue.toUtf8().constData())));  
    }
}

bool ParametersList::select_parameter(const QString& name)
{
    //Log::debug(LOGMSG("ParametersList::select_parameter(const QString& name) name:`%1`").arg(name));
    if (name.isEmpty())
        return false;

    for (size_t idx = 0; idx < m_parameterslist.size(); idx++) {
        //Log::debug(LOGMSG("idx:`%1`").arg(idx));
        //Log::debug(LOGMSG("at(idx).name:`%1`").arg(m_parameterslist.at(idx).name));
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
    //Log::debug(LOGMSG("ParametersList::select_parameter(const QString& name) / return false"));
    return false;
}

void ParametersList::save_selected_parameter()
{
    //Log::debug(LOGMSG("ParametersList::save_selected_parameter()"));
    const auto& value = m_parameterslist.at(m_current_idx);
    //Log::debug(LOGMSG("ParametersList::save_selected_parameter() - parameter: `%1`").arg(value.name));

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


QString ParametersList::currentName(const QString& Parameter) { 
        
        //Log::debug(LOGMSG("QString ParametersList::currentName(const QString& Parameter) - parameter: `%1`").arg(Parameter));
        
        if (m_parameter != Parameter)
        {
            //to signal refresh of model's data
            emit QAbstractItemModel::beginResetModel();
            m_parameter = Parameter;
            m_parameterslist = find_available_parameterslist(Parameter);
            select_preferred_parameter(Parameter);
            //to signal end of model's data
            emit QAbstractItemModel::endResetModel();
        }
        return m_parameterslist.at(m_current_idx).name; 
}

} // namespace model
