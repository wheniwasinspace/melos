#!/bin/sh

# This script assembles the MelizzOS bootloader and kernal
# with NASM, and then creates floppy

# Only the root user can mount the floppy disk image as a virtual
# drive (loopback mounting), in order to copy across the files

# (If you need to blank the floppy image: 'mkdosfs mellizos.flp')


if test "`whoami`" != "root" ; then
	echo "You must be logged in as root to build (for loopback mounting)"
	echo "Enter 'su' or 'sudo bash' to switch to root"
	exit
fi


if [ ! -e melizzos.flp ]
then
	echo ">>> Creating new MelizzOS floppy image..."
	mkdosfs -C melizzos.flp 1440 || exit
fi


echo ">>> Assembling bootloader..."

nasm -O0 -w+orphan-labels -f bin -o mikeboot.bin mikeboot.asm || exit


echo ">>> Assembling MelizzOS kernel..."

nasm -O0 -w+orphan-labels -f bin -o kernel.bin kernel.asm || exit

echo ">>> Adding bootloader to floppy image..."

dd status=noxfer conv=notrunc if=mikeboot.bin of=melizzos.flp || exit


echo ">>> Copying MelizzOS kernel"

rm -rf tmp-loop

mkdir tmp-loop && mount -o loop -t vfat melizzos.flp tmp-loop && cp kernel.bin tmp-loop/
cp *.txt tmp-loop/

sleep 0.2

echo ">>> Unmounting loopback floppy..."

umount tmp-loop || exit

rm -rf tmp-loop

echo '>>> Done!'

exit
