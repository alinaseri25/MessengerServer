#ifndef SESSION_H
#define SESSION_H

#include <QObject>

#include <QtSql>
#include <QtSql/QSqlDatabase>
#include <QSqlDatabase>
#include <QtSql/QtSql>
#include <QtSql/QSqlDatabase>
#include <QtSql/QSqlDriver>
#include <QtSql/QSqlQuery>

#include "equipment.h"
#include "entity.h"

class Session : public QObject
{
    Q_OBJECT
public:
    explicit Session(QSqlDatabase *_messengerDB,Entity *_entity,Equipment *_equipment,QString _ipAddress,QString _userAgent,QObject *parent = nullptr);
    ~Session();
    bool loginSession(void);
    bool logoutSession(void);
    bool checkSession(uint32_t _sessionId,QString _sessionToken);
    bool sessionIsValid(void);
    uint32_t getSessionId(void);
    Entity* getEntity(void);
    Equipment* getEquipment(void);
    QString getSessionToken(void);

private:
    uint32_t sessionId;
    QString ipAddress;
    QString userAgent;
    QString sessionToken;
    QString refreshToken;
    QDateTime expiresAt;

    Equipment *equipment = nullptr;
    Entity *entity = nullptr;

    QSqlDatabase *messengerDB;
    bool isValid;

private slots:
    void onEntityTerminatd(uint32_t _entityId);
    void onEquipmentTerminatd(uint32_t _equipmentID);

signals:
    uint32_t requestWriteData(QJsonDocument *jsonDoc, QByteArray *payload = nullptr);
    void sessionTerminated(uint32_t _sessionId);
};

#endif // SESSION_H
