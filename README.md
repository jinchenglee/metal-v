# RISC-V Bare Metal Memory Reader

A bare metal RISC-V application that demonstrates platform abstraction and interactive memory reading capabilities. The application can run on both the CanMV K230 chip and QEMU emulator with a clean, organized codebase structure.

## Features

- **Platform Abstraction Layer**: Clean separation between platform-specific and common code
- **Multi-Platform Support**: K230 and QEMU targets with dedicated implementations
- **Interactive Memory Reader**: UART-based interface for reading memory addresses
- **Organized Structure**: Well-structured directory layout for maintainability
- **Selective Compilation**: Platform-specific builds with appropriate optimizations

## Project Structure

```
metal-v/
├── include/
│   └── platform.h              # Platform abstraction interface
├── src/
│   ├── hello_readaddr.c        # Main application code
│   ├── k230/                   # K230 platform-specific code
│   │   ├── k230_platform.c     # K230 UART and memory implementation
│   │   └── k230.ld            # K230 linker script
│   └── qemu/                   # QEMU platform-specific code
│       ├── qemu_platform.c     # QEMU UART and memory implementation
│       ├── qemu.ld            # QEMU linker script
│       └── startup.s          # QEMU startup assembly code
├── Makefile                    # Build system with platform selection
└── README.md                  # This documentation
```

## Directory Organization

### `include/`
Contains common header files that define the platform abstraction interface.

### `src/`
Contains the main application source code and platform-specific implementations organized by target platform.

### `src/k230/`
K230-specific implementation files:
- **k230_platform.c**: UART driver with 4-byte register spacing and complex initialization
- **k230.ld**: Memory layout and linker configuration for K230 hardware

### `src/qemu/`
QEMU-specific implementation files:
- **qemu_platform.c**: 16550A UART driver with 1-byte register spacing
- **qemu.ld**: Memory layout for QEMU virt machine
- **startup.s**: Assembly startup code for QEMU environment

## Building

### Prerequisites
- RISC-V GCC toolchain (`riscv-none-elf-gcc`)
- QEMU (for testing QEMU target)

### Build Targets

#### K230 Target
```bash
make k230
```

#### QEMU Target
```bash
make qemu
```

#### Both Targets
```bash
make all
```

#### Default Target (QEMU)
```bash
make
```

### Build Output
- **K230**: `k230.bin` - Binary for K230 hardware
- **QEMU**: `qemu.bin` - Binary for QEMU emulation

## Running

### K230 Hardware
Flash the `k230.bin` file to your K230 device using your preferred method.

### QEMU Emulation
```bash
make run_qemu
# or manually:
qemu-system-riscv64 -machine virt -cpu rv64 -m 128M -nographic -kernel qemu.bin
```

**Note**: Use `-kernel` instead of `-bios` as the binary is loaded as a kernel image.

## Platform Configurations

### K230 Configuration
- **UART Base**: 0x91403000 (UART3)
- **Clock Frequency**: 50MHz
- **Baud Rate**: 115200
- **Memory Base**: 0x2000000
- **Memory Size**: 64KB
- **Register Spacing**: 4 bytes (reg-shift=2)

### QEMU Configuration
- **UART Base**: 0x10000000 (virt machine UART)
- **Clock Frequency**: 10MHz
- **Baud Rate**: 115200
- **Memory Base**: 0x80200000
- **Memory Size**: 128MB
- **Register Spacing**: 1 byte (standard 16550A)

## Application Usage

The application provides an interactive memory reader interface:

1. **Initialization**: Platform-specific UART and memory systems are initialized
2. **Hello Message**: Displays platform identification
3. **Interactive Loop**:
   - Prompts for a hexadecimal memory address (up to 8 characters)
   - Validates input and provides error feedback
   - Reads and displays the 32-bit value at the specified address
   - Repeats the process

### Input Format
- Enter hexadecimal addresses using characters 0-9, A-F, or a-f
- Maximum 8 characters (32-bit addresses)
- Press Enter to confirm input
- Invalid characters will reset the input

### Example Session
```
hello from QEMU
Enter address: 80200000
Address: 0x80200000
Data: 0x00000013
Done
Enter address: 
```

## Build System Features

### Selective Compilation
- Each platform target compiles only its specific implementation
- Platform-specific preprocessor flags (`QEMU_TARGET` for QEMU builds)
- Separate object files prevent cross-platform contamination

### Compiler Flags
- **Architecture**: RV64GC with LP64D ABI
- **Optimization**: -O2 with debug symbols
- **Safety**: No stack protection, no builtin functions
- **Include Path**: Automatic resolution of `include/` directory

### Clean Targets
```bash
make clean          # Remove all build artifacts
make help           # Display available targets
```

## Architecture Benefits

### Maintainability
- Clear separation of concerns between platforms
- Common interface in `include/` directory
- Platform-specific code isolated in dedicated directories

### Scalability
- Easy to add new platforms by creating new subdirectories
- Consistent structure across all platform implementations
- Reusable build system patterns

### Development
- Platform-specific debugging and testing
- Independent development of platform features
- Clear dependency management

## Troubleshooting

### Build Issues
- Ensure RISC-V toolchain is in PATH
- Verify all source files are in correct directories
- Check that include paths are properly configured

### Runtime Issues
- **K230**: Verify UART connection and baud rate settings
- **QEMU**: Ensure QEMU is properly installed and accessible
- **Memory Access**: Be cautious with memory addresses to avoid crashes

## Contributing

When adding new platforms:
1. Create a new subdirectory under `src/`
2. Implement platform-specific files following existing patterns
3. Update the Makefile with new build rules
4. Add platform configuration to `include/platform.h`
5. Test both build and runtime functionality

## License

This project is provided as an educational example of RISC-V bare metal programming with platform abstraction.