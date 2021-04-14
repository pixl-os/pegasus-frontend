//
// Created by bkg2k on 02/11/2020.
//
// From recalbox ES and Integrated by BozoTheGeek 12/04/2021 in Pegasus Front-end
//
#pragma once

//! Board model/generation
enum class BoardType
{
    // Undetected
    UndetectedYet, // Not yet detected
    Unknown,       // Unknown hardware
    // RaspberryPi
    Pi0,           // Pi 0, 0W
    Pi1,           // Pi 1, A, B, A+, B+
    Pi2,           // Pi 2B
    Pi3,           // Pi 3B
    Pi3plus,       // Pi 3B+
    Pi4,           // Pi 4B
    Pi400,         // Pi 400
    UnknownPi,     // Unknown Pi with higher revisions
    // Odroid
    OdroidAdvanceGo, // Odroid advance go 1 & 2
    OdroidAdvanceGoSuper, // Odroid advance go 3 (super)
    // PC
    PCx86,
    PCx64,
};
