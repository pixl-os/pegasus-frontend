/*
 * DateTime.cpp
 *
 *  Created on: 17 mars 2017
 *      Author: thierry.imbert
 */

#include <sys/time.h>
#include "DateTime.h"

char LoadTimeZone()
{
  time_t t = time(nullptr);
  struct tm* lt = localtime(&t);
  return (char)((lt->tm_gmtoff / (60* 60)) * 4);
}

bool LoadRTCValues(short &millis, short &year, char &month, char &day, char &hour, char &minute, char &second)
{
  timeval tv = { 0, 0 };
  gettimeofday(&tv, nullptr);
  time_t t=tv.tv_sec;
  struct tm* lt = localtime(&t);
  millis = (short)(tv.tv_usec / 1000);
  second = (char)lt->tm_sec;
  minute = (char)lt->tm_min;
  hour   = (char)lt->tm_hour;
  day    = (char)lt->tm_mday;
  month  = (char)(lt->tm_mon + 1);
  year   = (short)(lt->tm_year + 1900);
  return true;
}

char DateTime::sDefaultTimeZone = LoadTimeZone();

//! Day of week of the epoch day
#define EPOCH_DAY_OF_WEEK 3

//! Second per day definition
#define SECONDS_PER_DAY (24 * 60 * 60)

//! Leap year macro
#define IsLeapYear(Y) (((((Y&3) == 0) && (Y%100 != 0)) || (Y%400 == 0)) ? 1 : 0)

static const int JulianDays[2][13] = { { 0, 31, 59, 90, 120, 151, 181, 212, 243, 273, 304, 334, 365 }, { 0, 31, 60, 91, 121, 152, 182, 213, 244, 274, 305, 335, 366 } };
static const int MaxDayInMonth[2][13] = { { 0, 31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31 }, { 0, 31, 29, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31 } };

int DateTime::DayPerMonth() const
{
  return MaxDayInMonth[IsLeapYear(mYear)][(int)(unsigned char)mMonth];
}

int DateTime::DayPerMonth(int month, int year)
{
  if (month < 1) month = month + ((0x7FFFFFFF / 12) * 12);
  if (month > 12) month = ((month - 1) % 12) + 1;
  return MaxDayInMonth[IsLeapYear(year)][month];
}

int DateTime::ElapsedDayFromEpoch(int year, int month, int day)
{
  int Result = 0;
  // First, decrement the year and get the number of days
  // for all the years preceding it (in the Common Era).
  if ((year - 1) > 0)
  {
    year--;
    int cc = year / 100;
    int ddddd = year * 365;
    int leapdays = year >> 2;
    int cc_leapdays = (cc > 0) ? (cc >> 2) : 0;
    ddddd = ddddd + leapdays - cc + cc_leapdays;
    year++;

    Result = ddddd;
  }
  // Add days
  Result += day - 1;

  // Add the previous month YTD days to our ddddd. If it
  // is a leap year, take the second array
  // Then add in YTD days for previous months of this year
  Result += JulianDays[IsLeapYear(year) ? 1 : 0][month - 1];

  return Result;
}

void DateTime::FillFromRtc()
{
  short millis = 0;
  short year = 0;
  char  month = 0;
  char  day = 0;
  char  hour = 0;
  char  minute = 0;
  char  second = 0;

  if (!LoadRTCValues(millis, year, month, day, hour, minute, second))
  {
    FillFromStartOfEra();
    return;
  }

  mYear = year;
  mMonth = month;
  mDay = day;
  mHour = hour;
  mMinute = minute;
  mSecond = second;
  mMillis = millis;
  mTimeZone = sDefaultTimeZone;
}

void DateTime::FillFromStartOfEra()
{
  mYear = mMillis = 0;
  mHour = mMinute = mSecond = 0;
  mMonth = mDay = 1;
  mTimeZone = sDefaultTimeZone;
}

bool DateTime::IsZero() const
{
  return ((mYear | mMillis | mHour | mMinute | mSecond) == 0) &&
         (mMonth == 1) && (mDay == 1);
}

void DateTime::FillFromEpochTime(long long epochtime)
{
  epochtime += 24LL * 3600LL;
  long long currSec = 0;

  mYear = 1970;
  while ((currSec = (JulianDays[IsLeapYear(mYear) ? 1 : 0][12] * 24LL * 3600LL)) <= epochtime)
  {
    epochtime -= currSec;
    mYear++;
  }

  mMonth = 1;
  while ((currSec = (MaxDayInMonth[IsLeapYear(mYear) ? 1 : 0][(int)(unsigned char)mMonth] * 24LL * 3600LL)) <= epochtime)
  {
    epochtime -= currSec;
    mMonth++;
  }

  mDay = (char) (epochtime / (24LL * 3600LL));
  if (mDay == 0)
  {
    mMonth -= 1;
    if (mMonth == 0) { mYear -= 1; mMonth = 12; }
    mDay = (char)MaxDayInMonth[IsLeapYear(mYear) ? 1 : 0][(int)(unsigned char)mMonth];
  }
  epochtime %= 24LL * 3600LL;
  mHour = (char) (epochtime / 3600LL);
  epochtime %= 3600LL;
  mMinute = (char) (epochtime / 60LL);
  epochtime %= 60LL;
  mSecond = (char) epochtime;

  mMillis = 0;
  mTimeZone = sDefaultTimeZone;
}

void DateTime::Control()
{
  // Control date
  if (mYear < 0) mYear = 0;
  if (mMonth <= 0) mMonth = 1;
  if (mMonth > 12) mMonth = 12;
  if (mDay <= 0) mDay = 1;
  int mdim = MaxDayInMonth[IsLeapYear(mYear)][(int) mMonth];
  if (mDay > mdim) mDay = (char)mdim;

  // Time
  if (mHour < 0) mHour = 0;
  if (mHour >= 24) mHour %= 24;
  if (mMinute < 0) mMinute = 0;
  if (mMinute >= 60) mMinute %= 60;
  if (mSecond < 0) mSecond = 0;
  if (mSecond >= 60) mSecond %= 60;
  if (mMillis < 0) mMillis = 0;
  if (mMillis > 999) mMillis %= 1000;

  // Timezone
  if ((mTimeZone < -25 * 4) || (mTimeZone > 25 * 4)) mTimeZone = 0;
}

DateTime::DateTime()
{
  FillFromRtc();
  Control();
}

DateTime::DateTime(bool initialized)
{
  if (initialized) FillFromRtc();
  else FillFromStartOfEra();
  Control();
}

DateTime::DateTime(int year, int month, int day)
{
  FillFromStartOfEra();
  mYear = (short)year;
  mMonth = (char)month;
  mDay = (char)day;
  Control();
}

DateTime::DateTime(int year, int month, int day, int hour, int minute, int second)
{
  FillFromStartOfEra();
  mYear = (short)year;
  mMonth = (char)month;
  mDay = (char)day;
  mHour = (char)hour;
  mMinute = (char)minute;
  mSecond = (char)second;
  Control();
}

DateTime::DateTime(int year, int month, int day, int hour, int minute, int second, int millisecond)
{
  FillFromStartOfEra();
  mYear = (short)year;
  mMonth = (char)month;
  mDay = (char)day;
  mHour = (char)hour;
  mMinute = (char)minute;
  mSecond = (char)second;
  mMillis = (short)millisecond;
  Control();
}

DateTime::DateTime(int year, int month, int day, int hour, int minute, int second, int millisecond, int tzq)
{
  FillFromStartOfEra();
  mYear = (short)year;
  mMonth = (char)month;
  mDay = (char)day;
  mHour = (char)hour;
  mMinute = (char)minute;
  mSecond = (char)second;
  mMillis = (short)millisecond;
  mTimeZone = (char)tzq;
  Control();
}

DateTime::DateTime(int year, int month, int day, int hour, int minute, int second, int millisecond, int tzh, int tzm)
{
  FillFromStartOfEra();
  mYear = (short)year;
  mMonth = (char)month;
  mDay = (char)day;
  mHour = (char)hour;
  mMinute = (char)minute;
  mSecond = (char)second;
  mMillis = (short)millisecond;
  mTimeZone = (char)(tzh * 4 + tzm / 15);
  Control();
}

DateTime::DateTime(long long epochtime)
{
  FillFromEpochTime(epochtime);
  Control();
}

int DateTime::DayOfWeek() const
{
  return (int) ((ToEpochTime() / SECONDS_PER_DAY) + EPOCH_DAY_OF_WEEK) % 7;
}

static const char* shortMonthNames[] = { "", "Jan.", "Feb.", "Mar.", "Apr.", "May", "June", "July", "Aug.", "Sept.", "Oct.", "Nov.", "Dec." };
static const char* longMonthNames[] = { "", "January", "February", "March", "April", "May", "June", "July", "August", "September.", "October", "November",
                                        "December" };
static const char* shortDayNames[] = { "Mon.", "Tue.", "Wed.", "Thu.", "Fri.", "Sat.", "Sun." };
static const char* longDayNames[] = { "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday", "Sunday" };

std::string DateTime::ToStringFormat(const char* format) const
{
  std::string result;
  bool Escaped = false;

  for (int index = 0; format[index] != 0;)
  {
    char c = format[index];
    if (c == '\\')
    {
      Escaped = true;
      index++;
      continue;
    }
    if ((c != '%') || Escaped)
    {
      result += (c);
      Escaped = false;
      index++;
      continue;
    }
    // c is '%', get first format char
    c = format[++index];
    int repeat = 0;
    if (format[++index] == c)
    {
      repeat++;
      if (format[++index] == c)
      {
        repeat++;
        if (format[++index] == c)
        {
          repeat++;
          index++;
        }
      }
    }
    switch (c)
    {
      case 'Y':
      {
        if (repeat == 0) result += std::to_string((int)mYear);
        else if (repeat == 1) { result += ((char) ('0' + ((mYear / 10) % 10))); result += ((char) ('0' + (mYear % 10))); }
        else { result += ((char) ('0' + (mYear / 1000))); result += ((char) ('0' + ((mYear / 100) % 10))); result += ((char) ('0' + ((mYear / 10) % 10))); result += ((char) ('0' + (mYear % 10))); }
        break;
      }
      case 'M':
      {
        if (repeat == 0) result += std::to_string((int)mMonth);
        else if (repeat == 1) { result += ((char) ('0' + ((mMonth / 10) % 10))); result += ((char) ('0' + (mMonth % 10))); }
        else if (repeat == 2) result += (shortMonthNames[(int)(unsigned char)mMonth]);
        else result += (longMonthNames[(int)(unsigned char)mMonth]);
        break;
      }
      case 'd':
      {
        if (repeat == 0) result += std::to_string((int)mDay);
        else if (repeat == 1) { result += ((char) ('0' + ((mDay / 10) % 10))); result += ((char) ('0' + (mDay % 10))); }
        else if (repeat == 2) result += (shortDayNames[DayOfWeek()]);
        else result += (longDayNames[DayOfWeek()]);
        break;
      }
      case 'H':
      {
        if (repeat == 0) result += std::to_string((int)mHour);
        else if (repeat == 1) { result += ((char) ('0' + ((mHour / 10) % 10))); result += ((char) ('0' + (mHour % 10))); }
        break;
      }
      case 'm':
      {
        if (repeat == 0) result += std::to_string((int)mMinute);
        else if (repeat == 1) { result += ((char) ('0' + ((mMinute / 10) % 10))); result += ((char) ('0' + (mMinute % 10))); }
        break;
      }
      case 's':
      {
        if (repeat == 0) result += std::to_string((int)mSecond);
        else if (repeat == 1) { result += ((char) ('0' + ((mSecond / 10) % 10))); result += ((char) ('0' + (mSecond % 10))); }
        break;
      }
      case 'f':
      {
        if (repeat == 0) result += std::to_string((int)mMillis);
        else if (repeat == 2) { result += ((char) ('0' + ((mMillis / 100) % 10))); result += ((char) ('0' + ((mMillis / 10) % 10))); result += ((char) ('0' + (mMillis % 10))); }
        break;
      }
      case 'z':
      {
        int timeZone = (unsigned char)mTimeZone; if (timeZone < 0) timeZone = -timeZone;
        result += (mTimeZone < 0 ? '-' : '+');
        if (repeat == 0) result += std::to_string(timeZone);
        else if (repeat == 1) { result += ((char) ('0' + ((timeZone / 40) % 10))); result += ((char) ('0' + ((timeZone >> 2) % 10))); }
        else
        {
          int Value = (timeZone >> 2) * 100 + (timeZone & 3) * 15;
          result += ((char) ('0' + (Value / 1000))); result += ((char) ('0' + ((Value / 100) % 10))); result += ((char) ('0' + ((Value / 10) % 10))); result += ((char) ('0' + (Value % 10)));
        }
        break;
      }
      case '%':
      {
        result.append((unsigned int)repeat, '%');
        break;
      }
      default:
      {
        result += ("<Unk:");
        result.append((unsigned int)(repeat + 1), c);
        result += ('>');
        break;
      }
    }
  }

  return result;
}

bool DateTime::FetchNumeric(const char*& str, int min, int max, int& result)
{
  int r = 0;
  const char* p = str; // Cache values for fast run
  for (; --max >= 0; ++p, --min)
  {
    if (((unsigned char) p[0]) - 0x30 > 9) break;
    r = r * 10 + ((unsigned char) p[0]) - 0x30;
  }
  str = p; // Store back
  result = (min <= 0) ? r : 0;
  return (min <= 0);
}

bool DateTime::FetchStringIndex(const char*& str, const char* strs[], int count, int& result, bool zerobased)
{
  for (; --count >= 0;)
  {
    const char* p = str;
    const char* ps = strs[count];
    for (; ps[0] != 0; ps++, p++)
      if ((p[0] & 0xDF) != (ps[0] & 0xDF)) break; // & 0xDF => brutal lowercase to uppurcase conversion
    if (ps[0] != 0) continue;
    result = count + (zerobased ? 0 : 1);
    str = p;
    return true;
  }
  return false;
}

bool DateTime::ParseFromString(const char* format, const std::string& str, DateTime& destination)
{
  int year = 0, month = 1, day = 1, hour = 0, minute = 0, second = 0, millisecond = 0, tz = 0, dummy = 0;
  bool escaped = false;
  const char* p = str.c_str(); // Use char* to avoid length control of the string
  bool ok = true; // Be optimistic :)

  for (int findex = 0; format[findex] != 0 && ok;)
  {
    char c = format[findex];
    if (c == '\\')
    {
      escaped = true;
      findex++;
      continue;
    }
    if ((c != '%') || escaped)
    {
      if (p[0] != c) ok = false; // Non tag characters does not match: break now.
      escaped = false;
      findex++;
      p++;
      continue;
    }
    // c is '%', get first format char
    c = format[++findex];
    int repeat = 0;
    if (format[++findex] == c)
    {
      repeat++;
      if (format[++findex] == c)
      {
        repeat++;
        if (format[++findex] == c)
        {
          repeat++;
          findex++;
        }
      }
    }
    switch (c)
    {
      case 'Y':
      case 'y':
      {
        if (repeat == 0) ok = FetchNumeric(p, 1, 4, year);
        else if (repeat == 1)
        {
          ok = FetchNumeric(p, 2, 2, year);
          year += (year >= 50 ? 1900 : 2000);
        }
        else ok = FetchNumeric(p, 4, 4, year);
        break;
      }
      case 'M':
      {
        if (repeat == 0) ok = FetchNumeric(p, 1, 2, month);
        else if (repeat == 1) ok = FetchNumeric(p, 2, 2, month);
        else if (repeat == 2) ok = FetchStringIndex(p, shortMonthNames, 12, month, false);
        else ok = FetchStringIndex(p, longMonthNames, 12, month, false);
        break;
      }
      case 'D':
      case 'd':
      {
        if (repeat == 0) ok = FetchNumeric(p, 1, 2, day);
        else if (repeat == 1) ok = FetchNumeric(p, 2, 2, day);
        else if (repeat == 2) ok = FetchStringIndex(p, shortDayNames, 7, dummy, true);
        else ok = FetchStringIndex(p, longDayNames, 7, dummy, true);
        break;
      }
      case 'H':
      case 'h':
      {
        if (repeat == 0) ok = FetchNumeric(p, 1, 2, hour);
        else if (repeat == 1) ok = FetchNumeric(p, 2, 2, hour);
        break;
      }
      case 'm':
      {
        if (repeat == 0) ok = FetchNumeric(p, 1, 2, minute);
        else if (repeat == 1) ok = FetchNumeric(p, 2, 2, minute);
        break;
      }
      case 'S':
      case 's':
      {
        if (repeat == 0) ok = FetchNumeric(p, 1, 2, second);
        else if (repeat == 1) ok = FetchNumeric(p, 2, 2, second);
        break;
      }
      case 'F':
      case 'f':
      {
        if (repeat == 0) ok = FetchNumeric(p, 1, 3, millisecond);
        else if (repeat == 2) ok = FetchNumeric(p, 3, 3, millisecond);
        break;
      }
      case 'Z':
      case 'z':
      {
        if (p[0] == 'Z') tz = 0;
        else
        {
          int sign = (p[0] == '+' ? 1 : (p[0] == '-' ? -1 : 0));
          if (sign == 0)
          {
            ok = false;
            continue;
          }
          p++;
          if (repeat == 0) ok = FetchNumeric(p, 1, 2, tz);
          else if (repeat == 1)
          {
            ok = FetchNumeric(p, 1, 2, tz);
            tz <<= 2;
          } else
          {
            ok = FetchNumeric(p, 1, 2, tz);
            tz <<= 2;
            if (p[0] == ':') p++; // Extended format
            ok = FetchNumeric(p, 1, 2, dummy);
            tz += dummy / 15;
          }
        }
        break;
      }
      default:
      {
        ok = false;
        break;
      }
    }
  }

  if (ok)
  {
    destination.mYear = (short)year;
    destination.mMonth = (char)month;
    destination.mDay = (char)day;
    destination.mHour = (char)hour;
    destination.mMinute = (char)minute;
    destination.mSecond = (char)second;
    destination.mMillis = (short)millisecond;
    destination.mTimeZone = (char)tz;
    destination.Control();
  }
  else
  {
    destination.mYear = 1970;
    destination.mMonth = 1;
    destination.mDay = 1;
    destination.mHour = 0;
    destination.mMinute = 0;
    destination.mSecond = 0;
    destination.mMillis = 0;
    destination.mTimeZone = 0;
  }
  return ok;
}

long long DateTime::ToEpochTime() const
{
  // Static reference
  static int Reference = ElapsedDayFromEpoch(1970, 1, 1);
  // Get days from epoch
  int days = ElapsedDayFromEpoch(mYear, mMonth, mDay) - Reference;
  // Convert to seconds
  return ((long long) SECONDS_PER_DAY * (long long) days) + (long long) mHour * 3600LL + (long long) mMinute * 60LL + (long long) mSecond;
}
