
SOURCES_TB=Test/tb_core.v
SOURCES_CORE = core.v $(shell echo src/*.v)
SOURCES_TEST = tb_test.sv $(shell echo Test/*.sv)
OUTPUT_DIR=Debug
OUTPUT_NAME=core.out
CFLAG=
#SFLAG=-mrelax -al -march=rv32if -mabi=ilp32d
SFLAG=
#CFLAG=-fomit-frame-pointer -ftree-coalesce-vars -funit-at-a-time

all: build
	vvp ${OUTPUT_DIR}/${OUTPUT_NAME}


build: $(SOURCES_CORE)
	mkdir -p ./Debug
	iverilog -o ${OUTPUT_DIR}/${OUTPUT_NAME} ${SOURCES_TB} ${SOURCES_CORE}

wave: build
	vvp ${OUTPUT_DIR}/${OUTPUT_NAME}
	gtkwave ${OUTPUT_DIR}/core.vcd

test_build: $(SOURCES_TEST) $(SOURCES_CORE)
	vlog -sv ${SOURCES_TEST} ${SOURCES_CORE}

test_simulation: test_build
	vsim -c tb_test

cc:
	# compile _start
	riscv32-elf-as ${SFLAG} _start.s -o _start.o
	# compile main
	riscv32-unknown-elf-gcc ${CFLAG} -S -o main.s main.c
	riscv32-elf-as ${SFLAG} main.s -o main.o
	# link
	riscv32-elf-ld -Ttext 0x00 -o main _start.o main.o
	# conver
	# riscv32-elf-objcopy -O binary main
	#../../elfbin/elfbin -f main -o rom.dat

disassemble:
	riscv32-elf-gdb main

clean:
	rm main *.o  
	rm -rf work  
	rm transcript   
