//
// Created by bkg2k on 31/07/2019.
//

#include "Files.h"
#include "fcntl.h"
#include "unistd.h"

std::string Files::LoadFile(const Path& path)
{
  std::string result;

  if (path.Exists())
  {
    int fd = open(path.ToChars(), O_RDONLY);
    if (fd >= 0)
    {
      long l = lseek(fd, 0, SEEK_END);
      if (l > 0)
      {
        result.resize(l, 0);
        lseek(fd, 0, SEEK_SET);
        l = read(fd, (void*)result.data(), l);
        if (l < 0) l = 0; // Return empty string on error
        result.resize(l);
      }
      else if (l < 0)
      {
        char buffer[4096];
        for(int r = 0; (r = read(fd, buffer, sizeof(buffer))) > 0; )
          result.append(buffer, r);
      }
      close(fd);
    }
  }

  return result;
}

std::string Files::LoadFile(const Path& path, long long from, long long size)
{
  std::string result;

  if (path.Exists())
  {
    int fd = open(path.ToChars(), O_RDONLY);
    if (fd >= 0)
    {
      long l = lseek(fd, from, SEEK_END);
      if (l > 0)
      {
        result.resize(size, 0);
        lseek(fd, 0, SEEK_SET);
        l = read(fd, (void*)result.data(), size);
        if (l < 0) l = 0; // Return empty string on error
        result.resize(l);
      }
      close(fd);
    }
  }

  return result;
}

// TODO: convert to open/write/close
bool Files::SaveFile(const Path& path, const std::string& content)
{
  FILE* f = fopen(path.ToChars(), "wb");
  if (f != nullptr)
  {
    bool ok = (fwrite(content.c_str(), content.size(), 1, f) == 1);
    fclose(f);
    return ok;
  }
  return false;
}

bool Files::AppendToFile(const Path& path, const void* data, int size)
{
  FILE* f = fopen(path.ToChars(), "ab");
  if (f != nullptr)
  {
    bool ok = (fwrite(data, size, 1, f) == 1);
    fclose(f);
    return ok;
  }
  return false;
}
