#ifndef ENTITY_H
#define ENTITY_H

#include <QObject>

class Entity : public QObject
{
    Q_OBJECT
public:
    explicit Entity(QObject *parent = nullptr);

private:
    uint32_t entity_id;

signals:
    uint32_t requestWriteData(QJsonDocument *jsonDoc, QByteArray *payload);
};

#endif // ENTITY_H
