format ELF64 executable 3
entry start

_strip_errno equ 0

include "macros.inc"
include "constants.inc"
include "filebuf.inc"

pagesize                   equ 4096
filebuf_size               equ (8 * pagesize)
max_threads                equ 64
list_mode_buffer_size      equ (8 * pagesize)
initial_nonreg_buffer_size equ (4 * pagesize)

_feature_bit_file   equ 0
_feature_bit_dir    equ 1
_feature_bit_path   equ 2
_feature_flag_file  equ (1 shl _feature_bit_file)
_feature_flag_dir   equ (1 shl _feature_bit_dir )
_feature_flag_path  equ (1 shl _feature_bit_path)
_feature_flags_mask equ (_feature_flag_file or _feature_flag_dir or _feature_flag_path)

segment readable executable

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
    mov rcx, -1
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
    je .skip_open

    mov eax, __NR_openat
    mov edi, AT_FDCWD
    mov rsi, qword [path_in_db]
    mov edx, O_RDONLY
    syscall

    mov rdi, qword [path_in_db]
    cmp rax, -4096
    ja exit_failure_errno_path
    .skip_open:
    mov r12, rax

    mov eax, __NR_fstat
    mov rdi, r12
    mov rsi, scratch
    syscall

    mov r13, qword [scratch + 48]

    mov rdi, qword [path_in_db]
    cmp rax, -4096
    ja exit_failure_errno_path

    mov ebx, dword [scratch + 24]
    and ebx, S_IFMT

    mov rax, -EISDIR
    cmp ebx, S_IFDIR
    je exit_failure_errno_path
    mov rax, -EINVAL
    cmp ebx, S_IFBLK
    je exit_failure_errno_path
    cmp ebx, S_IFREG
    jne .read_nonreg

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

    .read_nonreg_back:

    mov r8, rax

    test r15, r15
    jnz list

    ; TODO: querry mode

    mov eax, __NR_exit
    mov edi, 1
    syscall

    ; r12: fd
    .read_nonreg:

      mov eax, __NR_mmap
      xor edi, edi
      mov esi, initial_nonreg_buffer_size
      mov edx, (PROT_READ or PROT_WRITE)
      mov r10, (MAP_PRIVATE or MAP_ANONYMOUS or MAP_UNINITIALIZED)
      mov r8, -1
      xor r9, r9
      syscall

      cmp rax, -4096
      ja exit_failure_errno

      mov r10, rax ; ptr
      xor r13, r13 ; offset
      mov r14, initial_nonreg_buffer_size ; size

      .read_nonreg_loop:

        mov rdx, r14
        sub rdx, r13

        jle .read_nonreg_realloc
        .read_nonreg_realloc_back:

        mov eax, __NR_read
        mov rdi, r12
        lea rsi, [r10 + r13]
        syscall

        cmp rax, -EINTR
        je .read_nonreg_realloc_back

        cmp rax, -4096
        ja exit_failure_errno

        add r13, rax

        test rax, rax
        jnz .read_nonreg_loop

      mov rax, r10

      jmp .read_nonreg_back

      .read_nonreg_realloc:

        mov eax, __NR_mremap
        mov rdi, r10
        mov rsi, r14
        shl r14, 1
        mov rdx, r14
        mov r10, MREMAP_MAYMOVE
        syscall

        cmp rax, -4096
        ja exit_failure_errno

        mov r10, rax
        mov rdx, r14
        sub rdx, r13

        jmp .read_nonreg_realloc_back

    exit_failure_errno_path:

      if ~ defined _strip_errno | _strip_errno < 2

        mov r12, rax
        mov r13, rdi

        xor eax, eax
        mov rcx, -1
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

      mov rbx, r8
      mov r14, qword [features]

      mov eax, __NR_mmap
      xor edi, edi
      mov esi, (filebuf_size + list_mode_buffer_size)
      mov edx, (PROT_READ or PROT_WRITE)
      mov r10, (MAP_PRIVATE or MAP_ANONYMOUS or MAP_UNINITIALIZED)
      mov r8, -1
      xor r9, r9
      syscall

      mov r8, rbx

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

        mov rax, r14
        mov rcx, r14
        assert _feature_bit_dir >= _feature_bit_file
        shr rcx, (_feature_bit_dir - _feature_bit_file)
        cmp byte [rbp - 1], _char_solidus
        cmove rax, rcx
        bt rax, _feature_bit_file
        jnc .skip_write

        mov rsi, qword [filebufs + r15 + _filebuf_ptr_offset]
        add rsi, filebuf_size
        bt r14, _feature_bit_path
        cmovnc rsi, rbx
        lea rcx, [rbp + 1]
        sub rcx, rsi
        filebuf_write filebuf_size

        .skip_write:

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
      filebuf_flush (filebufs + r15)

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

