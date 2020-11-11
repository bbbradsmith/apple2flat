; exit

.export exit
; X:A = exit code
; Re-initializes the monitor, prints the exit code, then enters the monitor * prompt.

exit:
	pha
	txa
	pha
	; the original monitor RESET calls these 4 routines
	jsr $FE84 ; SETNORM
	jsr $FB2F ; INIT
	jsr $FE93 ; SETVID
	jsr $FE89 ; SETKBD
	; newline, then print exit code and enter monitor * prompt
	jsr $FD8E ; CROUT newline
	pla
	jsr $FDDA ; PRBYTE hex display
	pla
	jsr $FDDA
	jsr $FD8E
	jmp $FF69 ; MONZ monitor * prompt
