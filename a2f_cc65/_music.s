; _music
;
; C interface for music.

.export _music_command
.export _music_play

.import popax
.import music_command
.import music_play

.import music_data

; void music_command(uint8 command)
_music_command = music_command

; void music_play(void* data, uint8 mode)
.proc _music_play
	pha
	jsr popax
	sta music_data+0
	stx music_data+1
	pla
	jmp music_play
.endproc
