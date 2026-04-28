#include "backend.h"

backend::backend(QObject *parent)
    : QObject{parent}
{
    networkThread = new QThread(this);
    curServer = new server(entityModel());
    connect(curServer,&server::serverState,this,&backend::onSocketsCountChanged);
    connect(curServer,&server::dataRecived,this,&backend::onDataRecieved);

    connect(this,&backend::startServer,curServer,&server::startServer);
    connect(this,&backend::stopServer,curServer,&server::stopServer);
    connect(this,&backend::getServerState,curServer,&server::getServerState);
    connect(this,&backend::sendDataTo,curServer,&server::sendDataTo);
    connect(this,&backend::loadEntitiesPage,curServer,&server::loadEntitiesPage);
    connect(this,&backend::setActivate,curServer,&server::onSetActivate);
    connect(this,&backend::setDeleted,curServer,&server::onSetDeleted);

    curServer->moveToThread(networkThread);
    networkThread->start();
}

EntityModel *backend::entityModel()
{
    return &m_entityModel;
}

backend::~backend()
{
    if(networkThread != nullptr)
    {
        networkThread->quit();
        networkThread->wait();
        networkThread->deleteLater();
        networkThread = nullptr;
    }
    if(curServer != nullptr)
    {
        curServer->deleteLater();
        curServer = nullptr;
    }
}

void backend::onSocketsCountChanged(bool _state, QString _serverMsg, quint64 _SocketCount, bool _dbState, QString _dbMsg)
{
    serverState = _state;
    emit socketsCount(_SocketCount);
    emit serverStateChanged(serverState,_serverMsg);
    emit dataBaseState(_dbState,_dbMsg);
}

void backend::onDataRecieved(QByteArray data, int index)
{
    QString str = QString::fromStdString(data.toStdString());
    emit dataFromSocket(str,index);
}

void backend::onSetDeleted(int entityId, bool isDeleted)
{
    emit setDeleted(entityId,isDeleted);
}

void backend::onSetActivate(int entityId, bool isActive)
{
    emit setActivate(entityId,isActive);
}

void backend::onConnectDisconnectClicked(quint16 portNumber)
{
    if(serverState)
    {
        emit stopServer();
    }
    else
    {
        emit startServer(QHostAddress::Any,portNumber);
    }
}

void backend::onSendClicked(int listNumber)
{
    emit sendDataTo(QString("Data send for %1").arg(listNumber),listNumber);
}

void backend::onQmlLoaded()
{
    emit loadEntitiesPage(50,0);
}
