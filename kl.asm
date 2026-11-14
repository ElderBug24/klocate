format ELF64 executable 3
entry start

; _errno_compact = 1
include "constants.inc"
include "filebuf.inc"

_pagesize             = 4096
filebuf_size          = (8 * _pagesize)
max_threads           = 64
list_mode_buffer_size = (8 * _pagesize)

segment readable executable

; TODO: option to filter files that do not exist anymore

  start:

    mov r8, [rsp]

    xor eax, eax
    cmp r8, 2
    setb al
    mov r15, rax
    jb .args_parsing_end

    mov rax, [rsp + 16]
    mov [querry], rax

    mov rdi, rax
    xor eax, eax
    or rcx, -1
    repne scasb
    not rcx
    dec rcx
    mov [querry_size], rcx

    cmp r8, 3
    jb .args_parsing_end

    mov rax, [rsp + 24]
    mov [path_in_db], rax

    ja exit_failure_too_many_args

    ; TODO: parse threads count

    .args_parsing_end:

    mov eax, __NR_openat
    mov edi, AT_FDCWD
    mov rsi, [path_in_db]
    mov edx, O_RDONLY
    syscall

    mov rdi, [path_in_db]
    cmp rax, -4096
    ja exit_failure_errno_path
    mov r12, rax

    mov eax, __NR_fstat
    mov rdi, r12
    mov rsi, scratch
    syscall

    mov r13, qword [scratch + 48]

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

    mov eax, __NR_mmap
    xor edi, edi
    mov rsi, r13
    mov edx, (PROT_READ or PROT_WRITE)
    mov r10, (MAP_PRIVATE or MAP_POPULATE)
    mov r8, r12
    xor r9, r9
    syscall

    cmp rax, -4096
    ja exit_failure_errno

    mov r8, rax

    test r15, r15
    jnz list

    ; TODO: querry mode

    mov eax, __NR_exit
    mov edi, 1
    syscall

    exit_failure_errno_path:

      mov r12, rax
      mov r13, rdi

      xor eax, eax
      or rcx, -1
      cld
      repne scasb
      not rcx
      dec rcx

      mov eax, __NR_write
      mov rsi, r13
      mov edi, STDERR_FILENO
      mov rdx, rcx
      syscall

      mov eax, __NR_write
      mov rsi, msg_sep
      mov edx, msg_sep_len
      syscall

      mov rax, r12
      not rax

      mov esi, dword [_errno_table_msg + 4 * rax + 4]
      movzx edx, byte [_errno_table_len + rax + 1]
      mov eax, __NR_write
      syscall

      mov eax, __NR_write
      mov rsi, char_newline
      mov edx, 1
      syscall

      mov eax, __NR_exit
      dec edi ; 1 = STDERR_FILENO - 1
      syscall

    exit_failure_errno:

      not rax

      mov esi, dword [_errno_table_msg + 4 * rax + 4]
      movzx edx, byte [_errno_table_len + rax + 1]
      mov eax, __NR_write
      mov edi, STDERR_FILENO
      syscall

      mov eax, __NR_write
      mov rsi, char_newline
      mov edx, 1
      syscall

      mov eax, __NR_exit
      dec edi ; 1 = STDERR_FILENO - 1
      syscall

    exit_failure_too_many_args:

      mov eax, __NR_write
      mov edi, STDERR_FILENO
      mov rsi, msg_err_too_many_args
      mov edx, msg_err_too_many_args_len
      syscall

      mov eax, __NR_exit
      dec edi ; 1 = STDERR_FILENO - 1
      syscall

    ; rsi : source
    ; rcx : size of source
    ; destroys: rax, rcx, rdx, rsi, rdi, r8, r9, r10, r11
    filter_entry:

      filebuf_write filebuf_size

      ret

    list:

      xor r15, r15

      mov eax, __NR_mmap
      xor edi, edi
      mov esi, (filebuf_size + list_mode_buffer_size)
      mov edx, (PROT_READ or PROT_WRITE)
      mov r10, (MAP_PRIVATE or MAP_ANONYMOUS or MAP_UNINITIALIZED)
      syscall

      cmp rax, -4096
      ja exit_failure_errno

      mov [filebufs + r15], rax
      mov [filebufs + r15 + 8], 0
      mov [filebufs + r15 + 16], STDOUT_FILENO

      lea rbp, [rax + filebuf_size]
      mov r13, r8

      jmp .skip_ahead

      .rec:

        cmp byte [r13], _char_null
        je .end

        cmp byte [r13], _char_slash
        je .ret

        .skip_ahead:

        mov rbx, rbp

        mov al, [r13]
        inc r13

        @@:

          mov [rbp], al
          inc rbp

          mov al, [r13]
          inc r13

          cmp al, _char_null
          jne @b

        mov byte [rbp], _char_newline

        mov rsi, [filebufs + r15]
        add rsi, filebuf_size
        lea rcx, [rbp + 1]
        sub rcx, rsi
        filebuf_write filebuf_size

        cmp byte [rbp - 1], _char_slash
        cmovne rbp, rbx
        jne .rec

        .dir:

          push rbx
          push @f

          jmp .rec

          @@:

          pop rbp

          jmp .rec

      .ret:

        inc r13

        ret

      .end:

      mov rdx, [filebufs + r15 + 8]
      filebuf_flush_buffer (filebufs + r15)

      mov eax, __NR_exit
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

  default_path_in_db db "/var/cache/klocate/db", _char_null

segment readable writeable

  querry      rq 1
  querry_size rq 1
  root_offset rq 1

  path_in_db dq default_path_in_db

  filebufs rq (max_threads * 4) ; 32 bytes padded

  scratch rb 144

