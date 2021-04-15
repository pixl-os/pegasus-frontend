//
// From recalbox ES and Integrated by BozoTheGeek 12/04/2021 in Pegasus Front-end
//

#include <hardware/Board.h>
#include <cstring>
#include <utils/rLog.h>
#include <utils/Files.h>

#include <sys/utsname.h>

#include <hardware/boards/NullBoard.h>
#include <hardware/boards/pc/PcComputers.h>

Board::Board()
  : StaticLifeCycleControler("Board")
  , mType(BoardType::UndetectedYet)
  , mSender()
  , mBoard(GetBoardInterface(mSender))
{
}

IBoardInterface* Board::GetBoardInterface(HardwareMessageSender& messageSender)
{
  BoardType model = GetBoardType();
  switch(model)
  {
    case BoardType::PCx86:
    case BoardType::PCx64:
    {
      { LOG(LogInfo) << "[Hardware] x86 or x64 PC detected."; }
      return new PcComputers(messageSender);
    }
    case BoardType::UndetectedYet:
    case BoardType::Unknown:
    case BoardType::Pi0:
    case BoardType::Pi1:
    case BoardType::Pi2:
    case BoardType::Pi3:
    case BoardType::Pi3plus:
    case BoardType::Pi4:
    case BoardType::Pi400:
    case BoardType::UnknownPi:
    default: break;
  }

  { LOG(LogInfo) << "[Hardware] Default hardware interface created."; }
  return new NullBoard(messageSender);
}

BoardType Board::GetPiModel(unsigned int revision)
{
  // Split - uuuuuuuuFMMMCCCCPPPPTTTTTTTTRRRR
  bool newGeneration  = ((revision >> 23) & 1) != 0;
  int  memorySize     = ((int)revision >> 20) & 0x7; (void)memorySize;
  int  manufacturer   = ((int)revision >> 16) & 0xF; (void)manufacturer;
  int  processor      = ((int)revision >> 12) & 0xF; (void)processor;
  int  model          = ((int)revision >>  4) & 0xFF;
  int  revisionNumber = ((int)revision >>  0) & 0xF; (void)revisionNumber;

  // Old revision numbering
  if (!newGeneration)
    return BoardType::Pi1;

  // New models
  switch ((RaspberryModel)model)
  {
    case RaspberryModel::Zero:
    case RaspberryModel::ZeroW: return BoardType::Pi0;
    case RaspberryModel::OneA:
    case RaspberryModel::OneAPlus:
    case RaspberryModel::OneB:
    case RaspberryModel::OneBPlus:
    case RaspberryModel::OneCM1: return BoardType::Pi1;
    case RaspberryModel::TwoB: return BoardType::Pi2;
    case RaspberryModel::TreeB:
    case RaspberryModel::TreeCM3: return BoardType::Pi3;
    case RaspberryModel::TreeBPlus:
    case RaspberryModel::TreeCM3Plus:
    case RaspberryModel::TreeAPlus: return BoardType::Pi3plus;
    case RaspberryModel::FourB:
    case RaspberryModel::FourCM4: return BoardType::Pi4;
    case RaspberryModel::FourHundred: return BoardType::Pi400;
    case RaspberryModel::Alpha:
    default: break;
  }

  return BoardType::UnknownPi;
}

#define CPU_INFO_FILE   "/proc/cpuinfo"
#define REVISION_STRING "Revision"
#define HARDWARE_STRING "Hardware"

#define SizeLitteral(x) (sizeof(x) - 1)

BoardType Board::GetBoardType()
{
  if (mType != BoardType::UndetectedYet) return mType;

  // Try uname (for PC)
  utsname uName {};
  memset(&uName, 0, sizeof(uName));
  uname(&uName);
  std::string machine(uName.machine);
  { LOG(LogDebug) << "[Hardware] Machine identifier: '" << machine << '\''; }
  if (machine == "i386") return mType = BoardType::PCx86;
  if (machine == "i686") return mType = BoardType::PCx86;
  if (machine == "x86_64") return mType = BoardType::PCx64;

  // Then try CPU info
  std::string hardware;
  std::string revision;
  mType = BoardType::Unknown;

  FILE* f = fopen(CPU_INFO_FILE, "r");
  if (f != nullptr)
  {
    char line[1024];
    std::string str; // Declared before loop to keep memory allocated
    while (fgets(line, sizeof(line) - 1, f) != nullptr)
    {
      // Raspberry pi
      if (strncmp(line, HARDWARE_STRING, SizeLitteral(HARDWARE_STRING)) == 0)
      {
        char* colon = strchr(line, ':');
        if (colon != nullptr)
        {
          hardware = colon + 2;
          hardware.erase(hardware.find_last_not_of(" \t\r\n") + 1);
          { LOG(LogInfo) << "[Hardware] Hardware " << hardware; }
        }
      }
      if (strncmp(line, REVISION_STRING, SizeLitteral(REVISION_STRING)) == 0)
      {
        char* colon = strchr(line, ':');
        if (colon != nullptr)
        {
          revision = colon + 2;
          revision.erase(revision.find_last_not_of(" \t\r\n") + 1);
          unsigned int irevision = (int) strtol(colon + 2, nullptr, 16); // Convert hexa revision

          if ((hardware == "BCM2835") || (hardware == "BCM2711"))
          {
            { LOG(LogInfo) << "[Hardware] Pi revision " << revision; }
            mType = GetPiModel(irevision);
          }
        }
      }
    }
    fclose(f);
  }

  return mType;
}
