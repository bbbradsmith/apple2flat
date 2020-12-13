; exit

.export exit
; X:A = exit code
; Re-initializes the monitor, prints the exit code, then enters the monitor * prompt.

; internal components of exit:
.export exit_common_start ; resets to monitor, ready for monitor text output
.export exit_common_end   ; displays 2 hex bytes from stack then enters monitor prompt

exit_common_start:
	; the original monitor RESET calls these 4 routines
	jsr $FE84 ; SETNORM
	jsr $FB2F ; INIT
	jsr $FE93 ; SETVID
	jsr $FE89 ; SETKBD
	jmp $FD8E ; CROUT newline

exit:
	pha
	txa
	pha
	jsr exit_common_start
exit_common_end: ; (exit code on stack)
	; print exit code and enter monitor * prompt
	pla
	jsr $FDDA ; PRBYTE hex display
	pla
	jsr $FDDA
	jsr $FD8E ; CROUT newline
	jmp $FF69 ; MONZ monitor * prompt
