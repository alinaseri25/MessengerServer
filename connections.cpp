#include "connections.h"

Connections::Connections(QSslSocket *_tcpSocket, quint64 _socketId, QSqlDatabase *_messengerDB, QObject *parent)
    : QObject{parent}
{
    tcpSocket = _tcpSocket;
    socketId = _socketId;
    messengerDB = _messengerDB;

    connect(tcpSocket,&QSslSocket::readyRead,this,&Connections::readyRead);
    connect(tcpSocket,&QSslSocket::disconnected,this,&Connections::disconnectedSocket);
    connect(tcpSocket,&QSslSocket::errorOccurred,this,&Connections::errorOccurred);
    connect(tcpSocket,&QSslSocket::bytesWritten,this,&Connections::onBytesWrited);

    queueTimer = new QTimer(this);
    connect(queueTimer,&QTimer::timeout,this,&Connections::onQueueTimerTimeout);
    queueTimer->setInterval(2);
    queueTimer->start();

    connectionTimeout = new QTimer(this);
    connect(connectionTimeout,&QTimer::timeout,this,&Connections::onConnectionTimeout);
    connectionTimeout->setInterval(connectionTime);
    connectionTimeout->start();

    sendTimeout = new QTimer(this);
    connect(sendTimeout,&QTimer::timeout,this,&Connections::onSendTimeout);
    sendTimeout->stop();

    inputProcess = new QTimer(this);
    connect(inputProcess,&QTimer::timeout,this,&Connections::inputProcessTimeout);
    inputProcess->setInterval(1);
    inputProcess->start();

    sendTestData(QString("Socket ID : %1").arg(socketId));
}

Connections::~Connections()
{
    foreach (Equipment *eqp, equipments.values()) {
        eqp->disconnectEquipment();
    }

    if(tcpSocket->isOpen())
    {
        tcpSocket->close();
    }
    tcpSocket->deleteLater();
}

uint32_t Connections::sendTestData(QString Data)
{
    QJsonObject *tempObject = new QJsonObject();
    tempObject->insert("type","RAW Data");
    tempObject->insert("value",Data);
    tempObject->insert("jsonVersion","00.00.01");
    QJsonDocument *doc = new QJsonDocument(*tempObject);
    return writeData(doc);
}

QString Connections::generateSessionToken()
{
    QByteArray randomBytes(32, Qt::Uninitialized);
    QRandomGenerator::securelySeeded().fillRange(
        reinterpret_cast<quint32*>(randomBytes.data()), 8
        );
    return QString::fromLatin1(
        QCryptographicHash::hash(randomBytes, QCryptographicHash::Sha256).toHex()
        );
}

bool Connections::logingIn(QJsonDocument *jsonDoc, QByteArray *payload)
{
    QJsonObject jsonObject = jsonDoc->object();
    QJsonObject responseObject;
    responseObject.insert(QString("type"),QString("loginResponse"));
    uint32_t _deviceId = jsonObject.value(QString("deviceId")).toInt(0);
    if(!equipments.contains(_deviceId))
    {
        responseObject.insert(QString("status"),States::nok);
        responseObject.insert(QString("error"),Errors::deviceExpired);
        QJsonDocument *responseDocument = new QJsonDocument(responseObject);
        writeData(responseDocument);
        return false;
    }
    else
    {
        QString username = jsonObject.value(QString("username")).toString("");
        QString hashedPassword = jsonObject.value(QString("password")).toString("");

        Entity *entity = new Entity(username,messengerDB);
        connect(entity,&Entity::requestWriteData,this,&Connections::writeData);

        if(!entity->loginEntity(hashedPassword))
        {
            entity->deleteLater();
            return false;
        }

        QString userAgent = jsonObject.value(QString("userAgent")).toString("TestAgent");

        Session *session = new Session(messengerDB,entity,equipments.value(_deviceId),tcpSocket->peerAddress().toString(),userAgent,this);
        if(session->loginSession())
        {
            if(sessions.contains(session->getSessionId()))
            {
                sessions.value(session->getSessionId())->deleteLater();
                sessions.remove(session->getSessionId());
            }
            sessions.insert(session->getSessionId(),session);
            responseObject.insert(QString("status"),States::ok);
            responseObject.insert(QString("sessionId"),(qint32)(session->getSessionId()));
            responseObject.insert(QString("entityId"),(qint32)(session->getEntity()->getEntityId()));
            responseObject.insert(QString("sessionTocken"),session->getSessionToken());
            responseObject.insert(QString("displayName"),session->getEntity()->getDisplayName());
            responseObject.insert(QString("username"),session->getEntity()->getUsername());
            QJsonDocument *responseDocument = new QJsonDocument(responseObject);
            writeData(responseDocument);
        }
        else
        {
            session->deleteLater();
        }
    }
    return true;
}

bool Connections::sessionRequest(QJsonDocument *jsonDoc, QByteArray *payload)
{
    QJsonObject jsonObject = jsonDoc->object();
    QJsonObject responseObject;
    responseObject.insert(QString("type"),QString("sessionResponse"));
    uint32_t _deviceId = jsonObject.value(QString("deviceId")).toInt(0);
    if(!equipments.contains(_deviceId))
    {
        responseObject.insert(QString("status"),States::nok);
        responseObject.insert(QString("error"),Errors::deviceExpired);
        QJsonDocument *responseDocument = new QJsonDocument(responseObject);
        writeData(responseDocument);
        return false;
    }
    QString username = QString("");
    Entity *entity = new Entity(username,messengerDB);
    connect(entity,&Entity::requestWriteData,this,&Connections::writeData);

    uint32_t entityId = jsonObject.value(QString("entityId")).toInt(0);

    if(!entity->checkExist(entityId))
    {
        entity->deleteLater();
        return false;
    }

    QString userAgent = jsonObject.value(QString("userAgent")).toString("TestAgent");

    Session *session = new Session(messengerDB,entity,equipments.value(_deviceId),tcpSocket->peerAddress().toString(),userAgent,this);
    uint32_t sessionId = jsonObject.value(QString("sessionId")).toInt(0);
    QString sessionTocken = jsonObject.value(QString("sessionTocken")).toString("");
    if(session->checkSession(sessionId,sessionTocken))
    {
        if(sessions.contains(session->getSessionId()))
        {
            sessions.value(session->getSessionId())->deleteLater();
            sessions.remove(session->getSessionId());
        }
        sessions.insert(session->getSessionId(),session);
        responseObject.insert(QString("status"),States::ok);
        responseObject.insert(QString("sessionId"),(qint32)(session->getSessionId()));
        responseObject.insert(QString("entityId"),(qint32)(session->getEntity()->getEntityId()));
        responseObject.insert(QString("sessionTocken"),session->getSessionToken());
        responseObject.insert(QString("displayName"),session->getEntity()->getDisplayName());
        responseObject.insert(QString("username"),session->getEntity()->getUsername());
        QJsonDocument *responseDocument = new QJsonDocument(responseObject);
        writeData(responseDocument);
    }
    else
    {
        session->deleteLater();
    }

    return true;
}

uint32_t Connections::writeData(QJsonDocument *jsonDoc, QByteArray *payload)
{
    QByteArray data,jsonByteArray = jsonDoc->toJson(QJsonDocument::Compact);
    delete jsonDoc;
    DataHeader dataHeader;
    dataHeader.jsonSize = jsonByteArray.size();
    if(payload != nullptr)
    {
        dataHeader.payloadSize = payload->size();
    }
    else
    {
        dataHeader.payloadSize = 0;
    }
    data.append((char *)&dataHeader,sizeof(DataHeader));
    data.append(jsonByteArray);
    if(payload != nullptr)
    {
        data.append(*payload);
        delete payload;
    }
    sendQueue.append(data);
    queueTimer->start();
    return data.size();
}

void Connections::onQueueTimerTimeout()
{
    if(sendQueue.size() > 0)
    {
        if(tcpSocket != nullptr)
        {
            // qDebug() << QString("Start To Send");
            tcpSocket->write(sendQueue.at(0));
            queueTimer->stop();
            sendTimeout->start(1000);
        }
    }
}

void Connections::onConnectionTimeout()
{
    qDebug() << QString("Connection Time Over");
    tcpSocket->disconnect();
    tcpSocket->close();
    emit connectionDisconnected(socketId);
}

void Connections::onSendTimeout()
{
    qDebug() << QString("Timeout");
    sendTimeout->stop();
    queueTimer->start();
}

void Connections::onBytesWrited(qint64 _bytes)
{
    qDebug() << QString("Bytes Wirted : %1 - sendQueue.at(0).size() : %2").arg(_bytes).arg(sendQueue.at(0).size());
    if(sendQueue.size() > 0)
    {
        if(_bytes == sendQueue.at(0).size())
        {
            sendQueue.removeAt(0);
            sendTimeout->stop();
            queueTimer->start();
        }
    }
}

void Connections::onEquipmentDisconnected(uint32_t _equipmentID)
{
    if(equipments.contains(_equipmentID))
    {
        equipments.remove(_equipmentID);
    }
}

void Connections::inputProcessTimeout()
{
    if(inputBuffers.size() == 0)
    {
        return;
    }
    inputProcess->stop();
    const DataHeader *header = (DataHeader *)(inputBuffers.at(0).constData());

    // ── استخراج JSON ──────────────────────────────────────────────
    QByteArray jsonBytes = inputBuffers.at(0).mid(sizeof(DataHeader), header->jsonSize);

    // ── استخراج Payload ───────────────────────────────────────────
    QByteArray payloadBytes;
    if (header->payloadSize > 0)
        payloadBytes = inputBuffers.at(0).mid(sizeof(DataHeader) + header->jsonSize, header->payloadSize);


    // ── پارس JSON ────────────────────────────────────────────────
    QJsonParseError parseError;
    QJsonDocument jsonDoc = QJsonDocument::fromJson(jsonBytes, &parseError);

    if (parseError.error != QJsonParseError::NoError) {
        qWarning() << "[ERROR] JSON parse failed:"
                   << parseError.errorString();
        qWarning() << "[ERROR] Raw JSON:" << jsonBytes;
        inputBuffers.remove(0);
        inputProcess->start();
        return;
    }

    qDebug() << "[RX] JSON:" << jsonBytes;
    connectionTimeout->start(connectionTime);

    // ── dispatch بر اساس type ─────────────────────────────────────
    QJsonObject jsonObject = jsonDoc.object();
    QString commandType = jsonObject.value("type").toString("");
    if(commandType == QString("handshake"))
    {
        Equipment *eqp = new Equipment(messengerDB,connectionTime,this);
        connect(eqp,&Equipment::requestWriteData,this,&Connections::writeData);
        if(eqp->handShake(&jsonDoc,&payloadBytes))
        {
            if(equipments.contains(eqp->getEquipmentID()))
            {
                equipments.value(eqp->getEquipmentID())->deleteLater();
                equipments.remove(eqp->getEquipmentID());
            }
            equipments.insert(eqp->getEquipmentID(),eqp);
        }
        else
        {
            qDebug() << QString("Error Happend - cannot add new equipments");
        }
    }
    else if(commandType == QString("keepAlive"))
    {
        uint32_t _deviceId = jsonObject.value("deviceId").toInt(0);
        if(equipments.contains(_deviceId))
        {
            equipments.value(_deviceId)->keepAlive(&jsonDoc,&payloadBytes);
        }
    }
    else if(commandType == QString("loginRequest"))
    {
        logingIn(&jsonDoc,&payloadBytes);
    }
    else if(commandType == QString("sessionRequest"))
    {
        sessionRequest(&jsonDoc,&payloadBytes);
    }

    inputBuffers.remove(0);
    inputProcess->start();
}

void Connections::onSessionTerminated(uint32_t _sessionId)
{
    if(sessions.contains(_sessionId))
    {
        sessions.remove(_sessionId);
    }
}

void Connections::readyRead()
{
    // ── داده جدید رو به بافر اضافه کن ────────────────────────────────
    m_buffer.append(tcpSocket->readAll());

    // ── تا زمانی که پکت کامل داریم پردازش کن ───────────────────────
    while (true)
    {
        // بررسی کافی بودن داده برای خواندن هدر
        if (m_buffer.size() < (int)sizeof(DataHeader))
            break;

        // ── خواندن هدر ───────────────────────────────────────────────
        const DataHeader *header = (DataHeader *)(m_buffer.constData());

        qDebug() << QString("[RX] jsonSize=%1 payloadSize=%2")
                        .arg(header->jsonSize).arg(header->payloadSize);

        // ── validation ────────────────────────────────────────────────
        if (header->jsonSize == 0 || header->jsonSize > MAX_JSON_SIZE) {
            qWarning() << "[ERROR] Invalid jsonSize:" << header->jsonSize;
            m_buffer.clear();   // بافر رو پاک کن، sync از دست رفته
            break;
        }
        if (header->payloadSize > MAX_PAYLOAD_SIZE) {
            qWarning() << "[ERROR] Invalid payloadSize:" << header->payloadSize;
            m_buffer.clear();
            break;
        }

        // ── بررسی کامل بودن پکت ──────────────────────────────────────
        int totalExpected = (int)(sizeof(DataHeader) + header->jsonSize + header->payloadSize);
        if (m_buffer.size() < totalExpected)
            break;

        inputBuffers.append(m_buffer);
        if(inputBuffers.size() > 100)
        {
            qDebug() << QString("Connection buffer over flow!");
            emit connectionDisconnected(socketId);
        }

        // ── مصرف این پکت از بافر ─────────────────────────────────────
        m_buffer.remove(0, totalExpected);

        return;
    }
}

void Connections::disconnectedSocket()
{
    emit connectionDisconnected(socketId);
}

void Connections::errorOccurred(QAbstractSocket::SocketError socketError)
{
    qDebug() << QString("Error : %1").arg(tcpSocket->errorString());
}
