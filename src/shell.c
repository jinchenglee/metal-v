#include <stdint.h>
#include "platform.h"
#include "cmd_parser.h"
#include "cmd_handler.h"
#include "utils.h"

// Print welcome banner
static void print_banner(void) {
    platform_uart_puts("\n");
    platform_uart_puts("========================================\n");
    platform_uart_puts(" Metal-V Interactive Shell\n");
    platform_uart_puts(" RISC-V Bare Metal Command Interface\n");
    platform_uart_puts("========================================\n");
    platform_uart_puts("\nPlatform: ");
#ifdef QEMU_TARGET
    platform_uart_puts("QEMU");
#else
    platform_uart_puts("K230");
#endif
    platform_uart_puts("\n");
    platform_uart_puts("Type 'help' for available commands.\n\n");
}

// Print command prompt
static void print_prompt(void) {
    platform_uart_puts("metal-v> ");
}

// Main function
int main(void) {
    // Initialize platform
#ifdef QEMU_TARGET
    platform_init(PLATFORM_QEMU);
#else
    platform_init(PLATFORM_K230);
#endif

    // Initialize UART
    platform_uart_init();

    // Initialize command handler system
    cmd_init();

    // Print welcome banner
    print_banner();

    // Command buffer
    char cmd_buffer[MAX_COMMAND_LENGTH];
    parsed_command_t parsed;

    // Main command loop
    while (1) {
        // Print prompt
        print_prompt();

        // Read command line
        int len = cmd_read_line(cmd_buffer, MAX_COMMAND_LENGTH);

        // Skip empty lines
        if (len == 0) {
            continue;
        }

        // Parse command
        if (cmd_parse(cmd_buffer, &parsed)) {
            // Execute command
            cmd_execute(&parsed);
        }

        platform_uart_puts("\n");
    }

    return 0;  // Never reached
}

