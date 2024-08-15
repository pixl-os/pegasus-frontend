
#pragma once

#include "utils/MoveOnly.h"
#include <utils/IniFile.h>
#include <QAbstractListModel>

namespace model {
struct ParameterEntry {
    QString name;
    explicit ParameterEntry(QString name);
    MOVE_ONLY(ParameterEntry)
};


class ParametersList : public QAbstractListModel {
    Q_OBJECT
    Q_PROPERTY(int currentIndex READ currentIndex WRITE setCurrentIndex NOTIFY parameterChanged)
    Q_PROPERTY(int count READ rowCount NOTIFY parameterChanged)
    Q_PROPERTY(int currentIndexChecked READ currentIndexChecked WRITE setCurrentIndexChecked NOTIFY checkedChanged)
public:
    explicit ParametersList(QObject* parent = nullptr);

    enum Roles {
        Name = Qt::UserRole + 1,
   };

    int rowCount(const QModelIndex& parent = QModelIndex()) const override;
    QVariant data(const QModelIndex& index, int role = Qt::DisplayRole) const override;
    QHash<int, QByteArray> roleNames() const override { return m_role_names; }

    int currentIndex() const { return static_cast<int>(m_current_idx); }
    int currentIndexChecked() const { return static_cast<int>(m_current_checked); }

    void setCurrentIndex(int);
    //to set checked value for current index
    void setCurrentIndexChecked(bool);
    
	//CurrentName is used to initiate the parameters list from list define by the developer and return the existing value from recalbox.conf if exist
    Q_INVOKABLE  QString currentName (const QString& Parameter, const QString& InternalName = "");
    Q_INVOKABLE  QString currentInternalName (const QString& Parameter);
    //CurrentNameFromSystem is used to initiate the parameters list generated from a system/script command and return the existing value from recalbox.conf if exist
    Q_INVOKABLE  QString currentNameFromSystem (const QString& Parameter, const QString& SysCommand, const QStringList& SysOptions);

    //CurrentNameChecked to return string with number of checked values/total
    Q_INVOKABLE  QString currentNameChecked (const QString& Parameter);
    //to be able to set checkbox state individually
    Q_INVOKABLE QList<bool> isChecked();

//Variant examples from QML	
/* Item {
    property variant items: [1, 2, 3, "four", "five"]
    property variant attributes: { 'color': 'red', 'width': 100 }

    Component.onCompleted: {
        for (var i = 0; i < items.length; i++)
            console.log(items[i])

        for (var prop in attributes)
            console.log(prop, "=", attributes[prop])
    }
}
 */
signals:
    void parameterChanged();
    void checkedChanged();

private:
    const QHash<int, QByteArray> m_role_names;
    std::vector<ParameterEntry> m_parameterslist;
    QString m_parameter;

    //! Boot configuration file
    IniFile m_RecalboxBootConf;
    
    size_t m_current_idx;
    size_t m_current_checked;

    //for parameter list using one selected value
    void select_preferred_parameter(const QString&);
    bool select_parameter(const QString&);
    void save_selected_parameter();

    //for parameter list using checkbox
    void check_preferred_parameter(const QString&);
    bool check_parameter(const QString&);
    void save_checked_parameter(const bool);

};
} // namespace model
