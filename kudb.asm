format ELF64 executable 3
entry start

_debug_tmpfile_name = 1
; _errno_compact = 1
include "constants.inc"
include "realpath.inc"
include "filebuf.inc"
include "dispatch.inc"

_pagesize             = 4096
realpath_buf_size     = (4 * _pagesize)
dents_buf_size        = (2 * _pagesize)
filebuf_size          = (8 * _pagesize)
pipe_buf              = _pagesize
max_threads           = 64 ; TODO: get rid of all limitaions imposed at assembly time
default_threads_count = 4
thread_stack_size_exp = 24
thread_stack_size     = (1 shl thread_stack_size_exp) ; (4 * 1024 * _pagesize)
scratch_size_exp      = 8
scratch_size          = (1 shl scratch_size_exp)

action_work     = 0
action_dispatch = 1
action_end      = 2

segment readable executable

  start:

    mov rcx, qword [rsp]
    cmp rcx, 2
    jb .args_parsing_end

    mov rax, [rsp + 16]
    mov [path_root_dir], rax

    je .args_parsing_end

    mov rbx, [rsp + 24]
    mov [path_out_db], rbx

    cmp rcx, 4
    jb .args_parsing_end
    ja exit_failure_too_many_args

    mov rsi, [rsp + 32]
    xor ebx, ebx

    @@:

      movzx eax, byte [rsi]
      inc rsi
      test al, al
      jz @f

      lea rcx, [rbx + 4 * rbx]
      lea rbx, [rax + 2 * rcx]
      sub rbx, _char_zero
      jmp @b

    @@:

    cmp rbx, max_threads
    ja exit_failure_too_many_threads

    mov [threads_count], rbx

    .args_parsing_end:

    ; TODO: parse environment variables

    cmp qword [path_out_db], default_path_out_db
    jne .different_path_out

    mov eax, __NR_mkdir
    mov rdi, default_path_out_db_dir
    mov esi, (S_IRWXU or S_IRGRP or S_IXGRP or S_IROTH or S_IXOTH)
    syscall

    test rax, rax
    setnz bl
    cmp rax, -EEXIST
    setne bh
    test bl, bh
    jnz exit_failure_errno_path

    .different_path_out:

    mov eax, STDOUT_FILENO
    mov rsi, qword [path_out_db]
    cmp word [rsi], _char_hyphen
    je .out_is_stdout

    mov eax, __NR_openat
    mov edi, AT_FDCWD
    mov rsi, [path_out_db]
    mov edx, (O_WRONLY or O_CREAT or O_TRUNC)
    mov r10, (S_IRUSR or S_IWUSR or S_IRGRP or S_IROTH)
    syscall

    cmp rax, -4096
    mov rdi, [path_out_db]
    ja exit_failure_errno_path
    .out_is_stdout:
    mov [out_db_fd], rax
    mov [filebufs + 16], rax

    mov eax, __NR_openat
    mov edi, AT_FDCWD
    mov rsi, [path_root_dir]
    mov edx, (O_RDONLY or O_NOATIME or O_DIRECTORY)
    syscall

    cmp rax, -4096
    mov rdi, [path_root_dir]
    ja exit_failure_errno_path

    mov r12, rax

    mov r13, [threads_count]

    mov eax, __NR_mmap
    xor edi, edi
    imul esi, r13d, (thread_stack_size + filebuf_size)
    mov edx, (PROT_READ or PROT_WRITE)
    mov r10, (MAP_PRIVATE or MAP_ANONYMOUS or MAP_UNINITIALIZED)
    syscall

    cmp rax, -4096
    ja exit_failure_errno

    mov rbx, rax
    mov rax, r13
    shl rax, thread_stack_size_exp
    lea r15, [rbx + rax]

    lea rcx, [r13 - 1]
    shl rcx, 5

    @@:

      mov [filebufs + rcx], r15
      mov [filebufs + rcx + 8], 0
      mov [tfoffsets + rcx], 0
      mov [tfoffsets + rcx + 8], 0
      add r15, filebuf_size

      sub rcx, 32
      jns @b

    xor r15, r15

    sub rsp, realpath_buf_size

    mov r10, rbx

    mov rax, r12
    mov rdi, rsp
    mov edx, realpath_buf_size
    realpath_fd

    mov rbx, r10

    mov r14, rax

    mov rsi, rsp
    mov rcx, rax
    filebuf_write_nocheck

    cmp byte [rsp + r14 - 1], _char_slash
    je @f

    filebuf_write_1_char_nocheck _char_slash

    @@:

    filebuf_write_1_char_nocheck _char_null

    mov rdx, [filebufs + 8]
    filebuf_flush_buffer filebufs

    add rsp, realpath_buf_size

    mov r13, [threads_count]

    .thread_spawn_loop:

      dec r13
      jz thread_spawn_loop_skip

      mov r14, rbx
      add rbx, thread_stack_size

      mov rdi, r14
      mov eax, __NR_mprotect
      mov esi, _pagesize
      xor edx, edx
      syscall

      cmp rax, -4096
      ja exit_failure_errno

      lea rsi, [r14 + (thread_stack_size - 8)]
      mov [rsi], r13

      mov eax, __NR_clone
      mov edi, (CLONE_FILES or CLONE_FS or CLONE_THREAD or CLONE_SIGHAND or CLONE_VM)
      syscall

      cmp rax, -4096
      ja exit_failure_errno

      test rax, rax
      jz thread_entry

      jmp .thread_spawn_loop

    thread_spawn_loop_skip:

    mov eax, __NR_memfd_create
    mov rdi, tmpfile_debug_name
    xor esi, esi
    syscall

    cmp rax, -4096
    ja exit_failure_errno

    mov [filebufs + 16], rax

    xor r15, r15

    filebuf_write_1_char_and_skip_n_nocheck action_work, 16

    mov r13, [threads_count]
    dec r13

    push thread_sleep

    .wait_loop:

      mov rdx, [dispatch_count]
      cmp rdx, r13
      je @f

      mov eax, __NR_futex
      mov rdi, dispatch_count
      mov esi, (FUTEX_WAIT or FUTEX_PRIVATE_FLAG)
      mov r10, timeout
      xor r8, r8
      xor r9, r9
      syscall

      jmp .wait_loop

    @@:

    jmp walker

    thread_last:

    mov r15, [threads_count]
    shl r15, 5
    sub r15, 32

    @@:

      mov eax, __NR_write
      mov rdi, [filebufs + r15 + 16]
      mov rsi, [filebufs + r15]
      mov rdx, [filebufs + r15 + 8]
      syscall

      mov rsi, [tfoffsets + r15]
      test rsi, rsi
      jz .skip_mmap

      mov eax, __NR_mmap
      xor edi, edi
      mov edx, PROT_READ
      mov r10, (MAP_PRIVATE or MAP_POPULATE)
      mov r8, [filebufs + r15 + 16]
      xor r9, r9
      syscall

      .skip_mmap:
      mov [filebufs + r15 + 24], rax

      sub r15, 32
      jns @b

    xor r13, r13
    xor r15, r15

    push .exit

    ; r15 : tmpfile index * 32
    .rec:

      add r13, 17
      mov r10, [filebufs + r15 + 24]
      add r10, r13

      movzx eax, byte [r10 - 17]
      mov rbx, qword [r10 - 16]

      cmp al, action_dispatch
      je .dispatch
      ja .ret

      @@:

        mov eax, __NR_write
        mov rdi, [out_db_fd]
        mov rsi, r10
        mov rdx, rbx
        syscall

        add r13, rax
        sub rbx, rax

        jnz @b

      jmp .rec

      .dispatch:

        mov rcx, qword [r10 - 8]

        push r13
        mov r13, rbx
        push r15
        mov r15, rcx

        call .rec

        pop r15
        pop r13

        jmp .rec

      .ret:

        ret

    .exit:

      mov eax, __NR_exit_group
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
      mov edi, STDERR_FILENO
      mov rsi, r13
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

      mov eax, __NR_exit_group
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

    exit_failure_too_many_threads:

      mov eax, __NR_write
      mov edi, STDERR_FILENO
      mov rsi, msg_err
      mov edx, msg_err_sep_len
      syscall

      mov eax, __NR_write
      mov rsi, msg_err_too_many_threads
      mov edx, msg_err_too_many_threads_len
      syscall

      mov eax, __NR_exit_group
      dec edi ; 1 = STDERR_FILENO - 1
      syscall

  thread_exit:

    mov eax, __NR_exit
    xor edi, edi
    syscall

  thread_entry:

    mov rax, [rsp]
    mov r15, rax
    shl r15, 5
    mov qword [rsp], thread_sleep

    mov rbp, rsp

    if defined _debug_tmpfile_name

      sub rsp, (tmpfile_debug_name_len + 16)

      mov rdi, rsp
      mov rsi, tmpfile_debug_name
      mov ecx, tmpfile_debug_name_len
      rep movsb

      mov r11, rdi

      lea rdi, [rsp + tmpfile_debug_name_len + 16 - 1]

      mov rbx, 0xCCCCCCCCCCCCCCCD

      .id_fmt_loop:

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
        jnz .id_fmt_loop

      lea rcx, [rsp + tmpfile_debug_name_len + 16 - 1]
      sub rcx, rdi
      lea rsi, [rdi + 1]
      mov rdi, r11

      rep movsb
      mov byte [rdi], 0

    end if

    mov eax, __NR_memfd_create
    if defined _debug_tmpfile_name
      mov rdi, rsp
    else
      mov rdi, tmpfile_debug_name
    end if
    xor esi, esi
    syscall

    mov rsp, rbp

    cmp rax, -4096
    ja exit_failure_errno

    mov [filebufs + r15 + 16], rax

    jmp thread_sleep_skip

    thread_sleep:

      mov eax, __NR_close
      mov rdi, r12
      syscall

      mov rax, [tfoffsets + r15 + 8]
      lea rsi, [rax + 16]
      mov rcx, [filebufs + r15 + 8]
      cmp rsi, rcx
      ja .not_cached

      mov rdi, [filebufs + r15]
      add rdi, rcx
      sub rdi, rsi

      mov [rdi], rax

      filebuf_write_1_char_and_skip_n_nocheck action_end, 16

      jmp @f

      .not_cached:

      filebuf_write_1_char_and_skip_n_nocheck action_end, 16

      mov eax, __NR_pwrite64
      mov rdi, [filebufs + r15 + 16]
      lea rsi, [tfoffsets + r15 + 8]
      mov edx, 8
      mov r10, [tfoffsets + r15]
      inc r10
      syscall

      @@:

      mov rax, [tfoffsets + r15 + 8]
      add rax, 34
      add [tfoffsets + r15], rax
      mov qword [tfoffsets + r15 + 8], 0

      mov rax, [dispatch_count]
      inc rax
      cmp rax, [threads_count]

      je thread_last

      push thread_sleep

    thread_sleep_skip:

    dispatch_worker_idle r12, r15, threads_count, thread_last

    filebuf_write_1_char_and_skip_n_nocheck action_work, 16

    ; fallthrough

  ; r12 : fd
  walker:

    mov byte [rsp - 1], 0
    sub rsp, (dents_buf_size + 8) ; room to check for ".\0" or "..\0", 8 bytes padded

    .loop:

      mov word [rsp + (dents_buf_size - 2)], -1

      mov eax, __NR_getdents64
      mov rdi, r12
      mov rsi, rsp
      mov edx, dents_buf_size
      syscall

      cmp rax, -4096
      ja exit_failure_errno

      test rax, rax
      jz .loop_end

      mov r13, rsp
      lea r14, [rsp + rax]

      .ent_loop:

        ; TODO: dynamic filter list (jit compiled ?)

        cmp byte [r13 + 19], _char_dot
        sete bl
        mov edx, ebx
        cmp byte [r13 + 20], _char_null
        sete bh
        and bl, bh

        cmp word [r13 + 20], _char_dot ; ".\0"
        sete bh
        and dl, bh

        or bl, dl
        jnz .ent_loop_skip

        lea rsi, [r13 + 19]

        mov rdi, rsi
        mov ecx, esi
        and rdi, -8
        and ecx, 7
        shl ecx, 3
        mov r8, 0x0101010101010101
        mov r9, 0x8080808080808080

        mov rdx, [rdi]
        or rax, -1
        shl rax, cl
        not rax
        or rdx, rax

        .check:

          mov rax, rdx
          sub rax, r8
          not rdx
          and rax, rdx
          and rax, r9
          jnz .found
          add rdi, 8
          mov rdx, [rdi]
          jmp .check

        .found:

          bsf rcx, rax
          shr ecx, 3
          add rcx, rdi
          sub rcx, rsi
          inc rcx

        cmp byte [r13 + 18], DT_DIR
        je .ent_loop_dir
        cmp byte [r13 + 18], DT_UNKNOWN
        je .unknown
        .unknown_back:

        lea rsi, [r13 + 19]
        add [tfoffsets + r15 + 8], rcx
        filebuf_write filebuf_size

        movzx rax, word [r13 + 16]
        add r13, rax

        cmp r13, r14
        jne .ent_loop
        jmp .ent_loop_end

        .ent_loop_dir:

        lea rsi, [r13 + 19]
        lea rbx, [rcx + 1]
        add [tfoffsets + r15 + 8], rbx
        filebuf_write_m1_and_2_chars _char_slash, filebuf_size ; "/\0"

        mov eax, __NR_openat
        mov rdi, r12
        lea rsi, [r13 + 19]
        mov edx, (O_RDONLY or O_NOATIME or O_DIRECTORY)
        syscall

        cmp rax, -4096
        ja .on_openat_err

        mov r10, rax
        dispatch_try_dispatch rax, rbx, r8, r10
        test rax, rax
        jnz .dispatch

        push r12
        push r13
        push r14

        mov r12, r10

        call walker

        mov eax, __NR_close
        mov rdi, r12
        syscall

        pop r14
        pop r13
        pop r12

        .ent_loop_skip:

        movzx rax, word [r13 + 16]
        add r13, rax

        cmp r13, r14
        jne .ent_loop

        .ent_loop_end:

      jmp .loop

    .loop_end:

      inc qword [tfoffsets + r15 + 8]
      filebuf_write_1_char _char_slash, filebuf_size

      add rsp, (dents_buf_size + 1 + 7)

      ret

    .unknown:

      mov rbx, rcx

      mov eax, __NR_newfstatat
      mov rdi, r12
      lea rsi, [r13 + 19]
      mov rdx, r15
      shl rdx, (scratch_size_exp - 5)
      add rdx, scratch
      mov r10, AT_SYMLINK_NOFOLLOW
      syscall

      mov rcx, rbx

      cmp rax, -4096
      ja .unknown_back

      mov eax, dword [rdx + 24]
      and eax, S_IFMT

      cmp eax, S_IFDIR
      je .ent_loop_dir

      jmp .unknown_back

    .on_openat_err:

      inc qword [tfoffsets + r15 + 8]
      filebuf_write_1_char_nocheck _char_slash

      mov rsi, r13

      jmp .ent_loop_skip

    .dispatch:

      mov rax, [tfoffsets + r15 + 8]
      lea rsi, [rax + 16]
      mov rcx, [filebufs + r15 + 8]
      cmp rsi, rcx
      ja .not_cached

      mov rdi, [filebufs + r15]
      add rdi, rcx
      sub rdi, rsi

      mov [rdi], rax

      jmp @f

      .not_cached:

      mov eax, __NR_pwrite64
      mov rdi, [filebufs + r15 + 16]
      lea rsi, [tfoffsets + r15 + 8]
      mov edx, 8
      mov r10, [tfoffsets + r15]
      inc r10
      syscall

      @@:

      mov rax, [tfoffsets + r15 + 8]
      add rax, 34
      add [tfoffsets + r15], rax
      mov qword [tfoffsets + r15 + 8], 0

      mov rax, r8
      filebuf_write_1_char_and_16_and_1_char_and_skip_16_nocheck action_dispatch, action_work

      jmp .ent_loop_skip

segment readable

  timeout dq 0
          dq 0500000

  _char_null    = 0
  _char_newline = 10
  _char_hyphen  = '-'
  _char_dot     = '.'
  _char_slash   = '/'
  _char_zero    = '0'

  char_newline db _char_newline

  msg_err               db "error"
  msg_sep               db      ": "
  msg_err_sep_len = $ - msg_err
  msg_sep_len = $ - msg_sep
                        db        "Too many arguments", _char_newline
  label msg_err_too_many_args byte at msg_err
  msg_err_too_many_args_len = $ - msg_err_too_many_args

  macro db_int value {
    local val, divisor, digit
    val = value
    if val = 0
      db '0'
    else
      divisor = 1
      while divisor <= val / 10
      divisor = divisor * 10
      end while
      while divisor > 0
        digit = val / divisor
        db '0' + digit
        val = val - (digit * divisor)
        divisor = divisor / 10
      end while
    end if
  }

  msg_err_too_many_threads db "Too many threads (max: "
                                               db_int max_threads
                                                              db ")", 10
  msg_err_too_many_threads_len = $ - msg_err_too_many_threads

  default_path_root_dir   db "/", _char_null
  default_path_out_db_dir db "/var/cache/klocate", _char_null
  default_path_out_db     db "/var/cache/klocate/db", _char_null

  tmpfile_debug_name db "tmpfile"
  tmpfile_debug_name_len = $ - tmpfile_debug_name
  if defined _debug_tmpfile_name
    db _char_zero
  end if
  db _char_null

segment readable writeable

  out_db_fd dq -1

  path_root_dir dq default_path_root_dir
  path_out_db   dq default_path_out_db
  threads_count dq default_threads_count

  dispatch_declare max_threads

  filebufs  rq (max_threads * 4) ; 32 bytes padded
  tfoffsets rq (max_threads * 4) ; 32 bytes padded

  pipe_fds rd 2

  scratch rb (max_threads * scratch_size)

