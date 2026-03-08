#ifndef SERVER_H
#define SERVER_H

#include <QObject>
#include <QTcpServer>
#include <QTcpSocket>
#include <QSslSocket>
#include <QSslConfiguration>
#include <QSslCertificate>
#include <QSslKey>
#include <QHostAddress>
#include <QMap>
#include <QFile>
#include <QNetworkInterface>
#include <QCoreApplication>
#include <QSqlDatabase>
#include <QSqlError>
#include <QDebug>

#include "connections.h"
#include "tlscertificategenerator.h"

class TlsTcpServer : public QTcpServer
{
    Q_OBJECT
public:
    explicit TlsTcpServer(QObject *parent = nullptr) : QTcpServer(parent) {}

signals:
    void descriptorReady(qintptr socketDescriptor);

protected:
    void incomingConnection(qintptr socketDescriptor) override
    {
        emit descriptorReady(socketDescriptor);
    }
};

class server : public QObject
{
    Q_OBJECT
public:
    explicit server(QObject *parent = nullptr);
    ~server(void);

private:
    QHostAddress listenAddress;
    quint16 portNumber;
    quint64 listNumber;
    bool dbState = false;
    QString dbMessege;
    QString serverMsg;

    TlsTcpServer *serverObj;
    QMap<quint64, Connections*> connectionsList;
    QSqlDatabase *messengerDB = nullptr;

    // TLS
    QSslCertificate serverCert;
    QSslKey serverKey;
    bool tlsEnabled = false;

    qint64 getSocketsCount(void);
    bool createconnection(void);
    bool loadTlsCredentials(const QString &certPath, const QString &keyPath);

    void handleIncomingDescriptor(qintptr socketDescriptor);

signals:
    void dataRecived(QByteArray data, int index);
    void serverState(bool _state, QString _serverMsg, quint64 _SocketCount, bool _dbState, QString _dbMsg);

public slots:
    void startServer(QHostAddress _address, quint16 _port);
    void stopServer(void);
    void getServerState(void);
    void sendDataTo(QString data, quint64 listNumber);

private slots:
    //void readData(QByteArray data, uint32_t _equipmentId);
    void disconnectedSocket(uint32_t _connectionId);

    //void onSocketEncrypted();
    //void onSslErrors(const QList<QSslError> &errors);
};

#endif // SERVER_H
