@echo off
mkdir objs 2>nul
nasm -f win64 kernels\asum_asm.asm -o objs\asum_asm.obj
nasm -f win64 kernels\asum_xmm.asm -o objs\asum_xmm.obj
nasm -f win64 kernels\asum_ymm.asm -o objs\asum_ymm.obj
cl /Od /Zi /c kernels\asum.c /Foobjs\asum.obj
cl /Od /Zi main.c objs\asum.obj objs\asum_xmm.obj /Fomain.obj /Feasum_d.exe
