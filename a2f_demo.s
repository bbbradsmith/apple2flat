.export _font_bin
.export _font_vwf_bin
.export _font_vwf_wid
.export _leyendecker_lr_bin
;.export _leyendecker_hr_bin
.export _leyendecker_dlr_bin
;.export _leyendecker_dhr_bin

.segment "RODATA"

_font_bin:            .incbin "demo_gfx/font.bin"
_font_vwf_bin:        .incbin "demo_gfx/font_vwf.bin"
_font_vwf_wid:        .incbin "demo_gfx/font_vwf.wid"
_leyendecker_lr_bin:  .incbin "demo_gfx/leyendecker_lr.bin"
;_leyendecker_hr_bin:  .incbin "demo_gfx/leyendecker_hr.bin"
_leyendecker_dlr_bin: .incbin "demo_gfx/leyendecker_dlr.bin"
;_leyendecker_dhr_bin: .incbin "demo_gfx/leyendecker_dhr.bin"
