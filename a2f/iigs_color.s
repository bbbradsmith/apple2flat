; iigs_color
;
; For setting the text and border colours on IIGS

.export iigs_color

.importzp a2f_temp

.proc iigs_color ; A = text FG, X = text BG, Y = border
	; set IIGS screen color register $C022 (4-bit text FG : 4-bit text BG)
	asl
	asl
	asl
	asl
	sta a2f_temp+0
	txa
	ora a2f_temp+0
	sta $C022
	; set IIGS border color register $C034
	; using 65816-only RMW instructions to avoid disturbing the real-time clock control in high nibble
	ldx #0 ; X=0 to avoid reading other registers on 6502
	tya
	and #$0F
	tay
	lda #$0F
	.byte $1C, $34, $C0 ; trb $C034 / nop $C034, X
	tya
	.byte $0C, $34, $C0 ; tsb $C034 / nop $C034
	; NOTE: TRB/TSB should be NOPs on 6502/65C02
	rts
.endproc
