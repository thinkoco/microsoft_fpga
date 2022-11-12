	.section .text
	.global _start
	.global main

_start:
	/* set stack pointer */
	lui sp,(0x80010000)>>12

	/* jump to main C code */
	jal ra,main

	/* trap */
	ebreak

