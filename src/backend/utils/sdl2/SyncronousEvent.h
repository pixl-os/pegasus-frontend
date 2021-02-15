#pragma once

#include "ISynchronousEvent.h"

class SyncronousEvent
{
  private:
    //! Reserved SDL Event
    unsigned int mSDLEvent;

    /*!
     * @brief Private constructor intended to be called only from Service
     * @param event Message index
     */
    explicit SyncronousEvent(unsigned int event)
      : mSDLEvent(event)
    {
    };

    friend class SyncronousEventService;

  public:
    /*!
     * @brief Public constructor
     * @param event Callback
     */
    explicit SyncronousEvent(ISynchronousEvent* callback);

    //! Destructor - Recycle message
    ~SyncronousEvent();

    /*!
     * @brief Return the message index
     * @return Message index
     */
    unsigned int Type() const { return mSDLEvent; }

    /*!
     * @brief Send an async message with no parameters
     */
    void Call() const;

    /*!
     * @brief Send an async message with one parameters
     * @param data free void* parameter
     */
    void Call(int data) const;

    /*!
     * @brief Send an async message with one parameters
     * @param data free void* parameter
     */
    void Call(void* data) const;

    /*!
     * @brief Send an async message with one parameters
     * @param data free void* parameter
     */
    void Call(int data, void* data1) const;

    /*!
     * @brief Send an async message with two parameters
     * @param data1 free void* parameter
     * @param data2 free void* parameter
     */
    void Call(void* data1, void* data2) const;

    /*!
     * @brief Send an async message with two parameters
     * @param data int parameter
     * @param data1 free void* parameter
     * @param data2 free void* parameter
     */
    void Call(int data, void* data1, void* data2) const;
};
