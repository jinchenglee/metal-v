ENTRY(main)

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
    *(.bss*)
    *(COMMON)
  } > dram_space
}

