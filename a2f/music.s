; music
;
; System for simple music playback.

.include "../a2f.inc"

.export music_command
.export music_play

.import sound_pulse
.import sound_noise
.import vdelay

.importzp a2f_temp

music_note_length:  .byte  16 ; default 1/4 second
music_note_octave:  .byte $40 ; default middle-C octave
music_note_duty:    .byte   1 ; default square
music_repeat_count: .byte   0 ; no repeats yet
music_repeat_point: .word   0
music_loop_point:   .word   0
music_data:         .word   0

music_period0lo: .byte $C9,$1A,$30,$FF,$7E,$A2,$62,$B5,$93,$F5,$D2,$24
music_period0hi: .byte $F3,$E6,$D9,$CC,$C1,$B6,$AC,$A2,$99,$90,$88,$81
music_timing8lo: .byte $5A,$53,$5B,$72,$9A,$D4,$20,$80,$F5,$80,$23,$DE
music_timing8hi: .byte $10,$11,$12,$13,$14,$15,$17,$18,$19,$1B,$1D,$1E

.proc music_command ; A = command
	cmp #$FF
	beq command_halt
	cmp #$70
	bcs command_note_direct
	cmp #$60
	bcs command_note_octave
	cmp #$20
	bcs command_duration
	cmp #$17
	bcs command_octave
	cmp #$10
	bcs command_duty
	cmp #$01
	bcs command_rest
	bcc command_halt
	cmp #$0D
	bcc command_repeat
	beq command_loop
	cmp #$0E
	beq command_repeat_point
	bne command_loop_point
; commands
command_halt:
	lda #0
	sta music_repeat_count
	sta music_data+0
	sta music_data+1
	rts
command_note_direct:
	sec
	sbc #$70
	jmp note
command_note_octave:
	and #$0F
	ora music_note_octave
	jmp note
command_duration:
	sec
	sbc #($20-1)
	sta music_note_length
	rts
command_octave:
	asl
	asl
	asl
	asl
	sec
	sbc #$70
	sta music_note_octave
	rts
command_duty:
	and #$07
	sta music_note_duty
	rts
command_rest:
	jmp rest
command_repeat:
	inc music_repeat_count
	cmp music_repeat_count
	bcs :+
		lda music_repeat_point+0
		sta music_data+0
		lda music_repeat_point+1
		sta music_data+1
		rts
	:
	lda #0
	sta music_repeat_count
	rts
command_loop:
	lda music_loop_point+0
	sta music_data+0
	lda music_loop_point+1
	sta music_data+1
	rts
command_repeat_point:
	lda music_data+0
	sta music_repeat_point+0
	lda music_data+1
	sta music_repeat_point+1
	rts
command_loop_point:
	lda music_data+0
	sta music_loop_point+0
	lda music_data+1
	sta music_loop_point+1
	rts
; actions
note:
	; A = $ON Octave Note
	pha
	and #$0F
	cmp #$0C
	bcs command_halt ; invalid note
	tax
	lda music_period0lo, X
	sta a2f_temp+0
	lda music_period0hi, X
	sta a2f_temp+1
	lda music_timing8lo, X
	sta a2f_temp+2
	lda music_timing8hi, X
	sta a2f_temp+3
	pla
	lsr
	lsr
	lsr
	lsr
	tax ; X = octave
	tay ; Y = octave also
	; shift period to match octave
	beq @pitch_end
:
	lsr a2f_temp+1
	ror a2f_temp+0
	dex
	bne :-
	; round to nearest for more accurate pitch
	bcc :+
	inc a2f_temp+0
	bne :+
	inc a2f_temp+1
:
@pitch_end:
	; shift timing to match octave
	cpy #8
	bcs @timing_end
:
	lsr a2f_temp+3
	ror a2f_temp+2
	iny
	cpy #8
	bcc :-
	; not bothering to round (timing isn't very precise)
@timing_end:
	; multiply timing by music_note_length and divide by 64
	lda #0
	sta a2f_temp+5 ; big-endian 5:4 to keep MSB in a2f_temp+4
	sta a2f_temp+4
	lda music_note_length
	sta a2f_temp+6
	ldx #7
@multiply:
	lsr a2f_temp+6 ; multiplier
	bcc :+
		lda a2f_temp+2
		clc
		adc a2f_temp+5
		sta a2f_temp+5
		lda a2f_temp+3
		adc a2f_temp+4
		sta a2f_temp+4
	:
	dex
	beq :+
	lsr a2f_temp+4
	ror a2f_temp+5
	jmp @multiply
:
	; make sure result is at least 1
	lda a2f_temp+5
	ora a2f_temp+4
	bne :+
		inc a2f_temp+5
	:
	; (a2f_temp 5:4 is now waveform count for sound_pulse)
	; calculate 2 periods for pulse
	lda a2f_temp+0
	sta a2f_temp+2
	lda a2f_temp+1
	sta a2f_temp+3
	ldx music_note_duty
	bne :+
		inx ; duty 0 = noise, should still act like square timing
	:
		lsr a2f_temp+1
		ror a2f_temp+0
		dex
		bne :-
	; minimum period is 45, adjust for this in case period went too low (preserves pitch despite wrong duty)
	lda a2f_temp+1
	bne :+
		lda a2f_temp+0
		cmp #45
		bcs :+
		lda #45
		sta a2f_temp+0
	:
	; second period takes whatever cycles are left in the wavelength
	lda a2f_temp+2
	sec
	sbc a2f_temp+0
	sta a2f_temp+2
	lda a2f_temp+3
	sbc a2f_temp+1
	sta a2f_temp+3
	; dispatch noise or note
	ldx music_note_duty
	beq :+
		ldy a2f_temp+5
		jmp sound_pulse
	:
		; noise needs double time
		asl a2f_temp+5
		rol a2f_temp+4
		ldy a2f_temp+5
		jmp sound_noise
	;
rest:
	ldy music_note_length
	:
		.assert (CPU_RATE/64)<=65535, error, "Rest cycle length must be 16-bit"
		lda #<(CPU_RATE/64)
		ldx #>(CPU_RATE/64)
		jsr vdelay
		dey
		bne :-
	rts
.endproc

.proc music_play ; A = mode: 0 only halt stops, 1 keypress stops, 2 keypress or joystick stops
	; TODO store mode and set it up
	lda #0
	sta music_repeat_count
@loop:
	lda music_data+1
	bne :+
		rts
	:
	sta a2f_temp+1
	lda music_data+0
	sta a2f_temp+0
	ldy #0
	lda (a2f_temp+0), Y
	inc music_data+0
	bne :+
		inc music_data+1
	:
	jsr music_command
	; TODO check mode and test input if needed
	jmp @loop
.endproc
