ENTRY(main)

MEMORY {
  dram_space (rwx) : ORIGIN = 0x2000000, LENGTH = 64K
}

SECTIONS {
  .text : {
    hello_readaddr_c.o(.text.startup)
    hello_readaddr_c.o(.text)
    hello_readaddr_c.o(.rodata*)
  } > dram_space
}
