; video_mixed
;
; Shared routines for mixed video.

.export video_mode_mixed_setup

.import video_text_y
.import video_text_yr

video_mode_mixed_setup:
	lda #20
	sta video_text_y
	sta video_text_yr
	rts
