//
// Created by bkg2k on 03/11/2020.
//
// From recalbox ES and Integrated by BozoTheGeek 12/04/2021 in Pegasus Front-end
//
#pragma once

#include "hardware/BoardType.h"
#include "MessageTypes.h"

class HardwareMessage
{
  public:
    //! Default constructor
    HardwareMessage()
      : mType(MessageTypes::None)
      , mBoardType(BoardType::Unknown)
    {
    }

    /*!
     * @brief Reset the message to its default value
     */
    void Reset()
    {
      Build(MessageTypes::None, BoardType::Unknown);
    }

    /*!
     * @brief Build a simple message
     * @param type MessageType
     * @param boardType BoardType
     * @return This message
     */
    HardwareMessage* Build(MessageTypes type, BoardType boardType)
    {
      mType = type;
      mBoardType = boardType;
      return this;
    }

    /*!
     * @brief Build a timed message
     * @param type MessageType
     * @param boardType BoardType
     * @param milliseconds time
     * @return This message
     */
    HardwareMessage* Build(MessageTypes type, BoardType boardType, int milliseconds)
    {
      mType = type;
      mBoardType = boardType;
      mMilliseconds = milliseconds;
      return this;
    }

    /*
     * Accessors
     */

    //! Get Message Type
    MessageTypes Type() const { return mType; }
    //! Get Board Type
    BoardType Board() const { return mBoardType; }
    //! Get Time
    int Millisecond() const { return mMilliseconds; }

  private:
    //! Message Type
    MessageTypes mType;
    //! Board Type
    BoardType mBoardType;
    //! Time
    int mMilliseconds;
};
