//
// Created by bkg2k on 15/01/2020.
//
// From recalbox ES and Integrated by BozoTheGeek in Pegasus Front-end
//

#include "Internationalizer.h"
#include <cstdint>
#include <utils/rLog.h>
#include <utils/Files.h>
#include <cstring>

// Instances
std::string Internationalizer::sMoFlatFile;
std::vector<Internationalizer::StringPairLinks> Internationalizer::sStrings;
Internationalizer::StringSet Internationalizer::sIndexes[sIndexCount];
std::string Internationalizer::sActiveLocale = "NONE";

// https://www.gnu.org/software/gettext/manual/html_node/MO-Files.html

//         byte
//              +------------------------------------------+
//           0  | magic number = 0x950412de                |
//              |                                          |
//           4  | file format revision = 0                 |
//              |                                          |
//           8  | number of strings                        |  == N
//              |                                          |
//          12  | offset of table with original strings    |  == O
//              |                                          |
//          16  | offset of table with translation strings |  == T
//              |                                          |
//          20  | size of hashing table                    |  == S
//              |                                          |
//          24  | offset of hashing table                  |  == H
//              |                                          |
//              .                                          .
//              .    (possibly more entries later)         .
//              .                                          .
//              |                                          |
//           O  | length & offset 0th string  ----------------.
//       O + 8  | length & offset 1st string  ------------------.
//               ...                                    ...   | |
// O + ((N-1)*8)| length & offset (N-1)th string           |  | |
//              |                                          |  | |
//           T  | length & offset 0th translation  ---------------.
//       T + 8  | length & offset 1st translation  -----------------.
//               ...                                    ...   | | | |
// T + ((N-1)*8)| length & offset (N-1)th translation      |  | | | |
//              |                                          |  | | | |
//           H  | start hash table                         |  | | | |
//               ...                                    ...   | | | |
//   H + S * 4  | end hash table                           |  | | | |
//              |                                          |  | | | |
//              | NUL terminated 0th string  <----------------' | | |
//              |                                          |    | | |
//              | NUL terminated 1st string  <------------------' | |
//              |                                          |      | |
//               ...                                    ...       | |
//              |                                          |      | |
//              | NUL terminated 0th translation  <---------------' |
//              |                                          |        |
//              | NUL terminated 1st translation  <-----------------'
//              |                                          |
//               ...                                    ...
//              |                                          |
//              +------------------------------------------+

bool Internationalizer::HasPlural(const char* string, int length, int& newlength)
{
  for(int left = 0, right = length - 1; ++left <= --right; )
    if (string[left] == 0)
    {
      newlength = left;
      return true;
    }
    else if (string[right] == 0)
    {
      newlength = right;
      return true;
    }

  newlength = length;
  return true;
}

bool Internationalizer::BuildStringIndexes()
{
  // Everything is stored in the byte order of the generator
  // We're compiling and running on little endian CPUs.
  // No byte reordering is required.
  const int* i32 = (int*)sMoFlatFile.data();

  // Check MAGIC NUMBER, ignore revision
  if ((unsigned int)i32[0] != 0x950412de) return false;

  // String count
  int count = i32[2];

  // Read offsets
  int keyTable        = i32[3] / 4; // Assuming both string tables are 4 bytes aligned
  int TranslatedTable = i32[4] / 4;

  // Read original table
  sStrings.reserve(count * 2);
  for(int i = count; --i >= 0; )
  {
    // Get original string
    int keyLength = i32[keyTable++];
    int keyOffset = i32[keyTable++];
    if ((keyOffset >= (int)sMoFlatFile.size()) ||
        (keyOffset + keyLength >= (int)sMoFlatFile.size()))
    {
      { LOG(LogError) << "[Locale] Invalid .mo file. Index out of range"; }
      return false;
    }
    const char* key = ((char*)i32) + keyOffset;

    // Get translated string
    int transLength = i32[TranslatedTable++];
    int transOffset = i32[TranslatedTable++];
    if ((transOffset >= (int)sMoFlatFile.size()) ||
        (transOffset + transLength >= (int)sMoFlatFile.size()))
    {
      { LOG(LogError) << "[Locale] Invalid .mo file. Index out of range"; }
      return false;
    }
    const char* translated = ((char*)i32) + transOffset;

    int keySplit = 0;
    if ((keyLength >= 3) && HasPlural(key, keyLength, keySplit))
    {
      // Check consistency
      int translatedSplit = 0;
      if (!HasPlural(translated, transLength, translatedSplit))
      {
        { LOG(LogError) << "[Locale] Inconsistent plural form in .mo file. Ignored"; }
        return false;
      }

      // Add singular form
      int h1 = 0, h2 = 0;
      Hash(key, keySplit, h1, h2);
      sStrings.push_back({key, translated, keySplit, translatedSplit, h1, h2 });

      // Add plural form
      key += keySplit + 1; keyLength -= keySplit + 1;
      translated += translatedSplit + 1; transLength -= translatedSplit + 1;
      if (transLength > 0)
      {
        Hash(key, keyLength, h1, h2);
        sStrings.push_back({ key, translated, keyLength, transLength, h1, h2 });
      }
    }
    else
    {
      // Add normal strings
      int h1 = 0, h2 = 0;
      Hash(key, keyLength, h1, h2);
      sStrings.push_back({key, translated, keyLength, transLength, h1, h2 });
    }
  }

  return true;
}

bool Internationalizer::BuildFastLookupIndexes()
{
  int count = (int)sStrings.size();
  if (count == 0) return false;

  for(int i = sIndexCount; --i >= 0; )
    sIndexes[i] = { -1, 0 };
  unsigned int previousChar = (unsigned char)sStrings[count - 1].KeyString[0];

  for(int i = count; --i >= 0; )
  {
    unsigned int currentChar = (unsigned char)sStrings[i].KeyString[0];
    sIndexes[currentChar].Count++;
    if (currentChar != previousChar)
      sIndexes[previousChar].FirstIndex = i + 1;
    previousChar = currentChar;
  }

  return true;
}

bool Internationalizer::LoadMoFile(const std::string& culture, const Path& basepath, const std::string& applicationname)
{
  // Check full culture
  std::string realCulture = culture;
  Path culturePath = basepath / realCulture / "LC_MESSAGES" / (applicationname + ".mo");
  if (!culturePath.Exists())
  {
    // Log
    { LOG(LogWarning) << "[Locale] " << culturePath.ToString() << " not found."; }
    // Try to compose language only
    if (realCulture.size() > 2)
      culturePath = basepath / (realCulture = realCulture.substr(0, 2)) / "LC_MESSAGES" / (applicationname + ".mo");

    // Final check
    if (!culturePath.Exists())
    {
      { LOG(LogWarning) << "[Locale] " << culturePath.ToString() << " not found."; }
      return false;
    }
  }

  // Load file
  { LOG(LogInfo) << "[Locale] Using " << culturePath.ToString(); }
  sActiveLocale = realCulture;
  sMoFlatFile = Files::LoadFile(culturePath);
  return BuildStringIndexes();
}

bool Internationalizer::InitializeLocale(const std::string& culture, const std::vector<Path>& basepath, const std::string& applicationname)
{
  CleanUp();

  // Check culture
  for(const Path& path : basepath)
    if (LoadMoFile(culture, path, applicationname))
      return BuildFastLookupIndexes();

  // Check default 'en_US'
  for(const Path& path : basepath)
    if (LoadMoFile("en_US", path, applicationname))
      return BuildFastLookupIndexes();

  return false;
}

std::string Internationalizer::GetText(const char* key, int keyLength)
{
  // Null ?
  if (key == nullptr) return std::string();

  // No locale?
  if (sMoFlatFile.empty()) return std::string(key, keyLength);

  // Get index
  const StringSet& set = sIndexes[(unsigned char)key[0]];
  int index = set.FirstIndex;
  // Valid ?
  if (index >= 0)
  {
    int hash1 = 0, hash2 = 0;
    Hash(key, keyLength, hash1, hash2);
    for (int i = set.Count; --i >= 0;)
    {
      const StringPairLinks& Link = sStrings[index + i];
      if (Link.KeyLength == keyLength)
        if (Link.Hash1 == hash1)
          if (Link.Hash2 == hash2)
            //return "Yâkädansé!";
            return std::string(Link.TranslatedString, Link.TranslatedLength);
    }
  }
  { LOG(LogDebug) << "[Locale] " << sActiveLocale << " - Missing translation of '" << key << "'"; }
  return std::string(key, keyLength);
}

/*
 * This is NOT a non-reversible and secure hash algorithm.
 * However this a simple, fast and efficient string hash algorithm.
 * To prevent collisons, a double hash is performed so that there is no
 * need to compare strings.
 */
void Internationalizer::Hash(const char* string, int length, int& hash1, int& hash2)
{
  unsigned int h1 = -length, h2 = length;
  unsigned int* i32 = (unsigned int*)string;

  // Aligned string?
  if ((((intptr_t)i32) & 3) == 0)
  {
    // Hash 4 bytes
    for (int i = length >> 2; --i >= 0;)
    {
      unsigned int value = i32[i];
      unsigned long long v1 = value * 2170698181;
      v1 ^= v1 >> 32;
      h1 = ((h1 >> 13u) | (h1 << (32u - 13u))) ^ v1;
      unsigned long long v2 = value * 73762243;
      v2 ^= v2 >> 32;
      h2 = ((h2 >> 7u) | (h2 << (32u - 7u))) ^ v2;
    }
  }
  else
  {
    // Hash 4 bytes
    for (int i = length >> 2; --i >= 0;)
    {
      unsigned int value =
        (((unsigned char*)&i32[i])[0] <<  0) |
        (((unsigned char*)&i32[i])[1] <<  8) |
        (((unsigned char*)&i32[i])[2] << 16) |
        (((unsigned char*)&i32[i])[3] << 24);
      unsigned long long v1 = value * 2170698181;
      v1 ^= v1 >> 32;
      h1 = ((h1 >> 13u) | (h1 << (32u - 13u))) ^ v1;
      unsigned long long v2 = value * 73762243;
      v2 ^= v2 >> 32;
      h2 = ((h2 >> 7u) | (h2 << (32u - 7u))) ^ v2;
    }
  }

  // Hash remaining bytes
  unsigned char* i8 = (unsigned char*)&i32[length >> 2];
  unsigned int value = 0;
  for(int i = length & 3; --i >= 0; )
    value = ((value << 8) | i8[i]);
  unsigned long long v1 = value * 2170698181;
  v1 ^= v1 >> 32;
  h1 = ((h1 >> 13u) | (h1 << (32u - 13u))) ^ v1;
  unsigned long long v2 = value * 73762243;
  v2 ^= v2 >> 32;
  h2 = ((h2 >> 7u) | (h2 << (32u - 7u))) ^ v2;

  // Store final hashes
  hash1 = (int)h1;
  hash2 = (int)h2;
}

void Internationalizer::CleanUp()
{
  sActiveLocale.clear();
  memset(sIndexes, 0, sizeof(sIndexes));
  sStrings.clear();
  sMoFlatFile.clear();
}
