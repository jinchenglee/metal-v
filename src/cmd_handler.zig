const c = @cImport({
    @cInclude("platform.h");
});
const utils = @import("utils.zig");
const parser = @import("cmd_parser.zig");

const MAX_COMMANDS = 16;

// Command handler function type
pub const CommandHandlerFunc = *const fn (i32, [*]?[*:0]u8) callconv(.c) i32;

pub const Command = struct {
    name: [*:0]const u8,
    help: [*:0]const u8,
    handler: CommandHandlerFunc,
};

// Array of registered commands
var commands: [MAX_COMMANDS]Command = undefined;
var command_count: i32 = 0;

// Register a new command
pub fn register(name: [*:0]const u8, help_text: [*:0]const u8, handler: CommandHandlerFunc) bool {
    if (command_count >= MAX_COMMANDS) {
        return false;
    }

    commands[@intCast(command_count)] = Command{
        .name = name,
        .help = help_text,
        .handler = handler,
    };
    command_count += 1;

    return true;
}

// Execute a parsed command
pub fn execute(parsed: *parser.ParsedCommand) i32 {
    if (parsed.command == null) {
        return -1;
    }

    const cmd = parsed.command.?;

    // Find and execute the command
    var i: i32 = 0;
    while (i < command_count) : (i += 1) {
        if (utils.strcmp(cmd, commands[@intCast(i)].name) == 0) {
            return commands[@intCast(i)].handler(parsed.arg_count, &parsed.args);
        }
    }

    // Command not found
    c.platform_uart_puts("Unknown command: ");
    c.platform_uart_puts(cmd);
    c.platform_uart_puts("\nType 'help' for available commands.\n");
    return -1;
}

// Get list of registered commands
pub fn getCommands(count: *i32) [*]Command {
    count.* = command_count;
    return &commands;
}

// Built-in command implementations
// =================================

fn cmdHelp(argc: i32, argv: [*]?[*:0]u8) callconv(.c) i32 {
    _ = argc;
    _ = argv;

    c.platform_uart_puts("\nAvailable commands:\n");
    c.platform_uart_puts("-------------------\n");

    var i: i32 = 0;
    while (i < command_count) : (i += 1) {
        c.platform_uart_puts("  ");
        c.platform_uart_puts(commands[@intCast(i)].name);
        c.platform_uart_puts("\n    ");
        c.platform_uart_puts(commands[@intCast(i)].help);
        c.platform_uart_puts("\n\n");
    }

    return 0;
}

fn cmdRead(argc: i32, argv: [*]?[*:0]u8) callconv(.c) i32 {
    if (argc < 1) {
        c.platform_uart_puts("Error: read requires at least 1 argument\n");
        c.platform_uart_puts("Usage: read <addr> [size]\n");
        c.platform_uart_puts("  addr: Address in hex (e.g., 0x80200000 or 80200000)\n");
        c.platform_uart_puts("  size: Number of 32-bit words to read (default: 1)\n");
        return -1;
    }

    // Parse address
    var addr: u64 = 0;
    if (!utils.parseHex64(argv[0].?, &addr)) {
        c.platform_uart_puts("Error: Invalid address: ");
        c.platform_uart_puts(argv[0].?);
        c.platform_uart_puts("\n");
        return -1;
    }

    // Get platform config for address validation
    const config = c.get_platform_config();

    // Warning for potentially unmapped regions
    if (addr < config.*.memory_base or addr > (config.*.memory_base + config.*.memory_size)) {
        c.platform_uart_puts("Warning: Address may be outside mapped memory region\n");
        c.platform_uart_puts("  Platform memory: 0x");
        utils.printHex64(config.*.memory_base);
        c.platform_uart_puts(" - 0x");
        utils.printHex64(config.*.memory_base + config.*.memory_size);
        c.platform_uart_puts("\n  Proceeding anyway (may cause crash)...\n\n");
    }

    // Parse size (optional, default to 1)
    var size: u64 = 1;
    if (argc >= 2) {
        if (!utils.parseHex64(argv[1].?, &size) and !utils.parseDec64(argv[1].?, &size)) {
            c.platform_uart_puts("Error: Invalid size: ");
            c.platform_uart_puts(argv[1].?);
            c.platform_uart_puts("\n");
            return -1;
        }

        // Sanity check on size
        if (size == 0 or size > 256) {
            c.platform_uart_puts("Error: Size must be between 1 and 256\n");
            return -1;
        }
    }

    // Read and display memory
    c.platform_uart_puts("\nReading ");
    utils.printHex64(size);
    c.platform_uart_puts(" word(s) from 0x");
    utils.printHex64(addr);
    c.platform_uart_puts(":\n");

    var i: u64 = 0;
    while (i < size) : (i += 1) {
        const current_addr = addr + (i * 4);
        const value = c.platform_read_memory(current_addr);

        // Print address
        c.platform_uart_puts("  0x");
        utils.printHex64(current_addr);
        c.platform_uart_puts(": 0x");
        utils.printHex32(value);
        c.platform_uart_puts("\n");
    }

    return 0;
}

fn cmdWrite(argc: i32, argv: [*]?[*:0]u8) callconv(.c) i32 {
    if (argc < 2) {
        c.platform_uart_puts("Error: write requires 2 arguments\n");
        c.platform_uart_puts("Usage: write <addr> <value>\n");
        c.platform_uart_puts("  addr:  Address in hex (e.g., 0x80200000 or 80200000)\n");
        c.platform_uart_puts("  value: Value in hex to write (e.g., 0xDEADBEEF or DEADBEEF)\n");
        return -1;
    }

    // Parse address
    var addr: u64 = 0;
    if (!utils.parseHex64(argv[0].?, &addr)) {
        c.platform_uart_puts("Error: Invalid address: ");
        c.platform_uart_puts(argv[0].?);
        c.platform_uart_puts("\n");
        return -1;
    }

    // Get platform config for address validation
    const config = c.get_platform_config();

    // Warning for potentially unmapped regions
    if (addr < config.*.memory_base or addr > (config.*.memory_base + config.*.memory_size)) {
        c.platform_uart_puts("Warning: Address may be outside mapped memory region\n");
        c.platform_uart_puts("  Platform memory: 0x");
        utils.printHex64(config.*.memory_base);
        c.platform_uart_puts(" - 0x");
        utils.printHex64(config.*.memory_base + config.*.memory_size);
        c.platform_uart_puts("\n  Proceeding anyway (may cause crash)...\n\n");
    }

    // Parse value
    var value: u64 = 0;
    if (!utils.parseHex64(argv[1].?, &value)) {
        c.platform_uart_puts("Error: Invalid value: ");
        c.platform_uart_puts(argv[1].?);
        c.platform_uart_puts("\n");
        return -1;
    }

    // Check if value fits in 32 bits
    if (value > 0xFFFFFFFF) {
        c.platform_uart_puts("Error: Value must be a 32-bit number (max 0xFFFFFFFF)\n");
        return -1;
    }

    // Write memory
    c.platform_uart_puts("Writing 0x");
    utils.printHex32(@intCast(value));
    c.platform_uart_puts(" to address 0x");
    utils.printHex64(addr);
    c.platform_uart_puts("... ");

    c.platform_write_memory(addr, @intCast(value));

    c.platform_uart_puts("Done.\n");

    // Read back and verify
    const read_value = c.platform_read_memory(addr);
    c.platform_uart_puts("Read back: 0x");
    utils.printHex32(read_value);

    if (read_value == @as(u32, @intCast(value))) {
        c.platform_uart_puts(" [OK]\n");
    } else {
        c.platform_uart_puts(" [MISMATCH]\n");
    }

    return 0;
}

// Initialize the command handler system (must be after command definitions)
pub fn init() void {
    command_count = 0;

    // Register built-in commands
    _ = register("help", "Display available commands", cmdHelp);
    _ = register("read", "Read memory: read <addr> [size]", cmdRead);
    _ = register("write", "Write memory: write <addr> <value>", cmdWrite);
}
