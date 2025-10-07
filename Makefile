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
K230_PLATFORM_SOURCE = src/k230/k230_platform.c
QEMU_PLATFORM_SOURCE = src/qemu/qemu_platform.c
STARTUP_SOURCE = src/qemu/startup.s

# Object files
K230_C_OBJECT = k230_hello_readaddr_c.o
QEMU_C_OBJECT = qemu_hello_readaddr_c.o
K230_PLATFORM_OBJECT = k230_platform.o
QEMU_PLATFORM_OBJECT = qemu_platform.o
STARTUP_OBJECT = startup.o



# Default target (run_qemu)
.DEFAULT_GOAL := run_qemu

# K230 target
k230: k230.bin

# QEMU target  
qemu: qemu.bin

# QEMU Zig target
qemu_zig: qemu_zig.bin

# Both all targets
all: k230 qemu qemu_zig



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
	rm -f k230.elf qemu.elf
	rm -f k230.bin qemu.bin
	rm -f qemu_zig qemu_zig.bin
	rm -f qemu_zig.o
	@echo "Clean complete!"



# Run QEMU target (S-mode)
run_qemu: qemu
	@echo "Running QEMU in S-mode..."
	qemu-system-riscv64 -machine virt -cpu rv64 -m 128M -nographic -kernel qemu.bin

# Run QEMU Zig target (S-mode)
run_qemu_zig: qemu_zig
	@echo "Running QEMU Zig version in S-mode..."
	qemu-system-riscv64 -machine virt -cpu rv64 -m 128M -nographic -kernel qemu_zig.bin



# Help target
help:
	@echo "Available targets:"
	@echo "  run_qemu              - Build and run QEMU version in S-mode (default)"
	@echo "  run_qemu_zig          - Build and run QEMU Zig version in S-mode"
	@echo "  k230                  - Build K230 version"
	@echo "  qemu                  - Build QEMU version"
	@echo "  qemu_zig              - Build QEMU Zig version"
	@echo "  all                   - Build all versions"
	@echo "  clean                 - Clean all build files"
	@echo "  help                  - Show this help message"
	@echo ""

# Phony targets
.PHONY: all k230 qemu qemu_zig run_qemu run_qemu_zig clean help
