//
// Created by bkg2k on 12/01/2020.
//
// From recalbox ES and Integrated by BozoTheGeek 12/04/2021 in Pegasus Front-end
//
#pragma once

#include <utils/rLog.h>

// Short name holder to get non-T dependant static instance per template instance
template<class T> class NameHolder
{
  public:
    //! Class name
    const char* mClassName;
    //! Constructor
    NameHolder() { mClassName = "<unset>"; }
};

template<class T> class StaticLifeCycleControler
{
  private:
    //! Class name (or whatever instance identifier you'd use)
    static NameHolder<T> sNameHolder;
    //! Instance
    static T* sInstance;

  protected:
    /*!
     * @brief Default constructor
     * @param name Name
     */
    explicit StaticLifeCycleControler(const char* name);

    /*!
     * @brief Default destructor
     */
    ~StaticLifeCycleControler();

  public:
    /*!
     * @brief Instance getter
     * @return static Instance
     */
    static T& Instance();

    /*!
     * @brief Check if the object is available
     * @return True if the object has been instantiated
     */
    static bool IsInstantiated() { return sInstance !=  nullptr; }
};

template<class T>
T* StaticLifeCycleControler<T>::sInstance = nullptr;

template<class T>
NameHolder<T> StaticLifeCycleControler<T>::sNameHolder;

template<class T>
StaticLifeCycleControler<T>::StaticLifeCycleControler(const char* name)
{
  if (sInstance != nullptr)
  {
    { LOG(LogInfo) << "[StaticLifeCycleControler] Instance of " << name << " already exists!"; }
    exit(-1);
  }

  sNameHolder.mClassName = name;
  sInstance = (T*)this;
  { LOG(LogInfo) << "[StaticLifeCycleControler] " << name << " instance created."; }
}

template<class T>
StaticLifeCycleControler<T>::~StaticLifeCycleControler()
{
  if (sInstance != this)
  {
    { LOG(LogInfo) << "[StaticLifeCycleControler] Abnormal destruction of " << sNameHolder.mClassName; }
    exit(-1);
  }
  sInstance = nullptr;
}

template<class T>
T& StaticLifeCycleControler<T>::Instance()
{
  if (sInstance != nullptr)
    return *sInstance;

  { LOG(LogError) << "[StaticLifeCycleControler] " << sNameHolder.mClassName << " not yet available!"; }
  exit(-1);
}

