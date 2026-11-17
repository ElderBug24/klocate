
macro mov dest, src {
  if dest in <rax, eax, rcx, ecx, rdx, edx, rbxm ebx, rsi, esi, rdi, edi, rbp, ebp, rsp, esp, r8, r8d, r9, r9d, r10, r10d, r11, r11d, r12, r12d, r13, r13d, r14, r14d, r15, r15d>
    if src eq 0
      if dest eq rax
        xor eax, eax
      else if dest eq rcx
        xor ecx, ecx
      else if dest eq rdx
        xor edx, edx
      else if dest eq rbx
        xor ebx, ebx
      else if dest eq rsi
        xor esi, esi
      else if dest eq rdi
        xor edi, edi
      else if dest eq rbp
        xor ebp, ebp
      else if dest eq rsp
        xor esp, esp
      else
        xor dest, dest
      end if
    else
      mov dest, src
    end if
  else
    mov dest, src
  end if
}

