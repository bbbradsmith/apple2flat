; sound_sweep
;
; Approximate square that sweeps down or up at quasi-logarithmic rate

.export sound_sweep_up
.export sound_sweep_down

.import vdelay

.importzp a2f_temp

.proc sound_sweep_common
	bit $C030
	lda a2f_temp+0
	ldx a2f_temp+1
	jsr vdelay
	lda a2f_temp+0
	ldx a2f_temp+1
	bit $C030
	jsr vdelay
	ldx a2f_temp+5
	; a2f_temp 3:A = a2f_temp 1:0 >> X
	lda a2f_temp+1
	sta a2f_temp+3
	lda a2f_temp+0
	:
		lsr a2f_temp+3
		ror
		dex
		bne :-
	rts ; A = low byte of period change
.endproc

; a2f_temp 1:0 = approximate cycles for half of pulse
; a2f_temp 4:Y = max wave count to play
; a2f_temp 5 = shift_count
.proc sound_sweep_up
	lsr a2f_temp+1 ; /2 (full wave to half wave)
	ror a2f_temp+0
@loop:
	jsr sound_sweep_common
	sta a2f_temp+2
	; a2f_temp 1:0 -= a2f_temp 3:2 + 1
	lda a2f_temp+0
	clc ; +1
	sbc a2f_temp+2
	sta a2f_temp+0
	lda a2f_temp+1
	sbc a2f_temp+3
	bcc @end ; crossed 0
	sta a2f_temp+1
	; timeout
	dey
	bne @loop
	dec a2f_temp+4
	bpl @loop
@end:
	rts
.endproc

; a2f_temp 1:0 = approximate cycles for half of pulse
; a2f_temp 4:Y = max wave count to play
; a2f_temp 5 = shift_count
.proc sound_sweep_down
	lsr a2f_temp+1 ; /2 (full wave to half wave)
	ror a2f_temp+0
@loop:
	jsr sound_sweep_common
	; a2f_temp 1:0 += a2f_temp 3:A + 1
	sec ; +1
	adc a2f_temp+0
	sta a2f_temp+0
	lda a2f_temp+1
	adc a2f_temp+3
	bcs @end ; crossed 65535
	sta a2f_temp+1
	; timeout
	dey
	bne @loop
	dec a2f_temp+4
	bpl @loop
@end:
	rts
.endproc
