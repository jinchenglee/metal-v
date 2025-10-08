#ifndef CMD_PARSER_H
#define CMD_PARSER_H

#include <stddef.h>

#define MAX_COMMAND_LENGTH 128
#define MAX_COMMAND_ARGS 8

/**
 * @brief Structure to hold parsed command
 */
typedef struct {
    char *command;           // Command name (e.g., "readmem")
    char *args[MAX_COMMAND_ARGS];  // Array of argument strings
    int arg_count;           // Number of arguments
} parsed_command_t;

/**
 * @brief Read a line of input from UART
 * @param buffer Buffer to store the line
 * @param max_length Maximum length of the buffer
 * @return Number of characters read (excluding null terminator)
 */
int cmd_read_line(char *buffer, size_t max_length);

/**
 * @brief Parse a command string into command and arguments
 * @param input The input string to parse
 * @param parsed Pointer to parsed_command_t structure to fill
 * @return 1 if successful, 0 if failed
 * 
 * Note: This function modifies the input string by replacing delimiters with null terminators
 */
int cmd_parse(char *input, parsed_command_t *parsed);

#endif // CMD_PARSER_H

