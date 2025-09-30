#ifndef PLATFORM_H
#define PLATFORM_H

#include <stdint.h>

// Platform types
typedef enum {
    PLATFORM_K230,
    PLATFORM_QEMU
} platform_type_t;

// Platform configuration structure
typedef struct {
    platform_type_t type;
    uintptr_t uart_base;
    uint32_t uart_clock_freq;
    uint32_t baud_rate;
    uintptr_t memory_base;
    uint32_t memory_size;
} platform_config_t;

// Platform-specific functions
void platform_init(platform_type_t platform);
const platform_config_t* get_platform_config(void);

// Platform-specific UART functions
void platform_uart_init(void);
void platform_uart_putc(char c);
void platform_uart_puts(const char *str);
char platform_uart_getc(void);

// Platform-specific memory functions
uint32_t platform_read_memory(uintptr_t address);
void platform_write_memory(uintptr_t address, uint32_t value);

#endif // PLATFORM_H
