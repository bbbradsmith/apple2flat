; screen_load_double
;
; Extends screen_load for double resolutions

.export screen_load_double
.export _screen_load_double

.importzp a2f_temp
.import temp_page
.import video_h
.import video_page_w

.import screen_load
.import screen_load_sector_
.import screen_load_count_

.proc screen_load_double
	jsr screen_load
	lda video_h
	cmp #104
	bcs @high
@low:
	lda video_page_w
	and #$0C
	eor #$04
	sta a2f_temp+7
	lda #4
	jmp @ready
@high:
	lda video_page_w
	and #$60
	eor #$20
	sta a2f_temp+7
	lda #32
@ready:
	sta screen_load_count_
@loop:
	jsr screen_load_sector_
	sta $C005 ; aux (RAMWRT)
	ldy #0
	:
		lda temp_page, Y
		sta (a2f_temp+6), Y
		iny
		cpy #120
		bcc :-
	ldy #128
	:
		lda temp_page, Y
		sta (a2f_temp+6), Y
		iny
		cpy #248
		bcc :-
	sta $C004 ; main (RAMWRT)
	inc a2f_temp+7
	dec screen_load_count_
	bne @loop
	rts
.endproc

_screen_load_double = screen_load_double

