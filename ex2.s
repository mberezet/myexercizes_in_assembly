; non-uniform idiocy of the fucking intel
;     instruction set.

section .data

EXIT_OK     equ 0
SYS_EXIT    equ 60  ; terminate sys call

qv1   dq 1
qv2   dq -100

section .text
global  _start

_start:

mov rax, [qv2]           ; rax = -100
mov eax, dword[qv2]      ; rax is NOT -100, eax is -100. this dword mov places zeroes to hi bits of rax!
mov ax,  word[qv2]       ; rax is still NOT -100, BUT BOTH eax and ax IS -100. eax hi bits NOT zeroed!

; so basically:  rax and eax targets treated DIFFERNTLY when mov used 
;    to extend value in tgt hi-bits from the shorter src! morons.

movsx rax, word[qv2]      ; rax IS -100
movzx rax, word[qv2]      ; rax IS 65436 as expected (unsigned extending)

mov rax, SYS_EXIT
mov rdi, EXIT_OK
xor rdi, rdi
syscall
