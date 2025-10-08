#ifndef CMD_HANDLER_H
#define CMD_HANDLER_H

#include "cmd_parser.h"

#define MAX_COMMANDS 16

/**
 * @brief Command handler function type
 * @param argc Number of arguments
 * @param argv Array of argument strings
 * @return 0 on success, non-zero on error
 */
typedef int (*command_handler_func_t)(int argc, char *argv[]);

/**
 * @brief Command structure
 */
typedef struct {
    const char *name;               // Command name
    const char *help;               // Help text
    command_handler_func_t handler; // Handler function
} command_t;

/**
 * @brief Initialize the command handler system
 */
void cmd_init(void);

/**
 * @brief Register a new command
 * @param name Command name
 * @param help Help text describing the command
 * @param handler Function to handle the command
 * @return 1 if successful, 0 if failed (e.g., too many commands)
 */
int cmd_register(const char *name, const char *help, command_handler_func_t handler);

/**
 * @brief Execute a parsed command
 * @param parsed Parsed command structure
 * @return 0 on success, non-zero on error
 */
int cmd_execute(parsed_command_t *parsed);

/**
 * @brief Get list of registered commands (for help command)
 * @param count Pointer to store the number of commands
 * @return Pointer to array of commands
 */
const command_t* cmd_get_commands(int *count);

#endif // CMD_HANDLER_H

