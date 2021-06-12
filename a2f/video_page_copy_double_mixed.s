; video_page_copy_double_mixed
;
; Shared video page copy for second half of double (80-column) text page

.export video_page_copy_double_mixed

.proc video_page_copy_double_mixed
	; TODO copy page_r to page_w
	; (only needs to copy aux page)
	rts
.endproc
