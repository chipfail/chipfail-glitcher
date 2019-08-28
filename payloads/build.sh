#!/bin/bash
TOOLCHAIN=arm-none-eabi-
set -e

if [ "$1" == "" ]; then
    echo "Need 1 argument (asm file)"
    exit
fi

${TOOLCHAIN}as ${1} -o ${1}.o
${TOOLCHAIN}ld -o ${1}.elf -T saml11.ld ${1}.o
${TOOLCHAIN}objcopy ${1}.elf ${1}.hex -O ihex
# rm ${1}.o ${1}.elf
echo "Generated ${1}.hex"