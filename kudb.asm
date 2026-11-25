format ELF64 executable 3
entry start

_strip_errno equ 0

include "macros.inc"
include "constants.inc"
include "realpath.inc"
include "filebuf.inc"
include "dispatch.inc"

_debug_tmpfile_name equ 1

pagesize              equ 4096           ; 4  Kib
realpath_buf_size     equ (4 * pagesize) ; 16 Kib
dents_buf_size        equ (2 * pagesize) ; 8  Kib
filebuf_size          equ (8 * pagesize) ; 32 Kib
pipe_buf              equ pagesize
max_threads           equ 64
default_threads_count equ 4
thread_stack_size_exp equ 24
thread_stack_size     equ (1 shl thread_stack_size_exp) ; (4 * 1024 * pagesize) = 4Mib
scratch_size_exp      equ 8
scratch_size          equ (1 shl scratch_size_exp) ; 256 bytes
ring_entries          equ 1024
ring_thread_idle_ms   equ 2000

action_work     equ 0
action_dispatch equ 1
action_end      equ 2

; TODO: add max dir recursion depth option
; TODO: add option to ignore hidden files and folders

segment readable executable

  start:

    mov rcx, qword [rsp]
    cmp rcx, 2
    jb .args_parsing_end

    mov rax, qword [rsp + 16]
    mov qword [path_root_dir], rax

    je .args_parsing_end

    mov rbx, qword [rsp + 24]
    mov qword [path_out_db], rbx

    cmp rcx, 4
    jb .args_parsing_end
    ja exit_failure_too_many_args

    mov rsi, qword [rsp + 32]
    xor ebx, ebx

    .parse_loop:

      movzx eax, byte [rsi]
      inc rsi
      test al, al
      jz .parse_loop_end

      lea rcx, [rbx + 4 * rbx]
      lea rbx, [rax + 2 * rcx]
      sub rbx, _char_digit_zero
      jmp .parse_loop

    .parse_loop_end:

    cmp rbx, max_threads
    ja exit_failure_too_many_threads

    mov qword [threads_count], rbx

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

      mov qword [path_out_db], rsi

      jmp .env_loop_end

      .env_loop_not_equal:

      add r8, 8
      jmp .env_loop

    .env_loop_end:

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
    cmp word [rsi], _char_hyphen_minus ; "-\0"
    je .out_is_stdout

    mov eax, __NR_openat
    mov edi, AT_FDCWD
    mov rsi, qword [path_out_db]
    mov edx, (O_WRONLY or O_CREAT or O_TRUNC)
    mov r10d, (S_IRUSR or S_IWUSR or S_IRGRP or S_IROTH)
    syscall

    cmp rax, -4096
    mov rdi, qword [path_out_db]
    ja exit_failure_errno_path
    .out_is_stdout:
    mov qword [out_db_fd], rax
    mov qword [filebufs + _offset_filebuf_fd], rax

    mov eax, __NR_openat
    mov edi, AT_FDCWD
    mov rsi, qword [path_root_dir]
    mov edx, (O_RDONLY or O_NOATIME or O_DIRECTORY)
    syscall

    cmp rax, -4096
    mov rdi, qword [path_root_dir]
    ja exit_failure_errno_path

    mov r12, rax

    mov r13, qword [threads_count]

    mov eax, __NR_mmap
    xor edi, edi
    imul rsi, r13, (thread_stack_size + filebuf_size)
    mov edx, (PROT_READ or PROT_WRITE)
    mov r10d, (MAP_PRIVATE or MAP_ANONYMOUS or MAP_UNINITIALIZED)
    mov r8, -1
    xor r9, r9
    syscall

    cmp rax, -4096
    ja exit_failure_errno

    mov rbx, rax
    mov rax, r13
    shl rax, thread_stack_size_exp
    lea r15, [rbx + rax]

    lea rcx, [r13 - 1]
    shl rcx, 5

    .zero_loop:

      mov qword [filebufs + rcx + _offset_filebuf_ptr], r15
      mov qword [filebufs + rcx + _offset_filebuf_len], 0
      mov qword [tfoffsets + rcx], 0
      mov qword [tfoffsets + rcx + 8], 0
      add r15, filebuf_size

      sub rcx, 32
      jns .zero_loop

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

    cmp byte [rsp + r14 - 1], _char_solidus
    je .skip_slash

    filebuf_write_1_char_nocheck _char_solidus

    .skip_slash:

    filebuf_write_1_char_nocheck _char_nul

    mov rdx, qword [filebufs + _offset_filebuf_len]
    filebuf_flush filebufs

    add rsp, realpath_buf_size

    mov r13, qword [threads_count]

    .thread_spawn_loop:

      dec r13
      jz thread_spawn_loop_skip

      mov r14, rbx
      add rbx, thread_stack_size

      lea rsi, [r14 + (thread_stack_size - 8)]
      mov qword [rsi], r13

      ; TODO: remove CLONE_FILES
      ; and request that each thread map their file and share ptr
      ; instead of mapping in the last thread
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

    mov qword [filebufs + _offset_filebuf_fd], rax

    xor r15, r15

    filebuf_write_1_char_and_skip_n_nocheck action_work, 16

    mov r13, qword [threads_count]
    dec r13

    push thread_sleep

    .wait_loop:

      mov rdx, qword [dispatch_count]
      cmp rdx, r13
      je .wait_loop_end

      mov eax, __NR_futex
      mov rdi, dispatch_count
      mov esi, FUTEX_WAIT ; FUTEX_PRIVATE_FLAG
      mov r10, timeout
      xor r8, r8
      xor r9, r9
      syscall

      jmp .wait_loop

    .wait_loop_end:

    jmp walker

    thread_last:

    mov r15, qword [threads_count]
    dec r15
    shl r15, 5

    .flush_loop:

      mov eax, __NR_write
      mov rdi, qword [filebufs + r15 + _offset_filebuf_fd]
      mov rsi, qword [filebufs + r15 + _offset_filebuf_ptr]
      mov rdx, qword [filebufs + r15 + _offset_filebuf_len]
      syscall

      mov rsi, qword [tfoffsets + r15]
      test rsi, rsi
      jz .skip_mmap

      mov eax, __NR_mmap
      xor edi, edi
      mov edx, PROT_READ
      mov r10d, (MAP_PRIVATE or MAP_POPULATE)
      mov r8, qword [filebufs + r15 + _offset_filebuf_fd]
      xor r9, r9
      syscall

      .skip_mmap:
      mov qword [tfoffsets + r15 + 24], rax

      sub r15, 32
      jns .flush_loop

    mov eax, __NR_io_uring_setup
    mov edi, ring_entries
    mov rsi, ring_params
    syscall

    cmp rax, -EINVAL
    sete dl
    cmp rax, -EPERM
    sete bl
    or dl, bl
    jnz thread_last_no_ring
    cmp rax, -4096
    ja exit_failure_errno

    mov [ring_fd], rax

    mov ecx, (IORING_FEAT_SINGLE_MMAP or IORING_FEAT_SQPOLL_NONFIXED)
    mov eax, [ring_params + _offset_p_features]
    and eax, ecx
    cmp eax, ecx
    jne thread_last_no_ring

    mov eax, __NR_mmap
    xor edi, edi
    mov esi, [ring_params + _offset_p_cq_entries]
    shl esi, 4
    add esi, [ring_params + _offset_p_cq_cqes]
    mov edx, (PROT_READ or PROT_WRITE)
    mov r10d, (MAP_SHARED or MAP_POPULATE)
    mov r8, [ring_fd]
    mov r9d, IORING_OFF_SQ_RING
    syscall

    cmp rax, -4096
    ja exit_failure_errno

    mov [ring_base], rax

    mov eax, __NR_mmap
    xor edi, edi
    mov esi, [ring_params + _offset_p_sq_entries]
    shl esi, 6
    mov edx, (PROT_READ or PROT_WRITE)
    mov r10d, (MAP_SHARED or MAP_POPULATE)
    mov r8, [ring_fd]
    mov r9d, IORING_OFF_SQES
    syscall

    cmp rax, -4096
    ja exit_failure_errno

    mov [sqes_base], rax

    xor r13, r13
    xor r15, r15

    push .fin

    mov r12, qword [out_db_fd]

    ; r15 : tmpfile index * 32
    .rec:

      add r13, 17
      mov rsi, qword [tfoffsets + r15 + 24]
      add rsi, r13

      movzx eax, byte [rsi - 17]
      mov rdx, qword [rsi - 16]

      cmp al, action_dispatch
      je .dispatch
      ja .ret

      add r13, rdx

      mov r8, qword [ring_base]
      mov eax, dword [ring_params + _offset_p_sq_tail]
      mov edi, dword [r8 + rax]
      mov r9d, dword [batch_count]
      lea eax, [rdi + r9]
      mov ecx, dword [ring_params + _offset_p_sq_entries]
      dec ecx
      and ecx, eax
      shl ecx, 6
      add rcx, [sqes_base]
      mov byte [rcx + _offset_sqe_opcode], IORING_OP_WRITE
      mov byte [rcx + _offset_sqe_flags], (IOSQE_IO_LINK or IOSQE_CQE_SKIP_SUCCESS or IOSQE_ASYNC)
      mov dword [rcx + _offset_sqe_fd], r12d
      mov qword [rcx + _offset_sqe_off], -1
      mov qword [rcx + _offset_sqe_addr], rsi
      mov dword [rcx + _offset_sqe_len], edx
      mov rax, rdx
      shl rax, 47
      or rax, rsi
      mov qword [rcx + _offset_sqe_user_data], rax
      inc r9d
      mov dword [batch_count], r9d
      cmp r9d, dword [ring_params + _offset_p_sq_entries]
      jb .end

      .publish:

        mov eax, dword [ring_params + _offset_p_sq_tail]
        mov edi, dword [r8 + rax]
        lea eax, [rdi + r9 - 1]
        mov ecx, dword [ring_params + _offset_p_sq_entries]
        dec ecx
        and ecx, eax
        shl ecx, 6
        add rcx, qword [sqes_base]
        mov byte [rcx + _offset_sqe_flags], IOSQE_ASYNC
        bts qword [rcx + _offset_sqe_user_data], 63
        add edi, r9d
        mov eax, dword [ring_params + _offset_p_sq_tail]
        mov dword [r8 + rax], edi
        mov dword [batch_count], 0

        mfence

        mov r10d, IORING_ENTER_GETEVENTS
        mov eax, dword [ring_params + _offset_p_sq_flags]
        test dword [r8 + rax], IORING_SQ_NEED_WAKEUP
        jz .wait
        or r10d, IORING_ENTER_SQ_WAKEUP

      .wait:

        mov eax, __NR_io_uring_enter
        mov rdi, qword [ring_fd]
        xor esi, esi
        mov edx, 1
        xor r8, r8
        xor r9, r9
        syscall

        mov r8, qword [ring_base]

      .reap:

        mov ecx, dword [ring_params + _offset_p_cq_head]
        mov eax, dword [r8 + rcx]
        mov ecx, dword [ring_params + _offset_p_cq_tail]
        cmp eax, dword [r8 + rcx]
        je .wait
        mov ecx, dword [ring_params + _offset_p_cq_entries]
        dec ecx
        and ecx, eax
        shl ecx, 4
        mov edi, [ring_params + _offset_p_cq_cqes]
        add rdi, r8
        add rdi, rcx
        mov r11, qword [rdi + _offset_cqe_user_data]
        mov r9d, dword [rdi + _offset_cqe_res]
        inc eax
        mov edi, dword [ring_params + _offset_p_cq_head]
        mov dword [r8 + rdi], eax
        mov rdx, r11
        shr rdx, 63
        mov rcx, r11
        shl rcx, 1
        shr rcx, 48
        cmp r9d, ecx
        je .ok
        test r9d, r9d
        jns .short
        cmp r9d, -EINTR
        je .again
        movsxd rax, r9d
        cmp r9d, -ECANCELED
        jne exit_failure_errno
        jmp .again

      .short:

        mov eax, r9d
        add r11, rax
        shl rax, 47
        sub r11, rax

      .again:

        mov rax, retry_ud
        mov ecx, [retry_n]
        mov qword [rax + 8 * rcx], r11
        inc ecx
        mov dword [retry_n], ecx

      .ok:

        test edx, edx
        jz .reap
        mov r9d, dword [retry_n]
        test r9d, r9d
        jz .end
        mov dword [retry_n], 0
        mov eax, dword [ring_params + _offset_p_sq_tail]
        mov edi, dword [r8 + rax]
        xor ebx, ebx

      .rebuf:

        lea eax, [rdi + rbx]
        mov ecx, dword [ring_params + _offset_p_sq_entries]
        dec ecx
        and ecx, eax
        shl ecx, 6
        add rcx, qword [sqes_base]
        mov rax, retry_ud
        mov rax, qword [rax + 8 * rbx]
        btr rax, 63
        mov r10, rax
        shr r10, 47
        mov rdx, rax
        shl rdx, 17
        shr rdx, 17
        mov byte [rcx + _offset_sqe_opcode], IORING_OP_WRITE
        mov byte [rcx + _offset_sqe_flags], (IOSQE_IO_LINK or IOSQE_CQE_SKIP_SUCCESS or IOSQE_ASYNC)
        mov dword [rcx + _offset_sqe_fd], r12d
        mov qword [rcx + _offset_sqe_off], -1
        mov qword [rcx + _offset_sqe_addr], rdx
        mov dword [rcx + _offset_sqe_len], r10d
        mov qword [rcx + _offset_sqe_user_data], rax
        inc ebx
        cmp ebx, r9d
        jb .rebuf
        jmp .publish

      .end:

      jmp .rec

      .dispatch:

        mov rcx, qword [rsi - 8]

        push r13
        mov r13, rdx
        push r15
        mov r15, rcx

        call .rec

        pop r15
        pop r13

        jmp .rec

      .ret:

        ret

    .fin:

      cmp dword [batch_count], 0
      je thread_last_no_ring.end
      mov r8, qword [ring_base]
      mov r9d, dword [batch_count]

    .fin_publish:

      mov eax, dword [ring_params + _offset_p_sq_tail]
      mov edi, dword [r8 + rax]
      lea eax, [rdi + r9 - 1]
      mov ecx, dword [ring_params + _offset_p_sq_entries]
      dec ecx
      and ecx, eax
      shl ecx, 6
      add rcx, qword [sqes_base]
      mov byte [rcx + _offset_sqe_flags], IOSQE_ASYNC
      bts qword [rcx + _offset_sqe_user_data], 63
      add edi, r9d
      mov eax, dword [ring_params + _offset_p_sq_tail]
      mov dword [r8 + rax], edi
      mov dword [batch_count], 0

      mfence

      mov r10d, IORING_ENTER_GETEVENTS
      mov eax, dword [ring_params + _offset_p_sq_flags]
      test dword [r8 + rax], IORING_SQ_NEED_WAKEUP
      jz .fin_wait
      or r10d, IORING_ENTER_SQ_WAKEUP

    .fin_wait:

      mov eax, __NR_io_uring_enter
      mov edi, dword [ring_fd]
      xor esi, esi
      mov edx, 1
      xor r8, r8
      xor r9, r9
      syscall

      mov r8, qword [ring_base]

    .fin_reap:

      mov ecx, dword [ring_params + _offset_p_cq_head]
      mov eax, dword [r8 + rcx]
      mov ecx, dword [ring_params + _offset_p_cq_tail]
      cmp eax, dword [r8 + rcx]
      je .fin_wait
      mov ecx, dword [ring_params + _offset_p_cq_entries]
      dec ecx
      and ecx, eax
      shl ecx, 4
      mov edi, dword [ring_params + _offset_p_cq_cqes]
      add rdi, r8
      add rdi, rcx
      mov r11, qword [rdi + _offset_cqe_user_data]
      mov r9d, dword [rdi + _offset_cqe_res]
      inc eax
      mov edi, dword [ring_params + _offset_p_cq_head]
      mov dword [r8 + rdi], eax
      mov rdx, r11
      shr rdx, 63
      mov rcx, r11
      shl rcx, 1
      shr rcx, 48
      cmp r9d, ecx
      je .fin_ok
      test r9d, r9d
      jns .fin_short
      cmp r9d, -EINTR
      je .fin_again
      movsxd rax, r9d
      cmp r9d, -ECANCELED
      jne exit_failure_errno
      jmp .fin_again

    .fin_short:

      mov eax, r9d
      add r11, rax
      shl rax, 47
      sub r11, rax

    .fin_again:

      mov rax, retry_ud
      mov ecx, dword [retry_n]
      mov qword [rax + 8 * rcx], r11
      inc ecx
      mov dword [retry_n], ecx

    .fin_ok:

      test edx, edx
      jz .fin_reap
      mov r9d, dword [retry_n]
      test r9d, r9d
      jz thread_last_no_ring.end
      mov dword [retry_n], 0
      mov eax, dword [ring_params + _offset_p_sq_tail]
      mov edi, dword [r8 + rax]
      xor ebx, ebx

    .fin_rebuf:

      lea eax, [rdi + rbx]
      mov ecx, dword [ring_params + _offset_p_sq_entries]
      dec ecx
      and ecx, eax
      shl ecx, 6
      add rcx, qword [sqes_base]
      mov rax, retry_ud
      mov rax, qword [rax + 8 * rbx]
      btr rax, 63
      mov r10, rax
      shr r10, 47
      mov rdx, rax
      shl rdx, 17
      shr rdx, 17
      mov byte [rcx + _offset_sqe_opcode], IORING_OP_WRITE
      mov byte [rcx + _offset_sqe_flags], (IOSQE_IO_LINK or IOSQE_CQE_SKIP_SUCCESS or IOSQE_ASYNC)
      mov dword [rcx + _offset_sqe_fd], r12d
      mov qword [rcx + _offset_sqe_off], -1
      mov qword [rcx + _offset_sqe_addr], rdx
      mov dword [rcx + _offset_sqe_len], r10d
      mov qword [rcx + _offset_sqe_user_data], rax
      inc ebx
      cmp ebx, r9d
      jb .fin_rebuf
      jmp .fin_publish

    thread_last_no_ring:

    xor r13, r13
    xor r15, r15

    push .end

    mov r12, qword [out_db_fd]
    imul rax, qword [threads_count], filebuf_size
    mov qword [filebufs + _offset_filebuf_capacity], rax
    mov qword [filebufs + _offset_filebuf_len], 0
    mov qword [filebufs + _offset_filebuf_fd], r12
    mov rax, qword [threads_count]
    shl rax, 5
    mov rax, qword [filebufs + rax - 32 + _offset_filebuf_ptr]
    mov qword [filebufs + _offset_filebuf_ptr], rax

    ; r15 : tmpfile index * 32
    .rec:

      add r13, 17
      mov r10, qword [tfoffsets + r15 + 24]
      add r10, r13

      movzx eax, byte [r10 - 17]
      mov rbx, qword [r10 - 16]

      cmp al, action_dispatch
      je .dispatch
      ja .ret

      mov rsi, r10
      mov rcx, rbx
      mov rdx, qword [filebufs + _offset_filebuf_capacity]
      add r13, rbx
      filebuf_write_big_capacity
      xor ebx, ebx

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

    .end:

      mov rdx, qword [filebufs + _offset_filebuf_len]
      filebuf_flush filebufs

      mov eax, __NR_write
      mov rdi, r12
      mov rsi, char_nul
      mov edx, 2
      syscall

      mov eax, __NR_exit_group
      xor edi, edi
      syscall

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

    mov eax, __NR_mprotect
    mov rdi, r14
    mov esi, pagesize
    xor edx, edx
    syscall

    cmp rax, -4096
    ja exit_failure_errno

    mov rax, qword [rsp]
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

        add ecx, _char_digit_zero
        mov byte [rdi], cl
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

    mov qword [filebufs + r15 + _offset_filebuf_fd], rax

    jmp thread_sleep_skip

    thread_sleep:

      mov eax, __NR_close
      mov rdi, r12
      syscall

      mov rax, qword [tfoffsets + r15 + 8]
      lea rsi, [rax + 16]
      mov rcx, qword [filebufs + r15 + _offset_filebuf_len]
      cmp rsi, rcx
      ja .not_cached

      mov rdi, qword [filebufs + r15 + _offset_filebuf_ptr]
      add rdi, rcx
      sub rdi, rsi

      mov qword [rdi], rax

      filebuf_write_1_char_and_skip_n_nocheck action_end, 16

      jmp .skip_ahead

      .not_cached:

      filebuf_write_1_char_and_skip_n_nocheck action_end, 16

      mov eax, __NR_pwrite64
      mov rdi, qword [filebufs + r15 + _offset_filebuf_fd]
      lea rsi, [tfoffsets + r15 + 8]
      mov edx, 8
      mov r10, qword [tfoffsets + r15]
      inc r10
      syscall

      .skip_ahead:

      mov rax, qword [tfoffsets + r15 + 8]
      add rax, 34
      add qword [tfoffsets + r15], rax
      mov qword [tfoffsets + r15 + 8], 0

      mov rax, qword [dispatch_count]
      inc rax
      cmp rax, qword [threads_count]

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

        cmp byte [r13 + 19], _char_full_stop
        sete bl
        mov edx, ebx
        cmp byte [r13 + 20], _char_nul
        sete cl
        and bl, cl

        cmp word [r13 + 20], _char_full_stop ; ".\0"
        sete cl
        and dl, cl

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

        mov rdx, qword [rdi]
        mov rax, -1
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
          mov rdx, qword [rdi]
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
        add qword [tfoffsets + r15 + 8], rcx
        filebuf_write filebuf_size

        movzx rax, word [r13 + 16]
        add r13, rax

        cmp r13, r14
        jne .ent_loop
        jmp .ent_loop_end

        .ent_loop_dir:

        lea rsi, [r13 + 19]
        mov word [rsi + rcx - 1], _char_solidus
        inc rcx
        add qword [tfoffsets + r15 + 8], rcx
        filebuf_write filebuf_size

        mov eax, __NR_openat
        mov rdi, r12
        lea rsi, [r13 + 19]
        mov edx, (O_RDONLY or O_NOATIME or O_DIRECTORY)
        syscall

        cmp rax, -4096
        ja .on_openat_err

        mov r10, rax

        cmp qword [dispatch_count], 0
        je .skip_dispatch

        dispatch_try_dispatch rax, rbx, r8, r10
        test rax, rax
        jnz .dispatch

        .skip_dispatch:

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
      filebuf_write_1_char _char_solidus, filebuf_size

      add rsp, (dents_buf_size + 8)

      ret

    .unknown:

      mov rbx, rcx

      mov eax, __NR_newfstatat
      mov rdi, r12
      lea rsi, [r13 + 19]
      mov rdx, r15
      shl rdx, (scratch_size_exp - 5)
      add rdx, scratch
      mov r10d, AT_SYMLINK_NOFOLLOW
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
      filebuf_write_1_char_nocheck _char_solidus

      mov rsi, r13

      jmp .ent_loop_skip

    .dispatch:

      mov rax, qword [tfoffsets + r15 + 8]
      lea rsi, [rax + 16]
      mov rcx, qword [filebufs + r15 + _offset_filebuf_len]
      cmp rsi, rcx
      ja .not_cached

      mov rdi, qword [filebufs + r15 + _offset_filebuf_ptr]
      add rdi, rcx
      sub rdi, rsi

      mov qword [rdi], rax

      jmp .skip_write

      .not_cached:

      mov eax, __NR_pwrite64
      mov rdi, qword [filebufs + r15 + _offset_filebuf_fd]
      lea rsi, [tfoffsets + r15 + 8]
      mov edx, 8
      mov r10, qword [tfoffsets + r15]
      inc r10
      syscall

      .skip_write:

      mov rax, qword [tfoffsets + r15 + 8]
      add rax, 34
      add qword [tfoffsets + r15], rax
      mov qword [tfoffsets + r15 + 8], 0

      mov rax, r8
      filebuf_write_1_char_and_16_and_1_char_and_skip_16_nocheck action_dispatch, action_work

      jmp .ent_loop_skip

segment readable

  timeout dq 0
          dq 0500000

  char_lf db _char_lf

  msg_err               db "error"
  msg_sep               db      ": "
  msg_err_sep_len = $ - msg_err
  msg_sep_len = $ - msg_sep
                        db        "Too many arguments", _char_lf
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

  default_path_root_dir   db "/", _char_nul
  default_path_out_db_dir db "/var/lib/klocate", _char_nul
  default_path_out_db     db "/var/lib/klocate/db", _char_nul

  tmpfile_debug_name db "tmpfile"
  tmpfile_debug_name_len = $ - tmpfile_debug_name
  if defined _debug_tmpfile_name
    db _char_digit_zero
  end if
  char_nul db 2 dup _char_nul

  env_klocate_db_path_id db "KLOCATE_DB_PATH="
  env_klocate_db_path_id_len = $ - env_klocate_db_path_id

segment readable writeable

  path_root_dir dq default_path_root_dir
  path_out_db   dq default_path_out_db
  threads_count dq default_threads_count

  ring_params:
    dd ring_entries
    dd ring_entries
    dd (IORING_SETUP_SQPOLL or IORING_SETUP_NO_SQARRAY or IORING_SETUP_CQSIZE or IORING_SETUP_CLAMP or IORING_SETUP_SINGLE_ISSUER)
    dd 0
    dd ring_thread_idle_ms
    dd 0
    dd 0
    dd 0, 0, 0
    db 40 dup 0
    db 40 dup 0

  dispatch_declare max_threads

  ring_base   rq 1
  sqes_base   rq 1
  batch_count rd 1
  retry_n     rd 1
  retry_ud    rq 256

  out_db_fd rq 1
  ring_fd   rq 1

  filebufs  rq (max_threads * 4) ; 32 bytes padded
  tfoffsets rq (max_threads * 4) ; 32 bytes padded

  pipe_fds rd 2

  scratch rb (max_threads * scratch_size)

