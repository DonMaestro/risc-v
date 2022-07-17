
SOURCES_TB=Test/tb_core.v
TEST_DIR=Test
SOURCES_CORE = $(shell echo src/*.v)
SOURCES_TEST = $(shell echo Test/*.sv)
TARGET=core
OUTPUT_DIR=Debug
OUTPUT_NAME=core.out
#SFLAG=-mrelax -al -march=rv32i -mabi=ilp32
SFLAG=
#CFLAG=-fomit-frame-pointer -ftree-coalesce-vars -funit-at-a-time
CFLAG=

.PHONY: disassemble

all: build
	vvp ${OUTPUT_DIR}/${OUTPUT_NAME}

build: $(SOURCES_CORE)
	mkdir -p ./Debug
	iverilog -o ${OUTPUT_DIR}/${OUTPUT_NAME} ${SOURCES_TB}

wave: build
	vvp ${OUTPUT_DIR}/${OUTPUT_NAME}
	gtkwave ${OUTPUT_DIR}/core.vcd

test_build:
	vlog ${TEST_DIR}/tb_${TARGET}.sv
	#iverilog -o ${TARGET}.out ${TEST_DIR}/tb_${TARGET}.v

test_simulation: test_build
	mkdir -p ./Debug
	vsim -c tb_${TARGET}
	#vvp ${TARGET}.out

uvm_test:
	mkdir -p ./Debug
	vlog +incdir+${UVM_HOME}/src ${UVM_HOME}/src/uvm.sv uvm/${TARGET}.sv
	vsim +UVM_NO_RELNOTES -c -sv_lib ${UVM_HOME}/lib/uvm_dpi top -do "run -all"

cc:
	# compile _start
	riscv64-elf-as ${SFLAG} _start.s -o _start.o
	# compile main
	riscv64-elf-gcc ${CFLAG} -S -march=rv32i -mabi=ilp32 -o main.s main.c
	riscv64-elf-as ${SFLAG} main.s -o main.o
	# link
	riscv32-elf-ld -Ttext 0x00 -o main _start.o main.o
	# conver
	# riscv32-elf-objcopy -O binary main
	#../../elfbin/elfbin -f main -o rom.dat

#riscv32-elf-as ${SFLAG} _start.s -o _start.o
#riscv32-unknown-elf-gcc ${CFLAG} -S -o main.s main.c
#riscv32-elf-as ${SFLAG} main.s -o main.o

disassemble:
	riscv32-elf-gdb main

clean:
	rm main *.o  
	rm -rf work  
	rm transcript   

