format ELF64 executable 3
entry start

include "constants.inc"
include "realpath.inc"
include "filebuf.inc"
include "dispatch.inc"

_pagesize = 4096
realpath_buf_size = (4 * _pagesize)
dents_buf_size = (2 * _pagesize)
filebuf_size = (8 * _pagesize)
max_threads = 4
thread_initial_stack_size = (4 * _pagesize)

segment readable executable

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

    imul rcx, [threads_count], filebuf_struct_size
    sub rcx, filebuf_struct_size

    @@:

      mov [filebufs + rcx], rax
      mov [filebufs + rcx + 8], filebuf_size
      mov [filebufs + rcx + 16], 0
      add rax, filebuf_size

      sub rcx, filebuf_struct_size
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
      mov rdi, (CLONE_PARENT_SETTID or CLONE_CHILD_CLEARTID or CLONE_FILES or CLONE_FS or CLONE_THREAD or CLONE_SIGHAND or CLONE_VM)
      lea rdx, [tid + 4 * r13 - 4]
      mov r10, rdx
      xor r8, r8
      syscall

      cmp rax, -4096
      ja exit_failure_errno

      test rax, rax
      jz child_func

      dec r13
      jnz thread_spawn_loop

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

    call walker

    mov rax, __NR_write
    mov rsi, [filebufs]
    mov rdi, [filebufs + 24]
    mov rdx, [filebufs + 16]
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

  child_exit:

    mov rax, __NR_exit
    xor edi, edi
    syscall

  child_func:

    mov rax, [rsp]
    mov qword [rsp], child_exit

    dispatch_worker_idle r12, rax

    ret

  ; r12 : fd
  walker:

    push rbp
    mov rbp, rsp

    sub rsp, (dents_buf_size + 1) ; room to check for ".\0" or "..\0"

    walker_loop:

      mov word [rsp + (dents_buf_size - 2)], -1
      assert ~ (_char_null = -1) & ~ (_char_slash = -1)

      mov rax, __NR_getdents64
      mov rdi, r12
      mov rsi, rsp
      mov rdx, dents_buf_size
      syscall

      test rax, rax
      jz walker_loop_end

      mov rsi, rsp
      mov r14, rsp
      add r14, rax

      walker_ent_loop:

        cmp byte [rsi + 19], _char_dot
        sete bl
        mov edx, ebx
        cmp byte [rsi + 20], _char_null
        sete bh
        and bl, bh

        cmp word [rsi + 20], _char_dot ; ".\0"
        sete bh
        and dl, bh

        or bl, dl
        jnz walker_ent_loop_skip

        lea rdi, [rsi + 19]
        xor rax, rax
        mov rcx, -1
        cld
        repne scasb
        not rcx
        dec rcx

        mov r13, rsi

        cmp byte [rsi + 18], DT_DIR
        je walker_ent_loop_dir
        cmp byte [rsi + 18], DT_UNKNOWN
        je walker_unknown
        walker_unknown_back:

        lea rsi, [r13 + 19]
        inc rcx
        filebuf_write

        mov rsi, r13

        movzx rax, word [rsi + 16]
        add rsi, rax

        cmp rsi, r14
        jne walker_ent_loop
        jmp walker_ent_loop_end

        walker_ent_loop_dir:

        mov ax, (_char_slash + (_char_null shl 8))
        lea rsi, [r13 + 19]
        filebuf_write_and_2

        mov rax, __NR_openat
        mov rdi, r12
        lea rsi, [r13 + 19]
        mov rdx, (O_RDONLY or O_NOATIME or O_DIRECTORY)
        syscall

        mov rsi, r13

        cmp rax, -4096
        ja walker_on_openat_err

        push r12
        push r13
        push r14

        mov r12, rax

        call walker

        mov rax, __NR_close
        mov rdi, r12
        syscall

        pop r14
        pop rsi
        pop r12

        walker_ent_loop_skip:

        movzx rax, word [rsi + 16]
        add rsi, rax

        cmp rsi, r14
        jne walker_ent_loop

        walker_ent_loop_end:

      jmp walker_loop

    walker_loop_end:

    mov al, _char_slash
    filebuf_write_1

    mov rsp, rbp
    pop rbp

    ret

    walker_unknown:

      mov rbx, rcx

      mov rax, __NR_newfstatat
      mov rdi, r12
      lea rsi, [r13 + 19]
      mov rdx, statbuf
      mov r10, AT_SYMLINK_NOFOLLOW
      syscall

      mov rcx, rbx

      mov eax, dword [statbuf + 24]
      and eax, S_IFMT

      cmp eax, S_IFDIR
      je walker_ent_loop_dir

      jmp walker_unknown_back

    walker_on_openat_err:

      mov al, _char_slash
      filebuf_write_1

      mov rsi, r13

      jmp walker_ent_loop_skip

segment readable

  _char_slash = '/'
  _char_null = 0
  _char_newline = 10
  _char_dot = '.'

  char_slash db _char_slash
  char_null db _char_null
  char_newline db _char_newline
  char_slash_null = char_slash

  path_parent db '.'
  path_current db "./"
  path_parent_len = $ - path_parent
  path_current_len = $ - path_current

  msg_sep db ": "
  msg_sep_len = $ - msg_sep
  msg_err_too_many_args db "error: Too many arguments", 10
  msg_err_too_many_args_len = $ - msg_err_too_many_args

  default_path_root_dir db "/", 0
  default_path_out_db_dir db "/var/cache/klocate", 0
  default_path_out_db db "/var/cache/klocate/db", 0

segment readable writeable

  dispatch_declare max_threads

  tid rd (max_threads - 1)

  align 8

  timeout dq 0
          dq 1000000

  path_root_dir dq default_path_root_dir
  path_out_db dq default_path_out_db
  threads_count dq max_threads

  filebufs rq (4 * (max_threads - 1))
  statbuf rb 144 ; struct stat

