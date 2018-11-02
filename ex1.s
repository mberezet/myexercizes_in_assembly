section .data

EXIT_OK     equ 0
SYS_EXIT    equ 60  ; terminate sys call

qv1   dq      10000
qv2   dq      20000
qres  dq      0

section .text
global  _start

_start:
mov rax,    qword[qv1]
add rax,    qword[qv2]
mov qword[qres], rax

mov rax, SYS_EXIT
mov rdi, EXIT_OK
syscall
