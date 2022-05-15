OUTPUT_DIR=img
TARGET=core
FORMAT=png

all: build
	echo "GG"

#.PHONY:

build:
	mkdir -p img
	dot -T${FORMAT} -o ${OUTPUT_DIR}/${TARGET}.${FORMAT} src/${TARGET}.gv

clean:
	rm ./img/*


