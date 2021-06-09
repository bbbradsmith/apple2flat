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
	beq @apple2p
	cmp #$06
	bne @unknown
	lda $FBC0
	beq @apple2c
	cmp #$E0
	beq @apple2ee
	cmp #$EA
	beq @apple2e
@unknown:
	lda #SYSTEM_UNKNOWN
	rts
@apple2:
	lda #SYSTEM_APPLE2
	rts
@apple2p:
	lda #SYSTEM_APPLE2P
	rts
@apple2e:
	lda #SYSTEM_APPLE2E
	rts
@apple2c:
	lda #SYSTEM_APPLE2C
	rts
@apple2ee:
	sec
	jsr $FE1F ; RTS except on IIGS which will clear carry
	bcc @apple2gs
	lda #SYSTEM_APPLE2EE
	rts
@apple2gs:
	lda #SYSTEM_APPLE2GS
	rts
.endproc
