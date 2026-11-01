	.file	"bench.c"
	.intel_syntax noprefix
	.text
	.local	A
	.comm	A,1048576,32
	.local	B
	.comm	B,1048576,32
	.local	C
	.comm	C,1048576,32
	.local	X
	.comm	X,16777216,32
	.local	Y
	.comm	Y,16777216,32
	.local	Z
	.comm	Z,4194304,32
	.type	now, @function
now:
	endbr64
	push	rbp
	mov	rbp, rsp
	sub	rsp, 32
	mov	rax, QWORD PTR fs:40
	mov	QWORD PTR -8[rbp], rax
	xor	eax, eax
	lea	rax, -32[rbp]
	mov	rsi, rax
	mov	edi, 1
	call	clock_gettime@PLT
	mov	rax, QWORD PTR -32[rbp]
	pxor	xmm1, xmm1
	cvtsi2sd	xmm1, rax
	mov	rax, QWORD PTR -24[rbp]
	pxor	xmm2, xmm2
	cvtsi2sd	xmm2, rax
	movsd	xmm0, QWORD PTR .LC0[rip]
	mulsd	xmm0, xmm2
	addsd	xmm0, xmm1
	mov	rax, QWORD PTR -8[rbp]
	sub	rax, QWORD PTR fs:40
	je	.L3
	call	__stack_chk_fail@PLT
.L3:
	leave
	ret
	.size	now, .-now
	.globl	fill
	.type	fill, @function
fill:
	endbr64
	push	rbp
	mov	rbp, rsp
	mov	QWORD PTR -24[rbp], rdi
	mov	QWORD PTR -32[rbp], rsi
	mov	DWORD PTR -36[rbp], edx
	mov	QWORD PTR -8[rbp], 0
	jmp	.L5
.L8:
	mov	eax, DWORD PTR -36[rbp]
	imul	eax, eax, 1664525
	add	eax, 1013904223
	mov	DWORD PTR -36[rbp], eax
	mov	eax, DWORD PTR -36[rbp]
	shr	eax, 8
	mov	eax, eax
	test	rax, rax
	js	.L6
	pxor	xmm0, xmm0
	cvtsi2ss	xmm0, rax
	jmp	.L7
.L6:
	mov	rdx, rax
	shr	rdx
	and	eax, 1
	or	rdx, rax
	pxor	xmm0, xmm0
	cvtsi2ss	xmm0, rdx
	addss	xmm0, xmm0
.L7:
	mov	rax, QWORD PTR -8[rbp]
	lea	rdx, 0[0+rax*4]
	mov	rax, QWORD PTR -24[rbp]
	add	rax, rdx
	movss	xmm1, DWORD PTR .LC1[rip]
	divss	xmm0, xmm1
	movss	DWORD PTR [rax], xmm0
	add	QWORD PTR -8[rbp], 1
.L5:
	mov	rax, QWORD PTR -8[rbp]
	cmp	rax, QWORD PTR -32[rbp]
	jb	.L8
	nop
	nop
	pop	rbp
	ret
	.size	fill, .-fill
	.globl	matmul
	.type	matmul, @function
matmul:
	endbr64
	push	rbp
	mov	rbp, rsp
	sub	rsp, 48
	mov	QWORD PTR -24[rbp], rdi
	mov	QWORD PTR -32[rbp], rsi
	mov	QWORD PTR -40[rbp], rdx
	mov	DWORD PTR -44[rbp], ecx
	mov	eax, DWORD PTR -44[rbp]
	movsx	rdx, eax
	mov	eax, DWORD PTR -44[rbp]
	cdqe
	imul	rax, rdx
	lea	rdx, 0[0+rax*4]
	mov	rax, QWORD PTR -40[rbp]
	mov	esi, 0
	mov	rdi, rax
	call	memset@PLT
	mov	DWORD PTR -16[rbp], 0
	jmp	.L10
.L15:
	mov	DWORD PTR -12[rbp], 0
	jmp	.L11
.L14:
	mov	eax, DWORD PTR -16[rbp]
	imul	eax, DWORD PTR -44[rbp]
	mov	edx, eax
	mov	eax, DWORD PTR -12[rbp]
	add	eax, edx
	cdqe
	lea	rdx, 0[0+rax*4]
	mov	rax, QWORD PTR -24[rbp]
	add	rax, rdx
	movss	xmm0, DWORD PTR [rax]
	movss	DWORD PTR -4[rbp], xmm0
	mov	DWORD PTR -8[rbp], 0
	jmp	.L12
.L13:
	mov	eax, DWORD PTR -16[rbp]
	imul	eax, DWORD PTR -44[rbp]
	mov	edx, eax
	mov	eax, DWORD PTR -8[rbp]
	add	eax, edx
	cdqe
	lea	rdx, 0[0+rax*4]
	mov	rax, QWORD PTR -40[rbp]
	add	rax, rdx
	movss	xmm1, DWORD PTR [rax]
	mov	eax, DWORD PTR -12[rbp]
	imul	eax, DWORD PTR -44[rbp]
	mov	edx, eax
	mov	eax, DWORD PTR -8[rbp]
	add	eax, edx
	cdqe
	lea	rdx, 0[0+rax*4]
	mov	rax, QWORD PTR -32[rbp]
	add	rax, rdx
	movss	xmm0, DWORD PTR [rax]
	mulss	xmm0, DWORD PTR -4[rbp]
	mov	eax, DWORD PTR -16[rbp]
	imul	eax, DWORD PTR -44[rbp]
	mov	edx, eax
	mov	eax, DWORD PTR -8[rbp]
	add	eax, edx
	cdqe
	lea	rdx, 0[0+rax*4]
	mov	rax, QWORD PTR -40[rbp]
	add	rax, rdx
	addss	xmm0, xmm1
	movss	DWORD PTR [rax], xmm0
	add	DWORD PTR -8[rbp], 1
.L12:
	mov	eax, DWORD PTR -8[rbp]
	cmp	eax, DWORD PTR -44[rbp]
	jl	.L13
	add	DWORD PTR -12[rbp], 1
.L11:
	mov	eax, DWORD PTR -12[rbp]
	cmp	eax, DWORD PTR -44[rbp]
	jl	.L14
	add	DWORD PTR -16[rbp], 1
.L10:
	mov	eax, DWORD PTR -16[rbp]
	cmp	eax, DWORD PTR -44[rbp]
	jl	.L15
	nop
	nop
	leave
	ret
	.size	matmul, .-matmul
	.globl	saxpy
	.type	saxpy, @function
saxpy:
	endbr64
	push	rbp
	mov	rbp, rsp
	movss	DWORD PTR -20[rbp], xmm0
	mov	QWORD PTR -32[rbp], rdi
	mov	QWORD PTR -40[rbp], rsi
	mov	QWORD PTR -48[rbp], rdx
	mov	QWORD PTR -8[rbp], 0
	jmp	.L17
.L18:
	mov	rax, QWORD PTR -8[rbp]
	lea	rdx, 0[0+rax*4]
	mov	rax, QWORD PTR -32[rbp]
	add	rax, rdx
	movss	xmm0, DWORD PTR [rax]
	movaps	xmm1, xmm0
	mulss	xmm1, DWORD PTR -20[rbp]
	mov	rax, QWORD PTR -8[rbp]
	lea	rdx, 0[0+rax*4]
	mov	rax, QWORD PTR -40[rbp]
	add	rax, rdx
	movss	xmm0, DWORD PTR [rax]
	mov	rax, QWORD PTR -8[rbp]
	lea	rdx, 0[0+rax*4]
	mov	rax, QWORD PTR -40[rbp]
	add	rax, rdx
	addss	xmm0, xmm1
	movss	DWORD PTR [rax], xmm0
	add	QWORD PTR -8[rbp], 1
.L17:
	mov	rax, QWORD PTR -8[rbp]
	cmp	rax, QWORD PTR -48[rbp]
	jb	.L18
	nop
	nop
	pop	rbp
	ret
	.size	saxpy, .-saxpy
	.globl	dot
	.type	dot, @function
dot:
	endbr64
	push	rbp
	mov	rbp, rsp
	mov	QWORD PTR -24[rbp], rdi
	mov	QWORD PTR -32[rbp], rsi
	mov	QWORD PTR -40[rbp], rdx
	pxor	xmm0, xmm0
	movss	DWORD PTR -12[rbp], xmm0
	mov	QWORD PTR -8[rbp], 0
	jmp	.L20
.L21:
	mov	rax, QWORD PTR -8[rbp]
	lea	rdx, 0[0+rax*4]
	mov	rax, QWORD PTR -24[rbp]
	add	rax, rdx
	movss	xmm1, DWORD PTR [rax]
	mov	rax, QWORD PTR -8[rbp]
	lea	rdx, 0[0+rax*4]
	mov	rax, QWORD PTR -32[rbp]
	add	rax, rdx
	movss	xmm0, DWORD PTR [rax]
	mulss	xmm0, xmm1
	movss	xmm1, DWORD PTR -12[rbp]
	addss	xmm0, xmm1
	movss	DWORD PTR -12[rbp], xmm0
	add	QWORD PTR -8[rbp], 1
.L20:
	mov	rax, QWORD PTR -8[rbp]
	cmp	rax, QWORD PTR -40[rbp]
	jb	.L21
	movss	xmm0, DWORD PTR -12[rbp]
	pop	rbp
	ret
	.size	dot, .-dot
	.type	cmp, @function
cmp:
	endbr64
	push	rbp
	mov	rbp, rsp
	mov	QWORD PTR -24[rbp], rdi
	mov	QWORD PTR -32[rbp], rsi
	mov	rax, QWORD PTR -24[rbp]
	movss	xmm0, DWORD PTR [rax]
	movss	DWORD PTR -8[rbp], xmm0
	mov	rax, QWORD PTR -32[rbp]
	movss	xmm0, DWORD PTR [rax]
	movss	DWORD PTR -4[rbp], xmm0
	movss	xmm0, DWORD PTR -8[rbp]
	comiss	xmm0, DWORD PTR -4[rbp]
	seta	al
	movzx	edx, al
	movss	xmm0, DWORD PTR -4[rbp]
	comiss	xmm0, DWORD PTR -8[rbp]
	seta	al
	movzx	eax, al
	sub	edx, eax
	mov	eax, edx
	pop	rbp
	ret
	.size	cmp, .-cmp
	.globl	sort_sample
	.type	sort_sample, @function
sort_sample:
	endbr64
	push	rbp
	mov	rbp, rsp
	sub	rsp, 32
	mov	QWORD PTR -8[rbp], rdi
	mov	QWORD PTR -16[rbp], rsi
	mov	QWORD PTR -24[rbp], rdx
	mov	rax, QWORD PTR -24[rbp]
	lea	rdx, 0[0+rax*4]
	mov	rcx, QWORD PTR -8[rbp]
	mov	rax, QWORD PTR -16[rbp]
	mov	rsi, rcx
	mov	rdi, rax
	call	memcpy@PLT
	mov	rsi, QWORD PTR -24[rbp]
	mov	rax, QWORD PTR -16[rbp]
	lea	rdx, cmp[rip]
	mov	rcx, rdx
	mov	edx, 4
	mov	rdi, rax
	call	qsort@PLT
	nop
	leave
	ret
	.size	sort_sample, .-sort_sample
	.section	.rodata
.LC5:
	.string	"fill"
.LC6:
	.string	"matmul"
.LC7:
	.string	"saxpy"
.LC8:
	.string	"dot"
.LC9:
	.string	"sort"
.LC10:
	.string	"%-8s %8.3f s\n"
.LC11:
	.string	"total"
.LC12:
	.string	"checksum %.6f\n"
	.text
	.globl	main
	.type	main, @function
main:
	endbr64
	push	rbp
	mov	rbp, rsp
	sub	rsp, 160
	mov	DWORD PTR -148[rbp], edi
	mov	QWORD PTR -160[rbp], rsi
	mov	rax, QWORD PTR fs:40
	mov	QWORD PTR -8[rbp], rax
	xor	eax, eax
	cmp	DWORD PTR -148[rbp], 1
	jle	.L27
	mov	rax, QWORD PTR -160[rbp]
	add	rax, 8
	mov	rax, QWORD PTR [rax]
	mov	rdi, rax
	call	atoi@PLT
	jmp	.L28
.L27:
	mov	eax, 5
.L28:
	mov	DWORD PTR -124[rbp], eax
	pxor	xmm0, xmm0
	movaps	XMMWORD PTR -96[rbp], xmm0
	movaps	XMMWORD PTR -80[rbp], xmm0
	movq	QWORD PTR -64[rbp], xmm0
	pxor	xmm0, xmm0
	movsd	QWORD PTR -120[rbp], xmm0
	call	now
	movq	rax, xmm0
	mov	QWORD PTR -104[rbp], rax
	mov	edx, 1
	mov	esi, 262144
	lea	rax, A[rip]
	mov	rdi, rax
	call	fill
	mov	edx, 2
	mov	esi, 262144
	lea	rax, B[rip]
	mov	rdi, rax
	call	fill
	mov	edx, 3
	mov	esi, 4194304
	lea	rax, X[rip]
	mov	rdi, rax
	call	fill
	mov	edx, 4
	mov	esi, 4194304
	lea	rax, Y[rip]
	mov	rdi, rax
	call	fill
	call	now
	movq	rax, xmm0
	movq	xmm1, rax
	subsd	xmm1, QWORD PTR -104[rbp]
	movsd	xmm0, QWORD PTR -96[rbp]
	addsd	xmm0, xmm1
	movsd	QWORD PTR -96[rbp], xmm0
	mov	DWORD PTR -140[rbp], 0
	jmp	.L29
.L34:
	call	now
	movq	rax, xmm0
	mov	QWORD PTR -104[rbp], rax
	mov	ecx, 512
	lea	rax, C[rip]
	mov	rdx, rax
	lea	rax, B[rip]
	mov	rsi, rax
	lea	rax, A[rip]
	mov	rdi, rax
	call	matmul
	call	now
	movq	rax, xmm0
	movq	xmm1, rax
	subsd	xmm1, QWORD PTR -104[rbp]
	movsd	xmm0, QWORD PTR -88[rbp]
	addsd	xmm0, xmm1
	movsd	QWORD PTR -88[rbp], xmm0
	call	now
	movq	rax, xmm0
	mov	QWORD PTR -104[rbp], rax
	mov	DWORD PTR -136[rbp], 0
	jmp	.L30
.L31:
	mov	edx, 4194304
	lea	rax, Y[rip]
	mov	rsi, rax
	lea	rax, X[rip]
	mov	rdi, rax
	mov	eax, DWORD PTR .LC4[rip]
	movd	xmm0, eax
	call	saxpy
	add	DWORD PTR -136[rbp], 1
.L30:
	cmp	DWORD PTR -136[rbp], 19
	jle	.L31
	call	now
	movq	rax, xmm0
	movq	xmm1, rax
	subsd	xmm1, QWORD PTR -104[rbp]
	movsd	xmm0, QWORD PTR -80[rbp]
	addsd	xmm0, xmm1
	movsd	QWORD PTR -80[rbp], xmm0
	call	now
	movq	rax, xmm0
	mov	QWORD PTR -104[rbp], rax
	mov	DWORD PTR -132[rbp], 0
	jmp	.L32
.L33:
	mov	eax, 4194304
	sub	eax, DWORD PTR -132[rbp]
	cdqe
	mov	edx, DWORD PTR -132[rbp]
	movsx	rdx, edx
	lea	rcx, 0[0+rdx*4]
	lea	rdx, Y[rip]
	add	rcx, rdx
	mov	rdx, rax
	mov	rsi, rcx
	lea	rax, X[rip]
	mov	rdi, rax
	call	dot
	pxor	xmm1, xmm1
	cvtss2sd	xmm1, xmm0
	movsd	xmm0, QWORD PTR .LC0[rip]
	mulsd	xmm0, xmm1
	movsd	xmm1, QWORD PTR -120[rbp]
	addsd	xmm0, xmm1
	movsd	QWORD PTR -120[rbp], xmm0
	add	DWORD PTR -132[rbp], 1
.L32:
	cmp	DWORD PTR -132[rbp], 19
	jle	.L33
	call	now
	movq	rax, xmm0
	movq	xmm1, rax
	subsd	xmm1, QWORD PTR -104[rbp]
	movsd	xmm0, QWORD PTR -72[rbp]
	addsd	xmm0, xmm1
	movsd	QWORD PTR -72[rbp], xmm0
	call	now
	movq	rax, xmm0
	mov	QWORD PTR -104[rbp], rax
	mov	edx, 1048576
	lea	rax, Z[rip]
	mov	rsi, rax
	lea	rax, Y[rip]
	mov	rdi, rax
	call	sort_sample
	call	now
	movq	rax, xmm0
	movq	xmm1, rax
	subsd	xmm1, QWORD PTR -104[rbp]
	movsd	xmm0, QWORD PTR -64[rbp]
	addsd	xmm0, xmm1
	movsd	QWORD PTR -64[rbp], xmm0
	mov	eax, DWORD PTR -140[rbp]
	cdqe
	lea	rdx, 0[0+rax*4]
	lea	rax, C[rip]
	movss	xmm1, DWORD PTR [rdx+rax]
	movss	xmm0, DWORD PTR Z[rip+2097152]
	addss	xmm0, xmm1
	cvtss2sd	xmm0, xmm0
	movsd	xmm1, QWORD PTR -120[rbp]
	addsd	xmm0, xmm1
	movsd	QWORD PTR -120[rbp], xmm0
	add	DWORD PTR -140[rbp], 1
.L29:
	mov	eax, DWORD PTR -140[rbp]
	cmp	eax, DWORD PTR -124[rbp]
	jl	.L34
	lea	rax, .LC5[rip]
	mov	QWORD PTR -48[rbp], rax
	lea	rax, .LC6[rip]
	mov	QWORD PTR -40[rbp], rax
	lea	rax, .LC7[rip]
	mov	QWORD PTR -32[rbp], rax
	lea	rax, .LC8[rip]
	mov	QWORD PTR -24[rbp], rax
	lea	rax, .LC9[rip]
	mov	QWORD PTR -16[rbp], rax
	pxor	xmm0, xmm0
	movsd	QWORD PTR -112[rbp], xmm0
	mov	DWORD PTR -128[rbp], 0
	jmp	.L35
.L36:
	mov	eax, DWORD PTR -128[rbp]
	cdqe
	mov	rdx, QWORD PTR -96[rbp+rax*8]
	mov	eax, DWORD PTR -128[rbp]
	cdqe
	mov	rax, QWORD PTR -48[rbp+rax*8]
	movq	xmm0, rdx
	mov	rsi, rax
	lea	rax, .LC10[rip]
	mov	rdi, rax
	mov	eax, 1
	call	printf@PLT
	mov	eax, DWORD PTR -128[rbp]
	cdqe
	movsd	xmm0, QWORD PTR -96[rbp+rax*8]
	movsd	xmm1, QWORD PTR -112[rbp]
	addsd	xmm0, xmm1
	movsd	QWORD PTR -112[rbp], xmm0
	add	DWORD PTR -128[rbp], 1
.L35:
	cmp	DWORD PTR -128[rbp], 4
	jle	.L36
	mov	rax, QWORD PTR -112[rbp]
	movq	xmm0, rax
	lea	rax, .LC11[rip]
	mov	rsi, rax
	lea	rax, .LC10[rip]
	mov	rdi, rax
	mov	eax, 1
	call	printf@PLT
	mov	rax, QWORD PTR -120[rbp]
	movq	xmm0, rax
	lea	rax, .LC12[rip]
	mov	rdi, rax
	mov	eax, 1
	call	printf@PLT
	mov	eax, 0
	mov	rdx, QWORD PTR -8[rbp]
	sub	rdx, QWORD PTR fs:40
	je	.L38
	call	__stack_chk_fail@PLT
.L38:
	leave
	ret
	.size	main, .-main
	.section	.rodata
	.align 8
.LC0:
	.long	-400107883
	.long	1041313291
	.align 4
.LC1:
	.long	1266679808
	.align 4
.LC4:
	.long	1056964608
	.ident	"GCC: (Ubuntu 13.3.0-6ubuntu2~24.04.1) 13.3.0"
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
