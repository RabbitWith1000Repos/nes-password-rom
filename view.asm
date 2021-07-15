        MAC MOVE_TO_NEXT_CHUNK
	lda #1
        bit CurrentPasswordChunk
        bne .NextLine
        lda #0
        sta PPU_DATA
        beq .NextChunk
.NextLine:
        txa
        pha
	lda #0
        ldx #19
.NextLineLoop:
        sta PPU_DATA
        dex
        cpx #0
        bne .NextLineLoop
        pla
        tax
.NextChunk:
        inc CurrentPasswordChunk
        ENDM

WritePassword: subroutine
        lda #0
        sta CurrentPasswordChunk
        jsr GetCurrentLetterPosition
        tax
        ldy #0
.WriteLetterInChunk:
	tya
        pha
        lda Passwords,x
        sta PPU_DATA
        pla
        tay
        cpy #5
        beq .ChunkDone
        inx
        iny
        bne .WriteLetterInChunk
.ChunkDone:
	MOVE_TO_NEXT_CHUNK
        lda #4
        ldy #0
        inx
        cmp CurrentPasswordChunk
        bne .WriteLetterInChunk
	rts    

WriteAlternateDecodedPassword: subroutine
        lda #0
        sta CurrentPasswordChunk
        ldx #0
        ldy #0
.WriteLetterInChunk
        tya
        pha
        lda AlternatePassword,x
        tay
        lda Letters,y
        sta PPU_DATA
        pla
        tay
        cpy #5
        beq .ChunkDone
        inx
        iny
        bne .WriteLetterInChunk
.ChunkDone
	MOVE_TO_NEXT_CHUNK
        lda #4
        ldy #0
        inx
        cmp CurrentPasswordChunk
        bne .WriteLetterInChunk
	rts    

DrawBamboo: subroutine
        lda #$80
        sta BambooRenderPos
.WriteColumn:
	lda BambooRenderPos
        sta PPU_DATA
        inc BambooRenderPos
        lda #%00000111
        and BambooRenderPos
        bne .WriteColumn
.MaybeNextRow
        lda #%11111110
        and BambooRenderPos
        beq .Done
        ldy #8
        lda #0
.ToNextRow
	sta PPU_DATA
	dey
        cpy #0
        bne .ToNextRow
        bcs .WriteColumn
.Done
        rts

; set palette colors
SetPalette: subroutine
; set PPU address to palette start
	PPU_SETADDR $3f00
        ldy #0
.loop:
	lda Palette,y	; lookup byte in ROM
	sta PPU_DATA	; store byte to PPU data
        iny		; Y = Y + 1
        cpy #32		; is Y equal to 32?
	bne .loop	; not yet, loop
        rts		; return to caller