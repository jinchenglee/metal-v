#include "platform.h"

// K230 Platform Type - exported for Zig to use
const platform_type_t TARGET_PLATFORM = PLATFORM_K230;

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
#define K230_UART_DLL  0x00        // Divisor Latch Low (when DLAB=1)
#define K230_UART_IER  0x04        // Interrupt Enable Register
#define K230_UART_DLM  0x04        // Divisor Latch High (when DLAB=1) - also DLH
#define K230_UART_FCR  0x08        // FIFO Control Register (write-only)
#define K230_UART_IIR  0x08        // Interrupt ID Register (read-only, same offset as FCR)
#define K230_UART_LCR  0x0C        // Line Control Register
#define K230_UART_MCR  0x10        // Modem Control Register
#define K230_UART_LSR  0x14        // Line Status Register
#define K230_UART_MSR  0x18        // Modem Status Register
#define K230_UART_SCH  0x1C        // Scratchpad High Register
#define K230_UART_USR  0x7C        // UART Status Register (DesignWare-specific, offset 31 << 2)
#define K230_UART_DLF  0xC0        // Divisor Latch Fraction (offset 48 << 2)

// K230 UART register values
#define K230_UART_LCR_8N1    0x03     // 8 data bits, no parity, 1 stop bit
#define K230_UART_LCR_DLAB   0x80     // Divisor Latch Access Bit
#define K230_UART_LSR_THRE   0x20     // Transmit Holding Register Empty
#define K230_UART_LSR_DR     0x01     // Data Ready (receiver has data)
#define K230_UART_FCR_ENABLE 0x07     // Enable FIFO, clear TX/RX
#define K230_UART_MCR_DTR_RTS 0x03    // DTR and RTS

// Global platform configuration
static platform_config_t current_platform;

// Calculate baud rate divisor with fraction (RT-Smart approach)
static void calculate_baud_divisor(uint32_t clock_freq, uint32_t baud_rate,
                                    uint32_t *dll, uint32_t *dlh, uint32_t *dlf) {
    uint32_t bdiv = clock_freq / baud_rate;
    
    *dlh = bdiv >> 12;
    *dll = (bdiv - (*dlh << 12)) / 16;
    *dlf = bdiv - (*dlh << 12) - (*dll * 16);
    
    // Ensure at least minimum divisor
    if (*dlh == 0 && *dll == 0) {
        *dll = 1;
        *dlf = 0;
    }
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
    uint32_t bdiv, dll, dlh, dlf;
    
    // Calculate baud rate divisor with fraction (RT-Smart approach)
    calculate_baud_divisor(config->uart_clock_freq, config->baud_rate, &dll, &dlh, &dlf);
    bdiv = config->uart_clock_freq / config->baud_rate;
    
    volatile uint32_t *uart_lcr = (volatile uint32_t *)(config->uart_base + K230_UART_LCR);
    volatile uint32_t *uart_ier = (volatile uint32_t *)(config->uart_base + K230_UART_IER);
    volatile uint32_t *uart_dll = (volatile uint32_t *)(config->uart_base + K230_UART_DLL);
    volatile uint32_t *uart_dlh = (volatile uint32_t *)(config->uart_base + K230_UART_DLM);
    volatile uint32_t *uart_dlf = (volatile uint32_t *)(config->uart_base + K230_UART_DLF);
    volatile uint32_t *uart_fcr = (volatile uint32_t *)(config->uart_base + K230_UART_FCR);
    volatile uint32_t *uart_mcr = (volatile uint32_t *)(config->uart_base + K230_UART_MCR);
    volatile uint32_t *uart_lsr = (volatile uint32_t *)(config->uart_base + K230_UART_LSR);
    volatile uint32_t *uart_rbr = (volatile uint32_t *)(config->uart_base + K230_UART_RBR);
    volatile uint32_t *uart_usr = (volatile uint32_t *)(config->uart_base + K230_UART_USR);
    volatile uint32_t *uart_iir = (volatile uint32_t *)(config->uart_base + K230_UART_IIR);
    volatile uint32_t *uart_sch = (volatile uint32_t *)(config->uart_base + K230_UART_SCH);
    
    // RT-Smart initialization sequence:
    
    // Step 1: Clear LCR first to ensure known state
    *uart_lcr = 0x00;
    
    // Step 2: Disable all interrupts
    *uart_ier = 0x00;
    
    // Step 3: Enable DLAB (Divisor Latch Access Bit) - 0x80 only
    *uart_lcr = 0x80;
    
    // Step 4: Set divisor registers (only if divisor is valid)
    if (bdiv) {
        *uart_dll = dll;  // Set divisor low byte
        *uart_dlh = dlh;  // Set divisor high byte
        *uart_dlf = dlf;  // Set divisor fraction byte
    }
    
    // Step 5: 8 bits, no parity, one stop bit (disable DLAB)
    *uart_lcr = 0x03;
    
    // Step 6: Enable FIFO
    *uart_fcr = 0x01;
    
    // Step 7: No modem control DTR RTS
    *uart_mcr = 0x00;
    
    // Step 8: Clear line status
    (void)*uart_lsr;
    
    // Step 9: Read receive buffer
    (void)*uart_rbr;
    
    // Step 10: Read UART status (DesignWare-specific)
    (void)*uart_usr;
    
    // Step 11: Read interrupt ID (reading FCR offset reads IIR)
    (void)*uart_iir;
    
    // Step 12: Set scratchpad
    *uart_sch = 0x00;
}

void platform_uart_putc(char c) {
    const platform_config_t* config = get_platform_config();
    volatile uint32_t *uart_lsr = (volatile uint32_t *)(config->uart_base + K230_UART_LSR);
    volatile uint32_t *uart_thr = (volatile uint32_t *)(config->uart_base + K230_UART_THR);
    
    // Handle line endings: send CR before LF for proper terminal display
    if (c == '\n') {
        // Wait for transmit buffer to be empty
        while (!(*uart_lsr & K230_UART_LSR_THRE)) {
            // Busy wait
        }
        *uart_thr = '\r';  // Send carriage return first
    }
    
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
