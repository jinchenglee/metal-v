#include "cmd_parser.h"
#include "platform.h"
#include "utils.h"

int cmd_read_line(char *buffer, size_t max_length) {
    size_t pos = 0;
    char c;
    
    while (pos < max_length - 1) {
        c = platform_uart_getc();
        
        // Handle backspace
        if (c == '\b' || c == 127) {  // Backspace or DEL
            if (pos > 0) {
                pos--;
                // Echo backspace sequence: backspace, space, backspace
                platform_uart_putc('\b');
                platform_uart_putc(' ');
                platform_uart_putc('\b');
            }
            continue;
        }
        
        // Handle Enter key (CR or LF)
        if (c == '\r' || c == '\n') {
            platform_uart_putc('\r');
            platform_uart_putc('\n');
            break;
        }
        
        // Handle printable characters
        if (c >= 32 && c <= 126) {
            buffer[pos++] = c;
            platform_uart_putc(c);  // Echo character
        }
    }
    
    buffer[pos] = '\0';
    return pos;
}

int cmd_parse(char *input, parsed_command_t *parsed) {
    if (!input || !parsed) {
        return 0;
    }
    
    // Initialize parsed command
    parsed->command = 0;
    parsed->arg_count = 0;
    for (int i = 0; i < MAX_COMMAND_ARGS; i++) {
        parsed->args[i] = 0;
    }
    
    // Skip leading whitespace
    while (*input && utils_is_whitespace(*input)) {
        input++;
    }
    
    // Empty command
    if (*input == '\0') {
        return 0;
    }
    
    // Extract command name
    parsed->command = input;
    while (*input && !utils_is_whitespace(*input)) {
        input++;
    }
    
    // Null-terminate command name
    if (*input) {
        *input = '\0';
        input++;
    }
    
    // Extract arguments
    while (*input && parsed->arg_count < MAX_COMMAND_ARGS) {
        // Skip whitespace between arguments
        while (*input && utils_is_whitespace(*input)) {
            input++;
        }
        
        if (*input == '\0') {
            break;
        }
        
        // Start of argument
        parsed->args[parsed->arg_count] = input;
        parsed->arg_count++;
        
        // Find end of argument
        while (*input && !utils_is_whitespace(*input)) {
            input++;
        }
        
        // Null-terminate argument
        if (*input) {
            *input = '\0';
            input++;
        }
    }
    
    return 1;
}

