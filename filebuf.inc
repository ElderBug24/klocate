
; filebuf structure:
; ptr rq 1
; capacity rq 1
; len rq 1
; fd rq 1

; TODO: pass in filebuf size as macro constant

; rsi : source
; rcx : count
; r15 : id * 32
; destroys: rax, rcx, rdx, rsi, rdi, r8, r9, r10, r11
macro filebuf_write {

  local .back

  mov r8, rsi
  mov r9, rcx
  lea rsi, [filebufs + r15]

  mov rdx, [rsi + 16]
  lea rax, [rdx + rcx]
  cmp rax, [rsi + 8]

  mov r10, .back

  ja filebuf_flush

  .back:

  mov rdi, [filebufs + r15]
  add rdi, qword [filebufs + r15 + 16]
  mov rsi, r8
  mov rcx, r9
  cld
  rep movsb

  add qword [filebufs + r15 + 16], r9

}

; r15 : id * 32
; destroys : rax, rcx, rdx, rsi, rdi, r10, r11
macro filebuf_write_1_char c {

  local .back

  lea rsi, [filebufs + r15]

  mov rdx, [rsi + 16]
  lea rax, [rdx + 1]
  cmp rax, [rsi + 8]

  mov r10, .back
  ja filebuf_flush

  .back:

  mov rdi, [filebufs + r15]
  add rdi, qword [filebufs + r15 + 16]
  mov byte [rdi], c

  inc qword [filebufs + r15 + 16]

}

; rsi : source
; rcx : count
; r15 : id * 32
; destroys : rax, rcx, rdx, rsi, rdi, r8, r9, r10, r11
macro filebuf_write_m1_and_2_chars cs {

  local .back

  mov r8, rsi
  lea r9, [rcx - 1]
  lea rsi, [filebufs + r15]

  mov rdx, [rsi + 16]
  lea rax, [rdx + rcx + 2]
  cmp rax, [rsi + 8]

  mov r10, .back
  ja filebuf_flush

  .back:

  mov rdi, [filebufs + r15]
  add rdi, qword [filebufs + r15 + 16]
  mov rsi, r8
  mov rcx, r9
  cld
  rep movsb
  mov word [rdi], cs

  add r9, 2
  add qword [filebufs + r15 + 16], r9

}

; r15 : id * 32
; destroys : rax, rcx, rdx, rsi, rdi, r10, r11
macro filebuf_write_1_char_and_skip_n c, n {

  local .back

  lea rsi, [filebufs + r15]

  mov rdx, [rsi + 16]
  lea rax, [rdx + (1 + n)]
  cmp rax, [rsi + 8]

  mov r10, .back
  ja filebuf_flush

  .back:

  mov rdi, [filebufs + r15]
  add rdi, qword [filebufs + r15 + 16]
  mov byte [rdi], c

  add qword [filebufs + r15 + 16], (1 + n)

}

; rbx : chars
; r15 : id * 32
; destroys : rax, rcx, rdx, rsi, rdi, r9, r10, r11
macro filebuf_write_1_char_and_8 c {

  local .back

  mov r9, rbx
  lea rsi, [filebufs + r15]

  mov rdx, [rsi + 16]
  lea rax, [rdx + 9]
  cmp rax, [rsi + 8]

  mov r10, .back
  ja filebuf_flush

  .back:

  mov rdi, [filebufs + r15]
  add rdi, qword [filebufs + r15 + 16]
  mov byte [rdi], c
  mov qword [rdi + 1], r9

  add qword [filebufs + r15 + 16], 9

}

; rax : chars
; rbx : chars
; r15 : id * 32
; destroys : rax, rcx, rdx, rsi, rdi, r8, r9, r10, r11
macro filebuf_write_1_char_and_16_and_1_char_and_skip_16 c1, c2 {

  local .back

  mov r8, rax
  mov r9, rbx
  lea rsi, [filebufs + r15]

  mov rdx, [rsi + 16]
  lea rax, [rdx + 34]
  cmp rax, [rsi + 8]

  mov r10, .back
  ja filebuf_flush

  .back:

  mov rdi, [filebufs + r15]
  add rdi, qword [filebufs + r15 + 16]
  mov byte [rdi], c1
  mov qword [rdi + 1], r8
  mov qword [rdi + 9], r9
  mov byte [rdi + 17], c2

  add qword [filebufs + r15 + 16], 34

}

segment readable executable

  if used filebuf_flush

    ; rsi : buffer struct
    ; rdx : count
    ; destroys : rax, rcx, rsi, rdi, r11
    filebuf_flush:

      mov qword [rsi + 16], 0

      mov rax, __NR_write
      mov rdi, [rsi + 24]
      mov rsi, [rsi]
      syscall

      jmp r10

  end if

