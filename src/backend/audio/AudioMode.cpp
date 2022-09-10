//
// Created by gugue_u on 24/03/2021.
//
// From recalbox ES and Integrated by BozoTheGeek 12/04/2021 in Pegasus Front-end
//

#include <RecalboxConf.h>
#include "AudioMode.h"

bool AudioModeTools::CanPlayMusic()
{
  AudioMode audioMode = RecalboxConf::Instance().GetAudioMode();
  switch (audioMode)
  {
    case AudioMode::MusicsOnly:
    case AudioMode::MusicsAndVideosSound:
    case AudioMode::MusicsXorVideosSound:
      return true;
    case AudioMode::VideosSoundOnly:
    case AudioMode::None:
      break;
  }
  return false;
}

bool AudioModeTools::CanDecodeVideoSound()
{
  AudioMode audioMode = RecalboxConf::Instance().GetAudioMode();
  switch (audioMode)
  {
    case AudioMode::VideosSoundOnly:
    case AudioMode::MusicsAndVideosSound:
    case AudioMode::MusicsXorVideosSound: return true;
    case AudioMode::MusicsOnly:
    case AudioMode::None: break;
  }
  return false;
}

AudioMode AudioModeTools::AudioModeFromString(const std::string& audioMode)
{
  //if (audioMode == "musiconly") return AudioMode::MusicsOnly; //-> not yet supported
  //if (audioMode == "videosoundonly") return AudioMode::VideosSoundOnly; //-> not yet supported
  if (audioMode == "musicandvideosound") return AudioMode::MusicsAndVideosSound;
  if (audioMode == "none") return AudioMode::None;
  //if (audioMode == "musicsxorvideossound") return AudioMode::MusicsXorVideosSound; //-> not yet supported
  
  //activate all sounds if not able to recognize/support the ES parameter
  return AudioMode::MusicsAndVideosSound;
}

const std::string& AudioModeTools::AudioModeFromEnum(AudioMode audioMode)
{
  switch (audioMode)
  {
    case AudioMode::MusicsXorVideosSound: break;
    case AudioMode::MusicsOnly:
    {
      static std::string sScraper = "musiconly";
      return sScraper;
    }
    case AudioMode::VideosSoundOnly:
    {
      static std::string sFileName = "videosoundonly";
      return sFileName;
    }
    case AudioMode::MusicsAndVideosSound:
    {
      static std::string sFileName = "musicandvideosound";
      return sFileName;
    }
    case AudioMode::None:
    {
      static std::string sFileName = "none";
      return sFileName;
    }
  }
  static std::string sFileName = "musicxorvideosound";
  return sFileName;
}