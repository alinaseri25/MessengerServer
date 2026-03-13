#ifndef CONNECTIONS_H
#define CONNECTIONS_H

#include <QObject>
#include <QSslSocket>
#include <QDebug>
#include <QJsonDocument>
#include <QJsonParseError>
#include <QJsonObject>
#include <QTimer>
#include <QAbstractSocket>

#include <QCryptographicHash>
#include <QRandomGenerator>

#include <QtSql>
#include <QtSql/QSqlDatabase>
#include <QSqlDatabase>
#include <QtSql/QtSql>
#include <QtSql/QSqlDatabase>
#include <QtSql/QSqlDriver>
#include <QtSql/QSqlQuery>

#include "packetStructs.h"
#include "session.h"

#define connectionTime 180000

class Connections : public QObject
{
    Q_OBJECT
public:
    explicit Connections(QSslSocket *_tcpSocket, quint64 _socketId, QSqlDatabase *_messengerDB, QObject *parent = nullptr);
    ~Connections();
    uint32_t sendTestData(QString Data);

private: //variables
    QSslSocket *tcpSocket;
    quint64 socketId;
    QByteArray m_buffer;
    QList<QByteArray> inputBuffers;
    QTimer *connectionTimeout,*queueTimer,*sendTimeout,*inputProcess;
    QSqlDatabase *messengerDB;
    QMap<uint32_t,Equipment*> equipments;
    QMap<uint32_t,Session*> sessions;
    QList<QByteArray> sendQueue;

private: //functions
    QString generateSessionToken(void);
    bool logingIn(QJsonDocument *jsonDoc, QByteArray *payload = nullptr);
    bool sessionRequest(QJsonDocument *jsonDoc, QByteArray *payload = nullptr);


private slots:
    void readyRead(void);
    void disconnectedSocket(void);
    void errorOccurred(QAbstractSocket::SocketError socketError);
    uint32_t writeData(QJsonDocument *jsonDoc, QByteArray *payload = nullptr);
    void onQueueTimerTimeout(void);
    void onConnectionTimeout(void);
    void onSendTimeout(void);
    void onBytesWrited(qint64 _bytes);
    void onEquipmentDisconnected(uint32_t _equipmentID);
    void inputProcessTimeout(void);
    void onSessionTerminated(uint32_t _sessionId);

signals:
    void connectionDisconnected(quint64 _socketId);
};

#endif // CONNECTIONS_H
