#include "platform.h"

// QEMU platform configuration
static const platform_config_t qemu_config = {
    .type = PLATFORM_QEMU,
    .uart_base = 0x10000000,  // QEMU virt machine UART
    .uart_clock_freq = 10000000,  // 10MHz (typical QEMU frequency)
    .baud_rate = 115200,
    .memory_base = 0x80000000,  // QEMU virt machine M-mode firmware load address
    .memory_size = 128 * 1024 * 1024  // 128MB
};

// QEMU 16550A UART register offsets (1 byte apart)
#define QEMU_UART_THR  0x00        // Transmit Holding Register
#define QEMU_UART_RBR  0x00        // Receive Buffer Register (same as THR)
#define QEMU_UART_LSR  0x05        // Line Status Register

// QEMU UART register values
#define QEMU_UART_LSR_TX_IDLE  (1 << 5) // Transmitter idle
#define QEMU_UART_LSR_RX_READY (1 << 0) // Receiver ready

// Global platform configuration
static platform_config_t current_platform;

void platform_init(platform_type_t platform) {
    if (platform == PLATFORM_QEMU) {
        current_platform = qemu_config;
    }
}

const platform_config_t* get_platform_config(void) {
    return &current_platform;
}

void platform_uart_init(void) {
    // QEMU UART initialization - much simpler, no initialization needed
    // The 16550A UART in QEMU is already configured and ready to use
}

void platform_uart_putc(char c) {
    const platform_config_t* config = get_platform_config();
    volatile char *uart_lsr = (volatile char *)(config->uart_base + QEMU_UART_LSR);
    volatile char *uart_thr = (volatile char *)(config->uart_base + QEMU_UART_THR);
    
    // Wait until transmitter is idle
    while ((*uart_lsr & QEMU_UART_LSR_TX_IDLE) == 0);
    *uart_thr = c;
    
    // Special handling for newline (send CR+LF)
    if (c == '\n') {
        while ((*uart_lsr & QEMU_UART_LSR_TX_IDLE) == 0);
        *uart_thr = '\r';
    }
}

void platform_uart_puts(const char *str) {
    while (*str) {
        platform_uart_putc(*str++);
    }
}

char platform_uart_getc(void) {
    const platform_config_t* config = get_platform_config();
    volatile char *uart_lsr = (volatile char *)(config->uart_base + QEMU_UART_LSR);
    volatile char *uart_rbr = (volatile char *)(config->uart_base + QEMU_UART_RBR);
    
    // Wait for data
    while ((*uart_lsr & QEMU_UART_LSR_RX_READY) == 0);
    return *uart_rbr;
}

uint32_t platform_read_memory(uintptr_t address) {
    volatile uint32_t *addr_ptr = (volatile uint32_t *)address;
    return *addr_ptr;
}

void platform_write_memory(uintptr_t address, uint32_t value) {
    volatile uint32_t *addr_ptr = (volatile uint32_t *)address;
    *addr_ptr = value;
}
