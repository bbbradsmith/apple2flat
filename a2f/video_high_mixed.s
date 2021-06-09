; video_high_mixed
;
; Common routines for high resolution mixed modes

.include "../a2f.inc"

.export video_page_high_mixed
.export video_page_copy_high_mixed
.export video_cls_high_mixed

.import video_page_apply
.import video_cls_page

.proc video_page_high_mixed
	; set mode
	sta $C050 ; graphics mode (TEXT)
	sta $C053 ; mixed (MIXED)
	sta $C057 ; high-res (HIRES)
	; disable double mode
	sta $C00C ; 40 columns (80COL)
	sta $C07E ; enable DHIRES switch (IOUDIS)
	sta $C05F ; double-hires off (AN3/DHIRES)
	jmp video_page_apply
.endproc

.proc video_page_copy_high_mixed
	; TODO
	rts
.endproc

.proc video_cls_high_mixed ; TODO make common and more succinct
	lda video_page_w
	and #1
	eor #CLS_HIGH0
	tax
	lda #0
	jsr video_cls_page
	; TODO TEXT0
	lda video_page_w
	and #1
	eor #CLS_LOW0
	tax
	lda #$A0
	jmp video_cls_page
.endproc
