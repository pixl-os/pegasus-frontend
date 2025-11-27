#include "qmlvaluereader.h"
#include "Log.h"

QString QmlValueReader::readStringValue(const QString& qmlFilePath, const QString& propertyKey)
{
    QFile file(qmlFilePath);

    // 1. Attempt to open the file for read-only access
    if (!file.open(QIODevice::ReadOnly | QIODevice::Text)) {
        //Log::debug(LOGMSG("QmlValueReader: Could not open QML file: '%1'").arg(qmlFilePath));
        return QString();
    }

    QTextStream in(&file);

    // The target key string we are searching for, including the colon
    QString targetKey = propertyKey + ":";
    //Log::debug(LOGMSG("QmlValueReader: targetKey: '%1'").arg(targetKey));

    while (!in.atEnd()) {
        QString line = in.readLine().trimmed();
        //Log::debug(LOGMSG("QmlValueReader: line trimmed: '%1'").arg(line));

        // 2. Check if the line starts with our target key
        if (line.contains(targetKey)) {
            // Remove the key and colon to isolate the value part
            line = line.remove(0, targetKey.length()).trimmed();
            //Log::debug(LOGMSG("QmlValueReader: line without key: '%1'").arg(line));

            // Expected format: "VALUE";
            // Check for quotes and the trailing semicolon for robustness
            if (line.startsWith('"') && line.contains(';')) {
                // 3. Extract the clean value

                // Remove the semicolon (;)

                line = line.split(";")[0].trimmed();

                // Remove the leading quote (")
                line.remove(0, 1);

                // Remove the trailing quote (")
                line.chop(1);

                // 4. Success! Close the file and return the value immediately.
                file.close();
                //Log::debug(LOGMSG("QmlValueReader: line returned: '%1'").arg(line));
                return line;
            }
        }
    }

    // If the loop finishes without finding the key
    file.close();
    //Log::debug(LOGMSG("QmlValueReader: Key not found or format invalid for key: '%1'").arg(propertyKey));
    return QString();
}
