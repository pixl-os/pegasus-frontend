// Pegasus Frontend
//
// Created by Bozo The Geek - 20/01/2022
//

#pragma once

#include "utils/QmlHelpers.h"
#include <QString>
#include <QObject>

namespace model {

class Bios : public QObject {
    Q_OBJECT

public:
    explicit Bios(QObject* parent = nullptr);
    Q_INVOKABLE QString md5 (const QString path); //could be any path relative or not

signals:

private slots:

public:

private:

};
} // namespace model
