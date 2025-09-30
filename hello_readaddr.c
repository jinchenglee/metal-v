#include <stdint.h>
#include "platform.h"

// Function prototypes
void print_hex(uint32_t value);
void delay_loop(uint32_t count);
uintptr_t read_hex_address(void);
void read_and_print_address_data(void);


// Function to print a 32-bit integer in hexadecimal format
void print_hex(uint32_t value) {
    const char hex_chars[] = "0123456789ABCDEF";
    
    for (int i = 7; i >= 0; i--) {
        uint32_t digit = (value >> (i * 4)) & 0xF;
        platform_uart_putc(hex_chars[digit]);
    }
}

// Simple delay function
void delay_loop(uint32_t count) {
    for (uint32_t i = 0; i < count; i++) {
        // Busy wait
        __asm__ volatile("nop");
    }
}

// Function to convert hex character to value
uint32_t hex_char_to_value(char c) {
    if (c >= '0' && c <= '9') {
        return c - '0';
    } else if (c >= 'A' && c <= 'F') {
        return c - 'A' + 10;
    } else if (c >= 'a' && c <= 'f') {
        return c - 'a' + 10;
    }
    return 0; // Invalid character
}

// Function to read a hexadecimal address from UART input
uintptr_t read_hex_address(void) {
    uintptr_t address = 0; // TODO: Is this a safe address to already reading from?
    char c;
    int valid_chars = 0;
    int max_chars_reached = 0;
    
    while (1) {
        c = platform_uart_getc();
        
        // Check for Enter key (CR or LF) - input completed
        if (c == '\r' || c == '\n') {
            platform_uart_putc('\n');  // Echo the newline
            break;
        }
        
        // If we've already reached max characters, ignore all input except Enter
        if (max_chars_reached) {
            continue;
        }
        
        // Echo the character back
        platform_uart_putc(c);
        
        // Check if it's a valid hex character
        if ((c >= '0' && c <= '9') || 
            (c >= 'A' && c <= 'F') || 
            (c >= 'a' && c <= 'f')) {
            // Check if we've reached the maximum number of characters
            if (valid_chars >= 8) {
                platform_uart_putc('\n');
                platform_uart_puts("Maximum 8 hex characters allowed. Press Enter to confirm.\n");
                max_chars_reached = 1;
                continue;
            }
            address = (address << 4) | hex_char_to_value(c);
            valid_chars++;
        } else {
            // Invalid character, reset and start over
            platform_uart_putc('\n');
            platform_uart_puts("Invalid hex character: \"");
            platform_uart_putc(c);
            platform_uart_puts("\". Use 0-9, A-F, or a-f. Starting over...\n");
            platform_uart_puts("Enter address: ");
            
            // Reset variables
            address = 0;
            valid_chars = 0;
            max_chars_reached = 0;
        }
    }
    
    // If no valid characters were entered, provide additional hint
    if (valid_chars == 0) {
        platform_uart_puts("No valid hex characters entered. Using address 0x0\n");
    }
    
    return address;
}

// Function to read data from user-specified address and print it
void read_and_print_address_data(void) {
    // Prompt for address input
    platform_uart_puts("Enter address: ");
    
    // Read the address
    uintptr_t address = read_hex_address();
    
    // Print newline
    platform_uart_putc('\n');
    
    // Print the address that was read
    platform_uart_puts("Address: 0x");
    print_hex(address);
    platform_uart_putc('\n');
    
    // Read data from the address using platform abstraction
    uint32_t data = platform_read_memory(address);
    
    // Print the data
    platform_uart_puts("Data: 0x");
    print_hex(data);
    platform_uart_putc('\n');
}

// Main function
int main(void) {
    // Initialize platform (default to K230, can be changed via compile-time flag)
#ifdef QEMU_TARGET
    platform_init(PLATFORM_QEMU);
#else
    platform_init(PLATFORM_K230);
#endif

    // Initialize UART
    platform_uart_init();

    // Print hello message with platform info
    platform_uart_puts("hello from ");
#ifdef QEMU_TARGET
    platform_uart_puts("QEMU");
#else
    platform_uart_puts("K230");
#endif
    platform_uart_puts("\n");
     
    while (1) {
        // Read address from input and print data from that address
        read_and_print_address_data();

        // Print some words
        platform_uart_puts("Done\n");
        
        // Introduce a delay
        delay_loop(5000000);
    }
    
    return 0;  // This should never be reached
}
