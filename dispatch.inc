
macro dispatch_declare max {

  align 64
  dispatch_lock  dq 0
  dispatch_count dq 0
  dispatch_stack rq max

}

; destroys : rax
macro dispatch_lock_state {

  local .try, .spin, .end

  .try:

    mov eax, 1
    xchg qword [dispatch_lock], rax
    test al, al
    jz .end

  .spin:

    pause
    cmp qword [dispatch_lock], 0
    jne .spin
    jmp .try

  .end:

}

; reg_task : 64 bit register
; reg_id   : 64 bit register containing worker id
; destroys : rax, rcx, rdx, rsi, rdi, r10, r11, reg_task (containing dispatched task)
macro dispatch_worker_idle reg_task, reg_id, threads_count_ptr, thread_last_label {

  local .wait, .woken, .last

  sub rsp, 24
  mov dword [rsp], 0
  mov qword [rsp + 8], reg_id
  mov qword [rsp + 16], 0

  dispatch_lock_state

  mov rax, qword [dispatch_count]
  mov qword [dispatch_stack + 8 * rax], rsp
  inc rax
  cmp rax, qword [threads_count_ptr]
  je .last
  mov qword [dispatch_count], rax
  mov qword [dispatch_lock], 0

  .wait:

    cmp dword [rsp], 0
    jne .woken

    mov eax, __NR_futex
    mov rdi, rsp
    mov esi, (FUTEX_WAIT or FUTEX_PRIVATE_FLAG)
    xor edx, edx
    xor r10, r10
    syscall

    jmp .wait

  .last:

  mov qword [dispatch_lock], 0
  add rsp, 24
  jmp thread_last_label

  .woken:

  mov reg_task, qword [rsp + 16]
  add rsp, 24

}

; reg_task : 64 bit register containing task to dispatch
; reg_id   : 64 bit register containing id
; destroys : rax, rcx, rdx, rsi, rdi, r8, r9, r11, reg_task (containing result of dispatch), reg_id (containing worker id if dispatched)
macro dispatch_try_dispatch reg_out, reg_id, reg_off, reg_task {

  local .end

  mov rdi, reg_task

  dispatch_lock_state

  mov reg_out, qword [dispatch_count]
  mov qword [dispatch_lock], reg_out
  test reg_out, reg_out
  jz .end
  dec reg_out
  mov qword [dispatch_count], reg_out

  mov r8, qword [dispatch_stack + 8 * reg_out]
  mov qword [dispatch_lock], 0
  mov qword [r8 + 16], rdi
  mov r9, qword [r8 + 8]
  mov rdi, r8
  mov r8, qword [tfoffsets + r9]
  mov dword [rdi], 1

  mov eax, __NR_futex
  mov esi, (FUTEX_WAKE or FUTEX_PRIVATE_FLAG)
  mov edx, 1
  syscall

  mov reg_out, 1
  mov reg_id, r9
  mov reg_off, r8

  .end:

}

