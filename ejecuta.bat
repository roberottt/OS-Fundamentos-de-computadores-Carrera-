@echo off
SETLOCAL
SET PATH=%PATH%;C:\Program Files\qemu
qemu-system-arm -M versatilepb -m 128M -nographic -kernel main.bin
ENDLOCAL
