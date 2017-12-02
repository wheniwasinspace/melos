#!/bin/sh
rm *.bin
rm *.elf
rm *.sym

echo nasm -f bin -o bootloader.bin bootloader.asm
nasm -f bin -o bootloader.bin bootloader.asm
echo nasm -f elf -F dwarf -g -o bootloader.elf bootloader.asm
nasm -f elf -F dwarf -g -o bootloader.elf bootloader.asm

echo nasm -f bin -o kernel.bin kernel.asm
nasm -f bin -o kernel.bin kernel.asm
echo nasm -f elf -F dwarf -g -o kernel.elf kernel.asm
nasm -f elf -F dwarf -g -o kernel.elf kernel.asm

echo objcopy --only-keep-debug bootloader.elf bootloader.sym
objcopy --only-keep-debug bootloader.elf bootloader.sym
echo objcopy --only-keep-debug kernel.elf kernel.sym
objcopy --only-keep-debug kernel.elf kernel.sym

echo objcopy --strip-debug bootloader.elf
objcopy --strip-debug bootloader.elf
echo objcopy --strip-debug kernel.elf
objcopy --strip-debug kernel.elf

echo "dd status=noxfer conv=notrunc if=bootloader.bin of=melizzos.flp"
dd status=noxfer conv=notrunc if=bootloader.bin of=melizzos.flp

echo "dd status=noxfer conv=notrunc if=kernel.bin of=melizzos.flp"
dd status=noxfer conv=notrunc seek=1 if=kernel.bin of=melizzos.flp


echo cp melizzos.flp /media/sf_VBOX_GEMENSAM/
cp melizzos.flp /media/sf_VBOX_GEMENSAM/

