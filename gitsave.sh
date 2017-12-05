#!/bin/sh
echo rm *.bin *.elf
rm *.bin
rm *.elf

echo "Staging (git add .)"
git add .

echo "Committing (git commit -m \"autocommited by script\")"
git commit 

echo "pushing (git push)"
git push
