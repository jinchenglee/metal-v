# Metal-V Makefile
# RISC-V Bare Metal Interactive Shell (Zig)

# Toolchain
OBJCOPY = riscv-none-elf-objcopy
ZIG = zig

# Source files
ZIG_SHELL_SOURCE = src/shell.zig
ZIG_SHELL_MODULES = src/utils.zig src/cmd_parser.zig src/cmd_handler.zig
QEMU_PLATFORM_SOURCE = src/qemu/qemu_platform.c
K230_PLATFORM_SOURCE = src/k230/k230_platform.c
QEMU_STARTUP = src/qemu/startup.s
K230_STARTUP = src/k230/k230_startup.s
QEMU_LINKER = src/qemu/qemu.ld
K230_LINKER = src/k230/k230.ld

# Default target
.DEFAULT_GOAL := run_qemu

# Build targets
qemu: qemu_shell.bin
k230: k230_shell.bin
all: qemu k230

# QEMU Zig Shell
qemu_shell.bin: $(ZIG_SHELL_SOURCE) $(ZIG_SHELL_MODULES) $(QEMU_STARTUP) $(QEMU_LINKER) $(QEMU_PLATFORM_SOURCE)
	@echo "Building QEMU shell (Zig + C platform)..."
	$(ZIG) build-exe $(ZIG_SHELL_SOURCE) $(QEMU_STARTUP) \
		-mcmodel=medium \
		-target riscv64-freestanding-none \
		-O ReleaseSmall \
		-fno-strip \
		-T $(QEMU_LINKER) \
		-I include \
		--name qemu_shell \
		-cflags -DQEMU_TARGET -- $(QEMU_PLATFORM_SOURCE)
	@echo "Creating QEMU binary..."
	$(OBJCOPY) -O binary qemu_shell qemu_shell.bin
	@echo "✓ QEMU shell built successfully: qemu_shell.bin"

# K230 Zig Shell - MUST clear BSS for global variables
k230_shell.bin: $(ZIG_SHELL_SOURCE) $(ZIG_SHELL_MODULES) $(K230_LINKER) $(K230_PLATFORM_SOURCE) $(K230_STARTUP)
	@echo "Building K230 shell (Zig + C platform with BSS clearing)..."
	$(ZIG) build-exe $(ZIG_SHELL_SOURCE) $(K230_STARTUP) \
		-mcmodel=medium \
		-target riscv64-freestanding-none \
		-O ReleaseSmall \
		-fno-strip \
		-T $(K230_LINKER) \
		-I include \
		--name k230_shell \
		-DK230_PLATFORM \
		-cflags -DK230_TARGET -DK230_PLATFORM -- $(K230_PLATFORM_SOURCE)
	@echo "Creating K230 binary..."
	$(OBJCOPY) -O binary k230_shell k230_shell.bin
	@echo "✓ K230 shell built successfully: k230_shell.bin"

# Run targets
run_qemu: qemu
	@echo "Running Metal-V shell in QEMU..."
	@echo "Press Ctrl-A then X to exit"
	@echo ""
	qemu-system-riscv64 -machine virt -cpu rv64 -m 128M -nographic -bios qemu_shell.bin


# Clean target
clean:
	@echo "Cleaning build artifacts..."
	rm -f qemu_shell qemu_shell.bin qemu_shell.o
	rm -f k230_shell k230_shell.bin k230_shell.o
	@echo "✓ Clean complete"

# Help target
help:
	@echo "Metal-V Interactive Shell - Build Targets"
	@echo "=========================================="
	@echo ""
	@echo "Run targets:"
	@echo "  make run_qemu    - Build and run in QEMU (default)"
	@echo ""
	@echo "Build targets:"
	@echo "  make qemu        - Build QEMU version binary"
	@echo "  make k230        - Build K230 version binary"
	@echo "  make all         - Build both versions"
	@echo ""
	@echo "Other:"
	@echo "  make clean       - Remove build artifacts"
	@echo "  make help        - Show this help"
	@echo ""

# Phony targets
.PHONY: all qemu k230 run_qemu run_k230 clean help
