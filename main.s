	.file	"main.c"
	.option nopic
	.attribute arch, "rv32i2p0_m2p0_a2p0_f2p0_d2p0_c2p0"
	.attribute unaligned_access, 0
	.attribute stack_align, 16
	.text
	.align	1
	.globl	gg
	.type	gg, @function
gg:
	addi	sp,sp,-32
	sw	s0,28(sp)
	addi	s0,sp,32
	sw	zero,-20(s0)
	li	a5,1
	sw	a5,-24(s0)
	lw	a5,-20(s0)
	addi	a5,a5,4
	sw	a5,-20(s0)
	lw	a5,-24(s0)
	addi	a5,a5,5
	sw	a5,-24(s0)
	nop
	lw	s0,28(sp)
	addi	sp,sp,32
	jr	ra
	.size	gg, .-gg
	.align	1
	.globl	main
	.type	main, @function
main:
	addi	sp,sp,-16
	sw	ra,12(sp)
	sw	s0,8(sp)
	addi	s0,sp,16
	call	gg
.L4:
	j	.L4
	.size	main, .-main
	.ident	"GCC: (GNU) 11.1.0"
