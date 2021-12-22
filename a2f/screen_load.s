; screen_load
;
; Loading routine for screen images, stored as raw data but 120 of 128 byte rows.
; Non-double resolutions

.export screen_load
.export _screen_load

.export screen_load_sector_
.export screen_load_count_

.importzp a2f_temp
.importzp disk_ptr ; a2f_temp+2
.import temp_page
.import video_h
.import video_page_w

.import disk_read ; X:A = sector to read, Y = sector count, disk_ptr = destination,

screen_load_count_: .res 1

.proc screen_load_sector_
	lda #<temp_page ; destination
	sta disk_ptr+0
	lda #>temp_page
	sta disk_ptr+1
	lda a2f_temp+4 ; sector
	ldx a2f_temp+5
	ldy #1
	jsr disk_read
	inc a2f_temp+4 ; next sector
	bne :+
		inc a2f_temp+5
	:
	rts
.endproc

.proc screen_load ; X:A = sector
	sta a2f_temp+4 ; sector
	stx a2f_temp+5
	lda #0
	sta a2f_temp+6
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
	inc a2f_temp+7
	dec screen_load_count_
	bne @loop
	rts
.endproc

_screen_load = screen_load
