# Basic 4 function calculator implemented in MIPS assembly

# preserves a0, v0
.macro print_str %str
    .data
    print_str_message: .asciiz %str
    .text
    push a0
    push v0
    la a0, print_str_message
    li v0, 4
    syscall
    pop v0
    pop a0
.end_macro
    .data
    display: .word 0
    operation: .word 0
    .text

.globl main
main:
    print_str "Hello! Welcome!\n"
    
    # while(true) {
_loop:
    # print the display variable 
    lw a0, display
    li v0, 1
    syscall
    
    # print the prompt string
    print_str "\nOperation (=,+,-,*,/,c,q): "
    
    # operation = read_char()
    li v0, 12
    syscall
    sw v0, operation
    
    # print newline
    print_str "\n"
    
    # switch(operation) {
    lw  t0, operation 
    beq t0, 'q', _quit
    beq t0, 'c', _clear
    beq t0, '+', _get_operand
    beq t0, '-', _get_operand
    beq t0, '*', _get_operand
    beq t0, '/', _get_operand
    beq t0, '=', _get_operand
    j   _default

    # case 'q':
    _quit:
	li v0, 10
	syscall
	j _break

    # case 'c'
    _clear:
	sw zero, display
	j _break
	
    # case for '+', '-', '*', '/' and '='			
    _get_operand:
    
    	# read integer value
    	print_str "Value: "
    	li v0, 5
    	syscall
    	
    	# switch(operation) {
    	lw t0, operation
    	beq t0, '+', _addition
    	beq t0, '-', _subtraction
    	beq t0, '*', _multiplication
    	beq t0, '/', _division
    	beq t0, '=', _equals
    	j    _default2 
    	
    	# case addition
    	_addition:
    	    lw a3, display
    	    add a0, a3, v0
    	    sw a0, display
    	    j _break2
    	    
    	# case subtraction
    	_subtraction:
    	    lw a3, display
    	    sub a0, a3, v0
    	    sw a0, display
    	    j _break2
    	
    	# case multiplication
    	_multiplication:
    	    lw a3, display
    	    mul a0, a3, v0
    	    sw a0, display
    	    j _break2
    	
    	# case division
    	_division:
    	    lw a3, display
    	    div a0, a3, v0
    	    sw a0, display
    	    j _break2
    	    
    	# case equals
    	_equals:
    	    sw v0, display
    	    j _break2
    	
    	#default
    	_default2:
    	    print_str "Error\n"
    	
    	_break2:
    	    # }
    	    j _loop
    	    
    	j _break

    # default:
    _default:
        print_str "Huh?\n"
        # no j _break needed cause it's the next line.
_break:
    # }
    j _loop

    
	
