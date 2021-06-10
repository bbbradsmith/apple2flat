; video_double_high
;
; Common routines for double-high resolution grpahics

.include "../a2f.inc"

.export video_cls_double_high
.export video_page_copy_double_high

.proc video_page_copy_double_high
	; TODO copy page_r to page_w
	rts
.endproc

.proc video_cls_double_high
	lda video_page_w
	and #1
	eor #CLS_DHIGH0
	tax
	lda #0
	jmp video_cls_page
.endproc
