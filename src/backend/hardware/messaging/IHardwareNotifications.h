//
// Created by bkg2k on 02/11/2020.
//
// From recalbox ES and Integrated by BozoTheGeek 12/04/2021 in Pegasus Front-end
//
#pragma once

#include <hardware/BoardType.h>

class IHardwareNotifications
{
  public:
    /*
     * Application status
     */

    /*!
     * @brief Get the status of the application
     * If the application is running and able to process notification messages, this method must return true.
     * If the application is blocked for an unknown amount of time, for exemple, running an external game,
     * it must return false
     * @return True if the application is running, false otherwise
     */
    virtual bool IsApplicationRunning() = 0;

    /*
     * Notifications
     */

    /*!
     * @brief Headphone has been pluggen in
     * @param board current board
     */
    virtual void HeadphonePluggedIn(BoardType board) = 0;

    /*!
     * @brief Headphone has been unplugged
     * @param board current board
     */
    virtual void HeadphoneUnplugged(BoardType board) = 0;

    /*!
     * @brief Decrease volume
     * @param board current board
     */
    virtual void VolumeDecrease(BoardType board, float percent) = 0;

    /*!
     * @brief Increase volume
     * @param board current board
     */
    virtual void VolumeIncrease(BoardType board, float percent) = 0;

    /*!
     * @brief Power button had been pressed and released for the given amount of time
     * @param board current board
     * @param milliseconds total time the power button has been pressed down
     */
    virtual void PowerButtonPressed(BoardType board, int milliseconds) = 0;

    /*!
     * @brief We have been resumed from suspend mode
     * @param board current board
     */
    virtual void Resume(BoardType board) = 0;
};
