//
//  c_awscrypto.h
//  AWSSDKSwiftCore
//
//  Created by Adam Fowler on 2019/08/08.
//

#ifndef C_AWSSDK_OPENSSL_H
#define C_AWSSDK_OPENSSL_H

#ifdef __linux__

#include <openssl/hmac.h>
#include <openssl/md5.h>
#include <openssl/sha.h>

HMAC_CTX *AWSCRYPTO_HMAC_CTX_new();
void AWSCRYPTO_HMAC_CTX_free(HMAC_CTX* ctx);

EVP_MD_CTX *AWSCRYPTO_EVP_MD_CTX_new(void);
void AWSCRYPTO_EVP_MD_CTX_free(EVP_MD_CTX *ctx);

#endif // __linux__

#endif // C_AWSSDK_OPENSSL_H
