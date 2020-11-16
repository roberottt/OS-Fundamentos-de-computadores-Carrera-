
#ARMGNU ?= arm-none-eabi
ARMGNU ?= arm-linux-gnueabi

AARCH = -march=armv5t
AOPS = --warn --fatal-warnings $(AARCH)
COPS = -Wall -O2 -nostdlib -nostartfiles -ffreestanding $(AARCH)

main.bin :  main.o auxiliar.o memmap
	$(ARMGNU)-ld main.o auxiliar.o -T memmap -o main.elf
	$(ARMGNU)-objdump -D main.elf > main.list
	$(ARMGNU)-objcopy main.elf -O binary main.bin

main.o : main.s
	$(ARMGNU)-as $(AOPS) main.s -o main.o

auxiliar.o : auxiliar.c 
	$(ARMGNU)-gcc -c $(COPS) auxiliar.c -o auxiliar.o

clean :
	rm -f *.o
	rm -f *.elf
	rm -f *.bin
	rm -f *.list

