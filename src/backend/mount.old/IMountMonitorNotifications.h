//
// Created by bkg2k on 14/01/2022.
//
// As part of the RECALBOX Project
// http://www.recalbox.com
//
#pragma once

#include "MountDevice.h"

class IMountMonitorNotifications
{
  public:
    //! Destructor
    virtual ~IMountMonitorNotifications() = default;

    /*!
     * @brief Notify a new device partition has been mounted
     * @param root Mount Point
     */
    virtual void NotifyDeviceMount(const DeviceMount& root) = 0;

    /*!
     * @brief Notify a new device partition has been unmounted
     * @param root Mount Point
     */
    virtual void NotifyDeviceUnmount(const DeviceMount& root) = 0;
};