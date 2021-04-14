//
// Created by bkg2k on 03/11/2020.
//
// From recalbox ES and Integrated by BozoTheGeek 12/04/2021 in Pegasus Front-end
//
#pragma once

//! Message types
enum class MessageTypes
{
    None,               //!< None - Invalid message
    HeadphonePluggedIn, //!< Headphone have been plugged in
    HeadphoneUnplugged, //!< Headphone have been unplugged
    PowerButtonPressed, //!< Power button pressed and released after an amount of time
    VolumeUpPressed,    //!< Go3 Volume button up pressed
    VolumeDownPressed,  //!< Go3 Volume button down pressed
    Resume,             //!< Hardware exited from suspend mode
};
