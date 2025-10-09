const c = @cImport({
    @cInclude("platform.h");
});
const utils = @import("utils.zig");

pub const MAX_COMMAND_LENGTH = 128;
pub const MAX_COMMAND_ARGS = 8;

pub const ParsedCommand = struct {
    command: ?[*:0]u8,
    args: [MAX_COMMAND_ARGS]?[*:0]u8,
    arg_count: i32,
};

// Read a line of input from UART
pub fn readLine(buffer: [*]u8, max_length: usize) i32 {
    var pos: usize = 0;

    while (pos < max_length - 1) {
        const ch = c.platform_uart_getc();

        // Handle backspace
        if (ch == '\x08' or ch == 127) { // Backspace or DEL
            if (pos > 0) {
                pos -= 1;
                // Echo backspace sequence: backspace, space, backspace
                c.platform_uart_putc('\x08');
                c.platform_uart_putc(' ');
                c.platform_uart_putc('\x08');
            }
            continue;
        }

        // Handle Enter key (CR or LF)
        if (ch == '\r' or ch == '\n') {
            c.platform_uart_putc('\r');
            c.platform_uart_putc('\n');
            break;
        }

        // Handle printable characters
        if (ch >= 32 and ch <= 126) {
            buffer[pos] = @intCast(ch);
            pos += 1;
            c.platform_uart_putc(ch); // Echo character
        }
    }

    buffer[pos] = 0;
    return @intCast(pos);
}

// Parse a command string into command and arguments
pub fn parse(input: [*]u8, parsed: *ParsedCommand) bool {
    var ptr = input;

    // Initialize parsed command
    parsed.command = null;
    parsed.arg_count = 0;
    var i: usize = 0;
    while (i < MAX_COMMAND_ARGS) : (i += 1) {
        parsed.args[i] = null;
    }

    // Skip leading whitespace
    while (ptr[0] != 0 and utils.isWhitespace(ptr[0])) {
        ptr += 1;
    }

    // Empty command
    if (ptr[0] == 0) {
        return false;
    }

    // Extract command name
    parsed.command = @ptrCast(ptr);
    while (ptr[0] != 0 and !utils.isWhitespace(ptr[0])) {
        ptr += 1;
    }

    // Null-terminate command name
    if (ptr[0] != 0) {
        ptr[0] = 0;
        ptr += 1;
    }

    // Extract arguments
    while (ptr[0] != 0 and parsed.arg_count < MAX_COMMAND_ARGS) {
        // Skip whitespace between arguments
        while (ptr[0] != 0 and utils.isWhitespace(ptr[0])) {
            ptr += 1;
        }

        if (ptr[0] == 0) {
            break;
        }

        // Start of argument
        parsed.args[@intCast(parsed.arg_count)] = @ptrCast(ptr);
        parsed.arg_count += 1;

        // Find end of argument
        while (ptr[0] != 0 and !utils.isWhitespace(ptr[0])) {
            ptr += 1;
        }

        // Null-terminate argument
        if (ptr[0] != 0) {
            ptr[0] = 0;
            ptr += 1;
        }
    }

    return true;
}
