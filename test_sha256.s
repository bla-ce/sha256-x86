global _start

%include "sha256.inc"

section .data

hash  times 8 dd 0  ; store the result

section .rodata

value1 times 64 db 0
value1_result dd 0xf5a5fd42
              dd 0xd16a2030
              dd 0x2798ef6e
              dd 0xd309979b
              dd 0x43003d23
              dd 0x20d9f0e8
              dd 0xea9831a9
              dd 0x2759fb4b

value2 times 560 db 0xFA
value2_result dd 0xfe958f24
              dd 0xe56761fa
              dd 0xf4559531
              dd 0xc2594c27
              dd 0xa4d449ca
              dd 0x502f1e80
              dd 0x9b7cd7f8
              dd 0x6874b177

empty_result dd 0xe3b0c442
             dd 0x98fc1c14
             dd 0x9afbf4c8
             dd 0x996fb924
             dd 0x27ae41e4
             dd 0x649b934c
             dd 0xa495991b
             dd 0x7852b855

_str db "The quick brown fox jumps over the lazy dog"
str_len equ $ - _str
str_result  dd 0xd7a8fbb3
            dd 0x07d78094
            dd 0x69ca9abc
            dd 0xb0082e4f
            dd 0x8d5651e4
            dd 0x6d3cdb76
            dd 0x2d02d0bf
            dd 0x37c9e592

section .text

_start:
  mov   rdi, value1
  mov   rsi, 64
  mov   rdx, hash
  call  sha256
  test  rax, rax
  jnz   .error

  mov   rdi, hash
  mov   rsi, value1_result
  mov   rcx, 8
  rep   cmpsd
  jne   .error

  mov   rdi, value2
  mov   rsi, 560
  mov   rdx, hash
  call  sha256
  test  rax, rax
  jnz   .error

  mov   rdi, hash
  mov   rsi, value2_result
  mov   rcx, 8
  rep   cmpsd
  jne   .error

  mov   rdi, value2
  mov   rsi, 0
  mov   rdx, hash
  call  sha256
  test  rax, rax
  jnz   .error

  mov   rdi, hash
  mov   rsi, empty_result
  mov   rcx, 8
  rep   cmpsd
  jne   .error

  mov   rdi, _str
  mov   rsi, str_len
  mov   rdx, hash
  call  sha256
  test  rax, rax
  jnz   .error

  mov   rdi, hash
  mov   rsi, str_result
  mov   rcx, 8
  rep   cmpsd
  jne   .error

  mov   rdi, 0
  jmp   .exit

.error:
  mov   rdi, -1

.exit:
  mov   rax, 60
  syscall
