	.file	"lfs.c"
	.text
	.comm	root_addr,8,8
	.comm	bmutex_pid,1,1
	.comm	u,824,32
	.section	.rodata
.LC0:
	.string	"lfs.c"
.LC1:
	.string	"addr == MYSBRK(0)"
	.align 8
.LC2:
	.string	"(total_size & LFS_PAGEMASK) == 0"
.LC3:
	.string	"root_addr==NULL"
.LC4:
	.string	"p->s_magic==LFS_MAGIC"
	.text
	.globl	lfs_init
	.type	lfs_init, @function
lfs_init:
.LFB2:
	.cfi_startproc
	pushq	%rbp
	.cfi_def_cfa_offset 16
	.cfi_offset 6, -16
	movq	%rsp, %rbp
	.cfi_def_cfa_register 6
	subq	$48, %rsp
	movq	%rdi, -40(%rbp)
	movl	%esi, -44(%rbp)
	movl	%edx, -48(%rbp)
	movl	$0, lfs_error(%rip)
	movq	root_addr(%rip), %rax
	testq	%rax, %rax
	je	.L2
	movl	$114, lfs_error(%rip)
	movl	$-1, %eax
	jmp	.L3
.L2:
	movq	-40(%rbp), %rax
	andl	$4095, %eax
	testq	%rax, %rax
	je	.L4
	movl	$180, lfs_error(%rip)
	movl	$-1, %eax
	jmp	.L3
.L4:
	cmpl	$0, -44(%rbp)
	jne	.L5
	movb	$0, bmutex_pid(%rip)
	movl	$0, %edi
	call	sbrk
	cmpq	%rax, -40(%rbp)
	je	.L6
	movl	$__PRETTY_FUNCTION__.3712, %ecx
	movl	$46, %edx
	movl	$.LC0, %esi
	movl	$.LC1, %edi
	call	__assert_fail
.L6:
	movl	$983552, -20(%rbp)
	movl	$0, %eax
	call	next_alloc_size
	addl	%eax, -20(%rbp)
	movl	-20(%rbp), %eax
	andl	$4095, %eax
	testl	%eax, %eax
	je	.L7
	movl	-20(%rbp), %eax
	addl	$4096, %eax
	andl	$-4096, %eax
	jmp	.L8
.L7:
	movl	-20(%rbp), %eax
.L8:
	movl	%eax, -20(%rbp)
	movl	-20(%rbp), %eax
	andl	$4095, %eax
	testl	%eax, %eax
	je	.L9
	movl	$__PRETTY_FUNCTION__.3712, %ecx
	movl	$51, %edx
	movl	$.LC0, %esi
	movl	$.LC2, %edi
	call	__assert_fail
.L9:
	movl	-20(%rbp), %eax
	cltq
	movq	%rax, %rdi
	call	sbrk
	movq	%rax, -8(%rbp)
	cmpq	$-1, -8(%rbp)
	jne	.L10
	movl	$181, lfs_error(%rip)
	movl	$-1, %eax
	jmp	.L3
.L10:
	movq	-40(%rbp), %rax
	movq	%rax, root_addr(%rip)
	movl	-20(%rbp), %eax
	movl	%eax, %edi
	call	init_superblock
	movq	root_addr(%rip), %rax
	addq	$4, %rax
	movq	%rax, %rdi
	call	nonbiased_lock
	movl	$0, %eax
	call	init_sfile
	movl	$0, %eax
	call	init_freemap
	movl	$0, %eax
	call	init_inodes
	movl	$0, %eax
	call	init_user
	movl	$0, %eax
	call	mkrootdir
	movq	root_addr(%rip), %rax
	addq	$4, %rax
	movq	%rax, %rdi
	call	nonbiased_unlock
	movl	$0, %eax
	jmp	.L3
.L5:
	cmpl	$1, -44(%rbp)
	jne	.L11
	movq	-40(%rbp), %rax
	movq	%rax, -16(%rbp)
	movq	-16(%rbp), %rax
	addq	$4, %rax
	movq	%rax, %rdi
	call	nonbiased_lock
	movq	root_addr(%rip), %rax
	testq	%rax, %rax
	je	.L12
	movl	$__PRETTY_FUNCTION__.3712, %ecx
	movl	$71, %edx
	movl	$.LC0, %esi
	movl	$.LC3, %edi
	call	__assert_fail
.L12:
	movq	-16(%rbp), %rax
	movl	(%rax), %eax
	cmpl	$-1414664191, %eax
	je	.L13
	movl	$__PRETTY_FUNCTION__.3712, %ecx
	movl	$72, %edx
	movl	$.LC0, %esi
	movl	$.LC4, %edi
	call	__assert_fail
.L13:
	movq	-40(%rbp), %rax
	movq	%rax, root_addr(%rip)
	movq	-16(%rbp), %rax
	movzbl	52(%rax), %eax
	cmpb	$63, %al
	jne	.L14
	movl	$183, lfs_error(%rip)
	movq	-16(%rbp), %rax
	addq	$4, %rax
	movq	%rax, %rdi
	call	nonbiased_unlock
	movl	$-1, %eax
	jmp	.L3
.L14:
	movq	-16(%rbp), %rax
	movzbl	52(%rax), %eax
	movb	%al, bmutex_pid(%rip)
	movq	-16(%rbp), %rax
	movzbl	52(%rax), %eax
	leal	1(%rax), %edx
	movq	-16(%rbp), %rax
	movb	%dl, 52(%rax)
	movq	-16(%rbp), %rax
	addq	$4, %rax
	movq	%rax, %rdi
	call	nonbiased_unlock
	movl	$0, %eax
	jmp	.L3
.L11:
	movl	$22, lfs_error(%rip)
	movl	$-1, %eax
.L3:
	leave
	.cfi_def_cfa 7, 8
	ret
	.cfi_endproc
.LFE2:
	.size	lfs_init, .-lfs_init
	.section	.rodata
.LC5:
	.string	"Super block: size = %lu\n"
.LC6:
	.string	"super->s_magic: 0x%08x\n"
.LC7:
	.string	"super->s_nblocks: %d\n"
	.align 8
.LC8:
	.string	"super->s_endaddr (relative): %p\n"
.LC9:
	.string	"super->nproc: %d\n"
.LC10:
	.string	"bmutex_pid: %d\n"
	.text
	.globl	lfs_printsuper
	.type	lfs_printsuper, @function
lfs_printsuper:
.LFB3:
	.cfi_startproc
	pushq	%rbp
	.cfi_def_cfa_offset 16
	.cfi_offset 6, -16
	movq	%rsp, %rbp
	.cfi_def_cfa_register 6
	subq	$16, %rsp
	movq	root_addr(%rip), %rax
	movq	%rax, -8(%rbp)
	movq	-8(%rbp), %rax
	addq	$4, %rax
	movq	%rax, %rdi
	call	nonbiased_lock
	movl	$512, %esi
	movl	$.LC5, %edi
	movl	$0, %eax
	call	printf
	movq	-8(%rbp), %rax
	movl	(%rax), %eax
	movl	%eax, %esi
	movl	$.LC6, %edi
	movl	$0, %eax
	call	printf
	movq	-8(%rbp), %rax
	movl	32(%rax), %eax
	movl	%eax, %esi
	movl	$.LC7, %edi
	movl	$0, %eax
	call	printf
	movq	-8(%rbp), %rax
	movq	40(%rax), %rax
	movq	%rax, %rsi
	movl	$.LC8, %edi
	movl	$0, %eax
	call	printf
	movq	-8(%rbp), %rax
	movzbl	52(%rax), %eax
	movzbl	%al, %eax
	movl	%eax, %esi
	movl	$.LC9, %edi
	movl	$0, %eax
	call	printf
	movzbl	bmutex_pid(%rip), %eax
	movzbl	%al, %eax
	movl	%eax, %esi
	movl	$.LC10, %edi
	movl	$0, %eax
	call	printf
	movq	-8(%rbp), %rax
	addq	$4, %rax
	movq	%rax, %rdi
	call	nonbiased_unlock
	nop
	leave
	.cfi_def_cfa 7, 8
	ret
	.cfi_endproc
.LFE3:
	.size	lfs_printsuper, .-lfs_printsuper
	.globl	init_freemap
	.type	init_freemap, @function
init_freemap:
.LFB4:
	.cfi_startproc
	pushq	%rbp
	.cfi_def_cfa_offset 16
	.cfi_offset 6, -16
	movq	%rsp, %rbp
	.cfi_def_cfa_register 6
	movq	root_addr(%rip), %rax
	addq	$33280, %rax
	movq	%rax, -8(%rbp)
	movl	$0, -12(%rbp)
	jmp	.L18
.L19:
	movl	-12(%rbp), %eax
	movslq	%eax, %rdx
	movq	-8(%rbp), %rax
	addq	%rdx, %rax
	movb	$0, (%rax)
	addl	$1, -12(%rbp)
.L18:
	cmpl	$786431, -12(%rbp)
	jle	.L19
	nop
	popq	%rbp
	.cfi_def_cfa 7, 8
	ret
	.cfi_endproc
.LFE4:
	.size	init_freemap, .-init_freemap
	.globl	init_sfile
	.type	init_sfile, @function
init_sfile:
.LFB5:
	.cfi_startproc
	pushq	%rbp
	.cfi_def_cfa_offset 16
	.cfi_offset 6, -16
	movq	%rsp, %rbp
	.cfi_def_cfa_register 6
	subq	$16, %rsp
	movq	root_addr(%rip), %rax
	addq	$512, %rax
	movq	%rax, -8(%rbp)
	movl	$0, -12(%rbp)
	jmp	.L22
.L23:
	movl	-12(%rbp), %eax
	cltq
	salq	$5, %rax
	movq	%rax, %rdx
	movq	-8(%rbp), %rax
	addq	%rdx, %rax
	movq	%rax, %rdi
	call	biased_lock_init
	movl	-12(%rbp), %eax
	cltq
	salq	$5, %rax
	movq	%rax, %rdx
	movq	-8(%rbp), %rax
	addq	%rdx, %rax
	movb	$0, 8(%rax)
	movl	-12(%rbp), %eax
	cltq
	salq	$5, %rax
	movq	%rax, %rdx
	movq	-8(%rbp), %rax
	addq	%rdx, %rax
	movb	$0, 9(%rax)
	movl	-12(%rbp), %eax
	cltq
	salq	$5, %rax
	movq	%rax, %rdx
	movq	-8(%rbp), %rax
	addq	%rdx, %rax
	movq	$0, 16(%rax)
	movl	-12(%rbp), %eax
	cltq
	salq	$5, %rax
	movq	%rax, %rdx
	movq	-8(%rbp), %rax
	addq	%rdx, %rax
	movl	$0, 24(%rax)
	addl	$1, -12(%rbp)
.L22:
	cmpl	$1023, -12(%rbp)
	jle	.L23
	nop
	leave
	.cfi_def_cfa 7, 8
	ret
	.cfi_endproc
.LFE5:
	.size	init_sfile, .-init_sfile
	.section	.rodata
	.align 8
.LC11:
	.string	"REL2ABS(p->s_endaddr) == MYSBRK(0)"
	.text
	.globl	init_superblock
	.type	init_superblock, @function
init_superblock:
.LFB6:
	.cfi_startproc
	pushq	%rbp
	.cfi_def_cfa_offset 16
	.cfi_offset 6, -16
	movq	%rsp, %rbp
	.cfi_def_cfa_register 6
	pushq	%rbx
	subq	$40, %rsp
	.cfi_offset 3, -24
	movl	%edi, -36(%rbp)
	movq	root_addr(%rip), %rax
	movq	%rax, -24(%rbp)
	movq	-24(%rbp), %rax
	movl	$-1414664191, (%rax)
	movq	-24(%rbp), %rax
	movl	$0, 4(%rax)
	movq	-24(%rbp), %rax
	addq	$8, %rax
	movq	%rax, %rdi
	call	biased_lock_init
	movq	-24(%rbp), %rax
	addq	$16, %rax
	movq	%rax, %rdi
	call	biased_lock_init
	movq	-24(%rbp), %rax
	addq	$24, %rax
	movq	%rax, %rdi
	call	biased_lock_init
	movl	-36(%rbp), %eax
	movslq	%eax, %rdx
	movq	-24(%rbp), %rax
	movq	%rdx, 40(%rax)
	movq	-24(%rbp), %rax
	movq	40(%rax), %rax
	movq	root_addr(%rip), %rdx
	addq	%rdx, %rax
	movq	%rax, %rbx
	movl	$0, %edi
	call	sbrk
	cmpq	%rax, %rbx
	je	.L26
	movl	$__PRETTY_FUNCTION__.3737, %ecx
	movl	$132, %edx
	movl	$.LC0, %esi
	movl	$.LC11, %edi
	call	__assert_fail
.L26:
	movq	-24(%rbp), %rax
	movq	40(%rax), %rax
	shrq	$9, %rax
	movl	%eax, %edx
	movq	-24(%rbp), %rax
	movl	%edx, 32(%rax)
	movq	-24(%rbp), %rax
	movl	$0, 48(%rax)
	movq	-24(%rbp), %rax
	movb	$1, 52(%rax)
	nop
	addq	$40, %rsp
	popq	%rbx
	popq	%rbp
	.cfi_def_cfa 7, 8
	ret
	.cfi_endproc
.LFE6:
	.size	init_superblock, .-init_superblock
	.section	.rodata
	.align 8
.LC12:
	.string	"Root addr: %p, starting addr of inode: %p\n"
	.text
	.globl	init_inodes
	.type	init_inodes, @function
init_inodes:
.LFB7:
	.cfi_startproc
	pushq	%rbp
	.cfi_def_cfa_offset 16
	.cfi_offset 6, -16
	movq	%rsp, %rbp
	.cfi_def_cfa_register 6
	subq	$32, %rsp
	movq	root_addr(%rip), %rax
	addq	$819712, %rax
	movq	%rax, -8(%rbp)
	movq	$0, -16(%rbp)
	movq	root_addr(%rip), %rax
	movq	-8(%rbp), %rdx
	movq	%rax, %rsi
	movl	$.LC12, %edi
	movl	$0, %eax
	call	printf
	movq	-8(%rbp), %rax
	movq	%rax, -16(%rbp)
	jmp	.L29
.L32:
	movq	-16(%rbp), %rax
	movq	%rax, %rdi
	call	biased_lock_init
	movq	-16(%rbp), %rax
	movb	$0, 8(%rax)
	movq	-16(%rbp), %rax
	movw	$0, 10(%rax)
	movq	-16(%rbp), %rax
	movw	$0, 12(%rax)
	movq	-16(%rbp), %rax
	movw	$0, 14(%rax)
	movq	-16(%rbp), %rax
	movl	$0, 16(%rax)
	movq	-16(%rbp), %rax
	movl	$0, 20(%rax)
	movq	-16(%rbp), %rax
	movl	$0, 24(%rax)
	movq	-16(%rbp), %rax
	movw	$0, 28(%rax)
	movq	-16(%rbp), %rax
	movq	$0, 32(%rax)
	movl	$0, -20(%rbp)
	jmp	.L30
.L31:
	movq	-16(%rbp), %rax
	movl	-20(%rbp), %edx
	movslq	%edx, %rdx
	addq	$4, %rdx
	movq	$0, 8(%rax,%rdx,8)
	addl	$1, -20(%rbp)
.L30:
	cmpl	$14, -20(%rbp)
	jle	.L31
	addq	$160, -16(%rbp)
.L29:
	movq	-8(%rbp), %rax
	addq	$163840, %rax
	cmpq	%rax, -16(%rbp)
	jb	.L32
	nop
	leave
	.cfi_def_cfa 7, 8
	ret
	.cfi_endproc
.LFE7:
	.size	init_inodes, .-init_inodes
	.globl	init_user
	.type	init_user, @function
init_user:
.LFB8:
	.cfi_startproc
	pushq	%rbp
	.cfi_def_cfa_offset 16
	.cfi_offset 6, -16
	movq	%rsp, %rbp
	.cfi_def_cfa_register 6
	subq	$16, %rsp
	movl	$u, %edi
	call	biased_lock_init
	movl	$0, u+8(%rip)
	movl	$0, u+12(%rip)
	movl	$0, -4(%rbp)
	jmp	.L35
.L36:
	movl	-4(%rbp), %eax
	cltq
	addq	$2, %rax
	movq	$0, u(,%rax,8)
	addl	$1, -4(%rbp)
.L35:
	cmpl	$99, -4(%rbp)
	jle	.L36
	movq	$0, u+816(%rip)
	nop
	leave
	.cfi_def_cfa 7, 8
	ret
	.cfi_endproc
.LFE8:
	.size	init_user, .-init_user
	.globl	next_alloc_size
	.type	next_alloc_size, @function
next_alloc_size:
.LFB9:
	.cfi_startproc
	pushq	%rbp
	.cfi_def_cfa_offset 16
	.cfi_offset 6, -16
	movq	%rsp, %rbp
	.cfi_def_cfa_register 6
	movl	nblocks.3757(%rip), %eax
	cmpl	$2047, %eax
	jg	.L38
	movl	nblocks.3757(%rip), %eax
	addl	%eax, %eax
	movl	%eax, nblocks.3757(%rip)
.L38:
	movl	nblocks.3757(%rip), %eax
	sall	$9, %eax
	popq	%rbp
	.cfi_def_cfa 7, 8
	ret
	.cfi_endproc
.LFE9:
	.size	next_alloc_size, .-next_alloc_size
	.globl	panic
	.type	panic, @function
panic:
.LFB10:
	.cfi_startproc
	pushq	%rbp
	.cfi_def_cfa_offset 16
	.cfi_offset 6, -16
	movq	%rsp, %rbp
	.cfi_def_cfa_register 6
	subq	$224, %rsp
	movq	%rdi, -216(%rbp)
	movq	%rsi, -168(%rbp)
	movq	%rdx, -160(%rbp)
	movq	%rcx, -152(%rbp)
	movq	%r8, -144(%rbp)
	movq	%r9, -136(%rbp)
	testb	%al, %al
	je	.L41
	movaps	%xmm0, -128(%rbp)
	movaps	%xmm1, -112(%rbp)
	movaps	%xmm2, -96(%rbp)
	movaps	%xmm3, -80(%rbp)
	movaps	%xmm4, -64(%rbp)
	movaps	%xmm5, -48(%rbp)
	movaps	%xmm6, -32(%rbp)
	movaps	%xmm7, -16(%rbp)
.L41:
	movq	%fs:40, %rax
	movq	%rax, -184(%rbp)
	xorl	%eax, %eax
	movl	$8, -208(%rbp)
	movl	$48, -204(%rbp)
	leaq	16(%rbp), %rax
	movq	%rax, -200(%rbp)
	leaq	-176(%rbp), %rax
	movq	%rax, -192(%rbp)
	leaq	-208(%rbp), %rdx
	movq	-216(%rbp), %rax
	movq	%rdx, %rsi
	movq	%rax, %rdi
	call	vprintf
	movl	$1, %edi
	call	exit
	.cfi_endproc
.LFE10:
	.size	panic, .-panic
	.section	.rodata
.LC13:
	.string	"p->nproc > 0"
	.text
	.globl	lfs_handoff_bias_mutex
	.type	lfs_handoff_bias_mutex, @function
lfs_handoff_bias_mutex:
.LFB11:
	.cfi_startproc
	pushq	%rbp
	.cfi_def_cfa_offset 16
	.cfi_offset 6, -16
	movq	%rsp, %rbp
	.cfi_def_cfa_register 6
	subq	$16, %rsp
	movq	root_addr(%rip), %rax
	movq	%rax, -8(%rbp)
	movq	-8(%rbp), %rax
	addq	$4, %rax
	movq	%rax, %rdi
	call	nonbiased_lock
	movq	-8(%rbp), %rax
	movzbl	52(%rax), %eax
	testb	%al, %al
	jne	.L44
	movl	$__PRETTY_FUNCTION__.3765, %ecx
	movl	$204, %edx
	movl	$.LC0, %esi
	movl	$.LC13, %edi
	call	__assert_fail
.L44:
	movq	-8(%rbp), %rax
	movzbl	52(%rax), %eax
	leal	-1(%rax), %edx
	movq	-8(%rbp), %rax
	movb	%dl, 52(%rax)
	movq	-8(%rbp), %rax
	addq	$4, %rax
	movq	%rax, %rdi
	call	nonbiased_unlock
	nop
	leave
	.cfi_def_cfa 7, 8
	ret
	.cfi_endproc
.LFE11:
	.size	lfs_handoff_bias_mutex, .-lfs_handoff_bias_mutex
	.section	.rodata
.LC14:
	.string	"p->nproc < 63"
	.text
	.globl	lfs_reacquire_bias_mutex
	.type	lfs_reacquire_bias_mutex, @function
lfs_reacquire_bias_mutex:
.LFB12:
	.cfi_startproc
	pushq	%rbp
	.cfi_def_cfa_offset 16
	.cfi_offset 6, -16
	movq	%rsp, %rbp
	.cfi_def_cfa_register 6
	subq	$16, %rsp
	movq	root_addr(%rip), %rax
	movq	%rax, -8(%rbp)
	movq	-8(%rbp), %rax
	addq	$4, %rax
	movq	%rax, %rdi
	call	nonbiased_lock
	movq	-8(%rbp), %rax
	movzbl	52(%rax), %eax
	cmpb	$62, %al
	jbe	.L47
	movl	$__PRETTY_FUNCTION__.3769, %ecx
	movl	$213, %edx
	movl	$.LC0, %esi
	movl	$.LC14, %edi
	call	__assert_fail
.L47:
	movq	-8(%rbp), %rax
	movzbl	52(%rax), %eax
	leal	1(%rax), %edx
	movq	-8(%rbp), %rax
	movb	%dl, 52(%rax)
	movq	-8(%rbp), %rax
	addq	$4, %rax
	movq	%rax, %rdi
	call	nonbiased_unlock
	nop
	leave
	.cfi_def_cfa 7, 8
	ret
	.cfi_endproc
.LFE12:
	.size	lfs_reacquire_bias_mutex, .-lfs_reacquire_bias_mutex
	.section	.rodata
	.align 8
	.type	__PRETTY_FUNCTION__.3712, @object
	.size	__PRETTY_FUNCTION__.3712, 9
__PRETTY_FUNCTION__.3712:
	.string	"lfs_init"
	.align 16
	.type	__PRETTY_FUNCTION__.3737, @object
	.size	__PRETTY_FUNCTION__.3737, 16
__PRETTY_FUNCTION__.3737:
	.string	"init_superblock"
	.data
	.align 4
	.type	nblocks.3757, @object
	.size	nblocks.3757, 4
nblocks.3757:
	.long	532632
	.section	.rodata
	.align 16
	.type	__PRETTY_FUNCTION__.3765, @object
	.size	__PRETTY_FUNCTION__.3765, 23
__PRETTY_FUNCTION__.3765:
	.string	"lfs_handoff_bias_mutex"
	.align 16
	.type	__PRETTY_FUNCTION__.3769, @object
	.size	__PRETTY_FUNCTION__.3769, 25
__PRETTY_FUNCTION__.3769:
	.string	"lfs_reacquire_bias_mutex"
	.ident	"GCC: (GNU) 7.3.0"
	.section	.note.GNU-stack,"",@progbits
