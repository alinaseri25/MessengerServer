#ifndef BACKEND_H
#define BACKEND_H

#include <QObject>
#include "server.h"
#include <QThread>

class backend : public QObject
{
    Q_OBJECT
    Q_PROPERTY(EntityModel* entityModel READ entityModel CONSTANT)
public:
    explicit backend(QObject *parent = nullptr);
    EntityModel* entityModel();
    ~backend();

private:
    server *curServer = nullptr;
    bool serverState = false;
    QThread *networkThread = nullptr;
    EntityModel m_entityModel;

signals:
    void showToastMessage(bool noError,const QString &_msg);
    void serverStateChanged(bool state,const QString &msg);
    void socketsCount(int count);
    void dataFromSocket(const QString &data,int index);
    void startServer(QHostAddress _address,quint16 _port);
    void stopServer(void);
    void getServerState(void);
    void sendDataTo(const QString &data, quint64 listNumber);
    void dataBaseState(bool dbState, const QString &msg);
    void loadEntitiesPage(int limit, int offset);
    void setDeleted(int entityId,bool isDeleted);
    void setActivate(int entityId, bool isActive);
    void createNewUser(const QString &display,const QString &username,const QString &password);
    void updateUser(int id,const QString &display,const QString &username,const QString &password);

private slots:
    void onSocketsCountChanged(bool _state, QString _serverMsg, quint64 _SocketCount, bool _dbState, QString _dbMsg);
    void onDataRecieved(QByteArray data,int index);

public slots:
    void onConnectDisconnectClicked(quint16 portNumber);
    void onSendClicked(int listNumber);
    void onQmlLoaded(void);
    void onSetDeleted(int entityId,bool isDeleted);
    void onSetActivate(int entityId, bool isActive);
    void onCreateNewUser(const QString &display,const QString &username,const QString &password);
    void onUpdateUser(int id,const QString &display,const QString &username,const QString &password);
};

#endif // BACKEND_H
