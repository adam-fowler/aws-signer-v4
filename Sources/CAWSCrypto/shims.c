//
//  shims.c
//  AWSSDKSwiftCore
//
//  Created by Adam Fowler on 2019/08/08.
//

#ifdef __linux__

// These are functions that shim over differences in different OpenSSL versions,
// which are best handled by using the C preprocessor.
#include "c_awscrypto.h"
#include <string.h>

HMAC_CTX *AWSCRYPTO_HMAC_CTX_new() {
#if OPENSSL_VERSION_NUMBER < 0x10100000L || (defined(LIBRESSL_VERSION_NUMBER) && LIBRESSL_VERSION_NUMBER < 0x2070000fL)
    HMAC_CTX *ctx = OPENSSL_malloc(sizeof(HMAC_CTX));
    if (ctx != NULL) {
        HMAC_CTX_init(ctx);
    }
    return ctx;
#else
    return HMAC_CTX_new();
#endif
}

void AWSCRYPTO_HMAC_CTX_free(HMAC_CTX* ctx) {
#if OPENSSL_VERSION_NUMBER < 0x10100000L || (defined(LIBRESSL_VERSION_NUMBER) && LIBRESSL_VERSION_NUMBER < 0x2070000fL)
    if (ctx != NULL) {
        HMAC_CTX_cleanup(ctx);
        OPENSSL_free(ctx);
    }
#else
    HMAC_CTX_free(ctx);
#endif
}

EVP_MD_CTX *AWSCRYPTO_EVP_MD_CTX_new(void) {
#if OPENSSL_VERSION_NUMBER < 0x10100000L || (defined(LIBRESSL_VERSION_NUMBER) && LIBRESSL_VERSION_NUMBER < 0x2070000fL)
    return EVP_MD_CTX_create();
#else
    return EVP_MD_CTX_new();
#endif
}

void AWSCRYPTO_EVP_MD_CTX_free(EVP_MD_CTX *ctx) {
#if OPENSSL_VERSION_NUMBER < 0x10100000L || (defined(LIBRESSL_VERSION_NUMBER) && LIBRESSL_VERSION_NUMBER < 0x2070000fL)
    if (ctx != NULL) {
        EVP_MD_CTX_destroy(ctx);
    }
#else
    EVP_MD_CTX_free(ctx);
#endif
}

#endif // __linux__
