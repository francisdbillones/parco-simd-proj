section .data align=16
    align 16
    absmask dq 0x7FFFFFFFFFFFFFFF, 0x7FFFFFFFFFFFFFFF ; 

section .text
bits 64
default rel
global asum_xmm
asum_xmm:

    mov rax, rdx                ; array pointer (2nd arg)
    mov r8d, ecx                ; N (1st arg, zero-extended) to r8
    xor rcx, rcx                

    vxorpd xmm0, xmm0, xmm0     ; clear xmm0 for sum
    vmovdqa xmm2, [absmask]     ; load absmask

    mov r9, r8
    sub r9, 1                   ; r9 = n - 1

.LOOP: ; sum of absolute value

    cmp rcx, r9                 ; check i and i+1 < n
    jge .LEFTOVER               ; if rcx >= r9, jump to leftover

    vmovupd xmm1, [rax + 8*rcx]
    vandpd xmm1, xmm1, xmm2     ; absolute value using mask

    vaddpd xmm0, xmm0, xmm1     ; xmm0 += xmm1

    add rcx, 2
    jmp .LOOP

.LEFTOVER: ; for boundary case when n is odd

    cmp rcx, r8                 ; check if there is leftover element i < n
    jge .DONE                   ; if rcx >= r8 it means array is even then jump to done

    vmovsd xmm1, [rax + 8*rcx]  ; copy leftover element to xmm1 
    vandpd xmm1, xmm1, xmm2     

    vaddsd xmm0, xmm0, xmm1     ; xmm0 += xmm1 (leftover element)

.DONE:

    vpermilpd xmm1, xmm0, 1     ; swap high and low bit
    vaddsd xmm0, xmm0, xmm1     ; add high half to low half

    ret
