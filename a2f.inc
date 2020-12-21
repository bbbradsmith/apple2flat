; A2F library public interface

; 4 bytes of temporary space on zero-page
.globalzp a2f_temp

;
; System
;

.enum
SYSTEM_UNKNOWN     = 0
SYSTEM_APPLE2      = 1
SYSTEM_APPLE2_PLUS = 2
SYSTEM_APPLE2E     = 3
SYSTEM_APPLE2C     = 4
.endenum
.global system_type ; set to one of the enums above at startup

.global exit ; X:A = exit code, prints error code and enters monitor * prompt
.global zero_intialize ; call at start to clear uninitialized RAM regions (not including stack, use STACK_INITIALIZE instead)
.global system_detect ; call to set up system_type

; user after zero_initialize to set up the stack
.macro STACK_INITIALIZE
	ldx #0
	txa
	:
	sta $100, X
	inx
	bne :-
	dex ; $FF
	txs
.endmacro

;
; Keyboard
;

KBDATA = $C000 ; Read: bit 7 = new keypress, bits 6-0 = last key
KBSTAT = $C010 ; Read: bit 7 = any keys down (IIc/IIe only), clears new keypress flag in $C000

;
; Video
;

; constants
CLS_LOW0  = 0 ; text 40 / low-res first page
CLS_LOW1  = 1 ;                   second page
CLS_HIGH0 = 2 ; high-res
CLS_HIGH1 = 3

; variables
.global video_text_x    ; text_out position
.global video_text_y
.global video_text_w    ; right side of text area (x wrap)
.global video_text_h    ; bottom of text area (y wrap)
.global video_text_xr   ; left side of text area (after x wrap)
.global video_text_yr   ; top of text area (after y wrap)
.global video_page_w    ; page to write/draw: 00 page 1, FF page 2
.global video_page_r    ; page to read/display
.global text_inverse    ; $80 = normal text, $00 = inverse text

; select video mode driver
.global video_mode_text
.global video_mode_low ; TODO
.global video_mode_low_mixed ; TODO
.global video_mode_high ; TODO
.global video_mode_high_mixed ; TODO

.global video_cls ; clear current write screen with an appropriate value
.global video_cls_page ; X = screen, A = fill value. clear one of the 4 screen memory areas
.global video_page ; TODO ; select write and read page
.global video_page_flip ; TODO
.global video_page_copy ; TODO

.global draw_pixel
.global draw_getpixel
.global draw_hline ; TODO
.global draw_vline ; TODO
.global draw_box ; TODO
.global draw_fillbox ; TODO
.global draw_ellipse ; TODO

.global text_printf ; TODO
.global text_out
.global text_scroll
.global text_charset ; TODO

.global blit_tile ; TODO
.global blit_coarse ; TODO
.global blit_fine ; TODO
.global blit_mask ; TODO

;
; Floppy disk
;

.enum
DISK_ERROR_FIND    = $01 ; could not find sector
DISK_ERROR_DATA    = $02 ; found sector, but could not find data field
DISK_ERROR_PARTIAL = $04 ; sector read but only partially correct (checksum fail)
.endenum

.globalzp disk_ptr ; parameter for disk_read, alias of a2f_temp
.global disk_error ; last error code from disk routine

.global disk_read ; X:A = segment to read, Y = segment count, disk_ptr = destination, returns disk_error
.global disk_write ; TODO write sector
.global disk_format ; TODO format track

;
; Misc
;

.import vdelay ; delays for X:A cycles, minimum: 29 (includes jsr), A/X clobbered (X=0)
