; _video
;
; C access for video

.export _video_page_w
.export _video_page_r

.export _video_cls
.export _video_cls_page
.export _video_page
.export _video_page_flip
.export _video_page_copy
.export _video_page_select
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
.import video_page
.import video_page_flip
.import video_page_copy
.import draw_pixel
.import draw_getpixel
.import draw_hline
.import draw_vline
.import draw_box
.import draw_fillbox
.import blit_tile
.import blit_coarse
.import blit_fine
.import blit_mask

.import video_page_w
.import video_page_r
.import draw_xh

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

; void video_page()
_video_page = video_page

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
	jmp video_page
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
