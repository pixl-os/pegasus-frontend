
#pragma once

#include "utils/MoveOnly.h"

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
public:
    explicit ParametersList(QObject* parent = nullptr);

    enum Roles {
        Name = Qt::UserRole + 1,
   };

    int rowCount(const QModelIndex& parent = QModelIndex()) const override;
    QVariant data(const QModelIndex& index, int role = Qt::DisplayRole) const override;
    QHash<int, QByteArray> roleNames() const override { return m_role_names; }

    int currentIndex() const { return static_cast<int>(m_current_idx); }
    void setCurrentIndex(int);
    
    Q_INVOKABLE  QString currentName (const QString& Parameter);

signals:
    void parameterChanged();

private:
    const QHash<int, QByteArray> m_role_names;
    std::vector<ParameterEntry> m_parameterslist;
    QString m_parameter;
    

    size_t m_current_idx;

    void select_preferred_parameter(const QString&);
    bool select_parameter(const QString&);
    void load_selected_parameter();

};
} // namespace model
