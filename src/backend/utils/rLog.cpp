//
// From recalbox ES and Integrated by BozoTheGeek 26/03/2021 in Pegasus Front-end
//

#include "rLog.h"
#include "RootFolders.h"
#include "utils/datetime/DateTime.h"

LogLevel rLog::reportingLevel = LogLevel::LogInfo;
FILE* rLog::sFile = nullptr;

static const char* StringLevel[] =
{
  "ERROR",
  "WARN!",
  "INFO ",
	"DEBUG",
};

Path rLog::getLogPath(const char* filename)
{
	return RootFolders::DataRootFolder / "system/logs" / filename;
}

void rLog::open(const char* filename)
{
  // Build log path
  Path logpath(filename != nullptr ? filename : getLogPath("es_log.txt").ToChars());

  // Backup?
  if (logpath.Exists())
    system(std::string("cp ").append(logpath.ToString()).append(1, ' ').append(logpath.ToString()+".backup").data());

  // Open new log
  sFile = fopen(logpath.ToChars(), "w");
}

rLog& rLog::get(LogLevel level)
{
	mMessage.append(1, '[')
	        .append(DateTime().ToPreciseTimeStamp())
	        .append("] (")
	        .append(StringLevel[(int)level])
	        .append(") : ");
	messageLevel = level;

	return *this;
}

void rLog::flush()
{
	fflush(sFile);
}

void rLog::close()
{
  {
    // *DO NOT REMOVE* the enclosing block as it allow the destructor to be called immediately
    // before calling doClose()
    // Generate an immediate log.
    rLog().get(LogLevel::LogInfo) << "Closing logger...";
  }
  doClose();
}

void rLog::doClose()
{
  if (sFile != nullptr)
    fclose(sFile);
  sFile = nullptr;
}

rLog::~rLog()
{
	bool loggerClosed = (sFile == nullptr);
	// Reopen temporarily
	if (loggerClosed)
  {
	  open();
	  mMessage += " [closed!]";
  }

  mMessage += '\n';
	fputs(mMessage.c_str(), sFile);
	if (!loggerClosed) flush();
	else doClose();

  // if it's an error, also print to console
  // print all messages if using --debug
  if(messageLevel == LogLevel::LogError || reportingLevel >= LogLevel::LogDebug)
    fputs(mMessage.c_str(), stderr);
}
