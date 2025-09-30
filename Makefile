# RISC-V Bare Metal Hello World Makefile
# Supports both K230 and QEMU targets

# Toolchain
CC = riscv-none-elf-gcc
AS = riscv-none-elf-as
LD = riscv-none-elf-ld
OBJCOPY = riscv-none-elf-objcopy

# Compiler flags
CFLAGS = -march=rv64gc -mabi=lp64d -mcmodel=medany -fno-common -fno-builtin -fno-stack-protector -Wall -Wextra -O2 -g -Iinclude
ASFLAGS = -march=rv64gc -mabi=lp64d

# Source files
C_SOURCE = src/hello_readaddr.c
K230_PLATFORM_SOURCE = src/k230/k230_platform.c
QEMU_PLATFORM_SOURCE = src/qemu/qemu_platform.c
STARTUP_SOURCE = src/qemu/startup.s

# Object files
C_OBJECT = hello_readaddr_c.o
K230_PLATFORM_OBJECT = k230_platform.o
QEMU_PLATFORM_OBJECT = qemu_platform.o
STARTUP_OBJECT = startup.o

# Default target (run_qemu)
.DEFAULT_GOAL := run_qemu

# K230 target
k230: k230.bin

# QEMU target  
qemu: qemu.bin

# Both targets
all: k230 qemu

# K230 build
k230.bin: k230.elf
	@echo "Creating K230 binary..."
	$(OBJCOPY) -O binary k230.elf k230.bin
	@echo "K230 version compiled successfully!"
	@echo "Binary: k230.bin"

k230.elf: $(C_OBJECT) $(K230_PLATFORM_OBJECT)
	@echo "Linking K230 executable..."
	$(LD) -m elf64lriscv -T src/k230/k230.ld -nostdlib -static -o k230.elf $(C_OBJECT) $(K230_PLATFORM_OBJECT)

# QEMU build
qemu.bin: qemu.elf
	@echo "Creating QEMU binary..."
	$(OBJCOPY) -O binary qemu.elf qemu.bin
	@echo "QEMU version compiled successfully!"
	@echo "Binary: qemu.bin"

qemu.elf: $(STARTUP_OBJECT) qemu_hello_readaddr_c.o $(QEMU_PLATFORM_OBJECT)
	@echo "Linking QEMU executable..."
	$(LD) -m elf64lriscv -T src/qemu/qemu.ld -nostdlib -static -o qemu.elf $(STARTUP_OBJECT) qemu_hello_readaddr_c.o $(QEMU_PLATFORM_OBJECT)

# Object file compilation
$(C_OBJECT): $(C_SOURCE)
	@echo "Compiling C source..."
	$(CC) $(CFLAGS) -c $(C_SOURCE) -o $(C_OBJECT)

# QEMU-specific C object (with QEMU_TARGET defined)
qemu_hello_readaddr_c.o: $(C_SOURCE)
	@echo "Compiling C source for QEMU..."
	$(CC) $(CFLAGS) -DQEMU_TARGET -c $(C_SOURCE) -o qemu_hello_readaddr_c.o

$(K230_PLATFORM_OBJECT): $(K230_PLATFORM_SOURCE)
	@echo "Compiling K230 platform source..."
	$(CC) $(CFLAGS) -c $(K230_PLATFORM_SOURCE) -o $(K230_PLATFORM_OBJECT)

$(QEMU_PLATFORM_OBJECT): $(QEMU_PLATFORM_SOURCE)
	@echo "Compiling QEMU platform source..."
	$(CC) $(CFLAGS) -DQEMU_TARGET -c $(QEMU_PLATFORM_SOURCE) -o $(QEMU_PLATFORM_OBJECT)

$(STARTUP_OBJECT): $(STARTUP_SOURCE)
	@echo "Assembling startup code..."
	$(AS) $(ASFLAGS) -c $(STARTUP_SOURCE) -o $(STARTUP_OBJECT)

# Clean targets
clean:
	@echo "Cleaning up..."
	rm -f $(C_OBJECT) qemu_hello_readaddr_c.o $(K230_PLATFORM_OBJECT) $(QEMU_PLATFORM_OBJECT) $(STARTUP_OBJECT)
	rm -f k230.elf qemu.elf
	rm -f k230.bin qemu.bin
	@echo "Clean complete!"

# Run QEMU target
run_qemu: qemu
	@echo "Running QEMU..."
	qemu-system-riscv64 -machine virt -cpu rv64 -m 128M -nographic -kernel qemu.bin

# Help target
help:
	@echo "Available targets:"
	@echo "  run_qemu   - Build and run QEMU version (default)"
	@echo "  k230       - Build K230 version"
	@echo "  qemu       - Build QEMU version"
	@echo "  all        - Build both versions"
	@echo "  clean      - Clean all build files"
	@echo "  help       - Show this help message"
	@echo ""
	@echo "Examples:"
	@echo "  make       - Build and run QEMU version (default)"
	@echo "  make k230  - Build K230 version"
	@echo "  make qemu  - Build QEMU version"
	@echo "  make all   - Build both versions"

# Phony targets
.PHONY: all k230 qemu run_qemu clean help
