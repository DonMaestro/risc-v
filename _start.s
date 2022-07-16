	.file	"_start.c"
	.option nopic
	.attribute arch, "rv32i2p1"
	.attribute unaligned_access, 0
	.attribute stack_align, 16
	.text
	.align	1
	.globl	_start
	.type	_start, @function
_start:
	lui	sp,0x2
	tail	main
	.size	_start, .-_start
	.ident	"GCC: (GNU) 11.1.0"
