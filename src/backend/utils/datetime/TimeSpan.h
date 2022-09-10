#pragma once

#include <string>

#ifndef __PACKED__
#  if  defined(__GNUC__) ||  defined (__clang__)
#    define __PACKED__ __attribute__((packed))
#  else
#    define __PACKED__
#  endif
#endif

// Forward declaration
class DateTime;

//! Simple time span class
class TimeSpan
{
private:
  /*!
   * Individual time field, packed in a simple structure.
   * This allows size control and union with larger fields for fast comparisons/fast copy
   */
  struct TimeUnit
  {
    short _Millis; //!< Millisecond part of the Timespan
    char _Seconds; //!< Second part of the Timespan
    char _Minutes; //!< Minutes part of the Timespan
    int _Hours;    //!< Hours part of the Timespan
  } __PACKED__;

  union
  {
    TimeUnit Units; //!< Individual fields
    long long  All; //!< Packed fields
  };

  /*!
   * Fill the current TimeSpan with the decomposed value in millisecond
   * @param ms TimeSpan in milliseconds
   * @return this instance
   */
  TimeSpan& Build(long long ms);

  /*!
   * Negate this TimeStamp
   * @return this instance
   */
  TimeSpan& Negate()
  {
    Units._Hours = -Units._Hours;
    Units._Minutes = (char)-Units._Minutes;
    Units._Seconds = (char)-Units._Seconds;
    Units._Millis = (short)-Units._Millis;
    return *this;
  }

public:
  //! Copy constructor
  TimeSpan(const TimeSpan& source) { All = source.All; }

  //! Default constructor, zero-ed TimeSpan
  TimeSpan() : All(0) {}
  //! Build a TimeSpan in milliseconds
  explicit TimeSpan(long long ms) { Build(ms); }
  //! Build a TimeSpan from seconds and milliseconds
  TimeSpan(int seconds, int ms) { Build((long long)ms + (long long)seconds * 1000LL); }
  //! Build a TimeSpan from minutes, seconds and milliseconds
  TimeSpan(int minutes, int seconds, int ms) { Build((long long)ms + (long long)seconds * 1000LL + (long long)minutes * 60000LL); }
  //! Build a TimeSpan from minutes, seconds and milliseconds
  TimeSpan(int hours, int minutes, int seconds, int ms) { Build((long long)ms + (long long)seconds * 1000LL + (long long)minutes * 60000LL + (long long)hours * 3600000LL); }
  //! Build a TimeSpan from the difference between two dates
  TimeSpan(const DateTime& start, const DateTime& stop);

  //! Get the current TimeSpan in Milliseconds
  long long TotalMilliseconds() const { return (long long)Units._Hours * 3600000LL + (long long)Units._Minutes * 60000LL + (long long)Units._Seconds * 1000LL + Units._Millis; }
  //! Get the current TimeSpan in Seconds
  long long TotalSeconds() const { return (long long)Units._Hours * 3600LL + (long long)Units._Minutes * 60LL + (long long)Units._Seconds; }
  //! Get the current TimeSpan in Minutes
  long long TotalMinutes() const { return (long long)Units._Hours * 60LL + (long long)Units._Minutes; }
  //! Get the current TimeSpan in Hours
  long long TotalHours() const { return (long long)Units._Hours; }
  //! Get the current TimeSpan in Days
  long long TotalDays() const { return (long long)Units._Hours / 24LL; }

  //! Return the Hour part of the current TimeSpan
  int Hours() const { return Units._Hours; }
  //! Return the Hour part of the current TimeSpan
  int Minutes() const { return Units._Minutes; }
  //! Return the Hour part of the current TimeSpan
  int Seconds() const { return Units._Seconds; }
  //! Return the Hour part of the current TimeSpan
  int Milliseconds() const { return Units._Millis; }

  /*!
   * Add a TimeSpan to the current TimeSpan
   * @param ts TimeSpan to add
   * @return Current TimeSpan
   */
  TimeSpan& operator += (const TimeSpan& ts)   { return Build(TotalMilliseconds() + ts.TotalMilliseconds()); }
  /*!
   * Substract a TimeSpan to the current TimeSpan
   * @param ts TimeSpan to substract
   * @return Current TimeSpan
   */
  TimeSpan& operator -= (const TimeSpan& ts)   { return Build(TotalMilliseconds() - ts.TotalMilliseconds()); }
  /*!
   * Multiply the current TimeSpan by a numeric value
   * @param multiplier Multiplier
   * @return Current TimeSpan
   */
  TimeSpan& operator *= (const int multiplier) { return Build(TotalMilliseconds() * (long long)multiplier); }
  /*!
   * Divide the current TimeSpan by a numeric value
   * @param divider Divider
   * @return Current TimeSpan
   */
  TimeSpan& operator /= (const int diviser)    { return Build(TotalMilliseconds() * (long long)diviser); }

  /*!
   * Add a TimeSpan to the current TimeSpan into a new TimeSpan
   * @param ts TimeSpan to add
   * @return New TimeSpan that contain the result of the addition
   */
  TimeSpan operator + (const TimeSpan& ts)   const { return TimeSpan(TotalMilliseconds() + ts.TotalMilliseconds()); }
  /*!
   * Substract a TimeSpan to the current TimeSpan into a new TimeSpan
   * @param ts TimeSpan to substract
   * @return New TimeSpan that contain the result of the substraction
   */
  TimeSpan operator - (const TimeSpan& ts)   const { return TimeSpan(TotalMilliseconds() - ts.TotalMilliseconds()); }
  /*!
   * Multiply the current TimeSpan by a numeric value into a new TimeSpan
   * @param multiplier Multiplier
   * @return New TimeSpan that contain the result of the multiplication
   */
  TimeSpan operator * (const int multiplier) const { return TimeSpan(TotalMilliseconds() * (long long)multiplier); }
  /*!
   * Divide the current TimeSpan by a numeric value into a new TimeSpan
   * @param divider Divider
   * @return New TimeSpan that contain the result of the division
   */
  TimeSpan operator / (const int diviser)    const { return TimeSpan(TotalMilliseconds() * (long long)diviser); }

  /*!
   * Negate the current TimeSpan into a new TimeSpan
   * @return Negative TimeSpan
   */
  TimeSpan operator ! () const { return TimeSpan(*this).Negate(); }

  /*!
   * Equal operator for fast copy
   * @param source TimeSpan to assign to the current TimeSpan
   * @return Curent TipeSpan
   */
  TimeSpan& operator = (const TimeSpan& source) { All = source.All; return *this; }

  /*!
   * Equality operator
   * @param to TimeSpan instance to compare to
   * @return True if both TimeStamp are strictly equal. False otherwise.
   */
  bool operator == (const TimeSpan& to) const { return TotalMilliseconds() == to.TotalMilliseconds(); }
  /*!
   * Inequality operator
   * @param to TimeSpan instance to compare to
   * @return True if both TimeStamp are not equal. False otherwise.
   */
  bool operator != (const TimeSpan& to) const { return TotalMilliseconds() != to.TotalMilliseconds(); }
  /*!
   * Lesser operator
   * @param to TimeSpan instance to compare to
   * @return True if the current TimeSpan is lesser than the one it compares to. False otherwise.
   */
  bool operator <  (const TimeSpan& to) const { return TotalMilliseconds() < to.TotalMilliseconds(); }
  /*!
   * Lesser or equal operator
   * @param to TimeSpan instance to compare to
   * @return True if the current TimeSpan is lesser than or equal to the one it compares to. False otherwise.
   */
  bool operator <= (const TimeSpan& to) const { return TotalMilliseconds() <= to.TotalMilliseconds(); }
  /*!
   * Greater or equal operator
   * @param to TimeSpan instance to compare to
   * @return True if the current TimeSpan is greater than the one it compares to. False otherwise.
   */
  bool operator >  (const TimeSpan& to) const { return TotalMilliseconds() > to.TotalMilliseconds(); }
  /*!
   * Greater or equal operator
   * @param to TimeSpan instance to compare to
   * @return True if the current TimeSpan is greater than or equal to the one it compares to. False otherwise.
   */
  bool operator >= (const TimeSpan& to) const { return TotalMilliseconds() >= to.TotalMilliseconds(); }

  /*!
   * Compare the current TimeSpan to another TimeSpan.
   * @param to TimeSpan to compare to
   * @return -1 current < to. +1 if current > to. 0 if they are strictly equal.
   */
  int Compare(const TimeSpan& to) const { long long c1 = TotalMilliseconds(), c2 = to.TotalMilliseconds(); return ((c1 < c2) ? -1 : ((c1 > c2) ? 1 : 0)); }

  /*!
   * Check if the current TimeSpan is negative
   * @return True if the current TimeSpan is strictly negative. False otherwise
   */
  bool IsNegative() const { return TotalMilliseconds() < 0; }
  /*!
   * Check if the current TimeSpan is positive
   * @return True if the current TimeSpan is positive or null. False otherwise
   */
  bool IsPositive() const { return TotalMilliseconds() >= 0; }
  /*!
   * Check if the current TimeSpan is null (0'ed)
   * @return True if the current TimeSpan is null. False otherwise
   */
  bool IsNull() const { return TotalMilliseconds() == 0; }

  /*!
   * Return an absolute value copy of this TaimeSpan
   * @return Positive timespan
   */
  TimeSpan AbsoluteValue() const { return TotalMilliseconds() >= 0 ? *this : !*this; }

  /*!
   * Return a string representation of the current object, using the following tags:
   * d    : Numeric day count (1..4 digits)
   * H    : Numeric *total* hours (0...)
   * HH   : 2 digits Numeric hour in 24h format (use this when using %d)
   * m    : Numeric minutes (1..2 digits)
   * mm   : 2 digits minutes
   * mmmm : Numeric *total* minutes (0...) (use as single unit)
   * s    : Numeric seconds (1..2 digits)
   * ss   : 2 digits seconds
   * ssss : Numeric *total* seconds (0...) (use as single unit)
   * f    : Numeric milliseconds (1..3 digits)
   * fff  : 3 digits milliseconds
   * ffff : Numeric *total* milliseconds (0...) (use as single unit)
   * Tags must follow a '%' (percent) character. Escape any character using '\'.
   * @param format String format
   * @return String representation of the current
   */
  std::string ToStringFormat(const char* format) const;

  /*!
   * Format current TimeStamp to a comprehensive string.
   * @param millisecond If true, milliseconds are added as second fractions.
   * @return Formatted string
   */
  std::string ToString(bool millisecond = false) const { return ToStringFormat(millisecond ? "%d:%HH:%mm:%ss.%fff" : "%d:%HH:%mm:%ss"); };

  /*!
   * Format current TimeStamp to a comprehensive string using Time unit only (no days).
   * @param millisecond If true, milliseconds are added as second fractions.
   * @return Formatted string
   */
  std::string ToTimeString(bool millisecond = false) const { return ToStringFormat(millisecond ? "%H:%mm:%ss.%fff" : "%H:%mm:%ss"); };

  /*!
   * Format current timestamp into a string representation of the total hours
   * @return Formatted string
   */
  std::string ToHoursString() const { return ToStringFormat("%H"); };

  /*!
   * Format current timestamp into a string representation of the total minutes
   * @return Formatted string
   */
  std::string ToMinutesString() const { return ToStringFormat("%mmmm"); };

  /*!
   * Format current timestamp into a string representation of the total seconds
   * @return Formatted string
   */
  std::string ToSecondsString() const { return ToStringFormat("%ssss"); };

  /*!
   * Format current timestamp into a string representation of the total milliseconds
   * @return Formatted string
   */
  std::string ToMillisecondsString() const { return ToStringFormat("%ffff"); };
};
