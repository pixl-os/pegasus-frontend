//
// Created by bkg2k on 10/12/2019.
//
// From recalbox ES and Integrated by BozoTheGeek in Pegasus Front-end
//

#include <utils/hash/Md5.h>
#include <algorithm>
#include "Zip.h"

Zip::Zip(const Path& zipfile, bool write)
{
  int err = 0;
  mArchive = zip_open(zipfile.ToChars(), write ? (ZIP_CREATE | ZIP_TRUNCATE) : ZIP_RDONLY, &err);
}

Zip::~Zip()
{
  if (mArchive != nullptr)
    zip_close(mArchive);
}

int Zip::Count() const
{
  if (mArchive != nullptr)
    return (int)zip_get_num_entries(mArchive, 0);
  return 0;
}

Path Zip::FileName(int index) const
{
  if (mArchive != nullptr)
  {
    const char* name = zip_get_name(mArchive, index, ZIP_FL_ENC_GUESS);
    if (name != nullptr)
      return Path(name);
  }
  return Path::Empty;
}

int Zip::Crc32(int index) const
{
  if (mArchive != nullptr)
  {
    zip_stat_t stats;
    if (zip_stat_index(mArchive, index, 0, &stats) == 0)
      if ((stats.valid & ZIP_STAT_CRC) != 0)
        return stats.crc;
  }
  return 0;
}

std::string Zip::Md5(int index) const
{
  if (mArchive != nullptr)
  {
    MD5 md5;
    zip_file_t* file = zip_fopen_index(mArchive, index, 0);
    if (file != nullptr)
    {
      char buffer[1 << 20]; // 1Mb buffer
      for(int read = 0; (read = (int)zip_fread(file, buffer, sizeof(buffer))) > 0; )
        md5.update(buffer, read);
      zip_fclose(file);
      md5.finalize();
      return md5.hexdigest();
    }
  }

  return std::string();
}

std::string Zip::Md5Composite() const
{
  if (mArchive != nullptr)
  {
    MD5 md5;

    // Build sorted file list
    std::vector<std::string> fileList;
    for(int i = zip_get_num_entries(mArchive, 0); --i >= 0; )
      fileList.push_back(zip_get_name(mArchive, i, ZIP_FL_ENC_GUESS));
    std::sort(fileList.begin(), fileList.end());

    // Get MD5
    for(const auto& fileName : fileList)
    {
      zip_file_t* file = zip_fopen(mArchive, fileName.data(), 0);
      if (file != nullptr)
      {
        char buffer[1 << 20]; // 1Mb buffer
        for (int read = 0; (read = (int) zip_fread(file, buffer, sizeof(buffer))) > 0;)
          md5.update(buffer, read);
        zip_fclose(file);
      }
    }
    md5.finalize();
    return md5.hexdigest();
  }

  return std::string();
}

long long Zip::CompressedSize(int index) const
{
  if (mArchive != nullptr)
  {
    zip_stat_t stats;
    if (zip_stat_index(mArchive, index, 0, &stats) == 0)
      if ((stats.valid & ZIP_STAT_COMP_SIZE) != 0)
        return stats.comp_size;
  }
  return 0;
}

long long Zip::UncompressedSize(int index) const
{
  if (mArchive != nullptr)
  {
    zip_stat_t stats;
    if (zip_stat_index(mArchive, index, 0, &stats) == 0)
      if ((stats.valid & ZIP_STAT_SIZE) != 0)
        return stats.size;
  }
  return 0;
}

bool Zip::Add(const Path& file, const Path& base)
{
  // Get source
  zip_source* source = zip_source_file_create(file.ToChars(), 0, 0, nullptr);
  if (source == nullptr)  return false;

  // Add
  bool dummy = false;
  int index =  zip_file_add(mArchive, file.MakeRelative(base, dummy).ToChars(), source, ZIP_FL_ENC_UTF_8);
  if (index < 0)
  {
    zip_source_free(source); // Delete source only on failure
    return false;
  }

  // Set compression
  zip_set_file_compression(mArchive, index, ZIP_CM_BZIP2, 9);

  return true;
}

bool Zip::Add(const std::string& content, const std::string path)
{
  // Get source
  zip_source* source = zip_source_buffer(mArchive, content.data(), content.length(), 0);
  if (source == nullptr)  return false;

  // Add
  int index =  zip_file_add(mArchive, path.data(), source, ZIP_FL_ENC_UTF_8);
  if (index < 0)
  {
    zip_source_free(source); // Delete source only on failure
    return false;
  }

  // Set compression
  zip_set_file_compression(mArchive, index, ZIP_CM_BZIP2, 9);

  return true;
}

std::string Zip::Content(int index) const
{
  if (mArchive != nullptr)
  {
    zip_file_t* file = zip_fopen_index(mArchive, index, 0);
    if (file != nullptr)
    {
      std::string result;
      char buffer[1 << 20]; // 1Mb buffer
      for(int read = 0; (read = (int)zip_fread(file, buffer, sizeof(buffer))) > 0; )
        result.append(buffer, read);
      zip_fclose(file);
      return result;
    }
  }
  return std::string();
}
