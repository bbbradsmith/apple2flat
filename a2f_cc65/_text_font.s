; _text_font
;
; C access to text_font

.export _text_fontset
.export _text_fontset_offset
.export _text_set_font

.import text_fontset
.import text_fontset_offset

.import popax

_text_fontset = text_fontset
_text_fontset_offset = text_fontset_offset

; void text_set_font(const uint8* fontset, uint8 offset)
_text_set_font:
	sta text_fontset_offset
	jsr popax
	sta text_fontset+0
	stx text_fontset+1
	rts
