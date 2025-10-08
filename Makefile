# RISC-V Bare Metal Hello World Makefile
# Supports both K230 and QEMU targets

# Toolchain
CC = riscv-none-elf-gcc
AS = riscv-none-elf-as
LD = riscv-none-elf-ld
OBJCOPY = riscv-none-elf-objcopy
ZIG = zig

# Compiler flags
BASE_CFLAGS = -march=rv64gc -mabi=lp64d -mcmodel=medany -fno-common -fno-builtin -fno-stack-protector -Wall -Wextra -O2 -g -Iinclude
K230_CFLAGS = $(BASE_CFLAGS)
QEMU_CFLAGS = $(BASE_CFLAGS) -DQEMU_TARGET
ASFLAGS = -march=rv64gc -mabi=lp64d

# Source files
C_SOURCE = src/hello_readaddr.c
SHELL_SOURCE = src/shell.c
UTILS_SOURCE = src/utils.c
CMD_PARSER_SOURCE = src/cmd_parser.c
CMD_HANDLER_SOURCE = src/cmd_handler.c
K230_PLATFORM_SOURCE = src/k230/k230_platform.c
QEMU_PLATFORM_SOURCE = src/qemu/qemu_platform.c
STARTUP_SOURCE = src/qemu/startup.s

# Object files for hello_readaddr
K230_C_OBJECT = k230_hello_readaddr_c.o
QEMU_C_OBJECT = qemu_hello_readaddr_c.o
K230_PLATFORM_OBJECT = k230_platform.o
QEMU_PLATFORM_OBJECT = qemu_platform.o
STARTUP_OBJECT = startup.o

# Object files for shell
K230_SHELL_OBJECT = k230_shell.o
QEMU_SHELL_OBJECT = qemu_shell.o
K230_UTILS_OBJECT = k230_utils.o
QEMU_UTILS_OBJECT = qemu_utils.o
K230_CMD_PARSER_OBJECT = k230_cmd_parser.o
QEMU_CMD_PARSER_OBJECT = qemu_cmd_parser.o
K230_CMD_HANDLER_OBJECT = k230_cmd_handler.o
QEMU_CMD_HANDLER_OBJECT = qemu_cmd_handler.o
K230_PLATFORM_SHELL_OBJECT = k230_platform_shell.o
QEMU_PLATFORM_SHELL_OBJECT = qemu_platform_shell.o



# Default target (run_shell)
.DEFAULT_GOAL := run_shell

# K230 targets
k230: k230.bin
k230_shell: k230_shell.bin

# QEMU targets
qemu: qemu.bin
qemu_shell: qemu_shell.bin

# QEMU Zig target
qemu_zig: qemu_zig.bin

# All targets
all: k230 qemu qemu_zig k230_shell qemu_shell



# K230 build
# ------------------------------------------------------------
k230.bin: k230.elf
	@echo "Creating K230 binary..."
	$(OBJCOPY) -O binary k230.elf k230.bin
	@echo "K230 version compiled successfully!"
	@echo "Binary: k230.bin"

k230.elf: $(K230_C_OBJECT) $(K230_PLATFORM_OBJECT)
	@echo "Linking K230 executable..."
	$(LD) -m elf64lriscv -T src/k230/k230.ld -nostdlib -static -o k230.elf $(K230_C_OBJECT) $(K230_PLATFORM_OBJECT)


# QEMU build
# ------------------------------------------------------------
qemu.bin: qemu.elf
	@echo "Creating QEMU binary..."
	$(OBJCOPY) -O binary qemu.elf qemu.bin
	@echo "QEMU version compiled successfully!"
	@echo "Binary: qemu.bin"

qemu.elf: $(STARTUP_OBJECT) $(QEMU_C_OBJECT) $(QEMU_PLATFORM_OBJECT)
	@echo "Linking QEMU executable..."
	$(LD) -m elf64lriscv -T src/qemu/qemu.ld -nostdlib -static -o qemu.elf $(STARTUP_OBJECT) $(QEMU_C_OBJECT) $(QEMU_PLATFORM_OBJECT)

# Object file compilation
$(K230_C_OBJECT): $(C_SOURCE)
	@echo "Compiling C source for K230..."
	$(CC) $(K230_CFLAGS) -c $(C_SOURCE) -o $(K230_C_OBJECT)

$(QEMU_C_OBJECT): $(C_SOURCE)
	@echo "Compiling C source for QEMU..."
	$(CC) $(QEMU_CFLAGS) -c $(C_SOURCE) -o $(QEMU_C_OBJECT)

$(K230_PLATFORM_OBJECT): $(K230_PLATFORM_SOURCE)
	@echo "Compiling K230 platform source..."
	$(CC) $(K230_CFLAGS) -c $(K230_PLATFORM_SOURCE) -o $(K230_PLATFORM_OBJECT)

$(QEMU_PLATFORM_OBJECT): $(QEMU_PLATFORM_SOURCE)
	@echo "Compiling QEMU platform source..."
	$(CC) $(QEMU_CFLAGS) -c $(QEMU_PLATFORM_SOURCE) -o $(QEMU_PLATFORM_OBJECT)

$(STARTUP_OBJECT): $(STARTUP_SOURCE)
	@echo "Assembling startup code..."
	$(AS) $(ASFLAGS) -c $(STARTUP_SOURCE) -o $(STARTUP_OBJECT)


# Shell build (K230)
# ------------------------------------------------------------
k230_shell.bin: k230_shell.elf
	@echo "Creating K230 shell binary..."
	$(OBJCOPY) -O binary k230_shell.elf k230_shell.bin
	@echo "K230 shell compiled successfully!"
	@echo "Binary: k230_shell.bin"

k230_shell.elf: $(K230_SHELL_OBJECT) $(K230_UTILS_OBJECT) $(K230_CMD_PARSER_OBJECT) $(K230_CMD_HANDLER_OBJECT) $(K230_PLATFORM_SHELL_OBJECT)
	@echo "Linking K230 shell executable..."
	$(LD) -m elf64lriscv -T src/k230/k230_shell.ld -nostdlib -static -o k230_shell.elf $(K230_SHELL_OBJECT) $(K230_UTILS_OBJECT) $(K230_CMD_PARSER_OBJECT) $(K230_CMD_HANDLER_OBJECT) $(K230_PLATFORM_SHELL_OBJECT)

$(K230_SHELL_OBJECT): $(SHELL_SOURCE)
	@echo "Compiling shell for K230..."
	$(CC) $(K230_CFLAGS) -c $(SHELL_SOURCE) -o $(K230_SHELL_OBJECT)

$(K230_UTILS_OBJECT): $(UTILS_SOURCE)
	@echo "Compiling utils for K230..."
	$(CC) $(K230_CFLAGS) -c $(UTILS_SOURCE) -o $(K230_UTILS_OBJECT)

$(K230_CMD_PARSER_OBJECT): $(CMD_PARSER_SOURCE)
	@echo "Compiling command parser for K230..."
	$(CC) $(K230_CFLAGS) -c $(CMD_PARSER_SOURCE) -o $(K230_CMD_PARSER_OBJECT)

$(K230_CMD_HANDLER_OBJECT): $(CMD_HANDLER_SOURCE)
	@echo "Compiling command handler for K230..."
	$(CC) $(K230_CFLAGS) -c $(CMD_HANDLER_SOURCE) -o $(K230_CMD_HANDLER_OBJECT)

$(K230_PLATFORM_SHELL_OBJECT): $(K230_PLATFORM_SOURCE)
	@echo "Compiling K230 platform for shell..."
	$(CC) $(K230_CFLAGS) -c $(K230_PLATFORM_SOURCE) -o $(K230_PLATFORM_SHELL_OBJECT)


# Shell build (QEMU)
# ------------------------------------------------------------
qemu_shell.bin: qemu_shell.elf
	@echo "Creating QEMU shell binary..."
	$(OBJCOPY) -O binary qemu_shell.elf qemu_shell.bin
	@echo "QEMU shell compiled successfully!"
	@echo "Binary: qemu_shell.bin"

qemu_shell.elf: $(STARTUP_OBJECT) $(QEMU_SHELL_OBJECT) $(QEMU_UTILS_OBJECT) $(QEMU_CMD_PARSER_OBJECT) $(QEMU_CMD_HANDLER_OBJECT) $(QEMU_PLATFORM_SHELL_OBJECT)
	@echo "Linking QEMU shell executable..."
	$(LD) -m elf64lriscv -T src/qemu/qemu.ld -nostdlib -static -o qemu_shell.elf $(STARTUP_OBJECT) $(QEMU_SHELL_OBJECT) $(QEMU_UTILS_OBJECT) $(QEMU_CMD_PARSER_OBJECT) $(QEMU_CMD_HANDLER_OBJECT) $(QEMU_PLATFORM_SHELL_OBJECT)

$(QEMU_SHELL_OBJECT): $(SHELL_SOURCE)
	@echo "Compiling shell for QEMU..."
	$(CC) $(QEMU_CFLAGS) -c $(SHELL_SOURCE) -o $(QEMU_SHELL_OBJECT)

$(QEMU_UTILS_OBJECT): $(UTILS_SOURCE)
	@echo "Compiling utils for QEMU..."
	$(CC) $(QEMU_CFLAGS) -c $(UTILS_SOURCE) -o $(QEMU_UTILS_OBJECT)

$(QEMU_CMD_PARSER_OBJECT): $(CMD_PARSER_SOURCE)
	@echo "Compiling command parser for QEMU..."
	$(CC) $(QEMU_CFLAGS) -c $(CMD_PARSER_SOURCE) -o $(QEMU_CMD_PARSER_OBJECT)

$(QEMU_CMD_HANDLER_OBJECT): $(CMD_HANDLER_SOURCE)
	@echo "Compiling command handler for QEMU..."
	$(CC) $(QEMU_CFLAGS) -c $(CMD_HANDLER_SOURCE) -o $(QEMU_CMD_HANDLER_OBJECT)

$(QEMU_PLATFORM_SHELL_OBJECT): $(QEMU_PLATFORM_SOURCE)
	@echo "Compiling QEMU platform for shell..."
	$(CC) $(QEMU_CFLAGS) -c $(QEMU_PLATFORM_SOURCE) -o $(QEMU_PLATFORM_SHELL_OBJECT)


# Zig targets
# ------------------------------------------------------------
ZIG_SOURCE = src/hello_readaddr.zig
QEMU_ZIG_STARTUP = src/qemu/startup.s
QEMU_ZIG_LINKER = src/qemu/qemu.ld
QEMU_ZIG_PLATFORM = src/qemu/qemu_platform.c

qemu_zig.bin: $(ZIG_SOURCE) $(QEMU_ZIG_STARTUP) $(QEMU_ZIG_LINKER) $(QEMU_ZIG_PLATFORM)
	@echo "Building QEMU Zig executable..."
	$(ZIG) build-exe $(ZIG_SOURCE) $(QEMU_ZIG_STARTUP) \
		-mcmodel=medium \
		-target riscv64-freestanding-none \
		-O ReleaseSmall \
		-fno-strip \
		-T $(QEMU_ZIG_LINKER) \
		-I include \
		--name qemu_zig \
		-cflags -DQEMU_TARGET -- $(QEMU_ZIG_PLATFORM)
	@echo "Creating QEMU Zig binary..."
	$(OBJCOPY) -O binary qemu_zig qemu_zig.bin
	@echo "QEMU Zig version compiled successfully!"
	@echo "Binary: qemu_zig.bin"



# Clean targets
clean:
	@echo "Cleaning up..."
	rm -f $(K230_C_OBJECT) $(QEMU_C_OBJECT) $(K230_PLATFORM_OBJECT) $(QEMU_PLATFORM_OBJECT) $(STARTUP_OBJECT)
	rm -f $(K230_SHELL_OBJECT) $(QEMU_SHELL_OBJECT) $(K230_UTILS_OBJECT) $(QEMU_UTILS_OBJECT)
	rm -f $(K230_CMD_PARSER_OBJECT) $(QEMU_CMD_PARSER_OBJECT) $(K230_CMD_HANDLER_OBJECT) $(QEMU_CMD_HANDLER_OBJECT)
	rm -f $(K230_PLATFORM_SHELL_OBJECT) $(QEMU_PLATFORM_SHELL_OBJECT)
	rm -f k230.elf qemu.elf k230_shell.elf qemu_shell.elf
	rm -f k230.bin qemu.bin k230_shell.bin qemu_shell.bin
	rm -f qemu_zig qemu_zig.bin
	rm -f qemu_zig.o
	@echo "Clean complete!"



# Run QEMU target (M-mode, no OpenSBI)
run_qemu: qemu
	@echo "Running QEMU in M-mode (bare metal, no OpenSBI)..."
	qemu-system-riscv64 -machine virt -cpu rv64 -m 128M -nographic -bios qemu.bin

# Run QEMU Zig target (M-mode, no OpenSBI)
run_qemu_zig: qemu_zig
	@echo "Running QEMU Zig version in M-mode (bare metal, no OpenSBI)..."
	qemu-system-riscv64 -machine virt -cpu rv64 -m 128M -nographic -bios qemu_zig.bin

# Run QEMU shell target (M-mode, no OpenSBI)
run_shell: qemu_shell
	@echo "Running QEMU shell in M-mode (bare metal, no OpenSBI)..."
	qemu-system-riscv64 -machine virt -cpu rv64 -m 128M -nographic -bios qemu_shell.bin



# Help target
help:
	@echo "Available targets:"
	@echo "  run_shell             - Build and run QEMU shell (default, interactive command interface)"
	@echo "  run_qemu              - Build and run QEMU hello_readaddr version"
	@echo "  run_qemu_zig          - Build and run QEMU Zig version"
	@echo "  k230                  - Build K230 hello_readaddr version"
	@echo "  qemu                  - Build QEMU hello_readaddr version"
	@echo "  qemu_shell            - Build QEMU shell version"
	@echo "  k230_shell            - Build K230 shell version"
	@echo "  qemu_zig              - Build QEMU Zig version"
	@echo "  all                   - Build all versions"
	@echo "  clean                 - Clean all build files"
	@echo "  help                  - Show this help message"
	@echo ""
	@echo "Shell Commands (when running shell):"
	@echo "  help                  - List available shell commands"
	@echo "  read <addr> [size]    - Read memory at address (size in words, default 1)"
	@echo "  write <addr> <val>    - Write value to memory address"
	@echo ""

# Phony targets
.PHONY: all k230 qemu qemu_zig k230_shell qemu_shell run_qemu run_qemu_zig run_shell run_k230_shell clean help
