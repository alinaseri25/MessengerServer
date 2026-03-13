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

bool Equipment::handShake(QJsonDocument *jsonDocument, QByteArray *payload)
{
    QJsonObject jsonObject = jsonDocument->object();
    QJsonObject responseObject;
    if(jsonObject.value("type").toString("") == QString("handshake"))
    {
        deviceUUID = jsonObject.value("deviceUUID").toString("");
        deviceName = jsonObject.value("deviceName").toString("");
        equipmentType = jsonObject.value("deviceType").toInt(EquipmentType::Other);

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
        if(equipmentID == jsonObject.value("deviceId").toInt(0))
        {
            firstConnection = false;
        }

        qDebug() << QString("deviceUUID : %1 - deviceName : %2 - equipmentID : %3").arg(deviceUUID,deviceName,QString::number(equipmentID));

        responseObject.insert("type",QString("handshake"));
        responseObject.insert("status",States::ok);
        responseObject.insert("firstConnection",firstConnection);
        responseObject.insert("connectionTimeout",static_cast<qint32>(connectionTimeout));
        responseObject.insert("deviceId", static_cast<qint32>(equipmentID));
    }
    else
    {
        responseObject.insert("type",QString("handshake"));
        responseObject.insert("status",States::nok);
        QJsonDocument *responseDocument = new QJsonDocument(responseObject);
        requestWriteData(responseDocument);
        return false;
    }

    QJsonDocument *responseDocument = new QJsonDocument(responseObject);
    requestWriteData(responseDocument);
    return true;
}

bool Equipment::keepAlive(QJsonDocument *jsonDocument, QByteArray *payload)
{
    QJsonObject jsonObject = jsonDocument->object();
    QJsonObject responseObject;
    if(jsonObject.value("type").toString("") == QString("keepAlive"))
    {
        responseObject.insert("type",QString("keepAlive"));
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
        responseObject.insert("type",QString("keepAlive"));
        responseObject.insert("status",States::nok);
        QJsonDocument *responseDocument = new QJsonDocument(responseObject);
        requestWriteData(responseDocument);
        return false;
    }

    QJsonDocument *responseDocument = new QJsonDocument(responseObject);
    requestWriteData(responseDocument);
    return true;
}

bool Equipment::disconnectEquipment()
{
    emit equipmentDisconnected(equipmentID);
    this->deleteLater();
    return true;
}
