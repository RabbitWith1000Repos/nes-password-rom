;
; 6502 LFSR PRNG - 16-bit
; Brad Smith, 2019
; http://rainwarrior.ca
;

; A 16-bit Galois LFSR

; Possible feedback values that generate a full 65535 step sequence:
; $2D = %00101101
; $39 = %00111001
; $3F = %00111111
; $53 = %01010011
; $BD = %10111101
; $D7 = %11010111

; $39 is chosen for its compact bit pattern

; simplest version iterates the LFSR 8 times to generate 8 random bits
; 133-141 cycles per call
; 19 bytes

galois16: subroutine
	ldy #8
	lda Seed+0
.one
	asl        ; shift the register
	rol Seed+1
	bcc .two
	eor #$39   ; apply XOR feedback whenever a 1 bit is shifted out
.two
	dey
	bne .one
	sta Seed+0
	cmp #0     ; reload flags
	rts

