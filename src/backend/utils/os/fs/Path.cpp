//
// Created by bkg2k on 23/10/2019.
//

#include <utils/Strings.h>
#include <sys/stat.h>
#include <zconf.h>
#include <cstring>
#include <dirent.h>
#include "Path.h"

const Path Path::Empty;

void Path::Normalize()
{
  // Remove "\\?\"
  if((mPath.find(R"(\\?\)")) <= 0)
    mPath.erase(0, 4);

  // Convert '\' to '/' in-place by removing the const qualifier - Yes it's bad
  for (char* p = (char*)mPath.c_str() - 1; *(++p) != 0; )
    if (*p == '\\')
      *p = sSeparator;

  // Remove tailing separator
  if (!mPath.empty())
    if (mPath.size() > 1) // Don't remove root /
      if (mPath[mPath.size() - 1] == sSeparator)
        mPath.resize(mPath.size() - 1);

  // Remove double separator
  if (mPath.find(sDoubleSeparatorString) != std::string::npos)
    mPath = Strings::Replace(mPath, sDoubleSeparatorString, sSeparatorString);

  // Remove single colon
  if (mPath.find(sSingleDotPath) != std::string::npos)
    mPath = Strings::Replace(mPath, sSingleDotPath, sSeparatorString);
  int size = mPath.size();
  if (size == 1 && mPath[0] == '.')
    mPath.clear();
  if (size > 2)
    if (mPath[size - 1] == '.' && mPath[size - 2] == '/')
      mPath.resize(size - 2);
}

std::string Path::Item(int index) const
{
  const char* p = mPath.c_str();    // Char pointer is faster
  if (*p == sSeparator) p++;        // Skip first separator if any
  const char* start = p;            // Record first start
  int count = 0;                    // Separator count
  if (index > 0)                    // Don't try to find previous separator on index 0
    for(; *p != 0; ++p)
      if (*p == sSeparator)         // Previous separator found
      {
        start = ++p;                // Reset the start to the current part
        if (++count == index) break;// Stop when index reached
      }
  if (*p == 0) start = p;
  else while(*p != sSeparator && *p != 0) ++p;
  return mPath.substr(start - mPath.c_str(), p - start);
}

std::string Path::UptoItem(int index) const
{
  const char* p = mPath.c_str();    // Char pointer is faster
  if (*p == sSeparator) p++;        // Skip first separator if any
  int count = 0;                    // Separator count
  if (index > 0)                    // Don't try to find previous separator on index 0
    for(; *p != 0; ++p)
      if (*p == sSeparator)         // Previous separator found
        if (++count == index)       // Stop when index reached
        {
          ++p;                      // Skip separator
          break;
        }
  while(*p != sSeparator && *p != 0) ++p;
  return mPath.substr(0, p - mPath.c_str());
}

std::string Path::FromItem(int index) const
{
  const char* p = mPath.c_str();    // Char pointer is faster
  if (*p == sSeparator) p++;        // Skip first separator if any
  int count = 0;                    // Separator count
  if (index > 0)                    // Don't try to find previous separator on index 0
    for(; *p != 0; ++p)
      if (*p == sSeparator)         // Previous separator found
        if (++count == index)       // Stop when index reached
        {
          ++p;                      // Skip separator
          break;
        }
  return mPath.substr(p - mPath.c_str());
}

int Path::ItemCount() const
{
  const char* p = mPath.c_str(); // Char pointer is faster
  if (*p == sSeparator) p++;     // Skip first separator if any
  int count = 0;                 // Initialize separator count
  while(*p++ != 0)
    if (*p == sSeparator)        // Increase separator count
      count++;
  return count + 1;              // return separator count + 1, so that (/)this/is/your/path returns 3+1
}

Path Path::operator/(const char* path) const
{
  Path result(*this);
  if (path != nullptr)
  {
    if (path[0] != sSeparator && !mPath.empty())
      result.mPath.append(1, sSeparator);
    result.mPath.append(path);
    result.Normalize();
  }
  return result;
}

Path Path::operator/(const std::string& path) const
{
  Path result(*this);
  if (!path.empty())
  {
    if (path[0] != sSeparator && !mPath.empty())
      result.mPath.append(1, sSeparator);
    result.mPath.append(path);
    result.Normalize();
  }
  return result;
}

Path Path::operator/(const Path& path) const
{
  Path result(*this);
  if (!path.IsEmpty())
  {
    if (path.mPath[0] != sSeparator && !mPath.empty())
      result.mPath.append(1, sSeparator);
    result.mPath.append(path.mPath);
    result.Normalize();
  }
  return result;
}

Path Path::Directory() const
{
  const char* p = mPath.c_str(); // Char pointer is faster
  for(int i=mPath.size(); --i >= 0;)
    if (p[i] == sSeparator)
      if (i != 0)
        return (strcmp(p + i + 1, "..") == 0) ?
               Path(mPath.substr(0, i)).Directory() :
               Path(mPath.substr(0, i));
  return Path::Empty;
}

std::string Path::Filename() const
{
  const char* p = mPath.c_str(); // Char pointer is faster
  for(int i=mPath.size(); --i >= 0;)
    if (p[i] == sSeparator)
        return mPath.substr(i + 1);
  return mPath;
}

std::string Path::FilenameWithoutExtension() const
{
  int start = 0;
  int startExt = 0;
  // Extract filename
  const char* p = mPath.c_str(); // Char pointer is faster
  for(int i=mPath.size(); --i >= 0;)
    if (p[i] == sSeparator)
    {
      start = i + 1;
      startExt = i;
      break;
    }

  // Remove extention
  while(p[++startExt] == '.');
  for(int i=mPath.size(); --i >= startExt;)
    if (p[i] == sExtensionSeparator)
      return mPath.substr(start, i - start);

  // No extension
  return mPath.substr(start);
}

std::string Path::Extension() const
{
  int startExt = 0;
  // Extract filename
  const char* p = mPath.c_str(); // Char pointer is faster
  for(int i=mPath.size(); --i >= 0;)
    if (p[i] == sSeparator)
    {
      startExt = i;
      break;
    }

  // Get extention
  while(p[++startExt] == '.');
  for(int i=mPath.size(); --i >= startExt;)
    if (p[i] == sExtensionSeparator)
      return mPath.substr(i);

  // No extension
  return std::string();
}

Path Path::ChangeExtension(const std::string& newext) const
{
  int startExt = 0;
  // Extract filename
  const char* p = mPath.c_str(); // Char pointer is faster
  for(int i=mPath.size(); --i >= 0;)
    if (p[i] == sSeparator)
    {
      startExt = i;
      break;
    }

  // Get extention
  while(p[++startExt] == '.');
  for(int i=mPath.size(); --i >= startExt;)
    if (p[i] == sExtensionSeparator)
    {
      Path newPath(mPath.substr(0, i));
      newPath.mPath.append(newext);
      return newPath;
    }

  // No extension
  Path newPath(mPath);
  newPath.mPath.append(newext);
  return newPath;
}

bool Path::Exists() const
{
  struct stat64 info = {};

  // check if stat64 succeeded
  return (stat64(mPath.c_str(), &info) == 0);
}

long long Path::Size() const
{
  struct stat64 info = {};

  // check if stat64 succeeded
  if (stat64(mPath.c_str(), &info) == 0)
    return info.st_size;

  return 0;
}

bool Path::IsFile() const
{
  struct stat64 info = {};

  // check if stat64 succeeded
  if (stat64(mPath.c_str(), &info) != 0) return false;
  return (S_ISREG(info.st_mode));
}

bool Path::IsSymLink() const
{
  struct stat64 info = {};

  // check if stat64 succeeded
  if (lstat64(mPath.c_str(), &info) != 0) return false;
  return (S_ISLNK(info.st_mode));
}

bool Path::IsDirectory() const
{
  struct stat64 info = {};

  // check if stat64 succeeded
  if (stat64(mPath.c_str(), &info) != 0) return false;
  return (S_ISDIR(info.st_mode));
}

bool Path::IsHidden() const
{
  constexpr unsigned int dot    = (unsigned int)sDotDirectory;
  constexpr unsigned int dotdot = (unsigned int)sDotDirectory | ((unsigned int)sDotDirectory << 8);

  std::string filename = Filename();
  // Ignore "." and ".."
  unsigned int strint = *((unsigned int*)filename.c_str());
  if ((strint &   0xFFFF) == dot   ) return false;
  if ((strint & 0xFFFFFF) == dotdot) return false;

  return ((char)strint) == '.';
}

Path Path::ToAbsolute(const Path& base) const
{
  // Hack for build-in resources path
  if (mPath.size() >= 2)
    if (mPath[0] == ':' && mPath[1] == '/')
      return *this;

  // Empty or absolute already?
  if (mPath.empty() || IsAbsolute()) return *this;

  // Expand home path
  if (mPath[0] == '~') return Home() / (mPath.c_str() + 1);

  // Add base
  return base / mPath;
}

Path Path::ToAbsolute() const
{
  // Hack for build-in resources path
  if (mPath.size() >= 2)
    if (mPath[0] == ':' && mPath[1] == '/')
      return *this;

  // Empty or absolute already?
  if (mPath.empty() || IsAbsolute()) return *this;

  // Expand home path
  if (mPath[0] == '~') return Home() / (mPath.c_str() + 1);

  // Get cwd as base
  char path[PATH_MAX];
  if (getcwd(path, sizeof(path)) != nullptr)
  {
    std::string base(path);
    base.append(1, '/');
    base.append(mPath);
    return Path(base);
  }

  // Nothing more to do...
  return *this;
}

std::string Path::ResolveSymbolicLink(const char* source)
{
  struct stat info = {};
  if(lstat(source, &info) == 0)
  {
    std::string resolved;
    resolved.resize(info.st_size);
    if (readlink(source, (char*)resolved.data(), resolved.size()) > 0)
      return resolved;
  }
  // Error, return the original path
  return std::string(source);
}

Path Path::ToCanonical() const
{
  // Get absolute cleaned-up path
  Path canonical(ToAbsolute());

  // Copy the path inbto a char buffer so it can be moved and changed faster
  struct stat info = {};
  char path[PATH_MAX + 1];
  // Get the actual path or it's resolved path if the last item is a symlink
  bool IsResolved = IsSymLink();
  strncpy(path, IsResolved ? ResolveSymbolicLink(canonical.ToChars()).c_str() : canonical.ToChars(), PATH_MAX);

  // Reverse search - everything to the right of the index is already processed
  for(int i = mPath.size(); --i >= 0;)
    if (path[i] == sSeparator)
    {
      path[i] = '\0';                                       // Temporarily close the string
      if (lstat(path, &info) == 0)
        if (S_ISLNK(info.st_mode))
        {
          std::string resolved = ResolveSymbolicLink(path); // Resolve the path
          int newIndex = resolved.size();                   // Save the index right after the new resolved path
          resolved.append(1, sSeparator);                // Add separator
          resolved.append(path + i + 1);                 // Add remaining path
          i = newIndex;                                     // Start the scan in the resolved path
          strncpy(path, resolved.c_str(), PATH_MAX);        // Copy the new to our working buffer
          IsResolved = true;
        }
      path[i] = sSeparator;                                 // Set the separator again
    }

  return IsResolved ? Path(path) : canonical;
}

Path Path::Home()
{
  static Path sHomePath;

  if (sHomePath.IsEmpty())                               // Build only once
  {
    char* envHome = getenv("HOME");              // Get home
    if (envHome != nullptr) sHomePath.mPath = envHome; // Store home
    if (sHomePath.IsEmpty()) sHomePath = Cwd();          // Fallback to current working directory
    sHomePath.Normalize();                             // Normalize
  }

  return sHomePath;
}

Path Path::Cwd()
{
  char path[PATH_MAX];
  if (getcwd(path, sizeof(path)) != nullptr) return Path(path); // Got it!
  return Path::Empty;                                                // Not lucky...
}

Path::PathList Path::GetDirectoryContent() const
{
  PathList list;

  constexpr unsigned int dot    = (unsigned int)sDotDirectory;
  constexpr unsigned int dotdot = (unsigned int)sDotDirectory | ((unsigned int)sDotDirectory << 8);

  DIR* dir = opendir(mPath.c_str());
  if(dir != nullptr)
  {
    const struct dirent* entry = nullptr;
    // loop over all files in the directory
    while((entry = readdir(dir)) != nullptr)
    {
      // Ignore "." and ".."
      unsigned int strint = *((unsigned int*)entry->d_name);
      if ((strint &   0xFFFF) == dot   ) continue;
      if ((strint & 0xFFFFFF) == dotdot) continue;

      Path item(mPath);
      item.mPath.append(1, sSeparator);
      item.mPath.append(entry->d_name);
      list.push_back(item);
    }
    closedir(dir);
  }

  return list;
}

Path Path::MakeRelative(const Path& parent, bool &ok) const
{
  if (!parent.IsEmpty())
  {
    Path startWidth = parent.Exists() && !parent.IsDirectory() ? parent.Directory() : parent;

    // Check if path starts with
    if (mPath.find(startWidth.mPath) <= 0)
    {
      char c = mPath.c_str()[startWidth.mPath.size()];
      ok = ((c == 0) || (c == sSeparator));
      if (ok) return Path(mPath.c_str() + startWidth.mPath.size() + 1);
    }
  }

  // Nothing found :(
  ok = false;
  return *this;
}

bool Path::StartWidth(const Path& path) const
{
  if(mPath.find(path.mPath) <= 0)
  {
    char c = mPath.c_str()[path.mPath.size()];
    return ((c == 0) || (c == sSeparator));
  }
  return false;
}

std::string Path::MakeEscaped() const
{
  std::string escaped = mPath;

  static std::string invalidChars = " '\"\\!$^&*(){}[]?;<>";
  const char* invalids = invalidChars.c_str();
  for(int i = escaped.size(); --i >= 0; )
  {
    char c = escaped.c_str()[i];
    for(int j = invalidChars.size(); --j >= 0; )
      if (c == invalids[j])
      {
        escaped.insert(i, "\\");
        break;
      }
  }

  return escaped;
}

bool Path::CreatePath() const
{
  // Empty path are considered created too (also stops recursive calls)
  if (mPath.empty()) return true;
  // Already created?
  if (IsDirectory()) return true;

  if (Directory().CreatePath())
  {
    if (mkdir(mPath.c_str(), S_IRWXU) != 0)
      return (errno == EEXIST); // EEXIST should never happen here
    return true;
  }
  return false;
}

bool Path::Delete() const
{
  if (!Exists()) return true;
  return (unlink(mPath.c_str()) == 0);
}

bool Path::Rename(const Path& from, const Path& to)
{
  return rename(from.ToChars(), to.ToChars()) == 0;
}

