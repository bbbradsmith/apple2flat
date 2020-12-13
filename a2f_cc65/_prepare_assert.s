; _prepare_assert
;
; Used to replace BRK handler with one that prints a message just before BRK.

.export _prepare_assert
.import brk_message
.import brkv
.importzp brk_message_ptr

.proc _prepare_assert
	sta brk_message_ptr+0
	stx brk_message_ptr+1
	lda #<brk_message
	sta brkv+0
	lda #>brk_message
	sta brkv+1
	rts
.endproc
