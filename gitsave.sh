#!/bin/sh
echo rm *.bin *.elf
rm *.bin
rm *.elf

echo "Staging (git add .)"
git add .

echo "Committing (git commit -m \"autocommited by script\")"
git commit -m "autocommited by script"

echo "pushing (git push master remote"
git push master remote
