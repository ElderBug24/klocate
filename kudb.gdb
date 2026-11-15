set disassembly-flavor intel
layout asm
layout regs
set print array on
set print repeats 0
add-symbol-file build/kudb.elf

break start

# run / /var/cache/klocate/db 4
run test_fs /var/cache/klocate/db 4
# run

