// Test the FULL command loop with parse and execute
const c = @cImport({
    @cInclude("platform.h");
});
const handler = @import("cmd_handler.zig");
const parser = @import("cmd_parser.zig");

fn printBanner() void {
    c.platform_uart_puts("\n");
    c.platform_uart_puts("========================================\n");
    c.platform_uart_puts(" Metal-V Interactive Shell (Zig)\n");
    c.platform_uart_puts(" RISC-V Bare Metal Command Interface\n");
    c.platform_uart_puts("========================================\n");
    c.platform_uart_puts("\nPlatform: ");

    const config = c.get_platform_config();
    if (config.*.type == c.PLATFORM_QEMU) {
        c.platform_uart_puts("QEMU");
    } else {
        c.platform_uart_puts("K230");
    }

    c.platform_uart_puts("\n");
    c.platform_uart_puts("Type 'help' for available commands.\n\n");
}

fn printPrompt() void {
    c.platform_uart_puts("metal-v> ");
}

export fn main() noreturn {
    // Use platform constant from C (TARGET_PLATFORM is defined in platform-specific C files)
    c.platform_init(c.TARGET_PLATFORM);
    c.platform_uart_init();
    handler.init();

    // Print welcome banner
    printBanner();

    // Command buffer
    var cmd_buffer: [parser.MAX_COMMAND_LENGTH]u8 = undefined;
    var parsed: parser.ParsedCommand = undefined;

    // Main command loop
    while (true) {
        // Print prompt
        printPrompt();

        // Read command line
        const len = parser.readLine(&cmd_buffer, parser.MAX_COMMAND_LENGTH);

        // Skip empty lines
        if (len == 0) {
            continue;
        }

        // Parse command
        if (parser.parse(&cmd_buffer, &parsed)) {
            // Execute command
            _ = handler.execute(&parsed);
        }

        c.platform_uart_puts("\n");
    }
}
