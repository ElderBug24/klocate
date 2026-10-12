
macro dispatch_declare max {

  align 64
  dispatch_lock dq 0
  dispatch_count dq 0
  dispatch_stack rq max

}

; destroys : rax
macro dispatch_lock_state {

  local try, spin, end

  try:

    mov eax, 1
    xchg [dispatch_lock], rax
    test eax, eax
    jz end

  spin:

    pause
    cmp [dispatch_lock], 0
    jne spin
    jmp try

  end:

}

; reg64_task : 64 bit register
; reg64_id : 64 bit register containing worker id
; destroys : rax, rcx, rdx, rsi, rdi, r10, r11, reg64_task (containing dispatched task)
macro dispatch_worker_idle reg64_task, reg64_id {

  local wait, woken

  sub rsp, 24
  mov dword [rsp], 0
  mov [rsp + 8], reg64_id
  mov qword [rsp + 16], 0

  dispatch_lock_state

  mov rax, [dispatch_count]
  mov [dispatch_stack + 8 * rax], rsp
  inc rax
  mov [dispatch_count], rax
  mov [dispatch_lock], 0

  wait:

    cmp dword [rsp], 0
    jne woken

    mov rax, __NR_futex
    mov rdi, rsp
    mov rsi, (FUTEX_WAIT or FUTEX_PRIVATE_FLAG)
    xor edx, edx
    xor r10, r10
    syscall

    jmp wait

  woken:

  mov reg64_task, [rsp + 16]
  add rsp, 24

}

; reg64_task : 64 bit register containing task to dispatch
; reg64_id : 64 bit register containing id
; destroys : rax, rcx, rdx, rsi, rdi, r8, r9, r11, reg64_task (containing result of dispatch), reg64_id (containing worker id if dispatched)
macro dispatch_try_dispatch reg64_out, reg64_id, reg64_task {

  local end

  mov rdi, reg64_task

  dispatch_lock_state

  mov reg64_out, [dispatch_count]
  mov [dispatch_lock], reg64_out
  test reg64_out, reg64_out
  jz end
  dec reg64_out
  mov [dispatch_count], reg64_out

  mov r8, [dispatch_stack + 8 * reg64_out]
  mov [dispatch_lock], 0
  mov [r8 + 16], rdi
  mov r9, [r8 + 8]
  mov dword [r8], 1

  mov rax, __NR_futex
  mov rdi, r8
  mov rsi, (FUTEX_WAKE or FUTEX_PRIVATE_FLAG)
  mov edx, 1
  syscall

  mov reg64_out, 1
  mov reg64_id, r9

  end:

}

