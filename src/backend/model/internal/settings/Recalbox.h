// Pegasus Frontend for recalbox

#pragma once

//For recalbox
#include "ParametersList.h"

#include "RecalboxConf.h"
#include "utils/QmlHelpers.h"
#include <audio/AudioController.h>

#include <QObject>

namespace model {

/// Provides a recalbox.conf interface for the frontend layer
class Recalbox : public QObject {
    Q_OBJECT

    //for recalbox.conf parameters using binding to be updated dynamically in menu and from other tools/services/scripts
    Q_PROPERTY(int audioVolume READ getAudioVolume WRITE setAudioVolume NOTIFY audioVolumeChanged);
    Q_PROPERTY(int screenBrightness READ getScreenBrightness WRITE setScreenBrightness NOTIFY screenBrightnessChanged);

    QML_CONST_PROPERTY(model::ParametersList, parameterslist);

public:
    explicit Recalbox(QObject* parent = nullptr);

    //for recalbox.conf parameters using binding to be updated dynamically in menu and from other tools/services/scripts
    int getAudioVolume() const { return RecalboxConf::Instance().GetAudioVolume(); }
    void setAudioVolume(int);
    int getScreenBrightness() const { return RecalboxConf::Instance().GetScreenBrightness(); }
    void setScreenBrightness(int);

    //INVOKABLE functions but without binding
    Q_INVOKABLE QString getStringParameter(const QString& Parameter, const QString& defaultValue = "");
    Q_INVOKABLE void setStringParameter(const QString& Parameter, const QString& Value);
    Q_INVOKABLE bool getBoolParameter(const QString& Parameter, const bool& defaultValue = false);
    Q_INVOKABLE void setBoolParameter(const QString& Parameter, const bool& Value);
    Q_INVOKABLE int getIntParameter(const QString& Parameter);
    Q_INVOKABLE void setIntParameter(const QString& Parameter, const int& Value);
    Q_INVOKABLE void saveParameters();
    Q_INVOKABLE void reloadParameter(QString parameters); //to reload any parameters from recalbox.conf
    Q_INVOKABLE QString runCommand(const QString& SysCommand, const QStringList& SysOptions);

signals:
    //for recalbox.conf parameters using binding to be updated dynamically in menu and from other tools/services/scripts
    void audioVolumeChanged();
    void screenBrightnessChanged();

private:

    //! Boot configuration file
    IniFile m_RecalboxBootConf;

};

} // namespace model
