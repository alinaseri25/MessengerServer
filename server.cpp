#include "server.h"

server::server(QObject *parent)
    : QObject{parent}
{
    qDebug() << QCoreApplication::libraryPaths();
    qDebug() << QSqlDatabase::drivers();

    serverObj = new TlsTcpServer(this);
    connect(serverObj, &TlsTcpServer::descriptorReady,
            this, &server::handleIncomingDescriptor);

    listNumber = 1;
    serverMsg = QString("Server Closed!");

    dbState = createconnection();
    if (dbState)
        qDebug() << "Server DB connection success.";
    else
        qDebug() << "Server cannot start DB.";

    tlsEnabled = loadTlsCredentials("server.crt", "server.key");
    if (!tlsEnabled)
        qWarning() << "TLS credentials not loaded. TLS connections will be rejected.";

    emit serverState(serverObj->isListening(), serverMsg, getSocketsCount(), dbState, dbMessege);
}

server::~server()
{
    if (messengerDB)
        messengerDB->close();
}

bool server::loadTlsCredentials(const QString &certPath, const QString &keyPath)
{

    if (!QFile::exists("server.crt") || !QFile::exists("server.key"))
    {
        TlsCertificateGenerator::generate(
            "server.crt",
            "server.key",
            "192.168.1.100"
            );
    }

    QFile certFile(certPath);
    if (!certFile.open(QIODevice::ReadOnly)) {
        qWarning() << "Cannot open certificate:" << certPath;
        return false;
    }

    QFile keyFile(keyPath);
    if (!keyFile.open(QIODevice::ReadOnly)) {
        qWarning() << "Cannot open private key:" << keyPath;
        return false;
    }

    serverCert = QSslCertificate(certFile.readAll(), QSsl::Pem);
    serverKey = QSslKey(keyFile.readAll(), QSsl::Rsa, QSsl::Pem);

    if (serverCert.isNull()) {
        qWarning() << "Invalid TLS certificate.";
        return false;
    }

    if (serverKey.isNull()) {
        qWarning() << "Invalid TLS private key.";
        return false;
    }

    qDebug() << "TLS credentials loaded successfully.";
    return true;
}

void server::startServer(QHostAddress _address, quint16 _port)
{
    serverMsg = "";

    if (!tlsEnabled) {
        serverMsg = "TLS credentials missing. Server start aborted.";
        qWarning() << serverMsg;
        emit serverState(false, serverMsg, getSocketsCount(), dbState, dbMessege);
        return;
    }

    if (!dbState) {
        dbState = createconnection();
        if (dbState)
            qDebug() << "Server DB connection success.";
        else
            qDebug() << "Server cannot start DB.";
    }

    listenAddress = _address;
    portNumber = _port;

    if (!serverObj->listen(listenAddress, portNumber)) {
        serverMsg = QString("Listen failed: %1").arg(serverObj->errorString());
        qWarning() << serverMsg;
        emit serverState(false, serverMsg, getSocketsCount(), dbState, dbMessege);
        return;
    }

    foreach (const QHostAddress &address, QNetworkInterface::allAddresses()) {
        if (address.protocol() == QAbstractSocket::IPv4Protocol &&
            address != QHostAddress::LocalHost)
        {
            qDebug() << "TLS Server reachable at:" << address.toString()
            << ":" << serverObj->serverPort();

            serverMsg.append(
                QString("TLS Server reachable at: %1 : %2\r\n")
                    .arg(address.toString())
                    .arg(serverObj->serverPort()));
        }
    }

    emit serverState(serverObj->isListening(), serverMsg, getSocketsCount(), dbState, dbMessege);
}

void server::stopServer()
{
    serverObj->close();
    serverMsg = "Server Closed!";
    emit serverState(serverObj->isListening(), serverMsg, getSocketsCount(), dbState, dbMessege);
}

void server::getServerState()
{
    emit serverState(serverObj->isListening(), serverMsg, getSocketsCount(), dbState, dbMessege);
}

qint64 server::getSocketsCount()
{
    return connectionsList.size();
}

bool server::createconnection()
{
    messengerDB = new QSqlDatabase();
    *messengerDB = QSqlDatabase::addDatabase("QMYSQL", "myapp");

    messengerDB->setHostName("127.0.0.1");
    messengerDB->setUserName("root");
    messengerDB->setPassword("ABCabc.123$%^");
    messengerDB->setDatabaseName("messengerdb");
    messengerDB->setConnectOptions("CLIENT_MULTI_RESULTS=1;MYSQL_OPT_RECONNECT=1");

    if (messengerDB->open()) {
        qDebug() << "DB Connection OK!";
        return true;
    }
    else {
        dbMessege = messengerDB->lastError().text();
        qDebug() << QString("DB Connection Fail: %1").arg(dbMessege);
        return false;
    }
}

void server::sendDataTo(QString data, quint64 listNumber)
{
    if (connectionsList.contains(listNumber))
        connectionsList.value(listNumber)->sendTestData(data);
}

void server::handleIncomingDescriptor(qintptr socketDescriptor)
{
    if (!tlsEnabled) {
        qWarning() << "TLS required but credentials missing. Rejecting connection.";
        QTcpSocket tempSocket;
        if (tempSocket.setSocketDescriptor(socketDescriptor))
            tempSocket.disconnectFromHost();
        return;
    }

    QSslSocket *sslSocket = new QSslSocket(this);

    if (!sslSocket->setSocketDescriptor(socketDescriptor)) {
        qWarning() << "Failed to adopt socket descriptor:" << sslSocket->errorString();
        sslSocket->deleteLater();
        return;
    }

    QSslConfiguration sslConfig = QSslConfiguration::defaultConfiguration();
    sslConfig.setLocalCertificate(serverCert);
    sslConfig.setPrivateKey(serverKey);
    sslConfig.setPeerVerifyMode(QSslSocket::VerifyNone);
    sslConfig.setProtocol(QSsl::TlsV1_2OrLater);

    sslSocket->setSslConfiguration(sslConfig);

    quint64 newId = listNumber;
    while (connectionsList.contains(newId))
        newId++;

    listNumber = newId + 1;

    connect(sslSocket, &QSslSocket::encrypted, this,
            [this, sslSocket, newId]()
            {
                qDebug() << "TLS session established. Connection ID:" << newId;

                Connections *con = new Connections(sslSocket, newId, messengerDB, this);

                connect(con, &Connections::connectionDisconnected,
                        this, &server::disconnectedSocket);

                connectionsList.insert(newId, con);

                emit serverState(serverObj->isListening(),
                                 serverMsg,
                                 getSocketsCount(),
                                 dbState,
                                 dbMessege);
            });

    connect(sslSocket,
            qOverload<const QList<QSslError>&>(&QSslSocket::sslErrors),
            this,
            [sslSocket](const QList<QSslError> &errors)
            {
                qWarning() << "TLS errors:" << errors;
                sslSocket->disconnectFromHost();
            });

    connect(sslSocket,
            qOverload<QAbstractSocket::SocketError>(&QSslSocket::errorOccurred),
            this,
            [sslSocket](QAbstractSocket::SocketError)
            {
                qWarning() << "Socket error:" << sslSocket->errorString();
            });

    connect(sslSocket, &QSslSocket::disconnected,
            sslSocket, &QSslSocket::deleteLater);

    sslSocket->startServerEncryption();
}

void server::disconnectedSocket(uint32_t connectionId)
{
    if (connectionsList.contains(connectionId)) {
        connectionsList.remove(connectionId);
    }

    emit serverState(serverObj->isListening(),
                     serverMsg,
                     getSocketsCount(),
                     dbState,
                     dbMessege);
}
