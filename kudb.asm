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
max_threads = 4
thread_initial_stack_size = (4 * _pagesize)

action_work     = 0
action_dispatch = 1
action_end      = 2

segment readable executable

  ; TODO: assert every syscall
  start:

    mov qword [filebufs + 24], -1

    cmp qword [rsp], 1
    je args_parsing_end

    mov rbx, [rsp + 16]
    mov [path_root_dir], rbx

    cmp qword [rsp], 3
    ja exit_failure_too_many_args
    jb args_parsing_end

    mov rbx, [rsp + 24]
    mov [path_out_db], rbx

    ; TODO: parse threads count
    mov [threads_count], max_threads

    args_parsing_end:

    cmp qword [path_out_db], default_path_out_db
    jne different_path_out

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

    different_path_out:

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

    mov rax, __NR_mmap
    xor edi, edi
    imul rsi, [threads_count], filebuf_size
    mov rdx, (PROT_READ or PROT_WRITE)
    mov r10, (MAP_PRIVATE or MAP_ANONYMOUS)
    xor r8, r8
    dec r8
    xor r9, r9
    syscall

    cmp eax, -4096
    ja exit_failure_errno

    imul rcx, [threads_count], 32
    sub rcx, 32

    @@:

      mov [filebufs + rcx], rax
      add rax, filebuf_size

      sub rcx, 32
      jns @b

    xor r15, r15

    sub rsp, realpath_buf_size

    mov rax, r12
    mov rdi, rsp
    mov rdx, realpath_buf_size
    call realpath_fd

    mov r14, rax

    mov rsi, rsp
    mov rcx, rax
    filebuf_write

    cmp byte [rsp + r14 - 1], _char_slash
    je @f

    mov al, _char_slash
    filebuf_write_1

    @@:

    mov al, _char_null
    filebuf_write_1

    mov rsi, filebufs
    mov rdx, [filebufs + 16]
    mov r10, @f
    jmp filebuf_flush
    @@:

    add rsp, realpath_buf_size

    mov r13, [threads_count]
    dec r13
    jz thread_spawn_loop_skip
    mov rbx, r13

    thread_spawn_loop:

      mov rax, __NR_mmap
      xor edi, edi
      mov rsi, thread_initial_stack_size
      mov rdx, (PROT_READ or PROT_WRITE)
      mov r10, (MAP_PRIVATE or MAP_ANONYMOUS or MAP_STACK or MAP_GROWSDOWN)
      xor r8, r8
      dec r8
      xor r9, r9
      syscall

      cmp rax, -4096
      ja exit_failure_errno

      mov rsi, rax
      add rsi, (thread_initial_stack_size - 8)
      mov [rsi], r13

      mov rax, __NR_clone
      mov rdi, (CLONE_FILES or CLONE_FS or CLONE_THREAD or CLONE_SIGHAND or CLONE_VM)
      syscall

      cmp rax, -4096
      ja exit_failure_errno

      test rax, rax
      jz thread_entry

      dec r13
      jnz thread_spawn_loop

    thread_spawn_loop_skip:

    mov rax, __NR_memfd_create
    mov rdi, tmpfile_debug_name
    xor rsi, rsi
    syscall

    cmp rax, -4096
    ja exit_failure_errno

    mov [filebufs + 24], rax

    mov al, action_work
    filebuf_write_1_and_skip_n 8

    mov rax, thread_sleep
    push rax

    wait_loop:

      mov rdx, [dispatch_count]
      cmp rdx, rbx
      je @f

      mov rax, __NR_futex
      mov rdi, dispatch_count
      mov rsi, (FUTEX_WAIT or FUTEX_PRIVATE_FLAG)
      mov r10, timeout
      xor r8, r8
      xor r9, r9
      syscall

      jmp wait_loop

    @@:

    jmp walker

    thread_last:

    imul rbx, [threads_count], 32
    sub rbx, 32

    @@:

      mov rax, __NR_write
      mov rsi, [filebufs + rbx]
      mov rdi, [filebufs + rbx + 24]
      mov rdx, [filebufs + rbx + 16]
      syscall

      sub rbx, 32
      jns @b

    ; TODO: open pipes

    imul rbx, [threads_count], 32
    sub rbx, 32

    @@:

      mov [tfoffsets + rbx], 0
      ; mov [tfoffsets + 4 * rbx + 8], 0

      sub rbx, 32
      jns @b

    mov rax, __NR_pipe
    mov rdi, pipe_fds
    syscall

    mov rax, __NR_fcntl
    mov edi, [pipe_fds]
    mov rsi, F_GETPIPE_SZ
    xor edx, edx
    syscall

    cmp rax, -4096
    ja exit_failure_errno

    mov r13, rax

    xor r15, r15

    mov rax, thread_last_exit
    push rax

    ; r15 : tmpfile index * 32
    thread_last_rec: ; TODO: broken because of stack: [r15][action][rip]
                     ; and need a action_end when a thread goes to sleep

      mov rax, __NR_pread64
      mov rdi, [filebufs + r15 + 24]
      mov rsi, scratch
      mov rdx, 9
      mov r10, [tfoffsets + r15]
      syscall

      cmp rax, -4096
      ja exit_failure_errno
      test rax, rax
      jz thread_last_rec_ret

      mov al, [scratch]
      mov rbx, qword [scratch + 1]

      cmp al, action_dispatch
      je thread_last_rec_dispatch
      ja thread_last_rec_ret

      add [tfoffsets + r15], 9

      @@:

        mov r12, rbx
        cmp r12, r13
        cmova r12, r13

        mov rax, __NR_splice
        mov rdi, [filebufs + r15 + 24]
        lea rsi, [tfoffsets + r15]
        mov edx, [pipe_fds + 4]
        xor r10, r10
        mov r8, r12
        xor r9, r9
        syscall

        cmp rax, -4096
        ja exit_failure_errno

        mov r8, rax
        mov rax, __NR_splice
        mov edi, [pipe_fds]
        xor esi, esi
        mov rdx, [out_db_fd]
        xor r10, r10
        xor r9, r9
        syscall

        cmp rax, -4096
        ja exit_failure_errno

        sub rbx, rax

        jnz @b

      jmp thread_last_rec

      thread_last_rec_dispatch:

        add [tfoffsets + r15], 9

        push r15
        mov r15, rbx

        call thread_last_rec

        pop r15

        jmp thread_last_rec

      thread_last_rec_ret:

        add [tfoffsets + r15], 1

        ret

    thread_last_exit:

    mov rax, __NR_close
    mov rdi, [out_db_fd]
    syscall

    mov rax, __NR_exit_group
    xor edi, edi
    syscall

    exit_failure_errno_path:

      mov r12, rax
      mov r13, rdi

      xor rax, rax
      mov rcx, -1
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
      mov rdx, 1
      syscall

      mov rax, __NR_exit_group
      mov edi, 1
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
      mov rdx, 1
      syscall

      mov rax, __NR_exit_group
      mov edi, 1
      syscall

    exit_failure_too_many_args:

      mov rax, __NR_write
      mov rdi, STDERR_FILENO
      mov rsi, msg_err_too_many_args
      mov rdx, msg_err_too_many_args_len
      syscall

      mov rax, __NR_exit_group
      mov edi, 1
      syscall

  thread_exit:

    mov rax, __NR_exit
    xor edi, edi
    syscall

  thread_entry:

    imul r15, [rsp], 32
    mov qword [rsp], thread_sleep

    mov rax, __NR_memfd_create
    mov rdi, tmpfile_debug_name
    xor rsi, rsi
    syscall

    cmp rax, -4096
    ja exit_failure_errno

    mov [filebufs + r15 + 24], rax

    jmp thread_sleep_skip

    thread_sleep:

      mov rax, __NR_close
      mov rdi, r12
      syscall

      mov al, action_end
      filebuf_write_1

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
      add rax, 10
      add [tfoffsets + r15], rax
      mov qword [tfoffsets + r15 + 8], 0

      mov rax, [dispatch_count]
      inc rax
      cmp rax, [threads_count]

      je thread_last

      mov rax, thread_sleep
      push rax

    thread_sleep_skip:

    dispatch_worker_idle r12, r15, threads_count, thread_last

    mov al, action_work
    filebuf_write_1_and_skip_n 8

    ; fallthrough

  ; r12 : fd
  walker:

    push rbp
    mov rbp, rsp

    sub rsp, (dents_buf_size + 1) ; room to check for ".\0" or "..\0"

    walker_loop:

      mov word [rsp + (dents_buf_size - 2)], -1
      assert ~(_char_null = -1) & ~(_char_slash = -1)

      mov rax, __NR_getdents64
      mov rdi, r12
      mov rsi, rsp
      mov rdx, dents_buf_size
      syscall

      test rax, rax
      jz walker_loop_end

      mov r13, rsp
      mov r14, rsp
      add r14, rax

      walker_ent_loop:

        ; TODO: dynamic filter list

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
        jnz walker_ent_loop_skip

        lea rdi, [r13 + 19]
        xor rax, rax
        mov rcx, -1
        cld
        repne scasb
        not rcx
        dec rcx

        cmp byte [r13 + 18], DT_DIR
        je walker_ent_loop_dir
        cmp byte [r13 + 18], DT_UNKNOWN
        je walker_unknown
        walker_unknown_back:

        lea rsi, [r13 + 19]
        inc rcx
        add [tfoffsets + r15 + 8], rcx
        filebuf_write

        movzx rax, word [r13 + 16]
        add r13, rax

        cmp r13, r14
        jne walker_ent_loop
        jmp walker_ent_loop_end

        walker_ent_loop_dir:

        mov ax, (_char_slash + (_char_null shl 8))
        lea rsi, [r13 + 19]
        mov rbx, rcx
        add rbx, 2
        add [tfoffsets + r15 + 8], rbx
        filebuf_write_and_2

        mov rax, __NR_openat
        mov rdi, r12
        lea rsi, [r13 + 19]
        mov rdx, (O_RDONLY or O_NOATIME or O_DIRECTORY)
        syscall

        cmp rax, -4096
        ja walker_on_openat_err

        mov r10, rax
        dispatch_try_dispatch rax, rbx, r10
        test rax, rax
        jnz walker_dispatch

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

        walker_ent_loop_skip:

        movzx rax, word [r13 + 16]
        add r13, rax

        cmp r13, r14
        jne walker_ent_loop

        walker_ent_loop_end:

      jmp walker_loop

    walker_loop_end:

    mov al, _char_slash
    inc qword [tfoffsets + r15 + 8]
    filebuf_write_1

    mov rsp, rbp
    pop rbp

    ret

    walker_unknown:

      mov rbx, rcx

      mov rax, __NR_newfstatat
      mov rdi, r12
      lea rsi, [r13 + 19]
      mov rdx, scratch
      mov r10, AT_SYMLINK_NOFOLLOW
      syscall

      mov rcx, rbx

      mov eax, dword [scratch + 24]
      and eax, S_IFMT

      cmp eax, S_IFDIR
      je walker_ent_loop_dir

      jmp walker_unknown_back

    walker_on_openat_err:

      mov al, _char_slash
      inc qword [tfoffsets + r15 + 8]
      filebuf_write_1

      mov rsi, r13

      jmp walker_ent_loop_skip

    walker_dispatch:

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
      add rax, 18
      add [tfoffsets + r15], rax
      mov qword [tfoffsets + r15 + 8], 0

      ; TODO: fuse writes
      mov al, action_dispatch
      filebuf_write_1_and_8

      mov al, action_work
      filebuf_write_1_and_skip_n 8

      jmp walker_ent_loop_skip

segment readable

  _char_slash   = '/'
  _char_null    = 0
  _char_newline = 10
  _char_dot     = '.'

  char_slash_null:
  char_slash db _char_slash
  char_newline db _char_newline

  path_parent db '.'
  path_current db "./"
  path_parent_len = $ - path_parent
  path_current_len = $ - path_current

  msg_sep db ": "
  msg_sep_len = $ - msg_sep
  msg_err_too_many_args db "error: Too many arguments", 10
  msg_err_too_many_args_len = $ - msg_err_too_many_args

  default_path_root_dir db   "/", 0
  default_path_out_db_dir db "/var/cache/klocate", 0
  default_path_out_db db     "/var/cache/klocate/db", 0

  tmpfile_debug_name db "tmpfile", 0

segment readable writeable

  dispatch_declare max_threads

  align 8

  timeout dq 0
          dq 1000000

  out_db_fd dq -1

  pipe_capacity dq _pagesize

  path_root_dir dq default_path_root_dir
  path_out_db dq default_path_out_db
  threads_count dq max_threads

  filebufs dq max_threads dup (0, filebuf_size, 0, -1)
  tfoffsets dq max_threads dup (0, 0, ?, ?) ; 32 bytes padded
  pipe_fds rd 2

  scratch rb 144 ; struct stat

