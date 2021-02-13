//
// Created by bkg2k on 15/01/2020.
//
#pragma once

#include <vector>
#include <string>
#include <utils/os/fs/Path.h>

class Internationalizer
{
  private:
    static constexpr int sIndexCount = 256;

    //! String set descriptor: Index + count
    struct StringSet
    {
      int FirstIndex; //!< First index in the index  list
      int Count;      //!< Number of index available for this byte/char
    };

    //! String links in MO file w/ hash
    struct StringPairLinks
    {
      const char* KeyString;        //!< Pointer to Key string
      const char* TranslatedString; //!< Pointer to Translated string
      int KeyLength;                //!< Key String length
      int TranslatedLength;         //!< Translated String length
      int Hash1;                    //!< Key String first hash
      int Hash2;                    //!< Key String second hash
    };

    //! Contains the raw .mo file
    static std::string sMoFlatFile;

    //! Key string links
    static std::vector<StringPairLinks> sStrings;

    /*!
     * @brief Provide direct access to a string set from a string's first-char.
     * Since english is the main key language, only ASCII7 printable char indexes are stored here.
     */
    static StringSet sIndexes[sIndexCount];

    //! Active locale
    static std::string sActiveLocale;

    /*!
     * @brief Double Hash the given string and return both hash value as an integer
     * @param string String to hash
     * @param length String length
     * @param hash1 First hash result
     * @param hash2 Second hash result
     */
    static void Hash(const char* string, int length, int& hash1, int& hash2);

    /*!
     * @brief Load .mo file, regarding the application name
     * @param culture Requested culture
     * @param basepath Base path where to lookup for localized file
     * @param applicationname Application name
     * @return True if a corresponding .mo has been loaded
     */
    static bool LoadMoFile(const std::string& culture, const Path& basepath, const std::string& applicationname);

    /*!
     * @brief Build string indexes of all available strings and translations
     * @return
     */
    static bool BuildStringIndexes();

    /*!
     * @brief Build fast lookup indexes to the loaded .mo file
     * @return True if the indexes have been built properly
     */
    static bool BuildFastLookupIndexes();

    /*!
     * @brief Check if a string contains a NUL and return the NUL position
     * @param string string to check
     * @param length original length
     * @param newlength new length or 0 if not found
     * @return True if a NUL has been found
     */
    static bool HasPlural(const char* string, int length, int& newlength);

    /*!
     * @brief Clean up any previous data when reloading
     */
    static void CleanUp();

  public:
    /*!
     * @brief Initialize .mo file, regarding the application name
     * @param culture Requested culture
     * @param basepath Base path where to lookup for localized file
     * @param applicationname Application name
     * @return True if a corresponding .mo has been loaded
     */
    static bool InitializeLocale(const std::string& culture, const std::vector<Path>& basepath, const std::string& applicationname);

    /*!
     * @brief Get text from the key
     * @param key Key
     * @param keyLength Ley lencgth in bytes
     * @return String
     */
    static std::string GetText(const char* key, int keyLength);

    /*!
     * @brief Get text from the singular or plural key, regarding the given count
     * @param count Count
     * @param keysingular Key to retrieve the string from when count <= 1
     * @param keyplural Key to retrieve the string from when count > 1
     * @return String
     */
    static std::string GetNText(int count, const char* keySingular, int keySingularLength, const char* keyPlural, int keyPluralLength)
    {
      return count <= 1 ? GetText(keySingular, keySingularLength) : GetText(keyPlural, keyPluralLength);
    }
};
