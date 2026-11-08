format ELF64 executable 3
entry start

_errno_compact = 1
include "constants.inc"
include "filebuf.inc"

_pagesize = 4096
filebuf_size          = (8 * _pagesize)
max_threads = 64
list_mode_buffer_size = (8 * _pagesize)

segment readable executable

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

    mov r11, r13
    mov r14, [querry]
    mov r13, [querry_size]
    mov r12, r8

    xor eax, eax
    or rcx, -1
    mov rdi, r8
    repne scasb
    sub rdi, 2
    mov [root_offset], rdi

    mov r10, r12
    .loop:

      mov rcx, r11
      mov rdi, r10

      mov al, [r14]
      repne scasb

      test rcx, rcx
      jz .end

      mov r11, rcx
      mov r10, rdi

      lea rsi, [r14 + 1]
      mov rcx, [querry_size]
      dec rcx
      repe cmpsb

      jnz .loop

      lea rdi, [r10 - 1]

      .skip_file_loop:

        mov al, [rdi]
        dec rdi

        test al, al
        jz .skip_file_loop_end
        cmp al, _char_slash
        jne .skip_file_loop

      .skip_file_loop_end:

      lea r9, [rdi + 2]

      jmp print_match
      .print_match_back:

      jmp .loop

    .end:

    mov eax, __NR_exit
    xor edi, edi
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
      or rdx, -1
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
      or rdx, -1
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

    ; r8 : ptr to the beginning of the file
    ; r9 : ptr to the match
    print_match:

      cld

      mov rbp, rsp
      dec rsp
      mov byte [rsp], _char_newline

      ; TODO: move in reverse, keeping the rdi of before the call

      mov rdi, r9
      xor eax, eax
      or rcx, -1
      repne scasb
      not rcx
      dec rcx

      sub rsp, rcx

      mov rsi, r9
      mov rdi, rsp
      rep movsb

      sub r9, 2

      .loop:

        mov ax, word [r9]
        test ah, ah
        jnz .skip_dir

        cmp al, _char_slash
        je .copy_dir

        .skip_file_loop:

          mov al, [r9]
          dec r9

          test al, al
          jz .skip_file_loop_end
          cmp al, _char_slash
          jne .skip_file_loop

        .skip_file_loop_end:

        jmp .loop

        .copy_dir:

          cmp r9, [root_offset]
          je .copy_root

          mov rsi, r9
          mov rdi, rsp

          mov al, byte [rsi]

          .copy_dir_loop:

            mov [rdi - 1], al
            dec rdi

            dec rsi
            mov al, [rsi]

            test al, al
            jz .copy_dir_loop_end
            cmp al, _char_slash
            jne .copy_dir_loop

          .copy_dir_loop_end:

          lea r9, [rsi - 1]

          mov rsp, rdi

        jmp .loop

        .skip_dir:

          mov ebx, 1

          mov eax, _char_slash
          mov rdi, r9
          std

          .skip_dir_loop:

            or rcx, -1
            repne scasb

            xor edx, edx
            cmp byte [rdi + 2], _char_null
            setne dl
            add edx, edx
            dec rdx
            add rbx, rdx

            jnz .skip_dir_loop

          .skip_dir_name_loop:

            mov al, [rdi]
            dec rdi

            test al, al
            jz .skip_dir_name_loop_end
            cmp al, _char_slash
            jne .skip_dir_name_loop

          .skip_dir_name_loop_end:

          mov r9, rdi

          cld

        jmp .loop

      .copy_root:

      mov rcx, [root_offset]
      sub rcx, r8
      inc rcx

      sub rsp, rcx

      mov rsi, r8
      mov rdi, rsp
      rep movsb

      mov eax, __NR_write
      mov edi, STDOUT_FILENO
      mov rsi, rsp
      lea rdx, [rbp + 1]
      sub rdx, rsp
      mov rbx, r11
      syscall
      mov r11, rbx

      mov rsp, rbp

      jmp start.print_match_back

    list:

      xor r15, r15

      mov eax, __NR_mmap
      xor edi, edi
      mov esi, filebuf_size
      mov edx, (PROT_READ or PROT_WRITE)
      mov r10, (MAP_PRIVATE or MAP_ANONYMOUS or MAP_UNINITIALIZED)
      syscall

      cmp rax, -4096
      ja exit_failure_errno

      mov [filebufs], rax
      mov [filebufs + 8], 0
      mov [filebufs + 16], STDOUT_FILENO

      sub rsp, list_mode_buffer_size
      mov rbp, rsp
      mov r14, rbp
      lea r12, [r8 + r13]
      mov r13, r8

      push rbp
      push .end

      jmp .skip_ahead

      .rec:

        cmp r13, r12
        jae .end

        cmp byte [r13], _char_slash
        je .ret

        .skip_ahead:

        mov r8, rbp

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

        mov rsi, r14
        lea rcx, [rbp + 1]
        sub rcx, r14
        mov rbx, r8
        filebuf_write filebuf_size
        mov r8, rbx

        cmp byte [rbp - 1], _char_slash
        cmovne rbp, r8
        jne .rec

        .dir:

          push r8
          push @f

          jmp .rec

          @@:

          pop rbp

          jmp .rec

      .ret:

        inc r13

        ret

      .end:

      mov rsi, filebufs
      mov rdx, [filebufs + 8]
      mov r10, @f
      jmp filebuf_flush
      @@:

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

  default_path_in_db     db "/var/cache/klocate/db", _char_null

segment readable writeable

  querry      rq 1
  querry_size rq 1
  root_offset rq 1

  path_in_db dq default_path_in_db

  filebufs rq (max_threads * 4) ; 32 bytes padded

  scratch rb 144

