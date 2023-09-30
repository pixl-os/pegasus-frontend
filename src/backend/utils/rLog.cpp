//
// From recalbox ES and Integrated by BozoTheGeek 26/03/2021 in Pegasus Front-end
// Updated 30/09/2023 by BozoTheGeek to redirect to Pegasus-Frontend Log class
//
#include <QString>
#include "rLog.h"
#include "RootFolders.h"

//added to redirect ES legacy functions from es_log.txt to lastrun and recalbox logs
#include "Log.h"

LogLevel rLog::reportingLevel = LogLevel::LogInfo;

//deprecated - now we don't need to open because we will redirect ES "legacy" rLog to Pegasus-Frontend Log class
Path rLog::getLogPath(const char* filename)
{
	return RootFolders::DataRootFolder / "system/logs" / filename;
}

//deprecated - now we don't need to open because we will redirect ES "legacy" rLog to Pegasus-Frontend Log class
void rLog::open(const char* filename)
{
}

rLog& rLog::get(LogLevel level)
{
	messageLevel = level;
	return *this;
}

//deprecated - now we don't need to flush because we will redirect ES "legacy" rLog to Pegasus-Frontend Log class
void rLog::flush()
{
}

//deprecated - now we don't need to close because we will redirect ES "legacy" rLog to Pegasus-Frontend Log class
void rLog::close()
{
}

//deprecated - now we don't need to close because we will redirect ES "legacy" rLog to Pegasus-Frontend Log class
void rLog::doClose()
{
}

//Now we need destructor just to redirect ES "legacy" rLog messages to Pegasus-Frontend Log class
rLog::~rLog()
{
    const QString prepared_msg = QString::fromStdString(mMessage);
    switch (messageLevel) {
        case LogLevel::LogDebug:
            Log::debug(LOGMSG("%1").arg(prepared_msg));
            break;
        case LogLevel::LogInfo:
            Log::info(LOGMSG("%1").arg(prepared_msg));
            break;
        case LogLevel::LogWarning:
            Log::warning(LOGMSG("%1").arg(prepared_msg));
            break;
        case LogLevel::LogError:
            Log::error(LOGMSG("%1").arg(prepared_msg));
            break;
        default:
            Log::warning(LOGMSG("%1").arg(prepared_msg));
            break;
    }
}
