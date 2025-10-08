# Metal-V: RISC-V Bare Metal Development Platform

Interactive command-line interface and memory tools for RISC-V bare metal systems. Supports K230 hardware and QEMU emulation with platform abstraction.

## Features

- **Interactive Shell**: Command-line interface with extensible command system
- **Memory Operations**: Read and write memory with hex address support
- **Platform Abstraction**: Clean separation between hardware-specific and generic code
- **Modular Design**: Easy to add new commands and functionality
- **No Dependencies**: Pure bare-metal implementation without libc

## Project Structure

```
metal-v/
├── include/
│   ├── platform.h              # Platform abstraction interface
│   ├── command_handler.h       # Command registration and dispatch
│   ├── command_parser.h        # Input parsing and tokenization
│   └── utils.h                 # Common utility functions
├── src/
│   ├── shell.c                 # Interactive shell application
│   ├── command_handler.c       # Command system implementation
│   ├── command_parser.c        # Parser implementation
│   ├── utils.c                 # Utility functions
│   ├── hello_readaddr.c        # Legacy memory reader app
│   ├── k230/                   # K230 platform implementation
│   └── qemu/                   # QEMU platform implementation
├── Makefile
├── README.md                   # This file
└── COMMAND_SYSTEM.md           # Detailed command system documentation
```

## Requirements

- RISC-V GCC toolchain (`riscv-none-elf-gcc`)
- QEMU (for testing)

## Quick Start

### Build and Run Interactive Shell (Default)
```bash
make run_shell
```

This will build and launch the interactive shell in QEMU. Press `Ctrl-A` then `X` to exit QEMU.

### Build Targets

**Shell Applications (Recommended):**
- `make run_shell` - Build and run interactive shell in QEMU (default)
- `make qemu_shell` - Build shell for QEMU
- `make k230_shell` - Build shell for K230
- `make run_k230_shell` - Build shell for K230 (ready to flash)

**Legacy Applications:**
- `make run_qemu` - Build and run hello_readaddr in QEMU
- `make qemu` - Build hello_readaddr for QEMU
- `make k230` - Build hello_readaddr for K230
- `make qemu_zig` - Build Zig version for QEMU

**Other:**
- `make all` - Build all versions
- `make clean` - Clean build artifacts
- `make help` - Show all available targets

## Shell Usage

The interactive shell provides a command-line interface for memory operations and system control:

```
========================================
 Metal-V Interactive Shell
 RISC-V Bare Metal Command Interface
========================================

Platform: QEMU
Type 'help' for available commands.

metal-v> help

Available commands:
-------------------
  help
    Display available commands

  read
    Read memory: read <addr> [size]

  write
    Write memory: write <addr> <value>

metal-v> read 80200000 4

Reading 0000000000000004 word(s) from 0x0000000080200000:
  0x0000000080200000: 0x00000013
  0x0000000080200004: 0x00000013
  0x0000000080200008: 0x0000006F
  0x000000008020000C: 0x00000000

metal-v> write 80300000 DEADBEEF
Writing 0xDEADBEEF to address 0x0000000080300000... Done.
Read back: 0xDEADBEEF [OK]

metal-v>
```

### Available Commands

- **help** - Display all available commands
- **read `<addr>` `[size]`** - Read memory (size in 32-bit words, default 1)
- **write `<addr>` `<value>`** - Write 32-bit value to memory

**⚠️ Important:** Use valid addresses for your platform! See `MEMORY_MAP.md` for details.

See `COMMAND_SYSTEM.md` for detailed documentation on adding custom commands.

## Platform Configurations

| Platform | UART Base | Memory Base | Register Spacing |
|----------|-----------|-------------|------------------|
| K230     | 0x91403000 | 0x2000000   | 4 bytes          |
| QEMU     | 0x10000000 | 0x80200000  | 1 byte           |

## Extending the Command System

The command system is designed for easy extensibility. Adding a new command is straightforward:

### Example: Adding a "peek" command

1. **Edit `src/cmd_handler.c`** - Add your command function:
```c
static int cmd_peek(int argc, char *argv[]) {
    if (argc < 1) {
        platform_uart_puts("Usage: peek <addr>\n");
        return -1;
    }
    
    uint64_t addr;
    if (!utils_parse_hex64(argv[0], &addr)) {
        platform_uart_puts("Error: Invalid address\n");
        return -1;
    }
    
    uint32_t value = platform_read_memory(addr);
    utils_print_hex32(value);
    platform_uart_puts("\n");
    return 0;
}
```

2. **Register it in `cmd_init()`**:
```c
cmd_register("peek", "Quick peek at address: peek <addr>", cmd_peek);
```

3. **Rebuild**:
```bash
make clean && make qemu_shell
```

For detailed instructions and advanced usage, see `COMMAND_SYSTEM.md`.

## Architecture

The project uses a clean layered architecture:

```
┌─────────────────────────────────────┐
│         Shell Application           │
│         (shell.c)                   │
├─────────────────────────────────────┤
│      Command System Layer           │
│  ┌──────────┬──────────────────┐    │
│  │  Parser  │  Handler         │    │
│  └──────────┴──────────────────┘    │
├─────────────────────────────────────┤
│      Utility Layer (utils.c)        │
├─────────────────────────────────────┤
│   Platform Abstraction (platform.h) │
├─────────────────────────────────────┤
│   Platform Implementation           │
│   ┌──────────┬──────────┐          │
│   │  K230    │  QEMU    │          │
│   └──────────┴──────────┘          │
└─────────────────────────────────────┘
```

This design provides:
- **Modularity**: Each layer has a clear responsibility
- **Portability**: Platform-specific code is isolated
- **Extensibility**: Easy to add new commands and platforms
- **Testability**: Components can be tested independently

