; video_double
;
; Shared routines for double video modes.

.export video_double_rw_aux_setup
.export video_double_read_aux ; safely reads (draw_ptr), Y from auxiliary memory
;.export video_double_write_aux ; safely writes A to (draw_ptr), Y in auxiliary memory

.importzp draw_ptr

.segment "CODE"
; code to be copied to ZP
video_double_read_aux_: ; reads from (draw_ptr), Y in auxiliary memory
	sta $C003 ; aux (RAMRD)
	lda (draw_ptr), Y
	sta $C002 ; main (RAMRD)
	rts
;video_double_write_aux_: ; writes to (draw_ptr), Y in auxiliary memory
;	sta $C005 ; aux (RAMWRT)
;	sta (draw_ptr), Y
;	sta $C004 ; main (RAMWRT)
;	rts
VIDEO_DOUBLE_ZPCODE_SIZE = * - video_double_read_aux_

.segment "LOWZP"
; code to be run from ZP
video_double_read_aux: .res VIDEO_DOUBLE_ZPCODE_SIZE
;video_double_write_aux = video_double_read_aux + (video_double_write_aux_ - video_double_read_aux_)

.segment "CODE"

video_double_rw_aux_setup:
	ldx #0
	:
		lda video_double_read_aux_, X
		sta video_double_read_aux, X
		inx
		cpx #VIDEO_DOUBLE_ZPCODE_SIZE
		bcc :-
	rts
