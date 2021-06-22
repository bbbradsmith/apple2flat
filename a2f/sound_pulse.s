; sound_pulse
;
; Basic pulse wave generator.

.export sound_pulse
.export sound_pulse_

.import vdelay

.importzp a2f_temp

; assert macro to ensure branches do not cross a page
.macro BP instruction_, label_
    instruction_ label_
    .assert >(label_) = >*, error, "Page crossed!"
.endmacro

.segment "ALIGN"

.align 32

; a2f_temp 1:0 = cycles-16 for first half of pulse
; a2f_temp 3:2 = cycles-16 for second half of pulse
; a2f_temp 4:Y = wave count to play
.proc sound_pulse_
@loop:
	bit $C030         ; +4
	lda a2f_temp+0    ; +3 = 7
	ldx a2f_temp+1    ; +3 = 10
	jsr vdelay        ; (X:A cycles)
	lda a2f_temp+2    ; +3 = 13
	ldx a2f_temp+3    ; +3 = 16 (first half overhead)
	bit $C030         ; +4
	jsr vdelay        ; (X:A) cycles
	dey               ; +2 = 6
	BP bne, :+        ; +2 = 8 (+3 = 9)
	dec a2f_temp+4    ; +5 = 13
	BP bpl, @loop     ; +3 = 16 (second half overhead, branch 1)
	rts
:
	nop               ; +2 = 11
	nop               ; +2 = 13
	jmp @loop         ; +3 = 16 (second half overhead, branch 2)
.endproc

.segment "CODE"

.proc sound_pulse
	; 16-cycle overhead
	lda a2f_temp+0
	sec
	sbc #<16
	sta a2f_temp+0
	lda a2f_temp+1
	sbc #>16
	sta a2f_temp+1
	lda a2f_temp+2
	sec
	sbc #<16
	sta a2f_temp+2
	lda a2f_temp+3
	sbc #>16
	sta a2f_temp+3
	jmp sound_pulse_ ; do pulse
.endproc
