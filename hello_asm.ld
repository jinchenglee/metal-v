MEMORY {
  dram_space (rwx) : ORIGIN = 0x5000000, LENGTH = 1024
}

SECTIONS {
  .text : {
    #hello.o(.text.bios)
    hello_readaddr.o(.text.bios)
  } > dram_space
}
