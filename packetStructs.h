#ifndef PACKETSTRUCTS_H
#define PACKETSTRUCTS_H

#include <QObject>

#define MAX_JSON_SIZE       (64*1024)
#define MAX_PAYLOAD_SIZE    (10*1024*1024)

#define jsonVersion         "00.00.02"
#define statByte            0xAA55AA55

enum EquipmentType{
    Other           = 0x01,
    Android         ,
    IOS             ,
    Desktop         ,
    Web             ,
    Stm32           ,
    ESP32
};

enum Errors{
    deviceExpired = 0x01,
    badLoginInput       ,
    userOrPassError     ,
    sessionMakerError   ,
    sessionExpired
};

enum MessageType{
    Request				= 0x01,
    Response			,
    ACK					,
    Handshake			,
    LoginResponse		,
    LoginRequest		,
    LogoutResponse		,
    LogoutRequest		,
    SessionResponse		,
    SessionRequest		,
    KeepAlive
};

enum States{
    ok      = 0x01,
    nok
};

struct DataHeader{
    uint32_t    startBytes = statByte;
    uint32_t    jsonSize;
    uint32_t    payloadSize;
    uint32_t    frameCRC;
};

#endif // PACKETSTRUCTS_H
