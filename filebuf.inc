
; filebuf structure:
; ptr rq 1
; capacity rq 1
; len rq 1
; fd rq 1

; rsi : source
; rcx : count
; r15 : id * 32
; destroys: rax, rcx, rdx, rsi, rdi, r8, r9, r10, r11
macro filebuf_write {

  local back

  mov r8, rsi
  mov r9, rcx
  lea rsi, [filebufs + r15]

  mov rdx, [rsi + 16]
  lea rax, [rdx + rcx]
  cmp rax, [rsi + 8]

  mov r10, back

  ja filebuf_flush

  back:

  mov rdi, [filebufs + r15]
  add rdi, qword [rdi + 16]
  mov rsi, r8
  mov rcx, r9
  cld
  rep movsb

  add qword [filebufs + r15 + 16], r9

}

; al : char
; r15 : id * 32
; destroys : rcx, rdx, rsi, rdi, r8, r10, r11
macro filebuf_write_1 {

  local back

  mov r8, rax
  lea rsi, [filebufs + r15]

  mov rdx, [rsi + 16]
  lea rax, [rdx + 1]
  cmp rax, [rsi + 8]

  mov r10, back
  ja filebuf_flush

  back:

  mov rdi, [filebufs + r15]
  add rdi, qword [rdi + 16]
  mov rax, r8
  mov byte [rdi], al

  inc qword [filebufs + r15 + 16]

}

; ax : chars
; rsi : source
; rcx : count
; r15 : id * 32
; destroys : rbx, rcx, rdx, rsi, rdi, r8, r9, r10, r11
macro filebuf_write_and_2 {

  local back

  mov r8, rsi
  mov r9, rcx
  mov rbx, rax
  lea rsi, [filebufs + r15]

  mov rdx, [rsi + 16]
  lea rax, [rdx + rcx + 2]
  cmp rax, [rsi + 8]

  mov r10, back
  ja filebuf_flush

  back:

  mov rdi, [filebufs + r15]
  add rdi, qword [rdi + 16]
  mov rsi, r8
  mov rcx, r9
  cld
  rep movsb
  mov rax, rbx
  stosw

  add r9, 2
  add qword [filebufs + r15 + 16], r9

}

; al : char
; r15 : id * 32
; destroys : rcx, rdx, rsi, rdi, r8, r10, r11
macro filebuf_write_1_and_skip_n n {

  local back

  mov r8, rax
  lea rsi, [filebufs + r15]

  mov rdx, [rsi + 16]
  lea rax, [rdx + 1 + n]
  cmp rax, [rsi + 8]

  mov r10, back
  ja filebuf_flush

  back:

  mov rdi, [filebufs + r15]
  add rdi, qword [rdi + 16]
  mov rax, r8
  mov byte [rdi], al

  add qword [filebufs + r15 + 16], (1 + n)

}

; al : char
; rbx : chars
; r15 : id * 32
; destroys : rax, rcx, rdx, rsi, rdi, r8, r9, r10, r11
macro filebuf_write_1_and_8 {

  local back

  mov r8, rax
  mov r9, rbx
  lea rsi, [filebufs + r15]

  mov rdx, [rsi + 16]
  lea rax, [rdx + 9]
  cmp rax, [rsi + 8]

  mov r10, back
  ja filebuf_flush

  back:

  mov rdi, [filebufs + r15]
  add rdi, qword [rdi + 16]
  mov rax, r8
  mov byte [rdi], al
  mov rbx, r9
  mov qword [rdi + 1], rbx

  add qword [filebufs + r15 + 16], 9

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

