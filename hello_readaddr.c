#include <stdint.h>

// UART register offsets (with reg-shift=2, registers are 4 bytes apart)
//#define UART_BASE 0x91400000  // UART0=ttyACM0
#define UART_BASE 0x91403000  // UART3=ttyACM1
#define UART_RBR  0x00        // Receiver Buffer Register (read)
#define UART_THR  0x00        // Transmit Holding Register (write) - same as RBR
#define UART_IER  0x04        // Interrupt Enable Register
#define UART_FCR  0x08        // FIFO Control Register
#define UART_LCR  0x0C        // Line Control Register
#define UART_MCR  0x10        // Modem Control Register
#define UART_LSR  0x14        // Line Status Register
#define UART_MSR  0x18        // Modem Status Register

// UART register values
#define UART_LCR_8N1    0x03     // 8 data bits, no parity, 1 stop bit
#define UART_LCR_DLAB   0x80     // Divisor Latch Access Bit
#define UART_LSR_THRE   0x20     // Transmit Holding Register Empty
#define UART_LSR_DR     0x01     // Data Ready (receiver has data)
#define UART_FCR_ENABLE 0x07     // Enable FIFO, clear TX/RX
#define UART_MCR_DTR_RTS 0x03    // DTR and RTS

// Calculate baud rate divisor for 115200 baud with 50MHz clock
// divisor = clock / (16 * baudrate) = 50000000 / (16 * 115200) ≈ 27
#define BAUD_DIVISOR 27

// Function prototypes
void uart_init(void);
void uart_putc(char c);
void uart_puts(const char *str);
char uart_getc(void);
void print_hex(uint32_t value);
void delay_loop(uint32_t count);
uintptr_t read_hex_address(void);
void read_and_print_address_data(void);

// UART initialization function
void uart_init(void) {
    volatile uint32_t *uart_lsr = (volatile uint32_t *)(UART_BASE + UART_LSR);
    volatile uint32_t *uart_lcr = (volatile uint32_t *)(UART_BASE + UART_LCR);
    volatile uint32_t *uart_thr = (volatile uint32_t *)(UART_BASE + UART_THR);
    volatile uint32_t *uart_ier = (volatile uint32_t *)(UART_BASE + UART_IER);
    volatile uint32_t *uart_fcr = (volatile uint32_t *)(UART_BASE + UART_FCR);
    volatile uint32_t *uart_mcr = (volatile uint32_t *)(UART_BASE + UART_MCR);
    
    // Wait for transmitter to be empty
    while (!(*uart_lsr & 0x40)) {  // Check TEMT bit
        // Busy wait
    }
    
    // Set baud rate divisor
    *uart_lcr = UART_LCR_DLAB | UART_LCR_8N1;
    *uart_thr = BAUD_DIVISOR & 0xFF;        // DLL register
    *uart_ier = (BAUD_DIVISOR >> 8) & 0xFF; // DLM register
    
    // Set line control (8N1, disable DLAB)
    *uart_lcr = UART_LCR_8N1;
    
    // Enable FIFO
    *uart_fcr = UART_FCR_ENABLE;
    
    // Set modem control
    *uart_mcr = UART_MCR_DTR_RTS;
}

// UART put character function
void uart_putc(char c) {
    volatile uint32_t *uart_lsr = (volatile uint32_t *)(UART_BASE + UART_LSR);
    volatile uint32_t *uart_thr = (volatile uint32_t *)(UART_BASE + UART_THR);
    
    // Wait for transmit buffer to be empty
    while (!(*uart_lsr & UART_LSR_THRE)) {
        // Busy wait
    }
    
    // Write character to transmit buffer
    *uart_thr = c;
}

// UART put string function
void uart_puts(const char *str) {
    while (*str) {
        uart_putc(*str++);
    }
}

// UART get character function
char uart_getc(void) {
    volatile uint32_t *uart_lsr = (volatile uint32_t *)(UART_BASE + UART_LSR);
    volatile uint32_t *uart_rbr = (volatile uint32_t *)(UART_BASE + UART_RBR);
    
    // Wait for data to be available
    while (!(*uart_lsr & UART_LSR_DR)) {
        // Busy wait
    }
    
    // Read character from receive buffer
    return (char)(*uart_rbr & 0xFF);
}

// Function to print a 32-bit integer in hexadecimal format
void print_hex(uint32_t value) {
    const char hex_chars[] = "0123456789ABCDEF";
    
    for (int i = 7; i >= 0; i--) {
        uint32_t digit = (value >> (i * 4)) & 0xF;
        uart_putc(hex_chars[digit]);
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
    
    while (1) {
        c = uart_getc();
        
        // Check for Enter key (CR or LF) - input completed
        if (c == '\r' || c == '\n') {
            uart_putc('\n');  // Echo the newline
            break;
        }
        
        // Echo the character back
        uart_putc(c);
        
        // Check if it's a valid hex character
        if ((c >= '0' && c <= '9') || 
            (c >= 'A' && c <= 'F') || 
            (c >= 'a' && c <= 'f')) {
            // Check if we've reached the maximum number of characters
            if (valid_chars >= 8) {
                uart_putc('\n');
                uart_puts("Maximum 8 hex characters allowed. Press Enter to confirm.\n");
                continue;
            }
            address = (address << 4) | hex_char_to_value(c);
            valid_chars++;
        } else {
            // Invalid character, reset and start over
            uart_putc('\n');
            uart_puts("Invalid hex character: \"");
            uart_putc(c);
            uart_puts("\". Use 0-9, A-F, or a-f. Starting over...\n");
            uart_puts("Enter address: ");
            
            // Reset variables
            address = 0;
            valid_chars = 0;
        }
    }
    
    // If no valid characters were entered, provide additional hint
    if (valid_chars == 0) {
        uart_puts("No valid hex characters entered. Using address 0x0\n");
    }
    
    return address;
}

// Function to read data from user-specified address and print it
void read_and_print_address_data(void) {
    // Prompt for address input
    uart_puts("Enter address: ");
    
    // Read the address
    uintptr_t address = read_hex_address();
    
    // Print newline
    uart_putc('\n');
    
    // Print the address that was read
    uart_puts("Address: 0x");
    print_hex(address);
    uart_putc('\n');
    
    //// Read data from the address
    volatile uint32_t *addr_ptr = (volatile uint32_t *)(uintptr_t)address;
    uint32_t data = *addr_ptr;
    
    //// Print the data
    uart_puts("Data: 0x");
    print_hex(data);
    uart_putc('\n');
}

// Main function
int main(void) {
    // Initialize UART
    uart_init();

    // Print hello message
    uart_puts("hello\n");
     
    while (1) {
       

        //// Read and print address value
        //volatile uint32_t *addr = (volatile uint32_t *)0x1000000;
        //uint32_t value = *addr;
        //print_hex(value);
        //uart_putc('\n');
        
        //// Print hardcoded value
        //print_hex(0xDEADBEEF);
        //uart_putc('\n');
        
        ////// Get character and echo it back
        //char c = uart_getc();
        //uart_putc(c);
        //uart_putc('\n');
        
        //// Read address from input and print data from that address
        read_and_print_address_data();

        //// Print some words
        uart_puts("Done\n");
        
        // Introduce a delay
        delay_loop(5000000);
    }
    
    return 0;  // This should never be reached
}
