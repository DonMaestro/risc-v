	.file	"_start.c"
	.option nopic
	.attribute arch, "rv32i2p0_m2p0_a2p0_f2p0_d2p0_c2p0"
	.attribute unaligned_access, 0
	.attribute stack_align, 16
	.text
	.align	1
	.globl	_start
	.type	_start, @function
_start:
	lui	sp,0x2
	call	main
	.size	_start, .-_start
	.ident	"GCC: (GNU) 11.1.0"
