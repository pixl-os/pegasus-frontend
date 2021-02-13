#ifndef _LOG_H_
#define _LOG_H_

#define LOG(level) \
if (LogLevel::level <= rLog::getReportingLevel()) rLog().get(LogLevel::level)

#include <string>
#include <utils/os/fs/Path.h>
#include "Strings.h"

//! rLog level
enum class LogLevel
{
	LogError   = 0, //!< Error messages
	LogWarning = 1, //!< Warning messages
	LogInfo    = 2, //!< Information message
	LogDebug   = 3, //!< Debug message
};

class rLog
{
  public:
    ~rLog();
    
    rLog& get(LogLevel level = LogLevel::LogInfo);

    static LogLevel getReportingLevel() { return reportingLevel; }
    static void setReportingLevel(LogLevel level) { reportingLevel = level; }

    static void open(const char* filename = nullptr);
    static void close();

    rLog& operator << (char v) { mMessage += v; return *this; }
    rLog& operator << (const char* v) { mMessage += v; return *this; }
    rLog& operator << (const std::string& v) { mMessage += v; return *this; }
    rLog& operator << (int v) { mMessage += Strings::ToString(v); return *this; }
    rLog& operator << (unsigned int v) { mMessage += Strings::ToString(v); return *this; }
    rLog& operator << (long long v) { mMessage += Strings::ToString(v); return *this; }
    rLog& operator << (unsigned long long v) { mMessage += Strings::ToString(v); return *this; }
    rLog& operator << (long v) { mMessage += Strings::ToString((long long)v); return *this; }
    rLog& operator << (unsigned long v) { mMessage += Strings::ToString((unsigned long long)v); return *this; }
    rLog& operator << (bool v) { mMessage += Strings::ToString(v); return *this; }
    rLog& operator << (float v) { mMessage += Strings::ToString(v, 4); return *this; }
    rLog& operator << (const Strings::Vector& v) { for(const std::string& s : v) mMessage.append(s).append(1, ' '); return *this; }

  private:
    static FILE* sFile;
    static LogLevel reportingLevel;
    std::string mMessage;
    LogLevel messageLevel;

    static Path getLogPath(const char* filename);

    static void flush();

    static void doClose();
};

#endif
