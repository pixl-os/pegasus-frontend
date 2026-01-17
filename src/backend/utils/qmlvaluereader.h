#ifndef QMLVALUEREADER_H
#define QMLVALUEREADER_H

#include <QString>
#include <QFile>
#include <QTextStream>
#include <QDebug>

class QmlValueReader
{
public:
    /**
     * @brief Reads a unique string value from a QML file based on its property name.
     * * The function performs a line-by-line text search, stopping as soon as the key is found.
     * It is optimized for the QML property format: 'propertyName: "value";'
     * * @param qmlFilePath The absolute path to the QML file.
     * @param propertyKey The property name to search for (e.g., "humanReadableName").
     * @return The extracted value (e.g., "SF30 PRO (JP/EU)"), or an empty string on failure.
     */
    static QString readStringValue(const QString& qmlFilePath, const QString& propertyKey);
};

#endif // QMLVALUEREADER_H

