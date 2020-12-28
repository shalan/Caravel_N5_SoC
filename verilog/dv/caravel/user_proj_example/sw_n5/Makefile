GCC_PATH?=/ef/apps/bin
GCC_PREFIX?=riscv32-unknown-elf

name := test

%.hex: $(name).c n5_drv.c crt0.S link.ld
	$(GCC_PATH)/$(GCC_PREFIX)-gcc -Wall  -falign-functions=4 -march=rv32ic -mabi=ilp32 -nostdlib -mstrict-align -T link.ld -o $(name).elf -lgcc crt0.S n5_drv.c $(name).c  -lgcc
	$(GCC_PATH)/$(GCC_PREFIX)-objcopy -O binary $(name).elf $(name).bin
	$(GCC_PATH)/$(GCC_PREFIX)-objcopy -O verilog $(name).elf $(name).hex
	$(GCC_PATH)/$(GCC_PREFIX)-objdump -D $(name).elf > $(name).lst

all: $(name).hex