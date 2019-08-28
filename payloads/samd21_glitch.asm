.cpu cortex-m0
.thumb
.code 16
.global _start
_start:
# We don't care about the stack
stacktop: .word 0x20000200

# Just a ridiculous amount of int vectors
.word reset
.word reset
.word reset
.word reset
.word reset
.word reset
.word reset
.word reset
.word reset
.word reset
.word reset
.word reset
.word reset
.word reset
.word reset
.word reset
.word reset
.word reset
.word reset
.word reset
.word reset
.word reset
.word reset
.word reset
.word reset
.word reset
.word reset
.word reset
.word reset
.word reset
.word reset
.word reset
.word reset
.word reset
.word reset
.word reset
.word reset
.word reset
.word reset
.word reset
.word reset

.align 4

.thumb_func
reset:
	# Set the ports we use as output
	# According to https://cdn-shop.adafruit.com/product-files/2772/atmel-42181-sam-d21_datasheet.pdf
	# PORT is mapped to 0x41004400
	LDR r0, =0x41004400


	# Page 387: DIRSET is at offset 0x8
	# We are setting as output: PA18, 19, 22, and 23
	# PA18 = tft lite
	# PA19 = tft d/c
	# PA22 = red led
	# PA23 = green led

	# hex(((1<<6)|(1<<17)|(1<<22)|(1<<23)))
	# '0xc20040'

	
	# Load offset
	MOV r1, #8

	# Store DIRSET
	LDR r2, =0xc20040
	STR r2, [r0, r1]

	# Enable RED led, disable green
	# Enable PA18, disable PA19

	# For disabled LED we need to pull it high. 
	# The others we leave low

	# hex((1 << 18) | (1<<23))
	# 0x840000

	# Load OUTSET offset 0x18
	MOV r1, #0x18
	LDR r2, =0x400040
	STR r2, [r0, r1]

	# Lets loop!
	MOV r5, #4
Loop:
	# This is the loop we are glitching:

	# Load byte at address 0
	LDR r4, [r5]
	# Compare it with 0xb1, which should be the value
	CMP r4, #0xb1
	BEQ Loop


	# WE GLITCHED! Turn on the christmas tree

	# OUTCLR 0x14
	#MOV r1, #0x14
	# Enable LEDs
	#LDR r2, =0xCC0000
	#STR r2, [r0, r1]

	# OUTSET 0x18
	MOV r1, #0x18
	# Enable D/C IO
	LDR r2, =0x820000
	STR r2, [r0, r1]
	
	B .

.end
