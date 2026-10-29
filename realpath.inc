
include "constants.inc"

  ; rax : fd
  ; rdi : pointer to destination buffer
  ; rdx : size of destination buffer
  ; destroys : rax, rbx, rcx, rdx, rsi, rdi, r11, r12, r13, r14
  macro realpath_fd {

    mov r13, rdi
    mov r14, rdx

    mov rdi, (realpath_fmt_buf + realpath_fmt_buf_size - 1)
    mov r11, rdi

    mov rbx, 0xCCCCCCCCCCCCCCCD ; 2^66 / 5

    realpath_fd_fmt_loop:

      mov rcx, rax
      mul rbx
      shr rdx, 3
      lea rax, [4 * rdx + rdx]
      add rax, rax
      sub rcx, rax
      mov rax, rdx

      add ecx, _char_zero
      mov [rdi], cl
      dec rdi

      test rax, rax
      jnz realpath_fd_fmt_loop

    mov rcx, r11
    sub rcx, rdi
    lea rsi, [rdi + 1]
    mov rdi, realpath_fmt_buf

    rep movsb
    mov byte [rdi], 0

    mov rax, __NR_readlink
    mov rdi, realpath_proc_self_fd_path
    mov rsi, r13
    mov rdx, r14
    syscall

    mov byte [r13 + rax], 0

}

if used realpath_proc_self_fd_path

  segment readable writeable

    realpath_proc_self_fd_path db "/proc/self/fd/"
    realpath_proc_self_fd_path_len = $ - realpath_proc_self_fd_path
    realpath_fmt_buf_size = 16
    realpath_fmt_buf rb realpath_fmt_buf_size

end if

