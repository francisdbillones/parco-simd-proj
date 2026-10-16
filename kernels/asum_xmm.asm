section .data
    align 16
    absmask dq 0x7FFFFFFFFFFFFFFF, 0x7FFFFFFFFFFFFFFF

section .text
bits 64
default rel
global asum_xmm
asum_xmm:

    lea rax, [rcx]              ; pointer to array 
    mov rdx, rdx                
    xor rcx, rcx               

    vxorpd xmm0, xmm0, xmm0     
    vmovdqa xmm2, [absmask]     ; load bitmask

.LOOP:

    vmovupd xmm1, [rax + 8*rcx] ; load 2 doubles 

    vandpd xmm1, xmm1, xmm2     ; 
    vaddpd xmm0, xmm0, xmm1     ; xmm0 += xmm1

    add rcx, 2
    cmp rcx, rdx
    jl .LOOP

    vpermilpd xmm1, xmm0, 1
    vaddsd xmm0, xmm0, xmm1

    ret