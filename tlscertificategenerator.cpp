#include "tlscertificategenerator.h"

#include <openssl/evp.h>
#include <openssl/pem.h>
#include <openssl/x509.h>
#include <openssl/x509v3.h>

TlsCertificateGenerator::TlsCertificateGenerator(QObject *parent)
    : QObject{parent}
{}

bool TlsCertificateGenerator::generate(const QString& certFile,
                                       const QString& keyFile,
                                       const QString& commonName,
                                       int daysValid)
{
    EVP_PKEY* pkey = nullptr;
    X509* cert = nullptr;

    bool ok = false;

    do
    {
        // -----------------------------
        // Generate RSA key
        // -----------------------------
        EVP_PKEY_CTX* ctx = EVP_PKEY_CTX_new_from_name(nullptr, "RSA", nullptr);
        if (!ctx) break;

        if (EVP_PKEY_keygen_init(ctx) <= 0) break;
        if (EVP_PKEY_CTX_set_rsa_keygen_bits(ctx, 2048) <= 0) break;

        if (EVP_PKEY_keygen(ctx, &pkey) <= 0)
        {
            EVP_PKEY_CTX_free(ctx);
            break;
        }

        EVP_PKEY_CTX_free(ctx);

        // -----------------------------
        // Create certificate
        // -----------------------------
        cert = X509_new();
        if (!cert) break;

        X509_set_version(cert, 2);
        ASN1_INTEGER_set(X509_get_serialNumber(cert), 1);

        X509_gmtime_adj(X509_get_notBefore(cert), 0);
        X509_gmtime_adj(X509_get_notAfter(cert), 60L * 60 * 24 * daysValid);

        X509_set_pubkey(cert, pkey);

        // -----------------------------
        // Subject / Issuer
        // -----------------------------
        X509_NAME* name = X509_get_subject_name(cert);

        X509_NAME_add_entry_by_txt(
            name,
            "CN",
            MBSTRING_ASC,
            (unsigned char*)commonName.toStdString().c_str(),
            -1,
            -1,
            0);

        X509_set_issuer_name(cert, name);

        // -----------------------------
        // Sign certificate
        // -----------------------------
        if (!X509_sign(cert, pkey, EVP_sha256()))
            break;

        // -----------------------------
        // Write private key
        // -----------------------------
        FILE* keyFileFp = fopen(keyFile.toStdString().c_str(), "wb");
        if (!keyFileFp) break;

        PEM_write_PrivateKey(
            keyFileFp,
            pkey,
            nullptr,
            nullptr,
            0,
            nullptr,
            nullptr);

        fclose(keyFileFp);

        // -----------------------------
        // Write certificate
        // -----------------------------
        FILE* certFileFp = fopen(certFile.toStdString().c_str(), "wb");
        if (!certFileFp) break;

        PEM_write_X509(certFileFp, cert);

        fclose(certFileFp);

        ok = true;

    } while (false);

    if (cert) X509_free(cert);
    if (pkey) EVP_PKEY_free(pkey);

    return ok;
}
