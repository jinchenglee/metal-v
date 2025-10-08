#ifndef UTILS_H
#define UTILS_H

#include <stdint.h>
#include <stddef.h>

/**
 * @brief Print a 32-bit integer in hexadecimal format
 * @param value The value to print
 */
void utils_print_hex32(uint32_t value);

/**
 * @brief Print a 64-bit integer in hexadecimal format
 * @param value The value to print
 */
void utils_print_hex64(uint64_t value);

/**
 * @brief Convert hex character to value
 * @param c The character to convert
 * @return Value (0-15) or 0 if invalid
 */
uint32_t utils_hex_char_to_value(char c);

/**
 * @brief Check if character is a valid hex digit
 * @param c The character to check
 * @return 1 if valid hex digit, 0 otherwise
 */
int utils_is_hex_digit(char c);

/**
 * @brief Parse a hex string to a 64-bit unsigned integer
 * @param str The hex string to parse (with or without 0x prefix)
 * @param result Pointer to store the result
 * @return 1 if successful, 0 if failed
 */
int utils_parse_hex64(const char *str, uint64_t *result);

/**
 * @brief Parse a decimal string to a 64-bit unsigned integer
 * @param str The decimal string to parse
 * @param result Pointer to store the result
 * @return 1 if successful, 0 if failed
 */
int utils_parse_dec64(const char *str, uint64_t *result);

/**
 * @brief Simple string length function
 * @param str The string
 * @return Length of the string
 */
size_t utils_strlen(const char *str);

/**
 * @brief Simple string compare function
 * @param s1 First string
 * @param s2 Second string
 * @return 0 if equal, non-zero otherwise
 */
int utils_strcmp(const char *s1, const char *s2);

/**
 * @brief Check if character is whitespace
 * @param c The character to check
 * @return 1 if whitespace, 0 otherwise
 */
int utils_is_whitespace(char c);

#endif // UTILS_H

