#pragma once

#include <string>
#include <map>

class StringMapFile
{
  private:
    //! Path of map file
    std::string mPath;
    //! Map of simple key/values
    std::map<std::string, std::string> mMap;

  public:
    /*!
     * @brief Constructor
     * @param path target file path
     */
    explicit StringMapFile(const std::string& path)
      : mPath(path),
        mMap()
    {
    }

    /*!
     * @brief Load file's keys and values into our internal map
     */
    void Load();

    /*!
     * @brief Save internal map contents into file as 'key=value'
     */
    void Save();

    /*!
     * @brief Lookup a key into ou map and return the appropriate value
     * @param key Key to lookup
     * @param defaultvalue default value if the key does not exist in the map
     * @return Value associated to the key, or default value if the key does not exists
     */
    std::string GetString(const std::string& key, const std::string& defaultvalue);

    /*!
     * @brief Lookup a key into ou map and return the appropriate value
     * @param key Key to lookup
     * @param defaultvalue default value if the key does not exist in the map
     * @return Value associated to the key, or default value if the key does not exists
     */
    int GetInt(const std::string& key, int defaultvalue);

    /*!
     * @brief Lookup a key into ou map and return the appropriate value
     * @param key Key to lookup
     * @param defaultvalue default value if the key does not exist in the map
     * @return Value associated to the key, or default value if the key does not exists
     */
    bool GetBool(const std::string& key, bool defaultvalue);

    /*!
     * @brief Set the value for the given key
     * @param key Key
     * @param value Value to set
     */
    void SetString(const std::string& key, const std::string& value);

    /*!
     * @brief Set the value for the given key
     * @param key Key
     * @param value Value to set
     */
    void SetInt(const std::string& key, int value);

    /*!
     * @brief Set the value for the given key
     * @param key Key
     * @param value Value to set
     */
    void SetBool(const std::string& key, bool value);
};

