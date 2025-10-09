# Metal-V: RISC-V Bare Metal Interactive Shell

A modular, extensible command-line interface for RISC-V bare metal systems. Written in **Zig** with C platform abstraction for K230 and QEMU.

## Requirements

- Zig compiler (tested with 0.15.1)
- RISC-V GCC toolchain (`riscv-none-elf-gcc`, `riscv-none-elf-objcopy`)
- QEMU for testing (`qemu-system-riscv64`)

## Architecture

```
┌─────────────────────────────┐
│   Zig Application Layer     │
│  ┌──────────┬─────────────┐ │  Application logic,
│  │  Shell   │   Commands  │ │  parsing, utilities
│  └──────────┴─────────────┘ │  (Zig)
├─────────────────────────────┤
│   Platform Abstraction      │  UART, memory ops
│        (platform.h)         │  (C interface)
├─────────────────────────────┤
│  ┌──────────┬─────────────┐ │  Hardware-specific
│  │  QEMU    │    K230     │ │  implementations
│  └──────────┴─────────────┘ │  (C)
└─────────────────────────────┘
```

## Quick Start

```bash
# Build and run in QEMU (default)
make run_qemu

# Or just build
make qemu
```

Press `Ctrl-A` then `X` to exit QEMU.

```
========================================
 Metal-V Interactive Shell (Zig)
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
```

## Memory Addresses

**QEMU:**
- Valid RAM: `0x80200000` - `0x88200000`
- UART: `0x10000000`

**K230:**
- Valid RAM: `0x02000000` - `0x02010000`
- UART: `0x91403000`

⚠️ Accessing unmapped addresses will crash the system. The shell warns about out-of-bounds access.


## Adding Custom Commands

Edit `src/cmd_handler.zig`:

```zig
// 1. Add your command function
fn cmdMyCommand(argc: i32, argv: [*]?[*:0]u8) callconv(.c) i32 {
    c.platform_uart_puts("Hello from my command!\n");
    return 0;
}

// 2. Register it in init()
pub fn init() void {
    command_count = 0;
    _ = register("help", "Display available commands", cmdHelp);
    _ = register("read", "Read memory: read <addr> [size]", cmdRead);
    _ = register("write", "Write memory: write <addr> <value>", cmdWrite);
    _ = register("mycmd", "My custom command", cmdMyCommand);  // ← Add here
}
```

Rebuild with `make clean && make run_qemu` and your command is ready!

## Platform Configuration

| Platform | UART Base    | Memory Base  | Register Spacing |
|----------|--------------|--------------|------------------|
| QEMU     | `0x10000000` | `0x80200000` | 1 byte           |
| K230     | `0x91403000` | `0x02000000` | 4 bytes          |

## License

See LICENSE file.
