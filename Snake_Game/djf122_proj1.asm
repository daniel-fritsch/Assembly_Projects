# Daniel Fritsch
# djf122

# Cardinal directions.
.eqv DIR_N 0
.eqv DIR_E 1
.eqv DIR_S 2
.eqv DIR_W 3

# Game grid dimensions.
.eqv GRID_CELL_SIZE 4 # pixels
.eqv GRID_WIDTH  16 # cells
.eqv GRID_HEIGHT 14 # cells
.eqv GRID_CELLS 224 #= GRID_WIDTH * GRID_HEIGHT

# How long the snake can possibly be.
.eqv SNAKE_MAX_LEN GRID_CELLS # segments

# How many frames (1/60th of a second) between snake movements.
.eqv SNAKE_MOVE_DELAY 12 # frames

# How many apples the snake needs to eat to win the game.
.eqv APPLES_NEEDED 20

# ------------------------------------------------------------------------------------------------
.data

# set to 1 when the player loses the game (running into the walls/other part of the snake).
lost_game: .word 0

# the direction the snake is facing (one of the DIR_ constants).
snake_dir: .word DIR_N

# how long the snake is (how many segments).
snake_len: .word 2

# parallel arrays of segment coordinates. index 0 is the head.
snake_x: .byte 0:SNAKE_MAX_LEN
snake_y: .byte 0:SNAKE_MAX_LEN

# used to keep track of time until the next time the snake can move.
snake_move_timer: .word 0

# 1 if the snake changed direction since the last time it moved.
snake_dir_changed: .word 0

# how many apples have been eaten.
apples_eaten: .word 0

# coordinates of the (one) apple in the world.
apple_x: .word 3
apple_y: .word 2

# A pair of arrays, indexed by direction, to turn a direction into x/y deltas.
# e.g. direction_delta_x[DIR_E] is 1, because moving east increments X by 1.
#                         N  E  S  W
direction_delta_x: .byte  0  1  0 -1
direction_delta_y: .byte -1  0  1  0

.text

# ------------------------------------------------------------------------------------------------

# these .includes are here to make these big arrays come *after* the interesting
# variables in memory. it makes things easier to debug.
.include "display_2211_0822.asm"
.include "textures.asm"

# ------------------------------------------------------------------------------------------------

.text
.globl main
main:
	jal setup_snake
	jal wait_for_game_start

	# main game loop
	_loop:
		jal check_input
		jal update_snake
		jal draw_all
		jal display_update_and_clear
		jal wait_for_next_frame
	jal check_game_over
	beq v0, 0, _loop

	# when the game is over, show a message
	jal show_game_over_message
syscall_exit

# ------------------------------------------------------------------------------------------------
# Misc game logic
# ------------------------------------------------------------------------------------------------

# ------------------------------------------------------------------------------------------------

# waits for the user to press a key to start the game (so the snake doesn't go barreling
# into the wall while the user ineffectually flails attempting to click the display (ask
# me how I know that that happens))
wait_for_game_start:
enter
	_loop:
		jal draw_all
		jal display_update_and_clear
		jal wait_for_next_frame
	jal input_get_keys_pressed
	beq v0, 0, _loop
leave

# ------------------------------------------------------------------------------------------------

# returns a boolean (1/0) of whether the game is over. 1 means it is.
check_game_over:
enter
	li v0, 0

	# if they've eaten enough apples, the game is over.
	lw t0, apples_eaten
	blt t0, APPLES_NEEDED, _endif
		li v0, 1
		j _return
	_endif:

	# if they lost the game, the game is over.
	lw t0, lost_game
	beq t0, 0, _return
		li v0, 1
_return:
leave

# ------------------------------------------------------------------------------------------------

show_game_over_message:
enter
	# first clear the display
	jal display_update_and_clear

	# then show different things depending on if they won or lost
	lw t0, lost_game
	bne t0, 0, _lost
		# they finished successfully!
		li   a0, 7
		li   a1, 25
		lstr a2, "yay! you"
		li   a3, COLOR_GREEN
		jal  display_draw_colored_text

		li   a0, 12
		li   a1, 31
		lstr a2, "did it!"
		li   a3, COLOR_GREEN
		jal  display_draw_colored_text
	j _endif
	_lost:
		# they... didn't...
		li   a0, 5
		li   a1, 30
		lstr a2, "oh no :("
		li   a3, COLOR_RED
		jal  display_draw_colored_text
	_endif:

	jal display_update_and_clear
leave

# ------------------------------------------------------------------------------------------------
# Snake
# ------------------------------------------------------------------------------------------------

# sets up the snake so the first two segments are in the middle of the screen.
setup_snake:
enter
	# snake head in the middle, tail below it
	li  t0, GRID_WIDTH
	div t0, t0, 2
	sb  t0, snake_x
	sb  t0, snake_x + 1

	li  t0, GRID_HEIGHT
	div t0, t0, 2
	sb  t0, snake_y
	add t0, t0, 1
	sb  t0, snake_y + 1
leave

# ------------------------------------------------------------------------------------------------

# checks for the arrow keys to change the snake's direction.
check_input:
enter
	lw t0, snake_dir_changed
	bne t0, zero, _break


	# call input_get_keys_held and store value int t0
	jal input_get_keys_held
	move t0, v0
	
	# load key values into temp registers
	li t1, KEY_U
	li t2, KEY_D
	li t3, KEY_R
	li t4, KEY_L
	
	# switch case statement
	beq t0, t1, _north
	beq t0, t2, _south
	beq t0, t3, _east
	beq t0, t4, _west
	j _break
	
	_north:
		# if snake_dir is currently DIR_N, branch to break
		lw t0, snake_dir
		li t1, DIR_N
		beq t0, t1, _break
		
		# if snake_dir is currently DIR_S, branch to break
		li t2, DIR_S
		beq t0, t2, _break
		
		# set snake to DIR_N
		sw t1, snake_dir
		li t3, 1
		sw t3, snake_dir_changed
		
		j _break
		
	_south:
		# if snake_dir is currently DIR_S, branch to break
		lw t0, snake_dir
		li t1, DIR_S
		beq t0, t1, _break
		
		# if snake_dir is currently DIR_N, branch to break
		li t2, DIR_N
		beq t0, t2, _break
		
		# set snake to DIR_S
		sw t1, snake_dir
		li t3, 1
		sw t3, snake_dir_changed
		
		j _break
		
	_east:
		# if snake_dir is currently DIR_E, branch to break
		lw t0, snake_dir
		li t1, DIR_E
		beq t0, t1, _break
		
		# if snake_dir is currently DIR_W, branch to break
		li t2, DIR_W
		beq t0, t2, _break
		
		# set snake_dir to DIR_E
		sw t1, snake_dir
		li t3, 1
		sw t3, snake_dir_changed
		
		j _break
	
	_west:
		# if snake_dir is currently DIR_W, branch to break
		lw t0, snake_dir
		li t1, DIR_W
		beq t0, t1, _break
		
		# if snake_dir is currently DIR_E, branch to break
		li t2, DIR_E
		beq t0, t2, _break
		
		# set snake_dir to DIR_W
		sw t1, snake_dir
		li t3, 1
		sw t3, snake_dir_changed
		
	
	_break:
leave

# ------------------------------------------------------------------------------------------------

# update the snake.
update_snake:
enter
	lw t0, snake_move_timer
	# if (snake_move_timer != 0)
	bne t0, zero, _decrement
	#else
	#set snake_move_timer to SNAKE_MOVE_DELAY
	li t0, SNAKE_MOVE_DELAY
	sw t0, snake_move_timer
	
	#set snake_dir_changed to 0
	li t1, 0
	sw t1, snake_dir_changed
	
	# call move_snake
	jal move_snake
	j _skip # skip over the if condition
	
	# if
	_decrement:
		sub t0, t0, 1
		sw t0, snake_move_timer
	
	# if statement of loop exit
	_skip:
leave

# ------------------------------------------------------------------------------------------------

move_snake:
enter s0, s1
	# call compute_next_snake_pos and put its return values in s0 and s1
	jal compute_next_snake_pos
	move s0, v0
	move s1, v1
	
	# if conditions
	blt s0, zero, _game_over
	bge s0, GRID_WIDTH, _game_over
	blt s1, zero, _game_over
	bge s1, GRID_HEIGHT, _game_over
	
	# check if snake is going to run into itself
	move a0, s0
	move a1, s1
	jal is_point_on_snake
	beq v0, 1, _game_over
	
	# if coordinates dont match apple's, go to move forward
	lw t2, apple_x
	lw t3, apple_y
	bne s0, t2, _move_forward
	bne s1, t3, _move_forward
	
	# eat apple condition
	_eat_apple:
		# increment apples_eaten
		lw t0, apples_eaten
		add t0, t0, 1
		sw t0, apples_eaten
		
		# increment snake_len
		lw t0, snake_len
		add t0, t0, 1
		sw t0, snake_len
		
		# call shift_snake_segments and set snake_x and snake_y
		jal shift_snake_segments
		sb s0, snake_x
		sb s1, snake_y
		
		# call move apple
		jal move_apple
		
		j _break
	
	# move forward condition
	_move_forward:
		# call shift_snake_segments and set snake_x and snake_y
		jal shift_snake_segments
		sb s0, snake_x
		sb s1, snake_y
		j _break
	
	# game over condition
	_game_over:
		# set lost_game to 1
		li t0, 1
		sw t0, lost_game
	
	# break condition
	_break:
	
leave s0, s1

# ------------------------------------------------------------------------------------------------

shift_snake_segments:
enter
	# load snake_len and store it in t0, subtract 1 from the value
	lw t0, snake_len
	sub t0, t0, 1
	
	# for(int i = snake_len - 1; i >= 1; i--)
	_loop:
		# if t0 >= 1, go to next
		beq t0, zero, _next
		
		# load snake_x and snake_y i-1 values
		sub t3, t0, 1
		lb t1, snake_x(t3)
		lb t2, snake_y(t3)
		
		# set snake_x[i] and snake_y[i] values to snake_x[i-1] and snake_y[i-1]
		sb t1, snake_x(t0)
		sb t2, snake_y(t0)
		
		# decrement i
		sub t0, t0, 1
		
		j _loop
	# end of loop condition	
	_next:
leave

# ------------------------------------------------------------------------------------------------

move_apple:
enter
	# do while loop
	_loop:
		# generate random x coordinate
		li a0, 0
		li a1, GRID_WIDTH
		li v0, 42
		syscall
		move t0, v0
		
		# generate random y coordinate
		li a0, 0
		li a1, GRID_HEIGHT
		li v0, 42
		syscall
		move t1, v0
		
		# set up arguments for function
		move a0, t0
		move a1, t1
		
		# call is_point_on_snake
		jal is_point_on_snake
		
		# loop if returned value is 1
		beq v0, 1, _loop
	
	sw a0, apple_x
	sw a1, apple_y
		
leave

# ------------------------------------------------------------------------------------------------

compute_next_snake_pos:
enter
	# t9 = direction
	lw t9, snake_dir

	# v0 = direction_delta_x[snake_dir]
	lb v0, snake_x
	lb t0, direction_delta_x(t9)
	add v0, v0, t0

	# v1 = direction_delta_y[snake_dir]
	lb v1, snake_y
	lb t0, direction_delta_y(t9)
	add v1, v1, t0
leave

# ------------------------------------------------------------------------------------------------

# takes a coordinate (x, y) in a0, a1.
# returns a boolean (1/0) saying whether that coordinate is part of the snake or not.
is_point_on_snake:
enter
	# for i = 0 to snake_len
	li t9, 0
	_loop:
		lb t0, snake_x(t9)
		bne t0, a0, _differ
		lb t0, snake_y(t9)
		bne t0, a1, _differ

			li v0, 1
			j _return

		_differ:
	add t9, t9, 1
	lw  t0, snake_len
	blt t9, t0, _loop

	li v0, 0

_return:
leave

# ------------------------------------------------------------------------------------------------
# Drawing functions
# ------------------------------------------------------------------------------------------------

draw_all:
enter
	# if we haven't lost...
	lw t0, lost_game
	bne t0, 0, _return

		# draw everything.
		jal draw_snake
		jal draw_apple
		jal draw_hud
_return:
leave

# ------------------------------------------------------------------------------------------------

draw_snake:
enter s0
	# define s0 to be 0 as the start of loop and load snake_len into t0
	li s0, 0

	# for (int i = 0; i < snake_len; i++) 
	_loop:
		# check loop condition
		lw t0, snake_len
		bge s0, t0, _next
		
		#set a0 to snake_x[s0] * GRID_CELL_SIZE
		lb t1, snake_x(s0)
		mul a0, t1, GRID_CELL_SIZE
		
		#set a1 to snake_y[s0] * GRID_CELL_SIZE
		lb t2, snake_y(s0)
		mul a1, t2, GRID_CELL_SIZE
		
		# choose texture
		beq s0, zero, _draw_head
		la a2, tex_snake_segment
		j _skip_head # ensures that we dont always make everything a snake head
		# set a2 to the proper direction if we are on the snakes head
		_draw_head:
			lw t1, snake_dir
			mul t1, t1, 4
			lw a2, tex_snake_head(t1)
		
		# picks up here after texture selection
		_skip_head: 
			jal display_blit_5x5_trans
	
		# increment 
		add s0, s0, 1
		
		# loop
		j _loop
		
	_next:
leave s0

# ------------------------------------------------------------------------------------------------

draw_apple:
enter
	# load apple coordinates
	lw t0, apple_x
	lw t1, apple_y
	
	# multiplications and storage in a0 and a1
	mul a0, t0, GRID_CELL_SIZE
	mul a1, t1, GRID_CELL_SIZE
	
	# load texture address
	la a2, tex_apple
	
	# display apple
	jal display_blit_5x5_trans
leave

# ------------------------------------------------------------------------------------------------

draw_hud:
enter
	# draw a horizontal line above the HUD showing the lower boundary of the playfield
	li  a0, 0
	li  a1, GRID_HEIGHT
	mul a1, a1, GRID_CELL_SIZE
	li  a2, DISPLAY_W
	li  a3, COLOR_WHITE
	jal display_draw_hline

	# draw apples collected out of remaining
	li a0, 1
	li a1, 58
	lw a2, apples_eaten
	jal display_draw_int

	li a0, 13
	li a1, 58
	li a2, '/'
	jal display_draw_char

	li a0, 19
	li a2, 58
	li a2, APPLES_NEEDED
	jal display_draw_int
leave
