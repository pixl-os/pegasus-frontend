//
// Created by bkg2k on 03/11/2020.
//
// From recalbox ES and Integrated by BozoTheGeek 12/04/2021 in Pegasus Front-end
//
#pragma once

#include <utils/sdl2/ISynchronousEvent.h>
#include <utils/sdl2/SyncronousEvent.h>
#include <utils/storage/MessageFactory.h>
#include "MessageTypes.h"
#include "HardwareMessage.h"

class HardwareMessageSender: private ISynchronousEvent
{
  public:
    /*!
     * @brief Constructor
     */
    explicit HardwareMessageSender();
    
    /*!
     * @brief Send a simple message
     * @param board Board type
     * @param message Message type
     */
    void Send(BoardType board, MessageTypes message);

    /*!
     * @brief Send a timed message
     * @param board Board type
     * @param message Message type
     */
    void Send(BoardType board, MessageTypes message, int milliseconds);

  private:
   
    //! Message factory
    MessageFactory<HardwareMessage> mMessages;
    //! Synchronous event sender
    SyncronousEvent mSender;

    /*!
     * @brief Received synchronized messages from hardware threads
     * and send them to the target interface so that the main thread
     * can process hardware event safely
     * @param event SDL2 event
     */
    void ReceiveSyncCallback(const SDL_Event& event) override;

    /*!
     * @brief Process the hardware message
     * @param message Message to process
     */
    void ProcessMessage(HardwareMessage* message);
};

