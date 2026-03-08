#include "securesession.h"

#include <openssl/core_names.h>
#include <openssl/param_build.h>
#include <openssl/ec.h>

SecureSession::SecureSession(QObject *parent)
    : QObject(parent)
{
}

SecureSession::~SecureSession()
{
    clear();
}

void SecureSession::clear()
{
    if (m_localKey) {
        EVP_PKEY_free(m_localKey);
        m_localKey = nullptr;
    }

    m_publicKey.clear();
    m_sharedSecret.clear();
}

bool SecureSession::generateKeyPair()
{
    clear();

    EVP_PKEY_CTX* genCtx = EVP_PKEY_CTX_new_from_name(nullptr, "EC", nullptr);
    if (!genCtx) {
        return false;
    }

    bool ok = false;

    do {
        if (EVP_PKEY_keygen_init(genCtx) <= 0) {
            break;
        }

        if (EVP_PKEY_CTX_set_group_name(genCtx, "prime256v1") <= 0) {
            break;
        }

        if (EVP_PKEY_generate(genCtx, &m_localKey) <= 0) {
            break;
        }

        size_t pubLen = 0;
        if (EVP_PKEY_get_octet_string_param(
                m_localKey,
                OSSL_PKEY_PARAM_PUB_KEY,
                nullptr,
                0,
                &pubLen) <= 0) {
            break;
        }

        m_publicKey.resize(static_cast<int>(pubLen));

        if (EVP_PKEY_get_octet_string_param(
                m_localKey,
                OSSL_PKEY_PARAM_PUB_KEY,
                reinterpret_cast<unsigned char*>(m_publicKey.data()),
                pubLen,
                &pubLen) <= 0) {
            m_publicKey.clear();
            break;
        }

        m_publicKey.resize(static_cast<int>(pubLen));
        ok = true;
    } while (false);

    EVP_PKEY_CTX_free(genCtx);

    if (!ok) {
        clear();
    }

    return ok;
}

QByteArray SecureSession::publicKey() const
{
    return m_publicKey;
}

bool SecureSession::computeSharedSecret(const QByteArray& peerPublicKey)
{
    if (!m_localKey || peerPublicKey.isEmpty()) {
        return false;
    }

    EVP_PKEY* peerKey = nullptr;
    EVP_PKEY_CTX* fromDataCtx = nullptr;
    EVP_PKEY_CTX* deriveCtx = nullptr;
    OSSL_PARAM_BLD* paramBld = nullptr;
    OSSL_PARAM* params = nullptr;

    bool ok = false;

    do {
        paramBld = OSSL_PARAM_BLD_new();
        if (!paramBld) {
            break;
        }

        if (OSSL_PARAM_BLD_push_utf8_string(
                paramBld,
                OSSL_PKEY_PARAM_GROUP_NAME,
                "prime256v1",
                0) <= 0) {
            break;
        }

        if (OSSL_PARAM_BLD_push_octet_string(
                paramBld,
                OSSL_PKEY_PARAM_PUB_KEY,
                peerPublicKey.constData(),
                static_cast<size_t>(peerPublicKey.size())) <= 0) {
            break;
        }

        params = OSSL_PARAM_BLD_to_param(paramBld);
        if (!params) {
            break;
        }

        fromDataCtx = EVP_PKEY_CTX_new_from_name(nullptr, "EC", nullptr);
        if (!fromDataCtx) {
            break;
        }

        if (EVP_PKEY_fromdata_init(fromDataCtx) <= 0) {
            break;
        }

        if (EVP_PKEY_fromdata(fromDataCtx, &peerKey, EVP_PKEY_PUBLIC_KEY, params) <= 0) {
            break;
        }

        deriveCtx = EVP_PKEY_CTX_new(m_localKey, nullptr);
        if (!deriveCtx) {
            break;
        }

        if (EVP_PKEY_derive_init(deriveCtx) <= 0) {
            break;
        }

        if (EVP_PKEY_derive_set_peer(deriveCtx, peerKey) <= 0) {
            break;
        }

        size_t secretLen = 0;
        if (EVP_PKEY_derive(deriveCtx, nullptr, &secretLen) <= 0) {
            break;
        }

        m_sharedSecret.resize(static_cast<int>(secretLen));

        if (EVP_PKEY_derive(
                deriveCtx,
                reinterpret_cast<unsigned char*>(m_sharedSecret.data()),
                &secretLen) <= 0) {
            m_sharedSecret.clear();
            break;
        }

        m_sharedSecret.resize(static_cast<int>(secretLen));
        ok = true;
    } while (false);

    if (params) {
        OSSL_PARAM_free(params);
    }

    if (paramBld) {
        OSSL_PARAM_BLD_free(paramBld);
    }

    if (deriveCtx) {
        EVP_PKEY_CTX_free(deriveCtx);
    }

    if (fromDataCtx) {
        EVP_PKEY_CTX_free(fromDataCtx);
    }

    if (peerKey) {
        EVP_PKEY_free(peerKey);
    }

    if (!ok) {
        m_sharedSecret.clear();
    }

    return ok;
}

QByteArray SecureSession::sharedSecret() const
{
    return m_sharedSecret;
}
