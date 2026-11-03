set disassembly-flavor intel
layout asm
layout regs
set print array on

run file
ni
p (char) $ah
p (char) $al

