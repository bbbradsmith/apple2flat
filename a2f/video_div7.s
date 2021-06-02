; video_div7
;
; Table for division / modulo 7, used for high resolution pixel resolving.

.export video_div7

; low 3 bits  = X % 7
; high 5 bits = X / 7
video_div7:
.repeat 140, I
	.byte ((I/7)<<3)|(I .mod 7)
.endrepeat
