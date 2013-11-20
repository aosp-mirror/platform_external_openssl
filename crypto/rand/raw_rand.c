/* ====================================================================
 * Copyright (c) 2013 The OpenSSL Project.  All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 *
 * 1. Redistributions of source code must retain the above copyright
 *    notice, this list of conditions and the following disclaimer.
 *
 * 2. Redistributions in binary form must reproduce the above copyright
 *    notice, this list of conditions and the following disclaimer in
 *    the documentation and/or other materials provided with the
 *    distribution.
 *
 * 3. All advertising materials mentioning features or use of this
 *    software must display the following acknowledgment:
 *    "This product includes software developed by the OpenSSL Project
 *    for use in the OpenSSL Toolkit. (http://www.OpenSSL.org/)"
 *
 * 4. The names "OpenSSL Toolkit" and "OpenSSL Project" must not be used to
 *    endorse or promote products derived from this software without
 *    prior written permission. For written permission, please contact
 *    licensing@OpenSSL.org.
 *
 * 5. Products derived from this software may not be called "OpenSSL"
 *    nor may "OpenSSL" appear in their names without prior written
 *    permission of the OpenSSL Project.
 *
 * 6. Redistributions of any form whatsoever must retain the following
 *    acknowledgment:
 *    "This product includes software developed by the OpenSSL Project
 *    for use in the OpenSSL Toolkit (http://www.OpenSSL.org/)"
 *
 * THIS SOFTWARE IS PROVIDED BY THE OpenSSL PROJECT ``AS IS'' AND ANY
 * EXPRESSED OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
 * IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR
 * PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL THE OpenSSL PROJECT OR
 * ITS CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
 * SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT
 * NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
 * LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
 * HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT,
 * STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
 * ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED
 * OF THE POSSIBILITY OF SUCH DAMAGE.
 * ====================================================================
 */

#include <fcntl.h>
#include <string.h>
#include <sys/stat.h>
#include <sys/types.h>
#include <sys/uio.h>

#include "e_os.h"

#include <openssl/opensslconf.h>
#include <openssl/ossl_typ.h>
#include <openssl/rand.h>
#include "rand_lcl.h"

#include <openssl/err.h>

#define MIN(a,b) ((a) < (b) ? (a) : (b))

#define RANDOM_FILE "/dev/random"
#define PSEUDO_FILE "/dev/urandom"
// Must be a power of 2
#define BUFFER_SIZE (1 << 10)

typedef struct {
	int fd;
	unsigned char *buffer;
	unsigned int capacity;
	unsigned int read_count;
	unsigned int write_count;
} ring_buffer_t;

static ring_buffer_t random_buffer;
static ring_buffer_t pseudo_buffer;

static void ring_cleanup(ring_buffer_t* rb)
	{
	if (rb->fd != -1)
		{
		close(rb->fd);
		rb->fd = -1;
		}

	if (rb->buffer != NULL)
		{
		OPENSSL_cleanse(rb->buffer, rb->capacity);
		OPENSSL_free(rb->buffer);
		rb->buffer = NULL;
		}
	}

static int ring_init(ring_buffer_t* rb, int capacity, const char* source_file)
	{
	rb->fd = open(source_file, O_RDONLY, 0);
	if (rb->fd == -1)
		{
		return 0;
		}
	rb->buffer = (unsigned char*) OPENSSL_malloc(capacity);
	if (rb->buffer == NULL)
		{
		ring_cleanup(rb);
		return 0;
		}
	rb->capacity = capacity;
	rb->read_count = rb->write_count = 0;
	return 1;
	}

static inline unsigned char* ring_head(ring_buffer_t* rb)
	{
	return &rb->buffer[rb->read_count & (rb->capacity - 1)];
	}

static inline unsigned char* ring_tail(ring_buffer_t* rb)
	{
	return &rb->buffer[rb->write_count & (rb->capacity - 1)];
	}

static inline unsigned char* ring_end(ring_buffer_t* rb)
	{
	return &rb->buffer[rb->capacity];
	}

static inline int ring_num_used(ring_buffer_t* rb)
	{
	return (unsigned int)(rb->write_count - rb->read_count);
	}

static inline int ring_num_free(ring_buffer_t* rb)
	{
	return rb->capacity - ring_num_used(rb);
	}

static inline int ring_is_empty(ring_buffer_t* rb)
	{
	return rb->write_count == rb->read_count;
	}

static int ring_attempt_fill(ring_buffer_t* rb)
	{
	struct iovec iov[2];
	int vec_num = 0;
	int num_read = 0;
	int tail_len;
	int head_len;
	unsigned char* head;
	unsigned char* tail;

	tail = ring_tail(rb);
	tail_len = ring_end(rb) - tail;
	if (tail_len > 0)
		{
		iov[vec_num].iov_base = tail;
		iov[vec_num].iov_len = tail_len;
		vec_num++;
		}

	head = ring_head(rb);
	head_len = head - rb->buffer;
	if (head_len > 0)
		{
		iov[vec_num].iov_base = rb->buffer;
		iov[vec_num].iov_len = head_len;
		vec_num++;
		}

	if (vec_num == 0)
		{
		return 0;
		}

	num_read = readv(rb->fd, iov, vec_num);
	rb->write_count += num_read;
	return num_read;
	}

static void ring_write(ring_buffer_t* rb, const unsigned char* buf, int num)
	{
	int max_len;
	int tail_len;
	unsigned char* head;
	unsigned char* tail;

	max_len = ring_num_free(rb);
	if (num > max_len)
		num = max_len;

	tail = ring_tail(rb);
	tail_len = MIN(ring_end(rb) - tail, num);
	if (tail_len > 0)
		{
		memcpy(tail, buf, tail_len);
		}

	memcpy(rb->buffer, buf, num - tail_len);
	rb->write_count += num;
	}

static int ring_read(ring_buffer_t* rb, unsigned char* buf, int num)
	{
	unsigned char *head;
	unsigned char *tail;
	int requested = num;
	int to_copy;

	while (num > 0)
		{
		if (ring_is_empty(rb))
			{
			int nread = ring_attempt_fill(rb);
			if (nread <= 0)
				return requested - num;
			}

		to_copy = MIN(num, ring_num_used(rb));
		head = ring_head(rb);
		tail = ring_tail(rb);
		if (tail < head)
			{
			int part_len = MIN(to_copy, ring_end(rb) - head);
			memcpy(buf, head, part_len);
			buf += part_len;
			num -= part_len;

			part_len = MIN(to_copy - part_len, tail - rb->buffer);
			memcpy(buf, rb->buffer, part_len);
			buf += part_len;
			num -= part_len;
			}
		else
			{
			memcpy(buf, head, to_copy);
			buf += to_copy;
			num -= to_copy;
			}

		rb->read_count += to_copy;
		}
	return requested - num;
	}

static void raw_rand_seed(const void *buf, int num)
	{
	CRYPTO_w_lock(CRYPTO_LOCK_RAND);
	ring_write(&pseudo_buffer, (const unsigned char*) buf, num);
	CRYPTO_w_unlock(CRYPTO_LOCK_RAND);
	}

static int raw_rand_bytes(ring_buffer_t* rb, unsigned char *buf, int num)
	{
	int ret;
	int nbytes = 0;

	CRYPTO_r_lock(CRYPTO_LOCK_RAND);
	while (nbytes < num)
		{
		ret = ring_read(rb, buf, num);
		if (ret <= 0)
			break;
		nbytes += ret;
		}
	CRYPTO_r_unlock(CRYPTO_LOCK_RAND);
	return nbytes == num;
	}

static int raw_rand_nopseudo_bytes(unsigned char *buf, int num)
	{
	return raw_rand_bytes(&random_buffer, buf, num);
	}

static int raw_rand_pseudo_bytes(unsigned char *buf, int num)
	{
	return raw_rand_bytes(&pseudo_buffer, buf, num);
	}

static void raw_rand_cleanup(void)
	{
	ring_cleanup(&random_buffer);
	ring_cleanup(&pseudo_buffer);
	}

static void raw_rand_add(const void *buf, int num, double add)
	{
	CRYPTO_w_lock(CRYPTO_LOCK_RAND);
	ring_write(&pseudo_buffer, (const unsigned char*) buf, num);
	CRYPTO_w_unlock(CRYPTO_LOCK_RAND);
	}

static int raw_rand_status(void)
	{
	// TODO actually return a status
	return 0;
	}

static RAND_METHOD rand_raw_meth={
	raw_rand_seed,
	raw_rand_nopseudo_bytes,
	raw_rand_cleanup,
	raw_rand_add,
	raw_rand_pseudo_bytes,
	raw_rand_status
	};

RAND_METHOD *RAND_Raw(void)
	{
	ring_init(&random_buffer, BUFFER_SIZE, RANDOM_FILE);
	ring_init(&pseudo_buffer, BUFFER_SIZE, PSEUDO_FILE);

	return(&rand_raw_meth);
	}
