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
// Floppy disk
//

extern uint8_t disk_read(void* dest, uint16 sector, uint8 count);
// extern uint8 disk_write(void* src, uint16 sector, uint8 count);
extern uint8_t disk_error; // last disk error
extern uint8_t disk_volume; // last disk volume

#define DISK_ERROR_FIND      0x01
#define DISK_ERROR_DATA      0x02
#define DISK_ERROR_PARTIAL   0x04
// FIND = could not find sector on disk
// DATA = sector address found, data field missing
// PARTIAL = sector read but only partially correct (checksum fail)

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


// low/double resolution colours
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

extern uint8 video_text_x;
extern uint8 video_text_y;
extern uint8 video_text_w;
extern uint8 video_text_h;
extern uint8 video_text_xr;
extern uint8 video_text_yr;
extern uint8 video_page_w; // $00 (page 1) or $FF (page 2)
extern uint8 video_page_r;
extern uint8 text_inverse;

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
extern void video_mode_double_text();
extern void video_mode_double_low();
extern void video_mode_double_low_mixed();
extern void video_mode_double_high_mono(); // TODO
extern void video_mode_double_high_mono_mixed(); // TODO
extern void video_mode_double_high_color(); // TODO
extern void video_mode_double_high_color_mixed(); // TODO
// TODO high_color_double_mixed (hires with 80col)
// TODO high_mono_double_mixed

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
extern void text_xy(uint8 x, uint8 y); // set text output location (faster to set video_text_x/y directly, though)
extern void text_window(uint8 x0, uint8 y0, uint8 x1, uint8 y1); // confine text to x0<=x<x1, y0<=y<y1

extern void draw_pixel(uint16 x, uint8 y, uint8 c);
extern uint8 draw_getpixel(uint16 x, uint8 y);
extern void draw_hline(uint16 x, uint8 y, uint16 w, uint8 c);
extern void draw_vline(uint16 x, uint8 y, uint8 h, uint8 c);
extern void draw_box(uint16 x, uint8 y, uint16 w, uint8 h, uint8 c);
extern void draw_fillbox(uint16 x, uint8 y, uint16 w, uint8 h, uint8 c);
extern void draw_line(uint16 x0, uint8 y0, uint16 x1, uint8 y1); // TODO
extern void draw_ellipse(uint16 x0, uint8 y0, uint16 w, uint8 h); // TODO
//extern void draw_triangle(); // TODO filled triangle
//extern void draw_polygon(const uint8* list, color); // TODO can this be done efficiently without multiply?
// TODO keep track of current graphics mode
// only operate the IIe double registers if switching from a double mode
// for polgyon it could determine whether the list is 3-byte XXY or 2-byte XY
// ... maybe a polygon needs to be triangulated to be efficient... maybe trilist?
// span fill to chosen boundary colour (using vline) might be effective: https://en.wikipedia.org/wiki/Flood_fill#Span_Filling

// TODO these probably deserve to be per-mode, because they're large code
//extern void blit_coarse(uint16 x0, uint8 y0, const uint8* data, uint8 tw, uint8 th); // TODO
//extern void blit_fine(uint16 x0, uint8 y0, const uint8* data, uint8 tw, uint8 th); // TODO
//extern void blit_mask(uint16 x0, uint8 y0, const uint8* data, uint8 tw, uint8 th); // TODO

// set text/border colours on IIGS only (call if system_type == SYSTEM_APPLE2GS)
extern void iigs_color(uint8 text_fg, uint8 text_bg, uint8 border); // low-resolution colour values

//
// Misc
//

void delay(unsigned int ms); // delays roughly this number of milliseconds

#endif
