#ifndef TLSCERTIFICATEGENERATOR_H
#define TLSCERTIFICATEGENERATOR_H

#pragma once

#include <QObject>

class TlsCertificateGenerator : public QObject
{
    Q_OBJECT
public:
    explicit TlsCertificateGenerator(QObject *parent = nullptr);
    static bool generate(const QString& certFile,
                         const QString& keyFile,
                         const QString& commonName = "localhost",
                         int daysValid = 365);

signals:
};

#endif // TLSCERTIFICATEGENERATOR_H
