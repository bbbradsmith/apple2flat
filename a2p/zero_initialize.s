; zero_initialize

.export zero_initialize
; Initializes the following regions to zero:
;   zero page
;   LOWRAM
;   RAM
;   MAIN region following code
;   DISKREAD region following code
; Does not initialize stack, since it must RTS.

.segment "CODE"

.proc zero_initialize
ZI_START = $00
ZI_END   = $02
	; initialize all regions in the table
	ldx #0
	ldy #0
region:
	cpx REGION_END
	bcs finish
	lda region_table, X
	inx
	sta ZI_START+0
	lda region_table, X
	inx
	sta ZI_START+1
	lda region_table, X
	inx
	sta ZI_END+0
	lda region_table, X
	inx
	sta ZI_END+1
loop:
	tya
	sta (ZI_START), Y
	inc ZI_START+0
	bne :+
		inc ZI_START+1
	:
	lda ZI_START+0
	cmp ZI_END+0
	lda ZI_START+1
	sbc ZI_END+1
	bcc loop
	jmp region
finish:
	; clear zero page
	lda #0
	tax
	:
		sta z:0, X
		inx
		bne :-
	rts
; table of regions to clear
.import __LOWRAM_START__
.import __LOWRAM_SIZE__
.import __RAM_START__
.import __RAM_SIZE__
.import __MAIN_LAST__
.import __DISKREAD_START__
.import __DISKREAD_SIZE__
.import __DISKSYS_RUN__
.import __DISKSYS_SIZE__
region_table:
	.word __LOWRAM_START__, __LOWRAM_START__ + __LOWRAM_SIZE__
	.word __RAM_START__, __RAM_START__ + __RAM_SIZE__
	.word __MAIN_LAST__, __DISKREAD_START__
	.word __DISKSYS_RUN__ + __DISKSYS_SIZE__, __DISKREAD_START__ + __DISKREAD_SIZE__
REGION_END = * - region_table
.endproc

