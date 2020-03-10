#!/bin/bash

# target files are from https://github.com/esp8266/esp8266-wiki

tar -xf patch/xtensa-lx106-elf/include.tgz -C builds/xtensa-lx106-elf/lib/gcc/xtensa-lx106-elf/9.2.0/
cp patch/xtensa-lx106-elf/libhal.a builds/xtensa-lx106-elf/lib/gcc/xtensa-lx106-elf/9.2.0/ 
