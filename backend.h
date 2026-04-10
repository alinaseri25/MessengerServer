#ifndef BACKEND_H
#define BACKEND_H

#include <QObject>
#include "server.h"
#include <QThread>

class backend : public QObject
{
    Q_OBJECT
public:
    explicit backend(QObject *parent = nullptr);
    ~backend();

private:
    server *curServer = nullptr;
    bool serverState = false;
    QThread *networkThread = nullptr;

signals:
    void serverStateChanged(bool state,QString msg);
    void socketsCount(int count);
    void dataFromSocket(QString data,int index);
    void startServer(QHostAddress _address,quint16 _port);
    void stopServer(void);
    void getServerState(void);
    void sendDataTo(QString data, quint64 listNumber);
    void dataBaseState(bool dbState, QString msg);

private slots:
    void onSocketsCountChanged(bool _state, QString _serverMsg, quint64 _SocketCount, bool _dbState, QString _dbMsg);
    void onDataRecieved(QByteArray data,int index);

public slots:
    void onConnectDisconnectClicked(quint16 portNumber);
    void onSendClicked(int listNumber);
};

#endif // BACKEND_H
