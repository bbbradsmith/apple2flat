; _sound_pulse
;
; C interface for playing a square wave through the speaker.

.export _sound_square

.import popax
.import sound_square

.importzp a2f_temp

; void sound_square(uint16 cy, uint16 count)
.proc _sound_square
	stx a2f_temp+4
	pha
	jsr popax
	sta a2f_temp+0
	stx a2f_temp+1
	pla
	tay
	jmp sound_square
.endproc
