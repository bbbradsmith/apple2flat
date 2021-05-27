; kb_field
;
; text entry field utility

.include "../a2f.inc"

.export kb_field

.export kb_field_cursor
.export kb_field_cursor_rate

kb_field_cursor: .byte $7F ; default cursor
kb_field_cursor_rate: .byte 32 ; default speed

.proc kb_field
	; Y = length of buffer (1 more than length)
	; a2f_temp 0:1 = buffer
	; TODO
	rts
.endproc