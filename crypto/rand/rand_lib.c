/* crypto/rand/rand_lib.c */
/* Copyright (C) 1995-1998 Eric Young (eay@cryptsoft.com)
 * All rights reserved.
 *
 * This package is an SSL implementation written
 * by Eric Young (eay@cryptsoft.com).
 * The implementation was written so as to conform with Netscapes SSL.
 *
 * This library is free for commercial and non-commercial use as long as
 * the following conditions are aheared to.  The following conditions
 * apply to all code found in this distribution, be it the RC4, RSA,
 * lhash, DES, etc., code; not just the SSL code.  The SSL documentation
 * included with this distribution is covered by the same copyright terms
 * except that the holder is Tim Hudson (tjh@cryptsoft.com).
 *
 * Copyright remains Eric Young's, and as such any Copyright notices in
 * the code are not to be removed.
 * If this package is used in a product, Eric Young should be given attribution
 * as the author of the parts of the library used.
 * This can be in the form of a textual message at program startup or
 * in documentation (online or textual) provided with the package.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 * 1. Redistributions of source code must retain the copyright
 *    notice, this list of conditions and the following disclaimer.
 * 2. Redistributions in binary form must reproduce the above copyright
 *    notice, this list of conditions and the following disclaimer in the
 *    documentation and/or other materials provided with the distribution.
 * 3. All advertising materials mentioning features or use of this software
 *    must display the following acknowledgement:
 *    "This product includes cryptographic software written by
 *     Eric Young (eay@cryptsoft.com)"
 *    The word 'cryptographic' can be left out if the rouines from the library
 *    being used are not cryptographic related :-).
 * 4. If you include any Windows specific code (or a derivative thereof) from 
 *    the apps directory (application code) you must include an acknowledgement:
 *    "This product includes software written by Tim Hudson (tjh@cryptsoft.com)"
 *
 * THIS SOFTWARE IS PROVIDED BY ERIC YOUNG ``AS IS'' AND
 * ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
 * IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
 * ARE DISCLAIMED.  IN NO EVENT SHALL THE AUTHOR OR CONTRIBUTORS BE LIABLE
 * FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
 * DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS
 * OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
 * HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT
 * LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY
 * OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF
 * SUCH DAMAGE.
 *
 * The licence and distribution terms for any publically available version or
 * derivative of this code cannot be changed.  i.e. this code cannot simply be
 * copied and put under another distribution licence
 * [including the GNU Public Licence.]
 */

#include <stdio.h>
#include <time.h>
#include "cryptlib.h"
#include <openssl/rand.h>

#ifndef OPENSSL_NO_ENGINE
#include <openssl/engine.h>
#endif

#ifdef OPENSSL_FIPS
#include <openssl/fips.h>
#include <openssl/fips_rand.h>
#endif

#ifndef OPENSSL_NO_ENGINE
/* non-NULL if default_RAND_meth is ENGINE-provided */
static ENGINE *funct_ref =NULL;
#endif
static const RAND_METHOD *default_RAND_meth = NULL;

#define OPENSSL_HW_ASST 1

#if OPENSSL_HW_ASST
#include <tegra_se_secure.h>

#define HW_RNG_ALG	0x50000000
#define AES256_KEY_SIZE	32
#define AES_BLOCK_SIZE	16

uint8_t entropy_pool[AES256_KEY_SIZE];
uint8_t rand_bytes_buf[AES_BLOCK_SIZE];
uint64_t counter;
int rand_bytes_pos;

static const uint32_t ENTROPY_POOL_SIZE = sizeof(entropy_pool); // 32bytes
int hw_rng_operation(uint8_t *hwrng_buf, uint32_t len);
int aes_crypto_operation(uint8_t *out_buf, uint8_t *in_buf, uint32_t in_len, uint8_t *key);

int initialize_cprng();
#endif //OPENSSL_HW_ASST

int RAND_set_rand_method(const RAND_METHOD *meth)
	{
#ifndef OPENSSL_NO_ENGINE
	if(funct_ref)
		{
		ENGINE_finish(funct_ref);
		funct_ref = NULL;
		}
#endif
	default_RAND_meth = meth;
	return 1;
	}

const RAND_METHOD *RAND_get_rand_method(void)
	{
	if (!default_RAND_meth)
		{
#ifndef OPENSSL_NO_ENGINE
		ENGINE *e = ENGINE_get_default_RAND();
		if(e)
			{
			default_RAND_meth = ENGINE_get_RAND(e);
			if(!default_RAND_meth)
				{
				ENGINE_finish(e);
				e = NULL;
				}
			}
		if(e)
			funct_ref = e;
		else
#endif
			default_RAND_meth = RAND_SSLeay();
		}
	return default_RAND_meth;
	}

#ifndef OPENSSL_NO_ENGINE
int RAND_set_rand_engine(ENGINE *engine)
	{
	const RAND_METHOD *tmp_meth = NULL;
	if(engine)
		{
		if(!ENGINE_init(engine))
			return 0;
		tmp_meth = ENGINE_get_RAND(engine);
		if(!tmp_meth)
			{
			ENGINE_finish(engine);
			return 0;
			}
		}
	/* This function releases any prior ENGINE so call it first */
	RAND_set_rand_method(tmp_meth);
	funct_ref = engine;
	return 1;
	}
#endif

void RAND_cleanup(void)
	{
	const RAND_METHOD *meth = RAND_get_rand_method();
	if (meth && meth->cleanup)
		meth->cleanup();
	RAND_set_rand_method(NULL);
	}

void RAND_seed(const void *buf, int num)
	{
	const RAND_METHOD *meth = RAND_get_rand_method();
	if (meth && meth->seed)
		meth->seed(buf,num);
	}

void RAND_add(const void *buf, int num, double entropy)
	{
	const RAND_METHOD *meth = RAND_get_rand_method();
	if (meth && meth->add)
		meth->add(buf,num,entropy);
	}

int RAND_bytes(unsigned char *buf, int num)
	{
#if OPENSSL_HW_ASST
	return rand_bytes_hw_alt(buf, num);
#else
	const RAND_METHOD *meth = RAND_get_rand_method();
	if (meth && meth->bytes)
		return meth->bytes(buf,num);
	return(-1);
#endif
	}

int RAND_pseudo_bytes(unsigned char *buf, int num)
	{
	const RAND_METHOD *meth = RAND_get_rand_method();
	if (meth && meth->pseudorand)
		return meth->pseudorand(buf,num);
	return(-1);
	}

int RAND_status(void)
	{
	const RAND_METHOD *meth = RAND_get_rand_method();
	if (meth && meth->status)
		return meth->status();
	return 0;
	}

#ifdef OPENSSL_FIPS

/* FIPS DRBG initialisation code. This sets up the DRBG for use by the
 * rest of OpenSSL.
 */

/* Entropy gatherer: use standard OpenSSL PRNG to seed (this will gather
 * entropy internally through RAND_poll().
 */

static size_t drbg_get_entropy(DRBG_CTX *ctx, unsigned char **pout,
                                int entropy, size_t min_len, size_t max_len)
        {
	/* Round up request to multiple of block size */
	min_len = ((min_len + 19) / 20) * 20;
	*pout = OPENSSL_malloc(min_len);
	if (!*pout)
		return 0;
	if (RAND_SSLeay()->bytes(*pout, min_len) <= 0)
		{
		OPENSSL_free(*pout);
		*pout = NULL;
		return 0;
		}
        return min_len;
        }

static void drbg_free_entropy(DRBG_CTX *ctx, unsigned char *out, size_t olen)
	{
	if (out)
		{
		OPENSSL_cleanse(out, olen);
		OPENSSL_free(out);
		}
	}

/* Set "additional input" when generating random data. This uses the
 * current PID, a time value and a counter.
 */

static size_t drbg_get_adin(DRBG_CTX *ctx, unsigned char **pout)
    	{
	/* Use of static variables is OK as this happens under a lock */
	static unsigned char buf[16];
	static unsigned long counter;
	FIPS_get_timevec(buf, &counter);
	*pout = buf;
	return sizeof(buf);
	}

/* RAND_add() and RAND_seed() pass through to OpenSSL PRNG so it is 
 * correctly seeded by RAND_poll().
 */

static int drbg_rand_add(DRBG_CTX *ctx, const void *in, int inlen,
				double entropy)
	{
	RAND_SSLeay()->add(in, inlen, entropy);
	return 1;
	}

static int drbg_rand_seed(DRBG_CTX *ctx, const void *in, int inlen)
	{
	RAND_SSLeay()->seed(in, inlen);
	return 1;
	}

#ifndef OPENSSL_DRBG_DEFAULT_TYPE
#define OPENSSL_DRBG_DEFAULT_TYPE	NID_aes_256_ctr
#endif
#ifndef OPENSSL_DRBG_DEFAULT_FLAGS
#define OPENSSL_DRBG_DEFAULT_FLAGS	DRBG_FLAG_CTR_USE_DF
#endif 

static int fips_drbg_type = OPENSSL_DRBG_DEFAULT_TYPE;
static int fips_drbg_flags = OPENSSL_DRBG_DEFAULT_FLAGS;

void RAND_set_fips_drbg_type(int type, int flags)
	{
	fips_drbg_type = type;
	fips_drbg_flags = flags;
	}

int RAND_init_fips(void)
	{
	DRBG_CTX *dctx;
	size_t plen;
	unsigned char pers[32], *p;
#ifndef OPENSSL_ALLOW_DUAL_EC_DRBG
	if (fips_drbg_type >> 16)
		{
		RANDerr(RAND_F_RAND_INIT_FIPS, RAND_R_DUAL_EC_DRBG_DISABLED);
		return 0;
		}
#endif

	dctx = FIPS_get_default_drbg();
        if (FIPS_drbg_init(dctx, fips_drbg_type, fips_drbg_flags) <= 0)
		{
		RANDerr(RAND_F_RAND_INIT_FIPS, RAND_R_ERROR_INITIALISING_DRBG);
		return 0;
		}

        FIPS_drbg_set_callbacks(dctx,
				drbg_get_entropy, drbg_free_entropy, 20,
				drbg_get_entropy, drbg_free_entropy);
	FIPS_drbg_set_rand_callbacks(dctx, drbg_get_adin, 0,
					drbg_rand_seed, drbg_rand_add);
	/* Personalisation string: a string followed by date time vector */
	strcpy((char *)pers, "OpenSSL DRBG2.0");
	plen = drbg_get_adin(dctx, &p);
	memcpy(pers + 16, p, plen);

        if (FIPS_drbg_instantiate(dctx, pers, sizeof(pers)) <= 0)
		{
		RANDerr(RAND_F_RAND_INIT_FIPS, RAND_R_ERROR_INSTANTIATING_DRBG);
		return 0;
		}
        FIPS_rand_set_method(FIPS_drbg_method());
	return 1;
	}

#endif

#if OPENSSL_HW_ASST
int initialize_cprng(void)
{
	uint8_t hwrng_buf[AES256_KEY_SIZE];
	int result;

	// generate HW RNG here
	result = hw_rng_operation(hwrng_buf, AES256_KEY_SIZE);

	memcpy(entropy_pool, hwrng_buf, ENTROPY_POOL_SIZE);
	counter = 0;
	rand_bytes_pos = sizeof(rand_bytes_buf);
}

int rand_bytes_hw_alt(uint8_t *buf, size_t buflen)
{
	uint8_t counter_buf[AES_BLOCK_SIZE];
	int result = -1;

	while (buflen > 0) {
		if (rand_bytes_pos == sizeof(rand_bytes_buf)) {
			++counter;
			memset(counter_buf, 0, sizeof(counter_buf));
			memcpy(counter_buf, &counter, sizeof(counter));

			// do aes encrypt
			result = aes_crypto_operation(rand_bytes_buf, counter_buf,
					AES_BLOCK_SIZE, entropy_pool);
			rand_bytes_pos = 0;
		}

		while (rand_bytes_pos < sizeof(rand_bytes_buf) && buflen-- > 0) {
			*buf++ = rand_bytes_buf[rand_bytes_pos++];
		}
	}

	return result;
}

void add_entropy(uint8_t *entropy_buf, size_t entropy_buf_len)
{

	uint32_t i = 0;
	uint8_t new_pool[ENTROPY_POOL_SIZE];
	const uint32_t new_pool_size = sizeof(new_pool);

	RAND_bytes(new_pool, new_pool_size);
	memcpy(entropy_pool, new_pool, new_pool_size);
	for (i = 0; ((i < ENTROPY_POOL_SIZE) && (i < entropy_buf_len)); i++) {
		entropy_pool[i] ^= entropy_buf[i];
	}
}

int hw_rng_operation(uint8_t *hwrng_buf, uint32_t len)
{

	int result;
	te_securedriver_input_params_t param = {0};

	param.outbuf_ptr = hwrng_buf;
	param.out_len = len;
	param.algo_type = HW_RNG_ALG;

	result = te_securedriver_do_operation(&param);
	if (result) {
		printf("%s: RNG failure: 0x%x\n", __func__, result);
	}

	return result;
}

int aes_crypto_operation(uint8_t *out_buf, uint8_t *in_buf, uint32_t in_len, uint8_t *key)
{
	EVP_CIPHER_CTX ctx;
	unsigned char iv[EVP_MAX_IV_LENGTH];
	uint32_t out_len = in_len;

	memset(iv, 0, sizeof(EVP_CIPHER_CTX));

	EVP_CIPHER_CTX_init(&ctx);
	EVP_EncryptInit_ex(&ctx, EVP_aes_128_cbc(), NULL, key, iv);

	/* Encrypt session data */
	EVP_EncryptUpdate(&ctx, out_buf, &out_len, in_buf, in_len);
	EVP_EncryptFinal(&ctx, out_buf, &out_len);

	return 0;
}

#endif //OPENSSL_HW_ASST

