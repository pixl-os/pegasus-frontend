#pragma once
#ifndef ES_CORE_UTILS_STRING_UTIL_H
#define ES_CORE_UTILS_STRING_UTIL_H

#include <string>
#include <vector>

class Strings
{
  private:
    //! Limit to 16bits unicode
    static constexpr int sUnicodeSize = 0x10000;

    static unsigned short sSmallToCapital[1 << (8 * sizeof(unsigned short))];
    static unsigned short sCapitalToSmall[1 << (8 * sizeof(unsigned short))];

    static bool sInitialized;

    static bool sInitialize();

  public:
    typedef std::vector<std::string> Vector;

    static unsigned int UpperChar(const std::string& utf8string)
    {
      int dummy = 0;
      unsigned int unicode = chars2Unicode(utf8string, dummy);
      if (unicode < sUnicodeSize) return sSmallToCapital[unicode] == 0 ? unicode : sSmallToCapital[unicode];
      return unicode;
    }

    static unsigned int LowerChar(const std::string& utf8string)
    {
      int dummy = 0;
      unsigned int unicode = chars2Unicode(utf8string, dummy);
      if (unicode < sUnicodeSize) return sCapitalToSmall[unicode] == 0 ? unicode : sCapitalToSmall[unicode];
      return unicode;
    }

    static unsigned int UpperChar(unsigned int unicode)
    {
      if (unicode < sUnicodeSize) return sSmallToCapital[unicode] == 0 ? unicode : sSmallToCapital[unicode];
      return unicode;
    }

    static unsigned int LowerChar(unsigned int unicode)
    {
      if (unicode < sUnicodeSize) return sCapitalToSmall[unicode] == 0 ? unicode : sCapitalToSmall[unicode];
      return unicode;
    }

    static unsigned int chars2Unicode(const std::string& _string, int& _cursor);

    static std::string unicode2Chars(unsigned int _unicode);

    static size_t nextCursor(const std::string& _string, size_t _cursor);

    static size_t prevCursor(const std::string& _string, size_t _cursor);

    static size_t moveCursor(const std::string& _string, size_t _cursor, int _amount);

    static int CountChar(const std::string& source, char c);

    static std::string ToLowerUTF8(const std::string& _string);

    static std::string ToUpperUTF8(const std::string& _string);

    static std::string ToLowerASCII(const std::string& _string);

    static std::string ToUpperASCII(const std::string& _string);

    static std::string Trim(const std::string& _string);

    static std::string Trim(const std::string& _string, const char* _trimwhat);

    static std::string Replace(const std::string& _string, const std::string& _replace, const std::string& _with);

    static void ReplaceAllIn(std::string& _string, const std::string& _replace, const std::string& _with);

    static void ReplaceAllIn(std::string& _string, char _replace, const char* _with, int _withlength);

    static std::string Extract(const std::string& source, const char* starttag, const char* endtag, int starttagl, int endtagl);

    static bool StartsWith(const std::string& _string, const std::string& _start);

    static bool StartsWith(const std::string& _string, const char* _start, int length);

    static bool EndsWith(const std::string& _string, const std::string& _end);

    static std::string RemoveParenthesis(const std::string& _string);

    static Vector Split(const std::string& _string, char splitter, bool multipleSplittersAsOne = false);

    static std::string Join(const std::vector<std::string>& _string, const std::string& joiner);

    static std::string Join(const std::vector<const char*>& _string, const std::string& joiner);

    static std::string Format(const char* _string, ...);

    static std::string ScrambleSymetric(const std::string& _input, const std::string& key);

    static std::string ScrambleSymetric2(const std::string& _input, const std::string& key);

    static bool ToInt(const std::string& source, int index, char stop, int& out);

    static bool ToInt(const std::string& source, int index, int& out) { return ToInt(source, index, 0, out); }

    static bool ToInt(const std::string& source, int& out) { return ToInt(source, 0, 0, out); }

    static bool ToLong(const std::string& source, int index, char stop, long long int& out);

    static bool ToLong(const std::string& source, int index, long long int& out) { return ToLong(source, index, 0, out); }

    static bool ToLong(const std::string& source, long long int& out) { return ToLong(source, 0, 0, out); }

    static bool ToFloat(const std::string& source, int index, char stop, float& out);

    static bool ToFloat(const std::string& source, int index, float& out) { return ToFloat(source, index, 0, out); }

    static bool ToFloat(const std::string& source, float& out) { return ToFloat(source, 0, 0, out); }

    static bool ToBool(const std::string& source, int index, char stop, bool& out);

    static bool ToBool(const std::string& source, int index, bool& out) { return ToBool(source, index, 0, out); }

    static bool ToBool(const std::string& source, bool& out) { return ToBool(source, 0, 0, out); }

    static bool HexToInt(const std::string& from, int index, char stop, int& out);

    static bool HexToInt(const std::string& from, int index, int& out) { return HexToInt(from, index, 0, out); }

    static bool HexToInt(const std::string& from, int& out) { return HexToInt(from, 0, 0, out); }

    static std::string ToString(bool value);

    static std::string ToString(int value);

    static std::string ToString(unsigned int value);

    static std::string ToString(long long value);

    static std::string ToString(unsigned long long value);

    static std::string ToString(float value, int precision);

    static int ToHash(const std::string& string);

    static int ToHash(const char* string);

    static unsigned long long ToHash64(const std::string& string);

    static unsigned long long ToHash64(const char* string);

    static std::string ToHexa(int hex);

    static std::string ToHexa(long long hex);

    static std::string ToHexa(int hex, int length);

    static std::string ToHexa(long long hex, int length);

    static std::string URLEncode(const std::string& source);

    static std::string UnicodeToUtf8(const std::vector<unsigned int>& unicodes);

    static std::vector<unsigned int> Utf8ToUnicode(const std::string& utf8);
};

#endif // ES_CORE_UTILS_STRING_UTIL_H
