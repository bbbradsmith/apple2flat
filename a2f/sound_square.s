; sound_square
;
; Uses sound_pulse to generate a square wave.

.export sound_square

.import sound_pulse
.importzp a2f_temp

.proc sound_square ; divide input by 2
	lsr a2f_temp+1
	ror a2f_temp+0
	lda #0 ; use carry in case it was odd to preserve pitch slightly better
	adc a2f_temp+0
	sta a2f_temp+2
	lda #0
	adc a2f_temp+1
	sta a2f_temp+3
	jmp sound_pulse
.endproc
