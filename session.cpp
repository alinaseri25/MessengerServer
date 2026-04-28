#include "session.h"

Session::Session(QSqlDatabase *_messengerDB, Entity *_entity, Equipment *_equipment, QString _ipAddress, QString _userAgent, QObject *parent)
    : QObject{parent}
{
    ipAddress = _ipAddress;
    userAgent = _userAgent;
    entity = _entity;
    if(entity)
    {
        connect(entity,&Entity::entityTerminatd,this,&Session::onEntityTerminatd);
    }
    equipment = _equipment;
    if(equipment)
    {
        connect(equipment,&Equipment::equipmentTerminatd,this,&Session::onEquipmentTerminatd);
    }
    sessionId = 0;
    messengerDB = _messengerDB;

    isValid = false;
}

Session::~Session()
{
    if(entity != nullptr)
    {
        entity->deleteLater();
        entity = nullptr;
    }

    emit sessionTerminated(sessionId);
}

bool Session::loginSession()
{
    QJsonObject responseObject;
    responseObject.insert(QString("type"), LoginResponse);//QString("loginResponse")

    auto emitError = [&]() {
        responseObject.insert(QString("status"), States::nok);
        responseObject.insert(QString("error"), Errors::sessionMakerError);
        if(entity != nullptr)
        {
            responseObject.insert(QString("username"),entity->getUsername());
        }
        isValid = false;
        QJsonDocument *responseDocument = new QJsonDocument(responseObject);
        emit requestWriteData(responseDocument);
    };

    if(entity == nullptr || equipment == nullptr)
    {
        emitError();
        return false;
    }

    if(!equipment->getIsActivate())
    {
        emitError();
        return false;
    }

    if (!messengerDB->transaction()) {
        emitError();
        return false;
    }

    QSqlQuery query(*messengerDB);

    // ---------------------------------------------------
    // مرحله ۱: چک وجود رکورد
    // ---------------------------------------------------
    query.prepare(
        "SELECT session_id, expires_at "
        "FROM sessions "
        "WHERE entity_id = :entity_id AND equipment_id = :equipment_id"
        );
    query.bindValue(":entity_id",    entity->getEntityId());
    query.bindValue(":equipment_id", equipment->getEquipmentID());

    if (!query.exec()) {
        messengerDB->rollback();
        emitError();
        return false;
    }

    bool recordExists = query.next();

    // ---------------------------------------------------
    // مرحله ۲
    // ---------------------------------------------------
    if (recordExists) {
        QDateTime expiresAt = query.value("expires_at").toDateTime();
        bool isExpired      = expiresAt < QDateTime::currentDateTimeUtc();

        if (isExpired) {
            // token های جدید تولید کن
            QString newSessionToken = QUuid::createUuid().toString(QUuid::WithoutBraces).remove('-');
            QString newRefreshToken = QUuid::createUuid().toString(QUuid::WithoutBraces).remove('-');
            QDateTime newExpiresAt  = QDateTime::currentDateTimeUtc().addDays(30);

            query.prepare(
                "UPDATE sessions SET "
                "    session_token    = :session_token, "
                "    refresh_token    = :refresh_token, "
                "    expires_at       = :expires_at, "
                "    last_activity_at = NOW(), "
                "    ip_address       = :ip, "
                "    user_agent       = :agent "
                "WHERE entity_id = :entity_id AND equipment_id = :equipment_id"
                );
            query.bindValue(":session_token", newSessionToken);
            query.bindValue(":refresh_token", newRefreshToken);
            query.bindValue(":expires_at",    newExpiresAt);
            query.bindValue(":ip",            ipAddress);
            query.bindValue(":agent",         userAgent);
            query.bindValue(":entity_id",     entity->getEntityId());
            query.bindValue(":equipment_id",  equipment->getEquipmentID());
        } else {
            // فقط activity آپدیت بشه
            query.prepare(
                "UPDATE sessions SET "
                "    last_activity_at = NOW(), "
                "    ip_address       = :ip, "
                "    user_agent       = :agent "
                "WHERE entity_id = :entity_id AND equipment_id = :equipment_id"
                );
            query.bindValue(":ip",           ipAddress);
            query.bindValue(":agent",        userAgent);
            query.bindValue(":entity_id",    entity->getEntityId());
            query.bindValue(":equipment_id", equipment->getEquipmentID());
        }
    } else {
        // رکورد وجود نداشت → insert
        QString newSessionToken = QUuid::createUuid().toString(QUuid::WithoutBraces).remove('-');
        QString newRefreshToken = QUuid::createUuid().toString(QUuid::WithoutBraces).remove('-');
        QDateTime newExpiresAt  = QDateTime::currentDateTimeUtc().addDays(30);

        query.prepare(
            "INSERT INTO sessions (entity_id, equipment_id, session_token, refresh_token, ip_address, user_agent, expires_at) "
            "VALUES (:entity_id, :equipment_id, :session_token, :refresh_token, :ip, :agent, :expires_at)"
            );
        query.bindValue(":entity_id",     entity->getEntityId());
        query.bindValue(":equipment_id",  equipment->getEquipmentID());
        query.bindValue(":session_token", newSessionToken);
        query.bindValue(":refresh_token", newRefreshToken);
        query.bindValue(":ip",            ipAddress);
        query.bindValue(":agent",         userAgent);
        query.bindValue(":expires_at",    newExpiresAt);
    }

    if (!query.exec()) {
        messengerDB->rollback();
        emitError();
        return false;
    }

    // ---------------------------------------------------
    // مرحله ۳: برگردوندن row نهایی
    // ---------------------------------------------------
    query.prepare(
        "SELECT * FROM sessions "
        "WHERE entity_id = :entity_id AND equipment_id = :equipment_id"
        );
    query.bindValue(":entity_id",    entity->getEntityId());
    query.bindValue(":equipment_id", equipment->getEquipmentID());

    if (!query.exec() || !query.next()) {
        messengerDB->rollback();
        emitError();
        return false;
    }

    messengerDB->commit();

    sessionId    = query.value("session_id").toLongLong();
    sessionToken = query.value("session_token").toString();
    refreshToken = query.value("refresh_token").toString();
    expiresAt    = query.value("expires_at").toDateTime();

    if (sessionId != 0) {
        isValid = true;
    } else {
        emitError();
        return false;
    }

    if (!isValid) {
        QJsonDocument *responseDocument = new QJsonDocument(responseObject);
        emit requestWriteData(responseDocument);
    }

    return isValid;
}

bool Session::logoutSession()
{
    QJsonObject responseObject;
    responseObject.insert(QString("type"), LogoutResponse);//QString("logoutResponse")

    auto emitError = [&]() {
        responseObject.insert(QString("status"), States::nok);
        responseObject.insert(QString("error"), Errors::sessionExpired);
        isValid = false;
        QJsonDocument *responseDocument = new QJsonDocument(responseObject);
        emit requestWriteData(responseDocument);
    };

    if(entity == nullptr || equipment == nullptr)
    {
        emitError();
        return false;
    }

    if(!messengerDB)
    {
        emitError();
        return false;
    }

    if (!messengerDB->transaction()) {
        emitError();
        return false;
    }

    QSqlQuery query(*messengerDB);

    // ---------------------------------------------------
    // مرحله ۱: چک وجود رکورد
    // ---------------------------------------------------
    query.prepare(
        "SELECT session_id, expires_at "
        "FROM sessions "
        "WHERE session_id = :session_id AND session_token = :session_token"
        );
    query.bindValue(":session_id",    sessionId);
    query.bindValue(":session_token", sessionToken);

    if (!query.exec()) {
        messengerDB->rollback();
        emitError();
        return false;
    }

    bool recordExists = query.next();

    if (recordExists) {
        QDateTime newExpiresAt  = QDateTime::currentDateTimeUtc();
        query.prepare(
            "UPDATE sessions SET "
            "    expires_at       = :expires_at "
            "WHERE session_id = :session_id"
            );
        query.bindValue(":expires_at",    newExpiresAt);
        query.bindValue(":session_id",    sessionId);
    }
    else
    {
        messengerDB->rollback();
        emitError();
        return false;
    }

    if (!query.exec()) {
        messengerDB->rollback();
        emitError();
        return false;
    }

    messengerDB->commit();

    return true;
}

bool Session::checkSession(uint32_t _sessionId, QString _sessionToken)
{
    sessionId = _sessionId;
    sessionToken = _sessionToken;
    QJsonObject responseObject;
    responseObject.insert(QString("type"), SessionResponse);//QString("sessionResponse")

    auto emitError = [&]() {
        responseObject.insert(QString("status"), States::nok);
        responseObject.insert(QString("error"), Errors::sessionMakerError);
        if(entity != nullptr)
        {
            responseObject.insert(QString("entityId"),(qint32)entity->getEntityId());
        }
        isValid = false;
        QJsonDocument *responseDocument = new QJsonDocument(responseObject);
        emit requestWriteData(responseDocument);
    };

    if(entity == nullptr || equipment == nullptr)
    {
        emitError();
        return false;
    }

    if(!equipment->getIsActivate())
    {
        emitError();
        return false;
    }

    if(!messengerDB)
    {
        emitError();
        return false;
    }

    if (!messengerDB->transaction()) {
        emitError();
        return false;
    }

    QSqlQuery query(*messengerDB);

    // ---------------------------------------------------
    // مرحله ۱: چک وجود رکورد
    // ---------------------------------------------------
    query.prepare(
        "SELECT session_id, expires_at "
        "FROM sessions "
        "WHERE entity_id = :entity_id AND equipment_id = :equipment_id AND session_id = :session_id AND session_token = :session_token"
        );
    query.bindValue(":entity_id",    entity->getEntityId());
    query.bindValue(":equipment_id", equipment->getEquipmentID());
    query.bindValue(":session_id", sessionId);
    query.bindValue(":session_token", sessionToken);

    if (!query.exec()) {
        messengerDB->rollback();
        emitError();
        return false;
    }

    bool recordExists = query.next();

    // ---------------------------------------------------
    // مرحله ۲
    // ---------------------------------------------------
    if (recordExists) {
        QDateTime expiresAt = query.value("expires_at").toDateTime();
        bool isExpired      = expiresAt < QDateTime::currentDateTimeUtc();

        if (isExpired) {
            messengerDB->rollback();
            emitError();
            return false;
        } else {
            // فقط activity آپدیت بشه
            query.prepare(
                "UPDATE sessions SET "
                "    last_activity_at = NOW(), "
                "    ip_address       = :ip, "
                "    user_agent       = :agent "
                "WHERE session_id = :session_id"//entity_id = :entity_id AND equipment_id = :equipment_id"
                );
            query.bindValue(":ip",           ipAddress);
            query.bindValue(":agent",        userAgent);
            query.bindValue(":session_id",         sessionId);
            // query.bindValue(":entity_id",    entity->getEntityId());
            // query.bindValue(":equipment_id", equipment->getEquipmentID());
        }
    } else {
        // رکورد وجود نداشت → insert
        messengerDB->rollback();
        emitError();
        return false;
    }

    if (!query.exec()) {
        messengerDB->rollback();
        emitError();
        return false;
    }

    // ---------------------------------------------------
    // مرحله ۳: برگردوندن row نهایی
    // ---------------------------------------------------
    query.prepare(
        "SELECT * FROM sessions "
        "WHERE session_id = :session_id"
        );
    // query.bindValue(":entity_id",    entity->getEntityId());
    // query.bindValue(":equipment_id", equipment->getEquipmentID());
    query.bindValue(":session_id",         sessionId);

    if (!query.exec() || !query.next()) {
        messengerDB->rollback();
        emitError();
        return false;
    }

    messengerDB->commit();

    sessionId    = query.value("session_id").toLongLong();
    sessionToken = query.value("session_token").toString();
    refreshToken = query.value("refresh_token").toString();
    expiresAt    = query.value("expires_at").toDateTime();

    if (sessionId != 0) {
        isValid = true;
    } else {
        emitError();
        return false;
    }

    if (!isValid) {
        QJsonDocument *responseDocument = new QJsonDocument(responseObject);
        emit requestWriteData(responseDocument);
    }

    return isValid;
}

bool Session::sessionIsValid()
{
    return isValid;
}

uint32_t Session::getSessionId()
{
    return sessionId;
}

Entity *Session::getEntity()
{
    return entity;
}

Equipment *Session::getEquipment()
{
    return equipment;
}

QString Session::getSessionToken()
{
    return sessionToken;
}

void Session::onEntityTerminatd(uint32_t _entityId)
{
    this->deleteLater();
}

void Session::onEquipmentTerminatd(uint32_t _equipmentID)
{
    if(entity != nullptr)
    {
        entity->deleteLater();
        entity = nullptr;
    }
}
