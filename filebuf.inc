
macro filebuf_declare name, size {

  segment readable writeable

    filebuf_size_#name = size
    filebuf_len_#name rq 1
    filebuf_fd_#name rq 1
    filebuf_buffer_#name rb size
    filebuf_header_#name = filebuf_len_#name

}

; rsi : source
; rcx : count
; destroys : rax, rcx, rdx, rsi, rdi, r8, r9, r10, r11
macro filebuf_write name {

  local back

  mov r8, rsi
  mov r9, rcx
  mov rsi, filebuf_buffer_#name

  mov rdx, [filebuf_len_#name]
  lea rax, [rdx + rcx]
  cmp rax, filebuf_size_#name

  lea r10, [back]
  ja filebuf_flush

  back:

  mov rsi, r8
  mov rdi, filebuf_buffer_#name
  add rdi, qword [filebuf_len_#name]
  mov rcx, r9
  cld
  rep movsb

  add qword [filebuf_len_#name], r9

}

; al : char
; destroys : rax, rcx, rsi, rdi, r8, r10, r11
macro filebuf_write_1 name {

  local back

  mov r8, rax
  mov rsi, filebuf_buffer_#name

  cmp [filebuf_len_#name], filebuf_size_#name

  lea r10, [back]
  je filebuf_flush

  back:

  mov rax, r8
  mov rdi, filebuf_buffer_#name
  add rdi, qword [filebuf_len_#name]
  mov byte [rdi], al

  inc qword [filebuf_len_#name]

}

; ax : chars
; destroys : rax, rcx, rsi, rdi, r8, r10, r11
macro filebuf_write_2 name {

  local back

  mov r8, rax
  mov rsi, filebuf_buffer_#name

  cmp [filebuf_len_#name], (filebuf_size_#name - 1)

  lea r10, [back]
  jae filebuf_flush

  back:

  mov rax, r8
  mov rdi, filebuf_buffer_#name
  add rdi, qword [filebuf_len_#name]
  mov word [rdi], ax

  add qword [filebuf_len_#name], 2

}

; eax : chars
; destroys : rax, rcx, rsi, rdi, r8, r10, r11
macro filebuf_write_4 name {

  local back

  mov r8, rax
  mov rsi, filebuf_buffer_#name

  cmp [filebuf_len_#name], (filebuf_size_#name - 3)

  lea r10, [back]
  jae filebuf_flush

  back:

  mov rax, r8
  mov rdi, filebuf_buffer_#name
  add rdi, qword [filebuf_len_#name]
  mov dword [rdi], eax

  add qword [filebuf_len_#name], 4

}

; rax : chars
; destroys : rax, rcx, rsi, rdi, r8, r10, r11
macro filebuf_write_8 name {

  local back

  mov r8, rax
  mov rsi, filebuf_buffer_#name

  cmp [filebuf_len_#name], (filebuf_size_#name - 7)

  lea r10, [back]
  jae filebuf_flush

  back:

  mov rax, r8
  mov rdi, filebuf_buffer_#name
  add rdi, qword [filebuf_len_#name]
  mov qword [rdi], rax

  add qword [filebuf_len_#name], 8

}

; ax : chars
; rsi : source
; rcx : count
macro filebuf_write_and_2 name {

  local back

  mov r8, rsi
  mov r9, rcx
  mov rbx, rax
  mov rsi, filebuf_buffer_#name

  mov rdx, [filebuf_len_#name]
  lea rax, [rdx + rcx + 2]
  cmp rax, filebuf_size_#name

  lea r10, [back]
  ja filebuf_flush

  back:

  mov rsi, r8
  mov rdi, filebuf_buffer_#name
  add rdi, qword [filebuf_len_#name]
  mov rcx, r9
  cld
  rep movsb
  mov rax, rbx
  stosw

  add r9, 2
  add qword [filebuf_len_#name], r9

}

segment readable executable

  if used filebuf_flush

    ; rsi : buffer
    ; rdx : count
    ; destroys : rax, r11
    filebuf_flush:

      mov qword [rsi - 16], 0

      mov rax, __NR_write
      mov rdi, [rsi - 8]
      syscall

      jmp r10

  end if

  if used filebuf_flush_fn

    ; rsi : buffer
    ; rdx : count
    ; destroys : rax, r11
    filebuf_flush_fn:

      mov qword [rsi - 16], 0

      mov rax, __NR_write
      mov rdi, [rsi - 8]
      syscall

      ret

  end if

  if used filebuf_write_fn

    ; rsi : source
    ; rdi : buffer
    ; rbx : size
    ; rcx : count
    ; destroys : rax, rcx, rdx, rsi, rdi, r8, r9, r10, r11
    filebuf_write_fn:

      mov r8, rsi
      mov r9, rcx
      mov rsi, rdi

      mov rdx, [rdi - 16]
      lea rax, [rdx + rcx]
      cmp rax, rbx

      lea r10, [filebuf_write_fn_back]
      ja filebuf_flush

      filebuf_write_fn_back:

      mov rdi, rsi
      mov rsi, r8
      mov r8, rdi
      add rdi, qword [rdi - 16]
      mov rcx, r9
      cld
      rep movsb

      add qword [r8 - 16], r9

      ret

  end if

  if used filebuf_write_1_fn

    ; al : char
    ; rdi : buffer
    ; rbx : size
    filebuf_write_1_fn:

      mov r8, rax
      mov rsi, rdi

      cmp [rdi - 16], rbx

      lea r10, [filebuf_write_1_fn_back]
      je filebuf_flush

      filebuf_write_1_fn_back:

      mov rax, r8
      mov rdi, rsi
      mov r8, rdi
      add rdi, qword [rdi - 16]
      mov byte [rdi], al

      inc qword [r8 - 16]

      ret

  end if

  if used filebuf_write_2_fn

    ; ax : chars
    ; rdi : buffer
    ; rbx : size
    filebuf_write_2_fn:

      mov r8, rax
      mov rsi, rdi

      dec rbx
      cmp [rdi - 16], rbx

      lea r10, [filebuf_write_2_fn_back]
      jae filebuf_flush

      filebuf_write_2_fn_back:

      mov rax, r8
      mov rdi, rsi
      mov r8, rdi
      add rdi, qword [rdi - 16]
      mov word [rdi], ax

      add qword [r8 - 16], 2

      ret

  end if

  if used filebuf_write_4_fn

    ; eax : chars
    ; rdi : buffer
    ; rbx : size
    filebuf_write_4_fn:

      mov r8, rax
      mov rsi, rdi

      sub rbx, 3
      cmp [rdi - 16], rbx

      lea r10, [filebuf_write_2_fn_back]
      jae filebuf_flush

      filebuf_write_4_fn_back:

      mov rax, r8
      mov rdi, rsi
      mov r8, rdi
      add rdi, qword [rdi - 16]
      mov dword [rdi], eax

      add qword [r8 - 16], 4

      ret

  end if

  if used filebuf_write_8_fn

    ; rax : chars
    ; rdi : buffer
    ; rbx : size
    filebuf_write_8_fn:

      mov r8, rax
      mov rsi, rdi

      sub rbx, 7
      cmp [rdi - 16], rbx

      lea r10, [filebuf_write_2_fn_back]
      jae filebuf_flush

      filebuf_write_8_fn_back:

      mov rax, r8
      mov rdi, rsi
      mov r8, rdi
      add rdi, qword [rdi - 16]
      mov qword [rdi], rax

      add qword [r8 - 16], 8

      ret

  end if

