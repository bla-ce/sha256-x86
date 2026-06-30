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
value dq 0

working_hash times 8 dd 0

chunk_example times 64 db 0
chunk_example_result  dd 0xda5698be
                      dd 0x17b9b469
                      dd 0x62335799
                      dd 0x779fbeca
                      dd 0x8ce5d491
                      dd 0xc0d26243
                      dd 0xbafef9ea
                      dd 0x1837a9d8

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
  shl   rax, 2
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
  shl   rax, 2
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
  shl   rax, 2
  mov   r10d, dword [rsp+0x10+rax]

  ; r13d = w[i-7]
  mov   rax, r9
  sub   rax, 7
  shl   rax, 2
  mov   r13d, dword [rsp+0x10+rax]

  ; w[i] = w[i-16] + r11d + w[i-7] + r12d
  mov   edi, r10d
  add   edi, r11d
  add   edi, r13d
  add   edi, r12d

  mov   rax, r9
  shl   rax, 2
  mov   dword [rsp+0x10+rax], edi

  inc   r9
  jmp   .extend_loop

.extend_loop_end:
  ; copy init hash to working hash
  mov   rdi, working_hash
  mov   rsi, h0
  mov   rcx, 8
  rep   movsd

  xor   r9, r9

.compression_loop:
  cmp   r9, 64
  jge   .compression_loop_end

  ; r10d (S1) := (e rightrotate 6) xor (e rightrotate 11) xor (e rightrotate 25)
  ; edi = (e rightrotate 6)
  mov   edi, dword [working_hash+4*4]
  ror   edi, 6

  ; esi = (e rightrotate 11)
  mov   esi, dword [working_hash+4*4]
  ror   esi, 11

  ; edx = (e rightrotate 25)
  mov   edx, dword [working_hash+4*4]
  ror   edx, 25

  xor   edi, esi
  xor   edi, edx
  mov   r10d, edi

  ; r11d (ch) := (e and f) xor ((not e) and g)
  ; edi = (not e)
  mov   edi, dword [working_hash+4*4]
  not   edi

  ; edi = edi and g
  mov   edx, dword [working_hash+6*4]
  and   edi, edx

  ; esi = e and f
  mov   edx, dword [working_hash+4*4]
  and   edx, dword [working_hash+5*4]

  mov   r11d, edi
  xor   r11d, edx

  ; r10d (temp1) := h + r10d + ch + k[i] + w[i]
  add   r10d, dword [working_hash+7*4]
  add   r10d, r11d

  mov   rax, r9
  shl   rax, 2
  add   r10d, dword [k+rax]
  add   r10d, dword [rsp+0x10+rax]

  ; r11d (S0) := (a rightrotate 2) xor (a rightrotate 13) xor (a rightrotate 22)
  ; edi = (e rightrotate 6)
  mov   edi, dword [working_hash]
  ror   edi, 2

  ; esi = (e rightrotate 11)
  mov   esi, dword [working_hash]
  ror   esi, 13

  ; edx = (e rightrotate 25)
  mov   edx, dword [working_hash]
  ror   edx, 22

  xor   edi, esi
  xor   edi, edx
  mov   r11d, edi

  ; edi (maj) := (a and b) xor (a and c) xor (b and c)
  mov   edi, dword [working_hash]
  and   edi, dword [working_hash+4]

  mov   esi, dword [working_hash]
  and   esi, dword [working_hash+2*4]

  mov   edx, dword [working_hash+4]
  and   edx, dword [working_hash+2*4]

  xor   edi, esi
  xor   edi, edx

  ; r11d(temp2) := S0 + maj
  add   r11d, edi

  ; h := g
  mov   edi, dword [working_hash+6*4]
  mov   dword [working_hash+7*4], edi

  ; g := f
  mov   edi, dword [working_hash+5*4]
  mov   dword [working_hash+6*4], edi

  ; f := e
  mov   edi, dword [working_hash+4*4]
  mov   dword [working_hash+5*4], edi

  ; e := d + temp1
  mov   edi, dword [working_hash+3*4]
  add   edi, r10d
  mov   dword [working_hash+4*4], edi

  ; d := c
  mov   edi, dword [working_hash+2*4]
  mov   dword [working_hash+3*4], edi

  ; c := b
  mov   edi, dword [working_hash+4]
  mov   dword [working_hash+2*4], edi

  ; b := a
  mov   edi, dword [working_hash]
  mov   dword [working_hash+4], edi

  ; a := temp1 + temp2
  add   r10d, r11d
  mov   dword [working_hash], r10d

  inc   r9
  jmp   .compression_loop
.compression_loop_end:

  ; TODO: in a loop
  ; Add the compressed chunk to the current hash value
  mov   rax, [rsp+0x8]

  ; h0 := h0 + a
  mov   edi, dword [working_hash]
  add   dword [rax], edi

  ; h1 := h1 + b
  mov   edi, dword [working_hash+4]
  add   dword [rax+4], edi

  ; h2 := h2 + c
  mov   edi, dword [working_hash+2*4]
  add   dword [rax+2*4], edi

  ; h3 := h3 + d
  mov   edi, dword [working_hash+3*4]
  add   dword [rax+3*4], edi

  ; h4 := h4 + e
  mov   edi, dword [working_hash+4*4]
  add   dword [rax+4*4], edi

  ; h5 := h5 + f
  mov   edi, dword [working_hash+5*4]
  add   dword [rax+5*4], edi

  ; h6 := h6 + g
  mov   edi, dword [working_hash+6*4]
  add   dword [rax+6*4], edi

  ; h7 := h7 + h
  mov   edi, dword [working_hash+7*4]
  add   dword [rax+7*4], edi

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

  ; init hash
  mov   rdi, hash
  mov   rsi, h0
  mov   rcx, 8
  rep   movsd

  ; example to test process_chunk
  mov   rdi, chunk_example
  mov   rsi, hash
  call  _sha256_process_chunk
  test  rax, rax
  jnz   .error

  mov   rdi, hash
  mov   rsi, chunk_example_result
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
