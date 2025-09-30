#include "platform.h"

// K230 platform configuration
static const platform_config_t k230_config = {
    .type = PLATFORM_K230,
    .uart_base = 0x91403000,  // UART3=ttyACM1
    .uart_clock_freq = 50000000,  // 50MHz
    .baud_rate = 115200,
    .memory_base = 0x2000000,
    .memory_size = 64 * 1024  // 64KB
};

// K230 UART register offsets (with reg-shift=2, registers are 4 bytes apart)
#define K230_UART_RBR  0x00        // Receiver Buffer Register (read)
#define K230_UART_THR  0x00        // Transmit Holding Register (write) - same as RBR
#define K230_UART_IER  0x04        // Interrupt Enable Register
#define K230_UART_FCR  0x08        // FIFO Control Register
#define K230_UART_LCR  0x0C        // Line Control Register
#define K230_UART_MCR  0x10        // Modem Control Register
#define K230_UART_LSR  0x14        // Line Status Register
#define K230_UART_MSR  0x18        // Modem Status Register

// K230 UART register values
#define K230_UART_LCR_8N1    0x03     // 8 data bits, no parity, 1 stop bit
#define K230_UART_LCR_DLAB   0x80     // Divisor Latch Access Bit
#define K230_UART_LSR_THRE   0x20     // Transmit Holding Register Empty
#define K230_UART_LSR_DR     0x01     // Data Ready (receiver has data)
#define K230_UART_FCR_ENABLE 0x07     // Enable FIFO, clear TX/RX
#define K230_UART_MCR_DTR_RTS 0x03    // DTR and RTS

// Global platform configuration
static platform_config_t current_platform;

// Calculate baud rate divisor
static uint32_t calculate_baud_divisor(uint32_t clock_freq, uint32_t baud_rate) {
    return clock_freq / (16 * baud_rate);
}

void platform_init(platform_type_t platform) {
    if (platform == PLATFORM_K230) {
        current_platform = k230_config;
    }
}

const platform_config_t* get_platform_config(void) {
    return &current_platform;
}

void platform_uart_init(void) {
    const platform_config_t* config = get_platform_config();
    uint32_t baud_divisor = calculate_baud_divisor(config->uart_clock_freq, config->baud_rate);
    
    volatile uint32_t *uart_lsr = (volatile uint32_t *)(config->uart_base + K230_UART_LSR);
    volatile uint32_t *uart_lcr = (volatile uint32_t *)(config->uart_base + K230_UART_LCR);
    volatile uint32_t *uart_thr = (volatile uint32_t *)(config->uart_base + K230_UART_THR);
    volatile uint32_t *uart_ier = (volatile uint32_t *)(config->uart_base + K230_UART_IER);
    volatile uint32_t *uart_fcr = (volatile uint32_t *)(config->uart_base + K230_UART_FCR);
    volatile uint32_t *uart_mcr = (volatile uint32_t *)(config->uart_base + K230_UART_MCR);
    
    // Wait for transmitter to be empty
    while (!(*uart_lsr & 0x40)) {  // Check TEMT bit
        // Busy wait
    }
    
    // Set baud rate divisor
    *uart_lcr = K230_UART_LCR_DLAB | K230_UART_LCR_8N1;
    *uart_thr = baud_divisor & 0xFF;        // DLL register
    *uart_ier = (baud_divisor >> 8) & 0xFF; // DLM register
    
    // Set line control (8N1, disable DLAB)
    *uart_lcr = K230_UART_LCR_8N1;
    
    // Enable FIFO
    *uart_fcr = K230_UART_FCR_ENABLE;
    
    // Set modem control
    *uart_mcr = K230_UART_MCR_DTR_RTS;
}

void platform_uart_putc(char c) {
    const platform_config_t* config = get_platform_config();
    volatile uint32_t *uart_lsr = (volatile uint32_t *)(config->uart_base + K230_UART_LSR);
    volatile uint32_t *uart_thr = (volatile uint32_t *)(config->uart_base + K230_UART_THR);
    
    // Wait for transmit buffer to be empty
    while (!(*uart_lsr & K230_UART_LSR_THRE)) {
        // Busy wait
    }
    
    // Write character to transmit buffer
    *uart_thr = c;
}

void platform_uart_puts(const char *str) {
    while (*str) {
        platform_uart_putc(*str++);
    }
}

char platform_uart_getc(void) {
    const platform_config_t* config = get_platform_config();
    volatile uint32_t *uart_lsr = (volatile uint32_t *)(config->uart_base + K230_UART_LSR);
    volatile uint32_t *uart_rbr = (volatile uint32_t *)(config->uart_base + K230_UART_RBR);
    
    // Wait for data to be available
    while (!(*uart_lsr & K230_UART_LSR_DR)) {
        // Busy wait
    }
    
    // Read character from receive buffer
    return (char)(*uart_rbr & 0xFF);
}

uint32_t platform_read_memory(uintptr_t address) {
    volatile uint32_t *addr_ptr = (volatile uint32_t *)address;
    return *addr_ptr;
}

void platform_write_memory(uintptr_t address, uint32_t value) {
    volatile uint32_t *addr_ptr = (volatile uint32_t *)address;
    *addr_ptr = value;
}
