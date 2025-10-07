const std = @import("std");
const c = @cImport({
    @cInclude("platform.h");
});

// Function to print a 32-bit integer in hexadecimal format
fn printHex(value: u32) void {
    const hex_chars = "0123456789ABCDEF";
    
    var i: i32 = 7;
    while (i >= 0) : (i -= 1) {
        const digit = @as(u32, (value >> @as(u5, @intCast(i * 4))) & 0xF);
        c.platform_uart_putc(hex_chars[digit]);
    }
}

// Simple delay function
fn delayLoop(count: u32) void {
    var i: u32 = 0;
    while (i < count) : (i += 1) {
        // Busy wait - equivalent to __asm__ volatile("nop")
        asm volatile ("nop");
    }
}

// Function to convert hex character to value
fn hexCharToValue(input_char: u8) u32 {
    return switch (input_char) {
        '0'...'9' => input_char - '0',
        'A'...'F' => input_char - 'A' + 10,
        'a'...'f' => input_char - 'a' + 10,
        else => 0, // Invalid character
    };
}

// Function to read a hexadecimal address from UART input
fn readHexAddress() usize {
    var address: usize = 0;
    var valid_chars: u32 = 0;
    var max_chars_reached = false;
    
    while (true) {
        const received_char = c.platform_uart_getc();
        
        // Check for Enter key (CR or LF) - input completed
        if (received_char == '\r' or received_char == '\n') {
            c.platform_uart_putc('\n');  // Echo the newline
            break;
        }
        
        // If we've already reached max characters, ignore all input except Enter
        if (max_chars_reached) {
            continue;
        }
        
        // Echo the character back
        c.platform_uart_putc(received_char);
        
        // Check if it's a valid hex character
        if ((received_char >= '0' and received_char <= '9') or 
            (received_char >= 'A' and received_char <= 'F') or 
            (received_char >= 'a' and received_char <= 'f')) {
            // Check if we've reached the maximum number of characters
            if (valid_chars >= 8) {
                c.platform_uart_putc('\n');
                c.platform_uart_puts("Maximum 8 hex characters allowed. Press Enter to confirm.\n");
                max_chars_reached = true;
                continue;
            }
            address = (address << 4) | hexCharToValue(received_char);
            valid_chars += 1;
        } else {
            // Invalid character, reset and start over
            c.platform_uart_putc('\n');
            c.platform_uart_puts("Invalid hex character: \"");
            c.platform_uart_putc(received_char);
            c.platform_uart_puts("\". Use 0-9, A-F, or a-f. Starting over...\n");
            c.platform_uart_puts("Enter address: ");
            
            // Reset variables
            address = 0;
            valid_chars = 0;
            max_chars_reached = false;
        }
    }
    
    // If no valid characters were entered, provide additional hint
    if (valid_chars == 0) {
        c.platform_uart_puts("No valid hex characters entered. Using address 0x0\n");
    }
    
    return address;
}

// Function to read data from user-specified address and print it
fn readAndPrintAddressData() void {
    // Prompt for address input
    c.platform_uart_puts("Enter address: ");
    
    // Read the address
    const address = readHexAddress();
    
    // Print newline
    c.platform_uart_putc('\n');
    
    // Print the address that was read
    c.platform_uart_puts("Address: 0x");
    printHex(@as(u32, @intCast(address)));
    c.platform_uart_putc('\n');
    
    // Read data from the address using platform abstraction
    const data = c.platform_read_memory(address);
    
    // Print the data
    c.platform_uart_puts("Data: 0x");
    printHex(data);
    c.platform_uart_putc('\n');
}

// Main function
export fn main() c_int {
    // Initialize platform (default to K230, can be changed via compile-time flag)
    // Note: In Zig, we'll use a compile-time flag or environment variable
    // For now, defaulting to QEMU for demonstration
    c.platform_init(c.PLATFORM_QEMU);

    // Initialize UART
    c.platform_uart_init();

    // Print hello message with platform info
    c.platform_uart_puts("hello from ");
    c.platform_uart_puts("QEMU (Zig version)");
    c.platform_uart_puts("\n");
     
    while (true) {
        // Read address from input and print data from that address
        readAndPrintAddressData();

        // Print some words
        c.platform_uart_puts("Done\n");
        
        // Introduce a delay
        delayLoop(5000000);
    }
    
    return 0;  // This should never be reached
}
