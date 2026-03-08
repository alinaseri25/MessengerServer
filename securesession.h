#ifndef SECURESESSION_H
#define SECURESESSION_H

#include <QObject>
#include <QByteArray>

#include <openssl/evp.h>

class SecureSession : public QObject
{
    Q_OBJECT
public:
    explicit SecureSession(QObject *parent = nullptr);
    ~SecureSession() override;

    bool generateKeyPair();
    QByteArray publicKey() const;
    bool computeSharedSecret(const QByteArray& peerPublicKey);
    QByteArray sharedSecret() const;

private:
    void clear();

private:
    EVP_PKEY*  m_localKey = nullptr;
    QByteArray m_publicKey;
    QByteArray m_sharedSecret;
};

#endif // SECURESESSION_H
