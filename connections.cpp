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

uint32_t Connections::writeData(QJsonDocument *jsonDoc, QByteArray *payload)
{
    QByteArray data,jsonByteArray = jsonDoc->toJson();
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
            qDebug() << QString("Start To Send");
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
    equipments.remove(_equipmentID);
}

void Connections::readyRead()
{
    connectionTimeout->start(connectionTime);
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

        // ── استخراج JSON ──────────────────────────────────────────────
        QByteArray jsonBytes = m_buffer.mid(sizeof(DataHeader), header->jsonSize);

        // ── استخراج Payload ───────────────────────────────────────────
        QByteArray payloadBytes;
        if (header->payloadSize > 0)
            payloadBytes = m_buffer.mid(sizeof(DataHeader) + header->jsonSize, header->payloadSize);

        // ── مصرف این پکت از بافر ─────────────────────────────────────
        m_buffer.remove(0, totalExpected);

        // ── پارس JSON ────────────────────────────────────────────────
        QJsonParseError parseError;
        QJsonDocument jsonDoc = QJsonDocument::fromJson(jsonBytes, &parseError);

        if (parseError.error != QJsonParseError::NoError) {
            qWarning() << "[ERROR] JSON parse failed:"
                       << parseError.errorString();
            qWarning() << "[ERROR] Raw JSON:" << jsonBytes;
            continue;
        }

        qDebug() << "[RX] JSON:" << jsonBytes;

        // ── dispatch بر اساس type ─────────────────────────────────────
        QJsonObject jsonObject = jsonDoc.object();
        if(jsonObject.value("type").toString("") == QString("handshake"))
        {
            Equipment *eqp = new Equipment(messengerDB,connectionTime,this);
            connect(eqp,&Equipment::requestWriteData,this,&Connections::writeData);
            if(eqp->processPacket(&jsonDoc,&payloadBytes))
            {
                equipments.insert(eqp->getEquipmentID(),eqp);
                qDebug() << QString("equipments size : %1 -- equipments last key : %2").arg(equipments.size()).arg(eqp->getEquipmentID());
            }
            else
            {
                qDebug() << QString("Error Happend - cannot add new equipments");
            }
        }
        else if(jsonObject.value("type").toString("") == QString("keepAlive"))
        {
            uint32_t _deviceId = jsonObject.value("deviceId").toInt(0);
            equipments.value(_deviceId)->processPacket(&jsonDoc,&payloadBytes);
        }

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
