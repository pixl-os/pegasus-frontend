//
// Created by matthieu on 12/09/15.
//
#pragma once

#include <utils/IniFile.h>
#include <utils/cplusplus/StaticLifeCycleControler.h>

class RecalboxConf : public IniFile, public StaticLifeCycleControler<RecalboxConf>
{
  public:
    /*!
     * @brief Confstructor
     * @param initialConfigOnly true if only the original file has to be loaded
     */
    explicit RecalboxConf();

    /*!
     * @brief Called when file has been saved
     */
    void OnSave() override;
};
