#include "backend.h"

backend::backend(QObject *parent)
    : QObject{parent}
{
    networkThread = new QThread(this);
    curServer = new server();
    connect(curServer,&server::serverState,this,&backend::onSocketsCountChanged);
    connect(curServer,&server::dataRecived,this,&backend::onDataRecieved);

    connect(this,&backend::startServer,curServer,&server::startServer);
    connect(this,&backend::stopServer,curServer,&server::stopServer);
    connect(this,&backend::getServerState,curServer,&server::getServerState);
    connect(this,&backend::sendDataTo,curServer,&server::sendDataTo);

    curServer->moveToThread(networkThread);
    networkThread->start();
}

backend::~backend()
{
    if(networkThread != nullptr)
    {
        networkThread->quit();
        networkThread->wait();
        networkThread->deleteLater();
    }
    if(curServer != nullptr)
    {
        curServer->deleteLater();
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

void backend::onConnectDisconnectClicked(quint16 portNumber)
{
    if(serverState)
    {
        //curServer->stopServer();
        emit stopServer();
    }
    else
    {
        //curServer->startServer(QHostAddress::Any,portNumber);
        emit startServer(QHostAddress::Any,portNumber);
    }
}

void backend::onSendClicked(int listNumber)
{
    //curServer->sendDataTo(QString("Data send for %1").arg(listNumber),listNumber);
    emit sendDataTo(QString("Data send for %1").arg(listNumber),listNumber);
}
