; _sound_noise
;
; C interface for playing a square wave through the speaker.

.export _sound_noise

.import popax
.import sound_noise

.importzp a2f_temp

; void sound_noise(uint16 cy, uint16 count)
.proc _sound_noise
	stx a2f_temp+4
	pha
	; adjust for 40-cycle overhead
	jsr popax
	sta a2f_temp+0
	stx a2f_temp+1
	pla
	tay
	jmp sound_noise
.endproc
