# RISC-V Bare Metal Memory Reader

Interactive memory reader for RISC-V bare metal systems. Supports K230 hardware and QEMU emulation with platform abstraction.

## Project Structure

```
metal-v/
├── include/platform.h          # Platform abstraction
├── src/
│   ├── hello_readaddr.c        # Main application
│   ├── k230/                   # K230 implementation
│   └── qemu/                   # QEMU implementation
└── Makefile
```

## Requirements

- RISC-V GCC toolchain (`riscv-none-elf-gcc`)
- QEMU (for testing)

## Build Targets

- `make` or `make qemu` - Build for QEMU
- `make k230` - Build for K230
- `make all` - Build both targets
- `make clean` - Clean build artifacts

## Usage

The application provides an interactive UART interface for reading memory addresses:

```
hello from QEMU
Enter address: 80200000
Address: 0x80200000
Data: 0x00000013
Done
Enter address: 
```

Enter hexadecimal addresses (0-9, A-F) up to 8 characters.

## Platform Configurations

| Platform | UART Base | Memory Base | Register Spacing |
|----------|-----------|-------------|------------------|
| K230     | 0x91403000 | 0x2000000   | 4 bytes          |
| QEMU     | 0x10000000 | 0x80200000  | 1 byte           |

