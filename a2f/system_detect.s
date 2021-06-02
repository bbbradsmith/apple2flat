; system_detect

.include "../a2f.inc"

.export system_type
.export _system_type
.export system_detect

system_type:
.byte SYSTEM_UNKNOWN
_system_type = system_type ; C access

; System type detection based on Apple II misc. technical note #7: Apple II Family Identification
; http://www.1000bit.it/support/manuali/apple/technotes/misc/tn.misc.07.html

.proc system_detect
	jsr @detect
	sta system_type
	rts
@detect:
	lda $FBB3
	cmp #$38
	beq @apple2
	cmp #$EA
	beq @apple2_plus
	cmp #$06
	bne @unknown
	lda $FBC0
	beq @apple2c
	cmp #$E0
	beq @apple2e_enhanced
	cmp #$EA
	beq @apple2e
@unknown:
	lda #SYSTEM_UNKNOWN
	rts
@apple2:
	lda #SYSTEM_APPLE2
	rts
@apple2_plus:
	lda #SYSTEM_APPLE2_PLUS
	rts
@apple2c:
	lda #SYSTEM_APPLE2C
	rts
@apple2e_enhanced:
	sec
	jsr $FE1F ; RTS except on IIGS which will clear carry
	bcs @apple2e
	lda #SYSTEM_APPLE2GS
	rts
@apple2e:
	lda #SYSTEM_APPLE2E
	rts
.endproc
