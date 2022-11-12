.text
.global _start

_start:
    j 1f
    nop
    nop
    .word 0
    .word 0
    .word 0
    .word 0
    .word 0
    .word 0
    .word 0
1:
    li x1, 0x7
    li x2, 0x10012008
    sw x1, 0(x2)


    li x3, 0
    li x5, 1
2:
    li x1, 0x55
    li x2, 0x1001200C


    sw x1, 0(x2)
    li x4, 0x170000
3:
    sub x4,x4,x5
    bne x4,x3,3b


    li  x1, 0x00
    li  x2,0x1001200C
    sw  x1,0(x2)

    li  x4,0x170000
4:
    sub x4, x4,x5
    bne x4, x3,4b

    j 2b
    nop
