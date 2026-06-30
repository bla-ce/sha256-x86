global _start

section .rodata

; initial hash values
h0 dd 0x6a09e667
h1 dd 0xbb67ae85
h2 dd 0x3c6ef372
h3 dd 0xa54ff53a
h4 dd 0x510e527f
h5 dd 0x9b05688c
h6 dd 0x1f83d9ab
h7 dd 0x5be0cd19

k dd 0x428a2f98, 0x71374491, 0xb5c0fbcf, 0xe9b5dba5, 0x3956c25b, 0x59f111f1, 0x923f82a4, 0xab1c5ed5,
  dd 0xd807aa98, 0x12835b01, 0x243185be, 0x550c7dc3, 0x72be5d74, 0x80deb1fe, 0x9bdc06a7, 0xc19bf174,
  dd 0xe49b69c1, 0xefbe4786, 0x0fc19dc6, 0x240ca1cc, 0x2de92c6f, 0x4a7484aa, 0x5cb0a9dc, 0x76f988da,
  dd 0x983e5152, 0xa831c66d, 0xb00327c8, 0xbf597fc7, 0xc6e00bf3, 0xd5a79147, 0x06ca6351, 0x14292967,
  dd 0x27b70a85, 0x2e1b2138, 0x4d2c6dfc, 0x53380d13, 0x650a7354, 0x766a0abb, 0x81c2c92e, 0x92722c85,
  dd 0xa2bfe8a1, 0xa81a664b, 0xc24b8b70, 0xc76c51a3, 0xd192e819, 0xd6990624, 0xf40e3585, 0x106aa070,
  dd 0x19a4c116, 0x1e376c08, 0x2748774c, 0x34b0bcb5, 0x391c0cb3, 0x4ed8aa4a, 0x5b9cca4f, 0x682e6ff3,
  dd 0x748f82ee, 0x78a5636f, 0x84c87814, 0x8cc70208, 0x90befffa, 0xa4506ceb, 0xbef9a3f7, 0xc67178f2

section .data
hash  times 8 dd 0  ; store the result
value db 0

chunk_example times 64 db 0

section .text
; processes a 512-bit chunk
; @param  rdi: pointer to the chunk
; @param  rsi: pointer to the hash
; @return rax: return code
_sha256_process_chunk:
  sub   rsp, 0x10+256  ; entry message schedule array w 64 * 32bit words

  ; STACK USAGE
  ; [rsp]       -> pointer to the chunk
  ; [rsp+0x8]   -> pointer to the hash
  ; [rsp+0x10]  -> w

  mov   [rsp], rdi
  mov   [rsp+0x8], rsi

  test  rdi, rdi
  jz    .error

  test  rsi, rsi
  jz    .error

  ; copy chunk into first 16 words of w
  lea   rdi, [rsp+0x10]
  mov   rsi, [rsp]
  mov   rcx, 16
  rep   movsd

  ; extend the first 16 words into the remaining 48 words w[16..63] of the message schedule array
  mov   r9, 16

.extend_loop:
  cmp   r9, 64
  jge   .extend_loop_end

  ; r9d = w[i-15]
  mov   rax, r9
  sub   rax, 15
  mov   r10d, dword [rsp+0x10+rax]

  ; edi = (w[i-15] rightrotate 7)
  mov   edi, r10d
  ror   edi, 7

  ; esi = (w[i-15] rightrotate 18)
  mov   esi, r10d
  ror   esi, 18

  ; edx = (w[i-15] rightshift 3)
  mov   edx, r10d
  shr   edx, 3

  ; r11d = edi xor esi xor edx
  xor   edi, esi
  xor   edi, edx
  mov   r11d, edi

  ; r10d = w[i-2]
  mov   rax, r9
  sub   rax, 2
  mov   r10d, dword [rsp+0x10+rax]

  ; edi = (w[i-2] rightrotate 17)
  mov   edi, r10d
  ror   edi, 17

  ; esi = (w[i-2] rightrotate 19)
  mov   esi, r10d
  ror   esi, 19

  ; edx = (w[i-2] rightshift 10)
  mov   edi, r10d
  shr   edi, 10

  ; r12d = edi xor esi xor edx
  xor   edi, esi
  xor   edi, edx
  mov   r12d, edi

  ; r10d = w[i-16]
  mov   rax, r9
  sub   rax, 16
  mov   r10d, dword [rsp+0x10+rax]

  ; r13d = w[i-7]
  mov   rax, r9
  sub   rax, 7
  mov   r13d, dword [rsp+0x10+rax]

  ; w[i] = w[i-16] + r11d + w[i-7] + r12d
  mov   edi, r10d
  add   edi, r11d
  add   edi, r13d
  add   edi, r12d

  mov   dword [rsp+0x10+r9], edi

  inc   r9
  jmp   .extend_loop

.extend_loop_end:

  xor   r9, r9

.compression_loop:
  cmp   r9, 64
  jge   .compression_loop_end


  inc   r9
  jmp   .compression_loop
.compression_loop_end:

  mov   rax, 0
  jmp   .return

.error:
  mov   rax, -1

.return:
  add   rsp, 0x10+256
  ret

; hashes the sequence of bytes in rdi using sha256 algorithm
; @param  rdi: pointer to the sequence of bytes
; @param  rsi: length of the sequence
; @param  rdx: pointer to the hash
; @return rax: return code
sha256:
  sub   rsp, 0x18

  ; STACK USAGE
  ; [rsp]       -> pointer to the sequence of bytes
  ; [rsp+0x8]   -> length of the sequence
  ; [rsp+0x10]  -> pointer to the hash

  mov   [rsp], rdi
  mov   [rsp+0x8], rsi
  mov   [rsp+0x10], rdx

  test  rdi, rdi
  jz    .error

  test  rsi, rsi
  js    .error

  test  rdx, rdx
  jz    .error

  mov   rax, 0
  jmp   .return

.error:
  mov   rax, -1

.return:
  add   rsp, 0x18
  ret

_start:
  mov   rdi, value
  mov   rsi, 0
  mov   rdx, hash
  call  sha256
  test  rax, rax
  jnz   .error

  ; example to test process_chunk
  mov   rdi, chunk_example
  mov   rsi, hash
  call  _sha256_process_chunk
  test  rax, rax
  jnz   .error

  mov   rdi, 0
  jmp   .exit

.error:
  mov   rdi, -1

.exit:
  mov   rax, 60
  syscall
