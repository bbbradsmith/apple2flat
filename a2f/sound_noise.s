; sound_noise
;
; Noise generator.

.export sound_noise
.export sound_noise_seed

.import vdelay

.importzp a2f_temp

; assert macro to ensure branches do not cross a page
.macro BP instruction_, label_
    instruction_ label_
    .assert >(label_) = >*, error, "Page crossed!"
.endmacro

.segment "CODE"

sound_noise_seed: .word $5555

.segment "ALIGN"

.align 32

; a2f_temp 1:0 = cycles-45 for first half of pulse
; a2f_temp 4:Y = wave count to play
.proc sound_noise_
@loop:
	lda a2f_temp+2       ; +3
	asl                  ; +2 = 5
	rol a2f_temp+3       ; +5 = 10
	BP bcs, :+           ; +2 = 12 (+3 = 13)
		bit $C030        ; +4 = 16
		inc a2f_temp+5   ; +5 = 21
		jmp :++          ; +3 = 24
	:
		eor #$39         ; +2 = 15
		php              ; +3 = 18
		plp              ; +4 = 22
		nop              ; +2 = 24
	:
	sta a2f_temp+2       ; +3 = 27
	lda a2f_temp+0       ; +3 = 30
	ldx a2f_temp+1       ; +3 = 33
	jsr vdelay           ; (X:A cycles)
	dey                  ; +2 = 35
	BP bne, :+           ; +2 = 37 (+3 = 38)
	dec a2f_temp+4       ; +5 = 42
	BP bpl, @loop        ; +3 = 45 (second half overhead, branch 1)
	rts
:
	nop                  ; +2 = 40
	nop                  ; +2 = 42
	jmp @loop            ; +3 = 45 (second half overhead, branch 2)
.endproc

.segment "CODE"

.proc sound_noise
	; 45 cycle overhead
	lda a2f_temp+0
	sec
	sbc #<45
	sta a2f_temp+0
	lda a2f_temp+1
	sbc #>45
	sta a2f_temp+1
	; copy seed to ZP
	lda sound_noise_seed+0
	ora #$80 ; ensure the seed is never 0
	sta a2f_temp+2
	lda sound_noise_seed+1
	sta a2f_temp+3
	; count parity
	lda #0
	sta a2f_temp+5
	; do noise
	jsr sound_noise_
	; if noise flipped the speaker an odd number of times, flip it once more for parity
	lda a2f_temp+5
	and #1
	beq :+
		bit $C030
	:
	; copy ZP back to seed
	lda a2f_temp+2
	sta sound_noise_seed+0
	lda a2f_temp+3
	sta sound_noise_seed+1
	rts
.endproc
