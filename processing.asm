GetCurrentLetterPosition: subroutine
	lda #0
        ldx #0
SelectPassword:
        cpx PasswordInUse
        beq SelectPasswordDone
        adc #24
        inx
        bne SelectPassword
SelectPasswordDone:
	rts

DecodePassword: subroutine
        lda #0                    ; set up decoding variables
        sta DecodedPasswordOffset
        jsr GetCurrentLetterPosition
        sta CurrentLetterPositionProcess
        ldx #0
.ReadLetterLoop
        ldy CurrentLetterPositionProcess ; load the next letter of the password
        lda Passwords,y
        sta CurrentLetter         ; ...and stick it in a spot in RAM
        ldx #0                    ;
        ldy DecodedPasswordOffset
.FindMatchLoop
	lda Letters,x                    ; put the next search letter into accumulator
        jsr PushLetterToDecodedPassword ; always push the letter offset onto the decode list
        cmp CurrentLetter                ; if it's the same, we're done
        beq .FindMatchExit
        inx
        ;cpx #SPACE_LOCATION
        bne .FindMatchLoop
        
        lda Letters,x                    ; this is a space
        ldx #SPACE_VALUE
        jsr PushLetterToDecodedPassword
.FindMatchExit
        inc DecodedPasswordOffset
        iny
        inc CurrentLetterPositionProcess
        cpy #PASSWORD_LENGTH
        bne .ReadLetterLoop

	rts
        
ConvertDecodedPasswordToAlternatePassword: subroutine
        ldx #0
.NextCharacter
        lda DecodedPassword,x
        sta AlternatePassword,x
        cpx #0                   ; we can't do anything at position 0
        beq .NotSpaceValue
        cmp #SPACE_VALUE  ; not a candidate for modifying the prior value
        beq .SpaceValue
        cmp #SPACE_BECOME_VALUE  ; not a candidate for modifying the prior value
        beq .CanBecomeSpaceValue
        bne .NotSpaceValue
.SpaceValue        
        lda #SPACE_BECOME_VALUE
        sta AlternatePassword,x
        jsr galois16
        tay
        and #%00000100
        bne .UseASpace
        dex
        lda DecodedPassword,x
        ora #%00000011
        sta AlternatePassword,x
        inx
        bcs .NotSpaceValue
.CanBecomeSpaceValue
	; check to make sure both low bits are set on prior
        dex
        lda AlternatePassword,x
        and #%00000011
        bne .DoneBecomingSpace
        inx
        jsr galois16
        tay
        and #%00000100
        bne .NotSpaceValue
        lda #SPACE_VALUE
        sta AlternatePassword,x
        dex
        lda AlternatePassword,x
        cmp #SPACE_VALUE
.DoneBecomingSpace
        inx
        lda #0
        beq .NotSpaceValue
.UseASpace
        tya
	and #%00000011
	sta RandomValueForPasswordLetterModification ; y contains the lower bits to use instead
        lda #SPACE_LOCATION
        sta AlternatePassword,x
        dex
        lda DecodedPassword,x
        and #%11111100
        ora RandomValueForPasswordLetterModification
        sta AlternatePassword,x
        inx
.NotSpaceValue
        inx
        cpx #PASSWORD_LENGTH
        bne .NextCharacter
.done
        rts
 
PushLetterToDecodedPassword: subroutine
        ; X contains the letters.indexOf(letter)
        ; Y contains the current letter index
        ; A will get preserved
        pha
        txa
        sta DecodedPassword,y
        pla
        rts