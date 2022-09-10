//
// Created by bkg2k on 18/11/2019.
//
#pragma once

/*!
 * @brief Inherit this class to avoid any copy/move
 */
class INoCopy
{
  public:
    /*!
     * @brief Default constructor
     */
    INoCopy() = default;

    /*!
     * @brief Delete copy constructor
     * @param source Source object
     */
    INoCopy(const INoCopy& source) = delete;

    /*!
     * @brief Delete move constructor
     * @param source Source object
     */
    INoCopy(INoCopy&& source) = delete;

    /*!
     * @brief Delete copy assignation
     * @param source Source object
     */
    INoCopy& operator =(const INoCopy& source) = delete;

    /*!
     * @brief Delete move assignation
     * @param source Source object
     */
    INoCopy& operator =(INoCopy&& source) = delete;
};