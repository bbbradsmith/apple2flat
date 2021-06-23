#ifndef A2F_H
#define A2F_H

#include <stdint.h>
#include <stdarg.h>

typedef uint16_t uint16;
typedef int16_t  sint16;
typedef uint8_t  uint8;
typedef int8_t   sint8;

//
// System
//

// system type detected at startup
#define SYSTEM_UNKNOWN      0
#define SYSTEM_APPLE2       1
#define SYSTEM_APPLE2P      2
#define SYSTEM_APPLE2E      3
#define SYSTEM_APPLE2EE     4
#define SYSTEM_APPLE2C      5
#define SYSTEM_APPLE2GS     6
extern uint8 system_type;

// exits to monitor with program counter display
#define FATAL() { asm ("BRK"); }

// ASSERT that acts like a conditional FATAL with a custom message
// Define NDEBUG to remove asserts for a release build.
#ifdef NDEBUG
#define ASSERT(condition_,message_) {}
#else
extern void prepare_assert(const char* message);
#define ASSERT(condition_,message_) { if(!(condition_)) { prepare_assert((message_)); FATAL(); } }
#endif

// Average rate of CPU cycle (14,318,180 Hz divided by 14 on 64/65 cycles, and 16 on the 65th)
// Reference: Understanding the Apple II, Jim Sather 1983. Section 3-3.
#define CPU_RATE  1020484

// TODO
// query avaiable RAM pages
// RAM banking

//
// Keyboard
//

// some useful key codes

#define KB_ESC    0x1B
#define KB_TAB    0x09
#define KB_DELETE 0x7F
#define KB_RETURN 0x0D
#define KB_SPACE  0x20

#define KB_LEFT   0x08
#define KB_RIGHT  0x15
#define KB_UP     0x0B
#define KB_DOWN   0x0A

// Other keycodes can be identified by their ASCII char, e.g. 'A' for A key.
// Control, Shift and Capslock are not keypresses, but modify the result of other keys.
// The modification depends on the key, but example for letters:
//   K = 0x4B 'K'      (shift on)
//   K = 0x6B 'k'      (shift off)
//   K = 0x0B up arrow (control on)

char kb_new(); // 1 if a new key has been pressed (does not cancel pending)
char kb_get(); // wait for kb_new (if not already pending) and return keycode
char kb_last(); // last pressed keycode (doesn't matter if kb_new was cancelled)
uint8 kb_data(); // direct read from $C000 (bit 7 = pending new, 6-0 = keycode)
char kb_any(); // reads $C010, cancels any pending kb_new, returns 1 if any keys are currently held
// NOTE: kb_any always returns 0 on Apple II models prior to Apple IIe/IIc

// TODO not implemented yet
// kb_field text input field
extern uint8 kb_field_cursor; // tile to use for field cursor
extern uint8 kb_field_cursor_rate; // blink speed for field cursor (lower = faster)
char kb_field(char* field, uint8 len);
// field is a buffer of size len, to be null terminated. len-1 characters will be shown for editing.
// All normal characters are accepted.
// Left and Right will move through the input. Delete will move the cursor left and truncate.
// Escape, Return, Tab, Up, or Down will all return with the relevant keycode.
// (You could use the return value to switch to another field, decide to accept or cancel, etc.
// and if you only want to accept e.g. Return you could loop kb_field until you get Return.)
// This will only work with single-buffered video: make sure the write and display pages are the same.

//
// Paddle
//

// paddle button mask
// NOTE: Unconnected buttons may be erratic or always report as set.
//       On IIe, B0/B1 are always connected as keys, but B2 is likely unconnected.
#define PADDLE_B0            0x01
#define PADDLE_B1            0x02
#define PADDLE_B2            0x01

// paddle axis results are approximately 0-70, centre at around 32, right side range is slightly wider
// 128 indicates a timeout, no paddle connected (avoid continually polling a disconnected paddle)
// low/high are recommended thresholds
#define PADDLE_CENTER        32
#define PADDLE_LOW           16
#define PADDLE_HIGH          52

// paddle poll result
extern uint8 paddle0_b; // B1, B0
extern uint8 paddle1_b; // B2
extern uint8 paddle0_x;
extern uint8 paddle0_y;
extern uint8 paddle1_x;
extern uint8 paddle1_y;

extern uint8 paddleb_poll(); // update only paddle buttons (and returns paddle0_b result)
extern void paddle0_poll(); // update paddle0 and buttons (avg 1.5ms, max 3ms, 5ms if timeout)
extern void paddle01_poll(); // update both paddles and buttons (avg 3ms, max 6ms, 10ms if both timeout)
// TODO uint8 paddle0_digital() automatically apply thresholds and return digital bitmask?

//
// Sound
//

extern void sound_square(uint16 cy, uint16 count); // square wave with wavelength of cy CPU cycles (cy >= 90)
extern void sound_pulse(uint16 cya, uint16 cyb, uint16 count); // pulse wave with separate high/low lengths (cya/cyb >= 45)
extern void sound_noise(uint16 cy, uint16 count); // randomly flip every cy cycles, count times (cy >= 69)
extern void sound_sweep_up(uint16 cy, uint16 count, uint8 shift); // approximate square sweep, shift 1-16 controls speed (16 slowest)
extern void sound_sweep_down(uint16 cy, uint16 count, uint8 shift);

// music command format:
// $00    = halt music / reset
// $01    = rest
// $02-0C = repeat 2x-13x
// $0D    = loop
// $0E    = set repeat point
// $0F    = set loop point
// $10    = noise
// $11    = square (pulse 1/2)
// $12    = pulse 1/4
// $13    = pulse 1/8
// $14    = pulse 1/16
// $15    = pulse 1/32
// $16    = pulse 1/64
// $17-1F = set octave
// $20-5F = note duration ($5F = 1 second, $20 = 1/64th, $21 = 2/64th...
// $60-6B = note at last octave
// $70-FB = direct notes $XY = octave X-7, pitch Y, $B0 = middle C
// (unused note values ($XC-XF) are reserved and will cause a halt/reset)
// $FE    = no-effect
// $FF    = first of 2-byte command:
// $FF, $00    = halt music / reset
// $FF  $01    = space duration 0
// $FF, $20-5F = space duration (extra rest that follows any note or rest)
// $FF, $FE    = no-effect ($FE can be used to ensure not in second-byte mode)
// $FF, $FF    = halt music / reset
// (unused values are reserved and will cause a halt/reset)

extern void music_reset(); // resets music commands to default state
extern void music_command(uint8 command);

extern uint8 music_play(void* data, uint8 mode); // play string of music commands, returns nonzero if user-stopped
extern uint8 music_resume(uint8 mode); // resumes user-stopped music (returns immediately if end of music reached)
// mode 0: stop only at halt
// mode 1: stop at halt or keypress (does not read keypress, leaves it queued for kb_get)
// mode 2: stop at halt, keypress, or joystick buttons 0/1
// (data pointing at zero page will be treated as a halt)

//
// Floppy disk
//

extern uint8 disk_read(void* dest, uint16 sector, uint8 count);
// extern uint8 disk_write(void* src, uint16 sector, uint8 count);
// extern uint8 disk_format(uint8 volume);
extern uint8 disk_error; // last disk error
extern uint8 disk_volume; // last disk volume

#define DISK_ERROR_FIND      0x01
#define DISK_ERROR_DATA      0x02
#define DISK_ERROR_PARTIAL   0x04
// FIND = could not find sector on disk
// DATA = sector address found, data field missing
// PARTIAL = sector read but only partially correct (checksum fail)

// TODO drive select?

//
// Tape
//

// TODO monitor read/write interface?

//
// Video
//

// page definitions for video_cls_page
#define CLS_LOW0    0
#define CLS_LOW1    1
#define CLS_HIGH0   2
#define CLS_HIGH1   3
#define CLS_MIXED0  4
#define CLS_MIXED1  5
#define CLS_DLOW0   6
#define CLS_DLOW1   7
#define CLS_DHIGH0  8
#define CLS_DHIGH1  9
#define CLS_DMIXED0 10
#define CLS_DMIXED1 11


// low/double-low resolution colours
#define COL_BLACK       0
#define COL_MAGENTA     1
#define COL_BLUE_DARK   2
#define COL_PURPLE      3
#define COL_GREEN_DARK  4
#define COL_GREY0       5
#define COL_BLUE_MID    6
#define COL_BLUE_LIGHT  7
#define COL_BROWN       8
#define COL_ORANGE      9
#define COL_GREY1       10
#define COL_PINK        11
#define COL_GREEN_LIGHT 12
#define COL_YELLOW      13
#define COL_AQUAMARINE  14
#define COL_WHITE       15

// high resolution colours
#define COH_BLACK0      0x00
#define COH_PURPLE      0x01
#define COH_GREEN       0x02
#define COH_WHITE0      0x03
#define COH_BLACK1      0x80
#define COH_ORANGE      0x81
#define COH_BLUE        0x82
#define COH_WHITE1      0x83

// monochrome colours
#define COM_BLACK       0
#define COM_WHITE       1

// double-high resolution colours
#define COD_BLACK       0
#define COD_BLUE_DARK   1
#define COD_GREEN_DARK  2
#define COD_BLUE_MID    3
#define COD_BROWN       4
#define COD_GREY1       5
#define COD_GREEN_LIGHT 6
#define COD_AQUAMARINE  7
#define COD_MAGENTA     8
#define COD_PURPLE      9
#define COD_GREY0       10
#define COD_BLUE_LIGHT  11
#define COD_ORANGE      12
#define COD_PINK        13
#define COD_YELLOW      14
#define COD_WHITE       15

extern uint16 video_w; // pixel dimensons of current video mode
extern uint8 video_h;
extern uint16 video_text_x; // text_out position
extern uint8 video_text_y;
extern uint16 video_text_w; // right side of text area
extern uint8 video_text_h; // bottom of text area
extern uint16 video_text_xr; // left side of text area (after x wrap)
extern uint8 video_text_yr; // top of text area
extern uint8 video_page_w; // page to write/draw: $00 (page 1) or $FF (page 2)
extern uint8 video_page_r; // page to read/display
extern uint8 text_inverse; // $80 (normal text) or $00 (inverse text)
extern uint8* text_fontset; // high-resolution font set
extern uint8* text_fontset_width; // nibble-packed widths for VWF font set
extern uint8 text_fontset_offset; // ASCII offset to beginning of font set (usually $20)

// TODO vysnc ; wait for next video frame (needs separate IIe/IIc implementation), assembly version: call system_detect first, otherwise uses fallback (or if not IIe/IIc)
// TODO extern uint16 vsync_fallback ; for Apple II/II+ use a fixed timer instead of vsync, 12.5ms by default

// video modes
extern void video_mode_text();
extern void video_mode_low();
extern void video_mode_low_mixed();
extern void video_mode_high_mono();
extern void video_mode_high_mono_mixed();
extern void video_mode_high_color();
extern void video_mode_high_color_mixed();
// double video modes (80-column card / IIe / IIc // IIGS)
extern void video_mode_double_text();
extern void video_mode_double_low();
extern void video_mode_double_low_mixed();
extern void video_mode_double_high_mono();
extern void video_mode_double_high_mono_mixed();
extern void video_mode_double_high_color();
extern void video_mode_double_high_color_mixed();
// 80-column text with non-double graphics
extern void video_mode_high_color_double_mixed();
extern void video_mode_high_mono_double_mixed();
extern void video_mode_low_double_mixed();
// high/double-high resolution with no text support
extern void video_mode_high_mono_notext();
extern void video_mode_high_color_notext();
extern void video_mode_double_high_mono_notext();
extern void video_mode_double_high_color_notext();
// high resolution with variable width software-font
extern void video_mode_high_mono_vwf();
extern void video_mode_high_color_vwf();

extern void video_cls();
extern void video_cls_page(uint8 page, uint8 fill);
extern void video_page_apply(); // applies video page selection immediately (probably use flip/select instead)
extern void video_page_flip(); // flips the two selected video pages
extern void video_page_copy(); // copies read page into write page
extern void video_page_select(uint8 read, uint8 write); // sets and applies pages: 0 = page 1, 1 = page 2
// read page is what is visible onscreen, write page is what draw/text operations work on

extern void text_out(char c); // output one character at the current position
extern void text_outs(const char* s); // output a null-terminated string
extern void text_printf(const char* format, ...);
extern void text_vprintf(const char* format, va_list ap);
extern void text_scroll(sint8 lines); // positive: shift text up, clear bottom, negative: shift text down, clear top
extern void text_charset(char alt); // 0 = primary character set, 1 = alternat character set (IIe)
extern void text_xy(uint16 x, uint8 y); // set text output location (faster to set video_text_x/y directly, though)
extern void text_window(uint16 x0, uint8 y0, uint16 x1, uint8 y1); // confine text to x0<=x<x1, y0<=y<y1
extern void text_set_font(const uint8* fontset, uint8 offset); // set high-resolution fontset (beginning at offset character)
extern void text_set_font_vwf(const uint8* widths, const uint8* fontset, uint8 offset); // set vwf fontset with nibble-packed glyph widths

extern void draw_pixel(uint16 x, uint8 y, uint8 c);
extern uint8 draw_getpixel(uint16 x, uint8 y);
extern void draw_hline(uint16 x, uint8 y, uint16 w, uint8 c);
extern void draw_vline(uint16 x, uint8 y, uint8 h, uint8 c);
extern void draw_box(uint16 x, uint8 y, uint16 w, uint8 h, uint8 c);
extern void draw_fillbox(uint16 x, uint8 y, uint16 w, uint8 h, uint8 c);
extern void draw_line(uint16 x0, uint8 y0, uint16 x1, uint8 y1); // TODO
extern void draw_ellipse(uint16 x0, uint8 y0, uint16 w, uint8 h); // TODO
extern void draw_fill(uint16 x, uint8 y, uint8 c); // TODO
// span fill to chosen boundary colour (using vline) might be effective: https://en.wikipedia.org/wiki/Flood_fill#Span_Filling

// TODO these probably deserve to be per-mode, because they're large code
//extern void blit_coarse(uint16 x0, uint8 y0, const uint8* data, uint8 tw, uint8 th); // TODO
//extern void blit_fine(uint16 x0, uint8 y0, const uint8* data, uint8 tw, uint8 th); // TODO
//extern void blit_mask(uint16 x0, uint8 y0, const uint8* data, uint8 tw, uint8 th); // TODO
// blit coarse low, high, double-low, double-high
// set-font, pointer to data + ascii start
// font high, font double high color (does bit doubling for wider font), font double high mono

// blit coarse:
// low res (1x2) 1b
// hires mono (7x1) 1b
// hires color (7x1) 2b
// double-low res (2x2) 2b
// double-high res mono (14x1) 2b
// double-high res colour (7x1) 4b

// blit coarse masked:
// hires mono (7x1) 2b
// hires color (7x1) 4b
// double-high res mono (14x1) 4b
// double-high res colour (14x1) 8b

// blit fine:
// hires mono
// hires color

// blit fine masked:
// hires mono
// hires color

// TODO set attribute high, set attribute double high (used to set "secret" high bit, value = 0 or $80)
// TODO get for above

// TODO "unpack screen" take contiguous screen that goes across empty bytes at end of rows and respace it

// set text/border colours on IIGS only (call if system_type == SYSTEM_APPLE2GS)
extern void iigs_color(uint8 text_fg, uint8 text_bg, uint8 border); // low-resolution colour values

//
// Misc
//

void delay(unsigned int ms); // delays roughly this number of milliseconds
// TODO prng
// TODO huffmunch?

#endif
