format ELF64 executable 3
entry start

_errno_compact = 1
include "constants.inc"
include "realpath.inc"
include "filebuf.inc"
include "dispatch.inc"

_pagesize = 4096
realpath_buf_size = (4 * _pagesize)
dents_buf_size    = (2 * _pagesize)
filebuf_size      = (8 * _pagesize)
pipe_buf = _pagesize
max_threads = 16 ; TODO: get rid of all limitaions imposed at assembly time
default_threads_count = 4
thread_stack_size_exp = 24
thread_stack_size = (1 shl thread_stack_size_exp) ; (4 * 1024 * _pagesize)
scratch_size_exp = 8
scratch_size = (1 shl scratch_size_exp)

action_work     = 0
action_dispatch = 1
action_end      = 2

segment readable executable

  start:

    mov qword [filebufs + 24], -1

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
      test eax, eax
      jz @f

      lea rcx, [rbx + 4 * rbx]
      lea rbx, [rax + 2 * rcx]
      sub rbx, _char_zero
      jmp @b

    @@:

    mov [threads_count], rbx

    .args_parsing_end:

    ; TODO: parse environment variables

    cmp qword [path_out_db], default_path_out_db
    jne .different_path_out

    mov rax, __NR_mkdir
    mov rdi, default_path_out_db_dir
    mov rsi, (S_IRWXU or S_IRGRP or S_IXGRP or S_IROTH or S_IXOTH)
    syscall

    test rax, rax
    setnz bl
    cmp rax, -EEXIST
    setne bh
    test bl, bh
    mov rdi, default_path_out_db_dir
    jnz exit_failure_errno_path

    .different_path_out:

    mov rax, __NR_openat
    mov rdi, AT_FDCWD
    mov rsi, [path_out_db]
    mov rdx, (O_WRONLY or O_CREAT or O_TRUNC)
    mov r10, (S_IRUSR or S_IWUSR or S_IRGRP or S_IROTH)
    syscall

    cmp rax, -4096
    mov rdi, [path_out_db]
    ja exit_failure_errno_path
    mov [out_db_fd], rax
    mov [filebufs + 24], rax

    mov rax, __NR_openat
    mov rdi, AT_FDCWD
    mov rsi, [path_root_dir]
    mov rdx, (O_RDONLY or O_NOATIME or O_DIRECTORY)
    syscall

    cmp rax, -4096
    mov rdi, [path_root_dir]
    ja exit_failure_errno_path

    mov r12, rax

    mov r13, [threads_count]

    mov rax, __NR_mmap
    xor edi, edi
    imul rsi, r13, (thread_stack_size + filebuf_size)
    mov rdx, (PROT_READ or PROT_WRITE)
    mov r10, (MAP_PRIVATE or MAP_ANONYMOUS or MAP_UNINITIALIZED)
    xor r8, r8
    dec r8
    xor r9, r9
    syscall

    cmp eax, -4096
    ja exit_failure_errno

    mov rbx, rax
    mov rax, r13
    shl rax, thread_stack_size_exp
    lea r15, [rbx + rax]

    lea rcx, [r13 - 1]
    shl rcx, 5

    @@:

      mov [filebufs + rcx], r15
      add r15, filebuf_size

      sub rcx, 32
      jns @b

    xor r15, r15

    sub rsp, realpath_buf_size

    mov r10, rbx

    mov rax, r12
    mov rdi, rsp
    mov rdx, realpath_buf_size
    realpath_fd

    mov rbx, r10

    mov r14, rax

    mov rsi, rsp
    mov rcx, rax
    filebuf_write

    cmp byte [rsp + r14 - 1], _char_slash
    je @f

    filebuf_write_1_char _char_slash

    @@:

    filebuf_write_1_char _char_null

    mov rsi, filebufs
    mov rdx, [filebufs + 16]
    mov r10, @f
    jmp filebuf_flush
    @@:

    add rsp, realpath_buf_size

    mov r13, [threads_count]

    .thread_spawn_loop:

      dec r13
      jz thread_spawn_loop_skip

      mov r14, rbx
      add rbx, thread_stack_size

      mov rdi, r14
      mov rax, __NR_mprotect
      mov esi, _pagesize
      xor edx, edx
      syscall

      cmp rax, -4096
      ja exit_failure_errno

      lea rsi, [r14 + (thread_stack_size - 8)]
      mov [rsi], r13

      mov rax, __NR_clone
      mov rdi, (CLONE_FILES or CLONE_FS or CLONE_THREAD or CLONE_SIGHAND or CLONE_VM)
      syscall

      cmp rax, -4096
      ja exit_failure_errno

      test rax, rax
      jz thread_entry

      jmp .thread_spawn_loop

    thread_spawn_loop_skip:

    mov rax, __NR_memfd_create
    mov rdi, tmpfile_debug_name
    xor esi, esi
    syscall

    cmp rax, -4096
    ja exit_failure_errno

    mov [filebufs + 24], rax

    xor r15, r15

    filebuf_write_1_char_and_skip_n action_work, 16

    mov r13, [threads_count]
    dec r13

    push thread_sleep

    .wait_loop:

      mov rdx, [dispatch_count]
      cmp rdx, r13
      je @f

      mov rax, __NR_futex
      mov rdi, dispatch_count
      mov rsi, (FUTEX_WAIT or FUTEX_PRIVATE_FLAG)
      mov r10, timeout
      xor r8, r8
      xor r9, r9
      syscall

      jmp .wait_loop

    @@:

    jmp walker

    thread_last:

    mov rbx, [threads_count]
    shl rbx, 5
    sub rbx, 32

    @@:

      mov rax, __NR_write
      mov rsi, [filebufs + rbx]
      mov rdi, [filebufs + rbx + 24]
      mov rdx, [filebufs + rbx + 16]
      syscall

      sub rbx, 32
      jns @b

    mov [tfoffsets], 0

    mov rax, __NR_pipe
    mov rdi, pipe_fds
    syscall

    mov rax, __NR_fcntl
    mov edi, [pipe_fds]
    mov rsi, F_GETPIPE_SZ
    xor edx, edx
    syscall

    mov rbx, pipe_buf
    cmp rax, -4096
    cmova rax, rbx

    mov r13, rax

    xor r15, r15

    push .exit

    ; r15 : tmpfile index * 32
    .rec:

      xor r14, r14
      mov ebx, 17

      @@:

        mov edx, 17
        cmp ebx, edx
        cmovb edx, ebx

        mov rax, __NR_pread64
        mov rdi, [filebufs + r15 + 24]
        lea rsi, [scratch + r14]
        mov r10, [tfoffsets]
        add r10, r14
        syscall

        test rax, rax
        jz .ret

        cmp rax, -4096
        ja exit_failure_errno

        add r14, rax
        sub ebx, eax

        jnz @b

      movzx eax, byte [scratch]
      mov rbx, qword [scratch + 1]

      add [tfoffsets], 17

      cmp eax, action_dispatch
      je .dispatch
      ja .ret

      @@:

        mov r12, rbx
        cmp r12, r13
        cmova r12, r13

        mov rax, __NR_splice
        mov rdi, [filebufs + r15 + 24]
        lea rsi, [tfoffsets]
        mov edx, [pipe_fds + 4]
        xor r10, r10
        mov r8, r12
        xor r9, r9
        syscall

        mov r8, rax
        mov rax, __NR_splice
        mov edi, [pipe_fds]
        xor esi, esi
        mov rdx, [out_db_fd]
        xor r10, r10
        xor r9, r9
        mov r9, SPLICE_F_MORE
        syscall

        sub rbx, rax

        jnz @b

      jmp .rec

      .dispatch:

        mov rcx, qword [scratch + 9]

        push [tfoffsets]
        mov [tfoffsets], rbx
        push r15
        mov r15, rcx

        call .rec

        pop r15
        pop [tfoffsets]

        jmp .rec

      .ret:

        ret

    .exit:

      mov rax, __NR_exit_group
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

      mov rax, __NR_exit_group
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

      mov rax, __NR_exit_group
      xor edi, edi
      inc edi
      syscall

    exit_failure_too_many_args:

      mov rax, __NR_write
      mov rdi, STDERR_FILENO
      mov rsi, msg_err_too_many_args
      mov rdx, msg_err_too_many_args_len
      syscall

      mov rax, __NR_exit_group
      xor edi, edi
      inc edi
      syscall

  thread_exit:

    mov rax, __NR_exit
    xor edi, edi
    syscall

  thread_entry:

    mov rax, [rsp]
    mov r15, rax
    shl r15, 5
    mov qword [rsp], thread_sleep

    ; TODO: this section is only useful for debugging
    mov rbp, rsp
    sub rsp, (tmpfile_debug_name_len + 16)

    mov rdi, rsp
    mov rsi, tmpfile_debug_name
    mov rcx, tmpfile_debug_name_len
    rep movsb

    mov r11, rdi

    lea rdi, [rsp + tmpfile_debug_name_len + 16 - 1]

    mov rbx, 0xCCCCCCCCCCCCCCCD ; 2^66 / 5

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

    mov rax, __NR_memfd_create
    mov rdi, rsp
    xor esi, esi
    syscall

    mov rsp, rbp

    cmp rax, -4096
    ja exit_failure_errno

    mov [filebufs + r15 + 24], rax

    jmp thread_sleep_skip

    thread_sleep:

      mov rax, __NR_close
      mov rdi, r12
      syscall

      filebuf_write_1_char_and_skip_n action_end, 16

      lea rsi, [filebufs + r15]
      mov rdx, [filebufs + r15 + 16]
      mov r10, @f
      jmp filebuf_flush
      @@:

      mov rax, __NR_pwrite64
      mov rdi, [filebufs + r15 + 24]
      lea rsi, [tfoffsets + r15 + 8]
      mov rdx, 8
      mov r10, [tfoffsets + r15]
      inc r10
      syscall

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

    filebuf_write_1_char_and_skip_n action_work, 16

    ; fallthrough

  ; r12 : fd
  walker:

    mov byte [rsp - 1], 0
    sub rsp, (dents_buf_size + 1 + 7) ; room to check for ".\0" or "..\0" and 7 bytes of padding

    .loop:

      mov word [rsp + (dents_buf_size - 2)], -1

      mov rax, __NR_getdents64
      mov rdi, r12
      mov rsi, rsp
      mov rdx, dents_buf_size
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

        lea rdi, [r13 + 19]
        xor eax, eax
        xor ecx, ecx
        dec rcx
        cld
        repne scasb
        not rcx

        cmp byte [r13 + 18], DT_DIR
        je .ent_loop_dir
        cmp byte [r13 + 18], DT_UNKNOWN
        je .unknown
        .unknown_back:

        lea rsi, [r13 + 19]
        add [tfoffsets + r15 + 8], rcx
        filebuf_write

        movzx rax, word [r13 + 16]
        add r13, rax

        cmp r13, r14
        jne .ent_loop
        jmp .ent_loop_end

        .ent_loop_dir:

        lea rsi, [r13 + 19]
        lea rbx, [rcx + 1]
        add [tfoffsets + r15 + 8], rbx
        filebuf_write_m1_and_2_chars _char_slash ; ".\0"

        mov rax, __NR_openat
        mov rdi, r12
        lea rsi, [r13 + 19]
        mov rdx, (O_RDONLY or O_NOATIME or O_DIRECTORY)
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

        mov rax, __NR_close
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
      filebuf_write_1_char _char_slash

      add rsp, (dents_buf_size + 1 + 7)

      ret

    .unknown:

      mov rbx, rcx

      mov rax, __NR_newfstatat
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
      filebuf_write_1_char _char_slash

      mov rsi, r13

      jmp .ent_loop_skip

    .dispatch:

      lea rsi, [filebufs + r15]
      mov rdx, [rsi + 16]
      mov r10, @f
      jmp filebuf_flush
      @@:

      mov rax, __NR_pwrite64
      mov rdi, [filebufs + r15 + 24]
      lea rsi, [tfoffsets + r15 + 8]
      mov rdx, 8
      mov r10, [tfoffsets + r15]
      inc r10
      syscall

      mov rax, [tfoffsets + r15 + 8]
      add rax, 34
      add [tfoffsets + r15], rax
      mov qword [tfoffsets + r15 + 8], 0

      mov rax, r8
      filebuf_write_1_char_and_16_and_1_char_and_skip_16 action_dispatch, action_work

      jmp .ent_loop_skip

segment readable

  timeout dq 0
          dq 0500000

  _char_null    = 0
  _char_newline = 10
  _char_dot     = '.'
  _char_slash   = '/'
  _char_zero    = '0'

  char_newline db _char_newline

  msg_err_too_many_args db "error"
  msg_sep               db      ": "
  msg_sep_len = $ - msg_sep
                        db        "Too many arguments", _char_newline
  msg_err_too_many_args_len = $ - msg_err_too_many_args

  default_path_root_dir   db "/", _char_null
  default_path_out_db_dir db "/var/cache/klocate", _char_null
  default_path_out_db     db "/var/cache/klocate/db", _char_null

  tmpfile_debug_name db "tmpfile"
  tmpfile_debug_name_len = $ - tmpfile_debug_name
  db _char_zero, _char_null

segment readable writeable

  out_db_fd dq -1

  path_root_dir dq default_path_root_dir
  path_out_db   dq default_path_out_db
  threads_count dq default_threads_count

  ; TODO: remove the require and set to zero at runtime
  filebufs  dq max_threads dup (0, filebuf_size, 0, -1)
  tfoffsets dq max_threads dup (0, 0, ?, ?) ; 32 bytes padded

  dispatch_declare max_threads

  pipe_fds rd 2

  scratch rb (max_threads * scratch_size)

