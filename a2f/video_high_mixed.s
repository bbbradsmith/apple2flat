; video_high_mixed
;
; Common routines for high resolution mixed modes

.include "../a2f.inc"

.export video_page_copy_high_mixed
.export video_cls_high_mixed

.import video_cls_page

.proc video_page_copy_high_mixed
	; TODO
	rts
.endproc

.proc video_cls_high_mixed
	; reset cursor
	lda video_text_xr
	sta video_text_x
	lda video_text_yr
	sta video_text_y
	; clear graphics
	lda video_page_w
	and #1
	eor #CLS_HIGH0
	tax
	lda #0
	jsr video_cls_page
	; clear mixed text
	lda video_page_w
	and #1
	eor #CLS_MIXED0
	tax
	lda #$A0 ; space, normal
	jmp video_cls_page
.endproc
