//
// Created by bkg2k on 13/08/2020.
//
#pragma once

#include <vector>
#include <string>
#include "DeviceDescriptor.h"

class IAudioController
{
  public:
    //! Autoswitch string
    static constexpr const char* sAutoSwitch = "auto:switch";

    //! For convenience only
    typedef std::vector<DeviceDescriptor> DeviceList;

    //! Destructor
    virtual ~IAudioController() = default;

    /*!
     * @brief Get playback list
     * @return Device list
     */
    virtual DeviceList GetPlaybackList() = 0;

    /*!
     * @brief Set the default card/device
     * @param playbackName playback name from GetPlaybackList()
     * @return playbackName or default value if playbackName is invalid
     */
    virtual std::string SetDefaultPlayback(const std::string& playbackName) = 0;

    /*!
     * @brief Get volume from the given playback
     * @return Volume percent
     */
    virtual int GetVolume() = 0;

    /*!
     * @brief Set volume to the given playback
     * @param volume Volume percent
     */
    virtual void SetVolume(int volume) = 0;

    /*!
     * @brief Force the implementation to refresh all its internal objects
     */
    virtual void Refresh() = 0;
};
