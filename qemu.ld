ENTRY(_start)

MEMORY {
  ram (rwx) : ORIGIN = 0x80200000, LENGTH = 128M
}

SECTIONS {
  .text : {
    startup.o(.text.startup)
    qemu_hello_readaddr_c.o(.text.startup)
    qemu_hello_readaddr_c.o(.text)
    qemu_hello_readaddr_c.o(.rodata*)
    qemu_platform.o(.text)
    qemu_platform.o(.rodata*)
  } > ram
  
  .data : {
    qemu_hello_readaddr_c.o(.data*)
    qemu_platform.o(.data*)
  } > ram
  
  .bss : {
    qemu_hello_readaddr_c.o(.bss*)
    qemu_platform.o(.bss*)
    *(COMMON)
  } > ram
}
