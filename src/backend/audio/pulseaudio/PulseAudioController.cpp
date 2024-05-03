//
// Created by bkg2k on 19/12/2020.
//
// From recalbox ES and Integrated by BozoTheGeek 12/04/2021 in Pegasus Front-end
//

#include "PulseAudioController.h"
#include <pulse/pulseaudio.h>
#include <utils/rLog.h>
#include <utils/locale/LocaleHelper.h>
#include <utils/math/Misc.h>
#include <RecalboxConf.h>
#include <hardware/Board.h>

PulseAudioController::PulseAudioController()
  : mConnectionState(ConnectionState::NotConnected)
  , mPulseAudioContext(nullptr)
  , mPulseAudioMainLoop(nullptr)
{
  Thread::Start("PulseAudio");
  Initialize();
}

PulseAudioController::~PulseAudioController()
{
  Finalize();
  Thread::Stop();
}

void PulseAudioController::Initialize()
{
  // Connect to pulseaudio server
  PulseContextConnect();
  // Enumerate all output devices
  PulseEnumerateCards();

  // Subscribe to changes
  //PulseSubscribe();
  { LOG(LogDebug) << "[PulseAudio] Initialized."; }
}

void PulseAudioController::Finalize()
{
  PulseContextDisconnect();
}

void PulseAudioController::SetProfileCallback(pa_context *context, int success, void *userdata)
{
  (void)context;
  (void)success;

  { LOG(LogDebug) << "[PulseAudio] Set Profile result: " << (success != 0 ? "SUCCESS" : "FAIL"); }

  // Get class
  PulseAudioController& This = *(PulseAudioController*)userdata;

  // Result - don't care about the actual result
  This.mSignal.Fire();
}

void PulseAudioController::SetVolumeCallback(pa_context *context, int success, void *userdata)
{
  (void)context;
  (void)success;

  { LOG(LogDebug) << "[PulseAudio] Set Volume result: " << (success != 0 ? "SUCCESS" : "FAIL"); }

  // Get class
  PulseAudioController& This = *(PulseAudioController*)userdata;

  // Result - don't care about the actual result
  This.mSignal.Fire();
}

void PulseAudioController::SetMuteCallback(pa_context *context, int success, void *userdata)
{
  (void)context;
  (void)success;

  { LOG(LogDebug) << "[PulseAudio] Set Mute result: " << (success != 0 ? "SUCCESS" : "FAIL"); }

  // Get class
  PulseAudioController& This = *(PulseAudioController*)userdata;

  // Result - don't care about the actual result
  This.mSignal.Fire();
}

void PulseAudioController::SetSinkCallback(pa_context *context, int success, void *userdata)
{
  (void)context;
  (void)success;

  { LOG(LogDebug) << "[PulseAudio] Set Sink result: " << (success != 0 ? "SUCCESS" : "FAIL"); }

  // Get class
  PulseAudioController& This = *(PulseAudioController*)userdata;

  // Result - don't care about the actual result
  This.mSignal.Fire();
}

void PulseAudioController::SetPortCallback(pa_context *context, int success, void *userdata)
{
  (void)context;
  (void)success;

  { LOG(LogDebug) << "[PulseAudio] Set Port result: " << (success != 0 ? "SUCCESS" : "FAIL"); }

  // Get class
  PulseAudioController& This = *(PulseAudioController*)userdata;

  // Result - don't care about the actual result
  This.mSignal.Fire();
}

void PulseAudioController::ContextStateCallback(pa_context *context, void *userdata)
{
  // Get class
  PulseAudioController& This = *(PulseAudioController*)userdata;

  // Get state
  pa_context_state_t state = pa_context_get_state(context);
	switch(state)
	{
		case PA_CONTEXT_FAILED:
		case PA_CONTEXT_TERMINATED:
    {
      This.mConnectionState = ConnectionState::Closed;
      This.mSignal.Fire();
      break;
    }
		case PA_CONTEXT_READY:
    {
      This.mConnectionState =ConnectionState::Ready;
      This.mSignal.Fire();
      break;
    }
    case PA_CONTEXT_UNCONNECTED:
    case PA_CONTEXT_CONNECTING:
    case PA_CONTEXT_AUTHORIZING:
    case PA_CONTEXT_SETTING_NAME:
    default: break;
	}
}

void PulseAudioController::SubsciptionCallback(pa_context *context, pa_subscription_event_type_t type, uint32_t index, void *userdata)
{
  (void)context;
  // Get class
  PulseAudioController& This = *(PulseAudioController*)userdata;
  (void)This;

  unsigned int facility = type & PA_SUBSCRIPTION_EVENT_FACILITY_MASK;
  unsigned int typ = (pa_subscription_event_type_t)(type & PA_SUBSCRIPTION_EVENT_TYPE_MASK);

  std::string typeStr;
  switch(typ)
  {
    case PA_SUBSCRIPTION_EVENT_NEW: typeStr = "NEW"; break;
    case PA_SUBSCRIPTION_EVENT_CHANGE: typeStr = "CHANGE"; break;
    case PA_SUBSCRIPTION_EVENT_REMOVE: typeStr = "REMOVE"; break;
    default: typeStr = "UNKNOWN TYPE"; break;
  }
  std::string eventStr;
  switch(facility)
  {
    case PA_SUBSCRIPTION_EVENT_SINK: eventStr = "SINK"; break;
    case PA_SUBSCRIPTION_EVENT_SOURCE: eventStr = "SOURCE"; break;
    case PA_SUBSCRIPTION_EVENT_SINK_INPUT: eventStr = "SINK_INPUT"; break;
    case PA_SUBSCRIPTION_EVENT_SOURCE_OUTPUT: eventStr = "SOURCE_OUTPUT"; break;
    case PA_SUBSCRIPTION_EVENT_MODULE: eventStr = "MODULE"; break;
    case PA_SUBSCRIPTION_EVENT_CLIENT: eventStr = "CLIENT"; break;
    case PA_SUBSCRIPTION_EVENT_SAMPLE_CACHE: eventStr = "SAMPLE CACHE"; break;
    case PA_SUBSCRIPTION_EVENT_SERVER: eventStr = "SERVER"; break;
    case PA_SUBSCRIPTION_EVENT_AUTOLOAD: eventStr = "AUTOLOAD"; break;
    case PA_SUBSCRIPTION_EVENT_CARD: eventStr = "CARD"; break;
    default: eventStr = "UNKNOWN EVENT"; break;
  }

  { LOG(LogError) << "[PulseAudio] EVENT! Type: " << typeStr << " - Event: " << eventStr << " - Index: " << index; }
}

AudioIcon PulseAudioController::GetPortIcon(const pa_card_port_info& info)
{
  const char* icon = pa_proplist_gets(info.proplist, "device.icon_name");
  if (icon == nullptr) return AudioIcon::Unidentified;

  if (strcmp(icon, "audio-speakers") == 0) return AudioIcon::Speakers;
  if (strcmp(icon, "audio-headphones") == 0) return AudioIcon::Headphones;
  if (strcmp(icon, "video-display") == 0) return AudioIcon::Screens;

  return AudioIcon::Unidentified;
}

void PulseAudioController::EnumerateCardCallback(pa_context* context, const pa_card_info* info, int eol, void* userdata)
{
  (void)context;
  // Get class
  PulseAudioController& This = *(PulseAudioController*)userdata;

  // If eol is set to a positive number, you're at the end of the list
  if (eol > 0)
  {
    This.mSignal.Fire();
    return;
  }

  // New card
  Card newCard;
  newCard.Name = info->name;
  newCard.Description = GetCardDescription(*info);
  newCard.Index = info->index;
  newCard.HasActioveProfile = false;

  { LOG(LogDebug) << "[PulseAudio] Card #" << newCard.Index << " : " << newCard.Name; }

  // Active profile
  std::string activeProfileName;
  if (info->active_profile2 != nullptr)
  {
    activeProfileName = info->active_profile2->name;
    { LOG(LogDebug) << "[PulseAudio] Active Profile: " << info->active_profile2->description << " ("
                    << info->active_profile2->name << ") - Available "
                    << (info->active_profile2->available != 0 ? "YES" : "NO") << " - Priority "
                    << info->active_profile2->priority; }
  }

  // Ports (device outputs)
  for(int i = info->n_ports; --i >= 0; )
  {
    pa_card_port_info& portInfo = *info->ports[i];
    if ((portInfo.direction & PA_DIRECTION_OUTPUT) == 0) continue; // Ignore non-output ports

    Port newPort;
    newPort.Name = portInfo.name;
    newPort.Icon = GetPortIcon(portInfo);
    newPort.Description = GetPortDescription(portInfo, newPort.Icon);
    newPort.Available = portInfo.available != PA_PORT_AVAILABLE_NO;
    newPort.Priority = portInfo.priority;
    newPort.InternalIndex = (int)newCard.Ports.size();

    { LOG(LogDebug) << "[PulseAudio]   Port " << newPort.Description << " (" << newPort.Name << ") - Available " << (newPort.Available ? "YES" : "NO") << " - Priority " << newPort.Priority; }

    // Port's supported profiles
    for(int p = portInfo.n_profiles; --p >= 0; )
    {
      pa_card_profile_info2& profileInfo = *portInfo.profiles2[p];
      if (profileInfo.n_sinks <= 0) continue; // Ignore source-only profiles

      Profile newProfile;
      newProfile.Name = profileInfo.name;
      newProfile.Description = profileInfo.description;
      newProfile.Available = profileInfo.available != 0;
      newProfile.Priority = profileInfo.priority;

      { LOG(LogDebug) << "[PulseAudio]     Profile " << newProfile.Description << " (" << newProfile.Name << ") - Available " << (newProfile.Available ? "YES" : "NO") << " - Priority " << newProfile.Priority; }

      // Check if this profile is the active one
      newCard.HasActioveProfile |= (newProfile.Name == activeProfileName);

      // Add profile to the port
      newPort.Profiles.push_back(newProfile);
    }

    // Add port to the card
    newCard.Ports.push_back(newPort);
  }

  // Store card
  This.mSyncer.Lock();
  This.mCards.push_back(newCard);
  This.mSyncer.UnLock();
}

void PulseAudioController::EnumerateSinkCallback(pa_context* context, const pa_sink_info* info, int eol, void* userdata)
{
  (void)context;
  // Get class
  PulseAudioController& This = *(PulseAudioController*)userdata;

  // If eol is set to a positive number, you're at the end of the list
  if (eol > 0)
  {
    This.mSignal.Fire();
    return;
  }

  Sink newSink;
  newSink.Name = info->name;
  newSink.Index = info->index;
  newSink.Channels = info->channel_map.channels;

  { LOG(LogDebug) << "[PulseAudio] Sink #" << newSink.Index << ' ' << newSink.Name << " found."; }

  // Collect available ports
  for(int i = info->n_ports; --i >= 0; )
  {
    newSink.PortNames.push_back(info->ports[i]->name);
    { LOG(LogDebug) << "[PulseAudio]   Port " << info->ports[i]->name << " - " << info->ports[i]->description; }
  }

  // Attach the sink to it's parent card
  bool attached = false;
  for(Card& card : This.mCards)
    if (card.Index == (int)info->card)
    {
      This.mSyncer.Lock();
      card.Sinks.push_back(newSink);
      This.mSyncer.UnLock();
      attached = true;
      { LOG(LogDebug) << "[PulseAudio] Sink #" << newSink.Index << ' ' << newSink.Name << " attached to card #" << card.Index << ' ' << card.Name; }
    }

  // Attached?
  if (!attached)
  { LOG(LogWarning) << "[PulseAudio] Sink #" << newSink.Index << ' ' << newSink.Name << " has no parent card!"; }
}

void PulseAudioController::AddSpecialPlaybacks(IAudioController::DeviceList& list)
{
  switch(Board::Instance().GetBoardType())
  {
    case BoardType::UndetectedYet:
    case BoardType::Unknown:
    case BoardType::Pi0:
    case BoardType::Pi1:
    case BoardType::Pi2:
    case BoardType::Pi3:
    case BoardType::Pi3plus:
    case BoardType::Pi4:
    case BoardType::Pi400:
    case BoardType::UnknownPi:
    case BoardType::PCx86:
    case BoardType::PCx64:
    default: break;
  }
}

IAudioController::DeviceList PulseAudioController::GetPlaybackList()
{
  // Refresh all objects
  Refresh();

  Mutex::AutoLock lock(mSyncer);
  DeviceList result;

  AddSpecialPlaybacks(result);

  for(const Card& card : mCards)
    for(const Port& port : card.Ports)
    {
      bool available = false;
      for(const Profile& profile : port.Profiles)
        available |= profile.Available;

      std::string device = mCards.size() > 1 ? std::string(card.Description).append(" - ").append(_S(port.Description)) : port.Description;
      switch(port.Icon)
      {
        case AudioIcon::Auto: device.append(" \uf1e0"); break;
        case AudioIcon::Unidentified: device.append(" \uf1b0"); break;
        case AudioIcon::Speakers: device.append(" \uf1e1"); break;
        case AudioIcon::Headphones: device.append(" \uf1e2"); break;
        case AudioIcon::Screens: device.append(" \uf1e3"); break;
      }
      std::string displayable = available ? std::string("\u26ab ").append(device).append(" \u26ab") : std::string("\u26aa ").append(device).append(" \u26aa") ;
      result.push_back({ displayable, std::string(card.Name).append(1, ':').append(port.Name), port.Icon, available });
    }

  return result;
}

const PulseAudioController::Card* PulseAudioController::LookupCard(const std::string& name)
{
  for(const Card& card : mCards)
    if (name == card.Name)
      return &card;

  if (!mCards.empty())
    return &mCards[0];

  return nullptr;
}

const PulseAudioController::Port* PulseAudioController::LookupPort(const Card& card, const std::string& name)
{
  for(const Port& port : card.Ports)
    if (name == port.Name)
      return &port;

  if (!card.Ports.empty())
    return &card.Ports[0];

  return nullptr;
}

bool PulseAudioController::HasPort(const PulseAudioController::Sink& sink, const PulseAudioController::Port& port)
{
  for(const std::string& portname : sink.PortNames)
    if (portname == port.Name)
      return true;

  return false;
}

std::string PulseAudioController::AdjustSpecialPlayback(const std::string& originalPlaybackName, bool& allprocessed)
{
  allprocessed = false;

  switch(Board::Instance().GetBoardType())
  {
    case BoardType::UndetectedYet:
    case BoardType::Unknown:
    case BoardType::Pi0:
    case BoardType::Pi1:
    case BoardType::Pi2:
    case BoardType::Pi3:
    case BoardType::Pi3plus:
    case BoardType::Pi4:
    case BoardType::Pi400:
    case BoardType::UnknownPi:
    case BoardType::PCx86:
    case BoardType::PCx64:
    default: break;
  }

  return originalPlaybackName;
}

std::string PulseAudioController::SetDefaultPlayback(const std::string& originalPlaybackName)
{
  bool allProcessed = false;
  std::string playbackName = AdjustSpecialPlayback(originalPlaybackName, allProcessed);
  if (allProcessed) return playbackName; // AjustSpecialPlayback did some tricks, no need to go further

  const Card* card = nullptr;
  const Port* port = nullptr;
  {
    Mutex::AutoLock lock(mSyncer);

    { LOG(LogDebug) << "[PulseAudio] Switching to " << playbackName; }

    std::string cardName;
    std::string portName;
    if (!Strings::SplitAt(playbackName, ':', cardName, portName, true))
    { LOG(LogError) << "[PulseAudio] Invalid playbackname: " << playbackName; }

    card = LookupCard(cardName);
    if (card == nullptr) { LOG(LogError) << "[PulseAudio] No sound card available!"; return playbackName; }
    port = LookupPort(*card, portName);
    if (port == nullptr) { LOG(LogError) << "[PulseAudio] No port '" << portName << "' available on sound card " << card->Description; return playbackName; }

    // Activate port's best profile
    const Profile* selectedProfile = &port->Profiles[0];
    for (const Profile& profile : port->Profiles)
      selectedProfile = (profile.Priority > selectedProfile->Priority) ? &profile : selectedProfile;

    { LOG(LogDebug) << "[PulseAudio] Activating profile " << selectedProfile->Description << " for card #" << card->Index << ' ' << card->Name; }

    pa_operation* profileOp = pa_context_set_card_profile_by_index(mPulseAudioContext, card->Index, selectedProfile->Name.data(), SetProfileCallback,this);
    // Wait for response
    mSignal.WaitSignal();
    // Release
    pa_operation_unref(profileOp);
  }

  // Refesh sinks
  PulseEnumarateSinks();

  for(const Sink& sink : card->Sinks)
  {
    Mutex::AutoLock lock(mSyncer);
    //if (!HasPort(sink, *port)) continue; // Sink contains the target port?

    // Set port
    pa_operation* op = pa_context_set_sink_port_by_index(mPulseAudioContext, sink.Index, port->Name.data(), SetPortCallback, this);
    // Wait for result
    mSignal.WaitSignal();
    // Release
    pa_operation_unref(op);
    { LOG(LogDebug) << "[PulseAudio] Sink '" << sink.Name << "' has been switched to port " << port->Name; }

    // Set sink the default one
    op = pa_context_set_default_sink(mPulseAudioContext, sink.Name.data(), SetSinkCallback, this);
    // Wait for result
    mSignal.WaitSignal();
    // Release
    pa_operation_unref(op);
    { LOG(LogDebug) << "[PulseAudio] Sink '" << sink.Name << "' has been set as default sink."; }

    break;
  }

  // Return new  playback
  return std::string(card->Name).append(1, ':').append(port->Name);
}

int PulseAudioController::GetVolume()
{
  return Math::clampi(RecalboxConf::Instance().AsInt("audio.volume"),0, 100);
}

void PulseAudioController::SetVolume(int volume)
{
  if (mPulseAudioContext == nullptr) return;

  volume = Math::clampi(volume, 0, 100);

  Mutex::AutoLock lock(mSyncer);

  for(Card& card : mCards)
    for(Sink& sink : card.Sinks)
    {
      pa_cvolume volumeStructure;
      pa_cvolume_init(&volumeStructure);
      pa_cvolume_set(&volumeStructure, sink.Channels, (PA_VOLUME_NORM * volume) / 100);

      // Set volume
      pa_operation* op = pa_context_set_sink_volume_by_index(mPulseAudioContext, sink.Index, &volumeStructure, SetVolumeCallback, this);
      // Wait for result
      mSignal.WaitSignal();
      // Release
      pa_operation_unref(op);
    }
}

void PulseAudioController::Break()
{
  pa_mainloop_quit(mPulseAudioMainLoop, 1);
}

void PulseAudioController::Run()
{

  // Create a mainloop API and connection to the default server
  mPulseAudioMainLoop = pa_mainloop_new();
  pa_mainloop_api* pa_mlapi = pa_mainloop_get_api(mPulseAudioMainLoop);
  mPulseAudioContext = pa_context_new(pa_mlapi, "Recalbox");
  // This function defines a callback so the server will tell us it's state.
  pa_context_set_state_callback(mPulseAudioContext, ContextStateCallback, this);
  // This function connects to the pulse server
  pa_context_connect(mPulseAudioContext, nullptr, pa_context_flags::PA_CONTEXT_NOFLAGS, nullptr);

  // Thread loop
  int result = 0;
  pa_mainloop_run(mPulseAudioMainLoop, &result);

  // Deinit
  pa_context_unref(mPulseAudioContext);
  pa_mainloop_free(mPulseAudioMainLoop);
}

void PulseAudioController::PulseContextConnect()
{
  // Wait for response
  mSignal.WaitSignal();
  { LOG(LogDebug) << "[PulseAudio] Connected to Server."; }
}

void PulseAudioController::PulseContextDisconnect()
{
  // Disconnect from pulse server
  pa_context_disconnect(mPulseAudioContext);
  { LOG(LogDebug) << "[PulseAudio] Disconnected to Server."; }
}

void PulseAudioController::PulseEnumarateSinks()
{
  mSyncer.Lock();
  for(Card& card : mCards)
    card.Sinks.clear();
  mSyncer.UnLock();

  // Enumerate sinks
  { LOG(LogDebug) << "[PulseAudio] Enumerating Sinks"; }
  pa_operation* sinkOp = pa_context_get_sink_info_list(mPulseAudioContext, EnumerateSinkCallback, this);
  // Wait for response
  mSignal.WaitSignal();
  // Release
  pa_operation_unref(sinkOp);

  // Unmute all sinks
  for(Card& card : mCards)
    for(Sink& sink : card.Sinks)
    {
      { LOG(LogDebug) << "[PulseAudio] Unmute Sink #" << sink.Index << " - " << sink.Name; }
      // Set volume
      pa_context_set_sink_mute_by_index(mPulseAudioContext, sink.Index, 0, SetMuteCallback, this);
      // Wait for result
      mSignal.WaitSignal();
    }
}

const PulseAudioController::Profile* PulseAudioController::GetBestProfile(const PulseAudioController::Card& card)
{
  // Seek for the highest priority port
  const Port* selectedPort = nullptr;
  int priority = -1;
  for (const Port& port : card.Ports)
  {
    bool available = false;
    for(const Profile& profile : port.Profiles)
      available |= profile.Available;

    // Get highest priority port with profile available
    if (port.Priority > priority && available)
    {
      priority = port.Priority;
      selectedPort = &port;
    }
  }
  // Check port
  if (selectedPort == nullptr)
  { LOG(LogWarning) << "[PulseAudio] Card #" << card.Index << ' ' << card.Name << " has no port with available profiles!"; return nullptr; }

  // Check available profiles
  if (selectedPort->Profiles.empty()) { LOG(LogWarning) << "[PulseAudio] Card #" << card.Index << ' ' << card.Name << ", Port " << selectedPort->Description << " has no profile!"; return nullptr; }

  // Seek for the highest profile
  const Profile* selectedProfile = &selectedPort->Profiles[0];
  for (const Profile& profile : selectedPort->Profiles)
    selectedProfile = (profile.Priority > selectedProfile->Priority) ? &profile : selectedProfile;

  return selectedProfile;
}

void PulseAudioController::SetDefaultProfiles()
{
  for(Card& card : mCards)
  {
    if (card.HasActioveProfile) continue;
    if (card.Ports.empty()) { LOG(LogWarning) << "[PulseAudio] Card #" << card.Index << ' ' << card.Name << " has no port!"; continue; }

    { LOG(LogDebug) << "[PulseAudio] Card #" << card.Index << ' ' << card.Name << " has no profile activated."; }

    const Profile* selectedProfile = GetBestProfile(card);
    if (selectedProfile == nullptr) continue;

    // Activate selected profile
    { LOG(LogDebug) << "[PulseAudio] Activating profile " << selectedProfile->Description << " for card #" << card.Index << ' ' << card.Name; }

    pa_operation* profileOp = pa_context_set_card_profile_by_index(mPulseAudioContext, card.Index, selectedProfile->Name.data(), SetProfileCallback, this);
    // Wait for response
    mSignal.WaitSignal();
    // Release
    pa_operation_unref(profileOp);
  }
}

void PulseAudioController::PulseEnumerateCards()
{
  mCards.clear();

  // Enumerate cards
  { LOG(LogDebug) << "[PulseAudio] Enumerating Cards."; }
  pa_operation* cardOp = pa_context_get_card_info_list(mPulseAudioContext, EnumerateCardCallback, this);
  
  // Wait for response
  mSignal.WaitSignal();
  
  // Release
  pa_operation_unref(cardOp);
  
  // Activate the best profile on every card if they do not have default profile
  SetDefaultProfiles();
  
  // Enumerate sinks
  PulseEnumarateSinks();
  
}  

void PulseAudioController::PulseSubscribe()
{
  { LOG(LogDebug) << "[PulseAudio] Subscribing to events"; }

  pa_context_set_subscribe_callback(mPulseAudioContext, SubsciptionCallback, this);
  pa_context_subscribe(mPulseAudioContext, PA_SUBSCRIPTION_MASK_ALL, nullptr, nullptr);
}

std::string PulseAudioController::GetCardDescription(const pa_card_info& info)
{
  std::string result;

  // Get best name
  const char* cardName = pa_proplist_gets(info.proplist, "alsa.card_name");
  if (cardName == nullptr) cardName = pa_proplist_gets(info.proplist, "bluez.alias");
  if (cardName == nullptr) cardName = pa_proplist_gets(info.proplist, "device.description");
  if (cardName == nullptr) cardName = "Unlabelled device";

  // Change
  switch(Board::Instance().GetBoardType())
  {
    case BoardType::Pi0:
    case BoardType::Pi1:
    case BoardType::Pi2:
    case BoardType::Pi3:
    case BoardType::Pi3plus:
    case BoardType::Pi4:
    case BoardType::Pi400:
    case BoardType::UnknownPi:
    {
      result = cardName;
      Strings::ReplaceAllIn(result, "bcm2835", "");
      Strings::ReplaceAllIn(result, "v4-hdmi", "HDMI");
      break;
    }
    case BoardType::PCx86:
    case BoardType::PCx64:
    case BoardType::UndetectedYet:
    case BoardType::Unknown:
    default:
    {
      result = cardName;
      break;
    }
  }

  if (result.empty()) result.append("Card #").append(Strings::ToString(info.index));

  return Strings::Trim(result);
}

std::string PulseAudioController::GetPortDescription(const pa_card_port_info& info, AudioIcon& icon)
{
  std::string result = info.description;
  std::string low(Strings::ToLowerASCII(result));

  // Change
  switch(Board::Instance().GetBoardType())
  {
    case BoardType::Pi0:
    case BoardType::Pi1:
    case BoardType::Pi2:
    case BoardType::Pi3:
    case BoardType::Pi3plus:
    case BoardType::Pi4:
    case BoardType::Pi400:
    case BoardType::UnknownPi: break;
    case BoardType::PCx86:
    case BoardType::PCx64:
    case BoardType::UndetectedYet:
    case BoardType::Unknown:
    default: break;
  }

  return result;
}
