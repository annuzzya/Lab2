	.file	"bench.c"
	.intel_syntax noprefix
	.text
	.p2align 4
	.type	cmp, @function
cmp:
	endbr64
	vmovss	xmm0, DWORD PTR [rdi]
	vmovss	xmm1, DWORD PTR [rsi]
	xor	eax, eax
	vcomiss	xmm0, xmm1
	seta	al
	xor	edx, edx
	vcomiss	xmm1, xmm0
	seta	dl
	sub	eax, edx
	ret
	.size	cmp, .-cmp
	.p2align 4
	.type	sort_sample.constprop.0, @function
sort_sample.constprop.0:
	sub	rsp, 8
	lea	rdi, Z[rip]
	mov	edx, 4194304
	lea	rsi, Y[rip]
	call	memcpy@PLT
	lea	rcx, cmp[rip]
	mov	edx, 4
	mov	esi, 1048576
	mov	rdi, rax
	add	rsp, 8
	jmp	qsort@PLT
	.size	sort_sample.constprop.0, .-sort_sample.constprop.0
	.p2align 4
	.type	dot.constprop.0, @function
dot.constprop.0:
	mov	rdx, rdi
	test	rsi, rsi
	je	.L13
	lea	rax, -1[rsi]
	cmp	rax, 6
	jbe	.L14
	mov	rdi, rsi
	vxorps	xmm0, xmm0, xmm0
	lea	rcx, X[rip]
	xor	eax, eax
	shr	rdi, 3
	sal	rdi, 5
	.p2align 4,,10
	.p2align 3
.L8:
	vmovups	ymm4, YMMWORD PTR [rdx+rax]
	vmulps	ymm1, ymm4, YMMWORD PTR [rcx+rax]
	add	rax, 32
	vaddss	xmm0, xmm0, xmm1
	vshufps	xmm3, xmm1, xmm1, 85
	vshufps	xmm2, xmm1, xmm1, 255
	vaddss	xmm0, xmm0, xmm3
	vunpckhps	xmm3, xmm1, xmm1
	vextractf128	xmm1, ymm1, 0x1
	vaddss	xmm0, xmm0, xmm3
	vaddss	xmm0, xmm0, xmm2
	vshufps	xmm2, xmm1, xmm1, 85
	vaddss	xmm0, xmm0, xmm1
	vaddss	xmm0, xmm0, xmm2
	vunpckhps	xmm2, xmm1, xmm1
	vshufps	xmm1, xmm1, xmm1, 255
	vaddss	xmm0, xmm0, xmm2
	vaddss	xmm0, xmm0, xmm1
	cmp	rdi, rax
	jne	.L8
	mov	rax, rsi
	and	rax, -8
	test	sil, 7
	je	.L23
	vzeroupper
.L7:
	mov	rdi, rsi
	sub	rdi, rax
	lea	r8, -1[rdi]
	cmp	r8, 2
	jbe	.L11
	vmovups	xmm5, XMMWORD PTR [rdx+rax*4]
	vmulps	xmm1, xmm5, XMMWORD PTR [rcx+rax*4]
	mov	r8, rdi
	and	r8, -4
	add	rax, r8
	and	edi, 3
	vaddss	xmm0, xmm0, xmm1
	vshufps	xmm2, xmm1, xmm1, 85
	vaddss	xmm0, xmm0, xmm2
	vunpckhps	xmm2, xmm1, xmm1
	vshufps	xmm1, xmm1, xmm1, 255
	vaddss	xmm0, xmm0, xmm2
	vaddss	xmm0, xmm0, xmm1
	je	.L5
.L11:
	lea	r8, 1[rax]
	vmovss	xmm6, DWORD PTR [rcx+rax*4]
	lea	rdi, 0[0+rax*4]
	vfmadd231ss	xmm0, xmm6, DWORD PTR [rdx+rax*4]
	cmp	r8, rsi
	jnb	.L5
	add	rax, 2
	vmovss	xmm7, DWORD PTR 4[rcx+rdi]
	vfmadd231ss	xmm0, xmm7, DWORD PTR 4[rdx+rdi]
	cmp	rax, rsi
	jnb	.L5
	vmovss	xmm7, DWORD PTR 8[rcx+rdi]
	vfmadd231ss	xmm0, xmm7, DWORD PTR 8[rdx+rdi]
	ret
	.p2align 4,,10
	.p2align 3
.L13:
	vxorps	xmm0, xmm0, xmm0
.L5:
	ret
	.p2align 4,,10
	.p2align 3
.L23:
	vzeroupper
	ret
.L14:
	vxorps	xmm0, xmm0, xmm0
	xor	eax, eax
	lea	rcx, X[rip]
	jmp	.L7
	.size	dot.constprop.0, .-dot.constprop.0
	.p2align 4
	.type	saxpy.constprop.0, @function
saxpy.constprop.0:
	lea	rax, Y[rip]
	lea	rdx, X[rip]
	vbroadcastss	ymm1, DWORD PTR .LC2[rip]
	lea	rcx, 16777216[rax]
	.p2align 4,,10
	.p2align 3
.L25:
	vmovaps	ymm0, YMMWORD PTR [rdx]
	vfmadd213ps	ymm0, ymm1, YMMWORD PTR [rax]
	add	rax, 32
	add	rdx, 32
	vmovaps	YMMWORD PTR -32[rax], ymm0
	cmp	rax, rcx
	jne	.L25
	vzeroupper
	ret
	.size	saxpy.constprop.0, .-saxpy.constprop.0
	.p2align 4
	.type	matmul.constprop.0, @function
matmul.constprop.0:
	push	rbp
	lea	rcx, C[rip]
	mov	edx, 1048576
	xor	esi, esi
	mov	rdi, rcx
	mov	rbp, rsp
	and	rsp, -32
	call	memset@PLT
	lea	r10, A[rip]
	xor	r9d, r9d
	lea	r8, B[rip+1048576]
	mov	rdx, rax
	.p2align 4,,10
	.p2align 3
.L28:
	lea	rcx, B[rip]
	mov	rdi, r10
	.p2align 4,,10
	.p2align 3
.L33:
	vbroadcastss	ymm2, DWORD PTR [rdi]
	vbroadcastss	ymm1, DWORD PTR 4[rdi]
	lea	rsi, 2048[rcx]
	xor	eax, eax
	.p2align 4,,10
	.p2align 3
.L30:
	vmovaps	ymm0, YMMWORD PTR [rcx+rax]
	vfmadd213ps	ymm0, ymm2, YMMWORD PTR [rdx+rax]
	vfmadd231ps	ymm0, ymm1, YMMWORD PTR [rsi+rax]
	vmovaps	YMMWORD PTR [rdx+rax], ymm0
	add	rax, 32
	cmp	rax, 2048
	jne	.L30
	add	rcx, 4096
	add	rdi, 8
	cmp	r8, rcx
	jne	.L33
	add	r9, 512
	add	rdx, 2048
	add	r10, 2048
	cmp	r9, 262144
	jne	.L28
	vzeroupper
	leave
	ret
	.size	matmul.constprop.0, .-matmul.constprop.0
	.p2align 4
	.globl	fill
	.type	fill, @function
fill:
	endbr64
	test	rsi, rsi
	je	.L45
	vmovss	xmm1, DWORD PTR .LC4[rip]
	vxorps	xmm2, xmm2, xmm2
	lea	rcx, [rdi+rsi*4]
	.p2align 4,,10
	.p2align 3
.L40:
	imul	edx, edx, 1664525
	add	rdi, 4
	add	edx, 1013904223
	mov	eax, edx
	shr	eax, 8
	vcvtsi2ss	xmm0, xmm2, eax
	vmulss	xmm0, xmm0, xmm1
	vmovss	DWORD PTR -4[rdi], xmm0
	cmp	rcx, rdi
	jne	.L40
.L45:
	ret
	.size	fill, .-fill
	.p2align 4
	.globl	matmul
	.type	matmul, @function
matmul:
	endbr64
	push	rbp
	mov	r10, rdx
	movsx	rdx, ecx
	mov	rbp, rsp
	push	r15
	mov	r15, rdx
	push	r14
	mov	r14, rdi
	mov	rdi, r10
	push	r13
	push	r12
	mov	r12, rsi
	xor	esi, esi
	push	rbx
	mov	rbx, rdx
	and	rsp, -32
	sub	rsp, 64
	mov	QWORD PTR 48[rsp], rdx
	imul	rdx, rdx
	sal	rdx, 2
	call	memset@PLT
	test	ebx, ebx
	jle	.L70
	lea	edx, -1[rbx]
	sal	r15, 2
	mov	r13d, ebx
	mov	r10, rax
	mov	DWORD PTR 60[rsp], edx
	mov	edx, ebx
	lea	rax, [r14+r15]
	shr	r13d, 3
	and	edx, -8
	mov	QWORD PTR 40[rsp], rax
	lea	rsi, [r10+r15]
	mov	rax, r10
	mov	DWORD PTR 24[rsp], edx
	mov	edx, ebx
	sal	r13, 5
	xor	edi, edi
	and	edx, 7
	mov	DWORD PTR 56[rsp], 0
	mov	DWORD PTR 20[rsp], edx
	sub	edx, 1
	mov	QWORD PTR 32[rsp], 0
	mov	DWORD PTR 16[rsp], edx
	.p2align 4,,10
	.p2align 3
.L48:
	mov	rdx, QWORD PTR 32[rsp]
	mov	DWORD PTR 12[rsp], edi
	xor	r11d, r11d
	xor	r9d, r9d
	mov	QWORD PTR [rsp], r14
	lea	r8, [r14+rdx*4]
	mov	rdx, r12
	.p2align 4,,10
	.p2align 3
.L57:
	cmp	DWORD PTR 60[rsp], 2
	vmovss	xmm1, DWORD PTR [r8]
	jbe	.L58
	lea	rcx, 4[rdx]
	mov	r14, rax
	mov	rdi, rdx
	sub	r14, rcx
	mov	rcx, rax
	cmp	r14, 24
	ja	.L72
	.p2align 4,,10
	.p2align 3
.L55:
	vmovss	xmm0, DWORD PTR [rdi]
	vfmadd213ss	xmm0, xmm1, DWORD PTR [rcx]
	add	rcx, 4
	add	rdi, 4
	vmovss	DWORD PTR -4[rcx], xmm0
	cmp	rcx, rsi
	jne	.L55
.L56:
	mov	rdi, QWORD PTR 48[rsp]
	add	r8, 4
	add	rdx, r15
	add	r9d, ebx
	add	r11, rdi
	mov	rdi, QWORD PTR 40[rsp]
	cmp	r8, rdi
	jne	.L57
	mov	edi, DWORD PTR 12[rsp]
	mov	rcx, QWORD PTR 48[rsp]
	add	rax, r15
	add	rsi, r15
	add	QWORD PTR 40[rsp], r15
	mov	r14, QWORD PTR [rsp]
	add	edi, 1
	add	DWORD PTR 56[rsp], ebx
	add	QWORD PTR 32[rsp], rcx
	cmp	ebx, edi
	jne	.L48
	vzeroupper
.L70:
	lea	rsp, -40[rbp]
	pop	rbx
	pop	r12
	pop	r13
	pop	r14
	pop	r15
	pop	rbp
	ret
	.p2align 4,,10
	.p2align 3
.L72:
	cmp	DWORD PTR 60[rsp], 6
	jbe	.L60
	vbroadcastss	ymm2, xmm1
	xor	ecx, ecx
	.p2align 4,,10
	.p2align 3
.L51:
	vmovups	ymm0, YMMWORD PTR [rdx+rcx]
	vfmadd213ps	ymm0, ymm2, YMMWORD PTR [rax+rcx]
	vmovups	YMMWORD PTR [rax+rcx], ymm0
	add	rcx, 32
	cmp	rcx, r13
	jne	.L51
	mov	edi, DWORD PTR 24[rsp]
	cmp	edi, ebx
	je	.L56
	cmp	DWORD PTR 16[rsp], 2
	mov	ecx, DWORD PTR 20[rsp]
	jbe	.L61
	mov	DWORD PTR 28[rsp], edi
.L50:
	mov	r14, QWORD PTR 32[rsp]
	vshufps	xmm0, xmm1, xmm1, 0
	add	r14, rdi
	add	rdi, r11
	lea	r14, [r10+r14*4]
	vmovups	xmm3, XMMWORD PTR [r14]
	vfmadd132ps	xmm0, xmm3, XMMWORD PTR [r12+rdi*4]
	vmovups	XMMWORD PTR [r14], xmm0
	test	cl, 3
	je	.L56
	mov	edi, DWORD PTR 28[rsp]
	and	ecx, -4
	add	ecx, edi
.L53:
	mov	edi, DWORD PTR 56[rsp]
	add	edi, ecx
	movsx	rdi, edi
	lea	r14, [r10+rdi*4]
	lea	edi, [r9+rcx]
	movsx	rdi, edi
	vmovss	xmm0, DWORD PTR [r12+rdi*4]
	vfmadd213ss	xmm0, xmm1, DWORD PTR [r14]
	lea	edi, 1[rcx]
	vmovss	DWORD PTR [r14], xmm0
	cmp	edi, ebx
	jge	.L56
	mov	r14d, DWORD PTR 56[rsp]
	add	ecx, 2
	add	r14d, edi
	add	edi, r9d
	movsx	r14, r14d
	movsx	rdi, edi
	lea	r14, [r10+r14*4]
	vmovss	xmm0, DWORD PTR [r12+rdi*4]
	vfmadd213ss	xmm0, xmm1, DWORD PTR [r14]
	vmovss	DWORD PTR [r14], xmm0
	cmp	ebx, ecx
	jle	.L56
	mov	r14d, DWORD PTR 56[rsp]
	lea	edi, [r14+rcx]
	add	ecx, r9d
	movsx	rdi, edi
	movsx	rcx, ecx
	lea	rdi, [r10+rdi*4]
	vmovss	xmm4, DWORD PTR [rdi]
	vfmadd132ss	xmm1, xmm4, DWORD PTR [r12+rcx*4]
	vmovss	DWORD PTR [rdi], xmm1
	jmp	.L56
	.p2align 4,,10
	.p2align 3
.L58:
	mov	rdi, rdx
	mov	rcx, rax
	jmp	.L55
.L60:
	mov	DWORD PTR 28[rsp], 0
	mov	ecx, ebx
	xor	edi, edi
	jmp	.L50
.L61:
	mov	ecx, edi
	jmp	.L53
	.size	matmul, .-matmul
	.p2align 4
	.globl	saxpy
	.type	saxpy, @function
saxpy:
	endbr64
	mov	rcx, rsi
	test	rdx, rdx
	je	.L99
	lea	rsi, -1[rdx]
	cmp	rsi, 2
	jbe	.L83
	lea	rax, 4[rdi]
	mov	r8, rcx
	sub	r8, rax
	xor	eax, eax
	cmp	r8, 24
	ja	.L100
	.p2align 4,,10
	.p2align 3
.L81:
	vmovss	xmm1, DWORD PTR [rdi+rax*4]
	vfmadd213ss	xmm1, xmm0, DWORD PTR [rcx+rax*4]
	vmovss	DWORD PTR [rcx+rax*4], xmm1
	add	rax, 1
	cmp	rdx, rax
	jne	.L81
	ret
.L97:
	vzeroupper
.L99:
	ret
	.p2align 4,,10
	.p2align 3
.L100:
	cmp	rsi, 6
	jbe	.L85
	mov	rsi, rdx
	vbroadcastss	ymm2, xmm0
	shr	rsi, 3
	sal	rsi, 5
	.p2align 4,,10
	.p2align 3
.L77:
	vmovups	ymm1, YMMWORD PTR [rdi+rax]
	vfmadd213ps	ymm1, ymm2, YMMWORD PTR [rcx+rax]
	vmovups	YMMWORD PTR [rcx+rax], ymm1
	add	rax, 32
	cmp	rax, rsi
	jne	.L77
	mov	rax, rdx
	and	rax, -8
	test	dl, 7
	je	.L97
	mov	rsi, rdx
	sub	rsi, rax
	lea	r8, -1[rsi]
	cmp	r8, 2
	jbe	.L101
	vzeroupper
.L76:
	lea	r8, [rcx+rax*4]
	vshufps	xmm1, xmm0, xmm0, 0
	vmovups	xmm3, XMMWORD PTR [r8]
	vfmadd132ps	xmm1, xmm3, XMMWORD PTR [rdi+rax*4]
	vmovups	XMMWORD PTR [r8], xmm1
	mov	r8, rsi
	and	r8, -4
	add	rax, r8
	and	esi, 3
	je	.L99
.L79:
	lea	rsi, 0[0+rax*4]
	vmovss	xmm1, DWORD PTR [rdi+rax*4]
	lea	r8, [rcx+rsi]
	vfmadd213ss	xmm1, xmm0, DWORD PTR [r8]
	vmovss	DWORD PTR [r8], xmm1
	lea	r8, 1[rax]
	cmp	r8, rdx
	jnb	.L99
	lea	r8, 4[rcx+rsi]
	vmovss	xmm1, DWORD PTR 4[rdi+rsi]
	add	rax, 2
	vfmadd213ss	xmm1, xmm0, DWORD PTR [r8]
	vmovss	DWORD PTR [r8], xmm1
	cmp	rax, rdx
	jnb	.L99
	lea	rax, 8[rcx+rsi]
	vmovss	xmm4, DWORD PTR [rax]
	vfmadd132ss	xmm0, xmm4, DWORD PTR 8[rdi+rsi]
	vmovss	DWORD PTR [rax], xmm0
	ret
	.p2align 4,,10
	.p2align 3
.L83:
	xor	eax, eax
	jmp	.L81
.L85:
	mov	rsi, rdx
	xor	eax, eax
	jmp	.L76
.L101:
	vzeroupper
	jmp	.L79
	.size	saxpy, .-saxpy
	.p2align 4
	.globl	dot
	.type	dot, @function
dot:
	endbr64
	mov	rcx, rsi
	test	rdx, rdx
	je	.L110
	lea	rax, -1[rdx]
	cmp	rax, 6
	jbe	.L111
	mov	rsi, rdx
	xor	eax, eax
	vxorps	xmm0, xmm0, xmm0
	shr	rsi, 3
	sal	rsi, 5
	.p2align 4,,10
	.p2align 3
.L105:
	vmovups	ymm4, YMMWORD PTR [rdi+rax]
	vmulps	ymm1, ymm4, YMMWORD PTR [rcx+rax]
	add	rax, 32
	vaddss	xmm0, xmm0, xmm1
	vshufps	xmm3, xmm1, xmm1, 85
	vshufps	xmm2, xmm1, xmm1, 255
	vaddss	xmm0, xmm0, xmm3
	vunpckhps	xmm3, xmm1, xmm1
	vextractf128	xmm1, ymm1, 0x1
	vaddss	xmm0, xmm0, xmm3
	vaddss	xmm0, xmm0, xmm2
	vshufps	xmm2, xmm1, xmm1, 85
	vaddss	xmm0, xmm0, xmm1
	vaddss	xmm0, xmm0, xmm2
	vunpckhps	xmm2, xmm1, xmm1
	vshufps	xmm1, xmm1, xmm1, 255
	vaddss	xmm0, xmm0, xmm2
	vaddss	xmm0, xmm0, xmm1
	cmp	rsi, rax
	jne	.L105
	mov	rax, rdx
	and	rax, -8
	test	dl, 7
	je	.L120
	vzeroupper
.L104:
	mov	rsi, rdx
	sub	rsi, rax
	lea	r8, -1[rsi]
	cmp	r8, 2
	jbe	.L108
	vmovups	xmm5, XMMWORD PTR [rdi+rax*4]
	vmulps	xmm1, xmm5, XMMWORD PTR [rcx+rax*4]
	mov	r8, rsi
	and	r8, -4
	add	rax, r8
	and	esi, 3
	vaddss	xmm0, xmm0, xmm1
	vshufps	xmm2, xmm1, xmm1, 85
	vaddss	xmm0, xmm0, xmm2
	vunpckhps	xmm2, xmm1, xmm1
	vshufps	xmm1, xmm1, xmm1, 255
	vaddss	xmm0, xmm0, xmm2
	vaddss	xmm0, xmm0, xmm1
	je	.L102
.L108:
	lea	r8, 1[rax]
	vmovss	xmm6, DWORD PTR [rdi+rax*4]
	lea	rsi, 0[0+rax*4]
	vfmadd231ss	xmm0, xmm6, DWORD PTR [rcx+rax*4]
	cmp	r8, rdx
	jnb	.L102
	add	rax, 2
	vmovss	xmm7, DWORD PTR 4[rdi+rsi]
	vfmadd231ss	xmm0, xmm7, DWORD PTR 4[rcx+rsi]
	cmp	rax, rdx
	jnb	.L102
	vmovss	xmm7, DWORD PTR 8[rdi+rsi]
	vfmadd231ss	xmm0, xmm7, DWORD PTR 8[rcx+rsi]
	ret
	.p2align 4,,10
	.p2align 3
.L110:
	vxorps	xmm0, xmm0, xmm0
.L102:
	ret
	.p2align 4,,10
	.p2align 3
.L120:
	vzeroupper
	ret
.L111:
	xor	eax, eax
	vxorps	xmm0, xmm0, xmm0
	jmp	.L104
	.size	dot, .-dot
	.p2align 4
	.globl	sort_sample
	.type	sort_sample, @function
sort_sample:
	endbr64
	push	rbx
	mov	rax, rdi
	mov	rbx, rdx
	mov	rdi, rsi
	lea	rdx, 0[0+rdx*4]
	mov	rsi, rax
	call	memcpy@PLT
	mov	rsi, rbx
	mov	edx, 4
	pop	rbx
	mov	rdi, rax
	lea	rcx, cmp[rip]
	jmp	qsort@PLT
	.size	sort_sample, .-sort_sample
	.section	.rodata.str1.1,"aMS",@progbits,1
.LC6:
	.string	"fill"
.LC7:
	.string	"matmul"
.LC8:
	.string	"saxpy"
.LC9:
	.string	"dot"
.LC11:
	.string	"sort"
.LC12:
	.string	"%-8s %8.3f s\n"
.LC13:
	.string	"total"
.LC14:
	.string	"checksum %.6f\n"
	.section	.text.startup,"ax",@progbits
	.p2align 4
	.globl	main
	.type	main, @function
main:
	endbr64
	lea	r10, 8[rsp]
	and	rsp, -32
	lea	rcx, .LC8[rip]
	push	QWORD PTR -8[r10]
	vmovq	xmm0, rcx
	lea	rcx, .LC6[rip]
	push	rbp
	vmovq	xmm1, rcx
	mov	rbp, rsp
	push	r14
	push	r13
	mov	r13d, 5
	push	r12
	push	r10
	push	rbx
	sub	rsp, 200
	mov	rax, QWORD PTR fs:40
	mov	QWORD PTR -56[rbp], rax
	lea	rax, .LC9[rip]
	vpinsrq	xmm0, xmm0, rax, 1
	lea	rax, .LC7[rip]
	vpinsrq	xmm1, xmm1, rax, 1
	vinserti128	ymm6, ymm1, xmm0, 0x1
	vmovdqa	YMMWORD PTR -240[rbp], ymm6
	cmp	edi, 1
	jle	.L124
	mov	rdi, QWORD PTR 8[rsi]
	mov	edx, 10
	xor	esi, esi
	vzeroupper
	call	strtol@PLT
	movsx	r13, eax
.L124:
	vpxor	xmm0, xmm0, xmm0
	lea	rbx, -160[rbp]
	mov	edi, 1
	vmovdqu	YMMWORD PTR -88[rbp], ymm0
	mov	rsi, rbx
	vzeroupper
	call	clock_gettime@PLT
	vxorpd	xmm7, xmm7, xmm7
	mov	esi, 262144
	vcvtsi2sd	xmm0, xmm7, QWORD PTR -160[rbp]
	mov	edx, 1
	lea	rdi, A[rip]
	vcvtsi2sd	xmm1, xmm7, QWORD PTR -152[rbp]
	vfmadd132sd	xmm1, xmm0, QWORD PTR .LC10[rip]
	vmovsd	QWORD PTR -168[rbp], xmm1
	call	fill
	mov	edx, 2
	lea	rdi, B[rip]
	call	fill
	mov	esi, 4194304
	mov	edx, 3
	lea	rdi, X[rip]
	call	fill
	mov	edx, 4
	lea	rdi, Y[rip]
	call	fill
	mov	rsi, rbx
	mov	edi, 1
	vzeroupper
	call	clock_gettime@PLT
	vxorpd	xmm7, xmm7, xmm7
	vcvtsi2sd	xmm1, xmm7, QWORD PTR -160[rbp]
	vcvtsi2sd	xmm0, xmm7, QWORD PTR -152[rbp]
	vfmadd132sd	xmm0, xmm1, QWORD PTR .LC10[rip]
	vxorpd	xmm1, xmm1, xmm1
	vsubsd	xmm0, xmm0, QWORD PTR -168[rbp]
	vaddsd	xmm0, xmm0, xmm1
	vmovsd	QWORD PTR -96[rbp], xmm0
	test	r13d, r13d
	jle	.L132
	lea	r12, C[rip]
	vmovsd	QWORD PTR -200[rbp], xmm1
	lea	r13, [r12+r13*4]
	vmovsd	QWORD PTR -192[rbp], xmm1
	vmovsd	QWORD PTR -184[rbp], xmm1
	vmovsd	QWORD PTR -176[rbp], xmm1
	vmovsd	QWORD PTR -168[rbp], xmm1
	.p2align 4,,10
	.p2align 3
.L128:
	mov	rsi, rbx
	mov	edi, 1
	call	clock_gettime@PLT
	vxorpd	xmm4, xmm4, xmm4
	vcvtsi2sd	xmm0, xmm4, QWORD PTR -160[rbp]
	vcvtsi2sd	xmm1, xmm4, QWORD PTR -152[rbp]
	vfmadd132sd	xmm1, xmm0, QWORD PTR .LC10[rip]
	vmovsd	QWORD PTR -208[rbp], xmm1
	call	matmul.constprop.0
	mov	rsi, rbx
	mov	edi, 1
	call	clock_gettime@PLT
	vxorpd	xmm4, xmm4, xmm4
	mov	rsi, rbx
	mov	edi, 1
	vcvtsi2sd	xmm1, xmm4, QWORD PTR -160[rbp]
	vcvtsi2sd	xmm0, xmm4, QWORD PTR -152[rbp]
	vfmadd132sd	xmm0, xmm1, QWORD PTR .LC10[rip]
	vsubsd	xmm0, xmm0, QWORD PTR -208[rbp]
	vaddsd	xmm7, xmm0, QWORD PTR -176[rbp]
	vmovsd	QWORD PTR -176[rbp], xmm7
	vmovsd	QWORD PTR -88[rbp], xmm7
	call	clock_gettime@PLT
	vxorpd	xmm4, xmm4, xmm4
	mov	esi, 20
	vcvtsi2sd	xmm1, xmm4, QWORD PTR -152[rbp]
	vcvtsi2sd	xmm0, xmm4, QWORD PTR -160[rbp]
	vfmadd132sd	xmm1, xmm0, QWORD PTR .LC10[rip]
	vmovsd	QWORD PTR -208[rbp], xmm1
	.p2align 4,,10
	.p2align 3
.L126:
	call	saxpy.constprop.0
	call	saxpy.constprop.0
	sub	esi, 2
	jne	.L126
	mov	rsi, rbx
	mov	edi, 1
	call	clock_gettime@PLT
	vxorpd	xmm6, xmm6, xmm6
	mov	rsi, rbx
	mov	edi, 1
	vcvtsi2sd	xmm1, xmm6, QWORD PTR -160[rbp]
	vcvtsi2sd	xmm0, xmm6, QWORD PTR -152[rbp]
	vfmadd132sd	xmm0, xmm1, QWORD PTR .LC10[rip]
	vsubsd	xmm0, xmm0, QWORD PTR -208[rbp]
	vaddsd	xmm7, xmm0, QWORD PTR -184[rbp]
	vmovsd	QWORD PTR -184[rbp], xmm7
	vmovsd	QWORD PTR -80[rbp], xmm7
	call	clock_gettime@PLT
	vxorpd	xmm6, xmm6, xmm6
	mov	esi, 4194304
	lea	r9, Y[rip]
	vcvtsi2sd	xmm1, xmm6, QWORD PTR -152[rbp]
	vcvtsi2sd	xmm0, xmm6, QWORD PTR -160[rbp]
	vfmadd132sd	xmm1, xmm0, QWORD PTR .LC10[rip]
	vmovsd	QWORD PTR -208[rbp], xmm1
	.p2align 4,,10
	.p2align 3
.L127:
	mov	rdi, r9
	add	r9, 4
	call	dot.constprop.0
	vmovsd	xmm2, QWORD PTR .LC10[rip]
	sub	rsi, 1
	vcvtss2sd	xmm0, xmm0, xmm0
	vfmadd213sd	xmm0, xmm2, QWORD PTR -168[rbp]
	vmovsd	QWORD PTR -168[rbp], xmm0
	cmp	rsi, 4194284
	jne	.L127
	mov	rsi, rbx
	mov	edi, 1
	add	r12, 4
	call	clock_gettime@PLT
	vxorpd	xmm5, xmm5, xmm5
	mov	rsi, rbx
	mov	edi, 1
	vcvtsi2sd	xmm1, xmm5, QWORD PTR -160[rbp]
	vcvtsi2sd	xmm0, xmm5, QWORD PTR -152[rbp]
	vfmadd132sd	xmm0, xmm1, QWORD PTR .LC10[rip]
	vsubsd	xmm0, xmm0, QWORD PTR -208[rbp]
	vaddsd	xmm7, xmm0, QWORD PTR -192[rbp]
	vmovsd	QWORD PTR -192[rbp], xmm7
	vmovsd	QWORD PTR -72[rbp], xmm7
	call	clock_gettime@PLT
	vxorpd	xmm5, xmm5, xmm5
	vcvtsi2sd	xmm0, xmm5, QWORD PTR -160[rbp]
	vcvtsi2sd	xmm1, xmm5, QWORD PTR -152[rbp]
	vfmadd132sd	xmm1, xmm0, QWORD PTR .LC10[rip]
	vmovsd	QWORD PTR -208[rbp], xmm1
	call	sort_sample.constprop.0
	mov	rsi, rbx
	mov	edi, 1
	call	clock_gettime@PLT
	vxorpd	xmm5, xmm5, xmm5
	vcvtsi2sd	xmm0, xmm5, QWORD PTR -152[rbp]
	vcvtsi2sd	xmm1, xmm5, QWORD PTR -160[rbp]
	vfmadd132sd	xmm0, xmm1, QWORD PTR .LC10[rip]
	vsubsd	xmm0, xmm0, QWORD PTR -208[rbp]
	vaddsd	xmm6, xmm0, QWORD PTR -200[rbp]
	vmovss	xmm0, DWORD PTR -4[r12]
	vaddss	xmm0, xmm0, DWORD PTR Z[rip+2097152]
	vmovsd	QWORD PTR -200[rbp], xmm6
	vcvtss2sd	xmm0, xmm0, xmm0
	vaddsd	xmm4, xmm0, QWORD PTR -168[rbp]
	vmovsd	QWORD PTR -64[rbp], xmm6
	vmovsd	QWORD PTR -168[rbp], xmm4
	cmp	r12, r13
	jne	.L128
.L125:
	lea	rax, .LC11[rip]
	vxorpd	xmm1, xmm1, xmm1
	lea	r14, -96[rbp]
	xor	ebx, ebx
	vmovdqa	ymm6, YMMWORD PTR -240[rbp]
	mov	QWORD PTR -112[rbp], rax
	lea	r13, -144[rbp]
	lea	r12, .LC12[rip]
	vmovdqa	YMMWORD PTR -144[rbp], ymm6
	vzeroupper
	.p2align 4,,10
	.p2align 3
.L129:
	vmovsd	xmm0, QWORD PTR [r14+rbx]
	mov	rdx, QWORD PTR 0[r13+rbx]
	mov	rsi, r12
	mov	edi, 2
	mov	eax, 1
	vmovsd	QWORD PTR -184[rbp], xmm1
	add	rbx, 8
	vmovsd	QWORD PTR -176[rbp], xmm0
	call	__printf_chk@PLT
	vmovsd	xmm0, QWORD PTR -176[rbp]
	vmovsd	xmm1, QWORD PTR -184[rbp]
	vaddsd	xmm1, xmm1, xmm0
	cmp	rbx, 40
	jne	.L129
	vmovsd	xmm0, xmm1, xmm1
	mov	rsi, r12
	mov	edi, 2
	mov	eax, 1
	lea	rdx, .LC13[rip]
	call	__printf_chk@PLT
	mov	edi, 2
	mov	eax, 1
	vmovsd	xmm0, QWORD PTR -168[rbp]
	lea	rsi, .LC14[rip]
	call	__printf_chk@PLT
	mov	rax, QWORD PTR -56[rbp]
	sub	rax, QWORD PTR fs:40
	jne	.L140
	add	rsp, 200
	xor	eax, eax
	pop	rbx
	pop	r10
	pop	r12
	pop	r13
	pop	r14
	pop	rbp
	lea	rsp, -8[r10]
	ret
.L132:
	mov	QWORD PTR -168[rbp], 0x000000000
	jmp	.L125
.L140:
	call	__stack_chk_fail@PLT
	.size	main, .-main
	.local	Z
	.comm	Z,4194304,32
	.local	Y
	.comm	Y,16777216,32
	.local	X
	.comm	X,16777216,32
	.local	C
	.comm	C,1048576,32
	.local	B
	.comm	B,1048576,32
	.local	A
	.comm	A,1048576,32
	.section	.rodata.cst4,"aM",@progbits,4
	.align 4
.LC2:
	.long	1056964608
	.align 4
.LC4:
	.long	864026624
	.section	.rodata.cst8,"aM",@progbits,8
	.align 8
.LC10:
	.long	-400107883
	.long	1041313291
	.ident	"GCC: (Ubuntu 13.3.0-6ubuntu2~24.04) 13.3.0"
	.section	.note.GNU-stack,"",@progbits
	.section	.note.gnu.property,"a"
	.align 8
	.long	1f - 0f
	.long	4f - 1f
	.long	5
0:
	.string	"GNU"
1:
	.align 8
	.long	0xc0000002
	.long	3f - 2f
2:
	.long	0x3
3:
	.align 8
4:
