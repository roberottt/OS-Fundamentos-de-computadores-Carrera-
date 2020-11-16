SETLOCAL
REM Esta linea (set Path) puede dar error, sustituir el subdirectorio "9 2019..." por el que toque
SET PATH=%PATH%;C:\Program Files (x86)\GNU Tools Arm Embedded\9 2019-q4-major\bin

SET _ARMGNU=arm-none-eabi

SET _AARCH=-march=armv5t
SET _AOPS=--warn --fatal-warnings %_AARCH%
SET _COPS=-Wall -O2 -nostdlib -nostartfiles -ffreestanding %_AARCH%

rem echo %_ARMGNU%

%_ARMGNU%-as %_AOPS% main.s -o main.o
%_ARMGNU%-gcc -c %_COPS% auxiliar.c -o auxiliar.o

%_ARMGNU%-ld main.o auxiliar.o -T memmap -o main.elf
%_ARMGNU%-objdump -D main.elf > main.list
%_ARMGNU%-objcopy main.elf -O binary main.bin

ENDLOCAL
