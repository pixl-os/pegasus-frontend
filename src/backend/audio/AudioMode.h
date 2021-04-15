//
// Created by gugue_u on 24/03/2021.
//
// From recalbox ES and Integrated by BozoTheGeek 12/04/2021 in Pegasus Front-end
//

#pragma once

enum class AudioMode
{
    MusicsOnly,
    VideosSoundOnly,
    MusicsAndVideosSound,
    MusicsXorVideosSound,
    None
};

class AudioModeTools
{
  public:
    static bool CanPlayMusic();
    static bool CanDecodeVideoSound();

    static AudioMode AudioModeFromString(const std::string& audioMode);
    static const std::string& AudioModeFromEnum(AudioMode audioMode);
};