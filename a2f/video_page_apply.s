; video_page_apply
;
; Shared routine for selecting video page

.export video_page_apply

.import video_page_r

.proc video_page_apply
	lda video_page_r
	and #1
	tax
	sta $C054, X ; (PAGE2)
	rts
.endproc
