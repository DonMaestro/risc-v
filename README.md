
# Superscalar RISC-V32 Processor

![Core](docs/img/core.png)

[RISC-V Manual](https://riscv.org/wp-content/uploads/2019/12/riscv-spec-20191213.pdf)

## Dependencies
### Requirements

- Modelsim or [iverilog][1](no tests)

### Recommends

- c
- riscv64-elf-gcc
- riscv32-elf-binutils or [riscv-gnu-toolchain][2]
- [elfbin][3]

## Building

```bash
$ git clone https://github.com/DonMaestro/risc-v.git
$ cd risc-v
$ make build
```

## DOCUMENTATION(EN/[UA][4])

[1]: http://iverilog.icarus.com/
[2]: https://github.com/riscv-collab/riscv-gnu-toolchain
[3]: https://github.com/DonMaestro/elfbin.git
[4]: docs/modules_ua/README.md

