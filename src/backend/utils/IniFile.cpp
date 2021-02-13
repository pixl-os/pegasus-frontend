//
// Created by thierry.imbert on 18/02/2020.
//

#include "IniFile.h"

#include <utils/Strings.h>
#include <utils/Files.h>
#include "utils/rLog.h"

IniFile::IniFile(const Path& path, const Path& fallbackpath)
  : mFilePath(path),
    mFallbackFilePath(fallbackpath),
    mValid(Load())
{
}

IniFile::IniFile(const Path& path)
  : mFilePath(path),
    mFallbackFilePath(),
    mValid(Load())
{
}

bool IniFile::IsValidKeyValue(const std::string& line, std::string& key, std::string& value)
{
  static std::string _allowedCharacters = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789.-,;:/!?*+=<>()@\"'#&{}[]%$";
  if (!line.empty()) // Ignore empty line
  {
    bool comment = (line[0] == ';' || line[0] == '#');
    if (!comment)
    {
      size_t separatorPos = line.find('=');
      if (separatorPos != std::string::npos) // Expect a key=value line
      {
        size_t validated = line.find_first_not_of(_allowedCharacters);
        if (validated == std::string::npos || validated >= separatorPos) // Unknown characters after the = ?
        {
          key = line.substr(0, separatorPos);
          value = line.substr(separatorPos + 1);
          return true;
        }
        else LOG(LogWarning) << "Invalid key: `" << line << '`';
      }
      else LOG(LogError) << "Invalid line: `" << line << '`';
    }
  }
  return false;
}

bool IniFile::Load()
{
  // Load file
  std::string content;
  if (!mFilePath.IsEmpty() && mFilePath.Exists()) content = Files::LoadFile(mFilePath);
  else if (!mFallbackFilePath.IsEmpty() && mFallbackFilePath.Exists()) content = Files::LoadFile(mFallbackFilePath);
  else return false;

  // Split lines
  content = Strings::Replace(content, "\r", "");
  Strings::Vector lines = Strings::Split(content, '\n');

  // Get key/value
  std::string key, value;
  for (std::string& line : lines)
    if (IsValidKeyValue(Strings::Trim(line, " \t\r\n"), key, value))
      mConfiguration[key] = value;

  OnLoad();
  return !mConfiguration.empty();
}

bool IniFile::Save()
{
  // No change?
  if (mPendingWrites.empty()) return true;

  // Load file
  std::string content = Files::LoadFile(mFilePath);

  // Split lines
  content = Strings::Replace(content, "\r", "");
  Strings::Vector lines = Strings::Split(content, '\n');

  // Save new value if exists
  for (auto& it : mPendingWrites)
  {
    // Write new kay/value
    std::string key = it.first;
    std::string val = it.second;
    bool lineFound = false;
    for (auto& line : lines)
      if (Strings::StartsWith(line, key + "=") || Strings::StartsWith(line, ";" + key + "="))
      {
        line = key.append("=").append(val);
        lineFound = true;
      }
    if (!lineFound)
      lines.push_back(key.append("=").append(val));

    // Move from Pendings to regular Configuration
    mConfiguration[key] = val;
    mPendingWrites.erase(key);
  }

  // Save new
  Files::SaveFile(mFilePath, Strings::Join(lines, "\n"));

  OnSave();
  return true;
}

std::string IniFile::AsString(const std::string& name) const
{
  return ExtractValue(name);
}

std::string IniFile::AsString(const std::string& name, const std::string& defaultValue) const
{
  std::string item = ExtractValue(name);
  return (!item.empty()) ? item : defaultValue;
}

bool IniFile::AsBool(const std::string& name, bool defaultValue) const
{
  std::string item = ExtractValue(name);
  return (!item.empty()) ? (item.size() == 1 && item[0] == '1') : defaultValue;
}

unsigned int IniFile::AsUInt(const std::string& name, unsigned int defaultValue) const
{
  std::string item = ExtractValue(name);
  if (!item.empty())
  {
    long long int value = 0;
    if (Strings::ToLong(item, value))
      return (unsigned int)value;
  }

  return defaultValue;
}

int IniFile::AsInt(const std::string& name, int defaultValue) const
{
  std::string item = ExtractValue(name);
  if (!item.empty())
  {
    int value = 0;
    if (Strings::ToInt(item, value))
      return value;
  }

  return defaultValue;
}

void IniFile::SetString(const std::string& name, const std::string& value)
{
  mPendingWrites[name] = value;
}

void IniFile::SetBool(const std::string& name, bool value)
{
  mPendingWrites[name] = value ? "1" : "0";
}

void IniFile::SetUInt(const std::string& name, unsigned int value)
{
  mPendingWrites[name] = Strings::ToString((long long)value);
}

void IniFile::SetInt(const std::string& name, unsigned int value)
{
  mPendingWrites[name] = Strings::ToString(value);
}

void IniFile::SetList(const std::string& name, const std::vector<std::string>& values)
{
  mPendingWrites[name] = Strings::Join(values, ",");
}

bool IniFile::isInList(const std::string& name, const std::string& value) const
{
  bool result = false;
  if (mConfiguration.contains(name))
  {
    std::string s = AsString(name);
    std::string delimiter = ",";

    size_t pos = 0;
    std::string token;
    while (((pos = s.find(delimiter)) != std::string::npos))
    {
      token = s.substr(0, pos);
      if (token == value)
        result = true;
      s.erase(0, pos + delimiter.length());
    }
    if (s == value)
      result = true;
  }
  return result;
}

std::string IniFile::ExtractValue(const std::string& key) const
{
  std::string* item = mPendingWrites.try_get(key);
  if (item == nullptr) item = mConfiguration.try_get(key);
  return (item != nullptr) ? *item : std::string();
}

