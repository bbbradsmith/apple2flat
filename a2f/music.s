; music
;
; System for simple music playback.

.include "../a2f.inc"

.export music_reset
.export music_command
.export music_play
.export music_resume

.import sound_pulse
.import sound_noise
.import vdelay

.importzp a2f_temp

music_note_length:  .byte  16 ; default 1/4 second
music_note_space:   .byte   0 ; default 0
music_note_octave:  .byte $40 ; default middle-C octave
music_note_duty:    .byte   1 ; default square
music_2byte:        .byte   0 ; 2-byte command
music_play_mode:    .byte   0
music_paddleb_last: .byte   0 ; last paddle read
music_repeat_count: .byte   0 ; no repeats yet
music_repeat_point: .word   0
music_loop_point:   .word   0
music_data:         .word   0

music_period0lo: .byte $C9,$1A,$30,$FF,$7E,$A2,$62,$B5,$93,$F5,$D2,$24
music_period0hi: .byte $F3,$E6,$D9,$CC,$C1,$B6,$AC,$A2,$99,$90,$88,$81
music_timing8lo: .byte $5A,$53,$5B,$72,$9A,$D4,$20,$80,$F5,$80,$23,$DE
music_timing8hi: .byte $10,$11,$12,$13,$14,$15,$17,$18,$19,$1B,$1D,$1E

.proc music_reset
	lda #16
	sta music_note_length
	lda #$40
	sta music_note_octave
	lda #1
	sta music_note_duty
	lda #0
	sta music_2byte
	sta music_note_space
	sta music_repeat_count
	sta music_repeat_point+0
	sta music_repeat_point+1
	sta music_loop_point+0
	sta music_loop_point+1
	rts ; returns with A=0
.endproc

.proc music_command_2byte ; second byte of 2-byte command
	ldx #0
	stx music_2byte
	cmp #$01
	bcc music_command_halt
	beq command_space_off
	cmp #$20
	bcc music_command_halt
	cmp #$60
	bcc command_space
	cmp #$FE
	bne music_command_halt
	rts ; $FE no-effect
command_space_off:
	lda #0
	sta music_note_space
	rts
command_space:
	sec
	sbc #($20-1)
	sta music_note_space
	rts
.endproc

music_command_halt:
	jsr music_reset
	; A = 0
	sta music_data+0
	sta music_data+1
	rts

.proc music_command ; A = command
	ldx music_2byte
	bne music_command_2byte
	cmp #$FF
	beq command_2byte
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
	beq command_rest
	bcc music_command_halt
	cmp #$0D
	bcc command_repeat
	beq command_loop
	cmp #$0E
	beq command_repeat_point
	bne command_loop_point
; commands
command_2byte:
	sta music_2byte
	rts
command_note_direct:
	cmp #$FE
	bcs :+
	sec
	sbc #$70
	jmp note
:
	bne :+
	rts ; no-effect
:
	sta music_2byte
	rts
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
	bcc :+
	beq :+
		; A <= music_repeat_count
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
	bcc :+
		pla
		jmp music_command_halt ; invalid note
	:
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
		jsr sound_pulse
		jmp :++
	:
		; noise needs double time
		asl a2f_temp+5
		rol a2f_temp+4
		ldy a2f_temp+5
		jsr sound_noise
	:
	ldy music_note_space
	bne rest_y
end:
	rts
rest:
	ldy music_note_length
	jsr rest_y
	ldy music_note_space
	beq end
rest_y:
	:
		.assert (CPU_RATE/64)<=65535, error, "Rest cycle length must be 16-bit"
		lda #<(CPU_RATE/64)
		ldx #>(CPU_RATE/64)
		jsr vdelay
		dey
		bne :-
	rts
.endproc

.proc music_paddleb_poll ; returns newly pressed buttons in A/Z, stores music_paddleb_last
	lda #0
	sta a2f_temp+0
	lda $C062 ; button 1
	asl
	rol a2f_temp+0
	lda $C061 ; button 0
	asl
	rol a2f_temp+0
	lda a2f_temp+0
	eor music_paddleb_last
	and a2f_temp+0
	pha
	lda a2f_temp+0
	sta music_paddleb_last
	pla
	rts
.endproc

music_play: ; A = mode: 0 only halt stops, 1 keypress stops, 2 keypress or joystick stops
	pha
	jsr music_reset
	pla
music_resume:
	sta music_play_mode
	cmp #0
	beq :+
		lda KBSTAT ; clear pending keypress flag
		cmp #2
		bne :+
		jsr music_paddleb_poll ; read current state so a new press is required
	:
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
	lda music_play_mode
	beq :+
		ldx KBDATA
		bmi @stop ; stop on any kepress
		cmp #2
		bcc :+
		jsr music_paddleb_poll
		bne @stop ; stop on button 0 or 1 pressed
	:
	jmp @loop
@stop:
	rts
