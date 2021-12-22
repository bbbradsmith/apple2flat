; A2F library public interface

; 8 bytes of temporary space on zero-page
.globalzp a2f_temp

;
; System
;

.enum
SYSTEM_UNKNOWN     = 0
SYSTEM_APPLE2      = 1
SYSTEM_APPLE2P     = 2
SYSTEM_APPLE2E     = 3
SYSTEM_APPLE2EE    = 4
SYSTEM_APPLE2C     = 5
SYSTEM_APPLE2GS    = 6
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

; Average rate of CPU cycle (14,318,180 Hz divided by 14 on 64/65 cycles, and 16 on the 65th)
; Reference: Understanding the Apple II, Jim Sather 1983. Section 3-3.
CPU_RATE = 1020484

;
; Keyboard
;

KBDATA = $C000 ; Read: bit 7 = new keypress, bits 6-0 = last key
KBSTAT = $C010 ; Read: bit 7 = any keys down (IIe/IIc only), clears new keypress flag in $C000

KB_ESC    = $1B
KB_TAB    = $09
KB_DELETE = $7F
KB_RETURN = $0D
KB_SPACE  = $20
KB_LEFT   = $08
KB_RIGHT  = $15
KB_UP     = $0B
KB_DOWN   = $0A

; kb_field control variables
.global kb_field_cursor ; tile to use for field cursor
.global kb_field_cursor_rate ; blink speed for field cursor (lower = faster)

; kb_field text input field subroutine
.global kb_field ; Y = len, a2f_temp+0,1 = buffer pointer
; buffer is of size len, to be null terminated. len-1 characters will be shown for editing.
; All normal characters are accepted.
; Left and Right will move through the input. Delete will move the cursor left and truncate.
; Escape, Return, Tab, Up, or Down will all return with the relevant keycode.
; (You could use the return value to switch to another field, decide to accept or cancel, etc.
; and if you only want to accept e.g. Return you could loop kb_field until you get Return.)
; This will only work with single-buffered video: make sure the write and display pages are the same.

;
; Paddle
;

; buttons
; NOTE: Unconnected buttons may be erratic or always report as set.
;       On IIe, B0/B1 are always connected as keys, but B2 is likely unconnected.
PADDLE_B0 = $01
PADDLE_B1 = $02
PADDLE_B2 = $01

; paddle axis results are approximately 0-70, centre at around 32, right side range is slightly wider
; 128 indicates a timeout, no paddle connected (avoid continually polling a disconnected paddle)
; low/high are recommended thresholds
PADDLE_CENTER = 32
PADDLE_LOW    = 16
PADDLE_HIGH   = 52

; variables updated by poll
.global paddle0_b ; B1, B0
.global paddle1_b ; B2
.global paddle0_x
.global paddle0_y
.global paddle1_x
.global paddle1_y

; poll routines
.global paddleb_poll        ; poll only paddle buttons, paddle0_b result loaded in A/flags (X=0)
.global paddle0_poll        ; poll paddle0 and buttons (avg 1.5ms, max 3ms, 5ms if timeout)
.global paddle01_poll       ; poll both paddles and buttons (avg 3ms, max 6ms, 10ms if both timeout)

;
; Sound
;

.global sound_square ; a2f_temp+1:0 = cycles in full wave, a2f_temp+4:Y = repetitions
.global sound_pulse ; a2f_temp+1:0, a2f_temp+3:2 = cycles in each half of wave, a2f_temp+4:Y = repetitions
.global sound_noise ; a2f_temp+1:0 = cycles between random speaker flips, a2f_temp+4:Y = repetitions
.global sound_sweep ; a2f_temp+1:0 = cycles in full wave, a2f_temp+4:Y = max repetitions, A = speed 1-16 (16=slowest)
; sound_square: minimum 90cy
; sound_pulse: minimum 45cy per half
; sound_noise: minimum 74cy

; music command format:
; $00    = halt music / reset
; $01    = rest
; $02-0C = repeat 2x-13x
; $0D    = loop
; $0E    = set repeat point
; $0F    = set loop point
; $10    = noise
; $11    = square (pulse 1/2)
; $12    = pulse 1/4
; $13    = pulse 1/8
; $14    = pulse 1/16
; $15    = pulse 1/32
; $16    = pulse 1/64
; $17-1F = set octave
; $20-5F = note duration ($5F = 1 second, $20 = 1/64th, $21 = 2/64th...
; $60-6B = note at last octave
; $70-FB = direct notes $XY = octave X-7, pitch Y, $B0 = middle C
; (unused note values ($XC-XF) are reserved and will cause a halt/reset)
; $FE    = no-effect
; $FF    = first of 2-byte command:
; $FF, $00    = halt music / reset
; $FF  $01    = space duration 0
; $FF, $20-5F = space duration (extra rest that follows any note or rest)
; $FF, $FE    = no-effect ($FE can be used to ensure not in second-byte mode)
; $FF, $FF    = halt music / reset
; (unused values are reserved and will cause a halt/reset)

.global music_raset ; resets music commands to default state
.global music_command ; A = command
.global music_play ; A = mode, music_data = pointer to string of commands
.global music_resume ; A = mode, music_data = pointer to string of commands (skips reset)
; mode 0: stop only at halt
; mode 1: stop at halt or keypress (does not read keypress, leaves it pending)
; mode 2: stop at halt, keypress, or joystick buttons 0/1
; (music_data is set to 0 at a halt command,
; but if user-halted in mode 1/2 you can use music_resume to continue.
; If music_data is 0, music_resume or music_play will return immediately.)

.global music_data ; 16-bit pointer to data for music_play (pointing to zero page is not allowed)

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

; TODO drive select?

;
; Tape
;

; TODO

;
; Video
;

; pages for video_cls_page
CLS_LOW0    = 0 ; text 40 / low-res first page
CLS_LOW1    = 1 ;                   second page
CLS_HIGH0   = 2 ; high-res
CLS_HIGH1   = 3
CLS_MIXED0  = 4 ; mixed text area
CLS_MIXED1  = 5
CLS_DLOW0   = 6 ; IIe double resolutions
CLS_DLOW1   = 7
CLS_DHIGH0  = 8
CLS_DHIGH1  = 9
CLS_DMIXED0 = 10
CLS_DMIXED1 = 11

; low/double-low resolution colours
COL_BLACK       = 0
COL_MAGENTA     = 1
COL_BLUE_DARK   = 2
COL_PURPLE      = 3
COL_GREEN_DARK  = 4
COL_GREY0       = 5
COL_BLUE_MID    = 6
COL_BLUE_LIGHT  = 7
COL_BROWN       = 8
COL_ORANGE      = 9
COL_GREY1       = 10
COL_PINK        = 11
COL_GREEN_LIGHT = 12
COL_YELLOW      = 13
COL_AQUAMARINE  = 14
COL_WHITE       = 15

; high resolution colours
COH_BLACK0      = $00
COH_PURPLE      = $01
COH_GREEN       = $02
COH_WHITE0      = $03
COH_BLACK1      = $80
COH_BLUE        = $81
COH_ORANGE      = $82
COH_WHITE1      = $83

; monochrome colours
COM_BLACK       = 0
COM_WHITE       = 1

; double-high resolution colours
COD_BLACK       = 0
COD_BLUE_DARK   = 1
COD_GREEN_DARK  = 2
COD_BLUE_MID    = 3
COD_BROWN       = 4
COD_GREY1       = 5
COD_GREEN_LIGHT = 6
COD_AQUAMARINE  = 7
COD_MAGENTA     = 8
COD_PURPLE      = 9
COD_GREY0       = 10
COD_BLUE_LIGHT  = 11
COD_ORANGE      = 12
COD_PINK        = 13
COD_YELLOW      = 14
COD_WHITE       = 15

; variables
.global video_w         ; (16-bit) pixel dimensions of current video mode
.global video_h         ; (8-bit)
.global video_text_x    ; text_out position (16-bit x, 8-bit y)
.global video_text_y
.global video_text_w    ; right side of text area (x wrap, 16-bit)
.global video_text_h    ; bottom of text area (y wrap, 8-bit)
.global video_text_xr   ; left side of text area (after x wrap, 16-bit)
.global video_text_yr   ; top of text area (8-bit)
.global video_page_w    ; page to write/draw: 00 page 1, FF page 2
.global video_page_r    ; page to read/display
.global text_inverse    ; $80 = normal text, $00 = inverse text
.global draw_x0 ; parameters/temporaries for drawing functions
.global draw_x1
.global draw_y0
.global draw_y1
.global draw_xh ; high byte for draw_pixel, alias of: draw_x0+1
.global text_fontset ; pointer to high-resolution font set
.global text_fontset_width ; pointer to nibble-packed widths for VWF glyphs
.global text_fontset_offset ; ASCII offset to beginning of font set (usually $20)

; select video mode driver
.global video_mode_text
.global video_mode_low
.global video_mode_low_mixed
.global video_mode_high_mono
.global video_mode_high_mono_mixed
.global video_mode_high_color
.global video_mode_high_color_mixed
; double video modes (80-column/IIe/IIc/IIGS)
.global video_mode_double_text
.global video_mode_double_low
.global video_mode_double_low_mixed
.global video_mode_double_high_mono
.global video_mode_double_high_mono_mixed
.global video_mode_double_high_color
.global video_mode_double_high_color_mixed
; half-double video modes (non-double graphics with 80-column text)
.global video_mode_high_color_double_mixed
.global video_mode_high_mono_double_mixed
.global video_mode_low_double_mixed
; high/double-high resolution with no text support
.global video_mode_high_mono_notext
.global video_mode_high_color_notext
.global video_mode_double_high_mono_notext
.global video_mode_double_high_color_notext
; high resolution with variable width software-font
.global video_mode_high_mono_vwf
.global video_mode_high_color_vwf

.global video_cls ; clear current write screen with an appropriate value
.global video_cls_page ; X = screen, A = fill value. clear one of the 4 screen memory areas
.global video_page ; applies  video_page_r / video_page_w
.global video_page_flip ; flips and applies video_page_r / video_page_w
.global video_page_copy ; copies video_page_r to video_page_w

.global vsync ; TODO

.global draw_pixel ; A = color, h:X,Y = coordinate (draw_xh for high byte of X if needed)
.global draw_getpixel ; X,Y = coordinate, returns value in A
.global draw_hline ; draw_x0,y0 = left pixel, draw_x1 = right pixel + 1, A = color
.global draw_vline
.global draw_box
;.global draw_fillbox
;.global draw_line ; TODO
;.global draw_ellipse ; TODO
.global blit ; X,Y = coordinate, a2f_temp+3:2 = data

.global text_out ; A = character
.global text_scroll ; A = signed value, positive = lines to shift up (clear bottom), negative = lines to shift down (clear top)
.global text_charset ; A = 0 primary character set, 1 alternate character set (IIe)

; set text/border colours on IIGS only
.global iigs_color ; A = text FG, X = text BG, Y = border (low-resolution colour values)

;
; Misc
;

.import vdelay ; delays for X:A cycles, minimum: 29 (includes jsr), A/X clobbered (X=0)
