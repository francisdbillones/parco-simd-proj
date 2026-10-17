section .text
bits 64
default rel
global asum_asm
asum_asm:

    mov rax, rdx                ; array pointer (2nd arg)
    mov r8d, ecx                ; N (1st arg, zero-extended) to r8
    xor rcx, rcx

    vxorpd xmm0, xmm0, xmm0     ; clear xmm0 for sum

.LOOP: ; sum of absolute value

    cmp rcx, r8                 ; check i < n
    jge .DONE                   ; if rcx >= r8, jump to done

    mov r9, [rax + 8*rcx]       ; load bits of A[i]
    btr r9, 63                  ; absolute value by clearing sign bit
    vmovq xmm1, r9

    vaddsd xmm0, xmm0, xmm1     ; xmm0 += xmm1

    inc rcx
    jmp .LOOP

.DONE:

    ret
