global _start

section .text

_start:
  mov   rax, 60
  mov   rdi, 74
  syscall
