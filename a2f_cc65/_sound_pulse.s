; _sound_pulse
;
; C interface for playing a pulse wave through the speaker.

.export _sound_pulse

.import popax
.import sound_pulse

.importzp a2f_temp

; void sound_pulse(uint16 cya, uint16 cyb, uint16 count)
.proc _sound_pulse
	stx a2f_temp+4
	pha
	jsr popax
	sta a2f_temp+2
	stx a2f_temp+3
	jsr popax
	sta a2f_temp+0
	stx a2f_temp+1
	pla
	tay
	jmp sound_pulse
.endproc
