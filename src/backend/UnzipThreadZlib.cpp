#include "UnzipThreadZlib.h"
#include <QFile>
#include <QDir>
#include <QDebug>
#include <zlib.h>
#include <vector>

UnzipThreadZlib::UnzipThreadZlib(const QString& zipFilePath, const QString& destinationPath, QObject* parent)
    : QThread(parent), zipFilePath_(zipFilePath), destinationPath_(destinationPath) {}

void UnzipThreadZlib::run() {
    QFile zipFile(zipFilePath_);
    if (!zipFile.open(QIODevice::ReadOnly)) {
        emit errorOccurred(QString("Failed to open zip file: %1").arg(zipFile.errorString()));
        return;
    }

    QByteArray zipData = zipFile.readAll();
    zipFile.close();

    const unsigned char* zipBytes = reinterpret_cast<const unsigned char*>(zipData.constData());
    uLong zipSize = zipData.size();

    const unsigned char* p = zipBytes;
    while (p < zipBytes + zipSize) {
        if (*reinterpret_cast<const uint32_t*>(p) == 0x04034b50) { // Local file header signature
            p += 4; // Skip signature
            uint16_t flags = *reinterpret_cast<const uint16_t*>(p + 6);
            uint16_t compressionMethod = *reinterpret_cast<const uint16_t*>(p + 8);
            uint32_t compressedSize = *reinterpret_cast<const uint32_t*>(p + 18);
            uint32_t uncompressedSize = *reinterpret_cast<const uint32_t*>(p + 22);
            uint16_t fileNameLength = *reinterpret_cast<const uint16_t*>(p + 26);
            uint16_t extraFieldLength = *reinterpret_cast<const uint16_t*>(p + 28);

            p += 30; // Skip local file header

            QString fileName = QString::fromLatin1(reinterpret_cast<const char*>(p), fileNameLength);
            p += fileNameLength;
            p += extraFieldLength;

            if (compressionMethod == 0) { // Stored (no compression)
                QString filePath = destinationPath_ + "/" + fileName;
                QFile outFile(filePath);
                if (outFile.open(QIODevice::WriteOnly)) {
                    outFile.write(reinterpret_cast<const char*>(p), compressedSize);
                    outFile.close();
                    emit fileUnzipped(fileName);
                } else {
                    emit errorOccurred(QString("Failed to create output file: %1").arg(outFile.errorString()));
                    return;
                }
                p += compressedSize;
            } else if (compressionMethod == 8) { // Deflate
                std::vector<unsigned char> uncompressedData(uncompressedSize);
                uLongf destLen = uncompressedSize;

                int result = uncompress(uncompressedData.data(), &destLen, p, compressedSize);
                if (result == Z_OK) {
                    QString filePath = destinationPath_ + "/" + fileName;
                    QFile outFile(filePath);
                    if (outFile.open(QIODevice::WriteOnly)) {
                        outFile.write(reinterpret_cast<const char*>(uncompressedData.data()), destLen);
                        outFile.close();
                        emit fileUnzipped(fileName);
                    } else {
                        emit errorOccurred(QString("Failed to create output file: %1").arg(outFile.errorString()));
                        return;
                    }
                } else {
                    emit errorOccurred(QString("Failed to uncompress file: %1").arg(result));
                    return;
                }
                p += compressedSize;
            } else {
                emit errorOccurred(QString("Unsupported compression method: %1").arg(compressionMethod));
                return;
            }
        } else {
            p++; // Skip invalid signature
        }
    }
    emit finishedUnzipping();
}
