// Pegasus Frontend
//
// Created by Bozo The Geek - 20/01/2022
//

#include <utils/rLog.h>
#include <utils/Files.h>
#include <RootFolders.h>
#include <utils/Zip.h>

#include "Bios.h"

namespace {
//section to add local private function
} // namespace

namespace model {
Bios::Bios(QObject* parent)
    : QObject(parent)
{
}

Bios::Md5Hash::Md5Hash(const std::string& source)
  : Md5Hash()
{
  if (source.length() != sizeof(mBytes) * 2)
  {
    { LOG(LogError) << "[Bios] Invalid MD5: " << source; }
    mValid = false;
    return;
  }

  // Deserialize
  for(int i = (int)sizeof(mBytes); --i >= 0;)
  {
    unsigned char b = 0;
    unsigned char cl = (source[i * 2 + 0]) | 0x20 /* force lowercase - do not disturb digits */;
    unsigned char ch = (source[i * 2 + 1]) | 0x20 /* force lowercase - do not disturb digits */;
    b |= ((cl - 0x30) <= 9 ? (cl - 0x30) : ((cl - 0x61) <= 5) ? (cl - 0x61 + 10) : 0) << 4;
    b |= ((ch - 0x30) <= 9 ? (ch - 0x30) : ((ch - 0x61) <= 5) ? (ch - 0x61 + 10) : 0) << 0;
    mBytes[i] = b;
  }
  mValid = true;
}

std::string Bios::Md5Hash::ToString() const
{
  char hashStr[sizeof(mBytes) * 2];

  // Serialize
  for(int i = (int)sizeof(mBytes); --i >= 0;)
  {
    hashStr[i * 2 + 0] = "0123456789ABCDEF"[mBytes[i] >> 4];
    hashStr[i * 2 + 1] = "0123456789ABCDEF"[mBytes[i] & 15];
  }

  return std::string(hashStr, sizeof(hashStr));
}

QString Bios::md5 (const QString path){

    // Set mandatory fields
    Strings::Vector list = Strings::Split(path.toUtf8().constData() , '|');
    for(int i = sMaxBiosPath; --i >= 0; )
      if ((int)list.size() > i)
      {
        mPath[i] = Path(list[i]);
        if (!mPath[i].IsAbsolute())
          mPath[i] = RootFolders::DataRootFolder / "bios" / path.toUtf8().constData();
      }

    // Scan
    bool found = false;
    for(int i = sMaxBiosPath; --i >= 0;)
    {
      if (!mPath[i].Exists()) continue;
      if (Strings::ToLowerASCII(mPath[i].Extension()) == ".zip")
      {
        // Get composite hash from the zip file
        std::string md5string = Zip(mPath[i]).Md5Composite();
        mRealFileHash = Md5Hash(md5string);
      }
      else
      {
        // Load bios
        std::string biosContent = Files::LoadFile(mPath[i]);

        // Compute md5
        MD5 md5;
        md5.update(biosContent.data(), biosContent.length());
        md5.finalize();
        mRealFileHash = Md5Hash(md5);
      }
      found = true;
    }

    // Not found
    if (!found)
    {
      mStatus = Status::FileNotFound;
      return "";
    }
    else
    {
      mStatus = Status::FileFound;
      return QString::fromStdString(mRealFileHash.ToString());
    }
}

} // namespace model
