.global _start
.section .text.bios

# UART register offsets (with reg-shift=2, registers are 4 bytes apart)
#.equ UART_BASE, 0x91400000 # UART0=ttyACM0
.equ UART_BASE, 0x91403000 # UART3=ttyACM1
.equ UART_RBR,  0x00    # Receiver Buffer Register (read)
.equ UART_THR,  0x00    # Transmit Holding Register (write) - same as RBR
.equ UART_IER,  0x04    # Interrupt Enable Register
.equ UART_FCR,  0x08    # FIFO Control Register
.equ UART_LCR,  0x0C    # Line Control Register
.equ UART_MCR,  0x10    # Modem Control Register
.equ UART_LSR,  0x14    # Line Status Register
.equ UART_MSR,  0x18    # Modem Status Register

# UART register values
.equ UART_LCR_8N1, 0x03     # 8 data bits, no parity, 1 stop bit
.equ UART_LCR_DLAB, 0x80    # Divisor Latch Access Bit
.equ UART_LSR_THRE, 0x20    # Transmit Holding Register Empty
.equ UART_FCR_ENABLE, 0x07  # Enable FIFO, clear TX/RX
.equ UART_MCR_DTR_RTS, 0x03 # DTR and RTS

# Calculate baud rate divisor for 115200 baud with 50MHz clock
# divisor = clock / (16 * baudrate) = 50000000 / (16 * 115200) ≈ 27
.equ BAUD_DIVISOR, 27

_start:
    # Initialize UART
    call uart_init
    
hello_loop:    # Print "hello"
    li a0, 'h'
    call uart_putc
    li a0, 'e'
    call uart_putc
    li a0, 'l'
    call uart_putc
    li a0, 'l'
    call uart_putc
    li a0, 'o'
    call uart_putc
    li a0, '\n'
    call uart_putc

    # Introduce a delay using a busy-wait loop
    li t0, 1000000  # Set loop counter (adjust this value for a longer/shorter delay)
delay_loop:
    addi t0, t0, -1   # Decrement the counter
    bnez t0, delay_loop # Branch back to delay_loop if counter is not zero

    j hello_loop      # Jump back to the start of the printing loop

loop:
    j loop

# UART initialization function
uart_init:
    # Save registers
    addi sp, sp, -16
    sw ra, 12(sp)
    sw a0, 8(sp)
    sw a1, 4(sp)
    sw a2, 0(sp)
    
    # Wait for transmitter to be empty
    li a0, UART_BASE
    addi a0, a0, UART_LSR
1:  lw a1, 0(a0)
    andi a1, a1, 0x40  # Check TEMT bit
    beqz a1, 1b
    
    # Set baud rate divisor
    li a0, UART_BASE
    addi a0, a0, UART_LCR
    li a1, UART_LCR_DLAB | UART_LCR_8N1
    sw a1, 0(a0)
    
    li a0, UART_BASE
    addi a0, a0, UART_THR  # DLL register
    li a1, BAUD_DIVISOR & 0xFF
    sw a1, 0(a0)
    
    li a0, UART_BASE
    addi a0, a0, UART_IER  # DLM register
    li a1, (BAUD_DIVISOR >> 8) & 0xFF
    sw a1, 0(a0)
    
    # Set line control (8N1, disable DLAB)
    li a0, UART_BASE
    addi a0, a0, UART_LCR
    li a1, UART_LCR_8N1
    sw a1, 0(a0)
    
    # Enable FIFO
    li a0, UART_BASE
    addi a0, a0, UART_FCR
    li a1, UART_FCR_ENABLE
    sw a1, 0(a0)
    
    # Set modem control
    li a0, UART_BASE
    addi a0, a0, UART_MCR
    li a1, UART_MCR_DTR_RTS
    sw a1, 0(a0)
    
    # Restore registers
    lw a2, 0(sp)
    lw a1, 4(sp)
    lw a0, 8(sp)
    lw ra, 12(sp)
    addi sp, sp, 16
    ret

# UART put character function
uart_putc:
    # Save registers
    addi sp, sp, -8
    sw ra, 4(sp)
    sw a1, 0(sp)
    
    # Wait for transmit buffer to be empty
    li a1, UART_BASE
    addi a1, a1, UART_LSR
1:  lw t0, 0(a1)
    andi t0, t0, UART_LSR_THRE
    beqz t0, 1b
    
    # Write character to transmit buffer
    li a1, UART_BASE
    addi a1, a1, UART_THR
    sw a0, 0(a1)
    
    # Restore registers
    lw a1, 0(sp)
    lw ra, 4(sp)
    addi sp, sp, 8
    ret
