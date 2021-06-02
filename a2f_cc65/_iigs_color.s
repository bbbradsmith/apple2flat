; _iigs_color
;
; C interface for iigs_color

.export _iigs_color

.import popa
.import iigs_color

.importzp a2f_temp

; void iigs_color(uint8 text_fg, uint8 text_bg, uint8 border)
.proc _iigs_color
	sta a2f_temp+0
	jsr popa
	sta a2f_temp+1
	jsr popa
	ldx a2f_temp+1
	ldy a2f_temp+0
	jmp iigs_color
.endproc
