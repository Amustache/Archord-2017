# Author: Mirjana Stojilovic
# Date:	  19/10/2017
# Notes: 
#         Tested in MARS 4.5 
#         Settings --> Memory configuration --> Compact, Data at Address 0

# symbolic constants
.eqv ARRAY_SIZE 0x00 	# array size stored at this address
.eqv ARRAY 		0x20	# array elements start at this address
.eqv RESULT 	0x40	# results start at this address
.eqv LSB_MASK	0xFF	# mask to extract the LSB

# storing data in memory
.data ARRAY_SIZE
.word 32	# ARRAY_SIZE = 0, mem[ARRAY_SIZE] = 32

.data ARRAY
.byte 0x12 	# 0
.byte 0xFF 	# 1, palindrome
.byte 0x3C	# 2, palindrome
.byte 0x11	# 3
.byte 0x54	# 4
.byte 0x42	# 5, palindrome
.byte 0xA0	# 6
.byte 0xAA	# 7
.byte 0x00	# 8, palindrome
.byte 0xDE	# 9
.byte 0xAD	# A
.byte 0xBE	# B
.byte 0xEF	# C
.byte 0xA5	# D, palindrome
.byte 0x5A	# E, palindrome
.byte 0x13	# F
.word 0x0000
.word 0x0000
.word 0x0000
.word 0x0000

# storing program
.text

#------------------------------------------------------------------------------
main:
#------------------------------------------------------------------------------

	lw		$s0, ARRAY_SIZE($zero)	# s0: array size
	add		$s1, $zero, $zero		# s1: current array index, initialized to zero

loop:
	bge		$s1, $s0, end			# if current array index = array size, we're done traversing the array
	
load_word:
	lw		$s2, ARRAY($s1)			# s2: word currently processed
	add		$s3, $zero, $zero		# s3: byte counter, initialized to 0. The correct range is 0--3.

loop_over_bytes_within_word:
	sll		$t0, $s3, 3 			# the number of bits to shift right to move this byte to the LSB position = t0 * 8
	srlv	$a0, $s2, $t0 			# shift right for t0 bits
	andi	$a0, $a0, LSB_MASK		# keep only the LSB the word currently processed

	jal		invert_byte				# call the function that will invert this byte. Function takes argument in $a0 and stores the result in v0

	bne		$a0, $v0, next_byte		# once the byte is inverted, check if v0 and a0 are the same. 
									# If yes, we found a palindrome and the result needs to be updated.
									# Else, next byte should be looked into.
palindrome_found:
	sub		$t0, $s0, $s1
	srl		$t0, $t0, 5 			# t0: (s0 - s1) / 32 = index of the word in the RESULT array
	sll		$t0, $t0, 2				# align the word address offset on word boundary
	lw		$t1, RESULT($t0)		# load current value of the word
	
	andi	$t2, $s1, 0x1F 			# location of bit within the word = array index modulo 32
	addi	$t3, $zero, 1			# $t3: one bit mask, used to set one bit in the RESULT array
	sllv	$t3, $t3, $t2			# $t3: all zeros but one '1' at the position $t2
	or		$t1, $t1, $t3 			# set one bit in result array
	sw		$t1, RESULT($t0)		# store the new value of the word

next_byte:
	addi	$s1, $s1, 1				# increment array index
	addi	$s3, $s3, 1				# increment byte counter
	
	bne		$s3, 4, loop_over_bytes_within_word

next_word:	
	j		loop

end:
	li 		$v0, 10					# END
	syscall
	
#------------------------------------------------------------------------------
invert_byte:						
#------------------------------------------------------------------------------
  	add		$t0, $a0, $zero			# BEGIN invert_byte. $t0: initialized to $a0
	add		$v0, $zero, $zero		# $v0: output
	addi	$t1, $zero, 8			# t1: bit counter, initialized to 8
	
loop_over_bits_within_byte:
	beq		$t1, $zero, return		# count down
	andi	$t2, $t0, 1 			# $t2: lowest-order bit from the input
	
	sll		$v0, $v0, 1 			# shift output left by 1 bit
	or		$v0, $v0, $t2 			# append the extracted bit ($t2) to the result
	
	srl		$t0, $t0, 1 			# consume lowest-order bit of input	
	addi	$t1, $t1, -1			# decrement bit counter
next_bit:
	j		loop_over_bits_within_byte

return:
	jr		$ra						# END invert_byte
