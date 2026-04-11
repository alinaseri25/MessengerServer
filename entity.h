#ifndef ENTITY_H
#define ENTITY_H

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

class Entity : public QObject
{
    Q_OBJECT
public:
    explicit Entity(QString _username,QSqlDatabase *_messengerDB,QObject *parent = nullptr);
    ~Entity();
    bool entityIsValid(void);
    bool loginEntity(QString _password);
    bool checkExist(uint32_t _entityId);
    uint32_t getEntityId(void);
    QString getDisplayName(void);
    QString getUsername(void);

private:
    uint32_t entityId;
    QString displayName;
    QString username;
    bool isActivate;
    bool isDeleted;
    bool isValid;
    QDateTime updatedAt;
    QSqlDatabase *messengerDB = nullptr;

signals:
    uint32_t requestWriteData(QJsonDocument *jsonDoc, QByteArray *payload = nullptr);
    void entityTerminatd(uint32_t _entityId);
};

#endif // ENTITY_H
