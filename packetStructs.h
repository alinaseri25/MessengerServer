#ifndef PACKETSTRUCTS_H
#define PACKETSTRUCTS_H

#include <QObject>

#define MAX_JSON_SIZE       (64*1024)
#define MAX_PAYLOAD_SIZE    (10*1024*1024)

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

enum States{
    ok      = 0x01,
    nok
};

struct DataHeader{
    uint32_t    startBytes = 0xFEEFEFFE;
    uint32_t    jsonSize;
    uint32_t    payloadSize;
};

#endif // PACKETSTRUCTS_H
