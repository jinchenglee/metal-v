ENTRY(_start)  /* _start clears BSS then jumps to main */

MEMORY {
  dram_space (rwx) : ORIGIN = 0x2000000, LENGTH = 64K
}

SECTIONS {
  .text : {
    *(.text.startup)
    *(.text)
    *(.text.*)
    *(.rodata*)
  } > dram_space
  
  .data : {
    *(.data*)
  } > dram_space
  
  .bss : {
    __bss_start = .;
    *(.bss*)
    *(COMMON)
    __bss_end = .;
    . = ALIGN(16);
    _stack_bottom = .;
    . = . + 0x2000;  /* 8KB stack */
    _stack_top = .;
  } > dram_space
}

