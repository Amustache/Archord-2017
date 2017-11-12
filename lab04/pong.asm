# Authors: Hugo Hueber & Florine Reau
# Date:	  28/11/2017
# Notes: 
#           - Only allowed procedure names: clear_leds, set_pixel, move_ball,
#               move_paddles, draw_paddles, hit_test, display_score
#           - Only one file, pong.asm
#           - Each procedure must be enclosed with
#                   ; BEGIN:procedure_name
#               and
#                   ; END:procedure_name
#           - 0x1000: Ball position on x-axis
#               0x1004: Ball position on y-axis
#               0x1008: Ball velocity along x-axis
#               0x100C: Ball velocity along y-axis
#           - 0x1010: Paddle 1 center position (left)
#               0x1014: Paddle 2 center position (right)
#           - 0x1018: Score of player 1 (left)
#               0x101C: Score of player 2 (right)

# Symbolic constants
.equ BALL,          0x1000  # Ball state (its position and velocity)
.equ PADDLES,       0x1010  # Paddles position
.equ SCORES,        0x1018  # Game scores
.equ LEDS,          0x2000  # LED addresses
.equ BUTTONS,       0x2030  # Button addresses
.equ INITX,         3       # Initial ball x position
.equ INITY,         1       # Initial ball y position
.equ INITXSPEED,    1       # Initial ball x velocity
.equ INITYSPEED,    -1      # Initial ball y velocity

; BEGIN:main
main:
    # Initializations
    # Init stack
    addi sp, zero, LEDS
init:
    # Init ball x and y
    addi t0, zero, INITX
    stw t0, BALL (zero)
    addi t0, zero, INITY
    stw t0, BALL+4 (zero)

    # Init ball velocity
    addi t0, zero, INITXSPEED
    stw t0, BALL+8 (zero)
    addi t0, zero, INITYSPEED
    stw t0, BALL+12 (zero)
    
    # Init paddles
    addi t0, zero, 3
    stw t0, PADDLES (zero)
    addi t0, zero, 4
    stw t0, PADDLES+4 (zero)
    
    # Round
round:
    call clear_leds
    
    call move_paddles
    call draw_paddles
    
    call move_ball
    
    # Draw ball
    ldw t0, BALL (zero)
    add a0, zero, t0
    ldw t1, BALL+4 (zero)
    add a1, zero, t1
    call set_pixel
    
    call hit_test
    beq v0, zero, round
    
    # Someone scored
scored:
    addi t0, zero, v0               # t0 = who scored
    slli t0, t0, 2
    ldw t1, SCORES (t0)
    addi t1, t1, 1
    stw t1, SCORES (t0)             # Whoever scored gets +1
    
    call display_score              # Brags about the score
    
    addi t0, zero, 10
    blt t1, t0, round               # if(score < 10) then goto init
    
    # End of the game
end:
    ret
; END:main

; BEGIN:clear_leds
clear_leds:
    ; your implementation code
    # Reset leds[]
    stw zero, LEDS (zero)           # reset leds[0]
    stw zero, LEDS+4 (zero)         # reset leds[1]
    stw zero, LEDS+8 (zero)         # reset leds[2]
    
    ret
; END:clear_leds

; BEGIN:set_pixel
set_pixel:
    ; your implementation code
    # Store a0, a1 in the stack
    addi sp, sp, -8
    stw a0, 4 (sp)
    stw a1, 0 (sp)
    
    # Which word should we use
    andi t0, a0, 12                 # t0 = a0 and "1100"
    
    # Which bit should we set
    andi t1, a0, 3                  # t1 = a0 and "0011"
    slli t1, t1, 3                  # t1 = t1 * 8 = (a0 % 4) * 8
    add t1, t1, a1                  # t1 = t1 + a1 = a0 * 8 + a1
    
    # Set the bit
    addi t2, zero, 1                # t2 = 1
    sll t2, t2, t1                  # t2 = t2 * (2 ^ t1) := mask
    ldw t3, LEDS (t0)               # t3 = leds[t0]
    or t3, t3, t2                   # t3 = t3 or t2 = leds[t0] or mask
    stw t3, LEDS (t0)               # leds[t0] = t3 = leds[t0] or mask
    
    # Load a0, a1 from the stack
    ldw a1, 0 (sp)
    ldw a0, 4 (sp)
    addi sp, sp, 8
    
    ret
; END:set_pixel

; BEGIN:hit_test
hit_test:
    ; your implementation code
    # Check for x-axis
hit_text_x:
    ldw t0, BALL (zero)             # t0 = ball.x
    cmpeqi t2, t0, 0                # t2 = ball.x == 0
    beq t2, zero, hit_test_x_1      # if(ball.x != 0) goto hit_test_x_1
    addi t2, zero, 1
    stw t2, BALL+8 (zero)           # else ball.xspeed = 1
hit_test_x_1:
    cmpeqi t2, t0, 11               # t2 = ball.x == 11
    beq t2, zero, hit_test_y        # if(ball.x != 11) goto hit_test_y
    addi t2, zero, -1
    stw t2, BALL+8 (zero)           # else ball.xspeed = -1
    
    # Check for y-axis
hit_test_y:
    ldw t0, BALL+4 (zero)           # t0 = ball.y
    cmpeqi t2, t0, 0                # t2 = ball.y == 0
    beq t2, zero, hit_test_y_1      # if(ball.y != 0) goto hit_test_y_1
    addi t2, zero, 1
    stw t2, BALL+12 (zero)          # else ball.yspeed = 1
hit_test_y_1:
    cmpeqi t2, t0, 7                # t2 = ball.y == 7
    beq t2, zero, hit_test_end      # if(ball.y != 7) goto hit_test_end
    addi t2, zero, -1
    stw t2, BALL+12 (zero)          # else ball.yspeed = -1
    
hit_test_end:
    ret
; END:hit_test

; BEGIN:move_ball
move_ball:
    ; your implementation code
    # X-axis
    ldw t0, BALL (zero)             # t0 = ball.x
    ldw t1, BALL+8 (zero)           # t1 = ball.xspeed
    add t0, t0, t1
    stw t0, BALL (zero)             # ball.x += ball.xspeed
    
    # Y-axis
    ldw t0, BALL+4 (zero)           # t0 = ball.y
    ldw t1, BALL+12 (zero)          # t0 = ball.yspeed
    add t0, t0, t1
    stw t0, BALL+4 (zero)           # ball.y += ball.yspeed
    
    ret
; END:move_ball

; BEGIN:move_paddles
move_paddles:
    ; your implementation code
    # 0: Paddle 1 up, 1: Paddle 1 down, 2: Paddle 2 down, 3: Paddle 2 up
    ldw t0, PADDLES (zero)          # t0 = paddle1.y
    ldw t1, PADDLES+4 (zero)        # t1 = paddle2.y
    ldw t2, BUTTONS+4 (zero)        # t2 = buttons.edgecapture
    
paddle_1_up:
    addi t3, zero, 1
    beq t0, t3, paddle_1_down       # if(paddle1.y == 1) then goto paddle_1_down
    andi t3, t2, 1
    cmpeqi t3, t3, 1                # else if(buttons.edgecapture.0 == 1) then
    xori t3, t3, 0xFFFF
    addi t3, t3, 1
    add t0, t0, t3                  # paddle1.y -= 1
    andi t0, t0, 7
    
paddle_1_down:
    addi t3, zero, 6
    beq t0, t3, paddle_2_down       # if(paddle1.y == 6) then goto paddle_2_down
    andi t3, t2, 2
    cmpeqi t3, t3, 2                # else if(buttons.edgecapture.1 == 1) then
    add t0, t0, t3                  # paddle1.y += 1
    andi t0, t0, 7
    
    stw t0, PADDLES (zero)
    
paddle_2_down:
    addi t3, zero, 6
    beq t1, t3, paddle_2_up         # if(paddle2.y == 6) then goto paddle_2_up
    andi t3, t2, 4
    cmpeqi t3, t3, 4                # else if(buttons.edgecapture.2 == 1) then
    add t1, t1, t3                  # paddle2.y += 1
    andi t1, t1, 7
    
paddle_2_up:
    addi t3, zero, 1
    beq t1, t3, reset_edgecapture   # if(paddle2.y == 1) then goto reset_edgecapture
    andi t3, t2, 8
    cmpeqi t3, t3, 8                # else if(buttons.edgecapture.3 == 1) then
    xori t3, t3, 0xFFFF
    addi t3, t3, 1
    add t1, t1, t3                  # paddle2.y -= 1
    andi t1, t1, 7
    
    stw t1, PADDLES+4 (zero)
    
reset_edgecapture:
    ldw t0, BUTTONS+4 (zero)
    andi t0, t0, 0xFFF0
    stw t0, BUTTONS+4 (zero)
    
    ret
; END:move_paddles

; BEGIN:draw_paddles
draw_paddles:
    ; your implementation code
    # Store a0, a1 in the stack
    addi sp, sp, -12
    stw ra, 8 (sp)
    stw a0, 4 (sp)
    stw a1, 0 (sp)
    
    # Draw left paddle
    addi a0, zero, 0
    ldw t0, PADDLES  (zero)
    add a1, zero, t0
    call set_pixel
    addi a1, a1, -1
    call set_pixel
    addi a1, a1, 2
    call set_pixel
    
    # Draw right paddle
    addi a0, zero, 11
    ldw t0, PADDLES+4 (zero)
    add a1, zero, t0
    call set_pixel
    addi a1, a1, -1
    call set_pixel
    addi a1, a1, 2
    call set_pixel

    # Load a0, a1 from the stack
    ldw a1, 0 (sp)
    ldw a0, 4 (sp)
    ldw ra, 8 (sp)
    addi sp, sp, 12
    
    ret
; END:draw_paddles

# Hexadecimal
font_data:
    .word 0x7E427E00 ; 0
    .word 0x407E4400 ; 1
    .word 0x4E4A7A00 ; 2
    .word 0x7E4A4200 ; 3
    .word 0x7E080E00 ; 4
    .word 0x7A4A4E00 ; 5
    .word 0x7A4A7E00 ; 6
    .word 0x7E020600 ; 7
    .word 0x7E4A7E00 ; 8
    .word 0x7E4A4E00 ; 9
    .word 0x7E127E00 ; A
    .word 0x344A7E00 ; B
    .word 0x42423C00 ; C
    .word 0x3C427E00 ; D
    .word 0x424A7E00 ; E
    .word 0x020A7E00 ; F
    .word 0x00181800 ; separator

; BEGIN:display_score
display_score:
    ; your implementation code
    # Load scores
    ldw t0, SCORES (zero)
    ldw t1, SCORES+4 (zero)
    
    # Prepare the right word
    slli t0, t0, 2
    slli t1, t1, 2
    addi t2, zero, 64
    
    # Fetch the right word
    ldw t0, font_data+0 (t0)
    ldw t1, font_data+0 (t1)
    ldw t2, font_data+0 (t2)
    
    # Store the word
    stw t0, LEDS (zero)
    stw t1, LEDS+8 (zero)
    stw t2, LEDS+4 (zero)
    
    ret
; END:display_score