
; filebuf structure:
;   ptr rq 1
;   len rq 1
;   fd  rq 1

_filebuf_ptr_offset equ 0
_filebuf_len_offset equ 8
_filebuf_fd_offset  equ 16

_filebuf_nocheck_buffer_size equ 64

; TODO: parallelize writes

; rsi : source
; rcx : count
; r15 : id * 32
; destroys: rax, rcx, rdx, rsi, rdi, r8, r9, r10, r11
macro filebuf_write cap {

  local .back

  mov r8, rsi
  mov r9, rcx

  mov rdx, qword [filebufs + r15 + _filebuf_len_offset]
  lea rax, [rdx + rcx]
  cmp rax, (cap - _filebuf_nocheck_buffer_size)

  mov r10, .back

  ja filebuf_flush_label

  .back:

  mov rdi, qword [filebufs + r15 + _filebuf_ptr_offset]
  add rdi, qword [filebufs + r15 + _filebuf_len_offset]
  mov rsi, r8
  mov rcx, r9
  rep movsb

  add qword [filebufs + r15 + _filebuf_len_offset], r9

}

; rsi : source
; rcx : count
; r15 : id * 32
; destroys: rax, rcx, rsi, rdi
macro filebuf_write_nocheck {

  mov rax, rcx
  mov rdi, qword [filebufs + r15 + _filebuf_ptr_offset]
  add rdi, qword [filebufs + r15 + _filebuf_len_offset]
  rep movsb

  add qword [filebufs + r15 + _filebuf_len_offset], rax

}

; r15 : id * 32
; destroys : rax, rcx, rdx, rsi, rdi, r10, r11
macro filebuf_write_1_char c, cap {

  local .back

  mov rdx, qword [filebufs + r15 + _filebuf_len_offset]
  lea rax, [rdx + 1]
  cmp rax, (cap - _filebuf_nocheck_buffer_size)

  mov r10, .back
  ja filebuf_flush_label

  .back:

  mov rdi, qword [filebufs + r15 + _filebuf_ptr_offset]
  add rdi, qword [filebufs + r15 + _filebuf_len_offset]
  mov byte [rdi], c

  inc qword [filebufs + r15 + _filebuf_len_offset]

}

; r15 : id * 32
; destroys : rsi, rdi
macro filebuf_write_1_char_nocheck c {

  mov rdi, qword [filebufs + r15 + _filebuf_ptr_offset]
  add rdi, qword [filebufs + r15 + _filebuf_len_offset]
  mov byte [rdi], c

  inc qword [filebufs + r15 + _filebuf_len_offset]

}

; rsi : source
; rcx : count
; r15 : id * 32
; destroys : rax, rcx, rdx, rsi, rdi, r8, r9, r10, r11
macro filebuf_write_m1_and_2_chars cs, cap {

  local .back

  mov r8, rsi
  lea r9, [rcx - 1]

  mov rdx, qword [filebufs + r15 + _filebuf_len_offset]
  lea rax, [rdx + rcx + 2]
  cmp rax, (cap - _filebuf_nocheck_buffer_size)

  mov r10, .back
  ja filebuf_flush_label

  .back:

  mov rdi, qword [filebufs + r15 + _filebuf_ptr_offset]
  add rdi, qword [filebufs + r15 + _filebuf_len_offset]
  mov rsi, r8
  mov rcx, r9
  rep movsb
  mov word [rdi], cs

  add r9, 2
  add qword [filebufs + r15 + _filebuf_len_offset], r9

}

; r15 : id * 32
; destroys : rax, rcx, rdx, rsi, rdi, r10, r11
macro filebuf_write_1_char_and_skip_n c, n, cap {

  local .back

  mov rdx, qword [filebufs + r15 + _filebuf_len_offset]
  lea rax, [rdx + (1 + n)]
  cmp rax, (cap - _filebuf_nocheck_buffer_size)

  mov r10, .back
  ja filebuf_flush_label

  .back:

  mov rdi, qword [filebufs + r15 + _filebuf_ptr_offset]
  add rdi, qword [filebufs + r15 + _filebuf_len_offset]
  mov byte [rdi], c

  add qword [filebufs + r15 + _filebuf_len_offset], (1 + n)

}

; r15 : id * 32
; destroys : rsi, rdi
macro filebuf_write_1_char_and_skip_n_nocheck c, n {

  mov rdi, qword [filebufs + r15 + _filebuf_ptr_offset]
  add rdi, qword [filebufs + r15 + _filebuf_len_offset]
  mov byte [rdi], c

  add qword [filebufs + r15 + _filebuf_len_offset], (1 + n)

}

; rbx : chars
; r15 : id * 32
; destroys : rax, rcx, rdx, rsi, rdi, r9, r10, r11
macro filebuf_write_1_char_and_8 c, cap {

  local .back

  mov r9, rbx

  mov rdx, qword [filebufs + r15 + _filebuf_len_offset]
  lea rax, [rdx + 9]
  cmp rax, (cap - _filebuf_nocheck_buffer_size)

  mov r10, .back
  ja filebuf_flush_label

  .back:

  mov rdi, qword [filebufs + r15 + _filebuf_ptr_offset]
  add rdi, qword [filebufs + r15 + _filebuf_len_offset]
  mov byte [rdi], c
  mov qword [rdi + 1], r9

  add qword [filebufs + r15 + _filebuf_len_offset], 9

}

; rax : chars
; rbx : chars
; r15 : id * 32
; destroys : rax, rcx, rdx, rsi, rdi, r8, r9, r10, r11
macro filebuf_write_1_char_and_16_and_1_char_and_skip_16 c1, c2, cap {

  local .back

  mov r8, rax
  mov r9, rbx

  mov rdx, qword [filebufs + r15 + _filebuf_len_offset]
  lea rax, [rdx + 34]
  cmp rax, (cap - _filebuf_nocheck_buffer_size)

  mov r10, .back
  ja filebuf_flush_label

  .back:

  mov rdi, qword [filebufs + r15 + _filebuf_ptr_offset]
  add rdi, qword [filebufs + r15 + _filebuf_len_offset]
  mov byte [rdi], c1
  mov qword [rdi + 1], r8
  mov qword [rdi + 9], r9
  mov byte [rdi + 17], c2

  add qword [filebufs + r15 + _filebuf_len_offset], 34

}

; rax : chars
; rbx : chars
; r15 : id * 32
; destroys : rdi
macro filebuf_write_1_char_and_16_and_1_char_and_skip_16_nocheck c1, c2 {

  mov rdi, qword [filebufs + r15 + _filebuf_ptr_offset]
  add rdi, qword [filebufs + r15 + _filebuf_len_offset]
  mov byte [rdi], c1
  mov qword [rdi + 1], rax
  mov qword [rdi + 9], rbx
  mov byte [rdi + 17], c2

  add qword [filebufs + r15 + _filebuf_len_offset], 34

}

; rdx : count
; destroys : rax, rcx, rdx, rsi, rdi, r11
macro filebuf_flush buffer {

  local .loop

  .loop:

    mov eax, __NR_write
    mov rdi, qword [buffer + _filebuf_fd_offset]
    mov rsi, qword [buffer + _filebuf_ptr_offset]
    syscall

    sub rdx, rax
    jnz .loop

  mov qword [buffer + _filebuf_len_offset], 0

}

segment readable executable

  if used filebuf_flush_label

    ; rdx : count
    ; r15 : id * 32
    ; destroys : rax, rcx, rdx, rsi, rdi, r11
    filebuf_flush_label:

      filebuf_flush (filebufs + r15)

      jmp r10

  end if

