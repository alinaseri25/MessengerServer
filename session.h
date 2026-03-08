#ifndef SESSION_H
#define SESSION_H

#include <QObject>
#include "equipment.h"
#include "entity.h"

class Session : public QObject
{
    Q_OBJECT
public:
    explicit Session(QObject *parent = nullptr);

private:
    uint32_t session_id;
    Equipment *equipment = nullptr;
    Entity *entity = nullptr;

signals:
    uint32_t requestWriteData(QJsonDocument *jsonDoc, QByteArray *payload);
};

#endif // SESSION_H
