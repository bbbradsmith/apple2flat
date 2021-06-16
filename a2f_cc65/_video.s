; _video
;
; C access for video

.export _video_w
.export _video_h
.export _video_page_w
.export _video_page_r

.export _video_cls
.export _video_cls_page
.export _video_page_apply
.export _video_page_flip
.export _video_page_copy
.export _video_page_select
.export _draw_pixel
.export _draw_getpixel
.export _draw_hline
.export _draw_vline
.export _draw_box
.export _draw_fillbox
.export _blit_coarse
.export _blit_fine
.export _blit_mask

.import popa
.import popax
.import video_cls
.import video_cls_page
.import video_page_apply
.import video_page_flip
.import video_page_copy
.import draw_pixel
.import draw_getpixel
.import draw_hline
.import draw_vline
.import draw_box
.import draw_fillbox
.import blit_coarse
.import blit_fine
.import blit_mask

.import video_w
.import video_h
.import video_page_w
.import video_page_r
.import draw_x0
.import draw_x1
.import draw_y0
.import draw_y1
.import draw_xh

.importzp a2f_temp

_video_w = video_w
_video_h = video_h
_video_page_w = video_page_w
_video_page_r = video_page_r

; void video_cls()
_video_cls = video_cls

; void video_cls_page(uint8 page, uint8 fill)
_video_cls_page:
	pha
	jsr popa
	tax
	pla
	jmp video_cls_page

; void video_page_apply()
_video_page_apply = video_page_apply

; void video_page_flip()
_video_page_flip = video_page_flip

; void video_page_copy()
_video_page_copy = video_page_copy

; void video_page_select(uint8 read, uint8 write)
_video_page_select:
	jsr @boolify
	sta video_page_w
	jsr popa
	jsr @boolify
	sta video_page_r
	jmp video_page_apply
@boolify:
	cmp #0
	beq :+
		lda #$FF
	:
	rts

; void draw_pixel(uint16 x, uint8 y, uint8 c)
_draw_pixel:
	pha
	jsr popa
	pha
	jsr popax
	stx draw_xh
	tax
	pla
	tay
	pla
	jmp draw_pixel

; uint8 draw_getpixel(uint16 x, uint8 y)
_draw_getpixel:
	pha
	jsr popax
	stx draw_xh
	tax
	pla
	tay
	jsr draw_getpixel
	ldx #0 ; cc65 8-bit returns must have X=0
	rts

; void draw_hline(uint16 x, uint8 y, uint16 w, uint8 c)
_draw_hline:
	pha
	jsr popax ; w
	sta a2f_temp+0
	stx a2f_temp+1
	jsr popa ; y
	sta draw_y0
	jsr popax ; x
	sta draw_x0+0
	stx draw_x0+1
	clc
	adc a2f_temp+0
	sta draw_x1+0 ; x+w
	txa
	adc a2f_temp+1
	sta draw_x1+1
	pla ; c
	jmp draw_hline

; void draw_vline(uint16 x, uint8 y, uint8 h, uint8 c)
_draw_vline:
	pha
	jsr popa ; h
	sta a2f_temp+0
	jsr popa ; y
	sta draw_y0
	clc
	adc a2f_temp+0
	sta draw_y1
	jsr popax ; x
	sta draw_x0+0
	stx draw_x0+1
	pla ; c
	jmp draw_vline

; void draw_box(uint16 x, uint8 y, uint16 w, uint8 h, uint8 c)
_draw_box:
	pha
	jsr popa ; h
	sta a2f_temp+2
	jsr popax ; w
	sta a2f_temp+0
	stx a2f_temp+1
	jsr popa ;y
	sta draw_y0
	clc
	adc a2f_temp+2
	sta draw_y1 ; y+h
	jsr popax ; x
	sta draw_x0+0
	stx draw_x0+1
	clc
	adc a2f_temp+0
	sta draw_x1+0 ; x+w
	txa
	adc a2f_temp+1
	sta draw_x1+1
	pla ; c
	jmp draw_box

; void draw_fillbox(uint16 x, uint8 y, uint16 w, uint8 h, uint8 c)
_draw_fillbox:
	pha
	jsr popa ; h
	sta a2f_temp+2
	jsr popax ; w
	sta a2f_temp+0
	stx a2f_temp+1
	jsr popa ;y
	sta draw_y0
	clc
	adc a2f_temp+2
	sta draw_y1 ; y+h
	jsr popax ; x
	sta draw_x0+0
	stx draw_x0+1
	clc
	adc a2f_temp+0
	sta draw_x1+0 ; x+w
	txa
	adc a2f_temp+1
	sta draw_x1+1
	pla ; c
	jmp draw_fillbox

_blit_coarse:
	; TODO
	rts

_blit_fine:
	; TODO
	rts

_blit_mask:
	; TODO
	rts
