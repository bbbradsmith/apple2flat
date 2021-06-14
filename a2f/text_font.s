; text_font
;
; Common things for graphics-mode text rendering

.export text_fontset
.export text_fontset_offset

.segment "CODE"

text_fontset:
.word 0

text_fontset_offset:
.byte $20
