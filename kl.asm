format ELF64 executable 3
entry start

; _errno_compact = 1
include "constants.inc"

_pagesize = 4096
list_mode_buffer_size = (8 * _pagesize)

segment readable executable

  start:

    mov rcx, qword [rsp]

    xor eax, eax
    cmp rcx, 2
    setb al
    mov r15, rax
    jb args_parsing_end

    mov rax, [rsp + 16]
    mov [input], rax

    je args_parsing_end

    mov rbx, qword [rsp + 24]
    mov [path_in_db], rbx

    cmp rcx, 3
    ja exit_failure_too_many_args

    ; TODO: parse threads count

    args_parsing_end:

    mov rax, __NR_openat
    mov rdi, AT_FDCWD
    mov rsi, [path_in_db]
    mov rdx, O_RDONLY
    syscall

    mov rdi, [path_in_db]
    cmp rax, -4096
    ja exit_failure_errno_path
    mov r12, rax

    mov rax, __NR_fstat
    mov rdi, r12
    mov rsi, scratch
    syscall

    mov rdi, [path_in_db]
    cmp rax, -4096
    ja exit_failure_errno_path

    mov eax, dword [scratch + 24]
    and eax, S_IFMT

    mov rbx, -EISDIR
    mov rcx, -EINVAL
    cmp eax, S_IFDIR
    cmove rax, rbx
    je exit_failure_errno_path
    cmp eax, S_IFREG
    cmovne rax, rcx
    jne exit_failure_errno_path

    mov r13, qword [scratch + 48]

    mov rax, __NR_mmap
    xor edi, edi
    mov rsi, r13
    mov rdx, (PROT_READ or PROT_WRITE)
    mov r10, (MAP_PRIVATE or MAP_ANONYMOUS or MAP_UNINITIALIZED)
    xor r8, r8
    dec r8
    xor r9, r9
    syscall

    cmp rax, -4096
    ja exit_failure_errno

    mov r8, rax

    xor r14, r14
    mov rbx, r13

    @@:

      mov rdx, r13
      cmp rbx, rdx
      cmovb rdx, rbx

      mov rax, __NR_pread64
      mov rdi, r12
      lea rsi, [r8 + r14]
      mov r10, r14
      syscall

      cmp rax, -4096
      ja exit_failure_errno

      add r14, rax
      sub ebx, eax

      jnz @b

    test r15, r15
    jnz list

    mov rcx, r13 ; TODO:

    mov rax, __NR_exit
    xor edi, edi
    syscall

    exit_failure_errno_path:

      mov r12, rax
      mov r13, rdi

      xor eax, eax
      xor ecx, ecx
      dec rcx
      cld
      repne scasb
      not rcx
      dec rcx

      mov rax, __NR_write
      mov rsi, r13
      mov rdi, STDERR_FILENO
      mov rdx, rcx
      syscall

      mov rax, __NR_write
      mov rdi, STDERR_FILENO
      mov rsi, msg_sep
      mov rdx, msg_sep_len
      syscall

      mov rax, r12
      not rax

      mov esi, dword [_errno_table_msg + 4 * rax + 4]
      movzx edx, byte [_errno_table_len + rax + 1]
      mov rax, __NR_write
      mov rdi, STDERR_FILENO
      syscall

      mov rax, __NR_write
      mov rdi, STDERR_FILENO
      mov rsi, char_newline
      xor edx, edx
      inc edx
      syscall

      mov rax, __NR_exit
      xor edi, edi
      inc edi
      syscall

    exit_failure_errno:

      not rax

      mov esi, dword [_errno_table_msg + 4 * rax + 4]
      movzx edx, byte [_errno_table_len + rax + 1]
      mov rax, __NR_write
      mov rdi, STDERR_FILENO
      syscall

      mov rax, __NR_write
      mov rdi, STDERR_FILENO
      mov rsi, char_newline
      xor edx, edx
      inc edx
      syscall

      mov rax, __NR_exit
      xor edi, edi
      inc edi
      syscall

    exit_failure_too_many_args:

      mov rax, __NR_write
      mov rdi, STDERR_FILENO
      mov rsi, msg_err_too_many_args
      mov rdx, msg_err_too_many_args_len
      syscall

      mov rax, __NR_exit
      xor edi, edi
      inc edi
      syscall

    list:

      sub rsp, list_mode_buffer_size
      mov rbp, rsp
      mov r14, rbp
      mov r13, r8

      push list_end
      push rbp

      jmp list_rec_skip_ahead

      list_rec:

        xor eax, eax
        cmp byte [r13], _char_slash
        sete al
        add r13, rax
        je list_rec_end

        list_rec_skip_ahead:

        mov al, [r13]
        inc r13

        @@:

          mov [rbp], al
          inc rbp

          mov al, [r13]
          inc r13

          cmp al, _char_null
          jne @b

        inc r13

        mov byte [rbp], _char_newline

        mov rax, __NR_write
        mov rdi, STDOUT_FILENO
        mov rsi, r14
        mov rdx, rbp
        sub rdx, r14
        inc rdx
        syscall

        xor eax, eax
        cmp byte [rbp - 1], _char_slash
        sete al
        add r13, rax
        jne list_rec

        list_rec_dir:

          push @f
          push rbp

          jmp list_rec

          @@:

          jmp list_rec

      list_rec_end:

        pop rbp

        ret

      list_end:

      mov rax, __NR_exit
      xor edi, edi
      syscall

segment readable

  _char_null    = 0
  _char_newline = 10
  _char_dot     = '.'
  _char_slash   = '/'
  _char_zero    = '0'

  char_slash_null:
  char_slash   db _char_slash
  char_newline db _char_newline

  msg_err_too_many_args db "error"
  msg_sep               db      ": "
  msg_sep_len = $ - msg_sep
                        db        "Too many arguments", _char_newline
  msg_err_too_many_args_len = $ - msg_err_too_many_args

  default_path_in_db     db "/var/cache/klocate/db", _char_null

segment readable writeable

  input rq 1

  path_in_db dq default_path_in_db

  scratch rb 144

