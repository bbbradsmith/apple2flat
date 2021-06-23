; _sound_sweep
;
; C interface for playing sweep sounds

.export _sound_sweep_up
.export _sound_sweep_down

.import popax
.import sound_sweep_up
.import sound_sweep_down

.importzp a2f_temp

.proc _sound_sweep_common
	sta a2f_temp+5
	jsr popax
	stx a2f_temp+4
	pha
	jsr popax
	sta a2f_temp+0
	stx a2f_temp+1
	pla
	tay
	rts
.endproc

; void sound_sweep_up(uint16 cy, uint16 count, uint8 shift)
.proc _sound_sweep_up
	jsr _sound_sweep_common
	jmp sound_sweep_up
.endproc

; void sound_sweep_up(uint16 cy, uint16 count, uint8 shift)
.proc _sound_sweep_down
	jsr _sound_sweep_common
	jmp sound_sweep_down
.endproc
