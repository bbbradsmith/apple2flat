; _kb
;
; C interface for keyboard

.include "../a2f.inc"

.export _kb_new
.export _kb_get
.export _kb_last
.export _kb_data
.export _kb_any

; char kb_new()
_kb_new:
	lda KBDATA
_kb_bit7_: ; transfer bit 7 to bit 0 (return 0/1)
	rol
	lda #0
	tax
	rol
	rts

; char kb_get()
_kb_get:
:
	lda KBDATA
	bpl :- ; wait until new keypress
	bit KBSTAT ; clear new key flag
	ldx #0
	and #$7F ; return low 7 data bits as keypress
	rts

; char kb_last()
_kb_last:
	lda KBDATA
	and #$7F
	rts

; uint8 kb_data()
_kb_data:
	lda KBDATA
	rts

; char kb_any()
_kb_any:
	lda KBSTAT
	jmp _kb_bit7_
