//
// Created by bkg2k on 03/11/2020.
//
// From recalbox ES and Integrated by BozoTheGeek 12/04/2021 in Pegasus Front-end
//

#include "HardwareMessageSender.h"

HardwareMessageSender::HardwareMessageSender()
  : mSender(this)
{
}

void HardwareMessageSender::ReceiveSyncCallback(const SDL_Event& event)
{
  // Extract parameters
  HardwareMessage* message = (HardwareMessage*)event.user.data1;

  // Process
  ProcessMessage(message);
}

void HardwareMessageSender::ProcessMessage(HardwareMessage* message)
{
  // Call target interface accordingly
  switch(message->Type())
  {
    case MessageTypes::None: break;
    case MessageTypes::HeadphonePluggedIn:
    {
      { LOG(LogDebug) << "[Hardware] Headphones plugged!"; }
      break;
    }
    case MessageTypes::HeadphoneUnplugged:
    {
      { LOG(LogDebug) << "[Hardware] Headphones unplugged!"; }
      break;
    }
    case MessageTypes::PowerButtonPressed:
    {
      { LOG(LogDebug) << "[Hardware] Power button pressed for " << message->Millisecond() << "ms."; }
      break;
    }
    case MessageTypes::VolumeDownPressed:
    {
      { LOG(LogDebug) << "[Hardware] Volume down button pressed."; }
      break;
    }
    case MessageTypes::VolumeUpPressed:
    {
      { LOG(LogDebug) << "[Hardware] Volume up button pressed."; }
      break;
    }
    case MessageTypes::Resume:
    {
      { LOG(LogDebug) << "[Hardware] Hardware exited from suspend mode."; }
      break;
    }
    default: break;
  }
  // Recycle message
  mMessages.Recycle(message);
}

void HardwareMessageSender::Send(BoardType boardType, MessageTypes messageType)
{
  HardwareMessage* message = mMessages.Obtain()->Build(messageType, boardType);
  ProcessMessage(message);
}

void HardwareMessageSender::Send(BoardType boardType, MessageTypes messageType, int milliseconds)
{
  HardwareMessage* message = mMessages.Obtain()->Build(messageType, boardType, milliseconds);
  ProcessMessage(message);
}

