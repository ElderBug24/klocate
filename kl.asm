format ELF64 executable 3
entry start

_strip_errno equ 0

include "macros.inc"
include "constants.inc"
include "filebuf.inc"
include "klocate.inc"

pagesize                   equ 4096              ; 4  Kib
filebuf_size               equ (8 * pagesize)    ; 32 Kib
max_threads                equ 64
list_mode_buffer_size      equ (1024 * pagesize) ; 4  Mib
initial_nonreg_buffer_size equ (4 * pagesize)    ; 16 Kib
max_recursion              equ (list_mode_buffer_size / 256)

_feature_bit_file          equ 8
_feature_bit_dir           equ 9
_feature_bit_hidden        equ 10
_feature_bit_display_path  equ 11
_feature_bit_cmp_path      equ 12
_feature_flag_file         equ (1 shl _feature_bit_file        )
_feature_flag_dir          equ (1 shl _feature_bit_dir         )
_feature_flag_hidden       equ (1 shl _feature_bit_hidden      )
_feature_flag_display_path equ (1 shl _feature_bit_display_path)
_feature_flag_cmp_path     equ (1 shl _feature_bit_cmp_path    )
_feature_flags_mask        equ (_feature_flag_file or _feature_flag_dir or _feature_flag_hidden or _feature_flag_display_path or _feature_flag_cmp_path)

expect_arg_any     equ 0
expect_arg_pattern equ 1
expect_arg_dbpath  equ 2
expect_arg_depth   equ 3

segment readable executable

  start:

    mov r8, qword [rsp]

    mov r12d, (_char_lf or _feature_flag_file or _feature_flag_dir or _feature_flag_display_path)

    lea r9, [rsp + 8 * r8 + 16]

    .env_loop:

      mov rbx, qword [r9]
      test rbx, rbx
      jz .env_loop_end

      mov rsi, rbx
      mov rdi, env_klocate_db_path_id
      mov rcx, env_klocate_db_path_id_len
      repe cmpsb

      jne .env_loop_not_equal

      mov qword [default_path_in_db_holder], rsi

      jmp .env_loop_end

      .env_loop_not_equal:

      add r9, 8
      jmp .env_loop

    .env_loop_end:

    mov eax, __NR_ioctl
    mov edi, STDIN_FILENO
    mov esi, TCGETS
    mov edx, scratch
    syscall

    mov rbx, qword [default_path_in_db_holder]
    mov rcx, path_stdin
    cmp rax, -ENOTTY
    cmove rbx, rcx
    mov qword [path_in_db], rbx

    mov r13d, expect_arg_any
    xor r10, r10
    lea r9, [rsp + 8]

    .args_parsing_loop:

      add r9, 8
      inc r10

      cmp r10, r8
      je .args_parsing_end

      mov rbx, qword [r9]

      mov eax, expect_arg_any
      mov rdx, qword [query]
      cmp r13d, expect_arg_pattern
      cmove rdx, rbx
      cmove r13d, eax
      mov qword [query], rdx
      je .args_parsing_loop

      mov eax, expect_arg_any
      mov rdx, qword [path_in_db]
      cmp r13d, expect_arg_dbpath
      cmove rdx, rbx
      cmove r13d, eax
      mov qword [path_in_db], rdx
      je .args_parsing_loop

      cmp r13d, expect_arg_depth
      je .args_parse_depth

      cmp byte [rbx], _char_hyphen_minus
      jne .args_parse_query

      inc rbx

      mov rsi, rbx
      mov rdi, arg_database_short
      mov ecx, arg_database_short_len
      repe cmpsb
      mov eax, expect_arg_dbpath
      test ecx, ecx
      cmovz r13d, eax
      jz .args_parsing_loop

      mov rsi, rbx
      mov rdi, arg_default_database_short
      mov ecx, arg_default_database_short_len
      repe cmpsb
      mov rax, qword [path_in_db]
      mov rdi, qword [default_path_in_db_holder]
      test ecx, ecx
      cmovz rax, rdi
      mov qword [path_in_db], rax
      jz .args_parsing_loop

      mov rsi, rbx
      mov rdi, arg_basename_short
      mov ecx, arg_basename_short_len
      repe cmpsb
      mov rax, r12
      btr rax, _feature_bit_display_path
      test ecx, ecx
      cmovz r12, rax
      jz .args_parsing_loop

      mov rsi, rbx
      mov rdi, arg_wholename_short
      mov ecx, arg_wholename_short_len
      repe cmpsb
      mov rax, r12
      bts rax, _feature_bit_cmp_path
      test ecx, ecx
      cmovz r12, rax
      jz .args_parsing_loop

      mov rsi, rbx
      mov rdi, arg_files_short
      mov ecx, arg_files_short_len
      repe cmpsb
      mov rax, r12
      bts rax, _feature_bit_file
      btr rax, _feature_bit_dir
      test ecx, ecx
      cmovz r12, rax
      jz .args_parsing_loop

      mov rsi, rbx
      mov rdi, arg_folders_short
      mov ecx, arg_folders_short_len
      repe cmpsb
      mov rax, r12
      bts rax, _feature_bit_dir
      btr rax, _feature_bit_file
      test ecx, ecx
      cmovz r12, rax
      jz .args_parsing_loop

      mov rsi, rbx
      mov rdi, arg_all_short
      mov ecx, arg_all_short_len
      repe cmpsb
      mov rax, r12
      bts rax, _feature_bit_hidden
      test ecx, ecx
      cmovz r12, rax
      jz .args_parsing_loop

      mov rsi, rbx
      mov rdi, arg_hidden_short
      mov ecx, arg_hidden_short_len
      repe cmpsb
      mov rax, r12
      bts rax, _feature_bit_hidden
      test ecx, ecx
      cmovz r12, rax
      jz .args_parsing_loop

      mov rsi, rbx
      mov rdi, arg_ignore_hidden_short
      mov ecx, arg_ignore_hidden_short_len
      repe cmpsb
      mov rax, r12
      btr rax, _feature_bit_hidden
      test ecx, ecx
      cmovz r12, rax
      jz .args_parsing_loop

      mov rsi, rbx
      mov rdi, arg_pattern_short
      mov ecx, arg_pattern_short_len
      repe cmpsb
      mov rax, qword [query]
      test ecx, ecx
      cmovz rax, rbx
      mov qword [query], rax
      jz .args_parsing_loop

      mov rsi, rbx
      mov rdi, arg_list_short
      mov ecx, arg_list_short_len
      repe cmpsb
      mov rax, qword [query]
      xor edx, edx
      test ecx, ecx
      cmovz rax, rdx
      mov qword [query], rax
      jz .args_parsing_loop

      mov rsi, rbx
      mov rdi, arg_depth_short
      mov ecx, arg_depth_short_len
      repe cmpsb
      mov eax, expect_arg_depth
      test ecx, ecx
      cmovz r13d, eax
      jz .args_parsing_loop

      mov rsi, rbx
      mov rdi, arg_newline_short
      mov ecx, arg_newline_short_len
      repe cmpsb
      mov rax, r12
      mov al, _char_lf
      test ecx, ecx
      cmovz r12, rax
      jz .args_parsing_loop

      mov rsi, rbx
      mov rdi, arg_null_short
      mov ecx, arg_null_short_len
      repe cmpsb
      mov rax, r12
      mov al, _char_nul
      test ecx, ecx
      cmovz r12, rax
      jz .args_parsing_loop

      mov rsi, rbx
      mov rdi, arg_help_short
      mov ecx, arg_help_short_len
      repe cmpsb
      test ecx, ecx
      jz .args_parsing_help

      cmp byte [rbx], _char_hyphen_minus
      jne .args_parse_query

      inc rbx

      mov rsi, rbx
      mov rdi, arg_database
      mov ecx, arg_database_len
      repe cmpsb
      mov eax, expect_arg_dbpath
      test ecx, ecx
      cmovz r13d, eax
      jz .args_parsing_loop

      mov rsi, rbx
      mov rdi, arg_default_database
      mov ecx, arg_default_database_len
      repe cmpsb
      mov rax, qword [path_in_db]
      mov rdi, qword [default_path_in_db_holder]
      test ecx, ecx
      cmovz rax, rdi
      mov qword [path_in_db], rax
      jz .args_parsing_loop

      mov rsi, rbx
      mov rdi, arg_basename
      mov ecx, arg_basename_len
      repe cmpsb
      mov rax, r12
      btr rax, _feature_bit_display_path
      test ecx, ecx
      cmovz r12, rax
      jz .args_parsing_loop

      mov rsi, rbx
      mov rdi, arg_wholename
      mov ecx, arg_wholename_len
      repe cmpsb
      mov rax, r12
      bts rax, _feature_bit_cmp_path
      test ecx, ecx
      cmovz r12, rax
      jz .args_parsing_loop

      mov rsi, rbx
      mov rdi, arg_files
      mov ecx, arg_files_len
      repe cmpsb
      mov rax, r12
      bts rax, _feature_bit_file
      btr rax, _feature_bit_dir
      test ecx, ecx
      cmovz r12, rax
      jz .args_parsing_loop

      mov rsi, rbx
      mov rdi, arg_folders
      mov ecx, arg_folders_len
      repe cmpsb
      mov rax, r12
      bts rax, _feature_bit_dir
      btr rax, _feature_bit_file
      test ecx, ecx
      cmovz r12, rax
      jz .args_parsing_loop

      mov rsi, rbx
      mov rdi, arg_all
      mov ecx, arg_all_len
      repe cmpsb
      mov rax, r12
      bts rax, _feature_bit_hidden
      test ecx, ecx
      cmovz r12, rax
      jz .args_parsing_loop

      mov rsi, rbx
      mov rdi, arg_hidden
      mov ecx, arg_hidden_len
      repe cmpsb
      mov rax, r12
      bts rax, _feature_bit_hidden
      test ecx, ecx
      cmovz r12, rax
      jz .args_parsing_loop

      mov rsi, rbx
      mov rdi, arg_ignore_hidden
      mov ecx, arg_ignore_hidden_len
      repe cmpsb
      mov rax, r12
      btr rax, _feature_bit_hidden
      test ecx, ecx
      cmovz r12, rax
      jz .args_parsing_loop

      mov rsi, rbx
      mov rdi, arg_pattern
      mov ecx, arg_pattern_len
      repe cmpsb
      mov rax, qword [query]
      test ecx, ecx
      cmovz rax, rbx
      mov qword [query], rax
      jz .args_parsing_loop

      mov rsi, rbx
      mov rdi, arg_list
      mov ecx, arg_list_len
      repe cmpsb
      mov rax, qword [query]
      xor edx, edx
      test ecx, ecx
      cmovz rax, rdx
      mov qword [query], rax
      jz .args_parsing_loop

      mov rsi, rbx
      mov rdi, arg_depth
      mov ecx, arg_depth_len
      repe cmpsb
      mov eax, expect_arg_depth
      test ecx, ecx
      cmovz r13d, eax
      jz .args_parsing_loop

      mov rsi, rbx
      mov rdi, arg_newline
      mov ecx, arg_newline_len
      repe cmpsb
      mov rax, r12
      mov al, _char_lf
      test ecx, ecx
      cmovz r12, rax
      jz .args_parsing_loop

      mov rsi, rbx
      mov rdi, arg_null
      mov ecx, arg_null_len
      repe cmpsb
      mov rax, r12
      mov al, _char_nul
      test ecx, ecx
      cmovz r12, rax
      jz .args_parsing_loop

      mov rsi, rbx
      mov rdi, arg_help
      mov ecx, arg_help_len
      repe cmpsb
      test ecx, ecx
      jz .args_parsing_help

      .args_parse_query:

      mov qword [query], rbx

      xor eax, eax
      mov rdi, rbx
      xor ecx, ecx
      dec rcx
      repne scasb
      not rcx
      dec rcx

      mov qword [query_size], rcx

      jmp .args_parsing_loop

    .args_parsing_help:

      mov eax, __NR_write
      mov edi, STDOUT_FILENO
      mov rsi, help_msg
      mov edx, help_msg_len
      syscall

      mov eax, __NR_exit
      xor edi, edi
      syscall

    .args_parse_depth:

      mov r13d, expect_arg_any

      mov rdi, rbx
      mov rsi, rbx
      xor ebx, ebx

      .parse_depth_loop:

        movzx eax, byte [rsi]
        inc rsi
        test al, al
        jz .parse_depth_loop_end
        cmp al, '0'
        jb exit_failure_parse
        cmp al, '9'
        ja exit_failure_parse

        lea rcx, [rbx + 4 * rbx]
        lea rbx, [rax + 2 * rcx]
        sub rbx, _char_digit_zero
        jmp .parse_depth_loop

      .parse_depth_loop_end:

      mov qword [max_rec], rbx

      jmp .args_parsing_loop

    .args_parsing_end:

    cmp r13d, expect_arg_any
    jne exit_failure_missing_operand

    mov qword [features], r12

    mov eax, STDIN_FILENO
    mov rsi, qword [path_in_db]
    cmp word [rsi], _char_hyphen_minus ; "-\0"
    je .skip_open

    mov eax, __NR_openat
    mov edi, AT_FDCWD
    mov edx, O_RDONLY
    syscall

    mov rdi, rsi
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

    cmp qword [query], 0
    je list

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

    mov r12, qword [max_rec]

    push exit_failure_corrupted_db

    jmp .query_skip_ahead

    .query_rec:

        dec r12
        js .query_skip_dir_name

        .query_loop:

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

      mov byte [rbp], r14b

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
      jnz .query_loop
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
      jne .query_loop

      push rbx
      push .query_back

      jmp .query_rec

      .query_back:

      pop rbp

      jmp .query_loop

    .query_ret:

      inc r13
      inc r12

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

      jmp .query_loop

    .query_skip_dir_name:

      add rsp, 16
      mov rbp, rbx

      xor ebx, ebx
      mov rdi, r13

      jmp .query_skip_dir_loop

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
        mov edi, STDERR_FILENO
        mov rsi, r13
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

        mov eax, __NR_write
        mov edi, STDERR_FILENO
        mov rdx, rcx
        syscall

        mov eax, __NR_write
        mov rsi, char_lf
        mov edx, 1
        syscall

      end if

      mov eax, __NR_exit_group
      assert (STDERR_FILENO = 2)
      dec edi ; 1 = STDERR_FILENO - 1
      syscall

    exit_failure_corrupted_db:

      mov eax, __NR_write
      mov edi, STDERR_FILENO
      mov rsi, msg_error
      assert (msg_error + msg_error_len = msg_sep)
      assert (msg_sep + msg_sep_len = msg_err_corrupted_db)
      mov edx, (msg_error_len + msg_sep_len + msg_err_corrupted_db_len)
      syscall

      mov eax, __NR_exit_group
      assert (STDERR_FILENO = 2)
      dec edi ; 1 = STDERR_FILENO - 1
      syscall

    exit_failure_parse:

      mov r13, rdi

      mov eax, __NR_write
      mov edi, STDERR_FILENO
      mov rsi, msg_error
      assert (msg_error + msg_error_len = msg_sep)
      mov edx, (msg_error_len + msg_sep_len)
      syscall

      mov eax, __NR_write
      mov rsi, msg_err_parse_1
      mov edx, msg_err_parse_1_len
      syscall

      mov rdi, r13
      xor eax, eax
      mov rcx, -1
      cld
      repne scasb
      not rcx
      dec rcx

      mov eax, __NR_write
      mov edi, STDERR_FILENO
      mov rsi, r13
      mov rdx, rcx
      syscall

      mov eax, __NR_write
      mov rsi, msg_err_parse_2
      mov edx, msg_err_parse_2_len
      syscall

      mov eax, __NR_exit_group
      assert (STDERR_FILENO = 2)
      dec edi ; 1 = STDERR_FILENO - 1
      syscall

    exit_failure_missing_operand:

      mov eax, __NR_write
      mov edi, STDERR_FILENO
      mov rsi, msg_error
      assert (msg_error + msg_error_len = msg_sep)
      mov edx, (msg_error_len + msg_sep_len)
      syscall

      mov eax, __NR_write
      mov rsi, msg_err_missing_op_1
      mov edx, msg_err_missing_op_1_len
      syscall

      mov rdi, [r9 - 8]
      mov rsi, rdi
      xor eax, eax
      mov rcx, -1
      cld
      repne scasb
      not rcx
      lea rdx, [rcx - 1]

      mov eax, __NR_write
      mov edi, STDERR_FILENO
      syscall

      mov eax, __NR_write
      mov rsi, msg_err_missing_op_2
      mov edx, msg_err_missing_op_2_len
      syscall

      mov eax, __NR_exit_group
      assert (STDERR_FILENO = 2)
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

      mov r12, qword [max_rec]

      push exit_failure_corrupted_db

      jmp .skip_ahead

      .rec:

        dec r12
        js .skip_dir_name

        .loop:

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

        mov byte [rbp], r14b

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
        jnz .loop
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
        jne .loop

        push rbx
        push .back

        jmp .rec

        .back:

        pop rbp

        jmp .loop

      .ret:

        inc r13
        inc r12

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

        jmp .loop

      .skip_dir_name:

        add rsp, 16
        mov rbp, rbx

        xor ebx, ebx
        mov rdi, r13

        jmp .skip_dir_loop

segment readable

  msg_error             db "error"
  msg_error_len = $ - msg_error
  msg_sep               db      ": "
  msg_sep_len = $ - msg_sep
  msg_err_corrupted_db  db        "Corrupted Database"
  char_lf db _char_lf
  msg_err_corrupted_db_len  = $ - msg_err_corrupted_db
  msg_err_parse_1      db         "Failed to parse '"
  msg_err_parse_1_len = $ - msg_err_parse_1
  msg_err_parse_2      db                           "'", _char_lf
  msg_err_parse_2_len = $ - msg_err_parse_2
  msg_err_missing_op_1 db         "Missing required argument to option '"
  msg_err_missing_op_1_len = $ - msg_err_missing_op_1
  label msg_err_missing_op_2 byte at msg_err_parse_2
  msg_err_missing_op_2_len = msg_err_parse_2_len

  default_path_in_db db klocate_default_path_db, _char_nul
  path_stdin db "-", _char_nul

  env_klocate_db_path_id db klocate_default_path_db, "="
  env_klocate_db_path_id_len = $ - env_klocate_db_path_id

  arg_database_short db "d", _char_nul
  arg_database_short_len = $ - arg_database_short
  arg_default_database db "default-"
  arg_database db "database", _char_nul
  arg_database_len = $ - arg_database
  arg_default_database_len = $ - arg_default_database
  arg_default_database_short db "D", _char_nul
  arg_default_database_short_len = $ - arg_default_database_short
  arg_basename db "basename", _char_nul
  arg_basename_len = $ - arg_basename
  arg_basename_short db "b", _char_nul
  arg_basename_short_len = $ - arg_basename_short
  arg_wholename db "wholename", _char_nul
  arg_wholename_len = $ - arg_wholename
  arg_wholename_short db "w", _char_nul
  arg_wholename_short_len = $ - arg_wholename_short
  arg_files db "files", _char_nul
  arg_files_len = $ - arg_files
  arg_files_short db "f", _char_nul
  arg_files_short_len = $ - arg_files_short
  arg_folders db "folders", _char_nul
  arg_folders_len = $ - arg_folders
  arg_folders_short db "F", _char_nul
  arg_folders_short_len = $ - arg_folders_short
  arg_all db "all", _char_nul
  arg_all_len = $ - arg_all
  arg_all_short db "a", _char_nul
  arg_all_short_len = $ - arg_all_short
  arg_hidden db "hidde"
  arg_newline_short db "n", _char_nul
  arg_newline_short_len = $ - arg_newline_short
  arg_hidden_len = $ - arg_hidden
  arg_hidden_short db ".", _char_nul
  arg_hidden_short_len = $ - arg_hidden_short
  arg_ignore_hidden db "ignore-hidden", _char_nul
  arg_ignore_hidden_len = $ - arg_ignore_hidden
  arg_ignore_hidden_short db "H", _char_nul
  arg_ignore_hidden_short_len = $ - arg_ignore_hidden_short
  arg_pattern db "pattern", _char_nul
  arg_pattern_len = $ - arg_pattern
  arg_pattern_short db "P", _char_nul
  arg_pattern_short_len = $ - arg_pattern_short
  arg_list db "list", _char_nul
  arg_list_len = $ - arg_list
  arg_depth db "depth", _char_nul
  arg_depth_len = $ - arg_depth
  arg_depth_short db "m", _char_nul
  arg_depth_short_len = $ - arg_depth_short
  arg_newline db "newline", _char_nul
  arg_newline_len = $ - arg_newline
  arg_null db "nul"
  arg_list_short db "l", _char_nul
  arg_list_short_len = $ - arg_list_short
  arg_null_len = $ - arg_null
  arg_null_short db "0", _char_nul
  arg_null_short_len = $ - arg_null_short
  arg_help db "help", _char_nul
  arg_help_len = $ - arg_help
  arg_help_short db "?", _char_nul
  arg_help_short_len = $ - arg_help_short
  arg_usage db "usage", _char_nul
  arg_usage_len = $ - arg_usage

  help_msg:
  db "kl (Klocate)", _char_lf
  db "usage: kl [OPTION]... [PATTERN]", _char_lf
  db "find files and directory matching PATTERN", _char_lf
  db "list them all if no PATTERN is provided", _char_lf
  db _char_lf
  db "  -d, --database DBPATH         search inside DBPATH", _char_lf
  db "  -D, --default-database        search inside the default database", _char_lf
  db "  -b, --basename                display only the base name", _char_lf
  db "  -w, --wholename               look for matches the whole path name", _char_lf
  db "  -f, --files                   ignore folders", _char_lf
  db "  -F, --folders                 ignore files", _char_lf
  db "  -a, --all,                    do not ignore hidden files and directories", _char_lf
  db "  -., --hidden", _char_lf
  db "  -H, --ignore-hidden           ignore hidden files and directories", _char_lf
  db "  -P, --pattern PATTERN         use PATTERN for matching", _char_lf
  db "  -l, --list                    list all files without filtering", _char_lf
  db "  -m, --depth DEPTH             limit the search depth to DEPTH", _char_lf
  db "  -n, --newline                 delimit matches by newline", _char_lf
  db "  -0, --null                    delimit matches by NUL", _char_lf
  db "  -?, --help                    print help information", _char_lf
  db "      --usage", _char_lf
  db _char_lf
  db "the default database is '", klocate_default_path_db, "', or the environment variable '", klocat_env_klocate_db_path_id, "', if set", _char_lf
  db "the default maximum search depth is "
  db_uint max_recursion
  db _char_lf
  help_msg_len = $ - help_msg

segment readable writeable

  default_path_in_db_holder dq default_path_in_db

  max_rec dq max_recursion

  query       dq 0
  query_size  rq 1
  features    rq 1
  root_offset rq 1
  file_end    rq 1

  path_in_db rq 1

  filebufs rq (max_threads * 4) ; 32 bytes padded

  scratch rb 256

