#ifndef EQUIPMENT_H
#define EQUIPMENT_H

#include <QObject>
#include <QJsonDocument>
#include <QJsonParseError>
#include <QJsonObject>
#include <QTimer>
#include <QDateTime>

#include <QtSql>
#include <QtSql/QSqlDatabase>
#include <QSqlDatabase>
#include <QtSql/QtSql>
#include <QtSql/QSqlDatabase>
#include <QtSql/QSqlDriver>
#include <QtSql/QSqlQuery>
#include "../../QtLibraries/packetStructs.hpp"


class Equipment : public QObject
{
    Q_OBJECT
public:
    explicit Equipment(QSqlDatabase *_messengerDB, uint32_t _connectionTimeout, QObject *parent = nullptr);
    ~Equipment();
    void setEquipmentID(uint32_t _equipmentID);
    void setDeviceUUID(QString _deviceUUID);
    uint32_t getEquipmentID(void);
    QString getDeviceUUID(void);
    bool getIsActivate(void);
    bool handShake(QJsonDocument *jsonDocument, QByteArray *payload = nullptr);
    bool keepAlive(QJsonDocument *jsonDocument, QByteArray *payload = nullptr);
    bool disconnectEquipment(void);

private:
    uint32_t connectionTimeout;
    uint32_t equipmentID;
    uint32_t equipmentType;
    bool isActivate;
    QString deviceUUID;
    QString deviceName;
    QSqlDatabase *messengerDB;
    bool firstConnection = true;
    bool checkEquipmentState(void);

signals:
    uint32_t requestWriteData(QJsonDocument *jsonDoc, QByteArray *payload = nullptr);
    void equipmentDisconnected(uint32_t _equipmentID);
    void equipmentTerminatd(uint32_t _equipmentID);
};

#endif // EQUIPMENT_H
