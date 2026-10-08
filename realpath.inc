
include "constants.inc"

segment readable executable

  if used realpath

    ; rsi : pointer to source buffer
    ; rdi : pointer to destination buffer
    ; rdx : size of destination buffer
    ; destroys : rax, rbx, rcx, rdx, rsi, rdi, r11, r12, r13, r14, r15
    realpath:

      mov r12, rsi
      mov r13, rdi
      mov r14, rdx

      mov rax, __NR_open
      mov rdi, rsi
      mov rsi, O_RDONLY
      xor rdx, rdx
      syscall ; nonzero fd

      cmp rax, -4096
      ja realpath_ret

      mov r15, rax

      mov rdi, (realpath_fmt_buf + realpath_fmt_buf_size)

      mov ebx, 10 ; base 10
      xor ecx, ecx

      realpath_fmt_loop:

        xor edx, edx
        div ebx
        add dl, '0'
        mov [rdi], dl
        dec rdi
        inc rcx

        test rax, rax
        jnz realpath_fmt_loop

      lea rsi, [rdi + 1]
      sub rdi, realpath_fmt_buf_size
      add rdi, rcx

      rep movsb
      mov byte [rdi], 0

      mov rax, __NR_readlink
      mov rdi, realpath_proc_self_fd_path
      mov rsi, r13
      mov rdx, r14
      syscall

      ; cmp rax, -4096
      ; ja realpath_ret

      mov r14, rax
      mov byte [r13 + rax], 0

      mov rax, __NR_close
      mov rdi, r15
      syscall

      ; cmp rax, -4096
      ; ja realpath_ret

      mov rax, r14

      realpath_ret:

      ret

  end if

  if used realpath_dir

    ; rsi : pointer to source buffer
    ; rdi : pointer to destination buffer
    ; rdx : size of destination buffer
    ; destroys : rax, rbx, rcx, rdx, rsi, rdi, r11, r12, r13, r14, r15
    realpath_dir:

      mov r12, rsi
      mov r13, rdi
      mov r14, rdx

      mov rax, __NR_open
      mov rdi, rsi
      mov rsi, (O_RDONLY or O_DIRECTORY)
      xor rdx, rdx
      syscall ; nonzero fd

      cmp rax, -4096
      ja realpath_dir_ret

      mov r15, rax

      mov rdi, (realpath_fmt_buf + realpath_fmt_buf_size)

      mov ebx, 10 ; base 10
      xor ecx, ecx

      realpath_dir_fmt_loop:

        xor edx, edx
        div ebx
        add dl, '0'
        mov [rdi], dl
        dec rdi
        inc rcx

        test rax, rax
        jnz realpath_dir_fmt_loop

      lea rsi, [rdi + 1]
      sub rdi, realpath_fmt_buf_size
      add rdi, rcx

      rep movsb
      mov byte [rdi], 0

      mov rax, __NR_readlink
      mov rdi, realpath_proc_self_fd_path
      mov rsi, r13
      mov rdx, r14
      syscall

      ; cmp rax, -4096
      ; ja realpath_dir_ret

      mov r14, rax
      mov byte [r13 + rax], 0

      mov rax, __NR_close
      mov rdi, r15
      syscall

      ; cmp rax, -4096
      ; ja realpath_dir_ret

      mov rax, r14

      realpath_dir_ret:

      ret

  end if

  if used realpath_fd

    ; rax : fd
    ; rdi : pointer to destination buffer
    ; rdx : size of destination buffer
    ; destroys : rax, rbx, rcx, rdx, rsi, rdi, r11, r12, r13, r14
    realpath_fd:

      mov r13, rdi
      mov r14, rdx

      mov rdi, (realpath_fmt_buf + realpath_fmt_buf_size)

      mov ebx, 10 ; base 10
      xor ecx, ecx

      realpath_fd_fmt_loop:

        xor edx, edx
        div ebx
        add dl, '0'
        mov [rdi], dl
        dec rdi
        inc rcx

        test rax, rax
        jnz realpath_fd_fmt_loop

      lea rsi, [rdi + 1]
      sub rdi, realpath_fmt_buf_size
      add rdi, rcx

      rep movsb
      mov byte [rdi], 0

      mov rax, __NR_readlink
      mov rdi, realpath_proc_self_fd_path
      mov rsi, r13
      mov rdx, r14
      syscall

      ; cmp rax, -4096
      ; ja realpath_fd_ret

      mov byte [r13 + rax], 0

      realpath_fd_ret:

      ret

  end if

  if used realpath | used realpath_dir | used realpath_fd

    segment readable writeable

      realpath_proc_self_fd_path db "/proc/self/fd/"
      realpath_proc_self_fd_path_len = $ - realpath_proc_self_fd_path
      realpath_fmt_buf_size = 10
      realpath_fmt_buf rb realpath_fmt_buf_size

  end if


