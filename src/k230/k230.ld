ENTRY(main)

MEMORY {
  dram_space (rwx) : ORIGIN = 0x2000000, LENGTH = 64K
}

SECTIONS {
  .text : {
    k230_hello_readaddr_c.o(.text.startup)
    k230_hello_readaddr_c.o(.text)
    k230_hello_readaddr_c.o(.rodata*)
    k230_platform.o(.text)
    k230_platform.o(.rodata*)
  } > dram_space
  
  .data : {
    k230_hello_readaddr_c.o(.data*)
    k230_platform.o(.data*)
  } > dram_space
  
  .bss : {
    k230_hello_readaddr_c.o(.bss*)
    k230_platform.o(.bss*)
    *(COMMON)
  } > dram_space
}
