# K230 minimal startup - ONLY clear BSS, nothing else
.section .text.startup
.global _start

_start:
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

