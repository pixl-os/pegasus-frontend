//
// Created by bkg2k on 18/07/22.
//
// As part of the RECALBOX Project
// http://www.recalbox.com
//
#pragma clang diagnostic push
#pragma ide diagnostic ignored "bugprone-macro-parentheses"
#pragma ide diagnostic ignored "HidingNonVirtualFunction"
#pragma ide diagnostic ignored "google-explicit-constructor"
#pragma once

//! Disable implicit construction from string (copy or move)
//#define NO_STD_STRING_AUTOBOXING

#include <string>
#include <vector>
#include <cstring>
#include <stdint.h>

#define LEGACY_STRING(x) x, (int)sizeof(x)-1

class String;

/*!
 * @brief Strings statics moved in this class
 * to hide them from debuggers
 */
class StringStatics
{
  protected:
    //! Largest type usable for fast memory operations
    #if (__WORDSIZE == 64)
    typedef unsigned long long LargestType;
    static constexpr int sLargestTypeBits = 3;
    #else
    typedef unsigned int LargestType;
      static constexpr int sLargestTypeBits = 2;
    #endif
    static constexpr int sLargestTypeSize = sizeof(LargestType);
    static constexpr int sLargestTypeMask = sLargestTypeSize - 1;

    //! Max int digits (10) + sign + TZ
    static constexpr int sMaxInt32Digits = 12;
    //! Max long long digits (20) + sign + TZ
    static constexpr int sMaxInt64Digits = 22;
    //! Max float digits (64) + sign
    static constexpr int sMaxFloatDigits = 64;
    //! Max double digits (128) + sign
    static constexpr int sMaxDoubleDigits = 128;
    //! Max hexadecimal int digits (8) + sign + max prefix size (2) + TZ
    static constexpr int sMaxInt32HexaDigits = 12;
    //! Max hexadecimal long long digits (16) + sign + max prefix size (2) + TZ
    static constexpr int sMaxInt64HexaDigits = 20;
    //! Default precision (fractional part max length) for floating point type conversion
    static constexpr int sDefaultFractionalPrecision = 2;
    //! Maximum char required for unicode encoding
    static constexpr int sUnicodeMaxChar= 4;

    //! Char array to receive int values
    typedef char Int32Storage[sMaxInt32Digits];
    //! Char array to receive long long values
    typedef char Int64Storage[sMaxInt64Digits];
    //! Char array to receive int values
    typedef char Int32HexaStorage[sMaxInt32HexaDigits];
    //! Char array to receive long long values
    typedef char Int64HexaStorage[sMaxInt64HexaDigits];
    //! Char array to receive float values
    typedef char FloatStorage[sMaxFloatDigits];
    //! Char array to receive double values
    typedef char DoubleStorage[sMaxDoubleDigits];
    //! Char array to receive double values
    typedef char UnicodeStorage[sUnicodeMaxChar];

    //! Default trimmed chars
    static const String sDefaultTrimmedChar;

    //! Limit to 16bits unicode
    static constexpr int sUnicodeArraySize = 0x10000;
    //! Unicode 16 type
    typedef unsigned short Unicode16;
    //! Translation array type
    typedef Unicode16 Unicode16Array[sUnicodeArraySize];
    //! Small to capital unicode translation array (to upper)
    static Unicode16Array sSmallToCapital;
    //! Capital to small unicode translation array (to lower)
    static Unicode16Array sCapitalToSmall;

    //! Static creation holder (force the compiler to call Initialize())
    static bool sInitialized;
    //! Static conversion array creation
    static bool InitializeUTF8Tables();

  public:
    //! Empty reference - Use it as parameter instead of "" which cause a new string creation
    static const String Empty;
    static const char CR;
    static const char LF;
    static const String CRLF;
};

/*!
 * @brief An extended string class
 */
class String : public std::string
             , public StringStatics
{
  public:
    /*!
     * @brief Option class for Formatting class
     * Every instance holds a single options type and value
     */
    class FormatOption
    {
      public:
        //! Default fractional part
        static constexpr int sFractionalPartDefaultSize = 2;
        //! Default hexadecimal length, including leading zeroes
        static constexpr int sHexadecimalSizeDefaultSize = 8;
        //! Option types
        enum Type
        {
          Frac, //!< Fractional part size of float/double
          Hexa, //!< Minimum size hexadecimal numbers
        };

        /*!
         * @brief Constructor to explicitly modify an option
         * @param type Option type
         * @param value Value
         */
        FormatOption(Type type, int value)
          : mType(type)
          , mValue(value)
        {
        }

        /*!
         * @brief Constructor to explicitly reset an option to its default value
         * @param type Option type
         */
        explicit FormatOption(Type type)
          : mType(type)
        {
          switch(type)
          {
            case Frac: mValue = sFractionalPartDefaultSize; break;
            case Hexa: mValue = sHexadecimalSizeDefaultSize; break;
            default: break;
          }
        }

      private:
        //! Option type
        Type mType;
        //! Option value
        int mValue;

        //! Give access to private members to format class
        friend class String;
    };

    /*!
     * @brief Simple text formatting class
     * Usage:
     *   Format string may contain placeholders for arguments, injected using '/' and '%' operators.
     *   Placeholders are in the form '{X}' where X is the index of the placeholder, starting from 0.
     *   Values are indexed in the exact order they are injected using '/' and '%'
     *
     *   Numeric values are always represented in numeric formats, except char & uchar which are represented
     *   as ascii char.
     *   Boolean values are represented as 0/1.
     *
     *   If there are more placeholders than injected values, remaining placeholders are not replaced.
     *   If there are more values than placeholders, remaining values are not used
     *   Special operator '()' get the resulting string as well as ToString() method
     *
     *   Maximum supported index: 100 (0..99)
     *
     *   Examples:
     *   (_F("Log: {0}") / logText)();
     */
    class Format
    {
      public:
        /*!
         * @brief Build a new format class using a format string as std::string
         * @param format Format string
         */
        explicit Format(const std::string& format)
          : mFormat(format)
          , mFracSize(FormatOption::sFractionalPartDefaultSize)
          , mHexaSize(FormatOption::sHexadecimalSizeDefaultSize)
          , mIndex(0)
        {
        }

        /*!
         * @brief Build a new format class using a format string as char*
         * @param format Format string
         */
        explicit Format(const char* format)
          : mFormat(format)
          , mFracSize(FormatOption::sFractionalPartDefaultSize)
          , mHexaSize(FormatOption::sHexadecimalSizeDefaultSize)
          , mIndex(0)
        {
        }

        /*!
         * @brief Inject a new value in the parameter list
         * @param value Long long value
         * @return This
         */
        Format& operator / (long long value) { return Replace(String(value)); }
        /*!
         * @brief Inject a new value in the parameter list
         * @param value Unsigned long long value
         * @return This
         */
        Format& operator / (unsigned long long value) { return Replace(String(value)); }
        /*!
         * @brief Inject a new value in the parameter list
         * @param value Unsigned int value
         * @return This
         */
        Format& operator / (int value) { return Replace(String(value)); }
        /*!
         * @brief Inject a new value in the parameter list
         * @param value Int value
         * @return This
         */
        Format& operator / (unsigned int value) { return Replace(String(value)); }
        /*!
         * @brief Inject a new value in the parameter list
         * @param value Char value
         * @return This
         */
        Format& operator / (char value) { return Replace(String(value)); }
        /*!
         * @brief Inject a new value in the parameter list
         * @param value Unsigned char value
         * @return This
         */
        Format& operator / (unsigned char value) { return Replace(String(value)); }
        /*!
         * @brief Inject a new value in the parameter list
         * @param value String value as const char*
         * @return This
         */
        Format& operator / (const char* value) { return Replace(value); }
        /*!
         * @brief Inject a new value in the parameter list
         * @param value String value as std::string
         * @return This
         */
        Format& operator / (const String& value) { return Replace(value); }
        /*!
         * @brief Inject a new value in the parameter list
         * @param value Boolean value
         * @return This
         */
        Format& operator / (bool value) { return Replace(String(value)); }
        /*!
         * @brief Inject a new value in the parameter list
         * @param value Float value
         * @return This
         */
        Format& operator / (float value) { return Replace(String(value, mFracSize)); }
        /*!
         * @brief Inject a new value in the parameter list
         * @param value Double value
         * @return This
         */
        Format& operator / (double value) { return Replace(String(value, mFracSize)); }

        /*!
         * @brief Inject a new value in the parameter list, represented in hexadecimal
         * @param value Long long value
         * @return This
         */
        Format& operator % (long long value) { return Replace(String::ToHexa(value, mHexaSize, Hexa::None)); }
        /*!
         * @brief Inject a new value in the parameter list, represented in hexadecimal
         * @param value Int value
         * @return This
         */
        Format& operator % (int value) { return Replace(String::ToHexa(value, mHexaSize, Hexa::None)); }
        /*!
         * @brief Inject a new value in the parameter list, represented in hexadecimal
         * @param value Unsigned long long value
         * @return This
         */
        Format& operator % (unsigned long long value) { return Replace(String::ToHexa(value, mHexaSize, Hexa::None)); }
        /*!
         * @brief Inject a new value in the parameter list, represented in hexadecimal
         * @param value Unsigned int value
         * @return This
         */
        Format& operator % (unsigned int value) { return Replace(String::ToHexa(value, mHexaSize, Hexa::None)); }

        /*!
         * @brief Inject an option modifier. This is not a value, it only modify an option for next parameters
         * @param o Option class
         * @return This
         */
        Format& operator / (const FormatOption& o)
        {
          switch(o.mType)
          {
            case FormatOption::Frac: mFracSize = o.mValue; break;
            case FormatOption::Hexa: mHexaSize = o.mValue; break;
            default: break;
          }
          return *this;
        }

        /*!
         * @brief Return the formatted string
         * @return Formatted string
         */
        [[nodiscard]] const String& operator () () const { return *((String*)&mFormat); }

        /*!
         * @brief Return the formatted string
         * @return Formatted string
         */
        [[nodiscard]] String ToString() const { return *((String*)&mFormat); }

      private:
        //! Format & formatted string
        std::string mFormat;
        //! Fractional size for float values
        int mFracSize;
        //! Length (including leading zeroes) for hexadecimal values
        int mHexaSize;
        //! Next injected index
        int mIndex;

        /*!
         * @brief Replace all current index's placeholders with the given item
         * @param item Placeholder replacement as string
         * @return This
         */
        Format& Replace(const String& item)
        {
          const char* p = mFormat.data();
          for(int start = (int)mFormat.find('{'); start != (int)std::string::npos; start = (int)mFormat.find('{', start + 1))
          {
            if (start > 0 && p[start - 1] == '\'') continue; // escaped {
            int offset = 0;
            int index = p[start + 1] - 0x30;
            if ((unsigned int)index > 9) continue; // first char is not a digit
            int index2 = p[start + 2] - 0x30;
            if ((unsigned int)index2 <= 9) { index = index * 10 + index2; ++offset; } // index 2nd char
            if (p[start + 2 + offset] != '}') continue; // end char must be '}'

            if (index == mIndex) // Current index?
            {
              mFormat.replace(start, 3 + offset, item);
              p = mFormat.data(); // Replace can move the string, take the pointer again
              start += (int)item.size() - 1; // Move X step forward and one step backward to eliminate the replaced '{'
            }
          }

          mIndex++;
          return *this;
        }
    };

    //! List type
    typedef std::vector<String> List;
    //! Unicode
    typedef unsigned int Unicode;
    //! Unicode list type
    typedef std::vector<Unicode> UnicodeList;

    //! Hexadecimal prefix
    enum class Hexa
    {
      None, //!< No prefix
      C   , //!< 0x prefix
      Asm , //!< Old Asm prefix $
    };

    //! Bidirectional insert parameter check
    #define __AtCheck__ do{ if (at > Count()) at = Count(); else { if (at < 0) at += Count(); if (at < 0) at = 0; } }while(false)

    /*
     * Constructors & destructor
     */

    //! Default constructor
    String() : std::string() { (void)sInitialized; }

    /*!
     * @brief Build a string from a c-string
     * @param source c-string
     */
    String(const char* source) : std::string(source) {}

    /*!
     * @brief Build a string from an initializer list of char
     * @param il initializer list
     */
    String(std::initializer_list<char> il) : std::string(il) {}

    /*!
     * @brief Build a string from a part of a source string
     * @param source Source string
     * @param from Start character from which to build the new string
     */
    String(const String& source, int from) : std::string(source, (size_t)from) {}
    /*!
     * @brief Build a string from a part of a source string
     * @param source Source string
     * @param from Start character from which to build the new string
     * @param length Number of character to take in the new string
     */
    String(const String& source, int from, int length) : std::string(source, (size_t)from, (size_t)length) {}
    /*!
     * @brief Build a string from a part of a source std::string
     * @param source Source string
     * @param from Start character from which to build the new string
     */
    String(const std::string& source, int from) : std::string(source, (size_t)from) {}
    /*!
     * @brief Build a string from a part of a source std::string
     * @param source Source string
     * @param from Start character from which to build the new string
     * @param length Number of character to take in the new string
     */
    String(const std::string& source, int from, int length) : std::string(source, (size_t)from, (size_t)length) {}

    /*!
     * @brief Build a string from a part of a source c-string
     * @param source Source string
     * @param length Number of character to take in the new string
     */
    String(const char* source, int length) : std::string(source, (size_t)length) {}
    /*!
     * @brief Build a string from a part of a source c-string
     * @param source Source string
     * @param from Start character from which to build the new string
     * @param length Number of character to take in the new string
     */
    String(const char* source, int from, int length) : std::string(source + from, (size_t)length) {}

    /*!
     * @brief Build a string from a single char
     * @param value Boolean value
     */
    explicit String(bool value) : std::string(1, value ? '1' : '0') {}
    /*!
     * @brief Build a string from a single char
     * @param value Boolean value
     *
     */
    explicit String(bool value, bool text) : std::string() { if (text) { if (value) Assign(LEGACY_STRING("true")); else Assign(LEGACY_STRING("false")); } else Assign(value ? '1' : '0'); }

    /*!
     * @brief Build a string from a single char
     * @param singleChar Char
     */
    explicit String(char singleChar) : std::string(1, singleChar) {}
    /*!
     * @brief Build a string by repeating "count" times a single char
     * @param singleChar Char to repeat
     */
    String(char singleChar, int count) : std::string(count, singleChar) {}
    /*!
     * @brief Build a string from a single unsigned char
     * @param singleChar unsigned Char
     */
    explicit String(unsigned char singleChar) : std::string(1, (char)singleChar) {}
    /*!
     * @brief Build a string by repeating "count" times a single unsigned char
     * @param singleChar Unsigned char to repeat
     */
    String(unsigned char singleChar, int count) : std::string(count, (char)singleChar) {}

    /*!
     * @brief Build a string by converting a short to its string representation
     * @param value short value
     */
    explicit String(short value) : std::string() { Int32Storage to; int l = ConvertNumeric<int, Int32Storage>((int)value, to); assign(&to[sizeof(to) - l], l); }
    /*!
     * @brief Build a string by converting an unsigned short to its string representation
     * @param value short value
     */
    explicit String(unsigned short value) : std::string() { Int32Storage to; int l = ConvertUnsignedNumeric<unsigned int, Int32Storage>((unsigned int)value, to); assign(&to[sizeof(to) - l], l); }

    /*!
     * @brief Build a string by converting an integer to its string representation
     * @param value integer value
     */
    explicit String(int value) : std::string() { Int32Storage to; int l = ConvertNumeric<int, Int32Storage>(value, to); assign(&to[sizeof(to) - l], l); }
    /*!
     * @brief Build a string by converting an unsigned integer to its string representation
     * @param value unsigned integer value
     */
    explicit String(unsigned int value) : std::string() { Int32Storage to; int l = ConvertUnsignedNumeric<unsigned int, Int32Storage>(value, to); assign(&to[sizeof(to) - l], l); }

    /*!
     * @brief Build a string by converting a long long to its string representation
     * @param value integer value
     */
    explicit String(long long value) : std::string() { Int64Storage to; int l = ConvertNumeric<long long, Int64Storage>(value, to); assign(&to[sizeof(to) - l], l); }
    /*!
     * @brief Build a string by converting an unsigned long long to its string representation
     * @param value unsigned integer value
     */
    explicit String(unsigned long long value) : std::string() { Int64Storage to; int l = ConvertUnsignedNumeric<unsigned long long, Int64Storage>(value, to); assign(&to[sizeof(to) - l], l); }

    /*!
     * @brief Build a string by converting a float to its string representation (default precision)
     * @param value float value
     */
    explicit String(float value) : std::string() { FloatStorage to; int l = ConvertFloat<float, unsigned int, FloatStorage>(value, sDefaultFractionalPrecision, to); assign(&to[sizeof(to) - l], l); }
    /*!
     * @brief Build a string by converting a double to its string representation (default precision)
     * @param value double value
     */
    explicit String(double value) : std::string() { DoubleStorage to; int l = ConvertFloat<double, unsigned long long, DoubleStorage>(value, sDefaultFractionalPrecision, to); assign(&to[sizeof(to) - l], l); }
    /*!
     * @brief Build a string by converting a float to its string representation with the given precision
     * @param value float value
     * @param precision Fractional part precision
     */
    String(float value, int precision) : std::string() { FloatStorage to; int l = ConvertFloat<float, unsigned int, FloatStorage>(value, precision, to); assign(&to[sizeof(to) - l], l); }
    /*!
     * @brief Build a string by converting a double to its string representation with the given precision
     * @param value double value
     * @param precision Fractional part precision
     */
    String(double value, int precision) : std::string() { DoubleStorage to; int l = ConvertFloat<double, unsigned long long, DoubleStorage>(value, precision, to); assign(&to[sizeof(to) - l], l); }

    /*!
     * @brief Build a string by repeating an unicode character
     * @param unicode Unicode character to fill the string with
     * @param count Repeat the unicode character "count" times
     */
    String(Unicode unicode, int count) : std::string() { for(; --count >= 0;) AppendUTF8(unicode); }

    /*!
     * @brief Build a string using the output of a Format class
     * @param format Format class
     */
    explicit String(const Format& format) : std::string(format.ToString()) {}

    //! Copy constructor
    String(const String& source) = default;
    #ifdef NO_STD_STRING_AUTOBOXING
    //! Copy constructor from base string
    String(const std::string& source) = delete;
    #else
    //! Copy constructor from base string
      String(const std::string& source) : std::string(source) {}
    #endif

    //! Move constructor
    String(String&& source) noexcept = default;
    #ifdef NO_STD_STRING_AUTOBOXING
    //! Move constructor from base string
    String(std::string&& source) noexcept = delete;
    #else
    //! Move constructor from base string
      String(std::string&& source) noexcept : std::string(source) {}
    #endif

    //! Default destructor
    ~String() = default;

    /*!
     * @brief Build a string from a signed int value conversion
     * @param value Value to convert
     * @param prefix Hexadecimal prefix
     * @return Hexadecimal string
     */
    String(int value, Hexa prefix) : std::string() { Int32HexaStorage to; int l = ConvertNumericToHexa<int>(value, 0, to, prefix); Assign(&to[sizeof(to) - l], l); }
    /*!
     * @brief Build a string from a signed long long value conversion
     * @param value Value to convert
     * @param prefix Hexadecimal prefix
     * @return Hexadecimal string
     */
    String(long long value, Hexa prefix) : std::string() { Int64HexaStorage to; int l = ConvertNumericToHexa<long long>(value, 0, to, prefix); Assign(&to[sizeof(to) - l], l); }
    /*!
     * @brief Build a string from a signed int value conversion
     * @param value Value to convert
     * @param minsize Minimum size of hexadecimal representation. Conversion may add leading zeroes if required
     * @param prefix Hexadecimal prefix
     * @return Hexadecimal string
     */
    String(int value, int minsize, Hexa prefix) : std::string() { Int32HexaStorage to; int l = ConvertNumericToHexa<int>(value, minsize, to, prefix); Assign(&to[sizeof(to) - l], l); }
    /*!
     * @brief Build a string from a signed long long value conversion
     * @param value Value to convert
     * @param minsize Minimum size of hexadecimal representation. Conversion may add leading zeroes if required
     * @param prefix Hexadecimal prefix
     * @return Hexadecimal string
     */
    String(long long value, int minsize, Hexa prefix) : std::string() { Int64HexaStorage to; int l = ConvertNumericToHexa<long long>(value, minsize, to, prefix); Assign(&to[sizeof(to) - l], l); }

    /*!
     * @brief Build a string from an unsigned int value conversion
     * @param value Value to convert
     * @param prefix Hexadecimal prefix
     * @return Hexadecimal string
     */
    String(unsigned int value, Hexa prefix) : std::string() { Int32HexaStorage to; int l = ConvertUnsignedNumericToHexa<unsigned int>(value, 0, to, prefix); Assign(&to[sizeof(to) - l], l); }
    /*!
     * @brief Build a string from an unsigned long long value conversion
     * @param value Value to convert
     * @param prefix Hexadecimal prefix
     * @return Hexadecimal string
     */
    String(unsigned long long value, Hexa prefix) : std::string() { Int64HexaStorage to; int l = ConvertUnsignedNumericToHexa<unsigned long long>(value, 0, to, prefix); Assign(&to[sizeof(to) - l], l); }
    /*!
     * @brief Build a string from an unsigned int value conversion
     * @param value Value to convert
     * @param minsize Minimum size of hexadecimal representation. Conversion may add leading zeroes if required
     * @param prefix Hexadecimal prefix
     * @return Hexadecimal string
     */
    String(unsigned int value, int minsize, Hexa prefix) : std::string() { Int32HexaStorage to; int l = ConvertUnsignedNumericToHexa<unsigned int>(value, minsize, to, prefix); Assign(&to[sizeof(to) - l], l); }
    /*!
     * @brief Build a string from an unsigned long long value conversion
     * @param value Value to convert
     * @param minsize Minimum size of hexadecimal representation. Conversion may add leading zeroes if required
     * @param prefix Hexadecimal prefix
     * @return Hexadecimal string
     */
    String(unsigned long long value, int minsize, Hexa prefix) : std::string() { Int64HexaStorage to; int l = ConvertUnsignedNumericToHexa<unsigned long long>(value, minsize, to, prefix); Assign(&to[sizeof(to) - l], l); }

    /*
     * Methods
     */

    // UTF8

    /*!
     * @brief Count UTF8 characters in a string, counting multi-char encoded unicode characters as one character
     * @return Unicode character count
     */
    [[nodiscard]] int CountUtf8() const { int count = 0; for(int pos = 0; pos < Count(); ++count) DecodeUTF8Char(pos); return count; }

    /*!
     * @brief Read unicode character at the given position
     * Subsequent calls update the position until it reaches the end of the string
     * @param[in,out] position Position to read unicode character from. Position is updated to the next character position.
     * @return Unicode character
     */
    [[nodiscard]] Unicode ReadFirstUTF8() const { int pos = 0; return ReadUTF8(pos); }

    /*!
     * @brief Read unicode character at the given position
     * Subsequent calls update the position until it reaches the end of the string
     * @param[in,out] position Position to read unicode character from. Position is updated to the next character position.
     * @return Unicode character
     */
    Unicode ReadUTF8(int& position) const { return position < Count() ? DecodeUTF8Char(position) : 0; }

    /*!
     * @brief Replace the whole content of this string with the value of the given unicode character
     * @param source Unicode character
     * @return This
     */
    String& AssignUTF8(Unicode unicode) { clear(); AppendUTF8(unicode); return *this; }

    /*!
     * @brief Replace the whole content of this string with the value of the given unicode character repeated count times
     * @param source Unicode character
     * @param count Repeat counter
     * @return This
     */
    String& AssignUTF8(Unicode unicode, int count) { clear(); for(; --count >= 0; ) AppendUTF8(unicode); return *this; }

    /*!
     * @brief Encode an unicode character in one or more chars and then append those chars to the current string
     * @param unicode Unicode character to encode & append
     * @return This
     */
    String& AppendUTF8(Unicode unicode) { UnicodeStorage to; int l = EncodeUTF8Char(unicode, to); Append(to, l); return *this; }

    /*!
     * @brief Encode an unicode character in one or more chars and then append those chars to the current string
     * @param unicode Unicode character to encode & append
     * @param count Repeat counter
     * @return This
     */
    String& AppendUTF8(Unicode unicode, int count) { UnicodeStorage to; for(int l = EncodeUTF8Char(unicode, to); --count >= 0; ) Append(to, l); return *this; }

    /*!
     * @brief Encode an unicode character in one or more chars and then insert those chars into the current string
     * at the given position "at" (expressed in unicode character)
     * @param at Position where to insert chars
     * @param unicode Unicode character to encode & append
     * @return This
     */
    String& InsertUTF8(int at, Unicode unicode) { int position = MoveUTF8(at >= 0 ? 0 : Count(), at); UnicodeStorage to; Insert(position, to, EncodeUTF8Char(unicode, to)); return *this; }
    /*!
     * @brief Encode an unicode character in one or more chars and then insert those chars into the current string
     * at the given position "at" (expressed in unicode character)
     * @param at Position where to insert chars
     * @param unicode Unicode character to encode & append
     * @param count Repeat counter
     * @return This
     */
    String& InsertUTF8(int at, Unicode unicode, int count) { int position = MoveUTF8(at >= 0 ? 0 : Count(), at); UnicodeStorage to; for(; --count >= 0; ) Insert(position, to, EncodeUTF8Char(unicode, to)); return *this; }

    /*!
     * @brief Convert all characters of the current string to lowercase
     * @return This
     */
    String& LowerCaseUTF8() { ChangeCaseUTF8(sCapitalToSmall); return *this; }

    /*!
     * @brief Return a lower case'd copy of the current string
     * @return Lowercase string
     */
    [[nodiscard]] String ToLowerCaseUTF8() const { return String(*this).LowerCaseUTF8(); }

    /*!
     * @brief Convert all characters of the current string to uppercase
     * @return This
     */
    String& UpperCaseUTF8() { ChangeCaseUTF8(sSmallToCapital); return *this; }

    /*!
     * @brief Return a upper-case'd copy of the current string
     * @return Uppercase string
     */
    [[nodiscard]] String ToUpperCaseUTF8() const { return String(*this).UpperCaseUTF8(); }

    /*!
     * @brief Convert an unicode to its lowercase representation when available
     * @param unicode Unicode to lower
     * @return Lowercase character or itself
     */
    static Unicode LowerUnicode(Unicode unicode) { if (unicode >> 16 != 0) return unicode; Unicode16 result = sCapitalToSmall[unicode]; return result != 0 ? result : unicode; }

    /*!
     * @brief Convert an unicode to its uppercase representation when available
     * @param unicode Unicode to upper
     * @return Uppercase character or itself
     */
    static Unicode UpperUnicode(Unicode unicode) { if (unicode >> 16 != 0) return unicode; Unicode16 result = sSmallToCapital[unicode]; return result != 0 ? result : unicode; }

    /*!
     * @brief Split the current string into an unicode character array
     * @return Unicode character array
     */
    [[nodiscard]] UnicodeList SplitUnicodes() const { UnicodeList result; for(int pos = 0; pos < Count(); ) result.push_back(DecodeUTF8Char(pos)); return result; }

    /*!
     * @brief Create a new string by joining all unicode character from the given unicode list
     * @param list Unicode character list
     * @return New string
     */
    static String JoinUnicodes(const UnicodeList& list) { String result; for(Unicode unicode : list) result.AppendUTF8(unicode); return result; }

    // Hashes

    /*!
     * @brief Return a 32bit hash of the current string
     * @return 32bit hash
     */
    [[nodiscard]] int Hash() const { return (int)MurMurHash2A(data(), Count()); }

    /*!
     * @brief Return a 32bit hash of the current string
     * @return 32bit hash
     */
    [[nodiscard]] long long Hash64() const { return (long long)MurMurHash64A(data(), Count()); }

    /*!
     * @brief Return a 32bit hash of the given c-string
     * @param string String to get hash from
     * @param length String length
     * @return 32bit hash
     */
    static int Hash(const char* string, int length) { return (int)MurMurHash2A(string, length); }

    /*!
     * @brief Return a 32bit hash of the given c-string
     * @param string String to get hash from
     * @param length String length
     * @return 32bit hash
     */
    static long long Hash64(const char* string, int length) { return (long long)MurMurHash64A(string, length); }

    /*!
     * @brief Return a 32bit hash of the given c-string
     * @param string String to get hash from
     * @return 32bit hash
     */
    static int Hash(const char* string) { return (int)MurMurHash2A(string, (int)strlen(string)); }

    /*!
     * @brief Return a 32bit hash of the given c-string
     * @param string String to get hash from
     * @return 32bit hash
     */
    static long long Hash64(const char* string) { return (long long)MurMurHash64A(string, (int)strlen(string)); }

    // Type-routed std::string substring

    /*!
     * @brief Get the substring starting at position "from"
     * @param from Start position to get string from
     * @return new string
     */
    [[nodiscard]] String SubString(int from) const { return String(*this, from); }
    /*!
     * @brief Get the substring starting at position "from" for "length" characters
     * @param from Start position to get string from
     * @param length Amount of character to get
     * @return new string
     */
    [[nodiscard]] String SubString(int from, int length) const { return String(*this, from, length); }

    // Replacers

    /*!
     * @brief Replace all occurrence of char "what" with char "with"
     * @param what Char to seek for
     * @param with Replacement char
     * @return This
     */
    String& Replace(char what, char with)
    {
      char *p = (char*)data();
      for(int pos = 0; (pos = Find(what, pos)) >= 0; ++pos)
        p[pos] = with;
      return *this;
    }
    /*!
     * @brief Replace all occurrence of char "what" with String "with"
     * @param what Char to seek for
     * @param with Replacement String
     * @return This
     */
    String& Replace(char what, const String& with) { return Replace(what, with.data(), with.Count()); }
    /*!
     * @brief Replace all occurrence of char "what" with c-string "with"
     * @param what Char to seek for
     * @param with Replacement c-string
     * @return This
     */
    String& Replace(char what, const char* with) { return Replace(what, with, (int)strlen(with)); }
    /*!
     * @brief Replace all occurrence of char "what" with size-known c-string "with"
     * @param what Char to seek for
     * @param with Replacement c-string
     * @param withLength Replacement c-string length
     * @return This
     */
    String& Replace(char what, const char* with, int withLength)
    {
      if (withLength > 0)
        for(int pos = 0; (pos = Find(what, pos)) >= 0; pos += withLength)
          replace(pos, 1, with, withLength);
      return *this;
    }

    /*!
     * @brief Replace all occurrence of String "what" with char "with"
     * @param what Char to seek for
     * @param with Replacement char
     * @return This
     */
    String& Replace(const String& what, char with) { return Replace(what.data(), what.Count(), &with, 1); }
    /*!
     * @brief Replace all occurrence of String "what" with String "with"
     * @param what Char to seek for
     * @param with Replacement String
     * @return This
     */
    String& Replace(const String& what, const String& with) { return Replace(what.data(), what.Count(), with.data(), with.Count()); }
    /*!
     * @brief Replace all occurrence of String "what" with c-string "with"
     * @param what Char to seek for
     * @param with Replacement c-string
     * @return This
     */
    String& Replace(const String& what, const char* with) { return Replace(what.data(), what.Count(), with, (int)strlen(with)); }
    /*!
     * @brief Replace all occurrence of String "what" with size-known c-string "with"
     * @param what Char to seek for
     * @param with Replacement c-string
     * @param withLength Replacement c-string length
     * @return This
     */
    String& Replace(const String& what, const char* with, int withLength) { return Replace(what.data(), what.Count(), with, withLength); }

    /*!
     * @brief Replace all occurrence of c-string "what" with char "with"
     * @param what Char to seek for
     * @param with Replacement char
     * @return This
     */
    String& Replace(const char* what, char with) { return Replace(what, (int)strlen(what), &with, 1); }
    /*!
     * @brief Replace all occurrence of c-string "what" with String "with"
     * @param what Char to seek for
     * @param with Replacement String
     * @return This
     */
    String& Replace(const char* what, const String& with) { return Replace(what, (int)strlen(what), with.data(), with.Count()); }
    /*!
     * @brief Replace all occurrence of c-string "what" with c-string "with"
     * @param what Char to seek for
     * @param with Replacement c-string
     * @return This
     */
    String& Replace(const char* what, const char* with) { return Replace(what, (int)strlen(what), with, (int)strlen(with)); }
    /*!
     * @brief Replace all occurrence of c-string "what" with size-known c-string "with"
     * @param what Char to seek for
     * @param with Replacement c-string
     * @param withLength Replacement c-string length
     * @return This
     */
    String& Replace(const char* what, const char* with, int withLength) { return Replace(what, (int)strlen(what), with, withLength); }

    /*!
     * @brief Replace all occurrence of size-known c-string "what" with char "with"
     * @param what Char to seek for
     * @param with Replacement char
     * @return This
     */
    String& Replace(const char* what, int whatLength, char with) { return Replace(what, whatLength, &with, 1); }
    /*!
     * @brief Replace all occurrence of size-known c-string "what" with String "with"
     * @param what Char to seek for
     * @param with Replacement String
     * @return This
     */
    String& Replace(const char* what, int whatLength, const String& with) { return Replace(what, whatLength, with.data(), with.Count()); }
    /*!
     * @brief Replace all occurrence of size-known c-string "what" with c-string "with"
     * @param what Char to seek for
     * @param with Replacement c-string
     * @return This
     */
    String& Replace(const char* what, int whatLength, const char* with) { return Replace(what, whatLength, with, (int)strlen(with)); }
    /*!
     * @brief Replace all occurrence of size-known c-string "what" with size-known c-string "with"
     * @param what Char to seek for
     * @param with Replacement c-string
     * @param withLength Replacement c-string length
     * @return This
     */
    String& Replace(const char* what, int whatLength, const char* with, int withLength)
    {
      if ((whatLength | withLength) > 0)
        for(int pos = 0; (pos = (int)find(what, pos, whatLength)) != (int)std::string::npos; pos += 0/*withLength*/)
          replace(pos, whatLength, with, withLength);
      return *this;
    }

    // Trimmers

    /*!
     * @brief Left trim & Right trim default characters from the current string
     * @return Trimmed string
     */
    String& Trim() { return TrimRight().TrimLeft(); }
    /*!
     * @brief Return a trimmed copy of the current string
     * @return Trimmed string
     */
    [[nodiscard]] String ToTrim() const { return String(*this).Trim(); }
    /*!
     * @brief Left trim default characters from the current string
     * @return Trimmed string
     */
    String& TrimLeft() { return TrimLeft(sDefaultTrimmedChar); }
    /*!
     * @brief Return a left-trimmed copy of the current string
     * @return Trimmed string
     */
    [[nodiscard]] String ToTrimLeft() const { return String(*this).TrimLeft(); }
    /*!
     * @brief Right trim default characters from the current string
     * @return Trimmed string
     */
    String& TrimRight() { return TrimRight(sDefaultTrimmedChar); }
    /*!
     * @brief Return a right-trimmed copy of the current string
     * @return Trimmed string
     */
    [[nodiscard]] String ToTrimRight() const { return String(*this).TrimRight(); }

    /*!
     * @brief Left trim & Right trim the given char from the current string
     * @return Trimmed string
     */
    String& Trim(char trim) { return TrimRight(trim).TrimLeft(trim); }
    /*!
     * @brief Return a trimmed copy of the current string
     * @return Trimmed string
     */
    [[nodiscard]] String ToTrim(char trim) const { return String(*this).Trim(trim); }
    /*!
     * @brief Left trim the given char from the current string
     * @return Trimmed string
     */
    String& TrimLeft(char trim)
    {
      size_t start = find_first_not_of(trim);
      if (start == std::string::npos) start = size();
      if (start > 0) erase(0, start);
      return *this;
    }
    /*!
     * @brief Return a left-trimmed copy of the current string
     * @return Trimmed string
     */
    [[nodiscard]] String ToTrimLeft(char trim) const { return String(*this).TrimLeft(trim); }
    /*!
     * @brief Right trim the given char from the current string
     * @return Trimmed string
     */
    String& TrimRight(char trim)
    {
      size_t stop = find_last_not_of(trim);
      if (stop < size() - 1) erase(stop + 1);
      return *this;
    }
    /*!
     * @brief Return a right-trimmed copy of the current string
     * @return Trimmed string
     */
    [[nodiscard]] String ToTrimRight(char trim) const { return String(*this).TrimRight(trim); }

    /*!
     * @brief Left trim & Right trim from the current string characters in the given string
     * @return Trimmed string
     */
    String& Trim(const char* trim) { return TrimRight(trim).TrimLeft(trim); }
    /*!
     * @brief Return a trimmed copy of the current string, trimming characters available in the given string
     * @return Trimmed string
     */
    String ToTrim(const char* trim) const { return String(*this).Trim(trim); }
    /*!
     * @brief Left trim from the current string characters in the given string
     * @return Trimmed string
     */
    String& TrimLeft(const char* trim)
    {
      size_t start = find_first_not_of(trim);
      if (start == std::string::npos) start = size();
      if (start > 0) erase(0, start);
      return *this;
    }
    /*!
     * @brief Return a left-trimmed copy of the current string, trimming characters available in the given string
     * @return Trimmed string
     */
    [[nodiscard]] String ToTrimLeft(const char* trim) const { return String(*this).TrimLeft(trim); }
    /*!
     * @brief Right trim from the current string characters in the given string
     * @return Trimmed string
     */
    String& TrimRight(const char* trim)
    {
      size_t stop = find_last_not_of(trim);
      if (stop == std::string::npos) stop = 0;
      if ((int)stop < (int)size() - 1) erase(stop + 1);
      return *this;
    }
    /*!
     * @brief Return a right-trimmed copy of the current string, trimming characters available in the given string
     * @return Trimmed string
     */
    [[nodiscard]] String ToTrimRight(const char* trim) const { return String(*this).TrimRight(trim); }

    /*!
     * @brief Left trim & Right trim from the current string characters in the given string
     * @return Trimmed string
     */
    String& Trim(const String& trim) { return TrimRight(trim).TrimLeft(trim); }
    /*!
     * @brief Return a trimmed copy of the current string, trimming characters available in the given string
     * @return Trimmed string
     */
    [[nodiscard]] String ToTrim(const String& trim) const { return String(*this).Trim(trim); }
    /*!
     * @brief Left trim from the current string characters in the given string
     * @return Trimmed string
     */
    String& TrimLeft(const String& trim)
    {
      size_t start = find_first_not_of(trim);
      if (start == std::string::npos) start = size();
      if (start > 0) erase(0, start);
      return *this;
    }
    /*!
     * @brief Return a left-trimmed copy of the current string, trimming characters available in the given string
     * @return Trimmed string
     */
    [[nodiscard]] String ToTrimLeft(const String& trim) const { return String(*this).TrimLeft(trim); }
    /*!
     * @brief Right trim from the current string characters in the given string
     * @return Trimmed string
     */
    String& TrimRight(const String& trim)
    {
      int stop = (int)find_last_not_of(trim);
      if (stop < (int)size() - 1) erase(stop + 1);
      return *this;
    }
    /*!
     * @brief Return a right-trimmed copy of the current string, trimming characters available in the given string
     * @return Trimmed string
     */
    [[nodiscard]] String ToTrimRight(const String& trim) const { return String(*this).TrimRight(trim); }

    // Counters

    /*!
     * @brief Get length of string as an integer
     * @return Length in char
     */
    [[nodiscard]] int Count() const { return (int)size(); }

    /*!
     * @brief Count occurrences of the given character
     * @param c Character to count occurrences
     * @return Number of occurrence of c
     */
    [[nodiscard]] int Count(char c) const { return CountCharOccurrences(c); }

    /*!
     * @brief Count occurrences of control chars (chars < 32)
     * @return Number of occurrence of control chars
     */
    [[nodiscard]] int CountControl() const { return CountControlCharOccurrences(); }

    // Search / Contains

    /*!
     * @brief Check if the string contains at least one occurrence of the given character
     * @param search Character to seek for
     * @return True if the character appears in the string at least once, false otherwise
     */
    [[nodiscard]] bool Contains(char search) const { return find(search) != std::string::npos; }
    /*!
     * @brief Check if the string contains at least one occurrence of the given c-string
     * @param search C-String to seek for
     * @return True if the c-string appears in the string at least once, false otherwise
     */
    [[nodiscard]] bool Contains(const char* search) const { return find(search) != std::string::npos; }
    /*!
     * @brief Check if the string contains at least one occurrence of the given c-string
     * @param search C-String to seek for
     * @return True if the c-string appears in the string at least once, false otherwise
     */
    [[nodiscard]] bool Contains(const char* search, int length) const { return find(search, 0, length) != std::string::npos; }
    /*!
     * @brief Check if the string contains at least one occurrence of the given string
     * @param search String to seek for
     * @return True if the string appears in the string at least once, false otherwise
     */
    [[nodiscard]] bool Contains(const String& search) const { return find(search) != std::string::npos; }

    /*!
     * @brief Check if the string starts with the given character
     * @param search Character to seek for
     * @return True if the character appears in the string at position 0, false otherwise
     */
    [[nodiscard]] bool StartsWith(char search) const { return find(search) == 0; }
    /*!
     * @brief Check if the string starts with the given c-string
     * @param search C-String to seek for
     * @return True if the c-string appears in the string at position 0, false otherwise
     */
    [[nodiscard]] bool StartsWith(const char* search) const { return find(search) == 0; }
    /*!
     * @brief Check if the string starts with the given c-string
     * @param search C-String to seek for
     * @return True if the c-string appears in the string at position 0, false otherwise
     */
    [[nodiscard]] bool StartsWith(const char* search, int length) const { return find(search, 0, length) == 0; }
    /*!
     * @brief Check if the string starts with the given string
     * @param search String to seek for
     * @return True if the string appears in the string at position 0, false otherwise
     */
    [[nodiscard]] bool StartsWith(const String& search) const { return find(search) == 0; }

    /*!
     * @brief Check if the string ends with the given character
     * @param search Character to seek for
     * @return True if the character appears in the string in last position, false otherwise
     */
    [[nodiscard]] bool EndsWith(char search) const { return find(search) == size() - 1; }
    /*!
     * @brief Check if the string ends with the given c-string
     * @param search C-String to seek for
     * @return True if the c-string appears in the string in last position, false otherwise
     */
    [[nodiscard]] bool EndsWith(const char* search) const { return EndsWith(search, (int) strlen(search)); }
    /*!
     * @brief Check if the string ends with the given c-string
     * @param search C-String to seek for
     * @return True if the c-string appears in the string in last position, false otherwise
     */
    [[nodiscard]] bool EndsWith(const char* search, int length) const { return find(search, 0, length) == size() - length; }
    /*!
     * @brief Check if the string ends with the given string
     * @param search String to seek for
     * @return True if the string appears in the string in last position, false otherwise
     */
    [[nodiscard]] bool EndsWith(const String& search) const { return find(search) == size() - search.size(); }

    /*!
     * @brief Try to locate the first position of the given character
     * @param search Character to seek for
     * @return Character position or -1 of not found
     */
    [[nodiscard]] int Find(char search) const { return (int)find(search); }
    /*!
     * @brief Try to locate the first position of the given c-string
     * @param search C-String to seek for
     * @return C-String position or -1 of not found
     */
    [[nodiscard]] int Find(const char* search) const { return (int)find(search); }
    /*!
     * @brief Try to locate the first position of the given string
     * @param search String to seek for
     * @return String position or -1 of not found
     */
    [[nodiscard]] int Find(const String& search) const { return (int)find(search); }

    /*!
     * @brief Try to locate the first position of the given character, starting from the given "from" position
     * @param search Character to seek for
     * @param from Start searching at this given index
     * @return Character position or -1 of not found
     */
    [[nodiscard]] int Find(char search, int from) const { return (int)find(search, (size_type)from); }
    /*!
     * @brief Try to locate the first position of the given c-string, starting from the given "from" position
     * @param search C-String to seek for
     * @param searchLength C-String size
     * @return C-String position or -1 of not found
     */
    [[nodiscard]] int Find(const char* search, int searchLength) const { return (int)find(search, (size_type)0, (size_type)searchLength); }
    /*!
     * @brief Try to locate the first position of the given c-string, starting from the given "from" position
     * @param search C-String to seek for
     * @param searchLength C-String size
     * @param from Start searching at this given index
     * @return C-String position or -1 of not found
     */
    [[nodiscard]] int Find(const char* search, int searchLength, int from) const { return (int)find(search, (size_type)from, (size_type)searchLength); }
    /*!
     * @brief Try to locate the first position of the given string, starting from the given "from" position
     * @param search String to seek for
     * @param from Start searching at this given index
     * @return String position or -1 of not found
     */
    [[nodiscard]] int Find(const String& search, int from) const { return (int)find(search, (size_type)from); }

    /*!
     * @brief Try to locate the first position of the given character, starting from the given "from" position
     * within the "length" characters following "from"
     * @param search Character to seek for
     * @param from Start searching at this given index
     * @param length Limit the search within the "length" characters following "from"
     * @return Character position or -1 of not found
     */
    [[nodiscard]] int Find(char search, int from, int length) const { int pos = (int)find(search, (size_type)from); return (long long)pos < (long long)from + (long long)length ? pos : -1; }
    /*!
     * @brief Try to locate the first position of the given c-string, starting from the given "from" position
     * within the "length" characters following "from"
     * @param search C-String to seek for
     * @param searchLength C-String size
     * @param from Start searching at this given index
     * @param length Limit the search within the "length" characters following "from"
     * @return C-String position or -1 of not found
     */
    [[nodiscard]] int Find(const char* search, int searchLength, int from, int length) const { int pos = (int)find(search, (size_type)from, (size_type)searchLength); return (long long)pos < (long long)from + (long long)length ? pos : -1; }
    /*!
     * @brief Try to locate the first position of the given string, starting from the given "from" position
     * within the "length" characters following "from"
     * @param search String to seek for
     * @param from Start searching at this given index
     * @param length Limit the search within the "length" characters following "from"
     * @return String position or -1 of not found
     */
    [[nodiscard]] int Find(const String& search, int from, int length) const { int pos = (int)find(search, (size_type)from); return (long long)pos < (long long)from + (long long)length ? pos : -1; }

    /*!
     * @brief Try to locate the last position of the given character
     * @param search Character to seek for
     * @return Character position or -1 of not found
     */
    [[nodiscard]] int FindLast(char search) const { return (int)rfind(search); }
    /*!
     * @brief Try to locate the last position of the given c-string
     * @param search C-String to seek for
     * @return C-String position or -1 of not found
     */
    [[nodiscard]] int FindLast(const char* search) const { return (int)rfind(search); }
    /*!
     * @brief Try to locate the last position of the given string
     * @param search String to seek for
     * @return String position or -1 of not found
     */
    [[nodiscard]] int FindLast(const String& search) const { return (int)rfind(search); }

    /*!
     * @brief Try to locate the last position of the given character, starting from the given "from" position
     * @param search Character to seek for
     * @param from Start searching at this given index
     * @return Character position or -1 of not found
     */
    [[nodiscard]] int FindLast(char search, int from) const { return (int)rfind(search, (size_type)from); }
    /*!
     * @brief Try to locate the last position of the given c-string, starting from the given "from" position
     * @param search C-String to seek for
     * @param from Start searching at this given index
     * @return C-String position or -1 of not found
     */
    [[nodiscard]] int FindLast(const char* search, int from) const { return (int)rfind(search, (size_type)from); }
    /*!
     * @brief Try to locate the last position of the given c-string, starting from the given "from" position
     * @param search C-String to seek for
     * @param searchLength C-String size
     * @param from Start searching at this given index
     * @return C-String position or -1 of not found
     */
    [[nodiscard]] int FindLast(const char* search, int searchLength, int from) const { return (int)rfind(search, (size_type)from, (size_type)searchLength); }
    /*!
     * @brief Try to locate the last position of the given string, starting from the given "from" position
     * @param search String to seek for
     * @param from Start searching at this given index
     * @return String position or -1 of not found
     */
    [[nodiscard]] int FindLast(const String& search, int from) const { return (int)rfind(search, (size_type)from); }

    // Assigners

    /*!
     * @brief Replace the whole content of this string with the value of the given string
     * @param source Source string
     * @return This
     */
    String& Assign(const std::string& source) { std::string::assign(source); return *this; }
    /*!
     * @brief Replace the whole content of this string with a part of the given string
     * @param source Source string
     * @param from Index in the source string from which to start copying characters
     * @return This
     */
    String& Assign(const std::string& source, int from) { std::string::assign(source, (size_type)from); return *this; }
    /*!
     * @brief Replace the whole content of this string with a part of the given string
     * @param source Source string
     * @param from Index in the source string from which to start copying characters
     * @param length Number of characters to copy
     * @return This
     */
    String& Assign(const std::string& source, int from, int length) { std::string::assign(source, (size_type)from, (size_type)length); return *this; }
    /*!
     * @brief Replace the whole content of this string with the value of the given c-string
     * @param source Source c-string
     * @return This
     */
    String& Assign(const char* source) { std::string::assign(source); return *this; }
    /*!
     * @brief Replace the whole content of this string with the value of the given sized c-string
     * @param source Source c-string
     * @param count Size of the source string
     * @return This
     */
    String& Assign(const char* source, int count) { std::string::assign(source, (size_t)count); return *this; }
    /*!
     * @brief Replace the whole content of this string with the value of the given character
     * @param source Character
     * @return This
     */
    String& Assign(const char source) { std::string::assign(1, source); return *this; }
    /*!
     * @brief Replace the whole content of this string with the value of the given character repeated count times
     * @param source Character
     * @param count Repeat counter
     * @return This
     */
    String& Assign(const char source, int count) { std::string::assign(count, source); return *this; }

    /*!
     * @brief Replace the whole content of this string with the value of the given string
     * @param source Source string
     * @return This
     */
    String& Assign(const String& source) { std::string::assign(source); return *this; }

    /*!
     * @brief Replace the whole content of this string with the value of the given char
     * @param source Source char
     * @return This
     */
    String& Assign(unsigned char singleChar) { return Assign((char)singleChar); }

    /*!
     * @brief Replace the whole content of this string with the string representation of the given boolean value
     * The boolean value is converted into its basic representation: '0' or '1'
     * @param value Boolean value
     * @return This
     */
    String& Assign(bool value) { return Assign(value ? '1' : '0'); }
    /*!
     * @brief Replace the whole content of this string with the string representation of the given boolean value
     * The boolean value is converted into its lowercase test representation: "false" or "true"
     * @param value Boolean value
     * @return This
     */
    String& AssignTextBool(bool value) { return value ? Assign(LEGACY_STRING("true")) : Assign(LEGACY_STRING("false")); }

    /*!
     * @brief Replace the whole content of this string with the string representation of the given short value
     * @param value Short value
     * @return This
     */
    String& Assign(short value) { Int32Storage to; int l = ConvertNumeric<int, Int32Storage>((int)value, to); return Assign(&to[sizeof(to) - l], l); }
    /*!
     * @brief Replace the whole content of this string with the string representation of the given unsigned short value
     * @param value unsigned short value
     * @return This
     */
    String& Assign(unsigned short value) { Int32Storage to; int l = ConvertUnsignedNumeric<unsigned int, Int32Storage>((unsigned int)value, to); return Assign(&to[sizeof(to) - l], l); }

    /*!
     * @brief Replace the whole content of this string with the string representation of the given int value
     * @param value Int value
     * @return This
     */
    String& Assign(int value) { Int32Storage to; int l = ConvertNumeric<int, Int32Storage>((int)value, to); return Assign(&to[sizeof(to) - l], l); }
    /*!
     * @brief Replace the whole content of this string with the string representation of the given unsigned int value
     * @param value unsigned int value
     * @return This
     */
    String& Assign(unsigned int value) { Int32Storage to; int l = ConvertUnsignedNumeric<unsigned int, Int32Storage>((unsigned int)value, to); return Assign(&to[sizeof(to) - l], l); }

    /*!
     * @brief Replace the whole content of this string with the string representation of the given long long value
     * @param value long long value
     * @return This
     */
    String& Assign(long long value) { Int64Storage to; int l = ConvertNumeric<long long, Int64Storage>((long long)value, to); return Assign(&to[sizeof(to) - l], l); }
    /*!
     * @brief Replace the whole content of this string with the string representation of the given unsigned long long value
     * @param value unsigned long long value
     * @return This
     */
    String& Assign(unsigned long long value) { Int64Storage to; int l = ConvertUnsignedNumeric<unsigned long long, Int64Storage>((unsigned long long)value, to); return Assign(&to[sizeof(to) - l], l); }

    /*!
     * @brief Replace the whole content of this string with the string representation of the given float value
     * Fractional part is limited to the default precision
     * @param value float value
     * @return This
     */
    String& Assign(float value) { FloatStorage to; int l = ConvertFloat<float, unsigned int, FloatStorage>(value, sDefaultFractionalPrecision, to); return Assign(&to[sizeof(to) - l], l); }
    /*!
     * @brief Replace the whole content of this string with the string representation of the given double value
     * Fractional part is limited to the default precision
     * @param value double value
     * @return This
     */
    String& Assign(double value) { DoubleStorage to; int l = ConvertFloat<double, unsigned long long, DoubleStorage>(value, sDefaultFractionalPrecision, to); return Assign(&to[sizeof(to) - l], l); }
    /*!
     * @brief Replace the whole content of this string with the string representation of the given float value
     * with a fractional part limited to the given precision
     * @param value float value
     * @param precision Fractional part precision
     * @return This
     */
    String& Assign(float value, int precision) { FloatStorage to; int l = ConvertFloat<float, unsigned int, FloatStorage>(value, precision, to); return Assign(&to[sizeof(to) - l], l); }
    /*!
     * @brief Replace the whole content of this string with the string representation of the given double value
     * with a fractional part limited to the given precision
     * @param value double value
     * @param precision Fractional part precision
     * @return This
     */
    String& Assign(double value, int precision) { DoubleStorage to; int l = ConvertFloat<double, unsigned long long, DoubleStorage>(value, precision, to); return Assign(&to[sizeof(to) - l], l); }

    /*!
     * @brief Replace the whole content of this string with the output of the given Format instance
     * @param value Format instance
     * @return This
     */
    String& Assign(const Format& format) { std::string::assign(format.ToString()); return *this; }

    /*!
     * @brief Assign a signed int value in its signed hexadecimal string representation
     * @param value Value to convert
     * @param prefix Hexadecimal prefix
     * @return Hexadecimal string
     */
    String& AssignHexa(int value, Hexa prefix = Hexa::C) { Int32HexaStorage to; int l = ConvertNumericToHexa<int>(value, 0, to, prefix); return Assign(&to[sizeof(to) - l], l); }
    /*!
     * @brief Assign a signed long long value in its signed hexadecimal string representation
     * @param value Value to convert
     * @param prefix Hexadecimal prefix
     * @return Hexadecimal string
     */
    String& AssignHexa(long long value, Hexa prefix = Hexa::C) { Int64HexaStorage to; int l = ConvertNumericToHexa<long long>(value, 0, to, prefix); return Assign(&to[sizeof(to) - l], l); }
    /*!
     * @brief Assign a signed int value in its signed hexadecimal string representation
     * @param value Value to convert
     * @param minsize Minimum size of hexadecimal representation. Conversion may add leading zeroes if required
     * @param prefix Hexadecimal prefix
     * @return Hexadecimal string
     */
    String& AssignHexa(int value, int minsize, Hexa prefix = Hexa::C) { Int32HexaStorage to; int l = ConvertNumericToHexa<int>(value, minsize, to, prefix); return Assign(&to[sizeof(to) - l], l); }
    /*!
     * @brief Assign a signed long long value in its signed hexadecimal string representation
     * @param value Value to convert
     * @param minsize Minimum size of hexadecimal representation. Conversion may add leading zeroes if required
     * @param prefix Hexadecimal prefix
     * @return Hexadecimal string
     */
    String& AssignHexa(long long value, int minsize, Hexa prefix = Hexa::C) { Int64HexaStorage to; int l = ConvertNumericToHexa<long long>(value, minsize, to, prefix); return Assign(&to[sizeof(to) - l], l); }

    /*!
     * @brief Assign an unsigned int value in its unsigned hexadecimal string representation
     * @param value Value to convert
     * @param prefix Hexadecimal prefix
     * @return Hexadecimal string
     */
    String& AssignHexa(unsigned int value, Hexa prefix = Hexa::C) { Int32HexaStorage to; int l = ConvertUnsignedNumericToHexa<unsigned int>(value, 0, to, prefix); return Assign(&to[sizeof(to) - l], l); }
    /*!
     * @brief Assign an unsigned long long value int its unsigned hexadecimal string representation
     * @param value Value to convert
     * @param prefix Hexadecimal prefix
     * @return Hexadecimal string
     */
    String& AssignHexa(unsigned long long value, Hexa prefix = Hexa::C) { Int64HexaStorage to; int l = ConvertUnsignedNumericToHexa<unsigned long long>(value, 0, to, prefix); return Assign(&to[sizeof(to) - l], l); }
    /*!
     * @brief Assign an unsigned int value int its unsigned hexadecimal string representation
     * @param value Value to convert
     * @param minsize Minimum size of hexadecimal representation. Conversion may add leading zeroes if required
     * @param prefix Hexadecimal prefix
     * @return Hexadecimal string
     */
    String& AssignHexa(unsigned int value, int minsize, Hexa prefix = Hexa::C) { Int32HexaStorage to; int l = ConvertUnsignedNumericToHexa<unsigned int>(value, minsize, to, prefix); return Assign(&to[sizeof(to) - l], l); }
    /*!
     * @brief Assign an unsigned long long value in its unsigned hexadecimal string representation
     * @param value Value to convert
     * @param minsize Minimum size of hexadecimal representation. Conversion may add leading zeroes if required
     * @param prefix Hexadecimal prefix
     * @return Hexadecimal string
     */
    String& AssignHexa(unsigned long long value, int minsize, Hexa prefix = Hexa::C) { Int64HexaStorage to; int l = ConvertUnsignedNumericToHexa<unsigned long long>(value, minsize, to, prefix); return Assign(&to[sizeof(to) - l], l); }

    // Appenders

    /*!
     * @brief Append the given std string to the current string
     * @param source std string to append
     * @return This
     */
    String& Append(const std::string& source) { std::string::append(source); return *this; }
    /*!
     * @brief Append the given std string to the current string, starting from the index "from".
     * @param source std string to append
     * @param from Index of the first character to append
     * @return This
     */
    String& Append(const std::string& source, int from) { std::string::append(source, (size_type)from); return *this; }
    /*!
     * @brief Append the given std string to the current string, starting from the index "from" anf for "length" characters
     * @param source std string to append
     * @param from Index of the first character to append
     * @param length Maximum number of character to copy
     * @return This
     */
    String& Append(const std::string& source, int from, int length) { std::string::append(source, (size_type)from, (size_type)length); return *this; }
    /*!
     * @brief Append the given c-string to the current string
     * @param source c-string to append
     * @return This
     */
    String& Append(const char* source) { std::string::append(source); return *this; }
    /*!
     * @brief Append the "count" first character from given c-string into the current string
     * @param source c-string to append
     * @param count Number of character to append
     * @return This
     */
    String& Append(const char* source, int count) { std::string::append(source, (size_t)count); return *this; }
    /*!
     * @brief Append the given char to the current string
     * @param source char to append
     * @return This
     */
    String& Append(const char source) { std::string::append(1, source); return *this; }
    /*!
     * @brief Append the given char to the current string, repeated "count" times
     * @param source char to append
     * @param count Number of time the character is appended
     * @return This
     */
    String& Append(const char source, int count) { std::string::append(count, source); return *this; }

    /*!
     * @brief Append the given string to the current string
     * @param source String to append
     * @return This
     */
    String& Append(const String& source) { std::string::append(source); return *this; }
    /*!
     * @brief Append the given string to the current string, starting from the index "from".
     * @param source String to append
     * @param from Index of the first character to append
     * @return This
     */
    String& Append(const String& source, int from) { std::string::append(source, (size_type)from); return *this; }
    /*!
     * @brief Append the given string to the current string, starting from the index "from" anf for "length" characters
     * @param source String to append
     * @param from Index of the first character to append
     * @param length Maximum number of character to copy
     * @return This
     */
    String& Append(const String& source, int from, int length) { std::string::append(source, (size_type)from, (size_type)length); return *this; }

    /*!
     * @brief Append a single char to the current string
     * @param singleChar Char to append
     * @return This
     */
    String& Append(unsigned char singleChar) { return Append((char)singleChar); }

    /*!
     * @brief Append a boolean value to the current string.
     * The boolean value is represented in its basic form: '0' or '1'
     * @param value Boolean value to append
     * @return This
     */
    String& Append(bool value) { return Append(value ? '1' : '0'); }
    /*!
     * @brief Append a boolean value to the current string.
     * The boolean value is represented in its lowercase text form: "false" or "true"
     * @param value Boolean value to append
     * @return This
     */
    String& AppendTextBool(bool value) { return value ? Append(LEGACY_STRING("true")) : Append(LEGACY_STRING("false")); }

    /*!
     * @brief Append a converted short value to the current string
     * @param value Value to append
     * @return This
     */
    String& Append(short value) { Int32Storage to; int l = ConvertNumeric<int, Int32Storage>((int)value, to); return Append(&to[sizeof(to) - l], l); }
    /*!
     * @brief Append a converted unsigned short value to the current string
     * @param value Value to append
     * @return This
     */
    String& Append(unsigned short value) { Int32Storage to; int l = ConvertUnsignedNumeric<unsigned int, Int32Storage>((unsigned int)value, to); return Append(&to[sizeof(to) - l], l); }

    /*!
     * @brief Append a converted int value to the current string
     * @param value Value to append
     * @return This
     */
    String& Append(int value) { Int32Storage to; int l = ConvertNumeric<int, Int32Storage>((int)value, to); return Append(&to[sizeof(to) - l], l); }
    /*!
     * @brief Append a converted unsigned int value to the current string
     * @param value Value to append
     * @return This
     */
    String& Append(unsigned int value) { Int32Storage to; int l = ConvertUnsignedNumeric<unsigned int, Int32Storage>((unsigned int)value, to); return Append(&to[sizeof(to) - l], l); }

    /*!
     * @brief Append a converted long long value to the current string
     * @param value Value to append
     * @return This
     */
    String& Append(long long value) { Int64Storage to; int l = ConvertNumeric<long long, Int64Storage>((long long)value, to); return Append(&to[sizeof(to) - l], l); }
    /*!
     * @brief Append a converted unsigned long long value to the current string
     * @param value Value to append
     * @return This
     */
    String& Append(unsigned long long value) { Int64Storage to; int l = ConvertUnsignedNumeric<unsigned long long, Int64Storage>((unsigned long long)value, to); return Append(&to[sizeof(to) - l], l); }

    /*!
     * @brief Append a converted float value to the current string
     * Fractional part is limited to the default precision
     * @param value Value to append
     * @return This
     */
    String& Append(float value) { FloatStorage to; int l = ConvertFloat<float, unsigned int, FloatStorage>(value, sDefaultFractionalPrecision, to); return Append(&to[sizeof(to) - l], l); }
    /*!
     * @brief Append a converted double value to the current string
     * Fractional part is limited to the default precision
     * @param value Value to append
     * @return This
     */
    String& Append(double value) { DoubleStorage to; int l = ConvertFloat<double, unsigned long long, DoubleStorage>(value, sDefaultFractionalPrecision, to); return Append(&to[sizeof(to) - l], l); }
    /*!
     * @brief Append a converted float value to the current string
     * Fractional part is limited to the given precision
     * @param value Value to append
     * @param precision Fractional part precision
     * @return This
     */
    String& Append(float value, int precision) { FloatStorage to; int l = ConvertFloat<float, unsigned int, FloatStorage>(value, precision, to); return Append(&to[sizeof(to) - l], l); }
    /*!
     * @brief Append a converted double value to the current string
     * Fractional part is limited to the given precision
     * @param value Value to append
     * @param precision Fractional part precision
     * @return This
     */
    String& Append(double value, int precision) { DoubleStorage to; int l = ConvertFloat<double, unsigned long long, DoubleStorage>(value, precision, to); return Append(&to[sizeof(to) - l], l); }

    /*!
     * @brief Append the output of the given Format instance
     * @param value Format instance
     * @return This
     */
    String& Append(const Format& format) { std::string::append(format.ToString()); return *this; }

    /*!
     * @brief Append a signed int value in its signed hexadecimal string representation
     * @param value Value to convert
     * @param hexa Hexadecimal prefix
     * @return Hexadecimal string
     */
    String& AppendHexa(int value, Hexa prefix = Hexa::C) { Int32HexaStorage to; int l = ConvertNumericToHexa<int>(value, 0, to, prefix); return Append(&to[sizeof(to) - l], l); }
    /*!
     * @brief Append a signed long long value in its signed hexadecimal string representation
     * @param value Value to convert
     * @param hexa Hexadecimal prefix
     * @return Hexadecimal string
     */
    String& AppendHexa(long long value, Hexa prefix = Hexa::C) { Int64HexaStorage to; int l = ConvertNumericToHexa<long long>(value, 0, to, prefix); return Append(&to[sizeof(to) - l], l); }
    /*!
     * @brief Append a signed int value in its signed hexadecimal string representation
     * @param value Value to convert
     * @param minsize Minimum size of hexadecimal representation. Conversion may add leading zeroes if required
     * @param hexa Hexadecimal prefix
     * @return Hexadecimal string
     */
    String& AppendHexa(int value, int minsize, Hexa prefix = Hexa::C) { Int32HexaStorage to; int l = ConvertNumericToHexa<int>(value, minsize, to, prefix); return Append(&to[sizeof(to) - l], l); }
    /*!
     * @brief Append a signed long long value in its signed hexadecimal string representation
     * @param value Value to convert
     * @param minsize Minimum size of hexadecimal representation. Conversion may add leading zeroes if required
     * @param hexa Hexadecimal prefix
     * @return Hexadecimal string
     */
    String& AppendHexa(long long value, int minsize, Hexa prefix = Hexa::C) { Int64HexaStorage to; int l = ConvertNumericToHexa<long long>(value, minsize, to, prefix); return Append(&to[sizeof(to) - l], l); }

    /*!
     * @brief Append an unsigned int value in its unsigned hexadecimal string representation
     * @param value Value to convert
     * @param hexa Hexadecimal prefix
     * @return Hexadecimal string
     */
    String& AppendHexa(unsigned int value, Hexa prefix = Hexa::C) { Int32HexaStorage to; int l = ConvertUnsignedNumericToHexa<unsigned int>(value, 0, to, prefix); return Append(&to[sizeof(to) - l], l); }
    /*!
     * @brief Append an unsigned long long value int its unsigned hexadecimal string representation
     * @param value Value to convert
     * @param hexa Hexadecimal prefix
     * @return Hexadecimal string
     */
    String& AppendHexa(unsigned long long value, Hexa prefix = Hexa::C) { Int64HexaStorage to; int l = ConvertUnsignedNumericToHexa<unsigned long long>(value, 0, to, prefix); return Append(&to[sizeof(to) - l], l); }
    /*!
     * @brief Append an unsigned int value int its unsigned hexadecimal string representation
     * @param value Value to convert
     * @param minsize Minimum size of hexadecimal representation. Conversion may add leading zeroes if required
     * @param hexa Hexadecimal prefix
     * @return Hexadecimal string
     */
    String& AppendHexa(unsigned int value, int minsize, Hexa prefix = Hexa::C) { Int32HexaStorage to; int l = ConvertUnsignedNumericToHexa<unsigned int>(value, minsize, to, prefix); return Append(&to[sizeof(to) - l], l); }
    /*!
     * @brief Append an unsigned long long value in its unsigned hexadecimal string representation
     * @param value Value to convert
     * @param minsize Minimum size of hexadecimal representation. Conversion may add leading zeroes if required
     * @param hexa Hexadecimal prefix
     * @return Hexadecimal string
     */
    String& AppendHexa(unsigned long long value, int minsize, Hexa prefix = Hexa::C) { Int64HexaStorage to; int l = ConvertUnsignedNumericToHexa<unsigned long long>(value, minsize, to, prefix); return Append(&to[sizeof(to) - l], l); }

    // Inserters

    /*!
     * @brief Insert the given std string into the current string
     * @param at Index from which to insert
     * @param source std string to insert
     * @return This
     */
    String& Insert(int at, const std::string& source) { __AtCheck__; std::string::insert(at, source); return *this; }
    /*!
     * @brief Insert the given std string into the current string
     * @param at Index from which to insert
     * @param source std string to insert
     * @param from Start index in the string to insert
     * @return This
     */
    String& Insert(int at, const std::string& source, int from) { __AtCheck__; std::string::insert(at, source, (size_type)from); return *this; }
    /*!
     * @brief Insert the given std string into the current string
     * @param at Index from which to insert
     * @param source std string to insert
     * @param from Start index in the string to insert
     * @param length Number of characters from the source string to insert
     * @return This
     */
    String& Insert(int at, const std::string& source, int from, int length) { __AtCheck__; std::string::insert(at, source, (size_type)from, (size_type)length); return *this; }
    /*!
     * @brief Insert the given c-string into the current string
     * @param at Index from which to insert
     * @param source c-string to insert
     * @return This
     */
    String& Insert(int at, const char* source) { __AtCheck__; std::string::insert(at, source); return *this; }
    /*!
     * @brief Insert part of the given c-string into the current string
     * @param at Index from which to insert
     * @param source c-string to insert
     * @param count Number of character to insert
     * @return This
     */
    String& Insert(int at, const char* source, int count) { __AtCheck__; std::string::insert(at, source, (size_t)count); return *this; }
    /*!
     * @brief Insert the given char into the current string
     * @param source char to insert
     * @return This
     */
    String& Insert(int at, const char source) { __AtCheck__; std::string::insert(at, 1, source); return *this; }
    /*!
     * @brief Insert the given char into the current string, repeated "count" times
     * @param source char to insert
     * @param count Number of time the character is inserted
     * @return This
     */
    String& Insert(int at, const char source, int count) { __AtCheck__; std::string::insert(at, count, source); return *this; }

    /*!
     * @brief Insert the given string into the current string
     * @param at Index from which to insert
     * @param source String to insert
     * @return This
     */
    String& Insert(int at, const String& source) { __AtCheck__; std::string::insert(at, source); return *this; }
    /*!
     * @brief Insert a part of the given string into the current string
     * @param at Index from which to insert
     * @param source String to insert
     * @param from Start index in the string to insert
     * @return This
     */
    String& Insert(int at, const String& source, int from) { __AtCheck__; std::string::insert(at, source, (size_type)from); return *this; }
    /*!
     * @brief Insert a part of the given string into the current string
     * @param at Index from which to insert
     * @param source String to insert
     * @param from Start index in the string to insert
     * @param length Number of characters from the source string to insert
     * @return This
     */
    String& Insert(int at, const String& source, int from, int length) { __AtCheck__; std::string::insert(at, source, (size_type)from, (size_type)length); return *this; }

    /*!
     * @brief Insert the given unsigned char into the current string
     * @param source unsigned char to insert
     * @return This
     */
    String& Insert(int at, unsigned char singleChar) { __AtCheck__; return Insert(at, (char)singleChar); }

    /*!
     * @brief Insert a boolean value into the current string.
     * The boolean value is represented in its basic form: '0' or '1'
     * @param value Boolean value to insert
     * @return This
     */
    String& Insert(int at, bool value) { __AtCheck__; return Insert(at, value ? '1' : '0'); }
    /*!
     * @brief Insert a boolean value into the current string.
     * The boolean value is represented in its lowercase text form: "false" or "true"
     * @param value Boolean value to insert
     * @return This
     */
    String& InsertTextBool(int at, bool value) { __AtCheck__; return value ? Insert(at, LEGACY_STRING("true")) : Insert(at, LEGACY_STRING("false")); }

    /*!
     * @brief Insert a converted short value into the current string
     * @param value Value to insert
     * @return This
     */
    String& Insert(int at, short value) { __AtCheck__; Int32Storage to; int l = ConvertNumeric<int, Int32Storage>((int)value, to); return Insert(at, &to[sizeof(to) - l], l); }
    /*!
     * @brief Insert a converted unsigned short value into the current string
     * @param value Value to insert
     * @return This
     */
    String& Insert(int at, unsigned short value) { __AtCheck__; Int32Storage to; int l = ConvertUnsignedNumeric<unsigned int, Int32Storage>((unsigned int)value, to); return Insert(at, &to[sizeof(to) - l], l); }

    /*!
     * @brief Insert a converted int value into the current string
     * @param value Value to insert
     * @return This
     */
    String& Insert(int at, int value) { __AtCheck__; Int32Storage to; int l = ConvertNumeric<int, Int32Storage>((int)value, to); return Insert(at, &to[sizeof(to) - l], l); }
    /*!
     * @brief Insert a converted unsigned int value into the current string
     * @param value Value to insert
     * @return This
     */
    String& Insert(int at, unsigned int value) { __AtCheck__; Int32Storage to; int l = ConvertUnsignedNumeric<unsigned int, Int32Storage>((unsigned int)value, to); return Insert(at, &to[sizeof(to) - l], l); }

    /*!
     * @brief Insert a converted long long value into the current string
     * @param value Value to insert
     * @return This
     */
    String& Insert(int at, long long value) { __AtCheck__; Int64Storage to; int l = ConvertNumeric<long long, Int64Storage>((long long)value, to); return Insert(at, &to[sizeof(to) - l], l); }
    /*!
     * @brief Insert a converted unsigned long long value into the current string
     * @param value Value to insert
     * @return This
     */
    String& Insert(int at, unsigned long long value) { __AtCheck__; Int64Storage to; int l = ConvertUnsignedNumeric<unsigned long long, Int64Storage>((unsigned long long)value, to); return Insert(at, &to[sizeof(to) - l], l); }

    /*!
     * @brief Insert a converted float value into the current string
     * Fractional part is limited to the default precision
     * @param value Value to append
     * @return This
     */
    String& Insert(int at, float value) { __AtCheck__; FloatStorage to; int l = ConvertFloat<float, unsigned int, FloatStorage>(value, sDefaultFractionalPrecision, to); return Insert(at, &to[sizeof(to) - l], l); }
    /*!
     * @brief Insert a converted float value into the current string
     * Fractional part is limited to the given precision
     * @param value Value to append
     * @param precision Fractional part precision
     * @return This
     */
    String& Insert(int at, double value) { __AtCheck__; DoubleStorage to; int l = ConvertFloat<double, unsigned long long, DoubleStorage>(value, sDefaultFractionalPrecision, to); return Insert(at, &to[sizeof(to) - l], l); }
    /*!
     * @brief Insert a converted double value into the current string
     * Fractional part is limited to the default precision
     * @param value Value to append
     * @return This
     */
    String& Insert(int at, float value, int precision) { __AtCheck__; FloatStorage to; int l = ConvertFloat<float, unsigned int, FloatStorage>(value, precision, to); return Insert(at, &to[sizeof(to) - l], l); }
    /*!
     * @brief Insert a converted double value into the current string
     * Fractional part is limited to the given precision
     * @param value Value to append
     * @param precision Fractional part precision
     * @return This
     */
    String& Insert(int at, double value, int precision) { __AtCheck__; DoubleStorage to; int l = ConvertFloat<double, unsigned long long, DoubleStorage>(value, precision, to); return Insert(at, &to[sizeof(to) - l], l); }

    /*!
     * @brief Append the output of the given Format instance
     * @param value Format instance
     * @return This
     */
    String& Insert(int at, const Format& format) { __AtCheck__; std::string::insert(at, format.ToString()); return *this; }

    /*!
     * @brief Insert a signed int value in its signed hexadecimal string representation
     * @param value Value to convert
     * @param hexa Hexadecimal prefix
     * @return Hexadecimal string
     */
    String& InsertHexa(int at, int value, Hexa prefix = Hexa::C) { Int32HexaStorage to; int l = ConvertNumericToHexa<int>(value, 0, to, prefix); return Insert(at, &to[sizeof(to) - l], l); }
    /*!
     * @brief Insert a signed long long value in its signed hexadecimal string representation
     * @param value Value to convert
     * @param hexa Hexadecimal prefix
     * @return Hexadecimal string
     */
    String& InsertHexa(int at, long long value, Hexa prefix = Hexa::C) { Int64HexaStorage to; int l = ConvertNumericToHexa<long long>(value, 0, to, prefix); return Insert(at, &to[sizeof(to) - l], l); }
    /*!
     * @brief Insert a signed int value in its signed hexadecimal string representation
     * @param value Value to convert
     * @param minsize Minimum size of hexadecimal representation. Conversion may add leading zeroes if required
     * @param hexa Hexadecimal prefix
     * @return Hexadecimal string
     */
    String& InsertHexa(int at, int value, int minsize, Hexa prefix = Hexa::C) { Int32HexaStorage to; int l = ConvertNumericToHexa<int>(value, minsize, to, prefix); return Insert(at, &to[sizeof(to) - l], l); }
    /*!
     * @brief Insert a signed long long value in its signed hexadecimal string representation
     * @param value Value to convert
     * @param minsize Minimum size of hexadecimal representation. Conversion may add leading zeroes if required
     * @param hexa Hexadecimal prefix
     * @return Hexadecimal string
     */
    String& InsertHexa(int at, long long value, int minsize, Hexa prefix = Hexa::C) { Int64HexaStorage to; int l = ConvertNumericToHexa<long long>(value, minsize, to, prefix); return Insert(at, &to[sizeof(to) - l], l); }

    /*!
     * @brief Insert an unsigned int value in its unsigned hexadecimal string representation
     * @param value Value to convert
     * @param hexa Hexadecimal prefix
     * @return Hexadecimal string
     */
    String& InsertHexa(int at, unsigned int value, Hexa prefix = Hexa::C) { Int32HexaStorage to; int l = ConvertUnsignedNumericToHexa<unsigned int>(value, 0, to, prefix); return Insert(at, &to[sizeof(to) - l], l); }
    /*!
     * @brief Insert an unsigned long long value int its unsigned hexadecimal string representation
     * @param value Value to convert
     * @param hexa Hexadecimal prefix
     * @return Hexadecimal string
     */
    String& InsertHexa(int at, unsigned long long value, Hexa prefix = Hexa::C) { Int64HexaStorage to; int l = ConvertUnsignedNumericToHexa<unsigned long long>(value, 0, to, prefix); return Insert(at, &to[sizeof(to) - l], l); }
    /*!
     * @brief Insert an unsigned int value int its unsigned hexadecimal string representation
     * @param value Value to convert
     * @param minsize Minimum size of hexadecimal representation. Conversion may add leading zeroes if required
     * @param hexa Hexadecimal prefix
     * @return Hexadecimal string
     */
    String& InsertHexa(int at, unsigned int value, int minsize, Hexa prefix = Hexa::C) { Int32HexaStorage to; int l = ConvertUnsignedNumericToHexa<unsigned int>(value, minsize, to, prefix); return Insert(at, &to[sizeof(to) - l], l); }
    /*!
     * @brief Insert an unsigned long long value in its unsigned hexadecimal string representation
     * @param value Value to convert
     * @param minsize Minimum size of hexadecimal representation. Conversion may add leading zeroes if required
     * @param hexa Hexadecimal prefix
     * @return Hexadecimal string
     */
    String& InsertHexa(int at, unsigned long long value, int minsize, Hexa prefix = Hexa::C) { Int64HexaStorage to; int l = ConvertUnsignedNumericToHexa<unsigned long long>(value, minsize, to, prefix); return Insert(at, &to[sizeof(to) - l], l); }

    // Deleters

    /*!
     * @brief Delete character at the given position
     * @param at Position to delete
     * @return This
     */
    String& Delete(int at) { std::string::erase(at, 1); return *this; }

    /*!
     * @brief Delete 'length' character at the given position
     * @param at Position to delete
     * @param length Amount of character to delete
     * @return This
     */
    String& Delete(int at, int length) { std::string::erase(at, length); return *this; }

    /*!
     * @brief Remove all occurrences of the given char
     * @param c Char to delete
     * @return This
     */
    String& Remove(const char c)
    {
      int l = Count();
      const char* p = data() + l; // Avoid array checks
      for(int i = (l & sLargestTypeMask); --l, --i >= 0; )
        if (*(--p) == c)
        {
          erase(l, 1);
          p = data() + l;
        }
      l++;
      LargestType* b = (LargestType*)p;
      for(int i = (Count() >> sLargestTypeBits); l -= sLargestTypeSize, --i >= 0; )
      {
        LargestType v = *(--b);
        for(int o = sLargestTypeSize; --o >= 0;)
          if ((char)(v >> (o << 3)) == c)
          {
            erase(l + o, 1);
            b = (LargestType*)(data() + l);
          }
      }
      return *this;
    }

    /*!
     * @brief Remove all control char occurrences
     * @return This
     */
    String& RemoveControl()
    {
      int l = Count();
      const char* p = data() + l; // Avoid array checks
      for(int i = (l & sLargestTypeMask); --l, --i >= 0; )
        if (*(--p) < 32)
        {
          erase(l, 1);
          p = data() + l;
        }
      l++;
      LargestType* b = (LargestType*)p;
      for(int i = (Count() >> sLargestTypeBits); l -= sLargestTypeSize, --i >= 0; )
      {
        LargestType v = *(--b);
        for(int o = sLargestTypeSize; --o >= 0;)
          if ((char)(v >> (o << 3)) < 32)
          {
            erase(l + o, 1);
            b = (LargestType*)(data() + l);
          }
      }
      return *this;
    }

    /*!
     * @brief Remove all occurrences of the given string
     * @param c String to delete
     * @return This
     */
    String& Remove(const char* s)
    {
      int l = (int)strlen(s);
      for(int pos = 0; (pos = (int)find(s, pos)) != (int)std::string::npos; )
        erase(pos, l);
      return *this;
    }

    /*!
     * @brief Remove all occurrences of the given string
     * @param s String to delete
     * @param length s length
     * @return This
     */
    String& Remove(const char* s, int length)
    {
      int l = (int)strlen(s);
      for(int pos = 0; (pos = (int)find(s, pos, length)) != (int)std::string::npos; )
        erase(pos, l);
      return *this;
    }

    /*!
     * @brief Remove all occurrence of the given string
     * @param s String to delete
     * @return This
     */
    String& Remove(const String& s)
    {
      for(int pos = 0; (pos = (int)find(s, pos)) != (int)std::string::npos; )
        erase(pos, s.length());
      return *this;
    }

    // Converters

    /*!
     * @brief Convert the whole string to a boolean value
     * @return Converted value or false as default value
     */
    [[nodiscard]] bool AsBool() const { return ConvertToBool(0, 0, false); }
    /*!
     * @brief Convert the string starting at from to a boolean value
     * @param from First character to check for a boolean value
     * @return Converted value or false as default value
     */
    [[nodiscard]] bool AsBool(int from) const { return ConvertToBool(from, 0, false); }
    /*!
     * @brief Convert the string to a boolean value that must end with the given stop character
     * @param stop Stop character that must appear immediately after the boolean value
     * @return Converted value or false as default value
     */
    [[nodiscard]] bool AsBool(char stop) const { return ConvertToBool(0, stop, false); }
    /*!
     * @brief Convert the string starting at from to a boolean value that must end with the given stop character
     * @param from First character to check for a boolean value
     * @param stop Stop character that must appear immediately after the boolean value
     * @return Converted value or default value
     */
    [[nodiscard]] bool AsBool(int from, char stop)  const { return ConvertToBool(from, stop, false); }
    /*!
     * @brief Convert the whole string to a boolean value
     * @param defaultValue default value if the conversion fails
     * @return Converted value or default value
     */
    [[nodiscard]] bool AsBool(bool defaultValue) const { return ConvertToBool(0, 0, defaultValue); }
    /*!
     * @brief Convert the string starting at from to a boolean value
     * @param from First character to check for a boolean value
     * @param defaultValue default value if the conversion fails
     * @return Converted value or default value
     */
    [[nodiscard]] bool AsBool(int from, bool defaultValue)  const { return ConvertToBool(from, 0, defaultValue); }
    /*!
     * @brief Convert the string to a boolean value that must end with the given stop character
     * @param stop Stop character that must appear immediately after the boolean value
     * @param defaultValue default value if the conversion fails
     * @return Converted value or default value
     */
    [[nodiscard]] bool AsBool(char stop, bool defaultValue)  const { return ConvertToBool(0, stop, defaultValue); }
    /*!
     * @brief Convert the string starting at from to a boolean value that must end with the given stop character
     * @param from First character to check for a boolean value
     * @param stop Stop character that must appear immediately after the boolean value
     * @param defaultValue default value if the conversion fails
     * @return Converted value or default value
     */
    [[nodiscard]] bool AsBool(int from, char stop, bool defaultValue)  const { return ConvertToBool(from, stop, defaultValue); }

    /*!
     * @brief Try to convert the whole string to a boolean value
     * @param[out] output Will receive the boolean value if the conversion complete successfuly
     * @return True if the conversion is successful and output if filled withe converted value. False otherwise
     */
    [[nodiscard]] bool TryAsBool(bool& output) const { return TryConvertingToBool(0, 0, output); }
    /*!
     * @brief Try to convert the string starting at from to a boolean value
     * @param from First character to check for a boolean value
     * @param[out] output Will receive the boolean value if the conversion complete successfuly
     * @return True if the conversion is successful and output if filled withe converted value. False otherwise
     */
    [[nodiscard]] bool TryAsBool(int from, bool& output) const { return TryConvertingToBool(from, 0, output); }
    /*!
     * @brief Try to convert the whole string to a boolean value that must end with the given stop character
     * @param stop Stop character that must appear immediately after the boolean value
     * @param[out] output Will receive the boolean value if the conversion complete successfuly
     * @return True if the conversion is successful and output if filled withe converted value. False otherwise
     */
    [[nodiscard]] bool TryAsBool(char stop, bool& output) const { return TryConvertingToBool(0, stop, output); }
    /*!
     * @brief Try to convert the string starting at from to a boolean value that must end with the given stop character
     * @param from First character to check for a boolean value
     * @param stop Stop character that must appear immediately after the boolean value
     * @param[out] output Will receive the boolean value if the conversion complete successfuly
     * @return True if the conversion is successful and output if filled withe converted value. False otherwise
     */
    [[nodiscard]] bool TryAsBool(int from, char stop, bool& output)  const { return TryConvertingToBool(from, stop, output); }

    /*!
     * @brief Convert the whole string to an int value
     * @return Converted value or 0 as default value
     */
    [[nodiscard]] int AsInt() const { return ConvertToNumeric<int>(0, 0, 0); }
    /*!
     * @brief Convert the string starting at from to an int value
     * @param from First character to check for an int value
     * @return Converted value or 0 as default value
     */
    [[nodiscard]] int AsInt(int from) const { return ConvertToNumeric<int>(from, 0, 0); }
    /*!
     * @brief Convert the string to an int value that must end with the given stop character
     * @param stop Stop character that must appear immediately after the int value
     * @return Converted value or 0 as default value
     */
    [[nodiscard]] int AsInt(char stop) const { return ConvertToNumeric<int>(0, stop, 0); }
    /*!
     * @brief Convert the string starting at from to an int value that must end with the given stop character
     * @param from First character to check for an int value
     * @param stop Stop character that must appear immediately after the int value
     * @return Converted value or default value
     */
    [[nodiscard]] int AsInt(int from, char stop)  const { return ConvertToNumeric<int>(from, stop, 0); }
    /*!
     * @brief Convert the string starting at from to an int value
     * @param from First character to check for an int value
     * @param defaultValue default value if the conversion fails
     * @return Converted value or default value
     */
    [[nodiscard]] int AsInt(int from, int defaultValue)  const { return ConvertToNumeric<int>(from, 0, defaultValue); }
    /*!
     * @brief Convert the string to an int value that must end with the given stop character
     * @param stop Stop character that must appear immediately after the int value
     * @param defaultValue default value if the conversion fails
     * @return Converted value or default value
     */
    [[nodiscard]] int AsInt(char stop, int defaultValue)  const { return ConvertToNumeric<int>(0, stop, defaultValue); }
    /*!
     * @brief Convert the string starting at from to an int value that must end with the given stop character
     * @param from First character to check for an int value
     * @param stop Stop character that must appear immediately after the int value
     * @param defaultValue default value if the conversion fails
     * @return Converted value or default value
     */
    [[nodiscard]] int AsInt(int from, char stop, int defaultValue)  const { return ConvertToNumeric<int>(from, stop, defaultValue); }

    /*!
     * @brief Try to convert the whole string to an int value
     * @param[out] output Will receive the int value if the conversion complete successfuly
     * @return True if the conversion is successful and output if filled withe converted value. False otherwise
     */
    [[nodiscard]] bool TryAsInt(int& output) const { return TryConvertingToNumeric<int>(0, 0, output); }
    /*!
     * @brief Try to convert the string starting at from to an int value
     * @param from First character to check for an int value
     * @param[out] output Will receive the int value if the conversion complete successfuly
     * @return True if the conversion is successful and output if filled withe converted value. False otherwise
     */
    [[nodiscard]] bool TryAsInt(int from, int& output) const { return TryConvertingToNumeric<int>(from, 0, output); }
    /*!
     * @brief Try to convert the whole string to an int value that must end with the given stop character
     * @param stop Stop character that must appear immediately after the int value
     * @param[out] output Will receive the int value if the conversion complete successfuly
     * @return True if the conversion is successful and output if filled withe converted value. False otherwise
     */
    [[nodiscard]] bool TryAsInt(char stop, int& output) const { return TryConvertingToNumeric<int>(0, stop, output); }
    /*!
     * @brief Try to convert the string starting at from to an int value that must end with the given stop character
     * @param from First character to check for an int value
     * @param stop Stop character that must appear immediately after the int value
     * @param[out] output Will receive the int value if the conversion complete successfuly
     * @return True if the conversion is successful and output if filled withe converted value. False otherwise
     */
    [[nodiscard]] bool TryAsInt(int from, char stop, int& output)  const { return TryConvertingToNumeric<int>(from, stop, output); }

    /*!
     * @brief Convert the whole string to a long long value
     * @return Converted value or 0 as default value
     */
    [[nodiscard]] long long AsInt64() const { return ConvertToNumeric<long long>(0, 0, 0); }
    /*!
     * @brief Convert the string starting at from to a long long value
     * @param from First character to check for a long long value
     * @return Converted value or 0 as default value
     */
    [[nodiscard]] long long AsInt64(int from) const { return ConvertToNumeric<long long>(from, 0, 0); }
    /*!
     * @brief Convert the string to a long long value that must end with the given stop character
     * @param stop Stop character that must appear immediately after the long long value
     * @return Converted value or 0 as default value
     */
    [[nodiscard]] long long AsInt64(char stop) const { return ConvertToNumeric<long long>(0, stop, 0); }
    /*!
     * @brief Convert the string starting at from to a long long value that must end with the given stop character
     * @param from First character to check for a long long value
     * @param stop Stop character that must appear immediately after the long long value
     * @return Converted value or default value
     */
    [[nodiscard]] long long AsInt64(int from, char stop)  const { return ConvertToNumeric<long long>(from, stop, 0); }
    /*!
     * @brief Convert the string starting at from to a long long value
     * @param from First character to check for a long long value
     * @param defaultValue default value if the conversion fails
     * @return Converted value or default value
     */
    [[nodiscard]] long long AsInt64(int from, long long defaultValue)  const { return ConvertToNumeric<long long>(from, 0, defaultValue); }
    /*!
     * @brief Convert the string to a long long value that must end with the given stop character
     * @param stop Stop character that must appear immediately after the long long value
     * @param defaultValue default value if the conversion fails
     * @return Converted value or default value
     */
    [[nodiscard]] long long AsInt64(char stop, long long defaultValue)  const { return ConvertToNumeric<long long>(0, stop, defaultValue); }
    /*!
     * @brief Convert the string starting at from to a long long value that must end with the given stop character
     * @param from First character to check for a long long value
     * @param stop Stop character that must appear immediately after the long long value
     * @param defaultValue default value if the conversion fails
     * @return Converted value or default value
     */
    [[nodiscard]] long long AsInt64(int from, char stop, long long defaultValue)  const { return ConvertToNumeric<long long>(from, stop, defaultValue); }

    /*!
     * @brief Try to convert the whole string to a long long value
     * @param[out] output Will receive the long long value if the conversion complete successfuly
     * @return True if the conversion is successful and output if filled withe converted value. False otherwise
     */
    [[nodiscard]] bool TryAsInt64(long long& output) const { return TryConvertingToNumeric<long long>(0, 0, output); }
    /*!
     * @brief Try to convert the string starting at from to a long long value
     * @param from First character to check for a long long value
     * @param[out] output Will receive the long long value if the conversion complete successfuly
     * @return True if the conversion is successful and output if filled withe converted value. False otherwise
     */
    [[nodiscard]] bool TryAsInt64(int from, long long& output) const { return TryConvertingToNumeric<long long>(from, 0, output); }
    /*!
     * @brief Try to convert the whole string to a long long value that must end with the given stop character
     * @param stop Stop character that must appear immediately after the long long value
     * @param[out] output Will receive the long long value if the conversion complete successfuly
     * @return True if the conversion is successful and output if filled withe converted value. False otherwise
     */
    [[nodiscard]] bool TryAsInt64(char stop, long long& output) const { return TryConvertingToNumeric<long long>(0, stop, output); }
    /*!
     * @brief Try to convert the string starting at from to a long long value that must end with the given stop character
     * @param from First character to check for a long long value
     * @param stop Stop character that must appear immediately after the long long value
     * @param[out] output Will receive the long long value if the conversion complete successfuly
     * @return True if the conversion is successful and output if filled withe converted value. False otherwise
     */
    [[nodiscard]] bool TryAsInt64(int from, char stop, long long& output)  const { return TryConvertingToNumeric<long long>(from, stop, output); }

    /*!
     * @brief Convert the whole string to an float value
     * @return Converted value or 0 as default value
     */
    [[nodiscard]] float AsFloat() const { return ConvertToFloat<float, int>(0, 0, 0.f); }
    /*!
     * @brief Convert the string starting at from to an float value
     * @param from First character to check for an float value
     * @return Converted value or 0 as default value
     */
    [[nodiscard]] float AsFloat(int from) const { return ConvertToFloat<float, int>(from, 0, 0.f); }
    /*!
     * @brief Convert the string to an float value that must end with the given stop character
     * @param stop Stop character that must appear immediately after the float value
     * @return Converted value or 0 as default value
     */
    [[nodiscard]] float AsFloat(char stop) const { return ConvertToFloat<float, int>(0, stop, 0.f); }
    /*!
     * @brief Convert the string starting at from to an float value that must end with the given stop character
     * @param from First character to check for an float value
     * @param stop Stop character that must appear immediately after the float value
     * @return Converted value or default value
     */
    [[nodiscard]] float AsFloat(int from, char stop)  const { return ConvertToFloat<float, int>(from, stop, 0.f); }
    /*!
     * @brief Convert the string starting at from to an float value
     * @param from First character to check for an float value
     * @param defaultValue default value if the conversion fails
     * @return Converted value or default value
     */
    [[nodiscard]] float AsFloat(int from, float defaultValue)  const { return ConvertToFloat<float, int>(from, 0, defaultValue); }
    /*!
     * @brief Convert the string to an float value that must end with the given stop character
     * @param stop Stop character that must appear immediately after the float value
     * @param defaultValue default value if the conversion fails
     * @return Converted value or default value
     */
    [[nodiscard]] float AsFloat(char stop, float defaultValue)  const { return ConvertToFloat<float, int>(0, stop, defaultValue); }
    /*!
     * @brief Convert the string starting at from to an float value that must end with the given stop character
     * @param from First character to check for an float value
     * @param stop Stop character that must appear immediately after the float value
     * @param defaultValue default value if the conversion fails
     * @return Converted value or default value
     */
    [[nodiscard]] float AsFloat(int from, char stop, float defaultValue)  const { return ConvertToFloat<float, int>(from, stop, defaultValue); }

    /*!
     * @brief Try to convert the whole string to an float value
     * @param[out] output Will receive the float value if the conversion complete successfuly
     * @return True if the conversion is successful and output if filled withe converted value. False otherwise
     */
    [[nodiscard]] bool TryAsFloat(float& output) const { return TryConvertingToFloat<float, int>(0, 0, output); }
    /*!
     * @brief Try to convert the string starting at from to an float value
     * @param from First character to check for an float value
     * @param[out] output Will receive the float value if the conversion complete successfuly
     * @return True if the conversion is successful and output if filled withe converted value. False otherwise
     */
    [[nodiscard]] bool TryAsFloat(int from, float& output) const { return TryConvertingToFloat<float, int>(from, 0, output); }
    /*!
     * @brief Try to convert the whole string to an float value that must end with the given stop character
     * @param stop Stop character that must appear immediately after the float value
     * @param[out] output Will receive the float value if the conversion complete successfuly
     * @return True if the conversion is successful and output if filled withe converted value. False otherwise
     */
    [[nodiscard]] bool TryAsFloat(char stop, float& output) const { return TryConvertingToFloat<float, int>(0, stop, output); }
    /*!
     * @brief Try to convert the string starting at from to an float value that must end with the given stop character
     * @param from First character to check for an float value
     * @param stop Stop character that must appear immediately after the float value
     * @param[out] output Will receive the float value if the conversion complete successfuly
     * @return True if the conversion is successful and output if filled withe converted value. False otherwise
     */
    [[nodiscard]] bool TryAsFloat(int from, char stop, float& output)  const { return TryConvertingToFloat<float, int>(from, stop, output); }

    /*!
     * @brief Convert the whole string to an double value
     * @return Converted value or 0 as default value
     */
    [[nodiscard]] double AsDouble() const { return ConvertToFloat<double, long long>(0, 0, 0.f); }
    /*!
     * @brief Convert the string starting at from to an double value
     * @param from First character to check for an double value
     * @return Converted value or 0 as default value
     */
    [[nodiscard]] double AsDouble(int from) const { return ConvertToFloat<double, long long>(from, 0, 0.f); }
    /*!
     * @brief Convert the string to an double value that must end with the given stop character
     * @param stop Stop character that must appear immediately after the double value
     * @return Converted value or 0 as default value
     */
    [[nodiscard]] double AsDouble(char stop) const { return ConvertToFloat<double, long long>(0, stop, 0.f); }
    /*!
     * @brief Convert the string starting at from to an double value that must end with the given stop character
     * @param from First character to check for an double value
     * @param stop Stop character that must appear immediately after the double value
     * @return Converted value or default value
     */
    [[nodiscard]] double AsDouble(int from, char stop)  const { return ConvertToFloat<double, long long>(from, stop, 0.f); }
    /*!
     * @brief Convert the string starting at from to an double value
     * @param from First character to check for an double value
     * @param defaultValue default value if the conversion fails
     * @return Converted value or default value
     */
    [[nodiscard]] double AsDouble(int from, double defaultValue)  const { return ConvertToFloat<double, long long>(from, 0, defaultValue); }
    /*!
     * @brief Convert the string to an double value that must end with the given stop character
     * @param stop Stop character that must appear immediately after the double value
     * @param defaultValue default value if the conversion fails
     * @return Converted value or default value
     */
    [[nodiscard]] double AsDouble(char stop, double defaultValue)  const { return ConvertToFloat<double, long long>(0, stop, defaultValue); }
    /*!
     * @brief Convert the string starting at from to a double value that must end with the given stop character
     * @param from First character to check for an double value
     * @param stop Stop character that must appear immediately after the double value
     * @param defaultValue default value if the conversion fails
     * @return Converted value or default value
     */
    [[nodiscard]] double AsDouble(int from, char stop, double defaultValue)  const { return ConvertToFloat<double, long long>(from, stop, defaultValue); }

    /*!
     * @brief Try to convert the whole string to a double value
     * @param[out] output Will receive the double value if the conversion complete successfuly
     * @return True if the conversion is successful and output if filled withe converted value. False otherwise
     */
    [[nodiscard]] bool TryAsDouble(double& output) const { return TryConvertingToFloat<double, long long>(0, 0, output); }
    /*!
     * @brief Try to convert the string starting at from to a double value
     * @param from First character to check for an double value
     * @param[out] output Will receive the double value if the conversion complete successfuly
     * @return True if the conversion is successful and output if filled withe converted value. False otherwise
     */
    [[nodiscard]] bool TryAsDouble(int from, double& output) const { return TryConvertingToFloat<double, long long>(from, 0, output); }
    /*!
     * @brief Try to convert the whole string to an double value that must end with the given stop character
     * @param stop Stop character that must appear immediately after the double value
     * @param[out] output Will receive the double value if the conversion complete successfuly
     * @return True if the conversion is successful and output if filled withe converted value. False otherwise
     */
    [[nodiscard]] bool TryAsDouble(char stop, double& output) const { return TryConvertingToFloat<double, long long>(0, stop, output); }
    /*!
     * @brief Try to convert the string starting at from to a double value that must end with the given stop character
     * @param from First character to check for a double value
     * @param stop Stop character that must appear immediately after the double value
     * @param[out] output Will receive the double value if the conversion complete successfuly
     * @return True if the conversion is successful and output if filled withe converted value. False otherwise
     */
    [[nodiscard]] bool TryAsDouble(int from, char stop, double& output)  const { return TryConvertingToFloat<double, long long>(from, stop, output); }

    /*!
     * @brief Convert a signed int value to its signed string representation
     * @param value Value to convert
     * @param hexa hexadecimal prefix
     * @return Hexadecimal string
     */
    [[nodiscard]] static String ToHexa(int value, Hexa prefix = Hexa::C) { Int32HexaStorage to; int l = ConvertNumericToHexa<int>(value, 0, to, prefix); return String().Append(&to[sizeof(to) - l], l); }
    /*!
     * @brief Convert a signed long long value to its signed string representation
     * @param value Value to convert
     * @param hexa hexadecimal prefix
     * @return Hexadecimal string
     */
    [[nodiscard]] static String ToHexa(long long value, Hexa prefix = Hexa::C) { Int64HexaStorage to; int l = ConvertNumericToHexa<long long>(value, 0, to, prefix); return String().Append(&to[sizeof(to) - l], l); }
    /*!
     * @brief Convert a signed int value to its signed string representation
     * @param value Value to convert
     * @param minsize Minimum size of hexadecimal representation. Conversion may add leading zeroes if required
     * @param hexa hexadecimal prefix
     * @return Hexadecimal string
     */
    [[nodiscard]] static String ToHexa(int value, int minsize, Hexa prefix = Hexa::C) { Int32HexaStorage to; int l = ConvertNumericToHexa<int>(value, minsize, to, prefix); return String().Append(&to[sizeof(to) - l], l); }
    /*!
     * @brief Convert a signed long long value to its signed string representation
     * @param value Value to convert
     * @param minsize Minimum size of hexadecimal representation. Conversion may add leading zeroes if required
     * @param hexa hexadecimal prefix
     * @return Hexadecimal string
     */
    [[nodiscard]] static String ToHexa(long long value, int minsize, Hexa prefix = Hexa::C) { Int64HexaStorage to; int l = ConvertNumericToHexa<long long>(value, minsize, to, prefix); return String().Append(&to[sizeof(to) - l], l); }

    /*!
     * @brief Convert an unsigned int value to its unsigned string representation
     * @param value Value to convert
     * @param hexa hexadecimal prefix
     * @return Hexadecimal string
     */
    [[nodiscard]] static String ToHexa(unsigned int value, Hexa prefix = Hexa::C) { Int32HexaStorage to; int l = ConvertUnsignedNumericToHexa<unsigned int>(value, 0, to, prefix); return String().Append(&to[sizeof(to) - l], l); }
    /*!
     * @brief Convert an unsigned long long value to its unsigned string representation
     * @param value Value to convert
     * @param hexa hexadecimal prefix
     * @return Hexadecimal string
     */
    [[nodiscard]] static String ToHexa(unsigned long long value, Hexa prefix = Hexa::C) { Int64HexaStorage to; int l = ConvertUnsignedNumericToHexa<unsigned long long>(value, 0, to, prefix); return String().Append(&to[sizeof(to) - l], l); }
    /*!
     * @brief Convert an unsigned int value to its unsigned string representation
     * @param value Value to convert
     * @param minsize Minimum size of hexadecimal representation. Conversion may add leading zeroes if required
     * @param hexa hexadecimal prefix
     * @return Hexadecimal string
     */
    [[nodiscard]] static String ToHexa(unsigned int value, int minsize, Hexa prefix = Hexa::C) { Int32HexaStorage to; int l = ConvertUnsignedNumericToHexa<unsigned int>(value, minsize, to, prefix); return String().Append(&to[sizeof(to) - l], l); }
    /*!
     * @brief Convert an unsigned long long value to its unsigned string representation
     * @param value Value to convert
     * @param minsize Minimum size of hexadecimal representation. Conversion may add leading zeroes if required
     * @param hexa hexadecimal prefix
     * @return Hexadecimal string
     */
    [[nodiscard]] static String ToHexa(unsigned long long value, int minsize, Hexa prefix = Hexa::C) { Int64HexaStorage to; int l = ConvertUnsignedNumericToHexa<unsigned long long>(value, minsize, to, prefix); return String().Append(&to[sizeof(to) - l], l); }

    // ASCII Case

    /*!
     * @brief Convert current string to lowercase
     * @return This
     */
    String& LowerCase() { return DoLowerCase(0, (int)size()); }
    /*!
     * @brief Return a lower-case'd copy of the current string
     * @return This
     */
    [[nodiscard]] String ToLowerCase() const { return String(*this).DoLowerCase(0, (int)size()); }
    /*!
     * @brief Convert current string to uppercase
     * @return This
     */
    String& UpperCase() { return DoUpperCase(0, (int)size()); }
    /*!
     * @brief Return an upper-case'd copy of the current string
     * @return This
     */
    [[nodiscard]] String ToUpperCase() const { return String(*this).DoUpperCase(0, (int)size()); }

    /*!
     * @brief Convert current string to lowercase, starting at position "from"
     * @return This
     */
    String& LowerCase(int from) { return DoLowerCase(from, (int)size() - from); }
    /*!
     * @brief Return a partially lower-case'd copy of the current string
     * @return This
     */
    [[nodiscard]] String ToLowerCase(int from) const { return String(*this).DoLowerCase(from, (int)size() - from); }
    /*!
     * @brief Convert current string to uppercase, starting at position "from"
     * @return This
     */
    String& UpperCase(int from) { return DoUpperCase(from, (int)size() - from); }
    /*!
     * @brief Return a partially upper-case'd copy of the current string
     * @return This
     */
    [[nodiscard]] String ToUpperCase(int from) const { return String(*this).DoUpperCase(from, (int)size() - from); }

    /*!
     * @brief Convert the substring starting at "from" of length "length" to lowercase
     * @return This
     */
    String& LowerCase(int from, int length) { return DoLowerCase(from, length); }
    /*!
     * @brief Copy the current string and then convert the copy's substring
     * starting at "from" of length "length" to lowercase
     * @return This
     */
    [[nodiscard]] String ToLowerCase(int from, int length) const { return String(*this).DoLowerCase(from, length); }
    /*!
     * @brief Convert the substring starting at "from" of length "length" to uppercase
     * @return This
     */
    String& UpperCase(int from, int length) { return DoUpperCase(from, length); }
    /*!
     * @brief Copy the current string and then convert the copy's substring
     * starting at "from" of length "length" to uppercase
     * @return This
     */
    [[nodiscard]] String ToUpperCase(int from, int length) const { return String(*this).DoUpperCase(from, length); }

    /*
     * Split & Join
     */

    /*!
     * @brief Split the current string using the given char as separator
     * @param splitter Separator
     * @return List of string
     */
    [[nodiscard]] List Split(char splitter) const { List result; Split(*this, result, splitter, INT32_MAX, false); return result; }
    /*!
     * @brief Split the current string using the given char as separator, until the max item is reached.
     * subsequent separators are then ignored.
     * @param splitter Separator
     * @param max List limit
     * @return List of string
     */
    [[nodiscard]] List Split(char splitter, int maxItems) const { List result; Split(*this, result, splitter, maxItems, false); return result; }
    /*!
     * @brief Split the current string using the given char as separator
     * Concomitants separators may be considered as a single one
     * @param splitter Separator
     * @param mergeConcomitantSplitters True to consider concomitants separator as a single once
     * @return List of string
     */
    [[nodiscard]] List Split(char splitter, bool mergeConcomitantSplitters) const { List result; Split(*this, result, splitter, INT32_MAX, mergeConcomitantSplitters); return result; }
    /*!
     * @brief Split the current string using the given char as separator, until the max item is reached.
     * subsequent separators are then ignored.
     * Concomitants separators may be considered as a single one
     * @param splitter Separator
     * @param max List limit
     * @param mergeConcomitantSplitters True to consider concomitants separator as a single once
     * @return List of string
     */
    [[nodiscard]] List Split(char splitter, int maxItems, bool mergeConcomitantSplitters) const { List result; Split(*this, result, splitter, maxItems, mergeConcomitantSplitters); return result; }

    /*!
     * @brief Split the current string using the given c-string as separator
     * @param splitter Separator
     * @return List of string
     */
    [[nodiscard]] List Split(const char* splitter) const { List result; Split(*this, result, splitter, (int)strlen(splitter), INT32_MAX, false); return result; }
    /*!
     * @brief Split the current string using the given c-string as separator
     * Concomitants separators may be considered as a single one
     * @param splitter Separator
     * @param mergeConcomitantSplitters True to consider concomitants separator as a single once
     * @return List of string
     */
    [[nodiscard]] List Split(const char* splitter, bool mergeConcomitantSplitters) const { List result; Split(*this, result, splitter, (int)strlen(splitter), INT32_MAX, mergeConcomitantSplitters); return result; }
    /*!
     * @brief Split the current string using the given c-string as separator, until the max item is reached.
     * subsequent separators are then ignored.
     * Concomitants separators may be considered as a single one
     * @param splitter Separator
     * @param max List limit
     * @param mergeConcomitantSplitters True to consider concomitants separator as a single once
     * @return List of string
     */
    [[nodiscard]] List Split(const char* splitter, int maxItems, bool mergeConcomitantSplitters) const { List result; Split(*this, result, splitter, (int)strlen(splitter), maxItems, mergeConcomitantSplitters); return result; }

    /*!
     * @brief Split the current string using the given c-string as separator
     * @param splitter Separator
     * @return List of string
     */
    [[nodiscard]] List Split(const char* splitter, int splitterLength) const { List result; Split(*this, result, splitter, splitterLength, INT32_MAX, false); return result; }
    /*!
     * @brief Split the current string using the given c-string as separator, until the max item is reached.
     * subsequent separators are then ignored.
     * @param splitter Separator
     * @param max List limit
     * @return List of string
     */
    [[nodiscard]] List Split(const char* splitter, int splitterLength, int maxItems) const { List result; Split(*this, result, splitter, splitterLength, maxItems, false); return result; }
    /*!
     * @brief Split the current string using the given c-string as separator, until the max item is reached.
     * subsequent separators are then ignored.
     * Concomitants separators may be considered as a single one
     * @param splitter Separator
     * @param max List limit
     * @param mergeConcomitantSplitters True to consider concomitants separator as a single once
     * @return List of string
     */
    [[nodiscard]] List Split(const char* splitter, int splitterLength, int maxItems, bool mergeConcomitantSplitters) const { List result; Split(*this, result, splitter, splitterLength, maxItems, mergeConcomitantSplitters); return result; }

    /*!
     * @brief Split the current string using the given string as separator
     * @param splitter Separator
     * @return List of string
     */
    [[nodiscard]] List Split(const String& splitter) const { List result; Split(*this, result, splitter, splitter.Count(), INT32_MAX, false); return result; }
    /*!
     * @brief Split the current string using the given string as separator, until the max item is reached.
     * subsequent separators are then ignored.
     * @param splitter Separator
     * @param max List limit
     * @return List of string
     */
    [[nodiscard]] List Split(const String& splitter, bool mergeConcomitantSplitters) const { List result; Split(*this, result, splitter, splitter.Count(), INT32_MAX, mergeConcomitantSplitters); return result; }
    /*!
     * @brief Split the current string using the given string as separator, until the max item is reached.
     * subsequent separators are then ignored.
     * @param splitter Separator
     * @param max List limit
     * @return List of string
     */
    [[nodiscard]] List Split(const String& splitter, int maxItems) const { List result; Split(*this, result, splitter, splitter.Count(), maxItems, false); return result; }
    /*!
     * @brief Split the current string using the given string as separator, until the max item is reached.
     * subsequent separators are then ignored.
     * Concomitants separators may be considered as a single one
     * @param splitter Separator
     * @param max List limit
     * @param mergeConcomitantSplitters True to consider concomitants separator as a single once
     * @return List of string
     */
    [[nodiscard]] List Split(const String& splitter, int maxItems, bool mergeConcomitantSplitters) const { List result; Split(*this, result, splitter, splitter.Count(), maxItems, mergeConcomitantSplitters); return result; }

    /*!
     * @brief Split the current string using the given char as separator
     * Separators are ignored in part of the string enclosed with double quotes.
     * @param splitter Separator
     * @return List of string
     */
    [[nodiscard]] List SplitQuoted(char splitter) const { List result; SplitQuoted(*this, result, splitter, INT32_MAX, false); return result; }
    /*!
     * @brief Split the current string using the given char as separator, until the max item is reached.
     * subsequent separators are then ignored.
     * Separators are ignored in part of the string enclosed with double quotes.
     * @param splitter Separator
     * @param max List limit
     * @return List of string
     */
    [[nodiscard]] List SplitQuoted(char splitter, bool mergeConcomitantSplitters) const { List result; SplitQuoted(*this, result, splitter, INT32_MAX, mergeConcomitantSplitters); return result; }
    /*!
     * @brief Split the current string using the given char as separator
     * Separators are ignored in part of the string enclosed with double quotes.
     * Concomitants separators may be considered as a single one
     * @param splitter Separator
     * @param mergeConcomitantSplitters True to consider concomitants separator as a single once
     * @return List of string
     */
    [[nodiscard]] List SplitQuoted(char splitter, int maxItems) const { List result; SplitQuoted(*this, result, splitter, maxItems, false); return result; }
    /*!
     * @brief Split the current string using the given char as separator, until the max item is reached.
     * subsequent separators are then ignored.
     * Separators are ignored in part of the string enclosed with double quotes.
     * Concomitants separators may be considered as a single one
     * @param splitter Separator
     * @param max List limit
     * @param mergeConcomitantSplitters True to consider concomitants separator as a single once
     * @return List of string
     */
    [[nodiscard]] List SplitQuoted(char splitter, int maxItems, bool mergeConcomitantSplitters) const { List result; SplitQuoted(*this, result, splitter, maxItems, mergeConcomitantSplitters); return result; }

    /*!
     * @brief Split the current string using the given c-string as separator
     * Separators are ignored in part of the string enclosed with double quotes.
     * @param splitter Separator
     * @return List of string
     */
    [[nodiscard]] List SplitQuoted(const char* splitter) const { List result; SplitQuoted(*this, result, splitter, (int)strlen(splitter), INT32_MAX, false); return result; }
    /*!
     * @brief Split the current string using the given c-string as separator
     * Separators are ignored in part of the string enclosed with double quotes.
     * Concomitants separators may be considered as a single one
     * @param splitter Separator
     * @param mergeConcomitantSplitters True to consider concomitants separator as a single once
     * @return List of string
     */
    [[nodiscard]] List SplitQuoted(const char* splitter, bool mergeConcomitantSplitters) const { List result; SplitQuoted(*this, result, splitter, (int)strlen(splitter), INT32_MAX, mergeConcomitantSplitters); return result; }
    /*!
     * @brief Split the current string using the given c-string as separator, until the max item is reached.
     * subsequent separators are then ignored.
     * Separators are ignored in part of the string enclosed with double quotes.
     * Concomitants separators may be considered as a single one
     * @param splitter Separator
     * @param max List limit
     * @param mergeConcomitantSplitters True to consider concomitants separator as a single once
     * @return List of string
     */
    [[nodiscard]] List SplitQuoted(const char* splitter, int maxItems, bool mergeConcomitantSplitters) const { List result; SplitQuoted(*this, result, splitter, (int)strlen(splitter), maxItems, mergeConcomitantSplitters); return result; }

    /*!
     * @brief Split the current string using the given c-string as separator
     * Separators are ignored in part of the string enclosed with double quotes.
     * @param splitter Separator
     * @return List of string
     */
    [[nodiscard]] List SplitQuoted(const char* splitter, int splitterLength) const { List result; SplitQuoted(*this, result, splitter, splitterLength, INT32_MAX, false); return result; }
    /*!
     * @brief Split the current string using the given c-string as separator, until the max item is reached.
     * subsequent separators are then ignored.
     * Separators are ignored in part of the string enclosed with double quotes.
     * @param splitter Separator
     * @param max List limit
     * @return List of string
     */
    [[nodiscard]] List SplitQuoted(const char* splitter, int splitterLength, int maxItems) const { List result; SplitQuoted(*this, result, splitter, splitterLength, maxItems, false); return result; }
    /*!
     * @brief Split the current string using the given c-string as separator, until the max item is reached.
     * subsequent separators are then ignored.
     * Separators are ignored in part of the string enclosed with double quotes.
     * Concomitants separators may be considered as a single one
     * @param splitter Separator
     * @param max List limit
     * @param mergeConcomitantSplitters True to consider concomitants separator as a single once
     * @return List of string
     */
    [[nodiscard]] List SplitQuoted(const char* splitter, int splitterLength, int maxItems, bool mergeConcomitantSplitters) const { List result; SplitQuoted(*this, result, splitter, splitterLength, maxItems, mergeConcomitantSplitters); return result; }

    /*!
     * @brief Split the current string using the given string as separator
     * Separators are ignored in part of the string enclosed with double quotes.
     * @param splitter Separator
     * @return List of string
     */
    [[nodiscard]] List SplitQuoted(const String& splitter) const { List result; SplitQuoted(*this, result, splitter, splitter.Count(), INT32_MAX, false); return result; }
    /*!
     * @brief Split the current string using the given string as separator, until the max item is reached.
     * subsequent separators are then ignored.
     * Separators are ignored in part of the string enclosed with double quotes.
     * @param splitter Separator
     * @param max List limit
     * @return List of string
     */
    [[nodiscard]] List SplitQuoted(const String& splitter, bool mergeConcomitantSplitters) const { List result; SplitQuoted(*this, result, splitter, splitter.Count(), INT32_MAX, mergeConcomitantSplitters); return result; }
    /*!
     * @brief Split the current string using the given string as separator, until the max item is reached.
     * Concomitants separators may be considered as a single one
     * Separators are ignored in part of the string enclosed with double quotes.
     * @param splitter Separator
     * @param max List limit
     * @return List of string
     */
    [[nodiscard]] List SplitQuoted(const String& splitter, int maxItems) const { List result; SplitQuoted(*this, result, splitter, splitter.Count(), maxItems, false); return result; }
    /*!
     * @brief Split the current string using the given string as separator, until the max item is reached.
     * subsequent separators are then ignored.
     * Separators are ignored in part of the string enclosed with double quotes.
     * Concomitants separators may be considered as a single one
     * @param splitter Separator
     * @param max List limit
     * @param mergeConcomitantSplitters True to consider concomitants separator as a single once
     * @return List of string
     */
    [[nodiscard]] List SplitQuoted(const String& splitter, int maxItems, bool mergeConcomitantSplitters) const { List result; SplitQuoted(*this, result, splitter, splitter.Count(), maxItems, mergeConcomitantSplitters); return result; }

    /*!
     * @brief Join list items within a result string using a char separator
     * @param list Input list
     * @param joiner Char separator
     * @return Result string
     */
    [[nodiscard]] static String Join(const List& list, char joiner) { String result; JoinList<char>(list, joiner, result); return result; }
    /*!
     * @brief Join list items within a result string using a char separator
     * @param list Input list
     * @param joiner Unsigned char separator
     * @return Result string
     */
    [[nodiscard]] static String Join(const List& list, unsigned char joiner) { String result; JoinList<unsigned char>(list, joiner, result); return result; }
    /*!
     * @brief Join list items within a result string using a char separator
     * @param list Input list
     * @param joiner c-string separator
     * @return Result string
     */
    [[nodiscard]] static String Join(const List& list, const char* joiner) { String result; JoinList<const char*>(list, joiner, (int)strlen(joiner), result); return result; }
    /*!
     * @brief Join list items within a result string using a char separator
     * @param list Input list
     * @param joiner c-string separator
     * @param joinerLength separator length in char
     * @return Result string
     */
    [[nodiscard]] static String Join(const List& list, const char* joiner, int joinerLength) { String result; JoinList<const char*>(list, joiner, joinerLength, result); return result; }
    /*!
     * @brief Join list items within a result string using a char separator
     * @param list Input list
     * @param joiner String separator
     * @return Result string
     */
    [[nodiscard]] static String Join(const List& list, const String& joiner) { String result; JoinList<String>(list, joiner, result); return result; }

    /*
     * Extractors
     */

    /*!
     * @brief Split the current string on the first encountered separator char and extract both left and right sides
     * Both extracted strings may be optionally trimmed
     * @param separator Separator char
     * @param leftOutput Left extracted string
     * @param rightOutput Right extracted string
     * @param trim True to trim extracted strings, false to keep them as-is
     * @return True if the separator has been found and strings extracted, false otherwise
     */
    [[nodiscard]] bool Extract(char separator, String& leftOutput, String& rightOutput, bool trim) const
    {
      int position = Find(separator, 0);
      if (position < 0) return false;
      leftOutput.Assign(*this, 0, position);
      if (&rightOutput == this) rightOutput.Delete(0, position + 1);
      else rightOutput.Assign(*this, position + 1);
      if (trim) { leftOutput.Trim(); rightOutput.Trim(); }
      return true;
    }

    /*!
     * @brief Split the current string on the first encountered separator c-string and extract both left and right sides
     * Both extracted strings may be optionally trimmed
     * @param separator Separator char
     * @param leftOutput Left extracted string
     * @param rightOutput Right extracted string
     * @param trim True to trim extracted strings, false to keep them as-is
     * @return True if the separator has been found and strings extracted, false otherwise
     */
    [[nodiscard]] bool Extract(const char* separator, String& leftOutput, String& rightOutput, bool trim) const { return Extract(separator, (int)strlen(separator), leftOutput, rightOutput, trim); }
    /*!
     * @brief Split the current string on the first encountered separator c-string and extract both left and right sides
     * Both extracted strings may be optionally trimmed
     * @param separator Separator c-string
     * @param separatorLength Separator length
     * @param leftOutput Left extracted string
     * @param rightOutput Right extracted string
     * @param trim True to trim extracted strings, false to keep them as-is
     * @return True if the separator has been found and strings extracted, false otherwise
     */
    [[nodiscard]] bool Extract(const char* separator, int separatorLength, String& leftOutput, String& rightOutput, bool trim) const
    {
      int position = Find(separator, separatorLength, 0, INT32_MAX);
      if (position < 0) return false;
      leftOutput.Assign(*this, 0, position);
      if (&rightOutput == this) rightOutput.Delete(0, position + separatorLength);
      else rightOutput.Assign(*this, position + separatorLength);
      if (trim) { leftOutput.Trim(); rightOutput.Trim(); }
      return true;
    }
    /*!
     * @brief Split the current string on the first encountered separator string and extract both left and right sides
     * Both extracted strings may be optionally trimmed
     * @param separator Separator string
     * @param leftOutput Left extracted string
     * @param rightOutput Right extracted string
     * @param trim True to trim extracted strings, false to keep them as-is
     * @return True if the separator has been found and strings extracted, false otherwise
     */
    [[nodiscard]] bool Extract(const String& separator, String& leftOutput, String& rightOutput, bool trim) const
    {
      int position = Find(separator);
      if (position < 0) return false;
      leftOutput.Assign(*this, 0, position);
      if (&rightOutput == this) rightOutput.Delete(0, position + separator.Count());
      else rightOutput.Assign(*this, position + separator.Count());
      if (trim) { leftOutput.Trim(); rightOutput.Trim(); }
      return true;
    }

    /*!
     * @brief Extract the string between start and end char, and optionally trim the result
     * @param start Start char
     * @param end End char
     * @param output Output string filled with the string between start and end
     * @param trim True to trim the resulting string from ' \t\r\n' characters
     * @return True if start and end chars have been found and a string has been extracted into output, false otherwise
     */
    [[nodiscard]] bool Extract(char start, char end, String& output, bool trim) const
    {
      int startPos = Find(start);
      int endPos = Find(end, startPos + 1);
      if ((startPos | endPos) < 0) return false;
      output.Assign(*this, startPos + 1, endPos - (startPos + 1));
      if (trim) output.Trim();
      return true;
    }
    /*!
     * @brief Extract the string between start and end c-string, and optionally trim the result
     * @param start Start c-string
     * @param end End c-string
     * @param output Output string filled with the string between start and end
     * @param trim True to trim the resulting string from ' \t\r\n' characters
     * @return True if start and end c-strings have been found and a string has been extracted into output, false otherwise
     */
    [[nodiscard]] bool Extract(const char* start, const char* end, String& output, bool trim) const { return Extract(start, (int)strlen(start), end, (int)strlen(end), output, trim); }
    /*!
     * @brief Extract the string between start and end c-string, and optionally trim the result
     * @param start Start c-string
     * @param startLength Length of start c-string
     * @param end End c-string
     * @param endLength Length of end c-string
     * @param output Output string filled with the string between start and end
     * @param trim True to trim the resulting string from ' \t\r\n' characters
     * @return True if start and end c-strings have been found and a string has been extracted into output, false otherwise
     */
    [[nodiscard]] bool Extract(const char* start, int startLength, const char* end, int endLength, String& output, bool trim) const
    {
      int startPos = Find(start, startLength, 0, INT32_MAX);
      int endPos = Find(end, endLength, startPos + startLength, INT32_MAX);
      if ((startPos | endPos) < 0) return false;
      output.Assign(*this, startPos + startLength, endPos - (startPos + startLength));
      if (trim) output.Trim();
      return true;
    }
    /*!
     * @brief Extract the string between start and end string, and optionally trim the result
     * @param start Start string
     * @param end End string
     * @param output Output string filled with the string between start and end
     * @param trim True to trim the resulting string from ' \t\r\n' characters
     * @return True if start and end strings have been found and a string has been extracted into output, false otherwise
     */
    [[nodiscard]] bool Extract(const String& start, const String& end, String& output, bool trim) const
    {
      int startPos = Find(start);
      int endPos = Find(end, startPos + start.Count());
      if ((startPos | endPos) < 0) return false;
      output.Assign(*this, startPos + start.Count(), endPos - (startPos + start.Count()));
      if (trim) output.Trim();
      return true;
    }

    /*
     * Operator overrides
     */

    // Appenders

    //! Non const appending of another string in this string
    String& operator +=(const String& source) { append(source); return *this; }
    //! Const appending of another string to this string into a result string
    String operator +(const String& source) const { return String(*this).Append(source); }

    //! Non const appending of another std::string in this string
    String& operator +=(const std::string& source) { append(source); return *this; }
    //! Const appending of another std::string to this string into a result string
    String operator +(const std::string& source) const { return String(*this).Append(source); }
    //! Non const appending of c-string in this string
    String& operator +=(const char* source) { append(source); return *this; }
    //! Const appending of c-string to this string into a result string
    String operator +(const char* source) const { return String(*this).Append(source); }

    //! Non const char appending
    String& operator +=(char singleChar) { return Append(singleChar); }
    //! Const char appending
    String operator +(char singleChar) const { return String(*this).Append(singleChar); }
    //! Non const unsigned char appending
    String& operator +=(unsigned char singleChar) { return Append((char)singleChar); }
    //! Const unsigned char appending
    String operator +(unsigned char singleChar) const { return String(*this).Append((char)singleChar); }

    //! Non const bool appending
    String& operator +=(bool value) { return Append(value ? '1' : '0'); }
    //! Non const bool appending
    String operator +(bool value) const { return String(*this).Append(value ? '1' : '0'); }

    //! Non const short appending (signed value)
    String& operator +=(short value) { Int32Storage to; int l = ConvertNumeric<int, Int32Storage>((int)value, to); return Append(&to[sizeof(to) - l], l); }
    //! Non const short appending (signed value)
    String operator +(short value) const { Int32Storage to; int l = ConvertNumeric<int, Int32Storage>((int)value, to); return String(*this).Append(&to[sizeof(to) - l], l); }
    //! Construct from value (unsigned short)
    String& operator +=(unsigned short value) { Int32Storage to; int l = ConvertUnsignedNumeric<unsigned int, Int32Storage>((unsigned int)value, to); return Append(&to[sizeof(to) - l], l); }
    //! Construct from value (unsigned short)
    String operator +(unsigned short value) const { Int32Storage to; int l = ConvertUnsignedNumeric<unsigned int, Int32Storage>((unsigned int)value, to); return String(*this).Append(&to[sizeof(to) - l], l); }

    //! Non const int appending (signed value)
    String& operator +=(int value) { Int32Storage to; int l = ConvertNumeric<int, Int32Storage>((int)value, to); return Append(&to[sizeof(to) - l], l); }
    //! Non const int appending (signed value)
    String operator +(int value) const { Int32Storage to; int l = ConvertNumeric<int, Int32Storage>((int)value, to); return String(*this).Append(&to[sizeof(to) - l], l); }
    //! Construct from value (unsigned int)
    String& operator +=(unsigned int value) { Int32Storage to; int l = ConvertUnsignedNumeric<unsigned int, Int32Storage>((unsigned int)value, to); return Append(&to[sizeof(to) - l], l); }
    //! Construct from value (unsigned int)
    String operator +(unsigned int value) const { Int32Storage to; int l = ConvertUnsignedNumeric<unsigned int, Int32Storage>((unsigned int)value, to); return String(*this).Append(&to[sizeof(to) - l], l); }

    //! Non const long long appending (signed value)
    String& operator +=(long long value) { Int64Storage to; int l = ConvertNumeric<long long, Int64Storage>((long long)value, to); return Append(&to[sizeof(to) - l], l); }
    //! Non const long long appending (signed value)
    String operator +(long long value) const { Int64Storage to; int l = ConvertNumeric<long long, Int64Storage>((long long)value, to); return String(*this).Append(&to[sizeof(to) - l], l); }
    //! Construct from value (unsigned long long)
    String& operator +=(unsigned long long value) { Int64Storage to; int l = ConvertUnsignedNumeric<unsigned long long, Int64Storage>((unsigned long long)value, to); return Append(&to[sizeof(to) - l], l); }
    //! Construct from value (unsigned long long)
    String operator +(unsigned long long value) const { Int64Storage to; int l = ConvertUnsignedNumeric<unsigned long long, Int64Storage>((unsigned long long)value, to); return String(*this).Append(&to[sizeof(to) - l], l); }

    //! Non const float appending, default precision
    String& operator +=(float value) { FloatStorage to; int l = ConvertFloat<float, unsigned int, FloatStorage>(value, sDefaultFractionalPrecision, to); return Append(&to[sizeof(to) - l], l); }
    //! Const float appending, default precision
    String operator +(float value) const { FloatStorage to; int l = ConvertFloat<float, unsigned int, FloatStorage>(value, sDefaultFractionalPrecision, to); return String(*this).Append(&to[sizeof(to) - l], l); }
    //! Non const double appending, default precision
    String& operator +=(double value) { DoubleStorage to; int l = ConvertFloat<double, unsigned long long, DoubleStorage>(value, sDefaultFractionalPrecision, to); return Append(&to[sizeof(to) - l], l); }
    //! Const double appending, default precision
    String operator +(double value) const { DoubleStorage to; int l = ConvertFloat<double, unsigned long long, DoubleStorage>(value, sDefaultFractionalPrecision, to); return String(*this).Append(&to[sizeof(to) - l], l); }

    /*!
     * @brief Append the result of the Format instance
     * @param value Format instance
     * @return This
     */
    String& operator +=(const Format& value) { return Append(value); }
    /*!
     * @brief Copy the current string, then append the result of the Format instance
     * @param value Format instance
     * @return New string
     */
    String operator +(const Format& value) const { return String(*this).Append(value); }

    // Deleters

    //! Non const char deletion
    String& operator -=(char c) { return Remove(c); }
    //! Const char deletion
    String operator -(char c) const { return String(*this).Remove(c); }

    //! Non const char deletion
    String& operator -=(const char* string) { return Remove(string); }
    //! Const char deletion
    String operator -(const char* string) const { return String(*this).Remove(string); }

    //! Non const char deletion
    String& operator -=(const String& string) { return Remove(string); }
    //! Const char deletion
    String operator -(const String& string) const { return String(*this).Remove(string); }

    // Multipliers

    /*!
     * @brief Repeat the content of the current string "multiplier" times.
     * multiplier less than 2 have no effect
     * @param multiplier Number of times the current string must be repeated
     * @return This
     */
    String& operator *=(int multiplier) { for(int size = Count(); --multiplier > 0; ) Append(data(), size); return *this; }
    /*!
     * @brief Return a copy of the current string, repeated "multiplier" times.
     * multiplier less than 2 have no effect
     * @param multiplier Number of times the current string must be repeated
     * @return This
     */
    String operator *(int multiplier) const { String result(*this); for(int size = Count(); --multiplier > 0; ) result.Append(data(), size); return result; }

    // Splitters

    /*!
     * @brief Split the current string using the given char as separator
     * @param splitter Char separator
     * @return String list
     */
    List operator /(char splitter) const { List result; Split(*this, result, splitter, INT32_MAX, false); return result; }
    /*!
     * @brief Split the current string using the given c-string as separator
     * @param splitter C-string separator
     * @return String list
     */
    List operator /(const char* splitter) const { List result; Split(*this, result, splitter, (int)strlen(splitter), INT32_MAX, false); return result; }
    /*!
     * @brief Split the current string using the given string as separator
     * @param splitter string separator
     * @return String list
     */
    List operator /(const String& splitter) const { List result; Split(*this, result, splitter, splitter.Count(), INT32_MAX, false); return result; }

    // Comparators

    //! Type-routed std::string comparators
    //! Since we cannot call nearest parent's operator, we rely on the compiler decision, using cast to the immediate parent.
    bool operator ==(const String& value) const { return *((std::string*)this) == *((std::string*)&value); }
    bool operator ==(const char* value) const { return *((std::string*)this) == value; }
    bool operator !=(const String& value) const { return *((std::string*)this) != *((std::string*)&value); }
    bool operator !=(const char* value) const { return *((std::string*)this) != value; }
    bool operator <(const String& value) const { return *((std::string*)this) < *((std::string*)&value); }
    bool operator <(const char* value) const { return *((std::string*)this) < value; }
    bool operator >(const String& value) const { return *((std::string*)this) > *((std::string*)&value); }
    bool operator >(const char* value) const { return *((std::string*)this) > value; }
    bool operator <=(const String& value) const { return *((std::string*)this) <= *((std::string*)&value); }
    bool operator <=(const char* value) const { return *((std::string*)this) <= value; }
    bool operator >=(const String& value) const { return *((std::string*)this) >= *((std::string*)&value); }
    bool operator >=(const char* value) const { return *((std::string*)this) >= value; }
    #ifndef NO_STD_STRING_AUTOBOXING
    bool operator ==(const std::string& value) const { return *((std::string*)this) == value; }
    #endif

    //! Convert & compare current string to boolean value
    bool operator ==(bool value) const { return (ConvertToBool(0, 0, false) == value); }
    //! Convert & compare current string to boolean value
    bool operator !=(bool value) const { return (ConvertToBool(0, 0, false) != value); }

    //! Convert & compare current string to single char value
    bool operator ==(char value) const { return size() == 1 && data()[0] == value; }
    //! Convert & compare current string single char value
    bool operator !=(char value) const { return size() != 1 || data()[0] != value; }

    #define DefineComparatorForType(comparator, type) \
      /*! Convert & compare current string to type value */ \
      bool operator comparator(type value) const { return (ConvertToNumeric<type>(0, 0, 0) comparator value); } \
      /*! Convert & compare current string to unsigned type value */ \
      bool operator comparator(unsigned type value) const { return (ConvertToNumeric<unsigned type>(0, 0, 0) comparator value); }

    #define DefineDoubleComparatorForType(comparator, notComparator, type) \
      DefineComparatorForType(comparator, type)                                \
      DefineComparatorForType(notComparator, type)

    #define DefineComparatorsForNumericTypes(comparator, notComparator) \
      DefineDoubleComparatorForType(comparator, notComparator, short) \
      DefineDoubleComparatorForType(comparator, notComparator, int) \
      DefineDoubleComparatorForType(comparator, notComparator, long long) \

    DefineComparatorsForNumericTypes(==,!=)
    DefineComparatorsForNumericTypes(<,>)
    DefineComparatorsForNumericTypes(<=,>=)

    // Assignment operator

    /*!
     * @brief Copy assignment operator
     * @param source source string
     * @return This
     */
    String& operator =(const String& source) { if (&source != this) *((std::string*)this) = source; return *this; }
    /*!
     * @brief Move assignment operator
     * @param source source string
     * @return This
     */
    String& operator =(String&& source) noexcept { if (&source != this) *((std::string*)this) = source; return *this; }

    #ifdef NO_STD_STRING_AUTOBOXING
    /*!
     * @brief Copy assignment operator
     * @param source source string
     * @return This
     */
    String& operator =(const std::string& source) = delete;
    /*!
     * @brief Move assignment operator
     * @param source source string
     * @return This
     */
    String& operator =(std::string&& source) noexcept = delete;
    #else
    /*!
       * @brief Copy assignment operator
       * @param source source string
       * @return This
       */
      String& operator =(const std::string& source) { if (&source != this) *((std::string*)this) = source; return *this; }
      /*!
       * @brief Move assignment operator
       * @param source source string
       * @return This
       */
      String& operator =(std::string&& source) noexcept { if (&source != this) *((std::string*)this) = source; return *this; }
    #endif
    /*!
     * @brief Assign from c-string
     * @param source source c-string
     * @return This
     */
    String& operator =(const char* source) { std::string::assign(source); return *this; }
    /*!
     * @brief Assign from single char
     * @param source source single char
     * @return This
     */
    String& operator =(const char source) { std::string::assign(1, source); return *this; }

    /*!
     * @brief Assign from single unsigned char
     * @param source source single unsigned char
     * @return This
     */
    String& operator =(unsigned char source) { Assign((char)source); return *this; }

    /*!
     * @brief Assign from boolean value ('0'/'1')
     * @param source source single unsigned char
     * @return This
     */
    String& operator =(bool source) { Assign(source ? '1' : '0'); return *this; }

    /*!
     * @brief Assign from signed short value
     * @param source source signed short value
     * @return This
     */
    String& operator =(short source) { Int32Storage to; int l = ConvertNumeric<int, Int32Storage>((int)source, to); Assign(&to[sizeof(to) - l], l); return *this; }
    /*!
     * @brief Assign from unsigned short value
     * @param source source unsigned short value
     * @return This
     */
    String& operator =(unsigned short source) { Int32Storage to; int l = ConvertUnsignedNumeric<unsigned int, Int32Storage>((unsigned int)source, to); Assign(&to[sizeof(to) - l], l); return *this; }

    /*!
     * @brief Assign from signed int value
     * @param source source signed int value
     * @return This
     */
    String& operator =(int source) { Int32Storage to; int l = ConvertNumeric<int, Int32Storage>((int)source, to); Assign(&to[sizeof(to) - l], l); return *this; }
    /*!
     * @brief Assign from unsigned int value
     * @param source source unsigned int value
     * @return This
     */
    String& operator =(unsigned int source) { Int32Storage to; int l = ConvertUnsignedNumeric<unsigned int, Int32Storage>((unsigned int)source, to); Assign(&to[sizeof(to) - l], l); return *this; }

    /*!
     * @brief Assign from signed long long value
     * @param source source signed long long value
     * @return This
     */
    String& operator =(long long source) { Int64Storage to; int l = ConvertNumeric<long long, Int64Storage>((long long)source, to); Assign(&to[sizeof(to) - l], l); return *this; }
    /*!
     * @brief Assign from unsigned long long value
     * @param source source unsigned long long value
     * @return This
     */
    String& operator =(unsigned long long source) { Int64Storage to; int l = ConvertUnsignedNumeric<unsigned long long, Int64Storage>((unsigned long long)source, to); Assign(&to[sizeof(to) - l], l); return *this; }

    /*!
     * @brief Assign from float value
     * @param source source float value
     * @return This
     */
    String& operator =(float source) { FloatStorage to; int l = ConvertFloat<float, unsigned int, FloatStorage>(source, sDefaultFractionalPrecision, to); Assign(&to[sizeof(to) - l], l); return *this; }
    /*!
     * @brief Assign from double value
     * @param source source double value
     * @return This
     */
    String& operator =(double source) { DoubleStorage to; int l = ConvertFloat<double, unsigned long long, DoubleStorage>(source, sDefaultFractionalPrecision, to); Assign(&to[sizeof(to) - l], l); return *this; }

    /*!
     * @brief Replace the content of the current string with the Format instance output
     * @param format Format instance
     * @return This
     */
    String& operator =(const Format& format) { Assign(format); return *this; }

    // Boolean operator

    //! Convert to bool
    explicit operator bool() const { return ConvertToBool(0, 0, false); }
    //! Convert to not bool
    bool operator !() const { return !ConvertToBool(0, 0, false); }

  private:
    // Privatize type-routed methods
    using std::string::append;
    using std::string::assign;
    using std::string::insert;
    using std::string::substr;

    /*
     * Counters
     */

    /*!
     * @brief Count char occurrence in the given string
     * @param c Char to count occurrences of
     * @return Char count
     */
    [[nodiscard]] int CountCharOccurrences(char c) const
    {
      int count = 0;
      const LargestType * p = (LargestType *)data();
      for(int l = Count() >> sLargestTypeBits; --l >= 0; )
      {
        LargestType v = *p++;
        for(int i = sLargestTypeSize; --i >= 0; v >>= 8)
          if ((char)v == c)
            count++;
      }
      const char* r = (char*)p;
      for(int l = Count() & sLargestTypeMask; --l >= 0; )
        if (*r++ == c)
          count++;
      return count;
    }

    /*!
     * @brief Count control char occurrences in the given string
     * @return Control char count
     */
    [[nodiscard]] int CountControlCharOccurrences() const
    {
      int count = 0;
      const LargestType * p = (LargestType *)data();
      for(int l = Count() >> sLargestTypeBits; --l >= 0; )
      {
        LargestType v = *p++;
        for(int i = sLargestTypeSize; --i >= 0; v >>= 8)
          if (char c = (char)v; (c != 9) && (c < 32))
            count++;
      }
      const char* r = (char*)p;
      for(int l = Count() & sLargestTypeMask; --l >= 0; )
        if (char c = *r++; (c != 9) && (c < 32))
          count++;
      return count;
    }

    /*
     * Converters (types TO string)
     */

    /*!
     * @brief Convert a numeric value T, with possible leading negative sign,
     * into its hexadecimal representation
     * @tparam T numeric type (int, long long, ...)
     * @tparam S storage type
     * @param value Value to convert
     * @param size Minimum output size, add leading 0 if necessary
     * @param to output storage
     * @return Length of converted value in char
     */
    template<typename T, typename S> [[nodiscard]] static int ConvertNumericToHexa(T value, int size, S& to, Hexa prefix)
    {
      const char* hexa = "0123456789ABCDEF";
      if (size > (int)sizeof(S) - 3) size = (int)sizeof(S) - 3;

      to[sizeof(to) - 1] = 0;
      int Index = sizeof(to);
      int Sign = value >> (8 * sizeof(T) - 1); // shift sign by max bit-1

      if (Sign < 0) { value = -value; do { to[--Index] = hexa[value & 0xF]; value >>= 4; } while (value != 0 && Index > 3); }
      else do { to[--Index] = hexa[value & 0xF]; value >>= 4; } while (value != 0 && Index > 3);
      size -= sizeof(to) - Index;
      while(--size >= 0 && Index > 3) to[--Index] = '0';
      switch(prefix)
      {
        case Hexa::C: to[--Index] = 'x'; to[--Index] = '0'; break;
        case Hexa::Asm: to[--Index] = '$';
        case Hexa::None:
        default: break;
      }
      if (Sign < 0) to[--Index] = '-';

      return (int)sizeof(to) - Index;
    }

    /*!
     * @brief Convert an unsigned numeric value T, into its hexadecimal representation
     * @tparam T numeric type (int, long long, ...)
     * @tparam S storage type
     * @param value Value to convert
     * @param size Minimum output size, add leading 0 if necessary
     * @param to output storage
     * @return Length of converted value in char
     */
    template<typename T, typename S> [[nodiscard]] static int ConvertUnsignedNumericToHexa(T value, int size, S& to, Hexa prefix)
    {
      const char* hexa = "0123456789ABCDEF";
      if (size > (int)sizeof(S) - 2) size = (int)sizeof(S) - 2;

      to[sizeof(to) - 1] = 0;
      int Index = sizeof(to);

      do { to[--Index] = hexa[value & 0xF]; value >>= 4; } while (value != 0 && Index > 2);
      size -= sizeof(to) - Index;
      while(--size >= 0 && Index > 2) to[--Index] = '0';
      switch(prefix)
      {
        case Hexa::C: to[--Index] = 'x'; to[--Index] = '0'; break;
        case Hexa::Asm: to[--Index] = '$';
        case Hexa::None:
        default: break;
      }

      return (int)sizeof(to) - Index;
    }

    /*!
     * @brief Convert a numeric value T, with possible leading negative sign
     * @tparam T numeric type (int, long long, ...)
     * @tparam S storage type
     * @param value Value to convert
     * @param to output storage
     * @return Length of converted value in char
     */
    template<typename T, typename S> [[nodiscard]] static int ConvertNumeric(T value, S& to)
    {
      to[sizeof(to) - 1] = 0;
      int Index = sizeof(to);
      bool Sign = (value < 0);

      if (Sign) { do { to[--Index] = (char)(0x30 + -(value % 10)); value /= 10; } while (value != 0 && Index > 1); to[--Index] = '-'; }
      else do { to[--Index] = (char)(0x30 +  (value % 10)); value /= 10; } while (value != 0 && Index != 0);

      return (int)sizeof(to) - Index;
    }

    /*!
     * @brief Convert an unsigned numeric value T
     * @tparam T numeric type (int, long long, ...)
     * @tparam S storage type
     * @param value Value to convert
     * @param to output storage
     * @return Length of converted value in char
     */
    template<typename T, typename S> [[nodiscard]] static int ConvertUnsignedNumeric(T value, S& to)
    {
      to[sizeof(to) - 1] = 0;
      int Index = sizeof(to);

      do { to[--Index] = (char)(0x30 +  (value % 10)); value /= 10; } while (value != 0 && Index != 0);

      return (int)sizeof(to) - Index;
    }

    /*!
     * @brief Convert a floating value of type T to a string
     * @tparam F Floating point type (float, double, ...)
     * @tparam I Integer type to hold the integer part of the Floating point type
     * @tparam S Storage type
     * @param value Value to convert
     * @param precision Number of digit after the '.'
     * @param to Output storage
     * @return Length of converted value in char
     */
    template<typename F, typename I, typename S> [[nodiscard]] static int ConvertFloat(F value, int precision, S& to)
    {
      static F Pow10[] =
        {
          (F)1,
          (F)10,
          (F)100,
          (F)1000,
          (F)10000,
          (F)100000,
          (F)1000000,
          (F)10000000,
          (F)100000000,
          (F)1000000000,
          (F)10000000000,
        };

      // Sign
      bool sign = value < (F)0;
      if (sign) value = -value;

      to[sizeof(to) - 1] = 0;
      int index = sizeof(to);

      // Extract integer part
      I integer = (I)value;

      // Fractional part
      if (precision > 0)
      {
        if (precision > 10) precision = 10;
        // Extract floating part
        F fPart = value - (F)integer;
        // Take it as an integer
        fPart *= Pow10[precision];
        I iPart = (I)fPart;
        // Write value
        while(--precision >= 0) { to[--index] = (char)(0x30 + (iPart % 10)); iPart /= 10; }
        to[--index] = '.';
      }

      // Write integer part
      do { to[--index] = (char)(0x30 + (integer % 10)); integer /= 10; } while (integer != 0);
      if (sign) to[--index] = '-';

      return (int)sizeof(to) - index;
    }

    /*
     * Converters (types FROM string)
     */

    /*!
     * @brief Convert a boolean value in the string to boolean value
     * it recognize 0/1 and true/false case insensitive
     * @param from First character in the string to check for a boolean value
     * @param stop stop char, must follow the last boolean character
     * @param defaultValue Default value if no boolean value is found at pos
     * @return Converted boolean value or default value
     */
    [[nodiscard]] bool ConvertToBool(int from, char stop, bool defaultValue) const
    {
      if ((unsigned int)from < size())
      {
        const char* p = data() + from;
        if (p[0] == '1' && p[1] == stop) return true;
        if (p[0] == '0' && p[1] == stop) return false;
        int l = (int)size() - from;
        if ((l >= 4) && ((p[0] | 0x20) == 't') && ((p[1] | 0x20) == 'r') && ((p[2] | 0x20) == 'u') && ((p[3] | 0x20) == 'e') && (p[4] == stop)) return true;
        if ((l >= 5) && ((p[0] | 0x20) == 'f') && ((p[1] | 0x20) == 'a') && ((p[2] | 0x20) == 'l') && ((p[3] | 0x20) == 's') && ((p[4] | 0x20) == 'e') && (p[5] == stop)) return false;
      }
      return defaultValue;
    }

    /*!
     * @brief Try converting a boolean value in the string to boolean value
     * it recognize 0/1 and true/false case insensitive
     * @param from First character in the string to check for a boolean value
     * @param stop stop char, must follow the last boolean character
     * @param[out] output boolean reference to fill with the converted value if possible
     * @return True if a value has been converted and output contains a valid value, false otherwise
     */
    [[nodiscard]] bool TryConvertingToBool(int from, char stop, bool& output) const
    {
      if ((unsigned int)from < size())
      {
        const char* p = data() + from;
        if (p[0] == '1' && p[1] == stop) { output = true; return true; }
        if (p[0] == '0' && p[1] == stop) { output = false; return true; }
        int l = (int)size() - from;
        if ((l >= 4) && ((p[0] | 0x20) == 't') && ((p[1] | 0x20) == 'r') && ((p[2] | 0x20) == 'u') && ((p[3] | 0x20) == 'e') && (p[4] == stop)) { output = true; return true; }
        if ((l >= 5) && ((p[0] | 0x20) == 'f') && ((p[1] | 0x20) == 'a') && ((p[2] | 0x20) == 'l') && ((p[3] | 0x20) == 's') && ((p[4] | 0x20) == 'e') && (p[5] == stop)) { output = false; return true; }
      }
      return false;
    }

    /*!
     * @brief Convert string to a float value.
     * @tparam T Float type value (float, double, ...)
     * @tparam S Integer type that can hold integer part
     * @param from First character to convert
     * @param stop stop char, must follow the last converted character
     * @param defaultValue Default value if no float or invalid float value is found at "from"
     * @return Converted value or default value
     */
    template<typename T, typename S> [[nodiscard]] T ConvertToFloat(int from, char stop, T defaultValue) const
    {
      if ((unsigned int)from >= size()) return defaultValue;
      const char* src = data() + from;

      S IntPart = 0;
      S FracPart = 0;
      S Pow10 = 1;
      if (src[0] == '-') { Pow10 = -1; ++src; }

      // Integer part
      while ((unsigned int)(src[0] - 0x30) <= 9) { IntPart *= 10; IntPart += src[0] - 0x30; src++; }
      IntPart *= Pow10;
      if (src[0] == '.')
        while ((unsigned int)(*(++src) - 0x30) <= 9) { FracPart *= 10; FracPart += src[0] - 0x30; Pow10 *= 10; }
      if (src[0] != stop) return defaultValue;

      return (T)IntPart + ((T)FracPart / (T)Pow10);
    }

    /*!
     * @brief Try to convert string to a float value.
     * @tparam T Float type value (float, double, ...)
     * @tparam S Integer type that can hold integer part
     * @param from First character to convert
     * @param stop stop char, must follow the last converted character
     * @param defaultValue Default value if no float or invalid float value is found at "from"
     * @return Converted value or default value
     */
    template<typename T, typename S> [[nodiscard]] bool TryConvertingToFloat(int from, char stop, T& out) const
    {
      if ((unsigned int)from >= size()) return false;
      const char* src = data() + from;

      S IntPart = 0;
      S FracPart = 0;
      S Pow10 = 1;
      if (src[0] == '-') { Pow10 = -1; ++src; }

      // Integer part
      while ((unsigned int)(src[0] - 0x30) <= 9) { IntPart *= 10; IntPart += src[0] - 0x30; src++; }
      IntPart *= Pow10;
      if (src[0] == '.')
        while ((unsigned int)(*(++src) - 0x30) <= 9) { FracPart *= 10; FracPart += src[0] - 0x30; Pow10 *= 10; }
      if (src[0] != stop) return false;

      out = (T)IntPart + ((T)FracPart / (T)Pow10);
      return true;
    }

    /*!
     * @brief Convert raw hexadecimal string value to a T numeric type
     * @tparam T numeric type (int, long long, ...)
     * @param from Position of first hexadecimal digit
     * @param stop stop char, must follow the last digit
     * @param defaultValue default value if the conversion fails
     * @return Converted value or default value
     */
    template<typename T> [[nodiscard]] T ConvertHexaToNumeric(int from, char stop, T defaultValue) const
    {
      if ((unsigned int)from < size())
      {
        const char* p = data() + from;
        T result = 0;
        for (;; ++p)
        {
          if ((unsigned int)(p[0] - '0') <= 9) result = (result << 4) | (int) ((unsigned int) p[0] - '0');
          else if ((unsigned int)((p[0] | 0x20) - 'a') <= 5) result = (result << 4) | (10 + (int) ((unsigned int)((p[0] | 0x20) - 'a')));
          else break;
        }
        if (p[0] == stop) return result;
      }
      return defaultValue;
    }

    /*!
     * @brief Convert an integer value in the string to a T numeric type
     * it recognize decimal value and hexadecimal values with $ or 0x prefixes
     * @tparam T numeric type (int, long long, ...)
     * @param from First character in the string to check for an int value
     * @param stop stop char, must follow the last int character
     * @param defaultValue Default value if no int value is found at pos
     * @return Converted boolean value or default value
     */
    template<typename T> [[nodiscard]] T ConvertToNumeric(int from, char stop, T defaultValue) const
    {
      int l = (int)size() - from;
      if (l <= 0) return defaultValue;

      const char* p = data() + from;
      T result = 0;
      int sign = 1;
      if ((T)-1 < (T)1) // Type is signed? This test is always true or false and is eliminated at compilation time
        if (p[0] == '-') { sign = -1; ++p; if (--l <= 0) return defaultValue; }
      if (p[0] == '$' || (p[0] == '0' && p[1] == 'x')) // Still safe to look next character as it can be the zero terminal
      {
        ++p; if (p[0] == 'x') ++p;
        return ConvertHexaToNumeric<T>((int)(p - data()), stop, defaultValue) * sign;
      }
      else
      {
        for (;; ++p)
        {
          if ((unsigned int) p[0] - '0' > 9) break;
          result = (result * 10) + (int) ((unsigned int) p[0] - '0') * sign;
        }
        if (p[0] == stop) return result;
      }
      return defaultValue;
    }

    /*!
     * @brief Try to convert raw hexadecimal string value to a numeric T value
     * @tparam T numeric type (int, long long, ...)
     * @param from Position of first hexadecimal digit
     * @param stop stop char, must follow the last digit
     * @param[out] output int reference to fill with the converted value if possible
     * @return True if a value has been converted and output contains a valid value, false otherwise
     */
    template<typename T> [[nodiscard]] bool TryConvertingHexaToNumeric(int from, char stop, T& output) const
    {
      if ((unsigned int)from < size())
      {
        const char* p = data() + from;
        T result = 0;
        for (;; ++p)
        {
          if ((unsigned int)(p[0] - '0') <= 9) result = (result << 4) | (int) ((unsigned int) p[0] - '0');
          else if ((unsigned int)((p[0] | 0x20) - 'a') <= 5) result = (result << 4) | (10 + (int) ((unsigned int)((p[0] | 0x20) - 'a')));
          else break;
        }
        if (p[0] == stop) { output = result; return true; }
      }
      return false;
    }

    /*!
     * @brief Try converting an integer value in the string into a numeric T type
     * it recognize decimal value and hexadecimal values with $ or 0x prefixes
     * @tparam T numeric type (int, long long, ...)
     * @param from First character in the string to check for an int value
     * @param stop stop char, must follow the last int character
     * @param[out] output int reference to fill with the converted value if possible
     * @return True if a value has been converted and output contains a valid value, false otherwise
     */
    template<typename T> [[nodiscard]] bool TryConvertingToNumeric(int from, char stop, T& output) const
    {
      int l = (int)size() - from;
      if (l <= 0) return false;

      const char* p = data() + from;
      T result = 0;
      int sign = 1;
      if ((T)-1 < (T)1) // Type is signed? This test is always true or false and is eliminated at compilation time
        if (p[0] == '-') { sign = -1; ++p; if (--l <= 0) return false; }
      if (p[0] == '$' || (p[0] == '0' && p[1] == 'x')) // Still safe to look next character as it can be the zero terminal
      {
        ++p; if (p[0] == 'x') ++p;
        bool ok = TryConvertingHexaToNumeric<T>((int)(p - data()), stop, output);
        output *= sign;
        return ok;
      }
      else
      {
        for (;; ++p)
        {
          if ((unsigned int) p[0] - '0' > 9) break;
          result = (result * 10) + (int) ((unsigned int) p[0] - '0') * sign;
        }
        if (p[0] == stop) { output = result; return true; }
      }
      return false;
    }

    /*
     * CASE management
     */

    /*!
     * @brief Lowercase 'A'-'Z' in the current string, starting from "from", for "length" characters
     * @param from First character to lower
     * @param length Number of character to lower
     * @return This
     */
    String& DoLowerCase(int from, int length)
    {
      // Check bounds
      if ((unsigned int)from >= size()) return *this;
      if (from + length > (int)size()) length = (int)size() - from;

      unsigned char* p = (unsigned char*)data() + from;
      // Try big steps
      if (length >= (int)sizeof(LargestType))
      {
        // Realign first
        int l = (sLargestTypeSize - (from & sLargestTypeMask)) & sLargestTypeMask;
        for(length -= l; --l >= 0; ++p)
          if ((unsigned int)((unsigned char)*p - (unsigned char)'A') < 26u)
            *p = *p | 0x20;
        // Then big steps
        LargestType* p2 = (LargestType*)p;
        l = length >> sLargestTypeBits;
        for(; --l >= 0; ++p2)
        {
          LargestType v = *p2;
          bool modified = false;
          for(int i = sLargestTypeSize; --i >= 0;)
            if ((unsigned int)((unsigned char)(v >> (8 * i)) - (unsigned char)'A') < 26u)
            {
              v |= (LargestType)0x20 << (8 * i);
              modified = true;
            }
          if (modified) *p2 = v;
        }
        // Update char pointer & length
        length &= sLargestTypeMask;
        p = (unsigned char*)p2;
      }
      // Remaining bytes
      for(; --length >= 0; ++p)
        if ((unsigned int)((unsigned char)*p - (unsigned char)'A') < 26u)
          *p = *p | 0x20;
      return *this;
    }

    /*!
     * @brief Uppercase 'A'-'Z' in the current string, starting from "from", for "length" characters
     * @param from First character to upper
     * @param length Number of character to upper
     * @return This
     */
    String& DoUpperCase(int from, int length)
    {
      // Check bounds
      if ((unsigned int)from >= size()) return *this;
      if (from + length > (int)size()) length = (int)size() - from;

      unsigned char* p = (unsigned char*)data() + from;
      // Try big steps
      if (length >= (int)sizeof(LargestType))
      {
        // Realign first
        int l = (sLargestTypeSize - (from & sLargestTypeMask)) & sLargestTypeMask;
        for(length -= l; --l >= 0; ++p)
          if ((unsigned int)((unsigned char)*p - (unsigned char)'a') < 26u)
            *p = *p & ~0x20;
        // Then big steps
        LargestType* p2 = (LargestType*)p;
        l = length >> sLargestTypeBits;
        for(; --l >= 0; ++p2)
        {
          LargestType v = *p2;
          bool modified = false;
          for(int i = sLargestTypeSize; --i >= 0;)
            if ((unsigned char)((unsigned char)(v >> (8 * i)) - (unsigned char)'a') < 26u)
            {
              v &= ~((LargestType)0x20 << (8 * i));
              modified = true;
            }
          if (modified) *p2 = v;
        }
        // Update char pointer & length
        length &= sLargestTypeMask;
        p = (unsigned char*)p2;
      }
      // Remaining bytes
      for(; --length >= 0; ++p)
        if ((unsigned int)((unsigned char)*p - (unsigned char)'a') < 26u)
          *p = *p & ~0x20;
      return *this;
    }

    /*
     * Hashes
     */

    /*!
     * @brief MurMur hash implementation - fast, very good distribution
     * This is a variant of MurmurHash2 modified to use the Merkle-Damgard
     * construction. Bulk speed should be identical to Murmur2, small-key speed
     * will be 10%-20% slower due to the added overhead at the end of the hash.
     * This variant fixes a minor issue where null keys were more likely to
     * collide with each other than expected, and also makes the algorithm
     * more amenable to incremental implementations. All other caveats from
     * MurmurHash2 still apply.
     * @param string String to hash
     * @param len String length
     * @param seed
     * @return
     */
    [[nodiscard]] static unsigned int MurMurHash2A(const char *string, int len)
    {
      if (len < 0) return 0;
      #define MurMurMix(h,k) { k *= m; k ^= k >> r; k *= m; h *= m; h ^= k; }
      static constexpr unsigned int fixedSeed = 0x1b873593;

      const unsigned int m = 0x5bd1e995;
      const int r = 24;
      unsigned int l = len;
      unsigned int h = fixedSeed;
      const unsigned char * data = (const unsigned char *)string;

      for(int steps4 = len >> 2; --steps4 >= 0; data += 4)
      {
        unsigned int k = *(unsigned int*)data;
        MurMurMix(h, k);
      }

      // Since we're in a zero-terminal string, we can read one more byte
      unsigned int t = 0;
      switch(len & 3)
      {
        case 3: t = *(unsigned int*)data; break;
        case 2: t = *(unsigned short*)data; break;
        case 1: t = data[0]; break;
        default: break;
      }

      MurMurMix(h,t);
      MurMurMix(h,l);

      h ^= h >> 13;
      h *= m;
      h ^= h >> 15;

      return h;
      #undef MurMurMix
    }

    /*!
     * @brief 64bit MurMur hash implementation - fast, very good distribution
     * This is a basic MurmurHash2 w/o the Merkle-Damgard construction.
     * All caveats from MurmurHash2 still apply.
     * @param string String to hash
     * @param len String length
     * @return 64bit hash
     */
    #if (__WORDSIZE == 64)
    [[nodiscard]] static unsigned long long MurMurHash64A(const void* string, int len)
    {
      if (len < 0) return 0;
      static constexpr unsigned int fixedSeed = 0x1b873593;
      const unsigned long long m = 0xc6a4a7935bd1e995;
      const int r = 47;
      unsigned long long h = fixedSeed ^ (len * m);

      const unsigned long long * data = (const unsigned long long *)string;
      for(int ll = len >> 3; --ll >= 0; )
      {
        unsigned long long k = *data++;
        k *= m; k ^= k >> r; k *= m;
        h ^= k; h *= m;
      }

      // Since we're in a zero-terminal string, we can read one more byte
      unsigned long long t = 0;
      switch(len & 7)
      {
        case 7: t = data[0]; h ^= t; h*= m; break;
        case 6: t = *((unsigned int*)data) | (((unsigned long long)*((unsigned short*)&data[1])) << 32); h ^= t; h *= m; break;
        case 5: t = *((unsigned int*)data) | (((unsigned long long)*((unsigned char*)&data[1])) << 32); h ^= t; h *= m; break;
        case 4: // 4/3 bytes = read int
        case 3: t = *((unsigned int*)data); h ^= t; h *= m; break;
        case 2: t = *((unsigned short*)data); h ^= t; h *= m; break;
        case 1: t = *((unsigned char*)data); h ^= t; h *= m; break;
        default: break;
      }

      h ^= h >> r; h *= m; h ^= h >> r;
      return h;
    }
    #else
    [[nodiscard]] static unsigned long long MurMurHash64A(const void* string, int len)
    {
      if (len < 0) return 0;
      static constexpr unsigned int fixedSeed = 0x1b873593;
      const unsigned int m = 0x5bd1e995;
      const int r = 24;
      unsigned int h1 = fixedSeed ^ len;
      unsigned int h2 = 0;

      const unsigned int * data = (const unsigned int *)string;
      // 64bits steps
      for(int ll = len >> 3; --ll >= 0; )
      {
        unsigned int k1 = *data++;
        k1 *= m; k1 ^= k1 >> r; k1 *= m;
        h1 *= m; h1 ^= k1;
        unsigned int k2 = *data++;
        k2 *= m; k2 ^= k2 >> r; k2 *= m;
        h2 *= m; h2 ^= k2;
      }
      // Remaining plain 32bits
      if(len >= 4)
      {
        unsigned int k1 = *data++;
        k1 *= m; k1 ^= k1 >> r; k1 *= m;
        h1 *= m; h1 ^= k1;
      }
      // Remaining bytes - since we're in a zero-terminal string, we can read one more byte
      switch(len & 3)
      {
        case 3: h2 ^= *((unsigned int*)data); h2 *= m; break;
        case 2: h2 ^= *((unsigned short*)data); h2 *= m; break;
        case 1: h2 ^= *((unsigned char*)data); h2 *= m; break;
        default: break;
      };

      h1 ^= h2 >> 18; h1 *= m;
      h2 ^= h1 >> 22; h2 *= m;
      h1 ^= h2 >> 17; h1 *= m;
      h2 ^= h1 >> 19; h2 *= m;

      unsigned long long h = h1;
      h = (h << 32) | h2;
      return h;
    }
    #endif

    /*
     * Unicode
     */

    Unicode DecodeUTF8Char(int& from) const
    {
      const char* p = data() + from;
      char c = p[0];

      // 0xxxxxxx, one byte character
      if ((c & 0x80) == 0) { from++; return (Unicode)c; }
      // 110xxxxx, two byte character (110xxxxx 10xxxxxx)
      if ((c & 0xE0) == 0xC0) { from += 2; return (Unicode)((c & 0x1F) <<  6) | (Unicode)(p[1] & 0x3F); }
      // 1110xxxx, three byte character (1110xxxx 10xxxxxx 10xxxxxx)
      if ((c & 0xF0) == 0xE0) { from += 3; return (Unicode)((c & 0x0F) << 12) | (Unicode)((p[1] & 0x3F) <<  6) | (Unicode)(p[2] & 0x3F); }
      // 11110xxx, four byte character (11110xxx 10xxxxxx 10xxxxxx 10xxxxxx)
      if ((c & 0xF8) == 0xF0) { from += 4; return (Unicode)((c & 0x07) << 18) | (Unicode)((p[1] & 0x3F) << 12) | (Unicode)((p[2] & 0x3F) <<  6) | (Unicode)(p[3] & 0x3F); }
      // error, invalid unicode
      from++;
      return (Unicode)'?';
    }

    static int EncodeUTF8Char(Unicode unicode, UnicodeStorage& to)
    {
      // one byte character
      if ((unicode >>  7) == 0) { to[0] = (char)unicode; return 1; }
      // two byte character
      if ((unicode >> 11) == 0) { to[0] = (char)((unicode >> 6) | 0xC0); to[1] = (char)((unicode & 0x3F) | 0x80); return 2; }
      // three byte character
      if ((unicode >> 16) == 0) { to[0] = (char)((unicode >> 12) | 0xE0); to[1] = (char)(((unicode >> 6) & 0x3F) | 0x80); to[2] = (char)((unicode & 0x3F) | 0x80); return 3; }
      // four byte character
      if ((unicode >> 21) == 0) { to[0] = (char)((unicode >> 18) | 0xF0); to[1] = (char)(((unicode >> 12) & 0x3F) | 0x80); to[2] = (char)(((unicode >> 6) & 0x3F) | 0x80); to[3] = (char)((unicode & 0x3F) | 0x80); return 4; }
      // error, invalid unicode
      to[0] = '?';
      return 1;
    }

    /*!
     * @brief Move the position forward, skipping "count" UTF8 characters
     * @param position Initial position
     * @param count Amount of UTF8 character to move over
     * @return New position
     */
    [[nodiscard]] int MoveForwardUTF8(int position, int count) const
    {
      for(int l = Count(); position < l && --count >= 0; )
        while(position < l)
          if ((std::string::operator[](++position) & 0xC0) != 0x80)
            break; // break inner loop
      return position;
    }

    /*!
     * @brief Move the position backward, skipping "count" UTF8 characters
     * @param position Initial position
     * @param count Amount of UTF8 character to move over
     * @return New position
     */
    [[nodiscard]] int MoveBackwardUTF8(int position, int count) const
    {
      for(; position > 0 && --count >= 0; )
        while(position > 0)
          if ((std::string::operator[](--position) & 0xC0) != 0x80)
            break; // break inner loop
      return position;
    }

    /*!
     * @brief Move the position forward or backward, regarding the sign of "count"
     * skipping the given "count" UTF8 characters
     * @param position Initial position
     * @param count Amount of UTF8 character to move over
     * @return New position
     */
    [[nodiscard]] int MoveUTF8(int position, int count) const
    {
      if (count >= 0) return MoveForwardUTF8(position, count);
      return MoveBackwardUTF8(position, -count);
    }

    /*!
     * @brief Change the case of the current string according to the given translator
     * either capital to small or small to capitals
     * @param translator
     */
    void ChangeCaseUTF8(const Unicode16Array& translator)
    {
      unsigned char* p = (unsigned char*)data();
      unsigned char* end = p + Count();

      while(p < end)
      {
        unsigned char c = p[0];
        // 0xxxxxxx, one byte character
        if ((c & 0x80) == 0)
        {
          p[0] = (char)translator[(Unicode16)c];
          ++p;
          continue;
        }
        // 110xxxxx, two byte character (110xxxxx 10xxxxxx)
        if ((c & 0xE0) == 0xC0)
        {
          Unicode16 unicode = translator[(Unicode)((c & 0x1F) <<  6) | (Unicode)(p[1] & 0x3F)];
          p[0] = (char)((unicode >> 6) | 0xC0); p[1] = (char)((unicode & 0x3F) | 0x80);
          p += 2;
          continue;
        }
        // 1110xxxx, three byte character (1110xxxx 10xxxxxx 10xxxxxx)
        if ((c & 0xF0) == 0xE0)
        {
          Unicode16 unicode = translator[(Unicode)((c & 0x0F) << 12) | (Unicode)((p[1] & 0x3F) <<  6) | (Unicode)(p[2] & 0x3F)];
          p[0] = (char)((unicode >> 12) | 0xE0); p[1] = (char)(((unicode >> 6) & 0x3F) | 0x80); p[2] = (char)((unicode & 0x3F) | 0x80);
          p += 3;
          continue;
        }
        // 11110xxx, four byte character (11110xxx 10xxxxxx 10xxxxxx 10xxxxxx)
        if ((c & 0xF8) == 0xF0)
        {
          // Do not convert unicode characters on more than 16bits
          p += 4;
          continue;
        }
        // error, invalid unicode
        p++;
      }
    }

    /*
     * Split/Join
     */

    /*!
     * @brief Split the input string into a list of String, using the given char as separator
     * @tparam T Splitter type
     * @param input Input string
     * @param output Output list to fill with input string parts
     * @param splitter Separator
     * @param maxItems Maximum item to add into the list
     * @param multipleSplittersAsOne Treat concomitant splitters as a single splitter?
     */
    static void Split(const String& input, List& output, char splitter, int maxItems, bool multipleSplittersAsOne)
    {
      int start = 0;
      int comma = input.Find(splitter, 0);
      while(comma >= 0)
      {
        if ((int)output.size() == maxItems - 1) comma = input.Count();
        output.push_back(String(input.data() + start, comma - start));
        start = comma + 1; if (multipleSplittersAsOne) start = (int)input.find_first_not_of(splitter, start);
        comma = input.Find(splitter, start);
      }
      if (start >= 0 && start <= input.Count()) output.push_back(String(input.data() + start, input.Count() - start));
    }

    /*!
     * @brief Split the input string into a list of String, using the given splitter as separator
     * @tparam T Splitter type
     * @param input Input string
     * @param output Output list to fill with input string parts
     * @param splitter Separator
     * @param splitterLength Separator length in char
     * @param maxItems Maximum item to add into the list
     * @param multipleSplittersAsOne Treat concomitant splitters as a single splitter?
     */
    static void Split(const String& input, List& output, const String& splitter, int splitterLength, int maxItems, bool multipleSplittersAsOne)
    {
      int start = 0;
      int comma = input.Find(splitter, 0);
      while(comma >= 0)
      {
        if ((int)output.size() == maxItems - 1) comma = input.Count();
        output.push_back(String(input.data() + start, comma - start));
        start = comma + splitterLength;
        if (multipleSplittersAsOne)
          for(int next = input.Find(splitter, start); next - start == 0; )
            start = next + splitterLength, next = input.Find(splitter, start);
        comma = input.Find(splitter, start);
      }
      if (start >= 0 && start <= input.Count()) output.push_back(String(input.data() + start, input.Count() - start));
    }

    /*!
     * @brief Split the input string into a list of String, using the given splitter as separator
     * @tparam T Splitter type
     * @param input Input string
     * @param output Output list to fill with input string parts
     * @param splitter Separator
     * @param splitterLength Separator length in char
     * @param maxItems Maximum item to add into the list
     * @param multipleSplittersAsOne Treat concomitant splitters as a single splitter?
     */
    static void Split(const String& input, List& output, const char* splitter, int splitterLength, int maxItems, bool multipleSplittersAsOne)
    {
      int start = 0;
      int comma = input.Find(splitter, splitterLength, 0);
      while(comma >= 0)
      {
        if ((int)output.size() == maxItems - 1) comma = input.Count();
        output.push_back(String(input.data() + start, comma - start));
        start = comma + splitterLength;
        if (multipleSplittersAsOne)
          for(int next = input.Find(splitter, splitterLength, start); next - start == 0; )
            start = next + splitterLength, next = input.Find(splitter, splitterLength, start);
        comma = input.Find(splitter, splitterLength, start);
      }
      if (start >= 0 && start <= input.Count()) output.push_back(String(input.data() + start, input.Count() - start));
    }

    /*!
     * @brief Split the input string into a list of String, using the given char as separator
     * This version takes into account inner quoted strings and thus, ignore separators inside
     * quoted strings
     * @tparam T Splitter type
     * @param input Input string
     * @param output Output list to fill with input string parts
     * @param splitter Separator
     * @param maxItems Maximum item to add into the list
     * @param multipleSplittersAsOne Treat concomitant splitters as a single splitter?
     */
    static void SplitQuoted(const String& input, List& output, char splitter, int maxItems, bool multipleSplittersAsOne)
    {
      int start = 0;
      int comma = input.Find(splitter, 0);
      int quote = input.Find('"', 0);
      if (quote < comma)
      {
        quote = input.Find('"', quote + 1);
        comma = quote >= 0 ? input.Find(splitter, quote + 1) : quote;
      }
      while(comma >= 0)
      {
        if ((int)output.size() == maxItems - 1) comma = input.Count();
        output.push_back(String(input.data() + start, comma - start));
        start = comma + 1; if (multipleSplittersAsOne) start = (int)input.find_first_not_of(splitter, start);
        comma = input.Find(splitter, start);
        quote = input.Find('"', start);
        if ((unsigned int)quote < (unsigned int)comma)
        {
          quote = input.Find('"', quote + 1);
          comma = quote >= 0 ? input.Find(splitter, quote + 1) : quote;
        }
      }
      if ((unsigned int)start < (unsigned int)input.Count()) output.push_back(String(input.data() + start, input.Count() - start));
    }

    /*!
     * @brief Split the input string into a list of String, using the given splitter as separator
     * @tparam T Splitter type
     * @param input Input string
     * @param output Output list to fill with input string parts
     * @param splitter Separator
     * @param splitterLength Separator length in char
     * @param maxItems Maximum item to add into the list
     * @param multipleSplittersAsOne Treat concomitant splitters as a single splitter?
     */
    static void SplitQuoted(const String& input, List& output, const char* splitter, int splitterLength, int maxItems, bool multipleSplittersAsOne)
    {
      int start = 0;
      int comma = input.Find(splitter, splitterLength, 0);
      int quote = input.Find('"', 0);
      if (quote < comma)
      {
        quote = input.Find('"', quote + 1);
        comma = quote >= 0 ? input.Find(splitter, quote + 1) : quote;
      }
      while(comma >= 0)
      {
        if ((int)output.size() == maxItems - 1) comma = input.Count();
        output.push_back(String(input.data() + start, comma - start));
        start = comma + splitterLength;
        if (multipleSplittersAsOne)
          for(int next = input.Find(splitter, splitterLength, start, splitterLength); next - start == 0; )
            start = next + splitterLength, next = input.Find(splitter, splitterLength, start);
        comma = input.Find(splitter, splitterLength, start);
        quote = input.Find('"', start);
        if ((unsigned int)quote < (unsigned int)comma)
        {
          quote = input.Find('"', quote + 1);
          comma = quote >= 0 ? input.Find(splitter, splitterLength, quote + 1) : quote;
        }
      }
      if ((unsigned int)start < (unsigned int)input.Count()) output.push_back(String(input.data() + start, input.Count() - start));
    }

    /*!
     * @brief Split the input string into a list of String, using the given splitter as separator
     * @tparam T Splitter type
     * @param input Input string
     * @param output Output list to fill with input string parts
     * @param splitter Separator
     * @param splitterLength Separator length in char
     * @param maxItems Maximum item to add into the list
     * @param multipleSplittersAsOne Treat concomitant splitters as a single splitter?
     */
    static void SplitQuoted(const String& input, List& output, const String& splitter, int splitterLength, int maxItems, bool multipleSplittersAsOne)
    {
      int start = 0;
      int comma = input.Find(splitter, 0);
      int quote = input.Find('"', 0);
      if (quote < comma)
      {
        quote = input.Find('"', quote + 1);
        comma = quote >= 0 ? input.Find(splitter, quote + 1) : quote;
      }
      while(comma >= 0)
      {
        if ((int)output.size() == maxItems - 1) comma = input.Count();
        output.push_back(String(input.data() + start, comma - start));
        start = comma + splitterLength;
        if (multipleSplittersAsOne)
          for(int next = input.Find(splitter, start, splitterLength); next - start == 0; )
            start = next + splitterLength, next = input.Find(splitter, start);
        comma = input.Find(splitter, start);
        quote = input.Find('"', start);
        if ((unsigned int)quote < (unsigned int)comma)
        {
          quote = input.Find('"', quote + 1);
          comma = quote >= 0 ? input.Find(splitter, quote + 1) : quote;
        }
      }
      if ((unsigned int)start < (unsigned int)input.Count()) output.push_back(String(input.data() + start, input.Count() - start));
    }

    /*!
     * @brief Join all string from the list into the given output string, using the given joiner as separator
     * @tparam T Joiner type
     * @param list Input list
     * @param joiner Joiner to use as separator
     * @param output Output string
     */
    template<typename T> static void JoinList(const List& list, T joiner, String& output)
    {
      if (!list.empty()) output.Append(list[0]);
      for(int limit = (int)list.size(), index = 0; ++index < limit; )
        output.Append(joiner).Append(list[index]);
    }

    /*!
     * @brief Join all string from the list into the given output string, using the given joiner as separator
     * @tparam T Joiner type
     * @param list Input list
     * @param joiner Joiner to use as separator
     * @param joinerSize Joiner length, in char
     * @param output Output string
     */
    template<typename T> static void JoinList(const List& list, T joiner, int joinerSize, String& output)
    {
      if (!list.empty()) output.Append(list[0]);
      for(int limit = (int)list.size(), index = 0; ++index < limit; )
        output.Append(joiner, joinerSize).Append(list[index]);
    }

    // Kill insert parameter check
    #undef __AtCheck__
};

//! literal operator
String operator"" _s(const char*, size_t);

//! Short access to String::Format
#define _F String::Format
//! Short access to String::FormatOption full constructor
#define _FOV(type, value) String::FormatOption(String::FormatOption::Type::type, value)
//! Short access to String::FormatOption reset-to-default constructor
#define _FO(type) String::FormatOption(String::FormatOption::Type::type)

#include <hash_fun.h>
/*!
 * @brief Specialized template for hashing String objects
 */
template<> struct std::hash<String>
{
  size_t operator()(const String& __val) const noexcept { return __val.Hash(); }
};
