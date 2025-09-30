# Startup code for bare metal RISC-V
.section .text.startup
.global _start

_start:
    # Initialize stack pointer to a safe location
    # For QEMU: RAM starts at 0x80200000, size is 128MB
    # Set SP to a reasonable location within the RAM
    li sp, 0x80200000 + 0x100000  # 0x80200000 + 1MB (safe location)
    
    # Jump to main function
    call main
    
    # If main returns (shouldn't happen), loop forever
loop:
    j loop
