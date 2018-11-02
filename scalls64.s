# ##############################################################################
# How to do syscalls in Lx64   (amd64 model used by 64-bit kernel)
# ##############################################################################
# int 0x80 is only for 32-comp mode and still can be done ...
# Lnx supports backcompatibility on 64-bit ABI.
# NOTE: g++ generates syscall/sysret - not sysenter/sysexit (which is used in 
#	32-bit mode linux to replace (still supported) int 0x80 mechanism).
#
# We call exit() here ( syscall number 60 in 64-bit)
# that can be refered in asm/unistd_64.h  for all 64-bit syscall numbers
# NOTE !!!  syscall numbers differ between 64-bit lnx and 32-bit lnx.
# ##############################################################################

# amd64 arch defines following registers that are mod/extension of i386
# that are understood by the gas :
#
#  %rax,%rdx,%rcx,%rbx,%rsi,%rdi,%rsp,%rbp
# [%eax,%edx,%ecx,%ebx,%esi,%edi,%esp,%ebp]
# 
# %r8-%r15
# ###############################################################################
#
#  as -o scalls64.o  scalls64.s ; ld -o scalls64 ./scalls64.o
#
# ###############################################################################

.section .data

out:
  .equ		SYSwrite,	1
  .equ		SYSexit,	60

  .ascii	"Hello\n"

.section .text

  .global _start

_start:
  nop

  movq $SYSwrite, %rax		# write()
  movq $2,  %rbx		# stderr
  movq $out,%rsi		# buff
  movq $6,  %rdx		# buflen
  syscall

  //  ... learning ...
  movl $1,   %eax 
  movl $2,   %ebx 
  cmp  %eax, %ebx
  jg   CONTINUE

  #ret							# THIS is crash ....

CONTINUE:
  movq $100, %rax
  leaq (%rax,%rax,8), %rdx   # fast multiply by 9(1 cpu cycle!) rax+rax*8
  leaq (,%rax,8), %rdx       # fast multiply by 8(1 cpu cycle!) rax*8

# loop instruction (rcx is counter)
   movq $1000, %rcx
DELAY:
  loop  DELAY
  pause                      # this is to fight terrible performance issue on a CRAP intel architecture !!

  movq $SYSexit, %rax        # exit
  movq $0,       %rdi        # rc code
  syscall
