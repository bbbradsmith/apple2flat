; delay
;
; C delay timer

.include "../a2f.inc"

.export _delay

.import vdelay

MS_CYCLES = CPU_RATE / 1000 ; cycles per millisecond

.proc _delay ; X:A = ms to delay
	sta a2f_temp+0
	stx a2f_temp+1
@loop:
	lda a2f_temp+0
	ora a2f_temp+1
	beq @finish
	lda a2f_temp+0
	bne :+
		dec a2f_temp+1
	:
	dec a2f_temp+0
	lda #<(MS_CYCLES-26)
	ldx #>(MS_CYCLES-26)
	jsr vdelay
	jmp @loop
@finish:
	rts
.endproc
