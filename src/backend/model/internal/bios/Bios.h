// Pegasus Frontend
//
// Created by Bozo The Geek - 20/01/2022
//

#pragma once

#include "utils/QmlHelpers.h"
#include <QString>
#include <QObject>
#include <utils/os/fs/Path.h>
#include <utils/hash/Md5.h>

namespace model {

class Bios : public QObject {
    Q_OBJECT

public:
    explicit Bios(QObject* parent = nullptr);
    Q_INVOKABLE QString md5 (const QString path); //could be any path relative or not

signals:

private slots:

public:
    static constexpr int sMaxBiosPath = 2;
    enum class Status
    {
      FileNotFound,    //!< File does not exist
      FileFound,    //!< File exists
    };

private:
    /*!
     * @brief MD5 Binary Hash container
     */
    struct Md5Hash
    {
      private:
        //! Binary representation of a MD5 hash
        unsigned char mBytes[16];
        bool mValid;

      public:
        /*!
         * @brief Default Constructor
         */
        Md5Hash()
          : mBytes {},
            mValid(false)
        {
          memset(mBytes, 0, sizeof(mBytes));
        }

        /*!
         * @brief Copy constructor
         * @param source Source Hash
         */
        Md5Hash& operator = (const Md5Hash& source)
        {
          if (&source != this)
          {
            memcpy(mBytes, source.mBytes, sizeof(mBytes));
            mValid = source.mValid;
          }
          return *this;
        }

        /*!
         * @brief Copy constructor
         * @param source Source Hash
         */
        Md5Hash(const Md5Hash& source)
          : mBytes {},
            mValid(source.mValid)
        {
          memcpy(mBytes, source.mBytes, sizeof(mBytes));
        }

        /*!
         * @brief Construct from MD5 object
         * @param source MD5 object
         */
        explicit Md5Hash(const MD5& source)
          : mBytes {},
            mValid(true)
        {
          memcpy(mBytes, source.Output(), sizeof(mBytes));
        }

        /*!
         * @brief Deserialization constructor
         * @param source Source stringized hash
         */
        explicit Md5Hash(const std::string& source);

        /*!
         * @brief String representation of the MD5
         * @return string
         */
        std::string ToString() const;
    };

    //! Bios path (absolute)
    Path mPath[sMaxBiosPath];
    //! Real File hash
    Md5Hash mRealFileHash;
    //! Scan status
    Status mStatus;
};
} // namespace model
