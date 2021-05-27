; _kb_field
;
; C access for kb_field

.include "../a2f.inc"

.export _kb_field
.export _kb_field_cursor
.export _kb_field_cursor_rate

.import popax
.import kb_field
.import kb_field_cursor
.import kb_field_cursor_blink_rate

_kb_field_cursor = kb_field_cursor
_kb_field_cursor_rate = kb_field_cursor_rate

; void kb_field(char* s, uint8 len)
.proc _kb_field
	pha
	jsr popax
	sta a2f_temp+0
	stx a2f_temp+1
	pla
	tay
	jmp kb_field
.endproc
