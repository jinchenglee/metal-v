const c = @cImport({
    @cInclude("platform.h");
});

// Print a 32-bit integer in hexadecimal format
pub fn printHex32(value: u32) void {
    const hex_chars = "0123456789ABCDEF";

    var i: i32 = 7;
    while (i >= 0) : (i -= 1) {
        const digit = @as(u32, (value >> @as(u5, @intCast(i * 4))) & 0xF);
        c.platform_uart_putc(hex_chars[digit]);
    }
}

// Print a 64-bit integer in hexadecimal format
pub fn printHex64(value: u64) void {
    const hex_chars = "0123456789ABCDEF";

    var i: i32 = 15;
    while (i >= 0) : (i -= 1) {
        const digit: u8 = @intCast((value >> @as(u6, @intCast(i * 4))) & 0xF);
        c.platform_uart_putc(hex_chars[digit]);
    }
}

// Convert hex character to value
pub fn hexCharToValue(ch: u8) u32 {
    return switch (ch) {
        '0'...'9' => ch - '0',
        'A'...'F' => ch - 'A' + 10,
        'a'...'f' => ch - 'a' + 10,
        else => 0,
    };
}

// Check if character is a valid hex digit
pub fn isHexDigit(ch: u8) bool {
    return (ch >= '0' and ch <= '9') or
        (ch >= 'A' and ch <= 'F') or
        (ch >= 'a' and ch <= 'f');
}

// Parse a hex string to a 64-bit unsigned integer
pub fn parseHex64(str: [*:0]const u8, result: *u64) bool {
    var ptr = str;
    result.* = 0;

    // Skip optional 0x prefix
    if (ptr[0] == '0' and (ptr[1] == 'x' or ptr[1] == 'X')) {
        ptr += 2;
    }

    // Parse hex digits
    var digit_count: u32 = 0;
    while (ptr[0] != 0 and isHexDigit(ptr[0])) : (ptr += 1) {
        if (digit_count >= 16) { // Max 16 hex digits for 64-bit
            return false;
        }
        result.* = (result.* << 4) | hexCharToValue(ptr[0]);
        digit_count += 1;
    }

    // Must have at least one digit and no trailing characters
    return digit_count > 0 and ptr[0] == 0;
}

// Parse a decimal string to a 64-bit unsigned integer
pub fn parseDec64(str: [*:0]const u8, result: *u64) bool {
    var ptr = str;
    result.* = 0;

    // Parse decimal digits
    var digit_count: u32 = 0;
    while (ptr[0] >= '0' and ptr[0] <= '9') : (ptr += 1) {
        const old_result = result.*;
        result.* = result.* * 10 + (ptr[0] - '0');
        if (result.* < old_result) { // Overflow occurred
            return false;
        }
        digit_count += 1;
    }

    // Must have at least one digit and no trailing characters
    return digit_count > 0 and ptr[0] == 0;
}

// String length function
pub fn strlen(str: [*:0]const u8) usize {
    var len: usize = 0;
    while (str[len] != 0) : (len += 1) {}
    return len;
}

// String compare function
pub fn strcmp(s1: [*:0]const u8, s2: [*:0]const u8) i32 {
    var i: usize = 0;
    while (s1[i] != 0 and s1[i] == s2[i]) : (i += 1) {}
    return @as(i32, s1[i]) - @as(i32, s2[i]);
}

// Check if character is whitespace
pub fn isWhitespace(ch: u8) bool {
    return ch == ' ' or ch == '\t' or ch == '\n' or ch == '\r';
}
