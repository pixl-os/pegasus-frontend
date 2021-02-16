// Pegasus Frontend for recalbox

#pragma once

//For recalbox
#include "RecalboxConf.h"

#include <QObject>

namespace model {

/// Provides a recalbox.conf interface for the frontend layer
class Recalbox : public QObject {
    Q_OBJECT

public:
    explicit Recalbox(QObject* parent = nullptr);
   
    Q_INVOKABLE QString getStringParameter(const QString& Parameter);
    Q_INVOKABLE void setStringParameter(const QString& Parameter, const QString& Value);
    
    Q_INVOKABLE bool getBoolParameter(const QString& Parameter);
    Q_INVOKABLE void setBoolParameter(const QString& Parameter, const bool& Value);
    
    Q_INVOKABLE void saveParameters();
    
private:

};

} // namespace model
