.export _font_bin
.export _font_vwf_bin
.export _font_vwf_wid

.segment "CODE"

_font_bin:
.incbin "font.bin"

_font_vwf_bin:
.incbin "font_vwf.bin"

_font_vwf_wid:
.incbin "font_vwf.wid"
