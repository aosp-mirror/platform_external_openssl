.text
.fpu	neon
.code	32
.align	5
rcon:
.long	0x01,0x01,0x01,0x01
.long	0x0c0f0e0d,0x0c0f0e0d,0x0c0f0e0d,0x0c0f0e0d	@ rotate-n-splat
.long	0x1b,0x1b,0x1b,0x1b

.globl	AES_set_encrypt_key
.type	AES_set_encrypt_key,%function
.align	5
AES_set_encrypt_key:
.Lenc_key:
	adr	r3,rcon
	cmp	r1,#192

	veor	q0,q0,q0
	vld1.8	{q3},[r0]!
	mov	r1,#8		@ reuse r1
	vld1.32	{q1,q2},[r3]!

	blt	.Loop128
	beq	.L192
	b	.L256

.align	4
.Loop128:
	vtbl.8	d20,{q3},d4
	vtbl.8	d21,{q3},d5
	vext.8	q9,q0,q3,#12
	vst1.32	{q3},[r2]!
	.long	0xf3f04300	@ aese q10,q0
	subs	r1,r1,#1

	veor	q3,q3,q9
	vext.8	q9,q0,q9,#12
	veor	q3,q3,q9
	vext.8	q9,q0,q9,#12
	 veor	q10,q10,q1
	veor	q3,q3,q9
	vshl.u8	q1,q1,#1
	veor	q3,q3,q10
	bne	.Loop128

	vld1.32	{q1},[r3]

	vtbl.8	d20,{q3},d4
	vtbl.8	d21,{q3},d5
	vext.8	q9,q0,q3,#12
	vst1.32	{q3},[r2]!
	.long	0xf3f04300	@ aese q10,q0

	veor	q3,q3,q9
	vext.8	q9,q0,q9,#12
	veor	q3,q3,q9
	vext.8	q9,q0,q9,#12
	 veor	q10,q10,q1
	veor	q3,q3,q9
	vshl.u8	q1,q1,#1
	veor	q3,q3,q10

	vtbl.8	d20,{q3},d4
	vtbl.8	d21,{q3},d5
	vext.8	q9,q0,q3,#12
	vst1.32	{q3},[r2]!
	.long	0xf3f04300	@ aese q10,q0

	veor	q3,q3,q9
	vext.8	q9,q0,q9,#12
	veor	q3,q3,q9
	vext.8	q9,q0,q9,#12
	 veor	q10,q10,q1
	veor	q3,q3,q9
	veor	q3,q3,q10
	vst1.32	{q3},[r2]
	add	r2,r2,#0x50

	mov	r12,#10
	b	.Ldone

.align	4
.L192:
	vld1.8	{q8},[r0]!
	vmov.i8	q10,#8			@ borrow q10
	vst1.32	{q3},[r2]!
	vsub.i8	q2,q2,q10	@ adjust the mask

.Loop192:
	vtbl.8	d20,{q8},d4
	vtbl.8	d21,{q8},d5
	vext.8	q9,q0,q3,#12
	vst1.32	{q8},[r2]!
	.long	0xf3f04300	@ aese q10,q0
	subs	r1,r1,#1

	veor	q3,q3,q9
	vext.8	q9,q0,q9,#12
	veor	q3,q3,q9
	vext.8	q9,q0,q9,#12
	veor	q3,q3,q9

	vdup.32	q9,d4[1]
	veor	q9,q9,q8
	 veor	q10,q10,q1
	vext.8	q8,q0,q8,#12
	vshl.u8	q1,q1,#1
	veor	q8,q8,q9
	veor	q3,q3,q10
	veor	q8,q8,q10
	vst1.32	{q3},[r2]!
	bne	.Loop192

	mov	r12,#12
	add	r2,r2,#0x20
	b	.Ldone

.align	4
.L256:
	vld1.8	{q8},[r0]
	mov	r1,#7
	mov	r12,#14
	vst1.32	{q3},[r2]!

.Loop256:
	vtbl.8	d20,{q8},d4
	vtbl.8	d21,{q8},d5
	vext.8	q9,q0,q3,#12
	vst1.32	{q8},[r2]!
	.long	0xf3f04300	@ aese q10,q0
	subs	r1,r1,#1

	veor	q3,q3,q9
	vext.8	q9,q0,q9,#12
	veor	q3,q3,q9
	vext.8	q9,q0,q9,#12
	 veor	q10,q10,q1
	veor	q3,q3,q9
	vshl.u8	q1,q1,#1
	veor	q3,q3,q10
	vst1.32	{q3},[r2]!
	beq	.Ldone

	vdup.32	q10,d4[1]
	vext.8	q9,q0,q8,#12
	.long	0xf3f04300	@ aese q10,q0

	veor	q8,q8,q9
	vext.8	q9,q0,q9,#12
	veor	q8,q8,q9
	vext.8	q9,q0,q9,#12
	veor	q8,q8,q9

	veor	q8,q8,q10
	b	.Loop256

.Ldone:
	str	r12,[r2]

	eor	r0,r0,r0		@ return value
	
	bx	lr
.size	AES_set_encrypt_key,.-AES_set_encrypt_key

.globl	AES_set_decrypt_key
.type	AES_set_decrypt_key,%function
.align	5
AES_set_decrypt_key:
	stmdb	sp!,{r4,lr}
	bl	.Lenc_key

	sub	r2,r2,#240		@ restore original r2
	mov	r4,#-16
	add	r0,r2,r12,lsl#4	@ end of key schedule

	vld1.32	{q0},[r2]
	vld1.32	{q1},[r0]
	vst1.32	{q0},[r0],r4
	vst1.32	{q1},[r2]!

.Loop_imc:
	vld1.32	{q0},[r2]
	vld1.32	{q1},[r0]
	.long	0xf3b003c0	@ aesimc q0,q0
	.long	0xf3b023c2	@ aesimc q1,q1
	vst1.32	{q0},[r0],r4
	vst1.32	{q1},[r2]!
	cmp	r0,r2
	bhi	.Loop_imc

	vld1.32	{q0},[r2]
	.long	0xf3b003c0	@ aesimc q0,q0
	vst1.32	{q0},[r0]

	eor	r0,r0,r0		@ return value
	ldmia	sp!,{r4,pc}
.size	AES_set_decrypt_key,.-AES_set_decrypt_key
.globl	AES_encrypt
.type	AES_encrypt,%function
.align	5
AES_encrypt:
	ldr	r3,[r2,#240]
	vld1.32	{q0},[r2]!
	vld1.8	{q2},[r0]
	sub	r3,r3,#2
	vld1.32	{q1},[r2]!

.Loop_enc:
	.long	0xf3b04300	@ aese q2,q0
	vld1.32	{q0},[r2]!
	.long	0xf3b04384	@ aesmc q2,q2
	subs	r3,r3,#2
	.long	0xf3b04302	@ aese q2,q1
	vld1.32	{q1},[r2]!
	.long	0xf3b04384	@ aesmc q2,q2
	bgt	.Loop_enc

	.long	0xf3b04300	@ aese q2,q0
	vld1.32	{q0},[r2]
	.long	0xf3b04384	@ aesmc q2,q2
	.long	0xf3b04302	@ aese q2,q1
	veor	q2,q2,q0

	vst1.8	{q2},[r1]
	bx	lr
.size	AES_encrypt,.-AES_encrypt
.globl	AES_decrypt
.type	AES_decrypt,%function
.align	5
AES_decrypt:
	ldr	r3,[r2,#240]
	vld1.32	{q0},[r2]!
	vld1.8	{q2},[r0]
	sub	r3,r3,#2
	vld1.32	{q1},[r2]!

.Loop_dec:
	.long	0xf3b04340	@ aesd q2,q0
	vld1.32	{q0},[r2]!
	.long	0xf3b043c4	@ aesimc q2,q2
	subs	r3,r3,#2
	.long	0xf3b04342	@ aesd q2,q1
	vld1.32	{q1},[r2]!
	.long	0xf3b043c4	@ aesimc q2,q2
	bgt	.Loop_dec

	.long	0xf3b04340	@ aesd q2,q0
	vld1.32	{q0},[r2]
	.long	0xf3b043c4	@ aesimc q2,q2
	.long	0xf3b04342	@ aesd q2,q1
	veor	q2,q2,q0

	vst1.8	{q2},[r1]
	bx	lr
.size	AES_decrypt,.-AES_decrypt
.globl	AES_cbc_encrypt
.type	AES_cbc_encrypt,%function
.align	5
AES_cbc_encrypt:
	mov	ip,sp
	stmdb	sp!,{r4-r8,lr}
	vstmdb	sp!,{d8-d15}            @ ABI specification says so
	ldmia	ip,{r4-r5}		@ load remaining args
	subs	r2,r2,#16
	mov	r8,#16
	blo	.Lcbc_abort
	moveq	r8,#0

	cmp	r5,#0			@ en- or decrypting?
	ldr	r5,[r3,#240]
	and	r2,r2,#-16
	vld1.8	{q6},[r4]
	vld1.8	{q0},[r0],r8

	vld1.32	{q8-q9},[r3]		@ load key schedule...
	sub	r5,r5,#6
	add	r7,r3,r5,lsl#4	@ pointer to last 7 round keys
	sub	r5,r5,#2
	vld1.32	{q10-q11},[r7]!
	vld1.32	{q12-q13},[r7]!
	vld1.32	{q14-q15},[r7]!
	vld1.32	{q7},[r7]

	add	r7,r3,#32
	mov	r6,r5
	beq	.Lcbc_dec

	cmp	r5,#2
	veor	q0,q0,q6
	veor	q5,q8,q7
	beq	.Lcbc_enc128

.Loop_cbc_enc:
	.long	0xf3b00320	@ aese q0,q8
	vld1.32	{q8},[r7]!
	.long	0xf3b00380	@ aesmc q0,q0
	subs	r6,r6,#2
	.long	0xf3b00322	@ aese q0,q9
	vld1.32	{q9},[r7]!
	.long	0xf3b00380	@ aesmc q0,q0
	bgt	.Loop_cbc_enc

	.long	0xf3b00320	@ aese q0,q8
	.long	0xf3b00380	@ aesmc q0,q0
	 subs	r2,r2,#16
	.long	0xf3b00322	@ aese q0,q9
	.long	0xf3b00380	@ aesmc q0,q0
	 moveq	r8,#0
	.long	0xf3b00324	@ aese q0,q10
	.long	0xf3b00380	@ aesmc q0,q0
	 add	r7,r3,#16
	.long	0xf3b00326	@ aese q0,q11
	.long	0xf3b00380	@ aesmc q0,q0
	 vld1.8	{q8},[r0],r8
	.long	0xf3b00328	@ aese q0,q12
	.long	0xf3b00380	@ aesmc q0,q0
	 veor	q8,q8,q5
	.long	0xf3b0032a	@ aese q0,q13
	.long	0xf3b00380	@ aesmc q0,q0
	 vld1.32 {q9},[r7]!	@ re-pre-load rndkey[1]
	.long	0xf3b0032c	@ aese q0,q14
	.long	0xf3b00380	@ aesmc q0,q0
	.long	0xf3b0032e	@ aese q0,q15

	 mov	r6,r5
	veor	q6,q0,q7
	vst1.8	{q6},[r1]!
	bhs	.Loop_cbc_enc

	b	.Lcbc_done

.align	5
.Lcbc_enc128:
	vld1.32	{q2-q3},[r7]
	.long	0xf3b00320	@ aese q0,q8
	.long	0xf3b00380	@ aesmc q0,q0
	b	.Lenter_cbc_enc128
.Loop_cbc_enc128:
	.long	0xf3b00320	@ aese q0,q8
	.long	0xf3b00380	@ aesmc q0,q0
	 vst1.8	{q6},[r1]!
.Lenter_cbc_enc128:
	.long	0xf3b00322	@ aese q0,q9
	.long	0xf3b00380	@ aesmc q0,q0
	 subs	r2,r2,#16
	.long	0xf3b00304	@ aese q0,q2
	.long	0xf3b00380	@ aesmc q0,q0
	 moveq	r8,#0
	.long	0xf3b00306	@ aese q0,q3
	.long	0xf3b00380	@ aesmc q0,q0
	.long	0xf3b00324	@ aese q0,q10
	.long	0xf3b00380	@ aesmc q0,q0
	.long	0xf3b00326	@ aese q0,q11
	.long	0xf3b00380	@ aesmc q0,q0
	 vld1.8	{q8},[r0],r8
	.long	0xf3b00328	@ aese q0,q12
	.long	0xf3b00380	@ aesmc q0,q0
	.long	0xf3b0032a	@ aese q0,q13
	.long	0xf3b00380	@ aesmc q0,q0
	.long	0xf3b0032c	@ aese q0,q14
	.long	0xf3b00380	@ aesmc q0,q0
	 veor	q8,q8,q5
	.long	0xf3b0032e	@ aese q0,q15
	veor	q6,q0,q7
	bhs	.Loop_cbc_enc128

	vst1.8	{q6},[r1]!
	b	.Lcbc_done

.align	5
.Lcbc_dec128:
	vld1.32	{q4-q5},[r7]
	veor	q6,q6,q7
	veor	q2,q0,q7
	mov	r12,r8

.Loop2x_cbc_dec128:
	.long	0xf3b00360	@ aesd q0,q8
	.long	0xf3b02360	@ aesd q1,q8
	.long	0xf3b003c0	@ aesimc q0,q0
	.long	0xf3b023c2	@ aesimc q1,q1
	 subs	r2,r2,#32
	.long	0xf3b00362	@ aesd q0,q9
	.long	0xf3b02362	@ aesd q1,q9
	.long	0xf3b003c0	@ aesimc q0,q0
	.long	0xf3b023c2	@ aesimc q1,q1
	 movlo	r8,#0
	.long	0xf3b00348	@ aesd q0,q4
	.long	0xf3b02348	@ aesd q1,q4
	.long	0xf3b003c0	@ aesimc q0,q0
	.long	0xf3b023c2	@ aesimc q1,q1
	 movls	r12,#0
	.long	0xf3b0034a	@ aesd q0,q5
	.long	0xf3b0234a	@ aesd q1,q5
	.long	0xf3b003c0	@ aesimc q0,q0
	.long	0xf3b023c2	@ aesimc q1,q1
	.long	0xf3b00364	@ aesd q0,q10
	.long	0xf3b02364	@ aesd q1,q10
	.long	0xf3b003c0	@ aesimc q0,q0
	.long	0xf3b023c2	@ aesimc q1,q1
	.long	0xf3b00366	@ aesd q0,q11
	.long	0xf3b02366	@ aesd q1,q11
	.long	0xf3b003c0	@ aesimc q0,q0
	.long	0xf3b023c2	@ aesimc q1,q1
	.long	0xf3b00368	@ aesd q0,q12
	.long	0xf3b02368	@ aesd q1,q12
	.long	0xf3b003c0	@ aesimc q0,q0
	.long	0xf3b023c2	@ aesimc q1,q1
	.long	0xf3b0036a	@ aesd q0,q13
	.long	0xf3b0236a	@ aesd q1,q13
	.long	0xf3b003c0	@ aesimc q0,q0
	.long	0xf3b023c2	@ aesimc q1,q1
	.long	0xf3b0036c	@ aesd q0,q14
	.long	0xf3b0236c	@ aesd q1,q14
	.long	0xf3b003c0	@ aesimc q0,q0
	.long	0xf3b023c2	@ aesimc q1,q1
	.long	0xf3b0036e	@ aesd q0,q15
	.long	0xf3b0236e	@ aesd q1,q15

	veor	q6,q6,q0
	veor	q2,q2,q1
	vld1.8	{q0},[r0],r8
	vld1.8	{q1},[r0],r12
	vst1.8	{q6},[r1]!
	veor	q6,q3,q7
	vst1.8	{q2},[r1]!
	veor	q2,q0,q7
	vorr	q3,q1,q1
	bhs	.Loop2x_cbc_dec128

	adds	r2,r2,#32
	veor	q6,q6,q7
	beq	.Lcbc_done
	veor	q2,q2,q7
	b	.Lcbc_dec_tail

.align	5
.Lcbc_dec:
	subs	r2,r2,#16
	vorr	q2,q0,q0
	blo	.Lcbc_dec_tail

	moveq	r8,#0
	cmp	r5,#2
	vld1.8	{q1},[r0],r8
	vorr	q3,q1,q1
	beq	.Lcbc_dec128

.Loop2x_cbc_dec:
	.long	0xf3b00360	@ aesd q0,q8
	.long	0xf3b02360	@ aesd q1,q8
	vld1.32	{q8},[r7]!
	.long	0xf3b003c0	@ aesimc q0,q0
	.long	0xf3b023c2	@ aesimc q1,q1
	subs	r6,r6,#2
	.long	0xf3b00362	@ aesd q0,q9
	.long	0xf3b02362	@ aesd q1,q9
	vld1.32	{q9},[r7]!
	.long	0xf3b003c0	@ aesimc q0,q0
	.long	0xf3b023c2	@ aesimc q1,q1
	bgt	.Loop2x_cbc_dec

	.long	0xf3b00360	@ aesd q0,q8
	.long	0xf3b02360	@ aesd q1,q8
	.long	0xf3b003c0	@ aesimc q0,q0
	.long	0xf3b023c2	@ aesimc q1,q1
	 veor	q4,q6,q7
	 veor	q5,q2,q7
	.long	0xf3b00362	@ aesd q0,q9
	.long	0xf3b02362	@ aesd q1,q9
	.long	0xf3b003c0	@ aesimc q0,q0
	.long	0xf3b023c2	@ aesimc q1,q1
	 vorr	q6,q3,q3
	 subs	r2,r2,#32
	.long	0xf3b00364	@ aesd q0,q10
	.long	0xf3b02364	@ aesd q1,q10
	.long	0xf3b003c0	@ aesimc q0,q0
	 movlo	r8,#0
	.long	0xf3b023c2	@ aesimc q1,q1
	 mov	r7,r3
	.long	0xf3b00366	@ aesd q0,q11
	.long	0xf3b02366	@ aesd q1,q11
	.long	0xf3b003c0	@ aesimc q0,q0
	 vld1.8	{q2},[r0],r8
	.long	0xf3b023c2	@ aesimc q1,q1
	 movls	r8,#0
	.long	0xf3b00368	@ aesd q0,q12
	.long	0xf3b02368	@ aesd q1,q12
	.long	0xf3b003c0	@ aesimc q0,q0
	.long	0xf3b023c2	@ aesimc q1,q1
	 vld1.8	{q3},[r0],r8
	.long	0xf3b0036a	@ aesd q0,q13
	.long	0xf3b0236a	@ aesd q1,q13
	.long	0xf3b003c0	@ aesimc q0,q0
	.long	0xf3b023c2	@ aesimc q1,q1
	 vld1.32 {q8},[r7]!	@ re-pre-load rndkey[0]
	.long	0xf3b0036c	@ aesd q0,q14
	.long	0xf3b0236c	@ aesd q1,q14
	.long	0xf3b003c0	@ aesimc q0,q0
	.long	0xf3b023c2	@ aesimc q1,q1
	 vld1.32 {q9},[r7]!	@ re-pre-load rndkey[1]
	.long	0xf3b0036e	@ aesd q0,q15
	.long	0xf3b0236e	@ aesd q1,q15

	 mov	r6,r5
	veor	q4,q4,q0
	veor	q5,q5,q1
	 vorr	q0,q2,q2
	vst1.8	{q4},[r1]!
	 vorr	q1,q3,q3
	vst1.8	{q5},[r1]!
	bhs	.Loop2x_cbc_dec

	adds	r2,r2,#32
	beq	.Lcbc_done

.Lcbc_dec_tail:
	.long	0xf3b00360	@ aesd q0,q8
	vld1.32	{q8},[r7]!
	.long	0xf3b003c0	@ aesimc q0,q0
	subs	r6,r6,#2
	.long	0xf3b00362	@ aesd q0,q9
	vld1.32	{q9},[r7]!
	.long	0xf3b003c0	@ aesimc q0,q0
	bgt	.Lcbc_dec_tail

	.long	0xf3b00360	@ aesd q0,q8
	.long	0xf3b003c0	@ aesimc q0,q0
	.long	0xf3b00362	@ aesd q0,q9
	.long	0xf3b003c0	@ aesimc q0,q0
	 veor	q4,q6,q7
	.long	0xf3b00364	@ aesd q0,q10
	.long	0xf3b003c0	@ aesimc q0,q0
	 vorr	q6,q2,q2
	.long	0xf3b00366	@ aesd q0,q11
	.long	0xf3b003c0	@ aesimc q0,q0
	.long	0xf3b00368	@ aesd q0,q12
	.long	0xf3b003c0	@ aesimc q0,q0
	.long	0xf3b0036a	@ aesd q0,q13
	.long	0xf3b003c0	@ aesimc q0,q0
	.long	0xf3b0036c	@ aesd q0,q14
	.long	0xf3b003c0	@ aesimc q0,q0
	.long	0xf3b0036e	@ aesd q0,q15

	veor	q4,q4,q0
	vst1.8	{q4},[r1]!

.Lcbc_done:
	vst1.8	{q6},[r4]
.Lcbc_abort:
	vldmia	sp!,{d8-d15}
	ldmia	sp!,{r4-r8,pc}
.size	AES_cbc_encrypt,.-AES_cbc_encrypt
