#!/bin/sh
echo "removing compiled stuff (rm *bin *elf)"
rm *.bin
rm *.elf

echo "Staging everything (git add .)"
git add .

echo "Committing (git commit)"
git commit 

echo "pushing (git push)"
git push
