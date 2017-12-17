#!/bin/sh
echo "removing compiled stuff (rm *bin *elf *sym *obj)"
rm *.bin
rm *.elf
rm *.sym
rm *.obj

echo "Staging everything (git add .)"
git add .

echo "Committing (git commit)"
git commit 

echo "pushing (git push)"
git push
