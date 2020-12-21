; _cputc
;
; C interface for cputc, separated so that text_printf can be used without rest of _conio

; void cputc (char c)
.export _cputc
.import text_out
_cputc = text_out
