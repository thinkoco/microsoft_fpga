# Software

## 01.led_asm

	riscv-none-embed-gcc -march=rv32i -mabi=ilp32 -Wl,-Tlinker.ld -nostdlib -static -o led.elf led_blink.S
	riscv-none-embed-objdump -s -D -M no-aliases,numeric  led.elf > led.dis
	riscv-none-embed-objcopy -O binary led.elf led.bin
	../../../tools/bin2ihex led.bin > led.hex

## 02.led_c
	riscv-none-embed-gcc -march=rv32i -mabi=ilp32 -Tlink_itcm.lds  -nostartfiles -o led.elf start.S main.c
	riscv-none-embed-objdump -s -D -M no-aliases,numeric  led.elf > led.dis
	riscv-none-embed-objcopy -O binary led.elf led.bin
	../../../tools/bin2ihex led.bin > led.hex
