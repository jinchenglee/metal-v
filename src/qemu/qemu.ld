ENTRY(_start)

MEMORY {
  ram (rwx) : ORIGIN = 0x80000000, LENGTH = 128M
}

SECTIONS {
  .text : {
    *(.text.startup)  /* Startup code must come first */
    *(.text)
    *(.text.*)
    *(.rodata)
    *(.rodata.*)
  } > ram
  
  .data : {
    *(.data)
    *(.data.*)
  } > ram
  
  .bss : {
    *(.bss)
    *(.bss.*)
    *(COMMON)
  } > ram
}

