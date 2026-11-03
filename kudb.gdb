set disassembly-flavor intel
layout asm
layout regs
set print array on

# run / /var/cache/klocate/db 1
run test_fs /var/cache/klocate/db 3

