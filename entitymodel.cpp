#include "entitymodel.h"

EntityModel::EntityModel(QObject *parent)
    : QAbstractListModel(parent)
{
}

int EntityModel::rowCount(const QModelIndex &) const
{
    return m_entities.size();
}

QVariant EntityModel::data(const QModelIndex &index, int role) const
{
    if (!index.isValid())
        return QVariant();

    const EntityEnum &e = m_entities[index.row()];

    switch (role) {
    case EntityIdRole: return e.entity_id;
    case EntityTypeRole: return e.entity_type;
    case DisplayNameRole: return e.display_name;
    case UsernameRole: return e.username;
    case QuickMetaRole: return e.quick_meta;
    case CreatedAtRole: return e.created_at;
    case UpdatedAtRole: return e.updated_at;
    case IsActiveRole: return e.is_active;
    case IsDeletedRole: return e.is_deleted;
    }

    return QVariant();
}

QHash<int, QByteArray> EntityModel::roleNames() const
{
    return {
        {EntityIdRole, "entity_id"},
        {EntityTypeRole, "entity_type"},
        {DisplayNameRole, "display_name"},
        {UsernameRole, "username"},
        {QuickMetaRole, "quick_meta"},
        {CreatedAtRole, "created_at"},
        {UpdatedAtRole, "updated_at"},
        {IsActiveRole, "is_active"},
        {IsDeletedRole, "is_deleted"}
    };
}

void EntityModel::addEntity(const EntityEnum &entity)
{
    beginInsertRows(QModelIndex(), m_entities.size(), m_entities.size());
    m_entities.append(entity);
    endInsertRows();
}

void EntityModel::clear()
{
    beginResetModel();
    m_entities.clear();
    endResetModel();
}
