#ifndef ENTITYMODEL_H
#define ENTITYMODEL_H

#include <QAbstractListModel>
#include <QJsonObject>
#include <QDateTime>

struct EntityEnum
{
    qint64 entity_id;
    int entity_type;
    QString display_name;
    QString username;
    QJsonObject quick_meta;
    QDateTime created_at;
    QDateTime updated_at;
    bool is_active;
    bool is_deleted;
};

class EntityModel : public QAbstractListModel
{
    Q_OBJECT

public:

    enum Roles {
        EntityIdRole = Qt::UserRole + 1,
        EntityTypeRole,
        DisplayNameRole,
        UsernameRole,
        QuickMetaRole,
        CreatedAtRole,
        UpdatedAtRole,
        IsActiveRole,
        IsDeletedRole
    };

    explicit EntityModel(QObject *parent = nullptr);

    int rowCount(const QModelIndex &parent = QModelIndex()) const override;
    QVariant data(const QModelIndex &index, int role) const override;
    QHash<int, QByteArray> roleNames() const override;

    void addEntity(const EntityEnum &entity);
    void clear();

private:
    QVector<EntityEnum> m_entities;
};

#endif
