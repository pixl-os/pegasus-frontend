#include "EventType.h"

std::string& operator <<(std::string& stream, const EventType& event)
{
  if (hasFlag(event, EventType::Access))       stream.append("access ");
  if (hasFlag(event, EventType::Attrib))       stream.append("attrib ");
  if (hasFlag(event, EventType::CloseWrite))   stream.append("close_write ");
  if (hasFlag(event, EventType::CloseNowrite)) stream.append("close_nowrite ");
  if (hasFlag(event, EventType::Create))       stream.append("create ");
  if (hasFlag(event, EventType::Remove))       stream.append("remove ");
  if (hasFlag(event, EventType::RemoveSelf))   stream.append("remove_self ");
  if (hasFlag(event, EventType::Modify))       stream.append("modify ");
  if (hasFlag(event, EventType::MoveSelf))     stream.append("move_self ");
  if (hasFlag(event, EventType::MovedFrom))    stream.append("moved_from ");
  if (hasFlag(event, EventType::MovedTo))      stream.append("moved_to ");
  if (hasFlag(event, EventType::Open))         stream.append("open ");
  if (hasFlag(event, EventType::IsDir))        stream.append("is_dir ");
  if (hasFlag(event, EventType::Unmount))      stream.append("unmount ");
  if (hasFlag(event, EventType::QOverflow))    stream.append("q_overflow ");
  if (hasFlag(event, EventType::Close))        stream.append("close ");
  if (hasFlag(event, EventType::Ignored))      stream.append("ignored ");
  if (hasFlag(event, EventType::Oneshot))      stream.append("oneshot ");

  return stream;
}
