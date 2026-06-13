#include "equipment.h"

Equipment::Equipment(QSqlDatabase *_messengerDB, uint32_t _connectionTimeout, QObject *parent)
    : QObject{parent}
{
    connectionTimeout = _connectionTimeout;
    messengerDB = _messengerDB;
}

Equipment::~Equipment()
{
    emit equipmentTerminatd(equipmentID);
}

void Equipment::setEquipmentID(uint32_t _equipmentID)
{
    equipmentID = _equipmentID;
}

void Equipment::setDeviceUUID(QString _deviceUUID)
{
    deviceUUID = _deviceUUID;
}

uint32_t Equipment::getEquipmentID()
{
    return equipmentID;
}

QString Equipment::getDeviceUUID()
{
    return deviceUUID;
}

bool Equipment::getIsActivate()
{
    return isActivate;
}

bool Equipment::handShake(QJsonDocument *jsonDocument, QByteArray *payload)
{
    auto emitError = [&]() {
        QJsonObject responseObject;
        responseObject.insert("type",Handshake);//QString("handshake")
        responseObject.insert("status",States::nok);
        QJsonDocument *responseDocument = new QJsonDocument(responseObject);
        emit requestWriteData(responseDocument);
    };

    if(!jsonDocument)
    {
        emit emitError();
        return false;
    }

    QJsonObject jsonObject = jsonDocument->object();
    QJsonObject responseObject;
    if(jsonObject.value("type").toInt(0) == Handshake)//QString("handshake")
    {
        deviceUUID = jsonObject.value("deviceUUID").toString("");
        deviceName = jsonObject.value("deviceName").toString("");
        equipmentType = jsonObject.value("deviceType").toInt(EquipmentType::Other);

        if(!messengerDB)
        {
            emit emitError();
            return false;
        }
        QSqlQuery query(*messengerDB);

        query.prepare(R"(
        INSERT INTO equipments (
            device_uuid,
            device_type,
            device_name,
            last_activity_at
        )
        VALUES (:uuid, :type, :name, NOW())
        ON DUPLICATE KEY UPDATE
            device_type = VALUES(device_type),
            device_name = VALUES(device_name),
            last_activity_at = NOW(),
            equipment_id = LAST_INSERT_ID(equipment_id)
        )");

        query.bindValue(":uuid", deviceUUID);
        query.bindValue(":type", equipmentType);
        query.bindValue(":name", deviceName);

        if(!query.exec())
        {
            qDebug() << query.lastError();
            return false;
        }
        equipmentID = query.lastInsertId().toULongLong();

        checkEquipmentState();

        if(equipmentID == jsonObject.value("deviceId").toInt(0))
        {
            firstConnection = false;
        }

        qDebug() << QString("deviceUUID : %1 - deviceName : %2 - equipmentID : %3").arg(deviceUUID,deviceName,QString::number(equipmentID));

        responseObject.insert("type",Handshake);//QString("handshake")
        responseObject.insert("status",States::ok);
        responseObject.insert("firstConnection",firstConnection);
        responseObject.insert("connectionTimeout",static_cast<qint32>(connectionTimeout));
        responseObject.insert("deviceId", static_cast<qint32>(equipmentID));
    }
    else
    {
        emit emitError();
        return false;
    }

    QJsonDocument *responseDocument = new QJsonDocument(responseObject);
    emit requestWriteData(responseDocument);
    return true;
}

bool Equipment::keepAlive(QJsonDocument *jsonDocument, QByteArray *payload)
{
    auto emitError = [&]() {
        QJsonObject responseObject;
        responseObject.insert("type",KeepAlive);//QString("keepAlive")
        responseObject.insert("status",States::nok);
        QJsonDocument *responseDocument = new QJsonDocument(responseObject);
        emit requestWriteData(responseDocument);
    };

    if(!jsonDocument)
    {
        emit emitError();
        return false;
    }
    QJsonObject jsonObject = jsonDocument->object();
    QJsonObject responseObject;
    if(jsonObject.value("type").toInt(0) == KeepAlive)//QString("keepAlive")
    {
        checkEquipmentState();
        responseObject.insert("type",KeepAlive);//QString("keepAlive")
        if(jsonObject.value("deviceId").toInt(0) == equipmentID)
        {
            responseObject.insert("status",States::ok);
        }
        else
        {
            responseObject.insert("status",States::nok);
            responseObject.insert("connectionTimeout",static_cast<qint32>(connectionTimeout));
            responseObject.insert("firstConnection",firstConnection);
            responseObject.insert("deviceId", static_cast<qint32>(equipmentID));
        }
    }
    else
    {
        emit emitError();
        return false;
    }

    QJsonDocument *responseDocument = new QJsonDocument(responseObject);
    emit requestWriteData(responseDocument);
    return true;
}

bool Equipment::disconnectEquipment()
{
    emit equipmentDisconnected(equipmentID);
    this->deleteLater();
    return true;
}

bool Equipment::checkEquipmentState()
{
    isActivate = false;
    if(!messengerDB)
    {
        return false;
    }

    QSqlQuery query(*messengerDB);

    query.prepare("SELECT * FROM equipments WHERE equipment_id = :equipmentId");
    query.bindValue(":equipmentId",equipmentID);

    if(!query.exec())
    {
        qDebug() << query.lastError();
        return false;
    }

    if(query.next())
    {
        isActivate = query.value("is_active").toBool();
    }
    return true;
}
