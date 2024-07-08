//
// Created by bkg2k on 16/07/22.
//
// As part of the RECALBOX Project
// http://www.recalbox.com
//
#pragma once

#include <utils/String.h>
#include <utils/locale/LocaleHelper.h>

/*!
 * @brief Simple size class to convert sizes (file or memory sizes)
 * into readable sizes in bytes, kilo bytes, mega bytes, etc...
 */
class Sizes
{
  public:
    /*!
     * @brief Build an instance from an integer size
     * @param size Integer size
     */
    explicit Sizes(int size) : mSize(size) {}
    /*!
     * @brief Build an instance from a long long size
     * @param size long long size
     */
    explicit Sizes(long long size) : mSize(size) {}

    /*
     * Convert
     */

    /*!
     * @brief Convert size to Bytes string
     * @return Byte representation as a string
     */
    [[nodiscard]] String ToBytes() const { return String(mSize).Append(_("B")); }

    /*!
     * @brief Convert size to KiloBytes string
     * @return KiloByte representation as a string
     */
    [[nodiscard]] String ToKiloBytes() const { return String((double)(mSize >> 00) * sDivider, 2).Append(_("KB")); }

    /*!
     * @brief Convert size to MegaBytes string
     * @return MegaByte representation as a string
     */
    [[nodiscard]] String ToMegaBytes() const { return String((double)(mSize >> 10) * sDivider, 2).Append(_("MB")); }

    /*!
     * @brief Convert size to GigaBytes string
     * @return GigaByte representation as a string
     */
    [[nodiscard]] String ToGigaBytes() const { return String((double)(mSize >> 20) * sDivider, 2).Append(_("GB")); }

    /*!
     * @brief Convert size to TeraBytes string
     * @return TeraByte representation as a string
     */
    [[nodiscard]] String ToTeraBytes() const { return String((double)(mSize >> 30) * sDivider, 2).Append(_("TB")); }

    /*!
     * @brief Convert size to the most human readable value, either in B, KB, MG, GB or TB
     * @return Human readable size
     */
    [[nodiscard]] String ToHumanSize() const
    {
      long long size = mSize;
      if (size < (1 << 10)) return String((int)size).Append(_("B"));
      if (size < (1 << 20)) return String((double)size * sDivider, 2).Append(_("KB"));
      size >>= 10; if (size < (1 << 20)) return String((double)size * sDivider, 2).Append(_("MB"));
      size >>= 10; if (size < (1 << 20)) return String((double)size * sDivider, 2).Append(_("GB"));
      size >>= 10; return String((double)size * sDivider, 2).Append(_("TB"));
    }

  private:
    //! 1024 divider :)
    static constexpr double sDivider = 1.0 / 1024.0;
    //! Size!
    long long mSize;
};
