#include "entity.h"

Entity::Entity(QString _username, QSqlDatabase *_messengerDB, QObject *parent)
    : QObject{parent}
{
    isValid = false;
    username = _username;
    messengerDB = _messengerDB;
}

Entity::~Entity()
{
    emit entityTerminatd(entityId);
}

bool Entity::entityIsValid()
{
    return isValid;
}

bool Entity::loginEntity(QString _password)
{
    auto emitError = [&]() {
        QJsonObject responseObject;
        responseObject.insert(QString("type"),LoginResponse);//QString("loginResponse")
        responseObject.insert(QString("status"), States::nok);
        responseObject.insert(QString("error"), Errors::userOrPassError);
        responseObject.insert(QString("username"),this->getUsername());
        isValid = false;
        QJsonDocument *responseDocument = new QJsonDocument(responseObject);
        emit requestWriteData(responseDocument);
    };

    if(!messengerDB)
    {
        emit emitError();
        return false;
    }
    messengerDB->transaction();
    QSqlQuery entityQuery(*messengerDB);

    // اول آپدیت
    entityQuery.prepare("UPDATE entities SET updated_at = NOW() WHERE username = :username AND password_hash = :password");
    entityQuery.bindValue(":username", username);
    entityQuery.bindValue(":password", _password);

    if (!entityQuery.exec()) {
        messengerDB->rollback();
        emit emitError();
        return isValid;
    }

    entityQuery.prepare("SELECT * FROM entities WHERE username = :username AND password_hash = :password");
    entityQuery.bindValue(":username", username);
    entityQuery.bindValue(":password", _password);

    if (!entityQuery.exec()) {
        messengerDB->rollback();
        emit emitError();
        isValid = false;
        return isValid;
    }

    messengerDB->commit();

    if (entityQuery.next()) {
        isValid = true;
        entityId = entityQuery.value("entity_id").toLongLong();
        displayName = entityQuery.value("display_name").toString();
        isActivate = entityQuery.value("is_active").toBool();
        isDeleted = entityQuery.value("is_deleted").toBool();
        updatedAt = entityQuery.value("updated_at").toDateTime();
        if(entityId == 0)
        {
            emit emitError();
            isValid = false;
        }
        else if(isDeleted)
        {
            emit emitError();
            isValid = false;
        }
        else
        {
            isValid = true;
        }
    }
    else
    {
        entityId = 0;
        displayName = QString("");
        isActivate = false;
        isDeleted = true;
        emit emitError();
    }

    return isValid;
}

bool Entity::checkExist(uint32_t _entityId)
{
    auto emitError = [&]() {
        QJsonObject responseObject;
        responseObject.insert(QString("type"),SessionResponse);//QString("sessionResponse")
        responseObject.insert(QString("status"), States::nok);
        responseObject.insert(QString("error"), Errors::userOrPassError);
        responseObject.insert(QString("entityId"),(qint32)_entityId);
        isValid = false;
        QJsonDocument *responseDocument = new QJsonDocument(responseObject);
        emit requestWriteData(responseDocument);
    };

    if(!messengerDB)
    {
        emit emitError();
        return false;
    }
    messengerDB->transaction();
    QSqlQuery entityQuery(*messengerDB);

    // اول آپدیت
    entityQuery.prepare("UPDATE entities SET updated_at = NOW() WHERE entity_id = :entity_id");
    entityQuery.bindValue(":entity_id", _entityId);

    if (!entityQuery.exec()) {
        messengerDB->rollback();
        emit emitError();
        return isValid;
    }

    entityQuery.prepare("SELECT * FROM entities WHERE entity_id = :entity_id");
    entityQuery.bindValue(":entity_id", _entityId);

    if (!entityQuery.exec()) {
        messengerDB->rollback();
        emit emitError();
        isValid = false;
        return isValid;
    }

    messengerDB->commit();

    if (entityQuery.next()) {
        isValid = true;
        entityId = entityQuery.value("entity_id").toLongLong();
        username = entityQuery.value("username").toString();
        qDebug() << QString("username : %1").arg(username);
        displayName = entityQuery.value("display_name").toString();
        isActivate = entityQuery.value("is_active").toBool();
        isDeleted = entityQuery.value("is_deleted").toBool();
        updatedAt = entityQuery.value("updated_at").toDateTime();
        if(entityId == 0)
        {
            emit emitError();
            isValid = false;
        }
        else if(!isActivate || isDeleted)
        {
            emit emitError();
            isValid = false;
        }
        else
        {
            isValid = true;
        }
    }
    else
    {
        entityId = 0;
        displayName = QString("");
        isActivate = false;
        isDeleted = true;
        emit emitError();
    }

    return isValid;
}

uint32_t Entity::getEntityId()
{
    return entityId;
}

QString Entity::getDisplayName()
{
    return displayName;
}

QString Entity::getUsername()
{
    return username;
}
