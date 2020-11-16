; _write
;
; Provides output for printf. Ignores file pointer, always prints to current video mode text output.

.export _write

.importzp ptr1
.importzp ptr2
.import incsp2
.import popptr1

.import text_out

.proc _write
	; X:A = count
	; C-stack: buffer pointer
	; C-stack: file descriptor pointer
	sta ptr2+0 ; count to ptr0
	stx ptr2+1
	jsr popptr1 ; buffer to ptr1
	jsr incsp2 ; discard the file descriptor
	lda ptr2+0
	ora ptr2+1
	bne loop
	rts ; 0 count
loop:
	ldy #0
	lda (ptr1), Y
	jsr text_out
	; increment buffer pointer
	inc ptr1+0
	bne :+
		inc ptr1+1
	:
	; decrement counter
	lda ptr2+0
	bne :+
		lda ptr2+1
		dec ptr2+1
	:
	dec ptr2+0
	bne loop
	lda ptr2+1
	bne loop
	rts
.endproc
