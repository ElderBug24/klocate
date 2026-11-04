
; filebuf structure:
; ptr rq 1
; len rq 1
; fd rq 1

; TODO: pass in filebuf size as macro constant

; rsi : source
; rcx : count
; r15 : id * 32
; destroys: rax, rcx, rdx, rsi, rdi, r8, r9, r10, r11
macro filebuf_write cap {

  local .back

  mov r8, rsi
  mov r9, rcx
  lea rsi, [filebufs + r15]

  mov rdx, [filebufs + r15 + 8]
  lea rax, [rdx + rcx]
  cmp rax, cap

  mov r10, .back

  ja filebuf_flush

  .back:

  mov rdi, [filebufs + r15]
  add rdi, qword [filebufs + r15 + 8]
  mov rsi, r8
  mov rcx, r9
  cld
  rep movsb

  add qword [filebufs + r15 + 8], r9

}

; r15 : id * 32
; destroys : rax, rcx, rdx, rsi, rdi, r10, r11
macro filebuf_write_1_char c, cap {

  local .back

  lea rsi, [filebufs + r15]

  mov rdx, [filebufs + r15 + 8]
  lea rax, [rdx + 1]
  cmp rax, cap

  mov r10, .back
  ja filebuf_flush

  .back:

  mov rdi, [filebufs + r15]
  add rdi, qword [filebufs + r15 + 8]
  mov byte [rdi], c

  inc qword [filebufs + r15 + 8]

}

; rsi : source
; rcx : count
; r15 : id * 32
; destroys : rax, rcx, rdx, rsi, rdi, r8, r9, r10, r11
macro filebuf_write_m1_and_2_chars cs, cap {

  local .back

  mov r8, rsi
  lea r9, [rcx - 1]
  lea rsi, [filebufs + r15]

  mov rdx, [filebufs + r15 + 8]
  lea rax, [rdx + rcx + 2]
  cmp rax, cap

  mov r10, .back
  ja filebuf_flush

  .back:

  mov rdi, [filebufs + r15]
  add rdi, qword [filebufs + r15 + 8]
  mov rsi, r8
  mov rcx, r9
  cld
  rep movsb
  mov word [rdi], cs

  add r9, 2
  add qword [filebufs + r15 + 8], r9

}

; r15 : id * 32
; destroys : rax, rcx, rdx, rsi, rdi, r10, r11
macro filebuf_write_1_char_and_skip_n c, n, cap {

  local .back

  lea rsi, [filebufs + r15]

  mov rdx, [filebufs + r15 + 8]
  lea rax, [rdx + (1 + n)]
  cmp rax, cap

  mov r10, .back
  ja filebuf_flush

  .back:

  mov rdi, [filebufs + r15]
  add rdi, qword [filebufs + r15 + 8]
  mov byte [rdi], c

  add qword [filebufs + r15 + 8], (1 + n)

}

; rbx : chars
; r15 : id * 32
; destroys : rax, rcx, rdx, rsi, rdi, r9, r10, r11
macro filebuf_write_1_char_and_8 c, cap {

  local .back

  mov r9, rbx
  lea rsi, [filebufs + r15]

  mov rdx, [filebufs + r15 + 8]
  lea rax, [rdx + 9]
  cmp rax, cap

  mov r10, .back
  ja filebuf_flush

  .back:

  mov rdi, [filebufs + r15]
  add rdi, qword [filebufs + r15 + 8]
  mov byte [rdi], c
  mov qword [rdi + 1], r9

  add qword [filebufs + r15 + 8], 9

}

; rax : chars
; rbx : chars
; r15 : id * 32
; destroys : rax, rcx, rdx, rsi, rdi, r8, r9, r10, r11
macro filebuf_write_1_char_and_16_and_1_char_and_skip_16 c1, c2, cap {

  local .back

  mov r8, rax
  mov r9, rbx
  lea rsi, [filebufs + r15]

  mov rdx, [filebufs + r15 + 8]
  lea rax, [rdx + 34]
  cmp rax, cap

  mov r10, .back
  ja filebuf_flush

  .back:

  mov rdi, [filebufs + r15]
  add rdi, qword [filebufs + r15 + 8]
  mov byte [rdi], c1
  mov qword [rdi + 1], r8
  mov qword [rdi + 9], r9
  mov byte [rdi + 17], c2

  add qword [filebufs + r15 + 8], 34

}

segment readable executable

  if used filebuf_flush

    ; rsi : buffer struct
    ; rdx : count
    ; destroys : rax, rcx, rsi, rdi, r11
    filebuf_flush:

      mov qword [rsi + 8], 0

      mov eax, __NR_write
      mov rdi, [rsi + 16]
      mov rsi, [rsi]
      syscall

      jmp r10

  end if

