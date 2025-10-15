# K230 minimal startup with C908 CPU initialization
.section .text.startup
.global _start

_start:
    # Setup stack pointer first
    la sp, _stack_top
    
    # Initialize C908 CPU-specific CSRs (from K230 SDK)
    # MHCR (0x7c1) - Hardware Control Register
    li t0, 0x11ff
    csrw 0x7c1, t0
    
    # MCOR (0x7c2) - Cache Operation Register  
    li t0, 0x70013
    csrw 0x7c2, t0
    
    # MCCR2 (0x7c3) - Cache Configuration Register 2
    li t0, 0xe0410009
    csrw 0x7c3, t0
    
    # MHINT (0x7c5) - Hardware Hint Register
    li t0, 0x16e30c
    csrw 0x7c5, t0
    
    # Enable vector extension in mstatus
    # Set VS (Vector Status) to Initial (01 in bits 10:9)
    li t0, 0x0600  # VS = 01 (Initial state - enables vector)
    csrs mstatus, t0
    
    # Setup trap vector
    la t0, trap_entry
    csrw mtvec, t0
    
    # Clear BSS section - critical for global variables!
    la t0, __bss_start
    la t1, __bss_end
clear_bss:
    beq t0, t1, bss_done
    sd zero, 0(t0)
    addi t0, t0, 8
    j clear_bss
bss_done:
    
    # Jump to main (don't use call - just jump directly)
    j main

# Minimal trap handler
.align 4
trap_entry:
    # For now, just return - proper handler can be added later
    mret

