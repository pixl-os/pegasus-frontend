//
// Created by bkg2k on 10/12/2019.
//
#pragma once

#include <zip.h>
#include <string>
#include <utils/os/fs/Path.h>

class Zip
{
  private:
    //! Archive file
    zip_t* mArchive;

  public:
    /*!
     * @brief Constructor
     * @param zipfile Zip file to open
     * @param write open/or create the zip archive in read/write mode
     */
    explicit Zip(const Path& zipfile, bool write = false);

    /*!
     * @brief Destructor
     */
    ~Zip();

    /*!
     * @brief Entry count in the archive
     * @return
     */
    int Count() const;

    /*!
     * @brief Get name of the entry at the given index
     * @param index Entry index from 0 to Count()-1
     * @return File Path
     */
    Path FileName(int index) const;

    /*!
     * @brief Get content of the entry at the given index
     * @param index Entry index from 0 to Count()-1
     * @return Content
     */
    std::string Content(int index) const;

    /*!
     * @brief Get crc32 of the entry at the given index
     * @param index Entry index from 0 to Count()-1
     * @return Crc32
     */
    int Crc32(int index) const;

    /*!
     * @brief Get Md5 of the entry at the given index
     * @param index Entry index from 0 to Count()-1
     * @return Md5
     */
    std::string Md5(int index) const;

    /*!
     * @brief Get Md5 of all entry in the zip original ordering
     * @return Md5
     */
    std::string Md5Composite() const;

    /*!
     * @brief Get compressed size of the entry at the given index
     * @param index Entry index from 0 to Count()-1
     * @return Compressed size
     */
    long long CompressedSize(int index) const;

    /*!
     * @brief Get uncompressed size of the entry at the given index
     * @param index Entry index from 0 to Count()-1
     * @return Uncompressed size
     */
    long long UncompressedSize(int index) const;

    /*!
     * @brief Add a file to the current archive
     * @param file file to add
     * @param base base folder to remove from the file path
     * @return True if the file has been added successfully
     */
    bool Add(const Path& file, const Path& base);

    /*!
     * @brief Add a content to the current archive
     * @param content content to zip
     * @param path entity path
     * @return True if the content has been added successfully
     */
    bool Add(const std::string& content, const std::string path);
};

