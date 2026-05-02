#include "server.h"

server::server(EntityModel *_entityModel, QObject *parent)
    : QObject{parent}
{
    entityModel = _entityModel;
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
    if (messengerDB.isOpen())
        messengerDB.close();
}

bool server::loadTlsCredentials(const QString &certPath, const QString &keyPath)
{

    if (!QFile::exists(certPath) || !QFile::exists(keyPath))
    {
        TlsCertificateGenerator::generate(
            certPath,
            keyPath,
            "messengerServer",
            {"192.168.1.100","5.57.34.52"},
            {"localhost"}
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

    if(!serverObj)
    {
        serverObj = new TlsTcpServer(this);
        connect(serverObj, &TlsTcpServer::descriptorReady,
                this, &server::handleIncomingDescriptor);
    }

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
    if(serverObj)
    {
        serverObj->close();
    }
    else
    {
        serverObj = new TlsTcpServer(this);
        connect(serverObj, &TlsTcpServer::descriptorReady,
                this, &server::handleIncomingDescriptor);
    }
    serverMsg = "Server Closed!";
    emit serverState(serverObj->isListening(), serverMsg, getSocketsCount(), dbState, dbMessege);
}

void server::getServerState()
{
    if(!serverObj)
    {
        serverObj = new TlsTcpServer(this);
        connect(serverObj, &TlsTcpServer::descriptorReady,
                this, &server::handleIncomingDescriptor);
    }
    emit serverState(serverObj->isListening(), serverMsg, getSocketsCount(), dbState, dbMessege);
}

qint64 server::getSocketsCount()
{
    return connectionsList.size();
}

bool server::createconnection()
{
    messengerDB = QSqlDatabase::addDatabase("QMYSQL", "myapp");

    messengerDB.setHostName("127.0.0.1");
    messengerDB.setUserName("root");
    messengerDB.setPassword("ABCabc.123$%^");
    messengerDB.setDatabaseName("messengerdb");
    messengerDB.setConnectOptions("MYSQL_OPT_RECONNECT=1");//CLIENT_MULTI_RESULTS=1;

    if (messengerDB.open()) {
        qDebug() << "DB Connection OK!";
        return true;
    }
    else {
        dbMessege = messengerDB.lastError().text();
        qDebug() << QString("DB Connection Fail: %1").arg(dbMessege);
        return false;
    }
}

void server::sendDataTo(QString data, quint64 listNumber)
{
    if (connectionsList.contains(listNumber))
    {
        if(connectionsList.value(listNumber) != nullptr)
        {
            connectionsList.value(listNumber)->sendTestData(data);
        }
    }
}

void server::loadEntitiesPage(int limit, int offset)
{
    if(entityModel == nullptr)
    {
        return;
    }
    lastLimit = limit;
    lastOffset = offset;
    QSqlQuery query(messengerDB);

    query.prepare("SELECT entity_id, entity_type, display_name, username, quick_meta, created_at, updated_at, is_active, is_deleted "
                  "FROM entities "
                  "ORDER BY created_at ASC "
                  "LIMIT :limit OFFSET :offset");

    query.bindValue(":limit", lastLimit);
    query.bindValue(":offset", lastOffset);

    if (!query.exec()) {
        return;
    }

    entityModel->clear();

    while(query.next())
    {
        EntityEnum e;

        e.entity_id = query.value("entity_id").toLongLong();
        e.entity_type = query.value("entity_type").toInt();
        e.display_name = query.value("display_name").toString();
        e.username = query.value("username").toString();

        QJsonDocument doc = QJsonDocument::fromJson(query.value("quick_meta").toByteArray());
        e.quick_meta = doc.object();

        e.created_at = query.value("created_at").toDateTime();
        e.updated_at = query.value("updated_at").toDateTime();
        e.is_active = query.value("is_active").toBool();
        e.is_deleted = query.value("is_deleted").toBool();

        entityModel->addEntity(e);   // IMPORTANT: append, not reset
    }
}

void server::onSetDeleted(int entityId, bool isDeleted)
{
    QSqlQuery query(messengerDB);

    query.prepare("UPDATE entities SET is_deleted = :isDeleted WHERE entity_id = :entityID");
    query.bindValue(":entityID",entityId);
    query.bindValue(":isDeleted",isDeleted);

    if (!query.exec()) {
        return;
    }

    loadEntitiesPage(lastLimit,lastOffset);
}

void server::onSetActivate(int entityId, bool isActive)
{
    QSqlQuery query(messengerDB);

    query.prepare("UPDATE entities SET is_active = :isActive WHERE entity_id = :entityID");
    query.bindValue(":entityID",entityId);
    query.bindValue(":isActive",isActive);

    if (!query.exec()) {
        return;
    }

    loadEntitiesPage(lastLimit,lastOffset);
}

void server::createNewUser(const QString &display, const QString &username, const QString &password)
{
    QSqlQuery query(messengerDB);

    query.prepare("INSERT INTO entities (entity_type, display_name, username, password_hash) VALUES ('user', :displayName, :username, :password);");
    query.bindValue(":displayName",display);
    query.bindValue(":username",username);
    query.bindValue(":password",hashPassword(password));

    if (!query.exec()) {
        return;
    }

    loadEntitiesPage(lastLimit,lastOffset);
}

void server::updateUser(int id, const QString &display, const QString &username, const QString &password)
{
    QSqlQuery query(messengerDB);

    query.prepare("UPDATE entities SET display_name = :displayName, username = :username, password_hash = :password WHERE entity_id = :entityId ");
    query.bindValue(":displayName",display);
    query.bindValue(":username",username);
    query.bindValue(":password",hashPassword(password));
    query.bindValue(":entityId",id);

    if (!query.exec()) {
        return;
    }

    loadEntitiesPage(lastLimit,lastOffset);
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
        sslSocket = nullptr;
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

                if(!serverObj)
                {
                    serverObj = new TlsTcpServer(this);
                    connect(serverObj, &TlsTcpServer::descriptorReady,
                            this, &server::handleIncomingDescriptor);
                }
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

QString server::hashPassword(const QString &password)
{
    QByteArray input = password.toUtf8();
    QByteArray hash = QCryptographicHash::hash(input, QCryptographicHash::Sha256);
    return QString(hash.toHex());
}

void server::disconnectedSocket(uint32_t connectionId)
{
    if (connectionsList.contains(connectionId)) {
        if(connectionsList.value(connectionId) != nullptr)
        {
            connectionsList.value(connectionId)->deleteLater();
        }
        connectionsList.remove(connectionId);
    }

    if(!serverObj)
    {
        serverObj = new TlsTcpServer(this);
        connect(serverObj, &TlsTcpServer::descriptorReady,
                this, &server::handleIncomingDescriptor);
    }
    emit serverState(serverObj->isListening(),
                     serverMsg,
                     getSocketsCount(),
                     dbState,
                     dbMessege);
}
