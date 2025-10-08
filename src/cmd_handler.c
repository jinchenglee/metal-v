#include "cmd_handler.h"
#include "platform.h"
#include "utils.h"

// Array of registered commands
static command_t commands[MAX_COMMANDS];
static int command_count = 0;

// Forward declarations for built-in commands
static int cmd_help(int argc, char *argv[]);
static int cmd_read(int argc, char *argv[]);
static int cmd_write(int argc, char *argv[]);

void cmd_init(void) {
    command_count = 0;
    
    // Register built-in commands
    cmd_register("help", "Display available commands", cmd_help);
    cmd_register("read", "Read memory: read <addr> [size]", cmd_read);
    cmd_register("write", "Write memory: write <addr> <value>", cmd_write);
}

int cmd_register(const char *name, const char *help, command_handler_func_t handler) {
    if (command_count >= MAX_COMMANDS) {
        return 0;
    }
    
    commands[command_count].name = name;
    commands[command_count].help = help;
    commands[command_count].handler = handler;
    command_count++;
    
    return 1;
}

int cmd_execute(parsed_command_t *parsed) {
    if (!parsed || !parsed->command) {
        return -1;
    }
    
    // Find and execute the command
    for (int i = 0; i < command_count; i++) {
        if (utils_strcmp(parsed->command, commands[i].name) == 0) {
            return commands[i].handler(parsed->arg_count, parsed->args);
        }
    }
    
    // Command not found
    platform_uart_puts("Unknown command: ");
    platform_uart_puts(parsed->command);
    platform_uart_puts("\nType 'help' for available commands.\n");
    return -1;
}

const command_t* cmd_get_commands(int *count) {
    if (count) {
        *count = command_count;
    }
    return commands;
}

// Built-in command implementations
// =================================

static int cmd_help(int argc, char *argv[]) {
    (void)argc;  // Unused
    (void)argv;  // Unused
    
    platform_uart_puts("\nAvailable commands:\n");
    platform_uart_puts("-------------------\n");
    
    for (int i = 0; i < command_count; i++) {
        platform_uart_puts("  ");
        platform_uart_puts(commands[i].name);
        platform_uart_puts("\n    ");
        platform_uart_puts(commands[i].help);
        platform_uart_puts("\n\n");
    }
    
    return 0;
}

static int cmd_read(int argc, char *argv[]) {
    if (argc < 1) {
        platform_uart_puts("Error: read requires at least 1 argument\n");
        platform_uart_puts("Usage: read <addr> [size]\n");
        platform_uart_puts("  addr: Address in hex (e.g., 0x80200000 or 80200000)\n");
        platform_uart_puts("  size: Number of 32-bit words to read (default: 1)\n");
        return -1;
    }
    
    // Parse address
    uint64_t addr;
    if (!utils_parse_hex64(argv[0], &addr)) {
        platform_uart_puts("Error: Invalid address: ");
        platform_uart_puts(argv[0]);
        platform_uart_puts("\n");
        return -1;
    }
    
    // Get platform config for address validation
    const platform_config_t* config = get_platform_config();
    
    // Warning for potentially unmapped regions (but allow anyway for flexibility)
    if (addr < config->memory_base || addr > (config->memory_base + config->memory_size)) {
        platform_uart_puts("Warning: Address may be outside mapped memory region\n");
        platform_uart_puts("  Platform memory: 0x");
        utils_print_hex64(config->memory_base);
        platform_uart_puts(" - 0x");
        utils_print_hex64(config->memory_base + config->memory_size);
        platform_uart_puts("\n  Proceeding anyway (may cause crash)...\n\n");
    }
    
    // Parse size (optional, default to 1)
    uint64_t size = 1;
    if (argc >= 2) {
        // Try to parse as hex first, then decimal
        if (!utils_parse_hex64(argv[1], &size) && !utils_parse_dec64(argv[1], &size)) {
            platform_uart_puts("Error: Invalid size: ");
            platform_uart_puts(argv[1]);
            platform_uart_puts("\n");
            return -1;
        }
        
        // Sanity check on size
        if (size == 0 || size > 256) {
            platform_uart_puts("Error: Size must be between 1 and 256\n");
            return -1;
        }
    }
    
    // Read and display memory
    platform_uart_puts("\nReading ");
    utils_print_hex64(size);
    platform_uart_puts(" word(s) from 0x");
    utils_print_hex64(addr);
    platform_uart_puts(":\n");
    
    for (uint64_t i = 0; i < size; i++) {
        uint64_t current_addr = addr + (i * 4);
        uint32_t value = platform_read_memory(current_addr);
        
        // Print address
        platform_uart_puts("  0x");
        utils_print_hex64(current_addr);
        platform_uart_puts(": 0x");
        utils_print_hex32(value);
        platform_uart_puts("\n");
    }
    
    return 0;
}

static int cmd_write(int argc, char *argv[]) {
    if (argc < 2) {
        platform_uart_puts("Error: write requires 2 arguments\n");
        platform_uart_puts("Usage: write <addr> <value>\n");
        platform_uart_puts("  addr:  Address in hex (e.g., 0x80200000 or 80200000)\n");
        platform_uart_puts("  value: Value in hex to write (e.g., 0xDEADBEEF or DEADBEEF)\n");
        return -1;
    }
    
    // Parse address
    uint64_t addr;
    if (!utils_parse_hex64(argv[0], &addr)) {
        platform_uart_puts("Error: Invalid address: ");
        platform_uart_puts(argv[0]);
        platform_uart_puts("\n");
        return -1;
    }
    
    // Get platform config for address validation
    const platform_config_t* config = get_platform_config();
    
    // Warning for potentially unmapped regions
    if (addr < config->memory_base || addr > (config->memory_base + config->memory_size)) {
        platform_uart_puts("Warning: Address may be outside mapped memory region\n");
        platform_uart_puts("  Platform memory: 0x");
        utils_print_hex64(config->memory_base);
        platform_uart_puts(" - 0x");
        utils_print_hex64(config->memory_base + config->memory_size);
        platform_uart_puts("\n  Proceeding anyway (may cause crash)...\n\n");
    }
    
    // Parse value
    uint64_t value;
    if (!utils_parse_hex64(argv[1], &value)) {
        platform_uart_puts("Error: Invalid value: ");
        platform_uart_puts(argv[1]);
        platform_uart_puts("\n");
        return -1;
    }
    
    // Check if value fits in 32 bits
    if (value > 0xFFFFFFFF) {
        platform_uart_puts("Error: Value must be a 32-bit number (max 0xFFFFFFFF)\n");
        return -1;
    }
    
    // Write memory
    platform_uart_puts("Writing 0x");
    utils_print_hex32((uint32_t)value);
    platform_uart_puts(" to address 0x");
    utils_print_hex64(addr);
    platform_uart_puts("... ");
    
    platform_write_memory(addr, (uint32_t)value);
    
    platform_uart_puts("Done.\n");
    
    // Read back and verify
    uint32_t read_value = platform_read_memory(addr);
    platform_uart_puts("Read back: 0x");
    utils_print_hex32(read_value);
    
    if (read_value == (uint32_t)value) {
        platform_uart_puts(" [OK]\n");
    } else {
        platform_uart_puts(" [MISMATCH]\n");
    }
    
    return 0;
}

