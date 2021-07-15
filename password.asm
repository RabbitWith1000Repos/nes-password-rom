PASSWORD_LENGTH = 24 ; length for comparing to Y
SPACE_VALUE = 64
SPACE_LOCATION = 64
SPACE_BECOME_VALUE = SPACE_LOCATION - 1
PASSWORD_COUNT = 5

	include "nesdefs.dasm"

;;;;; VARIABLES

	seg.u ZEROPAGE
	org $0

;; global

Seed ds 2
PasswordInUse ds 1
        
;; controller

CurrentController ds 1
BButtonDown ds 1
AButtonDown ds 1

;; decoding

CurrentLetter ds 1
CurrentPasswordChunk ds 1
RandomValueForPasswordLetterModification ds 1
DecodedPasswordOffset ds 1
CurrentLetterPositionProcess ds 1
CurrentLetterPositionDisplay ds 1

;; rendering

BambooRenderPos ds 1
StringToWrite ds 2

        seg.u PASSWORDS
        org $400

;; password storage

DecodedPassword ds 24
AlternatePassword ds 24


;;;;; NES CARTRIDGE HEADER

	NES_HEADER 0,2,1,NES_MIRR_HORIZ ; mapper 0, 2 PRGs, 1 CHR

;;;;; START OF CODE

Start:
; wait for PPU warmup; clear CPU RAM
	NES_INIT	; set up stack pointer, turn off PPU
        jsr WaitSync	; wait for VSYNC
        jsr ClearRAM	; clear RAM
        jsr WaitSync	; wait for VSYNC (and PPU warmup)
; set palette and nametable VRAM
	jsr SetPalette	; set palette colors
        lda #0
        sta PasswordInUse 

; reset PPU address and scroll registers
        lda #0
        sta PPU_ADDR
        sta PPU_ADDR	; PPU addr = $0000
        sta PPU_SCROLL
        sta PPU_SCROLL  ; PPU scroll = $0000
        
; seed rng
        lda #25
        sta Seed
        lda #43
        sta Seed+1

; disable NMI and scroll
        lda #0          ; disable NMI
        sta PPU_CTRL	

        lda #$0
        sta PPU_SCROLL
        sta PPU_SCROLL  ; PPU scroll = $0000

; set up controller
        lda #0
        sta AButtonDown
        sta BButtonDown
        
        jsr DecodePassword
        jsr ConvertDecodedPasswordToAlternatePassword

	jsr WriteUI

.endless
	jsr ReadJoypad0
        sta CurrentController
        
        jsr HandleBButton
        jsr HandleAButton

        inc Seed
	jmp .endless	; endless loop


;;;;; COMMON SUBROUTINES

	include "nesppu.dasm"
	include "processing.asm"
	include "view.asm"
	include "galois16.asm"
	include "data.asm"

WriteString: subroutine
	ldy #0
.Continue:
	lda (StringToWrite),y
        beq .Done
        sta PPU_DATA
      	iny
        bne .Continue
.Done
	rts

        MAC WRITE_STRING
        lda #<{1}
        sta StringToWrite
        lda #>{1}
        sta StringToWrite+1
        jsr WriteString
        ENDM

WriteUI: subroutine
        lda #0
        sta PPU_MASK ; turn rendering off

	PPU_SETADDR $2069
        jsr WritePassword
        
        PPU_SETADDR $20c1
        WRITE_STRING CanAlsoMessage

        PPU_SETADDR $2109
        jsr WriteAlternateDecodedPassword

        PPU_SETADDR $21a6
	WRITE_STRING AButtonMessage

        PPU_SETADDR $21c3
        WRITE_STRING BButtonMessage
        
        PPU_SETADDR $2242
        jsr DrawBamboo

        PPU_SETADDR $224a
	WRITE_STRING R1KRTitleOne

        PPU_SETADDR $226d
        WRITE_STRING R1KRTitleTwo

        PPU_SETADDR $22a9
        WRITE_STRING R1KRBlogTitle

        PPU_SETADDR $22e9
        WRITE_STRING R1KRBlogLinkOne

        PPU_SETADDR $230b
        WRITE_STRING R1KRBlogLinkTwo

;;;;; palette stuff

 	PPU_SETADDR $23e8
        
        lda #%01010101
        sta PPU_DATA
        sta PPU_DATA

 	PPU_SETADDR $23f0
        
        lda #%10101010
        sta PPU_DATA
        sta PPU_DATA

        lda #MASK_BG
        sta PPU_MASK 	; enable rendering
        lda #$0
        sta PPU_ADDR
        sta PPU_ADDR	; PPU addr = $0000
        
	rts
        
HandleBButton: subroutine
        lda #%01000000        ; lowest bit is b
        bit CurrentController
        beq .BButtonUp        ; button is up
.BButtonDown
        lda #0
        cmp BButtonDown
        bne .BButtonWasDown
        
        jsr ConvertDecodedPasswordToAlternatePassword
        jsr WriteUI

.BButtonWasDown
	lda #1
        sta BButtonDown
        bne .BButtonDone
.BButtonUp
	lda #0
        sta BButtonDown
.BButtonDone
	rts

HandleAButton: subroutine
        lda #%10000000        ; lowest bit is b
        bit CurrentController
        beq .AButtonUp        ; button is up
.AButtonDown
        lda #0
        cmp AButtonDown
        bne .AButtonWasDown
        
        inc PasswordInUse
        lda #PASSWORD_COUNT
        cmp PasswordInUse
        bne .NotEqual
        
        lda #0
        sta PasswordInUse
.NotEqual
        
        jsr DecodePassword
        jsr ConvertDecodedPasswordToAlternatePassword
        jsr WriteUI

.AButtonWasDown
	lda #1
        sta AButtonDown
        bne .AButtonDone
.AButtonUp
	lda #0
        sta AButtonDown
.AButtonDone
	rts


;;;;; INTERRUPT HANDLERS


NMIHandler: subroutine
	SAVE_REGS

        RESTORE_REGS
	rti

;;;;; CPU VECTORS

	NES_VECTORS

	org $10000
        
        
        incbin "calderon_with_bamboo.chr"
        incbin "calderon_with_bamboo.chr"
