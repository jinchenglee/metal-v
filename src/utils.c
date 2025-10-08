#include "utils.h"
#include "platform.h"

void utils_print_hex32(uint32_t value) {
    const char hex_chars[] = "0123456789ABCDEF";
    
    for (int i = 7; i >= 0; i--) {
        uint32_t digit = (value >> (i * 4)) & 0xF;
        platform_uart_putc(hex_chars[digit]);
    }
}

void utils_print_hex64(uint64_t value) {
    const char hex_chars[] = "0123456789ABCDEF";
    
    for (int i = 15; i >= 0; i--) {
        uint32_t digit = (value >> (i * 4)) & 0xF;
        platform_uart_putc(hex_chars[digit]);
    }
}

uint32_t utils_hex_char_to_value(char c) {
    if (c >= '0' && c <= '9') {
        return c - '0';
    } else if (c >= 'A' && c <= 'F') {
        return c - 'A' + 10;
    } else if (c >= 'a' && c <= 'f') {
        return c - 'a' + 10;
    }
    return 0;
}

int utils_is_hex_digit(char c) {
    return (c >= '0' && c <= '9') ||
           (c >= 'A' && c <= 'F') ||
           (c >= 'a' && c <= 'f');
}

int utils_parse_hex64(const char *str, uint64_t *result) {
    if (!str || !result) {
        return 0;
    }
    
    *result = 0;
    
    // Skip optional 0x prefix
    if (str[0] == '0' && (str[1] == 'x' || str[1] == 'X')) {
        str += 2;
    }
    
    // Parse hex digits
    int digit_count = 0;
    while (*str && utils_is_hex_digit(*str)) {
        if (digit_count >= 16) {  // Max 16 hex digits for 64-bit
            return 0;
        }
        *result = (*result << 4) | utils_hex_char_to_value(*str);
        str++;
        digit_count++;
    }
    
    // Must have at least one digit and no trailing characters
    return digit_count > 0 && *str == '\0';
}

int utils_parse_dec64(const char *str, uint64_t *result) {
    if (!str || !result) {
        return 0;
    }
    
    *result = 0;
    
    // Parse decimal digits
    int digit_count = 0;
    while (*str >= '0' && *str <= '9') {
        // Check for overflow (simplified check)
        uint64_t old_result = *result;
        *result = *result * 10 + (*str - '0');
        if (*result < old_result) {  // Overflow occurred
            return 0;
        }
        str++;
        digit_count++;
    }
    
    // Must have at least one digit and no trailing characters
    return digit_count > 0 && *str == '\0';
}

size_t utils_strlen(const char *str) {
    size_t len = 0;
    while (str[len] != '\0') {
        len++;
    }
    return len;
}

int utils_strcmp(const char *s1, const char *s2) {
    while (*s1 && (*s1 == *s2)) {
        s1++;
        s2++;
    }
    return *(const unsigned char *)s1 - *(const unsigned char *)s2;
}

int utils_is_whitespace(char c) {
    return c == ' ' || c == '\t' || c == '\n' || c == '\r';
}

