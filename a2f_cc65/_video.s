; _video
;
; C access for video

.export _video_text_x
.export _video_text_y
.export _video_text_w
.export _video_text_h
.export _video_text_xr
.export _video_text_yr
.export _video_page_w
.export _video_page_r
.export _text_inverse

.export _video_cls
.export _video_cls_page
.export _text_out
.export _text_scroll
.export _text_window
.export _draw_pixel
.export _draw_getpixel
.export _draw_hline
.export _draw_vline
.export _draw_box
.export _draw_fillbox
.export _blit_tile
.export _blit_coarse
.export _blit_fine
.export _blit_mask

.import popa
.import popax
.import video_cls
.import video_cls_page
.import text_out
.import text_scroll
.import draw_pixel
.import draw_getpixel
.import draw_hline
.import draw_vline
.import draw_rect
.import draw_box
.import blit_tile
.import blit_coarse
.import blit_fine
.import blit_mask

.import video_text_x
.import video_text_y
.import video_text_w
.import video_text_h
.import video_text_xr
.import video_text_yr
.import video_page_w
.import video_page_r
.import text_inverse
.import draw_xh

_video_text_x = video_text_x
_video_text_y = video_text_y
_video_text_w = video_text_w
_video_text_h = video_text_h
_video_text_xr = video_text_xr
_video_text_yr = video_text_yr
_video_page_w = video_page_w
_video_page_r = video_page_r
_text_inverse = text_inverse

; void video_cls()
_video_cls = video_cls

; void text_out(char c)
_text_out = text_out

; void text_scroll(sint8 lines)
_text_scroll = text_scroll

; void text_window(uint8 x0, uint8 y0, uint8 x1, uint8 y1)
.proc _text_window
	sta video_text_h
	jsr popa
	sta video_text_w
	jsr popa
	sta video_text_yr
	jsr popa
	sta video_text_xr
	; make sure within bounds
	lda video_text_x
	cmp video_text_xr
	bcc reset_position
	cmp video_text_w
	bcs reset_position
	lda video_text_y
	cmp video_text_yr
	bcc reset_position
	cmp video_text_h
	bcs reset_position
	rts
reset_position:
	lda video_text_xr
	sta video_text_x
	lda video_text_yr
	sta video_text_y
	rts
.endproc

; void video_cls_page(uint8 page, uint8 fill)
_video_cls_page:
	pha
	jsr popa
	tax
	pla
	jmp video_cls_page

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

; uint8 draw_getpixel(uint16 x, uint8 y, uint8 c)
_draw_getpixel:
	pha
	jsr popa
	pha
	jsr popax
	stx draw_xh
	tax
	pla
	tay
	pla
	jsr draw_getpixel
	ldx #0 ; cc65 8-bit returns must have X=0
	rts

_draw_hline:
	; TODO
	rts

_draw_vline:
	; TODO
	rts

_draw_box:
	; TODO
	rts

_draw_fillbox:
	; TODO
	rts

_blit_tile:
	; TODO
	rts

_blit_coarse:
	; TODO
	rts

_blit_fine:
	; TODO
	rts

_blit_mask:
	; TODO
	rts
