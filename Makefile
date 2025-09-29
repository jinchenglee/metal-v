# RISC-V Bare Metal Hello World Makefile
# Supports both Assembly and C versions

# Toolchain
CC = riscv-none-elf-gcc
AS = riscv-none-elf-as
LD = riscv-none-elf-ld
OBJCOPY = riscv-none-elf-objcopy

# Compiler flags
CFLAGS = -march=rv64gc -mabi=lp64d -mcmodel=medany -fno-common -fno-builtin -fno-stack-protector -Wall -Wextra -O2 -g
ASFLAGS = -march=rv64gc -mabi=lp64d
LDFLAGS_C = -m elf64lriscv -T hello.ld -nostdlib -static
LDFLAGS_ASM = -m elf64lriscv -T hello_asm.ld -nostdlib -static

# Source files
ASM_SOURCE = hello_readaddr.s
C_SOURCE = hello_readaddr.c

# Object files
ASM_OBJECT = hello_readaddr.o
C_OBJECT = hello_readaddr_c.o

# Executable files
ASM_EXEC = hello
C_EXEC = hello_c

# Binary files
ASM_BINARY = hello.bin
C_BINARY = hello_c.bin

# Default target (C version)
.DEFAULT_GOAL := c

# C version (default)
c: $(C_BINARY)

# Assembly version
asm: $(ASM_BINARY)

# Both versions
all: asm c

# C version build
$(C_BINARY): $(C_EXEC)
	@echo "Creating C binary..."
	$(OBJCOPY) -O binary $(C_EXEC) $(C_BINARY)
	@echo "C version compiled successfully!"
	@echo "Binary: $(C_BINARY)"

$(C_EXEC): $(C_OBJECT)
	@echo "Linking C executable..."
	$(LD) $(LDFLAGS_C) -o $(C_EXEC) $(C_OBJECT)

$(C_OBJECT): $(C_SOURCE)
	@echo "Compiling C source..."
	$(CC) $(CFLAGS) -c $(C_SOURCE) -o $(C_OBJECT)

# Assembly version build
$(ASM_BINARY): $(ASM_EXEC)
	@echo "Creating assembly binary..."
	$(OBJCOPY) -O binary $(ASM_EXEC) $(ASM_BINARY)
	@echo "Assembly version compiled successfully!"
	@echo "Binary: $(ASM_BINARY)"

$(ASM_EXEC): $(ASM_OBJECT)
	@echo "Linking assembly executable..."
	$(LD) $(LDFLAGS_ASM) -o $(ASM_EXEC) $(ASM_OBJECT)

$(ASM_OBJECT): $(ASM_SOURCE)
	@echo "Compiling assembly source..."
	$(AS) $(ASFLAGS) -c $(ASM_SOURCE) -o $(ASM_OBJECT)

# Clean targets
clean:
	@echo "Cleaning up..."
	rm -f $(ASM_OBJECT) $(C_OBJECT)
	rm -f $(ASM_EXEC) $(C_EXEC)
	rm -f $(ASM_BINARY) $(C_BINARY)
	@echo "Clean complete!"

# Clean only C files
clean-c:
	@echo "Cleaning C files..."
	rm -f $(C_OBJECT) $(C_EXEC) $(C_BINARY)
	@echo "C clean complete!"

# Clean only assembly files
clean-asm:
	@echo "Cleaning assembly files..."
	rm -f $(ASM_OBJECT) $(ASM_EXEC) $(ASM_BINARY)
	@echo "Assembly clean complete!"

# Rebuild targets
rebuild: clean all

rebuild-c: clean-c c

rebuild-asm: clean-asm asm

# Help target
help:
	@echo "Available targets:"
	@echo "  c          - Build C version (default)"
	@echo "  asm        - Build assembly version"
	@echo "  all        - Build both versions"
	@echo "  clean      - Clean all build files"
	@echo "  clean-c    - Clean only C build files"
	@echo "  clean-asm  - Clean only assembly build files"
	@echo "  rebuild    - Clean and build both versions"
	@echo "  rebuild-c  - Clean and build C version"
	@echo "  rebuild-asm- Clean and build assembly version"
	@echo "  help       - Show this help message"
	@echo ""
	@echo "Examples:"
	@echo "  make       - Build C version (default)"
	@echo "  make c     - Build C version"
	@echo "  make asm   - Build assembly version"
	@echo "  make all   - Build both versions"

# Phony targets
.PHONY: all c asm clean clean-c clean-asm rebuild rebuild-c rebuild-asm help
