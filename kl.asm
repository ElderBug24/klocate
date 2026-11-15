format ELF64 executable 3
entry start

_strip_errno equ 0
include "constants.inc"
include "filebuf.inc"

_pagesize             equ 4096
filebuf_size          equ (8 * _pagesize)
max_threads           equ 64
list_mode_buffer_size equ (8 * _pagesize)

_feature_bit_file equ 0
_feature_bit_dir  equ 1
_feature_bit_path equ 2

_entry_bit_dir    equ 31

_feature_flag_file equ (1 shl _feature_bit_file)
_feature_flag_dir  equ (1 shl _feature_bit_dir )
_feature_flag_path equ (1 shl _feature_bit_path)
_feature_flags_mask equ (_feature_flag_file or _feature_flag_dir or _feature_flag_path)

segment readable executable

; TODO: option to filter files that do not exist anymore

  start:

    mov r8, qword [rsp]

    mov r12, (_feature_flag_file or _feature_flag_dir or _feature_flag_path)

    mov eax, __NR_ioctl
    mov edi, STDIN_FILENO
    mov esi, TCGETS
    mov edx, scratch
    syscall

    mov rbx, default_path_in_db
    mov rcx, path_stdin
    cmp rax, -ENOTTY
    cmove rbx, rcx
    mov qword [path_in_db], rbx

    xor eax, eax
    cmp r8, 2
    setb al
    mov r15, rax
    jb .args_parsing_end

    mov rax, qword [rsp + 16]
    mov qword [querry], rax

    mov rdi, rax
    xor eax, eax
    or rcx, -1
    repne scasb
    not rcx
    dec rcx
    mov qword [querry_size], rcx

    cmp r8, 3
    jb .args_parsing_end

    mov rax, qword [rsp + 24]
    mov qword [path_in_db], rax

    ja exit_failure_too_many_args

    ; TODO: parse threads count

    .args_parsing_end:

    mov qword [features], r12

    mov eax, STDIN_FILENO
    mov rsi, qword [path_in_db]
    cmp word [rsi], _char_hyphen_minus ; "-\0"
    je .in_is_stdin

    mov eax, __NR_openat
    mov edi, AT_FDCWD
    mov rsi, qword [path_in_db]
    mov edx, O_RDONLY
    syscall

    mov rdi, qword [path_in_db]
    cmp rax, -4096
    ja exit_failure_errno_path
    mov r12, rax

    mov eax, __NR_fstat
    mov rdi, r12
    mov rsi, scratch
    syscall

    mov r13, qword [scratch + 48]

    mov rdi, qword [path_in_db]
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

    .in_is_stdin_back:

    mov r8, rax

    test r15, r15
    jnz list

    ; TODO: querry mode

    mov eax, __NR_exit
    mov edi, 1
    syscall

    .in_is_stdin:

      mov rax, -ENOSYS
      jmp exit_failure_errno

      ; TODO: read stdin into buffer
      ; put size in r13
      ; put ptr in rax
      jmp .in_is_stdin_back

    exit_failure_errno_path:

      if ~ defined _strip_errno | _strip_errno < 2

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

    end if

    ; fallthrough

    exit_failure_errno:

      if ~ defined _strip_errno | _strip_errno < 2

        not rax

        mov esi, dword [_errno_table_msg + 4 * rax + 4]
        movzx edx, byte [_errno_table_len + rax + 1]
        mov eax, __NR_write
        mov edi, STDERR_FILENO
        syscall

        mov eax, __NR_write
        mov rsi, char_lf
        mov edx, 1
        syscall

      end if

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

      mov qword [filebufs + r15 + _filebuf_ptr_offset], rax
      mov qword [filebufs + r15 + _filebuf_len_offset], 0
      mov qword [filebufs + r15 + _filebuf_fd_offset], STDOUT_FILENO

      lea rbp, [rax + filebuf_size]
      mov r13, r8

      jmp .skip_ahead

      .rec:

        cmp byte [r13], _char_nul
        je .end

        cmp byte [r13], _char_solidus
        je .ret

        .skip_ahead:

        mov rbx, rbp

        mov al, byte [r13]
        inc r13

        .copy_loop:

          mov byte [rbp], al
          inc rbp

          mov al, byte [r13]
          inc r13

          cmp al, _char_nul
          jne .copy_loop

        mov byte [rbp], _char_lf

        ; TODO: check features if the whole path should be displayed
        mov rsi, qword [filebufs + r15 + _filebuf_ptr_offset]
        add rsi, filebuf_size
        lea rcx, [rbp + 1]
        sub rcx, rsi
        filebuf_write filebuf_size

        cmp byte [rbp - 1], _char_solidus
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

      mov rdx, qword [filebufs + r15 + _filebuf_len_offset]
      filebuf_flush_buffer (filebufs + r15)

      mov eax, __NR_exit
      xor edi, edi
      syscall

segment readable

  char_solidus db _char_solidus
  char_lf      db _char_lf

  msg_err_too_many_args db "error"
  msg_sep               db      ": "
  msg_sep_len = $ - msg_sep
                        db        "Too many arguments", _char_lf
  msg_err_too_many_args_len = $ - msg_err_too_many_args

  default_path_in_db db "/var/cache/klocate/db", _char_nul
  path_stdin db "-", 0

segment readable writeable

  querry      rq 1
  querry_size rq 1
  features    rq 1
  root_offset rq 1

  path_in_db rq 1

  filebufs rq (max_threads * 4) ; 32 bytes padded

  scratch rb 144

