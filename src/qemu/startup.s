# Startup code for bare metal RISC-V in M-mode
.section .text.startup
.global _start

_start:
    # Disable interrupts during setup
    csrw mie, zero
    
    # Set up trap vector (direct mode)
    la t0, trap_handler
    csrw mtvec, t0
    
    # Initialize mstatus
    # Set MPP (Machine Previous Privilege) to M-mode (11 in bits 12:11)
    li t0, 0x1800  # MPP = 11 (M-mode)
    csrw mstatus, t0
    
    # Initialize stack pointer to a safe location
    # For QEMU M-mode: RAM starts at 0x80000000, size is 128MB
    # Set SP to a reasonable location within the RAM
    li sp, 0x80000000 + 0x100000  # 0x80000000 + 1MB (safe location)
    
    # Clear BSS section (if needed)
    # This is important for uninitialized global variables
    
    # Jump to main function
    call main
    
    # If main returns (shouldn't happen), loop forever
loop:
    wfi  # Wait for interrupt (lower power consumption)
    j loop

# Simple trap handler for M-mode
.align 4
trap_handler:
    # Save context (minimal - just return for now)
    # In a real application, you'd want to save registers and handle traps
    mret  # Return from trap
