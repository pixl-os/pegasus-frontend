//
// Created by thierry.imbert on 12/02/2020.
//
#pragma once

#include <utils/os/fs/Path.h>

class Crc32File
{
  private:
    Path mPath;

  public:
    /*!
     * @brief Constructor
     * @param path Path to compute Crc32 from
     */
    explicit Crc32File(const Path& path)
      : mPath(path)
    {
    }

    /*!
     * @brief Get Crc32 of the file content
     * @param targetCrc32 Crc32 output value
     * @return True if the Crc32 has been computed, false on error
     */
    bool Crc32(unsigned int& targetCrc32);
};
