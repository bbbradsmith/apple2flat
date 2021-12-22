.export _font_bin
.export _font_vwf_bin
.export _font_vwf_wid

.export _leyendecker_lr_seg
.export _leyendecker_dlr_seg
.export _leyendecker_mono_seg
.export _leyendecker_hr_seg
.export _leyendecker_dhr_seg

.segment "RODATA"

_font_bin:            .incbin "demo_gfx/font.bin"
_font_vwf_bin:        .incbin "demo_gfx/font_vwf.bin"
_font_vwf_wid:        .incbin "demo_gfx/font_vwf.wid"

.segment "EXTRA"

.align 256
_leyendecker_lr_seg = * >> 8
.incbin "demo_gfx/leyendecker_lr.scr"

.align 256
_leyendecker_dlr_seg = * >> 8
.incbin "demo_gfx/leyendecker_dlr.scr"

.align 256
_leyendecker_mono_seg = * >> 8
.incbin "demo_gfx/leyendecker_mono.scr"

.align 256
_leyendecker_hr_seg = * >> 8
.incbin "demo_gfx/leyendecker_hr.scr"

.align 256
_leyendecker_dhr_seg = * >> 8
.incbin "demo_gfx/leyendecker_dhr.scr"