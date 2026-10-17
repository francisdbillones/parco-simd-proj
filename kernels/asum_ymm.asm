section .data align=32
    align 32
    absmask dq 0x7FFFFFFFFFFFFFFF, 0x7FFFFFFFFFFFFFFF, 0x7FFFFFFFFFFFFFFF, 0x7FFFFFFFFFFFFFFF

section .text
bits 64
default rel
global asum_ymm
asum_ymm:

    mov rax, rdx                ; array pointer (2nd arg)
    mov r8d, ecx                ; N (1st arg, zero-extended) to r8
    xor rcx, rcx

    vxorpd ymm0, ymm0, ymm0
    vxorpd ymm3, ymm3, ymm3
    vxorpd ymm4, ymm4, ymm4
    vxorpd ymm5, ymm5, ymm5
    vmovdqa ymm2, [absmask]     ; load absmask

    mov r9, r8
    sub r9, 15                  ; r9 = n - 15

.LOOP16: ; we have lots of ymm registers go brrrrrrrr

    cmp rcx, r9                 ; check i to i+15 < n
    jge .COMBINE                ; if rcx >= r9, jump to combine

    vandpd ymm1, ymm2, [rax + 8*rcx]      ; absolute value using mask
    vaddpd ymm0, ymm0, ymm1
    vandpd ymm1, ymm2, [rax + 8*rcx + 32]
    vaddpd ymm3, ymm3, ymm1
    vandpd ymm1, ymm2, [rax + 8*rcx + 64]
    vaddpd ymm4, ymm4, ymm1
    vandpd ymm1, ymm2, [rax + 8*rcx + 96]
    vaddpd ymm5, ymm5, ymm1

    add rcx, 16
    jmp .LOOP16

.COMBINE: ; sum the 4 accumulators into ymm0

    vaddpd ymm0, ymm0, ymm3
    vaddpd ymm4, ymm4, ymm5
    vaddpd ymm0, ymm0, ymm4

    mov r9, r8
    sub r9, 3                   ; r9 = n - 3

.LOOP4: ; remaining blocks of 4

    cmp rcx, r9                 ; check i to i+3 < n
    jge .REDUCE                 ; if rcx >= r9, jump to reduce

    vandpd ymm1, ymm2, [rax + 8*rcx]      ; absolute value using mask
    vaddpd ymm0, ymm0, ymm1

    add rcx, 4
    jmp .LOOP4

.REDUCE: ; horizontal sum of ymm0 into the low element of xmm0

    vextractf128 xmm1, ymm0, 1  ; upper 2 elements
    vaddpd xmm0, xmm0, xmm1
    vpermilpd xmm1, xmm0, 1     ; swap high and low
    vaddsd xmm0, xmm0, xmm1

.LEFTOVER:

    cmp rcx, r8                 ; check if there is leftover element i < n
    jge .DONE

    vmovsd xmm1, [rax + 8*rcx]  ; copy leftover element to xmm1
    vandpd xmm1, xmm1, xmm2

    vaddsd xmm0, xmm0, xmm1     ; xmm0 += xmm1 (leftover element)

    inc rcx
    jmp .LEFTOVER

.DONE:

    ret
