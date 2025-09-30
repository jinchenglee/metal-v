# RISC-V Bare Metal Hello World

This project demonstrates a bare metal RISC-V application that can run on both the CanMV K230 chip and QEMU emulator.

## Features

- Platform abstraction layer supporting multiple targets
- UART communication for input/output
- Interactive memory address reading
- Support for both K230 and QEMU platforms

## Project Structure

```
metal-v/
├── hello_readaddr.c    # Main application code
├── platform.h          # Platform abstraction header
├── k230_platform.c     # K230-specific platform implementation
├── qemu_platform.c     # QEMU-specific platform implementation
├── k230.ld            # Linker script for K230
├── qemu.ld            # Linker script for QEMU
├── Makefile           # Build system (selective compilation)
└── README.md          # This file
```

## Building

### K230 Target (Default)
```bash
make k230
# or simply
make
```

### QEMU Target
```bash
make qemu
```

### Both Targets
```bash
make all
```

## Running

### K230
Flash the `k230.bin` file to your K230 device.

### QEMU
```bash
qemu-system-riscv64 -machine virt -cpu rv64 -m 128M -nographic -kernel qemu.bin
```

**Note**: Use `-kernel` instead of `-bios` for QEMU as the binary is loaded as a kernel image.

## Architecture

The codebase uses a **split platform architecture** where each target has its own dedicated platform implementation file:

- **`k230_platform.c`**: Contains K230-specific UART implementation with 4-byte register spacing and complex initialization
- **`qemu_platform.c`**: Contains QEMU-specific 16550A UART implementation with 1-byte register spacing and simple operation

The Makefile selectively compiles only the appropriate platform code for each target, ensuring clean separation and avoiding unnecessary code inclusion. Each target also gets its own version of the main application code with the appropriate preprocessor flags defined (`QEMU_TARGET` for QEMU builds).

### K230 Configuration
- UART Base: 0x91403000 (UART3)
- Clock Frequency: 50MHz
- Memory Base: 0x2000000
- Memory Size: 64KB

### QEMU Configuration
- UART Base: 0x10000000 (virt machine UART)
- Clock Frequency: 10MHz
- Memory Base: 0x80000000
- Memory Size: 128MB

## Usage

The application will:
1. Initialize the platform-specific UART
2. Print a hello message indicating the platform
3. Prompt for a memory address in hexadecimal
4. Read and display the data at that address
5. Repeat the process

## Cleanup

```bash
make clean          # Clean all build files
make clean-k230     # Clean only K230 files
make clean-qemu     # Clean only QEMU files
```

## Help

```bash
make help
```
