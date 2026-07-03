# sha256-x86

x86 implementation of the sha256 algorithm, as defined in the [Wikipedia](https://en.wikipedia.org/wiki/SHA-2#Pseudocode) page

The file can be copied and used as a library in your x86 projects

## Usage

```assembly
mov   rdi, message      ; pointer to the sequence of bytes to be hashed
mov   rsi, message_len  ; length of the sequence
mov   rdx, hash         ; pointer holding the hashed value
call  sha256
test  rax, rax
jnz   .error
```
