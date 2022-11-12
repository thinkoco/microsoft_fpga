
BIN2IHEX        = ../../../tools/bin2ihex
TOOLS_PREFIX    := /opt/riscv-none-gcc/7.2.0-2-20180111-2230/bin
TARGET          := $(TOOLS_PREFIX)/riscv-none-embed
AS              = $(TARGET)-as
ASFLAGS         = -march=rv32i -mabi=ilp32
LD              = $(TARGET)-ld
LDFLAGS         = -march=rv32i -mabi=ilp32 -Wl,-Tlinker.ld -nostdlib -static
CC              = $(TARGET)-gcc
CFLAGS          = -march=rv32i -mabi=ilp32 -Wall -Wextra -pedantic -O2
OBJCOPY         = $(TARGET)-objcopy
OBJDUMP         = $(TARGET)-objdump

.PHONY: all clean syntax time stat flash

all: led.dis led.bin led.hex

led.hex: led.bin
	$(BIN2IHEX) led.bin > $@

led.dis: led.elf
	$(OBJDUMP) -s -D -M no-aliases,numeric  $< > $@
  
led.bin: led.elf
	$(OBJCOPY) -O binary $< $@

led.elf: led_blink.o linker.ld Makefile
	$(CC) $(LDFLAGS) -o $@ led_blink.o

clean:
	\rm -fr *.o *.hex *.elf *.dis *.bin *.coe *.map *.mif *.mem


