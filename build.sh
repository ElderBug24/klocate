mkdir -p build
fasm kudb.asm -s build/kudb.fas && symbols build/kudb.fas build/kudb.symbols && python3 map2sym.py build/kudb.symbols && as syms.s -o build/syms.o && ld -Ttext=0x400000 -e 0 -o build/kudb.elf build/syms.o
fasm kl.asm -s build/kl.fas && symbols build/kl.fas build/kl.symbols && python3 map2sym.py build/kl.symbols && as syms.s -o build/syms.o && ld -Ttext=0x400000 -e 0 -o build/kl.elf build/syms.o
rm syms.s
