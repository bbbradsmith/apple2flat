; _music
;
; C interface for music.

.export _music_command
.export _music_play
.export _music_resume
.export _music_reset

.import popax
.import music_command
.import music_play
.import music_resume
.import music_reset

.import music_data

; void music_command(uint8 command)
_music_command = music_command

; uint8 music_play(void* data, uint8 mode)
.proc _music_play
	pha
	jsr popax
	sta music_data+0
	stx music_data+1
	pla
	jsr music_play
	ldx #0
	lda music_data+1
	rts
.endproc

; uint8 music_resume(uint8 mode)
_music_resume = music_resume

; void music_reset()
_music_reset = music_reset
