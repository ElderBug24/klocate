format ELF64 executable 3
entry start

_strip_errno equ 0

include "macros.inc"
include "constants.inc"
include "filebuf.inc"

pagesize                   equ 4096           ; 4  Kib
filebuf_size               equ (8 * pagesize) ; 32 Kib
max_threads                equ 64
list_mode_buffer_size      equ (8 * pagesize) ; 32 Kib
initial_nonreg_buffer_size equ (4 * pagesize) ; 16 Kib

_feature_bit_file          equ 0
_feature_bit_dir           equ 1
_feature_bit_hidden        equ 2
_feature_bit_display_path  equ 3
_feature_bit_cmp_path      equ 4
_feature_flag_file         equ (1 shl _feature_bit_file        )
_feature_flag_dir          equ (1 shl _feature_bit_dir         )
_feature_flag_hidden       equ (1 shl _feature_bit_hidden      )
_feature_flag_display_path equ (1 shl _feature_bit_display_path)
_feature_flag_cmp_path     equ (1 shl _feature_bit_cmp_path    )
_feature_flags_mask        equ (_feature_flag_file or _feature_flag_dir or _feature_flag_hidden or _feature_flag_display_path or _feature_flag_cmp_path)

; TODO: add max dir recursion depth option

segment readable executable

  start:

    mov r8, qword [rsp]

    mov r12d, (_feature_flag_file or _feature_flag_dir or _feature_flag_hidden or _feature_flag_display_path or _feature_flag_cmp_path)

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
    mov qword [query], rax

    mov rdi, rax
    xor eax, eax
    mov rcx, -1
    repne scasb
    not rcx
    dec rcx
    mov qword [query_size], rcx

    cmp r8, 3
    jb .args_parsing_end

    mov rax, qword [rsp + 24]
    mov qword [path_in_db], rax

    ja exit_failure_too_many_args

    ; TODO: parse threads count

    .args_parsing_end:

    mov rax, [rsp]

    lea r8, [rsp + 8 * rax + 16]

    .env_loop:

      mov rbx, qword [r8]
      test rbx, rbx
      jz .env_loop_end

      mov rsi, rbx
      mov rdi, env_klocate_db_path_id
      mov rcx, env_klocate_db_path_id_len
      repe cmpsb

      jne .env_loop_not_equal

      mov qword [path_in_db], rsi

      jmp .env_loop_end

      .env_loop_not_equal:

      add r8, 8
      jmp .env_loop

    .env_loop_end:

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
    mov r10d, (MAP_PRIVATE or MAP_POPULATE)
    mov r8, r12
    xor r9, r9
    syscall

    cmp rax, -4096
    ja exit_failure_errno

    .read_nonreg_back:

    mov r8, rax

    test r15, r15
    jnz list

    xor r15, r15

    mov rbx, r8
    mov r14, qword [features]

    mov eax, __NR_mmap
    xor edi, edi
    mov esi, (filebuf_size + list_mode_buffer_size)
    mov edx, (PROT_READ or PROT_WRITE)
    mov r10d, (MAP_PRIVATE or MAP_ANONYMOUS or MAP_UNINITIALIZED)
    mov r8, -1
    xor r9, r9
    syscall

    mov r8, rbx

    cmp rax, -4096
    ja exit_failure_errno

    mov qword [filebufs + r15 + _offset_filebuf_ptr], rax
    mov qword [filebufs + r15 + _offset_filebuf_len], 0
    mov qword [filebufs + r15 + _offset_filebuf_fd], STDOUT_FILENO

    lea rbp, [rax + filebuf_size]
    mov rax, r13
    mov r13, r8
    add r8, rax
    mov [file_end], r8

    push exit_failure_corrupted_db

    jmp .query_skip_ahead

    .query_rec:

      cmp byte [r13], _char_nul
      je .query_end

      cmp byte [r13], _char_solidus
      je .query_ret

      .query_skip_ahead:

      mov rbx, rbp

      mov al, byte [r13]
      inc r13

      .query_copy_loop:

        mov byte [rbp], al
        inc rbp

        mov ax, word [r13]
        inc r13

        cmp al, _char_nul
        jne .query_copy_loop

      mov byte [rbp], _char_lf

      test ah, ah
      jz exit_failure_corrupted_db

      mov rax, r14
      mov rcx, r14
      assert _feature_bit_dir >= _feature_bit_file
      shr rcx, (_feature_bit_dir - _feature_bit_file)
      cmp byte [rbp - 1], _char_solidus
      cmove rax, rcx
      setne dil

      cmp byte [rbx], _char_full_stop
      sete sil
      bt r14, _feature_bit_hidden
      setnc dl
      and sil, dl
      test sil, dil
      cmovnz rbp, rbx
      jnz .query_rec
      not dil
      test sil, dil
      jnz .query_skip_dir

      bt rax, _feature_bit_file
      jnc .query_skip_write

      mov rdi, qword [filebufs + r15 + _offset_filebuf_ptr]
      add rdi, filebuf_size
      bt r14, _feature_bit_cmp_path
      cmovnc rdi, rbx
      lea rcx, [rbp + 1]
      sub rcx, rdi

      mov r9, rcx
      mov r11, qword [query]
      mov rdx, qword [query_size]
      mov al, byte [r11]
      inc r11

      .query_cmp_loop:

        mov rcx, r9
        repne scasb
        test rcx, rcx
        jz .query_skip_write
        mov r9, rcx

        cmp rcx, rdx
        jb .query_skip_write
        mov rsi, r11
        mov rcx, rdx

        repe cmpsb

        test rcx, rcx
        jz .query_write

        jmp .query_cmp_loop

      .query_skip_write:

      cmp byte [rbp - 1], _char_solidus
      cmovne rbp, rbx
      jne .query_rec

      push rbx
      push .query_back

      jmp .query_rec

      .query_back:

      pop rbp

      jmp .query_rec

    .query_ret:

      inc r13

      ret

    .query_end:

    add r13, 2
    cmp r13, [file_end]
    jne exit_failure_corrupted_db

    mov rdx, qword [filebufs + r15 + _offset_filebuf_len]
    filebuf_flush (filebufs + r15)

    mov eax, __NR_exit_group
    xor edi, edi
    syscall

    .query_write:

      mov rsi, qword [filebufs + r15 + _offset_filebuf_ptr]
      add rsi, filebuf_size
      bt r14, _feature_bit_display_path
      cmovnc rsi, rbx
      lea rcx, [rbp + 1]
      sub rcx, rsi
      filebuf_write filebuf_size

      jmp .query_skip_write

    .query_skip_dir:

      mov rbp, rbx

      xor ebx, ebx
      mov rdi, r13

      .query_skip_dir_loop:

        mov eax, _char_solidus
        xor ecx, ecx
        dec rcx

        repne scasb

        mov ax, word [rdi]
        xor edx, edx
        test ax, ax
        jz exit_failure_corrupted_db
        cmp al, _char_nul
        sete dl
        add edx, edx
        dec rdx
        add rbx, rdx

        jns .query_skip_dir_loop

      mov r13, rdi

      jmp .query_rec

    ; r12: fd
    .read_nonreg:

      mov eax, __NR_mmap
      xor edi, edi
      mov esi, initial_nonreg_buffer_size
      mov edx, (PROT_READ or PROT_WRITE)
      mov r10d, (MAP_PRIVATE or MAP_ANONYMOUS or MAP_UNINITIALIZED)
      mov r8, -1
      xor r9, r9
      syscall

      cmp rax, -4096
      ja exit_failure_errno

      mov r10, rax
      xor r13, r13
      mov r14, initial_nonreg_buffer_size

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
        mov r10d, MREMAP_MAYMOVE
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
        lea rbx, [rax + 1]

        xor eax, eax
        mov rdi, _errno_table

        cld

        .loop:

          xor ecx, ecx
          dec rcx
          repne scasb

          dec rbx
          jns .loop

        not rcx
        dec rcx

        mov rsi, rdi
        sub rsi, rcx
        dec rsi

        mov eax, 1
        mov edi, 2
        mov rdx, rcx
        syscall

        mov eax, __NR_write
        mov rsi, char_lf
        mov edx, 1
        syscall

      end if

      mov eax, __NR_exit_group
      dec edi ; 1 = STDERR_FILENO - 1
      syscall

    exit_failure_too_many_args:

      mov eax, __NR_write
      mov edi, STDERR_FILENO
      mov rsi, msg_err_too_many_args
      mov edx, msg_err_too_many_args_len
      syscall

      mov eax, __NR_exit_group
      dec edi ; 1 = STDERR_FILENO - 1
      syscall

    exit_failure_corrupted_db:

      mov eax, __NR_write
      mov edi, STDERR_FILENO
      mov rsi, msg_error
      mov edx, (msg_error_len + msg_sep_len)
      syscall

      mov eax, __NR_write
      mov rsi, msg_err_corrupted_db
      mov edx, msg_err_corrupted_db_len
      syscall

      mov eax, __NR_exit_group
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
      mov r10d, (MAP_PRIVATE or MAP_ANONYMOUS or MAP_UNINITIALIZED)
      mov r8, -1
      xor r9, r9
      syscall

      mov r8, rbx

      cmp rax, -4096
      ja exit_failure_errno

      mov qword [filebufs + r15 + _offset_filebuf_ptr], rax
      mov qword [filebufs + r15 + _offset_filebuf_len], 0
      mov qword [filebufs + r15 + _offset_filebuf_fd], STDOUT_FILENO

      lea rbp, [rax + filebuf_size]
      mov rax, r13
      mov r13, r8
      add r8, rax
      mov [file_end], r8

      push exit_failure_corrupted_db

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

          mov ax, word [r13]
          inc r13

          cmp al, _char_nul
          jne .copy_loop

        mov byte [rbp], _char_lf

        test ah, ah
        jz exit_failure_corrupted_db

        mov rax, r14
        mov rcx, r14
        assert _feature_bit_dir >= _feature_bit_file
        shr rcx, (_feature_bit_dir - _feature_bit_file)
        cmp byte [rbp - 1], _char_solidus
        cmove rax, rcx
        setne dil

        cmp byte [rbx], _char_full_stop
        sete sil
        bt r14, _feature_bit_hidden
        setnc dl
        and sil, dl
        test sil, dil
        cmovnz rbp, rbx
        jnz .rec
        not dil
        test sil, dil
        jnz .skip_dir

        bt rax, _feature_bit_file
        jnc .skip_write

        mov rsi, qword [filebufs + r15 + _offset_filebuf_ptr]
        add rsi, filebuf_size
        bt r14, _feature_bit_display_path
        cmovnc rsi, rbx
        lea rcx, [rbp + 1]
        sub rcx, rsi
        filebuf_write filebuf_size

        .skip_write:

        cmp byte [rbp - 1], _char_solidus
        cmovne rbp, rbx
        jne .rec

        push rbx
        push .back

        jmp .rec

        .back:

        pop rbp

        jmp .rec

      .ret:

        inc r13

        ret

      .end:

      add r13, 2
      cmp r13, [file_end]
      jne exit_failure_corrupted_db

      mov rdx, qword [filebufs + r15 + _offset_filebuf_len]
      filebuf_flush (filebufs + r15)

      mov eax, __NR_exit_group
      xor edi, edi
      syscall

      .skip_dir:

        mov rbp, rbx

        xor ebx, ebx
        mov rdi, r13

        .skip_dir_loop:

          mov eax, _char_solidus
          xor ecx, ecx
          dec rcx

          repne scasb

          mov ax, word [rdi]
          xor edx, edx
          test ax, ax
          jz exit_failure_corrupted_db
          cmp al, _char_nul
          sete dl
          add edx, edx
          dec rdx
          add rbx, rdx

          jns .skip_dir_loop

        mov r13, rdi

        jmp .rec

segment readable

  msg_error             db "error"
  msg_error_len = $ - msg_error
  msg_sep               db      ": "
  msg_sep_len = $ - msg_sep
                        db        "Too many arguments", _char_lf
  label msg_err_too_many_args byte at msg_error
  msg_err_too_many_args_len = $ - msg_err_too_many_args
  msg_err_corrupted_db  db        "Corrupted Database"
  char_lf db _char_lf
  msg_err_corrupted_db_len  = $ - msg_err_corrupted_db

  default_path_in_db db "/var/lib/klocate/db", _char_nul
  label char_solidus byte at default_path_in_db
  path_stdin db "-", 0

  env_klocate_db_path_id db "KLOCATE_DB_PATH="
  env_klocate_db_path_id_len = $ - env_klocate_db_path_id

segment readable writeable

  query       rq 1
  query_size  rq 1
  features    rq 1
  root_offset rq 1
  file_end    rq 1

  path_in_db rq 1

  filebufs rq (max_threads * 4) ; 32 bytes padded

  scratch rb 144

