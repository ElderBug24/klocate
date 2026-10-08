
macro filebuf_decl name, size {

  segment readable writeable

    filebuf_size_#name = size
    filebuf_len_#name rq 1
    filebuf_fd_#name rq 1
    filebuf_buffer_#name rb size
    filebuf_header_#name = filebuf_len_#name

}

; rsi : source
; rcx : count
; destroys : rax, rcx, rdx, rsi, rdi, r8, r9, r10
macro filebuf_write name {

  local back

  mov r8, rsi
  mov r9, rcx
  lea r10, [back]
  mov rsi, filebuf_buffer_#name
  mov edi, dword [filebuf_fd_#name]

  mov rdx, [filebuf_len_#name]
  lea rax, [rdx + rcx]
  cmp rax, filebuf_size_#name

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

segment readable executable

  ; rsi : buffer
  ; rdi : fd
  ; rdx : count
  ; destroys : rax, r11
  filebuf_flush:

    mov qword [rsi - 12], 0

    mov rax, __NR_write
    syscall

    jmp r10

  filebuf_flush_fn:

    mov rax, __NR_write
    syscall

    ret

