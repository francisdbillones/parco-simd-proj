@echo off
mkdir objs 2>nul
nasm -f win64 kernels\asum_asm.asm -o objs\asum_asm.obj
nasm -f win64 kernels\asum_xmm.asm -o objs\asum_xmm.obj
nasm -f win64 kernels\asum_ymm.asm -o objs\asum_ymm.obj
cl /O2 /c kernels\asum.c /Foobjs\asum.obj
cl /O2 main.c objs\asum.obj objs\asum_xmm.obj objs\asum_ymm.obj /Foobjs\main.obj /Feasum_r.exe
