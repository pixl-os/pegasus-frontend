//
// Created by bkg2k on 13/08/2020.
//
// From recalbox ES and Integrated by BozoTheGeek 12/04/2021 in Pegasus Front-end
//
#pragma once

#include <audio/IAudioController.h>
#include <utils/cplusplus/StaticLifeCycleControler.h>
#include <audio/pulseaudio/PulseAudioController.h>

class AudioController: public StaticLifeCycleControler<AudioController>
{
  private:
    static IAudioController& GetAudioController()
    {
      static PulseAudioController sPulseaudioController;
      return sPulseaudioController;
    }

    // Underlaying audio controler
    IAudioController& mController;

    // Has special ausio settings?
    bool mHasSpecialAudio;

    /*!
     * @brief Check if the current machine has a special audio configuration
     * @return True if the current machine has a special audio configuration
     */
    static bool GetSpecialAudio();

  public:
    AudioController()
      : StaticLifeCycleControler("AudioController")
      , mController(GetAudioController())
      , mHasSpecialAudio(GetSpecialAudio())
    {
    }

    /*!
     * @brief Get playback list
     * @return Map identifier : playback name
     */
    IAudioController::DeviceList GetPlaybackList() const { return mController.GetPlaybackList(); }

    /*!
     * @brief Set the default card/device
     * @param playbackName playback name from GetPlaybackList()
     * @return playbackName or default value if playbackName is invalid
     */
    std::string SetDefaultPlayback(const std::string& playbackName);

    /*!
     * @brief Get volume from the given playback
     * @return Volume percent
     */
    int GetVolume() const { return mController.GetVolume(); }

    /*!
     * @brief Set volume to the given playback
     * @param volume Volume percent
     */
    void SetVolume(int volume) { if (!mHasSpecialAudio) mController.SetVolume(volume); }

    /*!
     * @brief Check if there is a special audio configuration
     * @return True if there is a special audio configuration
     */
    bool HasSpecialAudio() const { return mHasSpecialAudio; }


    /*!
     * @brief Force the implementation to refresh all its internal objects
     */
    void Refresh() { mController.Refresh(); }
};
